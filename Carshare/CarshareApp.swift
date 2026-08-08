import SwiftUI

@main
struct CarshareApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                .tint(Palette.accent)
        }
    }
}
