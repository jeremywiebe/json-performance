//
//  main.swift
//  json-performance
//
//  Created by Jeremy Wiebe on 2018-11-11.
//  Copyright © 2018 Jeremy Wiebe. All rights reserved.
//

import Foundation
import Darwin

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
	print("  iterations        the number of times to test each operation (default: 1000)")
	exit(0)
}

let dataDirectory: String = arguments[0]
let iterations: Int = arguments.count == 2 ? Int(arguments[1])! : 1000

let fm = FileManager()

typealias TestFileTiming = [dispatch_time_t]
typealias TestTiming = [String: TestFileTiming]

// Keyed by: Test Type
var timings: [String: TestTiming] = [:]

for testClass in tests {
	let testDescription = String(describing: testClass)
	
	print("Test: \(testDescription)")

	timings[testDescription] = [:]

	let tester = testClass.init()

	for dataFile in try! fm.contentsOfDirectory(atPath: dataDirectory).sorted() {
		let jsonFilePath = URL(fileURLWithPath: dataDirectory)

		print("  Processing: \(dataFile)")

		timings[testDescription]![dataFile] = []

		let data = try! Data(
			contentsOf: jsonFilePath.appendingPathComponent(dataFile)
		)

		// We'll populate this on the first pass of the test and use it in
		// deserialize tests
		var objToSerialize: Any?

		for _ in 0..<iterations  {
			let start = DispatchTime.now()
			let obj = tester.deserialize(data: data)
			let end = DispatchTime.now()

			if objToSerialize == nil { objToSerialize = obj }
			timings[testDescription]![dataFile]!.append(end.rawValue - start.rawValue)
		}
	}


	let timingJson = try! JSONSerialization.data(withJSONObject: timings,
													options: [.prettyPrinted])
	try! timingJson.write(to: URL(string: "file:///Users/jeremy/Desktop/json-timings.json")!)
}
