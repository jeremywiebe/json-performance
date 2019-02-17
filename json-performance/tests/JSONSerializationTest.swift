//
//  JSONSerialization.swift
//  json-performance
//
//  Created by Jeremy Wiebe on 2018-11-11.
//  Copyright © 2018 Jeremy Wiebe. All rights reserved.
//

import Foundation

class JSONSerializationTest: JsonTest {
	required init() {}

	func deserialize(data: Data) -> Any {
		return try! JSONSerialization.jsonObject(with: data, options: [])
	}

	func serialize(json: Any) -> Data {
		return try! JSONSerialization.data(withJSONObject: json, options: [])
	}
}
