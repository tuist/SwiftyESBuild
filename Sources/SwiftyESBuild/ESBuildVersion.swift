import Foundation

/**
 A enum that represents the version of ESBuild that you want to use.
 */
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
