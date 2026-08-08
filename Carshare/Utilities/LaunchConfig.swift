import Foundation

// MARK: - Launch configuration
//
// Lets an outside process open the app directly on a given screen:
//
//     xcrun simctl launch booted com.prototype.carshare -startScreen trips
//
// UserDefaults picks up `-key value` launch arguments automatically, so no argument
// parsing is needed. CI uses this to screenshot every tab without driving taps, and
// it's handy for jumping straight to a screen you're working on.

enum LaunchConfig {

    enum StartScreen: String {
        case welcome
        case explore
        case saved
        case trips
        case inbox
        case profile
        case host
        case hostListings
        case hostRequests
        case hostEarnings

        var isHost: Bool {
            switch self {
            case .host, .hostListings, .hostRequests, .hostEarnings: true
            default: false
            }
        }

        var appTab: AppTab? {
            switch self {
            case .explore: .explore
            case .saved: .favourites
            case .trips: .trips
            case .inbox: .inbox
            case .profile: .profile
            default: nil
            }
        }

        var hostTab: HostTab? {
            switch self {
            case .host: .dashboard
            case .hostListings: .listings
            case .hostRequests: .requests
            case .hostEarnings: .earnings
            default: nil
            }
        }
    }

    static var startScreen: StartScreen? {
        guard let raw = UserDefaults.standard.string(forKey: "startScreen") else { return nil }
        return StartScreen(rawValue: raw)
    }

    /// True when the app should skip the welcome screen. Any explicit start screen
    /// other than `welcome` implies it.
    static var skipsWelcome: Bool {
        guard let screen = startScreen else { return false }
        return screen != .welcome
    }
}
