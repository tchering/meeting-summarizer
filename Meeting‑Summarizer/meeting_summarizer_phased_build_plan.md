# AI Meeting Summarizer — Phased Build Plan for Codex + Xcode

This document converts the current research and blueprint into a **step-by-step execution plan** that Codex can follow one phase at a time.

Use this rule while building:
- Finish **one step at a time**
- Test that step manually
- Commit changes
- Only then move to the next step

---

# Project Goal

Build an iOS/macOS AI Meeting Summarizer app with:
- in-app audio recording
- optional audio file upload
- backend-powered transcription
- AI-generated structured summary
- extracted action items, decisions, deadlines, risks, and questions
- local meeting history storage

---

# Recommended Build Order

## Phase 1 — Foundation and Local App Shell
Goal: Create the app structure, local models, and screens without AI yet.

### Step 1.1 — Create the Xcode project
**Objective:** Start the base app correctly.

**Requirements:**
- SwiftUI app
- Swift language
- Storage: SwiftData
- Testing: None
- CloudKit: Off

**Deliverable:**
- Empty app launches successfully
- Project runs on simulator

**Codex prompt:**
```text
Set up the base iOS SwiftUI app structure for an AI Meeting Summarizer.
Use MVVM + Services architecture.
Create folders/groups for: App, Models, Views, ViewModels, Services, Persistence, Utilities.
Do not add backend or AI logic yet.
Ensure the app builds and launches.
```

### Step 1.2 — Create the project structure
**Status:** [x] Done

**Objective:** Organize the app so future steps are clean.

**Create:**
- `App/`
- `Models/`
- `Views/`
- `ViewModels/`
- `Services/`
- `Persistence/`
- `Utilities/`

**Deliverable:**
- Clear folder structure in Xcode
- No business logic inside views

**Codex prompt:**
```text
Create a clean MVVM + Services folder structure for the SwiftUI app.
Add placeholder Swift files where needed so the structure is visible and ready for future features.
Do not implement any complex logic yet.
```

### Step 1.3 — Create SwiftData models
**Status:** [x] Done

**Objective:** Define local data objects.

**Models to create:**
- `Meeting`
- `ActionItem`
- `DecisionItem`
- `OpenQuestionItem`

**Meeting fields:**
- id
- title
- createdAt
- updatedAt
- status
- transcript
- summary
- audioFilePath
- durationSeconds

**ActionItem fields:**
- id
- task
- owner
- deadlineText
- confidence
- sourceSegment
- isCompleted

**DecisionItem fields:**
- id
- text
- confidence
- sourceSegment

**OpenQuestionItem fields:**
- id
- text
- confidence
- sourceSegment

**Deliverable:**
- SwiftData models compile
- Relationships work

**Codex prompt:**
```text
Create SwiftData models for a meeting summarizer app.
Use @Model types for Meeting, ActionItem, DecisionItem, and OpenQuestionItem.
Meeting should have one-to-many relationships to action items, decisions, and open questions.
Keep the models simple and ready for MVP use.
```

### Step 1.4 — Create app navigation shell
**Status:** [x] Done

**Objective:** Build the base user flow.

**Screens to add:**
- HomeView
- RecordView
- HistoryView
- MeetingDetailView
- ProcessingView

**Deliverable:**
- App can navigate between screens
- Placeholder content exists

**Codex prompt:**
```text
Create the initial SwiftUI screens for HomeView, RecordView, HistoryView, MeetingDetailView, and ProcessingView.
Use simple placeholder UI and basic navigation.
Do not add AI or recording logic yet.
```

### Step 1.5 — Add sample data and history list
**Status:** [x] Done

**Objective:** Make the app feel real before backend work.

**Deliverable:**
- Home screen shows sample meetings
- History screen lists saved meetings
- Tapping a meeting opens detail view

**Codex prompt:**
```text
Add sample SwiftData meeting records and display them in a HistoryView list.
Allow tapping a meeting row to open a MeetingDetailView.
Use simple placeholder transcript and summary text.
```

---

# Phase 2 — Audio Recording MVP
Goal: Record audio inside the app and save the file locally.

### Step 2.1 — Add microphone permission flow
**Status:** [x] Done

**Objective:** Ask for mic access correctly.

**Requirements:**
- Add microphone permission handling
- Include user-facing permission state in UI
- Show denied state clearly

**Deliverable:**
- App requests microphone permission
- UI reflects granted/denied state

**Codex prompt:**
```text
Add microphone permission handling to the SwiftUI app.
Create a simple permission flow in RecordView.
If permission is denied, show a helpful message.
Do not start recording yet.
```

### Step 2.2 — Add recording service
**Status:** [x] Done

**Objective:** Record audio to local file.

**Create:**
- `AudioRecordingService.swift`

**Features:**
- startRecording()
- stopRecording()
- save `.m4a` file
- publish recording state

**Deliverable:**
- Start/Stop recording works
- Local file is created

**Codex prompt:**
```text
Create an AudioRecordingService using AVAudioRecorder.
Support starting and stopping recording to a local .m4a file.
Expose recording state so RecordView can react.
Keep the implementation clean and MVP-focused.
```

### Step 2.3 — Connect recording service to RecordViewModel
**Status:** [x] Done

**Objective:** Move UI logic out of the view.

**Create:**
- `RecordViewModel.swift`

**Deliverable:**
- Record button works through the view model
- UI updates live when recording starts/stops

**Codex prompt:**
```text
Create RecordViewModel and connect it to AudioRecordingService.
The view model should manage recording state, elapsed time, and the saved file URL.
Keep the SwiftUI view thin.
```

### Step 2.4 — Add recording UI polish
**Status:** [x] Done

**Objective:** Make the recorder usable.

**UI elements:**
- start button
- stop button
- recording indicator
- elapsed timer
- success state after saving

**Deliverable:**
- Recording flow feels complete

**Codex prompt:**
```text
Improve RecordView UI for the recording experience.
Add a visible recording indicator, elapsed timer, Start button, Stop button, and a saved-state confirmation.
Keep the design simple and modern.
```

### Step 2.5 — Save a Meeting after recording
**Status:** [x] Done

**Objective:** Turn a recorded file into a local meeting object.

**Deliverable:**
- Stopping recording creates a Meeting entry in SwiftData
- History screen shows the new meeting

**Codex prompt:**
```text
When a recording stops, create a new Meeting object in SwiftData.
Store the audio file path, createdAt date, and a default status like 'recorded'.
Refresh the history list automatically.
```

---

# Phase 3 — Upload and Backend Connection
Goal: Send recorded audio to your backend safely.

### Step 3.1 — Create API client shell
**Status:** [x] Done

**Objective:** Centralize networking.

**Create:**
- `APIClient.swift`

**Deliverable:**
- Reusable network layer exists
- No hardcoded OpenAI key in app

**Codex prompt:**
```text
Create a simple APIClient for the SwiftUI app.
It should support POST requests and file uploads to my own backend.
Do not call OpenAI directly from the client.
Make it reusable for future endpoints.
```

### Step 3.2 — Create upload service
**Status:** [x] Done

**Objective:** Upload recorded audio file.

**Create:**
- `UploadService.swift`

**Deliverable:**
- Audio file uploads to backend endpoint
- Upload state is visible in UI

**Codex prompt:**
```text
Create an UploadService that uploads a recorded audio file to a backend endpoint.
Expose progress, loading state, success, and failure state.
Integrate it with RecordViewModel.
```

### Step 3.3 — Add processing state flow
**Status:** [x] Done

**Objective:** Show what is happening after upload.

**States:**
- recorded
- uploading
- processing
- completed
- failed

**Deliverable:**
- Meeting status updates correctly
- ProcessingView can show current state

**Codex prompt:**
```text
Add a meeting processing state system.
Support statuses: recorded, uploading, processing, completed, failed.
Update Meeting objects and the UI when state changes.
```

### Step 3.4 — Poll backend for result
**Objective:** Fetch summary result after processing.

**Deliverable:**
- App checks backend for completed summary
- Updates local Meeting when result is ready

**Codex prompt:**
```text
Add polling logic to check whether backend summarization is complete.
When the result is ready, update the local Meeting object with transcript, summary, and extracted items.
Keep the polling logic simple and MVP-friendly.
```

---

# Phase 4 — AI Summary Result Integration
Goal: Accept structured backend JSON and display it in the app.

### Step 4.1 — Create response models
**Status:** [x] Done

**Objective:** Decode backend summary JSON.

**Create:**
- `MeetingSummaryResponse.swift`

**Deliverable:**
- JSON decodes into Swift models

**Codex prompt:**
```text
Create Codable response models for a meeting summary API response.
The response should include meeting_title, summary, key_decisions, action_items, risks, open_questions, and speakers.
Keep model names clean and easy to use from the view model.
```

### Step 4.2 — Map backend JSON into SwiftData
**Status:** [x] Done

**Objective:** Persist AI output locally.

**Deliverable:**
- Meeting summary saved
- Action items saved
- Decisions saved
- Open questions saved

**Codex prompt:**
```text
Map the decoded meeting summary API response into the SwiftData models.
Update the matching Meeting record and replace or insert related action items, decisions, and open questions.
Keep the mapping logic inside a service or repository, not inside the SwiftUI views.
```

### Step 4.3 — Build MeetingDetailView UI
**Status:** [x] Done

**Objective:** Show final meeting result clearly.

**Sections:**
- summary
- action items
- decisions
- risks
- open questions
- transcript

**Deliverable:**
- Meeting detail screen is readable and useful

**Codex prompt:**
```text
Build a polished MeetingDetailView for the meeting summarizer app.
Show sections for summary, action items, decisions, risks, open questions, and transcript.
Use clean SwiftUI layout and make the screen easy to scan.
```

### Step 4.4 — Add editing before sharing
**Status:** [x] Done

**Objective:** Human review before sending.

**Features:**
- edit summary text
- edit action item owner
- edit deadline text

**Deliverable:**
- User can correct AI output before sharing

**Codex prompt:**
```text
Add editing support to MeetingDetailView.
Allow users to edit the summary text, action item owner, and action item deadline.
Persist the edits to SwiftData.
```

---

# Phase 5 — Audio File Upload From Device
Goal: Support existing meeting files, not only live recording.

### Step 5.1 — Add file picker
**Status:** [x] Done

**Objective:** Let users choose audio files from device.

**Deliverable:**
- User can select supported audio files

**Codex prompt:**
```text
Add a file picker to the app so users can import an audio file from the device.
Support common audio formats and return a usable file URL for upload.
```

### Step 5.2 — Convert uploaded file into Meeting workflow
**Objective:** Reuse the same backend pipeline.

**Deliverable:**
- Imported file creates a Meeting object
- Upload and processing use same logic as recorded audio

**Codex prompt:**
```text
Integrate imported audio files into the same workflow as recorded audio.
When a file is selected, create a Meeting object and upload it through the same upload and processing pipeline.
```

---

# Phase 6 — Share and Export
Goal: Let users use the results.

### Step 6.1 — Copy/share summary
**Objective:** Make recap useful immediately.

**Deliverable:**
- User can copy summary text
- User can share meeting recap

**Codex prompt:**
```text
Add share and copy actions to MeetingDetailView.
Allow sharing the meeting summary and action items using the native iOS share sheet.
```

### Step 6.2 — Export JSON
**Objective:** Make integrations easier later.

**Deliverable:**
- User can export raw structured meeting JSON

**Codex prompt:**
```text
Add an export option for the structured meeting JSON.
Generate a clean JSON representation of the meeting and allow the user to share or save it.
```

---

# Phase 7 — Reliability and Error Handling
Goal: Make the MVP stable.

### Step 7.1 — Add reusable error states
**Objective:** Handle failures properly.

**Cover errors for:**
- microphone denied
- recording failed
- upload failed
- backend processing failed
- invalid response

**Deliverable:**
- User sees actionable error messages

**Codex prompt:**
```text
Add reusable error handling to the app for recording, upload, processing, and decoding failures.
Show clear user-friendly error messages and retry actions where appropriate.
```

### Step 7.2 — Add logging helpers
**Objective:** Debug issues faster.

**Deliverable:**
- Key events are logged
- Logging is centralized

**Codex prompt:**
```text
Create a lightweight app logging utility for the meeting summarizer app.
Use it for recording start/stop, upload start/success/failure, processing state changes, and decode failures.
Keep logs privacy-aware.
```

### Step 7.3 — Add loading skeletons and empty states
**Objective:** Improve UX.

**Deliverable:**
- Better UI while processing
- Better empty history screen

**Codex prompt:**
```text
Add loading states, empty states, and basic skeleton UI where useful.
Improve the UX for the meeting list, processing screen, and meeting detail screen.
```

---

# Phase 8 — Backend AI Pipeline Tasks
Goal: Build the server side that powers the app.

## This phase is backend-focused, but keep it in the plan so Codex can generate server code separately.

### Step 8.1 — Build backend upload endpoint
**Deliverable:**
- Backend accepts audio file
- Stores it securely
- Returns meeting/job ID

**Codex prompt:**
```text
Create a backend endpoint that accepts uploaded meeting audio, stores it securely, and returns a job ID.
Do not expose OpenAI keys to the client.
Prepare this endpoint for async processing.
```

### Step 8.2 — Add transcription job
**Deliverable:**
- Backend sends audio to transcription API
- Gets diarized transcript back

**Codex prompt:**
```text
Add a backend processing job that sends uploaded audio to OpenAI transcription with diarization enabled.
Store the returned transcript and speaker segments for later summarization.
```

### Step 8.3 — Add structured summary extraction job
**Deliverable:**
- Backend converts transcript into structured JSON

**Codex prompt:**
```text
Add a backend summarization step that converts a diarized transcript into structured meeting JSON.
Return summary, key decisions, action items, risks, open questions, and speakers.
Use strict structured output so the JSON shape is reliable.
```

### Step 8.4 — Add result endpoint
**Deliverable:**
- App can fetch completed meeting result

**Codex prompt:**
```text
Create a backend endpoint that returns the status and final structured result for a meeting processing job.
Support statuses like processing, completed, and failed.
```

---

# Phase 9 — Phase 2 Product Features (Later)
Goal: Expand after MVP works.

### Step 9.1 — Add search through meeting history
### Step 9.2 — Add calendar metadata
### Step 9.3 — Add action item completion toggles
### Step 9.4 — Add subscriptions/paywall
### Step 9.5 — Add realtime transcription mode
### Step 9.6 — Add Zoom/Meet/Teams integrations

Do not build these until Phases 1–8 are stable.

---

# Suggested Build Sequence for You

If you want the fastest path, do exactly this order:

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 4
5. Phase 7
6. Phase 5
7. Phase 6
8. Phase 8
9. Phase 9

---

# Rules for Working With Codex

Use these rules in every Codex prompt:

- Make only the requested change
- Keep MVVM + Services architecture
- Keep SwiftUI views thin
- Put business logic in ViewModels or Services
- Do not hardcode API keys
- Prefer simple, production-clean code
- Do not refactor unrelated files
- Make code compile after each step

---

# Master Codex Prompt Template

Use this template for each step:

```text
We are building an AI Meeting Summarizer app in Xcode using SwiftUI, SwiftData, and MVVM + Services architecture.

Current phase: {{PHASE NAME}}
Current step: {{STEP NAME}}

Task:
{{PASTE THE STEP TASK HERE}}

Rules:
- Keep MVVM + Services architecture
- Keep views thin
- Do not hardcode secrets
- Make the code compile
- Change only what is necessary for this step
- Use simple, clear Swift code suitable for an MVP

Deliver:
- the required files
- any needed updates to existing files
- brief notes on what was changed
```

---

# Definition of MVP Complete

The MVP is complete when:
- user can record audio in app
- user can upload audio to backend
- backend returns transcript + structured summary
- app stores and displays summary locally
- user can review and edit action items
- user can share/export recap

---

# Source basis

This phased plan is derived from the uploaded research blueprint and integration report, simplified into a Codex-friendly build order.
