# Backend-Only Build Plan — AI Meeting Summarizer

This document turns the broader meeting summarizer blueprint into a **backend-only implementation plan**.

It is designed for building the server side that powers an iOS/macOS meeting summarizer app.

---

## Backend Goal

Build a secure backend that can:

1. accept uploaded meeting audio
2. store audio and job metadata safely
3. run diarized transcription
4. normalize and chunk transcript text
5. generate structured meeting JSON
6. return job status and final results to the client
7. support retries, logging, and failure recovery

---

## Core Backend Principles

- Never expose OpenAI API keys to the mobile client
- Treat all audio and transcript data as sensitive
- Prefer asynchronous processing over synchronous request blocking
- Keep every pipeline step observable and retryable
- Preserve traceability from extracted output back to transcript segments
- Require deterministic JSON structure for final output
- Make human review possible by keeping evidence fields such as `source_segment`

---

## Recommended Backend Stack

Use any backend stack you prefer, but this plan assumes a practical setup like:

- API server: Node.js/TypeScript, Python FastAPI, or similar
- Queue/job runner: BullMQ, Celery, SQS workers, or equivalent
- Database: PostgreSQL
- Object storage: S3 or equivalent
- Cache/job coordination: Redis (optional but useful)
- OpenAI access: server-side only

A clean logical architecture:

- **API layer**: accepts uploads and serves status/results
- **Storage layer**: stores audio, transcript artifacts, and extracted JSON
- **Worker layer**: runs transcription + summarization pipeline
- **Persistence layer**: tracks jobs, meetings, errors, retries, and outputs

---

## Backend Data Flow

```text
Client uploads audio
→ backend stores file + creates meeting job
→ worker starts transcription
→ worker stores diarized transcript
→ worker normalizes transcript
→ worker chunks transcript
→ worker creates chunk summaries
→ worker generates final strict JSON
→ backend stores final result
→ client polls status/result endpoint
```

---

## Recommended Processing States

Use a strict job status model.

### Primary states

- `uploaded`
- `queued`
- `transcribing`
- `normalizing`
- `chunk_summarizing`
- `extracting_final`
- `completed`
- `failed`

### Optional secondary states

- `retrying`
- `partial_failure`
- `cancelled`
- `expired`

### State rules

- State updates must be persisted in the database
- Every state transition should be logged with timestamp
- Failed states should also store a machine-readable error code
- Workers must be able to resume from the last completed stage

---

## Recommended Backend Project Structure

```text
backend/
  src/
    api/
      routes/
      controllers/
      middleware/
    jobs/
      workers/
      schedulers/
      retry/
    services/
      storage/
      transcription/
      normalization/
      chunking/
      extraction/
      result_mapping/
    models/
    repositories/
    schemas/
    prompts/
    utils/
    config/
    logging/
  tests/
    unit/
    integration/
    fixtures/
```

Keep HTTP handlers thin. Put business logic in services and workers.

---

## Database Design

At minimum, use these tables or equivalent collections.

### 1. meetings

Core record for each uploaded or recorded meeting.

Suggested fields:

- `id`
- `created_at`
- `updated_at`
- `title`
- `client_platform`
- `status`
- `language`
- `timezone`
- `duration_seconds`
- `audio_storage_key`
- `transcript_storage_key`
- `normalized_transcript_storage_key`
- `chunk_summary_storage_key`
- `final_result_storage_key`
- `error_code`
- `error_message`
- `retry_count`

### 2. meeting_jobs

Tracks processing attempts and stage-level execution.

Suggested fields:

- `id`
- `meeting_id`
- `job_type`
- `status`
- `started_at`
- `completed_at`
- `attempt_number`
- `worker_id`
- `error_code`
- `error_message`
- `metadata_json`

### 3. meeting_artifacts

Tracks generated files or payloads.

Suggested fields:

- `id`
- `meeting_id`
- `artifact_type`
- `storage_key`
- `content_type`
- `version`
- `created_at`

Artifact types may include:

- `raw_audio`
- `diarized_transcript`
- `normalized_transcript`
- `chunk_summaries`
- `final_json`
- `processing_logs`

### 4. optional audit_events

Useful for debugging and compliance.

Suggested fields:

- `id`
- `meeting_id`
- `event_type`
- `event_time`
- `actor_type`
- `details_json`

---

## Object Storage Layout

Use predictable storage keys.

```text
meetings/{meeting_id}/audio/original.m4a
meetings/{meeting_id}/transcript/diarized.json
meetings/{meeting_id}/transcript/normalized.txt
meetings/{meeting_id}/summaries/chunk_summaries.json
meetings/{meeting_id}/result/final_meeting_summary.json
meetings/{meeting_id}/logs/pipeline.log
```

Storage rules:

- use private buckets only
- do not expose direct public URLs
- use short-lived signed URLs only when truly needed
- encrypt at rest
- set retention and deletion policies explicitly

---

## API Endpoints

Keep the public backend API small and stable.

### 1. `POST /api/meetings/upload`

Creates a meeting job from uploaded audio.

**Request**
- multipart form-data
- file field: `audio`
- optional metadata:
  - `title`
  - `language`
  - `timezone`
  - `meeting_date`
  - `participants`

**Response**

```json
{
  "meeting_id": "string",
  "status": "uploaded"
}
```

### 2. `GET /api/meetings/{meeting_id}/status`

Returns current pipeline status.

**Response**

```json
{
  "meeting_id": "string",
  "status": "transcribing",
  "progress": 0.35,
  "error_code": "",
  "error_message": ""
}
```

### 3. `GET /api/meetings/{meeting_id}/result`

Returns final structured meeting result once ready.

**Response**
- `404` or `409` if not ready yet
- `200` with final structured result when complete

### 4. `POST /api/meetings/{meeting_id}/retry`

Retries failed processing.

### 5. `DELETE /api/meetings/{meeting_id}`

Deletes meeting artifacts according to retention policy.

### 6. optional `GET /api/meetings/{meeting_id}/artifacts`

For admin/debug use only.

---

## Upload Handling

### Requirements

- validate MIME type and extension
- reject unsupported files early
- enforce max upload size
- generate server-side meeting ID
- write upload metadata immediately
- store file before queueing heavy work

### Supported audio formats

Support common formats already aligned with the upstream transcription flow:

- `m4a`
- `mp3`
- `mp4`
- `wav`
- `flac`
- `webm`

### Upload rules

- do checksum validation if feasible
- normalize filenames; never trust original filename for storage paths
- virus scan if your environment requires it
- reject empty files and ultra-short corrupt audio

---

## Queue and Worker Design

Do not process the full pipeline inside the upload request lifecycle.

### Queue flow

1. upload endpoint stores file
2. upload endpoint inserts meeting record
3. upload endpoint enqueues job
4. worker consumes job
5. worker advances through pipeline steps

### Worker requirements

- idempotent job execution
- safe retry behavior
- per-stage timeout limits
- retry with backoff
- stage checkpoint persistence
- dead-letter handling for repeated failures

### Retry policy suggestion

- network/transient errors: retry automatically
- schema/decode failures: retry once with logging
- unsupported input errors: fail immediately
- repeated upstream failure: mark failed and require manual retry

---

## Processing Pipeline

This is the recommended backend pipeline derived from the larger blueprint.

---

### Stage 1 — Audio Validation and Metadata Extraction

**Goal:** Ensure the uploaded file is valid before costly AI work.

**Tasks:**
- inspect file type
- inspect duration if available
- store basic metadata
- optionally standardize language/timezone metadata

**Deliverables:**
- validated meeting record
- audio artifact stored
- job moved to `queued` or `transcribing`

---

### Stage 2 — Diarized Transcription

**Goal:** Convert audio into a diarized transcript.

**Recommended OpenAI request shape:**
- transcription endpoint
- model: diarization-capable transcription model
- response format: diarized JSON
- set language if known
- use chunking strategy for longer files where required

**Output to persist:**
- full transcript text
- segments array with speaker labels
- timestamps
- request metadata used for the call

**Success criteria:**
- diarized transcript artifact saved
- meeting status updated to `normalizing`

**Failure handling:**
- save upstream error payload safely
- save failed stage metadata
- mark job failed or retry based on error class

---

### Stage 3 — Transcript Normalization

**Goal:** Convert raw diarized segments into a stable canonical transcript for downstream extraction.

**Normalization rules:**
- preserve meaning exactly
- preserve segment IDs
- preserve timestamps
- preserve speaker labels
- fix obvious ASR artifacts only
- mark unintelligible content explicitly
- do not invent names

**Recommended output format:**

```text
[seg:<id> <start>-<end> spk:<speaker>] <cleaned text>
```

**Why this stage matters:**
- improves downstream consistency
- makes chunking deterministic
- supports evidence-based extraction later

**Deliverables:**
- normalized transcript text artifact
- normalized transcript metadata saved

---

### Stage 4 — Chunking

**Goal:** Split long normalized transcript into manageable chunks.

**Chunking rules:**
- chunk by transcript size, not arbitrary raw characters only
- preserve segment boundaries
- avoid splitting a single segment across chunks
- carry a `chunk_range` such as `seg:001-seg:048`
- optionally overlap small boundaries for context continuity

**Chunk metadata to persist:**
- chunk ID
- segment start/end IDs
- token estimate
- text length

**Deliverables:**
- chunk list artifact
- pipeline state updated to `chunk_summarizing`

---

### Stage 5 — Chunk Summarization

**Goal:** Summarize each chunk and extract candidate structured items with evidence.

**Each chunk should produce:**
- `chunk_summary`
- `key_decisions`
- `action_items`
- `risks`
- `open_questions`
- confidence fields
- source segment references

**Required behavior:**
- every extracted item must reference source segments
- do not guess owners or deadlines
- prefer empty string when unknown
- keep output JSON deterministic

**Deliverables:**
- chunk summaries artifact
- validation pass confirming every item has evidence

---

### Stage 6 — Final Structured Extraction

**Goal:** Merge chunk-level outputs into one final meeting JSON.

**Final JSON should include at minimum:**
- `meeting_title`
- `summary`
- `key_decisions`
- `action_items`
- `risks`
- `open_questions`
- `speakers`

**Extraction rules:**
- return strict JSON only
- match schema exactly
- do not invent owners or dates
- preserve evidence via `source_segment`
- keep confidence tied to explicitness in transcript evidence

**Important:**
Use strict schema validation server-side after model output. Never trust model JSON without validation.

**Deliverables:**
- final validated JSON artifact
- meeting status updated to `completed`

---

### Stage 7 — Result Mapping and Persistence

**Goal:** Make final result easy for clients to consume.

**Tasks:**
- validate final JSON against server schema
- persist final result in storage
- store summary fields in database for fast retrieval if useful
- expose a stable result payload to the client

---

## Recommended Final Result Schema

Use a conservative schema with explicit evidence fields.

```json
{
  "meeting_title": "string",
  "summary": "string",
  "key_decisions": [
    {
      "decision": "string",
      "confidence": 0.0,
      "source_segment": "string"
    }
  ],
  "action_items": [
    {
      "task": "string",
      "owner": "string",
      "deadline": "string",
      "confidence": 0.0,
      "source_segment": "string"
    }
  ],
  "risks": [
    {
      "risk": "string",
      "confidence": 0.0,
      "source_segment": "string"
    }
  ],
  "open_questions": [
    {
      "question": "string",
      "confidence": 0.0,
      "source_segment": "string"
    }
  ],
  "speakers": [
    {
      "speaker_label": "string",
      "display_name": "string",
      "notes": "string"
    }
  ]
}
```

### Schema notes

- `deadline` should be ISO-8601 date only when explicit and resolved reliably
- otherwise use empty string
- `source_segment` should point to transcript evidence such as `seg:12 (00:45-01:10)`
- keep schema stable to reduce app-side decoding risk

---

## Prompt Files to Keep in Backend

Store prompts as versioned backend assets, not inline magic strings inside controllers.

Recommended prompt files:

- `prompts/normalize_transcript.txt`
- `prompts/chunk_summary.txt`
- `prompts/final_extraction.txt`

### Prompt management rules

- version every prompt
- log prompt version used for each meeting job
- avoid silent prompt changes in production
- add fixtures to regression test prompt behavior

---

## Validation Rules

Backend validation is mandatory.

### Validate before AI call

- file exists
- file format allowed
- duration within allowed bounds
- metadata sanitized

### Validate after transcription

- transcript exists
- segments array exists
- timestamps present
- speaker labels present or consistently fallback-labeled

### Validate after chunk summaries

- JSON parse succeeds
- every extracted item has `source_segments`
- confidence fields are numeric

### Validate after final extraction

- schema matches exactly
- required arrays exist even if empty
- no unexpected keys if strict mode is expected
- no nulls where client expects strings

---

## Security Requirements

### Secrets

- keep OpenAI API key only on the server
- store secrets in environment variables or secret manager
- rotate keys safely

### Auth

For MVP, client auth may be simple, but do not leave endpoints open in production.

Recommended options:
- session auth
- signed mobile auth token
- per-user meeting ownership checks

### File security

- private storage only
- encrypt at rest
- short-lived signed URLs only if necessary
- delete orphaned uploads

### Data minimization

Support retention options such as:
- delete audio after processing
- keep transcript only
- keep all artifacts for limited days

---

## Privacy and Consent Support

Backend should support the product’s consent and compliance model.

### Store useful metadata

- consent acknowledgement timestamp if captured by client
- meeting timezone
- optional meeting date
- optional deletion preference

### Delete flow

A delete request should remove:
- stored audio
- transcript artifacts
- summary artifacts
- database references where appropriate

---

## Observability and Logging

Centralized logging is essential.

### Log at least these events

- upload received
- file stored
- job queued
- transcription started/completed/failed
- normalization started/completed/failed
- chunk summarization started/completed/failed
- final extraction started/completed/failed
- result delivered
- delete completed

### Logging rules

- never dump sensitive transcript text blindly into logs
- prefer structured logs
- include `meeting_id`, `job_id`, `stage`, and `attempt_number`
- redact secrets and personal data where possible

### Metrics to track

- upload success rate
- transcription success rate
- extraction success rate
- average processing duration by stage
- retry rate
- failure rate by error code

---

## Error Model

Define clear internal error codes.

Example categories:

- `UPLOAD_INVALID_FILE`
- `UPLOAD_TOO_LARGE`
- `STORAGE_WRITE_FAILED`
- `TRANSCRIPTION_UPSTREAM_FAILED`
- `TRANSCRIPTION_INVALID_RESPONSE`
- `NORMALIZATION_FAILED`
- `CHUNK_SUMMARY_SCHEMA_FAILED`
- `FINAL_EXTRACTION_SCHEMA_FAILED`
- `RESULT_NOT_READY`
- `UNAUTHORIZED`

Client-facing responses should be safe and concise.
Internal logs can be more detailed.

---

## Example Result Lifecycle

### Upload

Client uploads `team-sync.m4a`.

Backend creates:
- meeting record with status `uploaded`
- object storage key for raw audio
- queued worker job

### Processing

Worker performs:
- diarized transcription
- normalization
- chunk summaries
- final extraction

### Completion

Backend stores:
- final structured JSON
- transcript artifacts
- job metadata

Client polls:
- `/status` until `completed`
- `/result` to retrieve final payload

---

## Suggested Phased Build Order for Backend

---

### Phase B1 — Backend Foundation

**Goal:** Create backend project shell and persistence basics.

**Build:**
- API server skeleton
- database connection
- object storage adapter
- meeting model
- job model
- environment config
- logging utility

**Definition of done:**
- backend starts locally
- health endpoint works
- database migrations run

---

### Phase B2 — Upload API

**Goal:** Accept audio files and create meeting jobs.

**Build:**
- upload endpoint
- file validation
- object storage write
- meeting record creation
- queue integration

**Definition of done:**
- valid audio upload creates a meeting ID
- invalid files are rejected cleanly

---

### Phase B3 — Worker and Job State Engine

**Goal:** Run asynchronous jobs safely.

**Build:**
- queue worker
- state transitions
- retry handling
- per-stage logging

**Definition of done:**
- worker consumes queued jobs
- status endpoint reflects real progress

---

### Phase B4 — Diarized Transcription Integration

**Goal:** Connect backend to transcription stage.

**Build:**
- transcription service wrapper
- artifact persistence
- failure handling

**Definition of done:**
- uploaded meeting produces stored diarized transcript

---

### Phase B5 — Normalization and Chunking

**Goal:** Prepare transcript for reliable extraction.

**Build:**
- normalization prompt flow
- transcript canonical format
- chunk generator

**Definition of done:**
- normalized transcript and chunk list stored successfully

---

### Phase B6 — Chunk Summaries

**Goal:** Produce intermediate evidence-based summaries.

**Build:**
- chunk summarization prompt flow
- schema validation for chunk output
- artifact persistence

**Definition of done:**
- every chunk returns validated summary JSON

---

### Phase B7 — Final Structured Extraction

**Goal:** Generate strict final JSON.

**Build:**
- final extraction prompt flow
- strict schema validation
- result persistence

**Definition of done:**
- final result is parseable, validated, and fetchable by client

---

### Phase B8 — Status and Result APIs

**Goal:** Make processing visible to clients.

**Build:**
- status endpoint
- result endpoint
- retry endpoint

**Definition of done:**
- client can poll status and retrieve final result

---

### Phase B9 — Reliability Hardening

**Goal:** Make backend production-safe.

**Build:**
- better retries
- dead-letter handling
- retention cleanup jobs
- metrics dashboard
- deletion flow
- regression tests

**Definition of done:**
- common failures recover gracefully
- stale artifacts get cleaned up

---

## Testing Plan

### Unit tests

Cover:
- file validation
- status transition rules
- transcript normalization formatter
- chunking logic
- JSON schema validation
- result mapping

### Integration tests

Cover:
- upload → queued job
- queued job → transcript artifact
- transcript → final result
- failed upstream call → retry/fail behavior

### Fixture tests

Keep test fixtures for:
- short clean meeting
- long noisy meeting
- unclear owners/deadlines
- multi-speaker discussion
- empty or invalid transcript edge cases

---

## Backend Rules for Codex or Other Codegen Tools

Use these rules in backend code generation prompts:

- make only the requested backend change
- keep controllers thin
- keep business logic in services/workers
- do not hardcode API keys
- validate every external response
- make job steps idempotent
- keep code compileable and testable after each step
- do not refactor unrelated modules

---

## Master Backend Prompt Template

```text
We are building the backend for an AI Meeting Summarizer.

Architecture:
- API server
- async worker pipeline
- object storage for audio and artifacts
- database for meetings and job states
- OpenAI calls only from backend

Current backend phase: {{PHASE NAME}}
Current backend step: {{STEP NAME}}

Task:
{{PASTE THE STEP TASK HERE}}

Rules:
- Keep controllers thin
- Put business logic in services or workers
- Do not hardcode secrets
- Validate external responses
- Make retries safe and idempotent
- Make the code compile
- Change only what is needed for this step

Deliver:
- required new files
- updates to existing files
- schema or migration updates if needed
- brief notes on what changed
```

---

## Definition of Backend MVP Complete

The backend MVP is complete when:

- audio upload works reliably
- uploaded files are stored securely
- async jobs process meetings without blocking the request lifecycle
- diarized transcript is generated and stored
- normalized transcript and chunk summaries are generated
- final structured JSON is validated and stored
- client can poll status and fetch results
- failures are logged clearly and can be retried
- delete flow and retention behavior are defined

---

## Final Recommendation

For the backend, do **not** reduce the AI pipeline to a single “transcribe and summarize” call if you want reliable production results.

The safer backend path is:

1. diarized transcription
2. normalization
3. chunk summaries with evidence
4. final strict JSON extraction
5. validation and persistence

That is the backend shape most consistent with the original blueprint, while still being implementable in phases.