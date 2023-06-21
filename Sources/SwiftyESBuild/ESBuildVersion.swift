import Foundation

public enum ESBuildVersion {
    /**
    It pulls the latest version.
     */
    case latest
    /**
    It pulls a fixed version.
     */
    case fixed(String)
}
