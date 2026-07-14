import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var circleService: CircleService
    @StateObject private var store = PreviewStore()

    var body: some View {
        Group {
            if !authSession.isFirebaseConfigured {
                FirebaseSetupRequiredView()
            } else if authSession.isLoading {
                ProgressView("Checking your account…")
            } else if !appState.hasCompletedOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.completeOnboarding()
                    }
                }
            } else if authSession.user == nil {
                SignInView()
            } else {
                MainTabView(store: store)
            }
        }
        .preferredColorScheme(nil)
        .task(id: authSession.user?.uid) {
            circleService.observeCircles(for: authSession.user?.uid)
        }
        .sheet(isPresented: invitationSheetBinding) {
            JoinInvitationView(initialCode: appState.pendingInvitationCode ?? "") {
                appState.pendingInvitationCode = nil
            }
            .environmentObject(circleService)
        }
    }

    private var invitationSheetBinding: Binding<Bool> {
        Binding(
            get: {
                authSession.user != nil && appState.pendingInvitationCode != nil
            },
            set: { isPresented in
                if !isPresented {
                    appState.pendingInvitationCode = nil
                }
            }
        )
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var store: PreviewStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .map:
                    HarborMapView(store: store)
                case .journey:
                    JourneyDashboardView(store: store)
                case .activity:
                    ActivityTimelineView(store: store)
                case .you:
                    YouView(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HarborTabBar(selection: $appState.selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

private struct HarborTabBar: View {
    @Binding var selection: AppState.Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppState.Tab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selection == tab ? HarborColors.calmTeal : HarborColors.slate)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(selection == tab ? HarborColors.seaGlass.opacity(0.75) : .clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(HarborColors.mineralBorder.opacity(0.7), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.10), radius: 20, y: 8)
    }
}
