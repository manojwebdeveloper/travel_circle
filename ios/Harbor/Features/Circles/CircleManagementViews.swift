import SwiftUI

struct CircleHubView: View {
    @EnvironmentObject private var circleService: CircleService
    @State private var showingCreate = false
    @State private var showingJoin = false

    var body: some View {
        List {
            if circleService.circles.isEmpty && !circleService.isLoading {
                Section {
                    ContentUnavailableView {
                        Label("No circles yet", systemImage: "person.3")
                    } description: {
                        Text("Create a family or trip circle, or join someone you trust with an invitation code.")
                    } actions: {
                        Button("Create circle") { showingCreate = true }
                            .buttonStyle(.borderedProminent)
                        Button("Join circle") { showingJoin = true }
                            .buttonStyle(.bordered)
                    }
                }
            } else {
                Section("Your circles") {
                    ForEach(circleService.circles) { circle in
                        NavigationLink {
                            FirebaseCircleDetailView(circle: circle)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: circle.kind == .family ? "person.3.fill" : "suitcase.rolling.fill")
                                    .foregroundStyle(circle.kind == .family ? HarborColors.calmTeal : HarborColors.clearSky)
                                    .frame(width: 34, height: 34)
                                    .background((circle.kind == .family ? HarborColors.seaGlass : HarborColors.clearSky.opacity(0.14)))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(circle.name)
                                        .font(.headline)
                                    HStack(spacing: 6) {
                                        Text(circle.kind.title)
                                        Text("•")
                                        Text(circle.role.capitalized)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let expiresAt = circle.expiresAt {
                                    Text(expiresAt, style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            if let errorMessage = circleService.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(HarborColors.signalRed)
                }
            }
        }
        .navigationTitle("Your circles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Create circle", systemImage: "plus.circle") {
                        showingCreate = true
                    }
                    Button("Join with code", systemImage: "number.square") {
                        showingJoin = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if circleService.isLoading {
                ProgressView()
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack {
                CreateCircleView()
            }
            .environmentObject(circleService)
        }
        .sheet(isPresented: $showingJoin) {
            NavigationStack {
                JoinInvitationView()
            }
            .environmentObject(circleService)
        }
    }
}

struct CreateCircleView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kind: FirebaseCircleSummary.Kind = .family
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Circle type") {
                Picker("Circle type", selection: $kind) {
                    ForEach(FirebaseCircleSummary.Kind.allCases) { kind in
                        Label(
                            kind.title,
                            systemImage: kind == .family ? "person.3.fill" : "suitcase.rolling.fill"
                        )
                        .tag(kind)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Details") {
                TextField(kind == .family ? "The Harris Family" : "Paris Weekend", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if kind == .trip {
                    DatePicker(
                        "Circle ends",
                        selection: $expiresAt,
                        in: Date.now.addingTimeInterval(3_600)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Text("Trip Circle membership and temporary sharing access end automatically at this time.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(HarborColors.signalRed)
                }
            }
        }
        .navigationTitle("Create circle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(isSubmitting)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task { await createCircle() }
                }
                .fontWeight(.semibold)
                .disabled(!isValid || isSubmitting)
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func createCircle() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            _ = try await circleService.createCircle(
                name: name,
                kind: kind,
                expiresAt: kind == .trip ? expiresAt : nil
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct JoinInvitationView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    @State private var code: String
    @State private var preview: InvitationPreview?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let onFinished: () -> Void

    init(initialCode: String = "", onFinished: @escaping () -> Void = {}) {
        _code = State(initialValue: InvitationLink.normalizedCode(initialCode) ?? initialCode)
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Invitation code") {
                    TextField("123456", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(.title2, design: .monospaced, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .onChange(of: code) { _, newValue in
                            code = String(newValue.filter(\.isNumber).prefix(6))
                            if code.count < 6 {
                                preview = nil
                            }
                        }

                    Button("Check invitation") {
                        Task { await lookup() }
                    }
                    .disabled(code.count != 6 || isLoading)
                }

                if let preview {
                    Section("You’re joining") {
                        LabeledContent("Circle", value: preview.circleName)
                        LabeledContent("Type", value: preview.circleKind.title)
                        LabeledContent(
                            "Invitation expires",
                            value: preview.expiresAt.formatted(date: .abbreviated, time: .shortened)
                        )

                        Button("Join circle") {
                            Task { await accept(preview) }
                        }
                        .fontWeight(.semibold)
                        .disabled(isLoading)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(HarborColors.signalRed)
                    }
                }
            }
            .navigationTitle("Join a circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onFinished()
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .task {
                if code.count == 6 {
                    await lookup()
                }
            }
        }
    }

    private func lookup() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            preview = try await circleService.lookupInvitation(code: code)
        } catch {
            preview = nil
            errorMessage = error.localizedDescription
        }
    }

    private func accept(_ preview: InvitationPreview) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await circleService.acceptInvitation(code: preview.code)
            onFinished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FirebaseCircleDetailView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    let circle: FirebaseCircleSummary

    @State private var showingInvitation = false
    @State private var showingDestructiveConfirmation = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Circle") {
                LabeledContent("Type", value: circle.kind.title)
                LabeledContent("Your role", value: circle.role.capitalized)
                if let expiresAt = circle.expiresAt {
                    LabeledContent(
                        "Ends",
                        value: expiresAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            }

            Section("Invite people") {
                Button {
                    showingInvitation = true
                } label: {
                    Label("Create secure invitation", systemImage: "person.badge.plus")
                }
            }

            Section {
                Button(
                    circle.role == "owner" ? "Delete circle" : "Leave circle",
                    role: .destructive
                ) {
                    showingDestructiveConfirmation = true
                }
                .disabled(isWorking)
            } footer: {
                Text(circle.role == "owner"
                     ? "Deleting this circle removes all memberships and active invitations."
                     : "Leaving immediately removes your access to this circle.")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(HarborColors.signalRed)
                }
            }
        }
        .navigationTitle(circle.name)
        .sheet(isPresented: $showingInvitation) {
            NavigationStack {
                InvitationShareView(circle: circle)
            }
            .environmentObject(circleService)
        }
        .confirmationDialog(
            circle.role == "owner" ? "Delete this circle?" : "Leave this circle?",
            isPresented: $showingDestructiveConfirmation,
            titleVisibility: .visible
        ) {
            Button(circle.role == "owner" ? "Delete circle" : "Leave circle", role: .destructive) {
                Task { await performDestructiveAction() }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func performDestructiveAction() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            if circle.role == "owner" {
                try await circleService.deleteCircle(circleID: circle.id)
            } else {
                try await circleService.leaveCircle(circleID: circle.id)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct InvitationShareView: View {
    @EnvironmentObject private var circleService: CircleService
    @Environment(\.dismiss) private var dismiss

    let circle: FirebaseCircleSummary

    @State private var invitation: InvitationDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let invitation {
                    QRCodeView(value: invitation.invitationURL.absoluteString)

                    VStack(spacing: 7) {
                        Text(invitation.code)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .tracking(5)
                        Text("Six-digit fallback code")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text("Invitation to \(invitation.circleName)")
                            .font(.headline)
                        Text("Expires \(invitation.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ShareLink(
                        item: invitation.invitationURL,
                        subject: Text("Join \(invitation.circleName) in Harbor"),
                        message: Text("Open this link in Harbor, scan the QR code, or enter code \(invitation.code).")
                    ) {
                        Label("Share invitation", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    Button("Revoke invitation", role: .destructive) {
                        Task { await revoke(invitation) }
                    }
                } else if isLoading {
                    ProgressView("Creating invitation…")
                        .padding(.top, 80)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(HarborColors.signalRed)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        .navigationTitle("Invite people")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .task {
            guard invitation == nil else { return }
            await createInvitation()
        }
    }

    private func createInvitation() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            invitation = try await circleService.createInvitation(circleID: circle.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func revoke(_ invitation: InvitationDetails) async {
        do {
            try await circleService.revokeInvitation(code: invitation.code)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
