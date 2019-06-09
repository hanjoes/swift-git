@testable import SwiftGitLib
@testable import SwiftPawn
import XCTest
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

private struct TC {
    static let TestRepo = "https://github.com/hanjoes/git.git"
}

class GitRuntimeTests: XCTestCase {

    func testCloneRepo() throws {
        let currentTemp = try makeTempDirectory()
        do {
            try Git.cloneRepo(from: TC.TestRepo, at: currentTemp)
        } catch {
            print(error)
        }
        XCTAssertTrue(Git.isRepo(at: currentTemp))
    }

    func testIsRepo() throws {
        let currentTemp = try makeTempDirectory()
        try Git.cloneRepo(from: TC.TestRepo, at: currentTemp)
        XCTAssertTrue(Git.isRepo(at: currentTemp))
    }

    func testFindRemoteButNoRepo() throws {
        let currentTemp = try makeTempDirectory()
        XCTAssertThrowsError(try Git.findRemotes(at: currentTemp))
    }

    func testFindRemote() throws {
        let currentTemp = try makeTempDirectory()
        try Git.cloneRepo(from: TC.TestRepo, at: currentTemp)
        let remotes = try Git.findRemotes(at: currentTemp)
        XCTAssertGreaterThanOrEqual(1, remotes.count)
        XCTAssertEqual("origin", remotes.first!)
    }

    func testInitialize() throws {
        let currentTemp = try makeTempDirectory()
        try Git.initialize(inDir: currentTemp)
    }

    func testCommit() throws {
        let currentTemp = try makeTempDirectory()
        try Git.initialize(inDir: currentTemp)
        chdir(currentTemp)
        _ = try SwiftPawn.execute(command: "touch", arguments: ["touch", "abc"])
        try Git.add("./abc", at: currentTemp)
        try Git.commit(at: currentTemp, withMessage: "test")
    }


    func testIsModified() throws {
        let currentTemp = try makeTempDirectory()
        try Git.initialize(inDir: currentTemp)
        chdir(currentTemp)
        _ = try SwiftPawn.execute(command: "touch", arguments: ["touch", "abc"])
        try Git.add("./abc", at: currentTemp)
        try Git.commit(at: currentTemp, withMessage: "test")
        let fd = fopen("./abc", "w")
        defer { fclose(fd) }
        fwrite("test", 1, 4, fd)
        fflush(fd)
        XCTAssertTrue(try Git.isModified(at: currentTemp))
    }

    func testCompare() throws {
        let currentTemp = try makeTempDirectory()
        try Git.cloneRepo(from: TC.TestRepo, at: currentTemp)
        XCTAssertEqual(-4, try Git.compare("50685d9342139e", "8925e720d508cca3", at: currentTemp))
        XCTAssertEqual(1, try Git.compare("ef0421b", "f1749a1", at: currentTemp))
        XCTAssertEqual(2, try Git.compare("origin/noremove", "b589c3d", at: currentTemp))
    }


    func testBranchName() throws {
        let currentTemp = try makeTempDirectory()
        try Git.initialize(inDir: currentTemp)
        _ = try SwiftPawn.execute(command: "touch", arguments: ["touch", "abc"])
        let name = try Git.branchName(at: currentTemp)
        XCTAssertEqual("master", name!)
    }

    private func makeTempDirectory() throws -> String {
        var g = SystemRandomNumberGenerator()
        let tempDirectoryPath = "/tmp/GitRuntimeTests-\(g.next())/"
        mkdir(tempDirectoryPath, S_IRWXU)
        return tempDirectoryPath
    }
}