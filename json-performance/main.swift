//
//  main.swift
//  json-performance
//
//  Created by Jeremy Wiebe on 2018-11-11.
//  Copyright © 2018 Jeremy Wiebe. All rights reserved.
//

import Foundation
import Darwin

let DEFAULT_ITERATIONS = UInt64(100_000)

protocol Init {
	init()
}

protocol JsonTest: class, Init {
	func deserialize(data: Data) -> Any
	func serialize(json: Any) -> Data
}

let tests: [JsonTest.Type] = [
	JSONSerializationTest.self,
	CodableTest.self
]

let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

if (arguments.count < 1 || arguments.count > 2) {
	print("Usage: \(ProcessInfo.processInfo.arguments.first!) <data_directory> [iterations]")
	print("  <data_directory>  directory with JSON files to test with")
	print("  iterations        the number of times to test each operation (default: \(DEFAULT_ITERATIONS))")
	exit(0)
}

let dataDirectory: String = arguments[0]
let iterations: UInt64 = arguments.count == 2 ? UInt64(arguments[1])! : DEFAULT_ITERATIONS

let fm = FileManager()

struct TestFileTiming {
	let path: String
	let fileSize: UInt64
	let timings: [UInt64]
}

typealias TestTiming = [String: [TestFileTiming]]

struct Timings {
	var serialize: TestTiming = [:]
	var deserialize: TestTiming = [:]
}

func calculate(description: String, testTiming: TestTiming) {
	print("  == \(description) \(String(repeating: "=", count: 60 - description.count))")
	for (_, timings) in testTiming {

		for fileTiming in timings {
			let totalTimeNS = UInt64(fileTiming.timings.reduce(
				UInt64(0),
				{ result, t in result + t }
			))

			let mb = (Double(iterations * fileTiming.fileSize) / Double(1024) / Double(1024))
			let totalTimeInSeconds = Double(totalTimeNS) / Double(1e9)
			let throughputInMbps = mb / Double(totalTimeInSeconds)

			let header = "\(fileTiming.path) (\(fileTiming.fileSize) bytes)"
			
			let formattedMbps = String(format: "%.2f", throughputInMbps)
			let padding = String(repeating: " ", count: 50 - header.count - formattedMbps.count)
			let paddedMbps = padding + formattedMbps

			print("  \(header) \(paddedMbps) MB/s")
		}

		print()
	}
}

func measureBlock(_ block: () -> Any) -> [UInt64] {
	var timings: [UInt64] = []
	for _ in 0..<iterations  {
		var timer = Timer()
		timer.start()
		let _ = block()
		timer.stop()

		timings.append(timer.nanoseconds)
	}

	return timings
}


let formatter = NumberFormatter()
formatter.numberStyle = .decimal
print("Running tests with \(formatter.string(from: NSNumber(value: iterations))!) iterations")
print()
for testClass in tests {
	let testDescription = String(describing: testClass)
		.replacingOccurrences(of: "Test", with: "")

	var allTimings = Timings(serialize: [:], deserialize: [:])
	allTimings.deserialize[testDescription] = []
	allTimings.serialize[testDescription] = []

	print("Test: \(testDescription)", terminator: "")

	let tester = testClass.init()
	for dataFile in try! fm.contentsOfDirectory(atPath: dataDirectory).sorted() {
		let jsonFilePath = URL(fileURLWithPath: dataDirectory).appendingPathComponent(dataFile)

		let attr = try fm.attributesOfItem(atPath: jsonFilePath.path)
		let fileSize = NSDictionary(dictionary: attr).fileSize()


		let data = try! Data(
			contentsOf: jsonFilePath
		)

		print(".", terminator: "")
		allTimings.deserialize[testDescription]?.append(
			TestFileTiming(
				path: dataFile,
				fileSize: fileSize,
				timings: measureBlock { tester.deserialize(data: data) }
			)
		)

		print(".", terminator: "")
		let objToSerialize = tester.deserialize(data: data)
		allTimings.serialize[testDescription]?.append(
			TestFileTiming(
				path: dataFile,
				fileSize: fileSize,
				timings: measureBlock { tester.serialize(json: objToSerialize) }
			)
		)
	}
	print()
	print()

	calculate(description: "Serializing...", testTiming: allTimings.serialize)
	calculate(description: "Deserializing...", testTiming: allTimings.deserialize)
}
