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

	func deserialize(data: Data) -> Message {
		return Message.fromJson(data: data)
	}

	func serialize(message: Message) -> Data {
		return try! JSONSerialization.data(withJSONObject: message.toJson(),
										   options: [])
	}
}

extension Message {
	static func fromJson(data: Data) -> Message {
		let json = try! JSONSerialization.jsonObject(
			with: data,
			options: []) as! [String: Any]

		let method = json["method"] as! String
		let params = json["params"] as! [String: Any]
		let viewId = params["view_id"] as! String

		var op: Operation
		switch method {
		case "edit":
			op = .edit(EditOperation.fromJson(json: params))
		case "available_plugins":
			op = .availablePlugins(AvailablePluginParams.fromJson(json: params))
		case "config_changed":
			op = .configChanged(ConfigChangedParams.fromJson(json: params))
		case "update":
			op = .update(UpdateParams.fromJson(json: params))
		default:
			fatalError()
		}

		return Message(viewId: viewId, operation: op)
	}

	func toJson() -> [String: Any] {
		var json: [String: Any] = [:]

		var jsonParams = [String: Any]()
		json["params"] = jsonParams
		jsonParams["view_id"] = self.viewId

		switch self.operation {
		case let .edit(op):
			json["method"] = "edit"

			var editParams = [String: Any]()
			jsonParams["params"] = editParams

			switch op {
			case let .paste(params):
				jsonParams["method"] = "paste"
				editParams["chars"] = params.chars

			case let .resize(params):
				jsonParams["method"] = "resize"
				editParams["height"] = params.height
				editParams["width"] = params.width
			}

		case let .availablePlugins(params):
			json["method"] = "available_plugins"
			jsonParams["plugins"] = params.plugins

		case let .configChanged(params):
			json["method"] = "config_changed"
			var changes = [String: Any]()
			jsonParams["changes"] = changes
			changes["auto_indent"] = params.changes.autoIndent
			changes["autodetect_whitespace"] = params.changes.autodetectWhitespace
			changes["font_face"] = params.changes.fontFace
			changes["font_size"] = params.changes.fontSize
			changes["line_ending"] = params.changes.lineEnding
			changes["plugin_search_path"] = params.changes.pluginSearchPath
			changes["scroll_past_end"] = params.changes.scrollPastEnd
			changes["surrounding_pairs"] = params.changes.surroundingPairs
			changes["tab_size"] = params.changes.tabSize
			changes["translate_tabs_to_spaces"] = params.changes.translateTabsToSpaces
			changes["unified_toolbar"] = params.changes.unifiedToolbar
			changes["use_tab_stops"] = params.changes.useTabStops
			changes["word_wrap"] = params.changes.wordWrap
			changes["wrap_width"] = params.changes.wrapWidth

		case let .update(params):
			json["method"] = "update"
			var update = [String: Any]()
			jsonParams["update"] = update

			let ops = params.update.ops.map { op in
				var opJson = [String: Any]()
				switch op {
				case let .Copy(params):
					opJson["op"] = "copy"
					opJson["n"] = params.n

				case let .Insert(params):
					opJson["op"] = "ins"
					opJson["n"] = params.n
					let lines = params.lines.map { line in
						var l = [String: Any]()
						l["styles"] = line.styles
						l["text"] = line.text
					}
					opJson["lines"] = lines

				case let .Invalidate(params):
					opJson["op"] = "invalidate"
					opJson["n"] = params.n

				case let .Skip(params):
					opJson["op"] = "skip"
					opJson["n"] = params.n
				}
			}
			update["ops"] = ops
		}

		return json
	}
}

extension EditOperation {
	static func fromJson(json: [String: Any]) -> EditOperation {
		let method = json["method"] as! String
		let params = json["params"] as! [String: Any]

		switch method {
		case "resize":
			let height = params["height"] as! Int
			let width = params["width"] as! Int
			return .resize(EditResizeParams(height: height, width: width))
		case "paste":
			return .paste(EditPasteParams(chars: params["chars"] as! String))
		default:
			fatalError()
		}
	}
}

extension Operation {
	static func fromJson(json: [String: Any]) -> Operation {
		let changes = json["changes"] as! [String: Any]

		return .configChanged(ConfigChangedParams(
			changes: EditorConfiguration(
				autoIndent: changes["auto_indent"] as! Bool,
				autodetectWhitespace: changes["autodetect_whitespace"] as! Bool,
				fontFace: changes["font_face"] as! String,
				fontSize: changes["font_size"] as! Int,
				lineEnding: changes["line_ending"] as! String,
				pluginSearchPath: changes["plugin_search_path"] as! [String],
				scrollPastEnd: changes["scroll_past_end"] as! Bool,
				surroundingPairs: changes["surrounding_pairs"] as! [[String]],
				tabSize: changes["tab_size"] as! Int,
				translateTabsToSpaces: changes["translate_tabs_to_spaces"] as! Bool,
				unifiedToolbar: changes["unified_toolbar"] as! Bool,
				useTabStops: changes["use_tab_stops"] as! Bool,
				wordWrap: changes["word_wrap"] as! Bool,
				wrapWidth: changes["wrap_width"] as! Int
			)
		))
	}

	static func parseUpdateNotification(params: [String: Any]) -> Operation {
		let updateParams = params["update"] as! [String: Any]
		let opsJson = updateParams["ops"] as! [[String: Any]]

		let ops = opsJson.map { json -> UpdateOperation in
			let op = json["op"] as! String
			let n = json["n"] as! Int

			switch op {
			case "invalidate":
				return .Invalidate(InvalidateParams(n: n))
			case "skip":
				return .Skip(SkipParams(n: n))
			case "copy":
				return .Copy(CopyParams(n: n))
			case "ins":
				let jsonLines = json["lines"] as! [[String: Any]]
				let lines = jsonLines.map { lineJson -> Line in
					return Line(styles: lineJson["styles"] as! [Int],
								text: lineJson["text"] as! String)
				}

				return .Insert(InsertParams(
					n: n,
					lines: lines
				))
			default:
				fatalError()
			}
		}

		return .update(UpdateParams(update: Update(
			ops: ops,
			pristine: params["pristine"] as! Bool
		)))
	}
}

extension AvailablePluginParams {
	static func fromJson(json: [String: Any]) -> AvailablePluginParams {
		return AvailablePluginParams(plugins: json["plugins"] as! [String])
	}
}

extension ConfigChangedParams {
	static func fromJson(json: [String: Any]) -> ConfigChangedParams {
		return ConfigChangedParams(
			changes: EditorConfiguration.fromJson(
				json: json["changes"] as! [String: Any]
			)
		)
	}
}

extension EditorConfiguration {
	static func fromJson(json: [String: Any]) -> EditorConfiguration {
		return EditorConfiguration(
			autoIndent: json["auto_indent"] as! Bool,
			autodetectWhitespace: json["autodetect_whitespace"] as! Bool,
			fontFace: json["font_face"] as! String,
			fontSize: json["font_size"] as! Int,
			lineEnding: json["line_ending"] as! String,
			pluginSearchPath: json["plugin_search_path"] as! [String],
			scrollPastEnd: json["scroll_past_end"] as! Bool,
			surroundingPairs: json["surrounding_pairs"] as! [[String]],
			tabSize: json["tab_size"] as! Int,
			translateTabsToSpaces: json["translate_tabs_to_spaces"] as! Bool,
			unifiedToolbar: json["unified_toolbar"] as! Bool,
			useTabStops: json["use_tab_stops"] as! Bool,
			wordWrap: json["word_wrap"] as! Bool,
			wrapWidth: json["wrap_width"] as! Int
		)
	}
}

extension UpdateParams {
	static func fromJson(json: [String: Any]) -> UpdateParams {
		return UpdateParams(update: Update.fromJson(json: json["update"] as! [String: Any]))
	}
}

extension Update {
	static func fromJson(json: [String: Any]) -> Update {
		return Update(
			ops: (json["ops"] as! [[String: Any]]).map { opJson in
				let op = opJson["op"] as! String
				let n = opJson["n"] as! Int

				switch op {
				case "invalidate":
					return .Invalidate(InvalidateParams(n: n))
				case "skip":
					return .Skip(SkipParams(n: n))
				case "copy":
					return .Copy(CopyParams(n: n))
				case "ins":
					let jsonLines = opJson["lines"] as! [[String: Any]]
					let lines = jsonLines.map { lineJson -> Line in
						return Line(styles: lineJson["styles"] as! [Int],
									text: lineJson["text"] as! String)
					}

					return .Insert(InsertParams(
						n: n,
						lines: lines
					))
				default:
					fatalError()
				}
			},
			pristine: json["pristine"] as! Bool)
	}
}
