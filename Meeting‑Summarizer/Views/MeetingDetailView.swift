import SwiftData
import SwiftUI
import UIKit

struct MeetingDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let meeting: Meeting

    @State private var isEditing = false
    @State private var draftSummary = ""
    @State private var actionOwnerDrafts: [UUID: String] = [:]
    @State private var actionDeadlineDrafts: [UUID: String] = [:]
    @State private var saveErrorMessage: String?
    @State private var copyConfirmationMessage: String?
    @State private var isShowingShareSheet = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                summaryCard
                actionItemsCard
                decisionsCard
                risksCard
                openQuestionsCard
                transcriptCard
            }
            .padding(AppTheme.contentPadding)
            .padding(.bottom, 32)
        }
        .appScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !isEditing {
                    Button {
                        isShowingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }

                    Button {
                        copyRecap()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveEdits()
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("Edit") {
                        beginEditing()
                    }
                }
            }
        }
        .task {
            loadDraftsFromMeeting()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ActivityShareSheet(activityItems: [shareText])
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(meeting.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .themeTitle()

                Spacer(minLength: 0)

                if isEditing {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }

            Text(meeting.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.medium))
                .themeMutedText()

            HStack(alignment: .top, spacing: 12) {
                statusPill

                Spacer(minLength: 0)

                metricChip(
                    title: "Duration",
                    value: formattedDuration
                )

                metricChip(
                    title: "Actions",
                    value: "\(meeting.actionItems.count)"
                )
            }

            Text(meeting.processingStatus.detailMessage)
                .font(.subheadline)
                .themeSecondaryText()

            if let saveErrorMessage {
                Text(saveErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.orange)
            }

            if let copyConfirmationMessage {
                Text(copyConfirmationMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .liquidGlassCard()
    }

    private var summaryCard: some View {
        detailCard(
            title: "Summary",
            icon: "text.alignleft",
            subtitle: "High-level recap"
        ) {
            if isEditing {
                TextEditor(text: $draftSummary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 160)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.elevatedSurfaceFill.opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.surfaceStroke, lineWidth: 1)
                    )
                    .themeSecondaryText()
            } else {
                Text(nonEmpty(meeting.summary, fallback: "No summary available yet."))
                    .font(.body)
                    .lineSpacing(4)
                    .themeSecondaryText()
            }
        }
    }

    private var actionItemsCard: some View {
        detailCard(
            title: "Action Items",
            icon: "checklist",
            subtitle: "Clear next steps"
        ) {
            if meeting.actionItems.isEmpty {
                emptyState("No action items were extracted.")
            } else {
                VStack(spacing: 12) {
                    ForEach(meeting.actionItems) { item in
                        actionItemRow(item)
                    }
                }
            }
        }
    }

    private var decisionsCard: some View {
        detailCard(
            title: "Decisions",
            icon: "checkmark.seal",
            subtitle: "Confirmed outcomes"
        ) {
            if meeting.decisions.isEmpty {
                emptyState("No decisions were captured.")
            } else {
                VStack(spacing: 12) {
                    ForEach(meeting.decisions) { decision in
                        itemRow(
                            title: decision.text,
                            detail: detailMetadata(
                                confidence: decision.confidence,
                                sourceSegment: decision.sourceSegment
                            )
                        )
                    }
                }
            }
        }
    }

    private var risksCard: some View {
        detailCard(
            title: "Risks",
            icon: "exclamationmark.triangle",
            subtitle: "Potential blockers"
        ) {
            emptyState("No risk data is stored for this meeting yet.")
        }
    }

    private var openQuestionsCard: some View {
        detailCard(
            title: "Open Questions",
            icon: "questionmark.circle",
            subtitle: "Items needing follow-up"
        ) {
            if meeting.openQuestions.isEmpty {
                emptyState("No open questions remain.")
            } else {
                VStack(spacing: 12) {
                    ForEach(meeting.openQuestions) { question in
                        itemRow(
                            title: question.text,
                            detail: detailMetadata(
                                confidence: question.confidence,
                                sourceSegment: question.sourceSegment
                            )
                        )
                    }
                }
            }
        }
    }

    private var transcriptCard: some View {
        detailCard(
            title: "Transcript",
            icon: "quote.bubble",
            subtitle: "Full reference"
        ) {
            Text(nonEmpty(meeting.transcript, fallback: "No transcript available yet."))
                .font(.body)
                .lineSpacing(5)
                .textSelection(.enabled)
                .themeSecondaryText()
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(meeting.processingStatus.accentColor)
                .frame(width: 8, height: 8)

            Text(meeting.processingStatus.displayTitle)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(meeting.processingStatus.accentColor.opacity(0.16))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(meeting.processingStatus.accentColor.opacity(0.32), lineWidth: 1)
        )
        .foregroundStyle(meeting.processingStatus.accentColor)
    }

    private func metricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .themeMutedText()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .themeTitle()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.elevatedSurfaceFill.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.surfaceStroke, lineWidth: 1)
        )
    }

    private func detailCard<Content: View>(
        title: String,
        icon: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .themeTitle()

                    Text(subtitle)
                        .font(.caption)
                        .themeMutedText()
                }
            }

            content()
        }
        .liquidGlassCard()
    }

    @ViewBuilder
    private func actionItemRow(_ item: ActionItem) -> some View {
        if isEditing {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.task)
                    .font(.body.weight(.semibold))
                    .themeTitle()

                VStack(alignment: .leading, spacing: 8) {
                    editableField(
                        title: "Owner",
                        text: Binding(
                            get: { actionOwnerDrafts[item.id, default: item.owner] },
                            set: { actionOwnerDrafts[item.id] = $0 }
                        ),
                        placeholder: "Assign owner"
                    )

                    editableField(
                        title: "Deadline",
                        text: Binding(
                            get: { actionDeadlineDrafts[item.id, default: item.deadlineText] },
                            set: { actionDeadlineDrafts[item.id] = $0 }
                        ),
                        placeholder: "Add deadline"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedSurfaceFill.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.surfaceStroke.opacity(0.9), lineWidth: 1)
            )
        } else {
            itemRow(
                title: item.task,
                detail: actionItemDetail(for: item)
            )
        }
    }

    private func itemRow(title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.semibold))
                .themeTitle()

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.footnote)
                    .themeMutedText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.elevatedSurfaceFill.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.surfaceStroke.opacity(0.9), lineWidth: 1)
        )
    }

    private func emptyState(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .themeMutedText()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.elevatedSurfaceFill.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.surfaceStroke.opacity(0.75), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            )
    }

    private func editableField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .themeMutedText()

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.surfaceFill.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.surfaceStroke, lineWidth: 1)
                )
                .themeTitle()
        }
    }

    private func actionItemDetail(for item: ActionItem) -> String? {
        let owner = item.owner.isEmpty ? nil : "Owner: \(item.owner)"
        let deadline = item.deadlineText.isEmpty ? nil : "Due: \(item.deadlineText)"
        let metadata = detailMetadata(confidence: item.confidence, sourceSegment: item.sourceSegment)

        return [owner, deadline, metadata]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "  •  ")
    }

    private func detailMetadata(confidence: Double, sourceSegment: String) -> String? {
        let confidenceText: String?
        if confidence > 0 {
            confidenceText = "Confidence: \(Int((confidence * 100).rounded()))%"
        } else {
            confidenceText = nil
        }

        let sourceText = sourceSegment.isEmpty ? nil : sourceSegment

        return [confidenceText, sourceText]
            .compactMap { $0 }
            .joined(separator: "  •  ")
    }

    private var formattedDuration: String {
        let duration = max(Int(meeting.durationSeconds.rounded()), 0)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func nonEmpty(_ text: String, fallback: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : text
    }

    private func loadDraftsFromMeeting() {
        draftSummary = meeting.summary
        actionOwnerDrafts = Dictionary(
            uniqueKeysWithValues: meeting.actionItems.map { ($0.id, $0.owner) }
        )
        actionDeadlineDrafts = Dictionary(
            uniqueKeysWithValues: meeting.actionItems.map { ($0.id, $0.deadlineText) }
        )
    }

    private func beginEditing() {
        loadDraftsFromMeeting()
        saveErrorMessage = nil
        isEditing = true
    }

    private func cancelEditing() {
        loadDraftsFromMeeting()
        saveErrorMessage = nil
        isEditing = false
    }

    private func saveEdits() {
        meeting.summary = draftSummary.trimmingCharacters(in: .whitespacesAndNewlines)

        for item in meeting.actionItems {
            item.owner = actionOwnerDrafts[item.id, default: item.owner].trimmingCharacters(in: .whitespacesAndNewlines)
            item.deadlineText = actionDeadlineDrafts[item.id, default: item.deadlineText].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        meeting.updatedAt = .now

        do {
            try modelContext.save()
            saveErrorMessage = nil
            isEditing = false
            loadDraftsFromMeeting()
        } catch {
            saveErrorMessage = "The changes could not be saved."
        }
    }

    private func copyRecap() {
        UIPasteboard.general.string = shareText
        copyConfirmationMessage = "Recap copied."

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if copyConfirmationMessage == "Recap copied." {
                copyConfirmationMessage = nil
            }
        }
    }

    private var shareText: String {
        var lines: [String] = [meeting.title]

        lines.append("")
        lines.append("Summary")
        lines.append(nonEmpty(meeting.summary, fallback: "No summary available yet."))

        if !meeting.actionItems.isEmpty {
            lines.append("")
            lines.append("Action Items")
            lines.append(contentsOf: meeting.actionItems.map { item in
                var row = "- \(item.task)"

                if !item.owner.isEmpty {
                    row += " | Owner: \(item.owner)"
                }

                if !item.deadlineText.isEmpty {
                    row += " | Due: \(item.deadlineText)"
                }

                return row
            })
        }

        return lines.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack {
        MeetingDetailView(meeting: SampleMeetingData.previewMeeting)
    }
    .modelContainer(SampleMeetingData.previewContainer)
}
