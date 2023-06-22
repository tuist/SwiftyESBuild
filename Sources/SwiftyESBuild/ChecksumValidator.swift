import Foundation
import TSCBasic

protocol ChecksumValidating {
    func validate(checksum: String, file: AbsolutePath) async throws
}

// TODO:
//  - Checksum validation response["versions"][version]["dist"]
//                                "integrity": "sha512-xoOZQRQJogDsoU6ZUq2irotU4N3BFDAvjEDPWXVWlrkZzZa17AidAf/r8wrjTbZqdZ0RDgV90o1ROrf2JZtVEQ==",
//                                "shasum": "1d600df3fb6865bc7ce53958306f7e8c4ec975b6",
//                                "tarball": "https://registry.npmjs.org/@esbuild/darwin-arm64/-/darwin-arm64-0.15.18.tgz",
//                                "fileCount": 3,
//                                "unpackedSize": 8740102,
//                                "signatures": [
//                                  {
//                                    "keyid": "SHA256:jl3bwswu80PjjokCgh0o2w5c2U4LhQAE57gj9cz1kzA",
//                                    "sig": "MEUCIQCc9642UtsMnlXsDCQlcYN7dpirPv8V/p+J5lDNR5++AgIgTlN4Fb12L3Bzu4NoHrF8yOcF8/HMFaHx0hKOqJoWo9M="
//                                  }
//                                ],
