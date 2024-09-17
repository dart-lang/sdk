// MIT License
//
// Copyright (c) Microsoft Corporation.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: constant_identifier_names

import 'dart:convert' show JsonEncoder;

import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:language_server_protocol/protocol_generated.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

bool _canParseBool(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && value is! bool) {
      reporter.reportError('must be of type bool');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseElement(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && !Element.canParse(value, reporter)) {
      reporter.reportError('must be of type Element');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseErrorCodes(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        !ErrorCodes.canParse(value, reporter)) {
      reporter.reportError('must be of type ErrorCodes');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseFlutterOutline(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        !FlutterOutline.canParse(value, reporter)) {
      reporter.reportError('must be of type FlutterOutline');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseInsertTextFormat(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        !InsertTextFormat.canParse(value, reporter)) {
      reporter.reportError('must be of type InsertTextFormat');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseInt(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && value is! int) {
      reporter.reportError('must be of type int');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseIntString(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && (value is! int && value is! String)) {
      reporter.reportError('must be of type Either2<int, String>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListClosingLabel(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> ||
            value.any((item) => !ClosingLabel.canParse(item, reporter)))) {
      reporter.reportError('must be of type List<ClosingLabel>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListFlutterOutline(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> ||
            value.any((item) => !FlutterOutline.canParse(item, reporter)))) {
      reporter.reportError('must be of type List<FlutterOutline>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListFlutterOutlineAttribute(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> ||
            value.any(
                (item) => !FlutterOutlineAttribute.canParse(item, reporter)))) {
      reporter.reportError('must be of type List<FlutterOutlineAttribute>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListInt(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> || value.any((item) => item is! int))) {
      reporter.reportError('must be of type List<int>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListOutline(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> ||
            value.any((item) => !Outline.canParse(item, reporter)))) {
      reporter.reportError('must be of type List<Outline>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseListString(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! List<Object?> || value.any((item) => item is! String))) {
      reporter.reportError('must be of type List<String>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseLiteral(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined,
    required bool allowsNull,
    required String literal}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && value != literal) {
      reporter.reportError("must be the literal '$literal'");
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseMapStringListString(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! Map ||
            (value.keys.any((item) =>
                item is! String ||
                value.values.any((item) =>
                    item is! List<Object?> ||
                    item.any((item) => item is! String)))))) {
      reporter.reportError('must be of type Map<String, List<String>>');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseMethod(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && !Method.canParse(value, reporter)) {
      reporter.reportError('must be of type Method');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseOutline(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && !Outline.canParse(value, reporter)) {
      reporter.reportError('must be of type Outline');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseRange(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && !Range.canParse(value, reporter)) {
      reporter.reportError('must be of type Range');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseResponseError(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        !ResponseError.canParse(value, reporter)) {
      reporter.reportError('must be of type ResponseError');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseString(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) && value is! String) {
      reporter.reportError('must be of type String');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseTypeHierarchyAnchor(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        !TypeHierarchyAnchor.canParse(value, reporter)) {
      reporter.reportError('must be of type TypeHierarchyAnchor');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

bool _canParseUri(
    Map<String, Object?> map, LspJsonReporter reporter, String fieldName,
    {required bool allowsUndefined, required bool allowsNull}) {
  reporter.push(fieldName);
  try {
    if (!allowsUndefined && !map.containsKey(fieldName)) {
      reporter.reportError('must not be undefined');
      return false;
    }
    final value = map[fieldName];
    final nullCheck = allowsNull || allowsUndefined;
    if (!nullCheck && value == null) {
      reporter.reportError('must not be null');
      return false;
    }
    if ((!nullCheck || value != null) &&
        (value is! String || Uri.tryParse(value) == null)) {
      reporter.reportError('must be of type Uri');
      return false;
    }
  } finally {
    reporter.pop();
  }
  return true;
}

Either2<int, String> _eitherIntString(Object? value) {
  return value is int
      ? Either2.t1(value)
      : value is String
          ? Either2.t2(value)
          : throw '$value was not one of (int, String)';
}

typedef DocumentUri = Uri;

typedef LSPAny = Object?;

typedef LSPObject = Object;

typedef LSPUri = Uri;

typedef TextDocumentEditEdits
    = List<Either3<AnnotatedTextEdit, SnippetTextEdit, TextEdit>>;

class AnalyzerStatusParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    AnalyzerStatusParams.canParse,
    AnalyzerStatusParams.fromJson,
  );

  final bool isAnalyzing;

  AnalyzerStatusParams({
    required this.isAnalyzing,
  });

  @override
  int get hashCode => isAnalyzing.hashCode;

  @override
  bool operator ==(Object other) {
    return other is AnalyzerStatusParams &&
        other.runtimeType == AnalyzerStatusParams &&
        isAnalyzing == other.isAnalyzing;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['isAnalyzing'] = isAnalyzing;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseBool(obj, reporter, 'isAnalyzing',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type AnalyzerStatusParams');
      return false;
    }
  }

  static AnalyzerStatusParams fromJson(Map<String, Object?> json) {
    final isAnalyzingJson = json['isAnalyzing'];
    final isAnalyzing = isAnalyzingJson as bool;
    return AnalyzerStatusParams(
      isAnalyzing: isAnalyzing,
    );
  }
}

class ClosingLabel implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ClosingLabel.canParse,
    ClosingLabel.fromJson,
  );

  final String label;

  final Range range;

  ClosingLabel({
    required this.label,
    required this.range,
  });
  @override
  int get hashCode => Object.hash(
        label,
        range,
      );

  @override
  bool operator ==(Object other) {
    return other is ClosingLabel &&
        other.runtimeType == ClosingLabel &&
        label == other.label &&
        range == other.range;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['label'] = label;
    result['range'] = range.toJson();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'label',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseRange(obj, reporter, 'range',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type ClosingLabel');
      return false;
    }
  }

  static ClosingLabel fromJson(Map<String, Object?> json) {
    final labelJson = json['label'];
    final label = labelJson as String;
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    return ClosingLabel(
      label: label,
      range: range,
    );
  }
}

/// Information about one of the arguments needed by the command.
///
/// A list of parameters is sent in the `data` field of the `CodeAction`
/// returned by the server. The values of the parameters should appear in the
/// `args` field of the `Command` sent to the server in the same order as the
/// corresponding parameters.
abstract class CommandParameter implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    CommandParameter.canParse,
    CommandParameter.fromJson,
  );

  /// A human-readable label to be displayed in the UI affordance used to prompt
  /// the user for the value of the parameter.
  final String parameterLabel;

  CommandParameter({
    required this.parameterLabel,
  });

  /// An optional default value for the parameter. The type of this value may
  /// vary between parameter kinds but must always be something that can be
  /// converted directly to/from JSON.
  Object? get defaultValue;
  @override
  int get hashCode => parameterLabel.hashCode;

  /// The kind of this parameter. The client may use different UIs based on this
  /// value.
  String get kind;

  @override
  bool operator ==(Object other) {
    return other is CommandParameter &&
        other.runtimeType == CommandParameter &&
        parameterLabel == other.parameterLabel;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['parameterLabel'] = parameterLabel;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseString(obj, reporter, 'parameterLabel',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type CommandParameter');
      return false;
    }
  }

  static CommandParameter fromJson(Map<String, Object?> json) {
    if (SaveUriCommandParameter.canParse(json, nullLspJsonReporter)) {
      return SaveUriCommandParameter.fromJson(json);
    }
    throw ArgumentError(
        'Supplied map is not valid for any subclass of CommandParameter');
  }
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    CompletionItemResolutionInfo.canParse,
    CompletionItemResolutionInfo.fromJson,
  );

  @override
  int get hashCode => 42;

  @override
  bool operator ==(Object other) {
    return other is CompletionItemResolutionInfo &&
        other.runtimeType == CompletionItemResolutionInfo;
  }

  @override
  Map<String, Object?> toJson() => {};

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return true;
    } else {
      reporter.reportError('must be of type CompletionItemResolutionInfo');
      return false;
    }
  }

  static CompletionItemResolutionInfo fromJson(Map<String, Object?> json) {
    if (DartCompletionResolutionInfo.canParse(json, nullLspJsonReporter)) {
      return DartCompletionResolutionInfo.fromJson(json);
    }
    if (PubPackageCompletionItemResolutionInfo.canParse(
        json, nullLspJsonReporter)) {
      return PubPackageCompletionItemResolutionInfo.fromJson(json);
    }
    return CompletionItemResolutionInfo();
  }
}

class ConnectToDtdParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ConnectToDtdParams.canParse,
    ConnectToDtdParams.fromJson,
  );

  final Uri uri;

  ConnectToDtdParams({
    required this.uri,
  });

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) {
    return other is ConnectToDtdParams &&
        other.runtimeType == ConnectToDtdParams &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type ConnectToDtdParams');
      return false;
    }
  }

  static ConnectToDtdParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return ConnectToDtdParams(
      uri: uri,
    );
  }
}

class DartCompletionResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartCompletionResolutionInfo.canParse,
    DartCompletionResolutionInfo.fromJson,
  );

  /// The file where the completion is being inserted.
  ///
  /// This is used to compute where to add the import.
  final String file;

  /// The URIs to be imported if this completion is selected.
  final List<String> importUris;

  /// The ElementLocation of the item being completed.
  ///
  /// This is used to provide documentation in the resolved response.
  final String? ref;
  DartCompletionResolutionInfo({
    required this.file,
    required this.importUris,
    this.ref,
  });
  @override
  int get hashCode => Object.hash(
        file,
        lspHashCode(importUris),
        ref,
      );

  @override
  bool operator ==(Object other) {
    return other is DartCompletionResolutionInfo &&
        other.runtimeType == DartCompletionResolutionInfo &&
        file == other.file &&
        const DeepCollectionEquality().equals(importUris, other.importUris) &&
        ref == other.ref;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['file'] = file;
    result['importUris'] = importUris;
    if (ref != null) {
      result['ref'] = ref;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'file',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseListString(obj, reporter, 'importUris',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'ref',
          allowsUndefined: true, allowsNull: false);
    } else {
      reporter.reportError('must be of type DartCompletionResolutionInfo');
      return false;
    }
  }

  static DartCompletionResolutionInfo fromJson(Map<String, Object?> json) {
    final fileJson = json['file'];
    final file = fileJson as String;
    final importUrisJson = json['importUris'];
    final importUris = (importUrisJson as List<Object?>)
        .map((item) => item as String)
        .toList();
    final refJson = json['ref'];
    final ref = refJson as String?;
    return DartCompletionResolutionInfo(
      file: file,
      importUris: importUris,
      ref: ref,
    );
  }
}

class DartDiagnosticServer implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartDiagnosticServer.canParse,
    DartDiagnosticServer.fromJson,
  );

  final int port;

  DartDiagnosticServer({
    required this.port,
  });

  @override
  int get hashCode => port.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DartDiagnosticServer &&
        other.runtimeType == DartDiagnosticServer &&
        port == other.port;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['port'] = port;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseInt(obj, reporter, 'port',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type DartDiagnosticServer');
      return false;
    }
  }

  static DartDiagnosticServer fromJson(Map<String, Object?> json) {
    final portJson = json['port'];
    final port = portJson as int;
    return DartDiagnosticServer(
      port: port,
    );
  }
}

class DartTextDocumentContent implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartTextDocumentContent.canParse,
    DartTextDocumentContent.fromJson,
  );

  final String? content;

  DartTextDocumentContent({
    this.content,
  });

  @override
  int get hashCode => content.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DartTextDocumentContent &&
        other.runtimeType == DartTextDocumentContent &&
        content == other.content;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['content'] = content;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseString(obj, reporter, 'content',
          allowsUndefined: false, allowsNull: true);
    } else {
      reporter.reportError('must be of type DartTextDocumentContent');
      return false;
    }
  }

  static DartTextDocumentContent fromJson(Map<String, Object?> json) {
    final contentJson = json['content'];
    final content = contentJson as String?;
    return DartTextDocumentContent(
      content: content,
    );
  }
}

class DartTextDocumentContentDidChangeParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartTextDocumentContentDidChangeParams.canParse,
    DartTextDocumentContentDidChangeParams.fromJson,
  );

  final DocumentUri uri;

  DartTextDocumentContentDidChangeParams({
    required this.uri,
  });

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DartTextDocumentContentDidChangeParams &&
        other.runtimeType == DartTextDocumentContentDidChangeParams &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type DartTextDocumentContentDidChangeParams');
      return false;
    }
  }

  static DartTextDocumentContentDidChangeParams fromJson(
      Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return DartTextDocumentContentDidChangeParams(
      uri: uri,
    );
  }
}

class DartTextDocumentContentParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartTextDocumentContentParams.canParse,
    DartTextDocumentContentParams.fromJson,
  );

  final DocumentUri uri;

  DartTextDocumentContentParams({
    required this.uri,
  });

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) {
    return other is DartTextDocumentContentParams &&
        other.runtimeType == DartTextDocumentContentParams &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type DartTextDocumentContentParams');
      return false;
    }
  }

  static DartTextDocumentContentParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return DartTextDocumentContentParams(
      uri: uri,
    );
  }
}

class DartTextDocumentContentProviderRegistrationOptions implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartTextDocumentContentProviderRegistrationOptions.canParse,
    DartTextDocumentContentProviderRegistrationOptions.fromJson,
  );

  /// A set of URI schemes the server can provide content for. The server may
  /// also return URIs with these schemes in responses to other requests.
  final List<String> schemes;

  DartTextDocumentContentProviderRegistrationOptions({
    required this.schemes,
  });

  @override
  int get hashCode => lspHashCode(schemes);

  @override
  bool operator ==(Object other) {
    return other is DartTextDocumentContentProviderRegistrationOptions &&
        other.runtimeType ==
            DartTextDocumentContentProviderRegistrationOptions &&
        const DeepCollectionEquality().equals(schemes, other.schemes);
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['schemes'] = schemes;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseListString(obj, reporter, 'schemes',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type DartTextDocumentContentProviderRegistrationOptions');
      return false;
    }
  }

  static DartTextDocumentContentProviderRegistrationOptions fromJson(
      Map<String, Object?> json) {
    final schemesJson = json['schemes'];
    final schemes =
        (schemesJson as List<Object?>).map((item) => item as String).toList();
    return DartTextDocumentContentProviderRegistrationOptions(
      schemes: schemes,
    );
  }
}

class Element implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Element.canParse,
    Element.fromJson,
  );

  final String kind;

  final String name;

  final String? parameters;
  final Range? range;
  final String? returnType;
  final String? typeParameters;
  Element({
    required this.kind,
    required this.name,
    this.parameters,
    this.range,
    this.returnType,
    this.typeParameters,
  });
  @override
  int get hashCode => Object.hash(
        kind,
        name,
        parameters,
        range,
        returnType,
        typeParameters,
      );

  @override
  bool operator ==(Object other) {
    return other is Element &&
        other.runtimeType == Element &&
        kind == other.kind &&
        name == other.name &&
        parameters == other.parameters &&
        range == other.range &&
        returnType == other.returnType &&
        typeParameters == other.typeParameters;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['kind'] = kind;
    result['name'] = name;
    if (parameters != null) {
      result['parameters'] = parameters;
    }
    if (range != null) {
      result['range'] = range?.toJson();
    }
    if (returnType != null) {
      result['returnType'] = returnType;
    }
    if (typeParameters != null) {
      result['typeParameters'] = typeParameters;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'kind',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'name',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'parameters',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseRange(obj, reporter, 'range',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'returnType',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'typeParameters',
          allowsUndefined: true, allowsNull: false);
    } else {
      reporter.reportError('must be of type Element');
      return false;
    }
  }

  static Element fromJson(Map<String, Object?> json) {
    final kindJson = json['kind'];
    final kind = kindJson as String;
    final nameJson = json['name'];
    final name = nameJson as String;
    final parametersJson = json['parameters'];
    final parameters = parametersJson as String?;
    final rangeJson = json['range'];
    final range = rangeJson != null
        ? Range.fromJson(rangeJson as Map<String, Object?>)
        : null;
    final returnTypeJson = json['returnType'];
    final returnType = returnTypeJson as String?;
    final typeParametersJson = json['typeParameters'];
    final typeParameters = typeParametersJson as String?;
    return Element(
      kind: kind,
      name: name,
      parameters: parameters,
      range: range,
      returnType: returnType,
      typeParameters: typeParameters,
    );
  }
}

class FlutterOutline implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    FlutterOutline.canParse,
    FlutterOutline.fromJson,
  );

  final List<FlutterOutlineAttribute>? attributes;

  final List<FlutterOutline>? children;

  final String? className;
  final Range codeRange;
  final Element? dartElement;
  final String kind;
  final String? label;
  final Range range;
  final String? variableName;
  FlutterOutline({
    this.attributes,
    this.children,
    this.className,
    required this.codeRange,
    this.dartElement,
    required this.kind,
    this.label,
    required this.range,
    this.variableName,
  });
  @override
  int get hashCode => Object.hash(
        lspHashCode(attributes),
        lspHashCode(children),
        className,
        codeRange,
        dartElement,
        kind,
        label,
        range,
        variableName,
      );

  @override
  bool operator ==(Object other) {
    return other is FlutterOutline &&
        other.runtimeType == FlutterOutline &&
        const DeepCollectionEquality().equals(attributes, other.attributes) &&
        const DeepCollectionEquality().equals(children, other.children) &&
        className == other.className &&
        codeRange == other.codeRange &&
        dartElement == other.dartElement &&
        kind == other.kind &&
        label == other.label &&
        range == other.range &&
        variableName == other.variableName;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (attributes != null) {
      result['attributes'] = attributes?.map((item) => item.toJson()).toList();
    }
    if (children != null) {
      result['children'] = children?.map((item) => item.toJson()).toList();
    }
    if (className != null) {
      result['className'] = className;
    }
    result['codeRange'] = codeRange.toJson();
    if (dartElement != null) {
      result['dartElement'] = dartElement?.toJson();
    }
    result['kind'] = kind;
    if (label != null) {
      result['label'] = label;
    }
    result['range'] = range.toJson();
    if (variableName != null) {
      result['variableName'] = variableName;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseListFlutterOutlineAttribute(obj, reporter, 'attributes',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseListFlutterOutline(obj, reporter, 'children',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'className',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseRange(obj, reporter, 'codeRange',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseElement(obj, reporter, 'dartElement',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'kind',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'label',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseRange(obj, reporter, 'range',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'variableName',
          allowsUndefined: true, allowsNull: false);
    } else {
      reporter.reportError('must be of type FlutterOutline');
      return false;
    }
  }

  static FlutterOutline fromJson(Map<String, Object?> json) {
    final attributesJson = json['attributes'];
    final attributes = (attributesJson as List<Object?>?)
        ?.map((item) =>
            FlutterOutlineAttribute.fromJson(item as Map<String, Object?>))
        .toList();
    final childrenJson = json['children'];
    final children = (childrenJson as List<Object?>?)
        ?.map((item) => FlutterOutline.fromJson(item as Map<String, Object?>))
        .toList();
    final classNameJson = json['className'];
    final className = classNameJson as String?;
    final codeRangeJson = json['codeRange'];
    final codeRange = Range.fromJson(codeRangeJson as Map<String, Object?>);
    final dartElementJson = json['dartElement'];
    final dartElement = dartElementJson != null
        ? Element.fromJson(dartElementJson as Map<String, Object?>)
        : null;
    final kindJson = json['kind'];
    final kind = kindJson as String;
    final labelJson = json['label'];
    final label = labelJson as String?;
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    final variableNameJson = json['variableName'];
    final variableName = variableNameJson as String?;
    return FlutterOutline(
      attributes: attributes,
      children: children,
      className: className,
      codeRange: codeRange,
      dartElement: dartElement,
      kind: kind,
      label: label,
      range: range,
      variableName: variableName,
    );
  }
}

class FlutterOutlineAttribute implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    FlutterOutlineAttribute.canParse,
    FlutterOutlineAttribute.fromJson,
  );

  final String label;

  final String name;

  final Range? valueRange;
  FlutterOutlineAttribute({
    required this.label,
    required this.name,
    this.valueRange,
  });
  @override
  int get hashCode => Object.hash(
        label,
        name,
        valueRange,
      );

  @override
  bool operator ==(Object other) {
    return other is FlutterOutlineAttribute &&
        other.runtimeType == FlutterOutlineAttribute &&
        label == other.label &&
        name == other.name &&
        valueRange == other.valueRange;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['label'] = label;
    result['name'] = name;
    if (valueRange != null) {
      result['valueRange'] = valueRange?.toJson();
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'label',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'name',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseRange(obj, reporter, 'valueRange',
          allowsUndefined: true, allowsNull: false);
    } else {
      reporter.reportError('must be of type FlutterOutlineAttribute');
      return false;
    }
  }

  static FlutterOutlineAttribute fromJson(Map<String, Object?> json) {
    final labelJson = json['label'];
    final label = labelJson as String;
    final nameJson = json['name'];
    final name = nameJson as String;
    final valueRangeJson = json['valueRange'];
    final valueRange = valueRangeJson != null
        ? Range.fromJson(valueRangeJson as Map<String, Object?>)
        : null;
    return FlutterOutlineAttribute(
      label: label,
      name: name,
      valueRange: valueRange,
    );
  }
}

class IncomingMessage implements Message, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    IncomingMessage.canParse,
    IncomingMessage.fromJson,
  );

  @override
  final int? clientRequestTime;

  @override
  final String jsonrpc;

  final Method method;
  final LSPAny params;
  IncomingMessage({
    this.clientRequestTime,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
        method,
        params,
      );

  @override
  bool operator ==(Object other) {
    return other is IncomingMessage &&
        other.runtimeType == IncomingMessage &&
        clientRequestTime == other.clientRequestTime &&
        jsonrpc == other.jsonrpc &&
        method == other.method &&
        params == other.params;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (clientRequestTime != null) {
      result['clientRequestTime'] = clientRequestTime;
    }
    result['jsonrpc'] = jsonrpc;
    result['method'] = method.toJson();
    if (params != null) {
      result['params'] = params;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInt(obj, reporter, 'clientRequestTime',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'jsonrpc',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseMethod(obj, reporter, 'method',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type IncomingMessage');
      return false;
    }
  }

  static IncomingMessage fromJson(Map<String, Object?> json) {
    if (RequestMessage.canParse(json, nullLspJsonReporter)) {
      return RequestMessage.fromJson(json);
    }
    if (NotificationMessage.canParse(json, nullLspJsonReporter)) {
      return NotificationMessage.fromJson(json);
    }
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final jsonrpcJson = json['jsonrpc'];
    final jsonrpc = jsonrpcJson as String;
    final methodJson = json['method'];
    final method = Method.fromJson(methodJson as String);
    final paramsJson = json['params'];
    final params = paramsJson;
    return IncomingMessage(
      clientRequestTime: clientRequestTime,
      jsonrpc: jsonrpc,
      method: method,
      params: params,
    );
  }
}

class Message implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Message.canParse,
    Message.fromJson,
  );

  final int? clientRequestTime;

  final String jsonrpc;

  Message({
    this.clientRequestTime,
    required this.jsonrpc,
  });
  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
      );

  @override
  bool operator ==(Object other) {
    return other is Message &&
        other.runtimeType == Message &&
        clientRequestTime == other.clientRequestTime &&
        jsonrpc == other.jsonrpc;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (clientRequestTime != null) {
      result['clientRequestTime'] = clientRequestTime;
    }
    result['jsonrpc'] = jsonrpc;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInt(obj, reporter, 'clientRequestTime',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'jsonrpc',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type Message');
      return false;
    }
  }

  static Message fromJson(Map<String, Object?> json) {
    if (IncomingMessage.canParse(json, nullLspJsonReporter)) {
      return IncomingMessage.fromJson(json);
    }
    if (ResponseMessage.canParse(json, nullLspJsonReporter)) {
      return ResponseMessage.fromJson(json);
    }
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final jsonrpcJson = json['jsonrpc'];
    final jsonrpc = jsonrpcJson as String;
    return Message(
      clientRequestTime: clientRequestTime,
      jsonrpc: jsonrpc,
    );
  }
}

class NotificationMessage implements IncomingMessage, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    NotificationMessage.canParse,
    NotificationMessage.fromJson,
  );

  @override
  final int? clientRequestTime;

  @override
  final String jsonrpc;

  @override
  final Method method;
  @override
  final LSPAny params;
  NotificationMessage({
    this.clientRequestTime,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
        method,
        params,
      );

  @override
  bool operator ==(Object other) {
    return other is NotificationMessage &&
        other.runtimeType == NotificationMessage &&
        clientRequestTime == other.clientRequestTime &&
        jsonrpc == other.jsonrpc &&
        method == other.method &&
        params == other.params;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (clientRequestTime != null) {
      result['clientRequestTime'] = clientRequestTime;
    }
    result['jsonrpc'] = jsonrpc;
    result['method'] = method.toJson();
    if (params != null) {
      result['params'] = params;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInt(obj, reporter, 'clientRequestTime',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'jsonrpc',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseMethod(obj, reporter, 'method',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type NotificationMessage');
      return false;
    }
  }

  static NotificationMessage fromJson(Map<String, Object?> json) {
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final jsonrpcJson = json['jsonrpc'];
    final jsonrpc = jsonrpcJson as String;
    final methodJson = json['method'];
    final method = Method.fromJson(methodJson as String);
    final paramsJson = json['params'];
    final params = paramsJson;
    return NotificationMessage(
      clientRequestTime: clientRequestTime,
      jsonrpc: jsonrpc,
      method: method,
      params: params,
    );
  }
}

class OpenUriParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    OpenUriParams.canParse,
    OpenUriParams.fromJson,
  );

  final Uri uri;

  OpenUriParams({
    required this.uri,
  });

  @override
  int get hashCode => uri.hashCode;

  @override
  bool operator ==(Object other) {
    return other is OpenUriParams &&
        other.runtimeType == OpenUriParams &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type OpenUriParams');
      return false;
    }
  }

  static OpenUriParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return OpenUriParams(
      uri: uri,
    );
  }
}

class Outline implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Outline.canParse,
    Outline.fromJson,
  );

  final List<Outline>? children;

  final Range codeRange;

  final Element element;
  final Range range;
  Outline({
    this.children,
    required this.codeRange,
    required this.element,
    required this.range,
  });
  @override
  int get hashCode => Object.hash(
        lspHashCode(children),
        codeRange,
        element,
        range,
      );

  @override
  bool operator ==(Object other) {
    return other is Outline &&
        other.runtimeType == Outline &&
        const DeepCollectionEquality().equals(children, other.children) &&
        codeRange == other.codeRange &&
        element == other.element &&
        range == other.range;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (children != null) {
      result['children'] = children?.map((item) => item.toJson()).toList();
    }
    result['codeRange'] = codeRange.toJson();
    result['element'] = element.toJson();
    result['range'] = range.toJson();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseListOutline(obj, reporter, 'children',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseRange(obj, reporter, 'codeRange',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseElement(obj, reporter, 'element',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseRange(obj, reporter, 'range',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type Outline');
      return false;
    }
  }

  static Outline fromJson(Map<String, Object?> json) {
    final childrenJson = json['children'];
    final children = (childrenJson as List<Object?>?)
        ?.map((item) => Outline.fromJson(item as Map<String, Object?>))
        .toList();
    final codeRangeJson = json['codeRange'];
    final codeRange = Range.fromJson(codeRangeJson as Map<String, Object?>);
    final elementJson = json['element'];
    final element = Element.fromJson(elementJson as Map<String, Object?>);
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    return Outline(
      children: children,
      codeRange: codeRange,
      element: element,
      range: range,
    );
  }
}

class PublishClosingLabelsParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PublishClosingLabelsParams.canParse,
    PublishClosingLabelsParams.fromJson,
  );

  final List<ClosingLabel> labels;

  final Uri uri;

  PublishClosingLabelsParams({
    required this.labels,
    required this.uri,
  });
  @override
  int get hashCode => Object.hash(
        lspHashCode(labels),
        uri,
      );

  @override
  bool operator ==(Object other) {
    return other is PublishClosingLabelsParams &&
        other.runtimeType == PublishClosingLabelsParams &&
        const DeepCollectionEquality().equals(labels, other.labels) &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['labels'] = labels.map((item) => item.toJson()).toList();
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseListClosingLabel(obj, reporter, 'labels',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishClosingLabelsParams');
      return false;
    }
  }

  static PublishClosingLabelsParams fromJson(Map<String, Object?> json) {
    final labelsJson = json['labels'];
    final labels = (labelsJson as List<Object?>)
        .map((item) => ClosingLabel.fromJson(item as Map<String, Object?>))
        .toList();
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return PublishClosingLabelsParams(
      labels: labels,
      uri: uri,
    );
  }
}

class PublishFlutterOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PublishFlutterOutlineParams.canParse,
    PublishFlutterOutlineParams.fromJson,
  );

  final FlutterOutline outline;

  final Uri uri;

  PublishFlutterOutlineParams({
    required this.outline,
    required this.uri,
  });
  @override
  int get hashCode => Object.hash(
        outline,
        uri,
      );

  @override
  bool operator ==(Object other) {
    return other is PublishFlutterOutlineParams &&
        other.runtimeType == PublishFlutterOutlineParams &&
        outline == other.outline &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['outline'] = outline.toJson();
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseFlutterOutline(obj, reporter, 'outline',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishFlutterOutlineParams');
      return false;
    }
  }

  static PublishFlutterOutlineParams fromJson(Map<String, Object?> json) {
    final outlineJson = json['outline'];
    final outline =
        FlutterOutline.fromJson(outlineJson as Map<String, Object?>);
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return PublishFlutterOutlineParams(
      outline: outline,
      uri: uri,
    );
  }
}

class PublishOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PublishOutlineParams.canParse,
    PublishOutlineParams.fromJson,
  );

  final Outline outline;

  final Uri uri;

  PublishOutlineParams({
    required this.outline,
    required this.uri,
  });
  @override
  int get hashCode => Object.hash(
        outline,
        uri,
      );

  @override
  bool operator ==(Object other) {
    return other is PublishOutlineParams &&
        other.runtimeType == PublishOutlineParams &&
        outline == other.outline &&
        uri == other.uri;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['outline'] = outline.toJson();
    result['uri'] = uri.toString();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseOutline(obj, reporter, 'outline',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseUri(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishOutlineParams');
      return false;
    }
  }

  static PublishOutlineParams fromJson(Map<String, Object?> json) {
    final outlineJson = json['outline'];
    final outline = Outline.fromJson(outlineJson as Map<String, Object?>);
    final uriJson = json['uri'];
    final uri = Uri.parse(uriJson as String);
    return PublishOutlineParams(
      outline: outline,
      uri: uri,
    );
  }
}

class PubPackageCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PubPackageCompletionItemResolutionInfo.canParse,
    PubPackageCompletionItemResolutionInfo.fromJson,
  );

  final String packageName;

  PubPackageCompletionItemResolutionInfo({
    required this.packageName,
  });

  @override
  int get hashCode => packageName.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PubPackageCompletionItemResolutionInfo &&
        other.runtimeType == PubPackageCompletionItemResolutionInfo &&
        packageName == other.packageName;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['packageName'] = packageName;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return _canParseString(obj, reporter, 'packageName',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type PubPackageCompletionItemResolutionInfo');
      return false;
    }
  }

  static PubPackageCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final packageNameJson = json['packageName'];
    final packageName = packageNameJson as String;
    return PubPackageCompletionItemResolutionInfo(
      packageName: packageName,
    );
  }
}

class RequestMessage implements IncomingMessage, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    RequestMessage.canParse,
    RequestMessage.fromJson,
  );

  @override
  final int? clientRequestTime;

  final Either2<int, String> id;

  @override
  final String jsonrpc;
  @override
  final Method method;
  @override
  final LSPAny params;
  RequestMessage({
    this.clientRequestTime,
    required this.id,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        id,
        jsonrpc,
        method,
        params,
      );

  @override
  bool operator ==(Object other) {
    return other is RequestMessage &&
        other.runtimeType == RequestMessage &&
        clientRequestTime == other.clientRequestTime &&
        id == other.id &&
        jsonrpc == other.jsonrpc &&
        method == other.method &&
        params == other.params;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (clientRequestTime != null) {
      result['clientRequestTime'] = clientRequestTime;
    }
    result['id'] = id;
    result['jsonrpc'] = jsonrpc;
    result['method'] = method.toJson();
    if (params != null) {
      result['params'] = params;
    }
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInt(obj, reporter, 'clientRequestTime',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseIntString(obj, reporter, 'id',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'jsonrpc',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseMethod(obj, reporter, 'method',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type RequestMessage');
      return false;
    }
  }

  static RequestMessage fromJson(Map<String, Object?> json) {
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final idJson = json['id'];
    final id = _eitherIntString(idJson);
    final jsonrpcJson = json['jsonrpc'];
    final jsonrpc = jsonrpcJson as String;
    final methodJson = json['method'];
    final method = Method.fromJson(methodJson as String);
    final paramsJson = json['params'];
    final params = paramsJson;
    return RequestMessage(
      clientRequestTime: clientRequestTime,
      id: id,
      jsonrpc: jsonrpc,
      method: method,
      params: params,
    );
  }
}

class ResponseError implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ResponseError.canParse,
    ResponseError.fromJson,
  );

  final ErrorCodes code;

  /// A string that contains additional information about the error. Can be
  /// omitted.
  final String? data;

  final String message;
  ResponseError({
    required this.code,
    this.data,
    required this.message,
  });
  @override
  int get hashCode => Object.hash(
        code,
        data,
        message,
      );

  @override
  bool operator ==(Object other) {
    return other is ResponseError &&
        other.runtimeType == ResponseError &&
        code == other.code &&
        data == other.data &&
        message == other.message;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['code'] = code.toJson();
    if (data != null) {
      result['data'] = data;
    }
    result['message'] = message;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseErrorCodes(obj, reporter, 'code',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'data',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'message',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type ResponseError');
      return false;
    }
  }

  static ResponseError fromJson(Map<String, Object?> json) {
    final codeJson = json['code'];
    final code = ErrorCodes.fromJson(codeJson as int);
    final dataJson = json['data'];
    final data = dataJson as String?;
    final messageJson = json['message'];
    final message = messageJson as String;
    return ResponseError(
      code: code,
      data: data,
      message: message,
    );
  }
}

class ResponseMessage implements Message, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ResponseMessage.canParse,
    ResponseMessage.fromJson,
  );

  @override
  final int? clientRequestTime;

  final ResponseError? error;

  final Either2<int, String>? id;
  @override
  final String jsonrpc;
  final LSPAny result;
  ResponseMessage({
    this.clientRequestTime,
    this.error,
    this.id,
    required this.jsonrpc,
    this.result,
  });
  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        error,
        id,
        jsonrpc,
        result,
      );

  @override
  bool operator ==(Object other) {
    return other is ResponseMessage &&
        other.runtimeType == ResponseMessage &&
        clientRequestTime == other.clientRequestTime &&
        error == other.error &&
        id == other.id &&
        jsonrpc == other.jsonrpc &&
        result == other.result;
  }

  @override
  Map<String, Object?> toJson() {
    var map = <String, Object?>{};
    if (clientRequestTime != null) {
      map['clientRequestTime'] = clientRequestTime;
    }
    map['id'] = id;
    map['jsonrpc'] = jsonrpc;
    if (error != null && result != null) {
      throw 'result and error cannot both be set';
    } else if (error != null) {
      map['error'] = error;
    } else {
      map['result'] = result;
    }
    return map;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInt(obj, reporter, 'clientRequestTime',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseResponseError(obj, reporter, 'error',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      if (!_canParseIntString(obj, reporter, 'id',
          allowsUndefined: false, allowsNull: true)) {
        return false;
      }
      return _canParseString(obj, reporter, 'jsonrpc',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type ResponseMessage');
      return false;
    }
  }

  static ResponseMessage fromJson(Map<String, Object?> json) {
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final errorJson = json['error'];
    final error = errorJson != null
        ? ResponseError.fromJson(errorJson as Map<String, Object?>)
        : null;
    final idJson = json['id'];
    final id = idJson == null ? null : _eitherIntString(idJson);
    final jsonrpcJson = json['jsonrpc'];
    final jsonrpc = jsonrpcJson as String;
    final resultJson = json['result'];
    final result = resultJson;
    return ResponseMessage(
      clientRequestTime: clientRequestTime,
      error: error,
      id: id,
      jsonrpc: jsonrpc,
      result: result,
    );
  }
}

/// Information about a Save URI argument needed by the command.
class SaveUriCommandParameter implements CommandParameter, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    SaveUriCommandParameter.canParse,
    SaveUriCommandParameter.fromJson,
  );

  /// A label for the file dialogs action button.
  final String actionLabel;

  /// An optional default URI for the parameter.
  @override
  final String? defaultValue;

  /// A set of file filters for a file dialog. Keys of the map are textual names
  /// ("Dart") and the value is a list of file extensions (["dart"]).
  final Map<String, List<String>>? filters;
  @override
  final String kind;

  /// A human-readable label to be displayed in the UI affordance used to prompt
  /// the user for the value of the parameter.
  @override
  final String parameterLabel;

  /// A title that may be displayed on a file dialog.
  final String parameterTitle;
  SaveUriCommandParameter({
    required this.actionLabel,
    this.defaultValue,
    this.filters,
    this.kind = 'saveUri',
    required this.parameterLabel,
    required this.parameterTitle,
  }) {
    if (kind != 'saveUri') {
      throw 'kind may only be the literal \'saveUri\'';
    }
  }
  @override
  int get hashCode => Object.hash(
        actionLabel,
        defaultValue,
        lspHashCode(filters),
        kind,
        parameterLabel,
        parameterTitle,
      );

  @override
  bool operator ==(Object other) {
    return other is SaveUriCommandParameter &&
        other.runtimeType == SaveUriCommandParameter &&
        actionLabel == other.actionLabel &&
        defaultValue == other.defaultValue &&
        const DeepCollectionEquality().equals(filters, other.filters) &&
        kind == other.kind &&
        parameterLabel == other.parameterLabel &&
        parameterTitle == other.parameterTitle;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['actionLabel'] = actionLabel;
    if (defaultValue != null) {
      result['defaultValue'] = defaultValue;
    }
    if (filters != null) {
      result['filters'] = filters;
    }
    result['kind'] = kind;
    result['parameterLabel'] = parameterLabel;
    result['parameterTitle'] = parameterTitle;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'actionLabel',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'defaultValue',
          allowsUndefined: true, allowsNull: true)) {
        return false;
      }
      if (!_canParseMapStringListString(obj, reporter, 'filters',
          allowsUndefined: true, allowsNull: true)) {
        return false;
      }
      if (!_canParseLiteral(obj, reporter, 'kind',
          allowsUndefined: false, allowsNull: false, literal: 'saveUri')) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'parameterLabel',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'parameterTitle',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type SaveUriCommandParameter');
      return false;
    }
  }

  static SaveUriCommandParameter fromJson(Map<String, Object?> json) {
    final actionLabelJson = json['actionLabel'];
    final actionLabel = actionLabelJson as String;
    final defaultValueJson = json['defaultValue'];
    final defaultValue = defaultValueJson as String?;
    final filtersJson = json['filters'];
    final filters = (filtersJson as Map<Object, Object?>?)?.map((key, value) =>
        MapEntry(key as String,
            (value as List<Object?>).map((item) => item as String).toList()));
    final kindJson = json['kind'];
    final kind = kindJson as String;
    final parameterLabelJson = json['parameterLabel'];
    final parameterLabel = parameterLabelJson as String;
    final parameterTitleJson = json['parameterTitle'];
    final parameterTitle = parameterTitleJson as String;
    return SaveUriCommandParameter(
      actionLabel: actionLabel,
      defaultValue: defaultValue,
      filters: filters,
      kind: kind,
      parameterLabel: parameterLabel,
      parameterTitle: parameterTitle,
    );
  }
}

class SnippetTextEdit implements TextEdit, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    SnippetTextEdit.canParse,
    SnippetTextEdit.fromJson,
  );

  final InsertTextFormat insertTextFormat;

  /// The string to be inserted. For delete operations use an empty string.
  @override
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  @override
  final Range range;
  SnippetTextEdit({
    required this.insertTextFormat,
    required this.newText,
    required this.range,
  });
  @override
  int get hashCode => Object.hash(
        insertTextFormat,
        newText,
        range,
      );

  @override
  bool operator ==(Object other) {
    return other is SnippetTextEdit &&
        other.runtimeType == SnippetTextEdit &&
        insertTextFormat == other.insertTextFormat &&
        newText == other.newText &&
        range == other.range;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['insertTextFormat'] = insertTextFormat.toJson();
    result['newText'] = newText;
    result['range'] = range.toJson();
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseInsertTextFormat(obj, reporter, 'insertTextFormat',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'newText',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseRange(obj, reporter, 'range',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type SnippetTextEdit');
      return false;
    }
  }

  static SnippetTextEdit fromJson(Map<String, Object?> json) {
    final insertTextFormatJson = json['insertTextFormat'];
    final insertTextFormat =
        InsertTextFormat.fromJson(insertTextFormatJson as int);
    final newTextJson = json['newText'];
    final newText = newTextJson as String;
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    return SnippetTextEdit(
      insertTextFormat: insertTextFormat,
      newText: newText,
      range: range,
    );
  }
}

class TypeHierarchyAnchor implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    TypeHierarchyAnchor.canParse,
    TypeHierarchyAnchor.fromJson,
  );

  /// Indices used to navigate from this anchor to the element.
  final List<int> path;

  /// The ElementLocation for this anchor element.
  final String ref;

  TypeHierarchyAnchor({
    required this.path,
    required this.ref,
  });
  @override
  int get hashCode => Object.hash(
        lspHashCode(path),
        ref,
      );

  @override
  bool operator ==(Object other) {
    return other is TypeHierarchyAnchor &&
        other.runtimeType == TypeHierarchyAnchor &&
        const DeepCollectionEquality().equals(path, other.path) &&
        ref == other.ref;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['path'] = path;
    result['ref'] = ref;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseListInt(obj, reporter, 'path',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'ref',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type TypeHierarchyAnchor');
      return false;
    }
  }

  static TypeHierarchyAnchor fromJson(Map<String, Object?> json) {
    final pathJson = json['path'];
    final path =
        (pathJson as List<Object?>).map((item) => item as int).toList();
    final refJson = json['ref'];
    final ref = refJson as String;
    return TypeHierarchyAnchor(
      path: path,
      ref: ref,
    );
  }
}

class TypeHierarchyItemInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    TypeHierarchyItemInfo.canParse,
    TypeHierarchyItemInfo.fromJson,
  );

  /// An anchor element that can be used to navigate to this element preserving
  /// type arguments.
  final TypeHierarchyAnchor? anchor;

  /// The ElementLocation for this element, used to re-locate the element when
  /// subtypes/supertypes are fetched later.
  final String ref;

  TypeHierarchyItemInfo({
    this.anchor,
    required this.ref,
  });
  @override
  int get hashCode => Object.hash(
        anchor,
        ref,
      );

  @override
  bool operator ==(Object other) {
    return other is TypeHierarchyItemInfo &&
        other.runtimeType == TypeHierarchyItemInfo &&
        anchor == other.anchor &&
        ref == other.ref;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (anchor != null) {
      result['anchor'] = anchor?.toJson();
    }
    result['ref'] = ref;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseTypeHierarchyAnchor(obj, reporter, 'anchor',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'ref',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type TypeHierarchyItemInfo');
      return false;
    }
  }

  static TypeHierarchyItemInfo fromJson(Map<String, Object?> json) {
    final anchorJson = json['anchor'];
    final anchor = anchorJson != null
        ? TypeHierarchyAnchor.fromJson(anchorJson as Map<String, Object?>)
        : null;
    final refJson = json['ref'];
    final ref = refJson as String;
    return TypeHierarchyItemInfo(
      anchor: anchor,
      ref: ref,
    );
  }
}

class ValidateRefactorResult implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ValidateRefactorResult.canParse,
    ValidateRefactorResult.fromJson,
  );

  final String? message;

  final bool valid;

  ValidateRefactorResult({
    this.message,
    required this.valid,
  });
  @override
  int get hashCode => Object.hash(
        message,
        valid,
      );

  @override
  bool operator ==(Object other) {
    return other is ValidateRefactorResult &&
        other.runtimeType == ValidateRefactorResult &&
        message == other.message &&
        valid == other.valid;
  }

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (message != null) {
      result['message'] = message;
    }
    result['valid'] = valid;
    return result;
  }

  @override
  String toString() => jsonEncoder.convert(toJson());

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'message',
          allowsUndefined: true, allowsNull: false)) {
        return false;
      }
      return _canParseBool(obj, reporter, 'valid',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type ValidateRefactorResult');
      return false;
    }
  }

  static ValidateRefactorResult fromJson(Map<String, Object?> json) {
    final messageJson = json['message'];
    final message = messageJson as String?;
    final validJson = json['valid'];
    final valid = validJson as bool;
    return ValidateRefactorResult(
      message: message,
      valid: valid,
    );
  }
}
