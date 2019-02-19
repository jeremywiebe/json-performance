//
//  JsonCodable.swift
//  json-performance
//
//  Created by Jeremy Wiebe on 2018-11-12.
//  Copyright © 2018 Jeremy Wiebe. All rights reserved.
//

import Foundation

struct DecodeError: Error { }

struct Message: Codable {
	enum CodingKeys: CodingKey {
		case method
		case params
	}

	enum NestedCodingKeys: CodingKey {
		case method
		case params
		case viewId
	}

	let viewId: String
	let operation: Operation

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let superDecoder = try container.superDecoder(forKey: .params)
		let paramsContainer = try superDecoder.container(keyedBy: NestedCodingKeys.self)
		viewId = try paramsContainer.decode(String.self, forKey: .viewId)

		let m = try container.decode(String.self, forKey: .method)
		switch (m) {
		case "edit":
			operation = .edit(try EditOperation.init(from: superDecoder))
		case "available_plugins":
			operation = .availablePlugins(try AvailablePluginParams.init(from: superDecoder))
		case "config_changed":
			operation = .configChanged(try ConfigChangedParams.init(from: superDecoder))
		case "update":
			operation = .update(try UpdateParams.init(from: superDecoder))
		default:
			print("Could not decode for method: '\(m)'")
			throw DecodeError()
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		let superEncoder = container.superEncoder(forKey: .params)
		var paramsContainer = superEncoder.container(keyedBy: NestedCodingKeys.self)
		try paramsContainer.encode(viewId, forKey: .viewId)

		switch (operation) {
		case .edit(let op):
			try container.encode("edit", forKey: .method)
			try op.encode(to: superEncoder)
		case .availablePlugins(let params):
			try container.encode("available_plugins", forKey: .method)
			try params.encode(to: superEncoder)
		case .configChanged(let params):
			try container.encode("config_changed", forKey: .method)
			try params.encode(to: superEncoder)
		case .update(let params):
			try container.encode("update", forKey: .method)
			try params.encode(to: superEncoder)
		}
	}
}

enum Operation {
	case edit(EditOperation)
	case availablePlugins(AvailablePluginParams)
	case configChanged(ConfigChangedParams)
	case update(UpdateParams)
}

enum EditOperation {
	case resize(EditResizeParams)
	case paste(EditPasteParams)
}

extension EditOperation: Codable {
	enum CodingKeys: CodingKey {
		case method
		case params
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch (try container.decode(String.self, forKey: .method)) {
		case "resize":
			self = .resize(try container.decode(EditResizeParams.self, forKey: .params))
		case "paste":
			self = .paste(try container.decode(EditPasteParams.self, forKey: .params))
		default:
			throw DecodeError()
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch(self) {
		case .resize(let params):
			try container.encode("resize", forKey: .method)
			try container.encode(params, forKey: .params)
		case .paste(let params):
			try container.encode("paste", forKey: .method)
			try container.encode(params, forKey: .params)
		}
	}
}

struct EditResizeParams: Codable {
	let height: Int
	let width: Int
}

struct EditPasteParams: Codable {
	let chars: String
}

struct AvailablePluginParams: Codable {
	let plugins: [String]
}

struct ConfigChangedParams: Codable {
	let changes: EditorConfiguration
}

struct EditorConfiguration: Codable {
	let autoIndent: Bool
	let autodetectWhitespace: Bool
	let fontFace: String
	let fontSize: Int
	let lineEnding: String
	let pluginSearchPath: [String]
	let scrollPastEnd: Bool
	let surroundingPairs: [[String]] // TODO: Enforce inner item as a pair!
	let tabSize: Int
	let translateTabsToSpaces: Bool
	let unifiedToolbar: Bool
	let useTabStops: Bool
	let wordWrap: Bool
	let wrapWidth: Int
}

struct UpdateParams: Codable {
	let update: Update
}

struct Update: Codable {
	let ops: [UpdateOperation]
	let pristine: Bool
}

enum UpdateOperation {
	case Invalidate(InvalidateParams)
	case Skip(SkipParams)
	case Copy(CopyParams)
	case Insert(InsertParams)
}

extension UpdateOperation: Codable {
	enum CodingKeys: CodingKey {
		case n
		case op
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let m = try container.decode(String.self, forKey: .op)
		let n = try container.decode(Int.self, forKey: .n)

		switch (m) {
		case "invalidate":
			self = .Invalidate(InvalidateParams(n: n))
		case "skip":
			self = .Skip(SkipParams.init(n: n))
		case "copy":
			self = .Copy(CopyParams.init(n: n))
		case "ins":
			self = .Insert(try InsertParams.init(from: decoder))
		default:
			print("Did not handle decoding from operation: \(m)")
			throw DecodeError()
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let superEncoder = container.superEncoder()

		switch self {
		case .Invalidate(let params):
			try container.encode("invalidate", forKey: .op)
			try params.encode(to: superEncoder)
		case .Skip(let params):
			try container.encode("skip", forKey: .op)
			try params.encode(to: superEncoder)
		case .Copy(let params):
			try container.encode("copy", forKey: .op)
			try params.encode(to: superEncoder)
		case .Insert(let params):
			try container.encode("ins", forKey: .op)
			try params.encode(to: superEncoder)
		}
	}
}

struct InvalidateParams: Codable {
	let n: Int
}

struct SkipParams: Codable {
	let n: Int
}

struct CopyParams: Codable {
	let n: Int
}

struct InsertParams: Codable {
	let n: Int
	let lines: [Line]
}

struct Line: Codable {
	let styles: [Int]
	let text: String
}

class JsonCodableTest: JsonTest {
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	required init() {
		decoder.keyDecodingStrategy = .convertFromSnakeCase
	}

	func deserialize(data: Data) -> Any {
		do {
			return try decoder.decode(Message.self, from: data)
		} catch {
			print("Error!!! \(error)" )
		}

		return ""
	}

	func serialize(json: Any) -> Data {
		if let message = json as? Message {
			return try! encoder.encode(message)
		}

		return Data(count: 0)
	}
}
