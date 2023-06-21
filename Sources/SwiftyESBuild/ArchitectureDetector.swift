import Foundation
import TSCBasic
import TSCUtility

// List of architectures: https://github.com/evanw/esbuild/tree/main/npm/%40esbuild

public enum CpuArchitecture: String, Hashable  {
    case arm = "arm"
    case arm64   = "arm64"
    case armv7   = "armv7"
    case x64 = "x64"
    case x86_64   = "x86_64"
    case ia32 = "ia32"
    case loong64 = "loong64"
    case mips64el = "mips64el"
    case ppc64 = "ppc64"
    case riscv64 = "riscv64"
    case s390x = "s390x"
    
    var esbuildValue: String {
        switch self {
        case .arm64: return "arm64"
        case .armv7: return "armv7"
        case .x86_64: return "x64"
        }
    }
}

/**
 A protocol that declares an interface to obtain the CPU architecture of the environment in which the program is running.
 */
protocol ArchitectureDetecting {
    /**
     It returns the architecture if it can be obtained and nil otherwise.
     */
    func architecture() -> CpuArchitecture?
}

class ArchitectureDetector: ArchitectureDetecting {
    func architecture() -> CpuArchitecture? {
        let process = Process(arguments: ["uname", "-m"], outputRedirection: .collect)
        _ = try? process.launch()
        let result = try? process.waitUntilExit()
        let output = try? result?.utf8Output().spm_chomp()
        return CpuArchitecture(rawValue: output ?? "")
    }
}
