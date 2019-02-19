//
//  main.swift
//  json-performance
//
//  Created by Jeremy Wiebe on 2018-11-11.
//  Copyright © 2018 Jeremy Wiebe. All rights reserved.
//

import Foundation
import Darwin

let DEFAULT_ITERATIONS = 100_000

protocol Init {
	init()
}

enum TestData: String {
	case One = "1.json"
	case Two = "2.json"
	case Three = "3.json"
	case Four = "4.json"
	case Five = "5-paste-whole-file:send.json"
}

protocol JsonTest: class, Init {
	func deserialize(data: Data) -> Any
	func serialize(json: Any) -> Data
}

let tests: [JsonTest.Type] = [
	JSONSerializationTest.self,
	JsonCodableTest.self
]

let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())

if (arguments.count < 1 || arguments.count > 2) {
	print("Usage: \(ProcessInfo.processInfo.arguments.first!) <data_directory> [iterations]")
	print("  <data_directory>  directory with JSON files to test with")
	print("  iterations        the number of times to test each operation (default: \(DEFAULT_ITERATIONS))")
	exit(0)
}

let dataDirectory: String = arguments[0]
let iterations: Int = arguments.count == 2 ? Int(arguments[1])! : DEFAULT_ITERATIONS

let fm = FileManager()

struct TestFileTiming {
	let path: String
	let fileSize: UInt64
	let timings: [dispatch_time_t]
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
			var minNS: UInt64 = 0, maxNS: UInt64 = 0

			let totalTimeNS = UInt64(fileTiming.timings.reduce(
				UInt64(0),
				{ result, t in
					minNS = min(minNS, t)
					maxNS = max(maxNS, t)
					return result + t
				}
			)) - maxNS - minNS

			let effectiveIterations = UInt64(iterations - 2)

			let mb = (Double(effectiveIterations * fileTiming.fileSize) / Double(1024) / Double(1024))
			let totalTimeInSeconds = Double(totalTimeNS) / Double(1e9)
			let throughputInMbps = mb / Double(totalTimeInSeconds)

			let header = "\(fileTiming.path) (\(fileTiming.fileSize) bytes)"
			
			let formattedMbps = String(format: "%.2f", throughputInMbps)
			let padding = String(repeating: " ", count: 54 - header.count - formattedMbps.count)
			let paddedMbps = padding + formattedMbps

			print("\(header) \(paddedMbps) MB/s")
		}

		print()
	}
}


for testClass in tests {
	// Keyed by: Test Type
	var allTimings = Timings(serialize: [:], deserialize: [:])

	let testDescription = String(describing: testClass).replacingOccurrences(of: "Test", with: "")
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
		var t: [dispatch_time_t] = []
		for _ in 0..<iterations  {
			var timer = Timer()
			timer.start()
			let _ = tester.deserialize(data: data)
			timer.stop()

			t.append(timer.nanoseconds)
		}
		allTimings.deserialize[testDescription]?.append(
			TestFileTiming(path: dataFile, fileSize: fileSize, timings: t)
		)

		print(".", terminator: "")
		let objToSerialize = tester.deserialize(data: data)
		t = []
		for _ in 0..<iterations {
			var timer = Timer()
			timer.start()
			let _ = tester.serialize(json: objToSerialize)
			timer.stop()

			t.append(timer.nanoseconds)
		}
		allTimings.serialize[testDescription]?.append(
			TestFileTiming(path: dataFile, fileSize: fileSize, timings: t)
		)
	}
	print()
	print()

	calculate(description: "Serializing...", testTiming: allTimings.serialize)
	calculate(description: "Deserializing...", testTiming: allTimings.deserialize)

	print()
	print()
}
