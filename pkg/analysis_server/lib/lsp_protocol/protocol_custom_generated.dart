// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: annotate_overrides
// ignore_for_file: unnecessary_parenthesis

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

class AnalyzerStatusParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      AnalyzerStatusParams.canParse, AnalyzerStatusParams.fromJson);

  AnalyzerStatusParams({required this.isAnalyzing});
  static AnalyzerStatusParams fromJson(Map<String, Object?> json) {
    final isAnalyzingJson = json['isAnalyzing'];
    final isAnalyzing = isAnalyzingJson as bool;
    return AnalyzerStatusParams(isAnalyzing: isAnalyzing);
  }

  final bool isAnalyzing;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['isAnalyzing'] = isAnalyzing;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('isAnalyzing');
      try {
        if (!obj.containsKey('isAnalyzing')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final isAnalyzing = obj['isAnalyzing'];
        if (isAnalyzing == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(isAnalyzing is bool)) {
          reporter.reportError('must be of type bool');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type AnalyzerStatusParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is AnalyzerStatusParams &&
        other.runtimeType == AnalyzerStatusParams) {
      return isAnalyzing == other.isAnalyzing && true;
    }
    return false;
  }

  @override
  int get hashCode => isAnalyzing.hashCode;

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ClosingLabel implements ToJsonable {
  static const jsonHandler =
      LspJsonHandler(ClosingLabel.canParse, ClosingLabel.fromJson);

  ClosingLabel({required this.range, required this.label});
  static ClosingLabel fromJson(Map<String, Object?> json) {
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    final labelJson = json['label'];
    final label = labelJson as String;
    return ClosingLabel(range: range, label: label);
  }

  final String label;
  final Range range;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['range'] = range.toJson();
    __result['label'] = label;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('range');
      try {
        if (!obj.containsKey('range')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final range = obj['range'];
        if (range == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(range, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('label');
      try {
        if (!obj.containsKey('label')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final label = obj['label'];
        if (label == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(label is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type ClosingLabel');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is ClosingLabel && other.runtimeType == ClosingLabel) {
      return range == other.range && label == other.label && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(range, label);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      CompletionItemResolutionInfo.canParse,
      CompletionItemResolutionInfo.fromJson);

  static CompletionItemResolutionInfo fromJson(Map<String, Object?> json) {
    if (DartSuggestionSetCompletionItemResolutionInfo.canParse(
        json, nullLspJsonReporter)) {
      return DartSuggestionSetCompletionItemResolutionInfo.fromJson(json);
    }
    if (PubPackageCompletionItemResolutionInfo.canParse(
        json, nullLspJsonReporter)) {
      return PubPackageCompletionItemResolutionInfo.fromJson(json);
    }
    return CompletionItemResolutionInfo();
  }

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      return true;
    } else {
      reporter.reportError('must be of type CompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is CompletionItemResolutionInfo &&
        other.runtimeType == CompletionItemResolutionInfo) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode => 42;

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartDiagnosticServer implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      DartDiagnosticServer.canParse, DartDiagnosticServer.fromJson);

  DartDiagnosticServer({required this.port});
  static DartDiagnosticServer fromJson(Map<String, Object?> json) {
    final portJson = json['port'];
    final port = portJson as int;
    return DartDiagnosticServer(port: port);
  }

  final int port;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['port'] = port;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('port');
      try {
        if (!obj.containsKey('port')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final port = obj['port'];
        if (port == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(port is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type DartDiagnosticServer');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is DartDiagnosticServer &&
        other.runtimeType == DartDiagnosticServer) {
      return port == other.port && true;
    }
    return false;
  }

  @override
  int get hashCode => port.hashCode;

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartSuggestionSetCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
      DartSuggestionSetCompletionItemResolutionInfo.canParse,
      DartSuggestionSetCompletionItemResolutionInfo.fromJson);

  DartSuggestionSetCompletionItemResolutionInfo(
      {required this.file,
      required this.offset,
      required this.libId,
      required this.displayUri,
      required this.rOffset,
      required this.iLength,
      required this.rLength});
  static DartSuggestionSetCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final fileJson = json['file'];
    final file = fileJson as String;
    final offsetJson = json['offset'];
    final offset = offsetJson as int;
    final libIdJson = json['libId'];
    final libId = libIdJson as int;
    final displayUriJson = json['displayUri'];
    final displayUri = displayUriJson as String;
    final rOffsetJson = json['rOffset'];
    final rOffset = rOffsetJson as int;
    final iLengthJson = json['iLength'];
    final iLength = iLengthJson as int;
    final rLengthJson = json['rLength'];
    final rLength = rLengthJson as int;
    return DartSuggestionSetCompletionItemResolutionInfo(
        file: file,
        offset: offset,
        libId: libId,
        displayUri: displayUri,
        rOffset: rOffset,
        iLength: iLength,
        rLength: rLength);
  }

  final String displayUri;
  final String file;
  final int iLength;
  final int libId;
  final int offset;
  final int rLength;
  final int rOffset;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['file'] = file;
    __result['offset'] = offset;
    __result['libId'] = libId;
    __result['displayUri'] = displayUri;
    __result['rOffset'] = rOffset;
    __result['iLength'] = iLength;
    __result['rLength'] = rLength;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('file');
      try {
        if (!obj.containsKey('file')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final file = obj['file'];
        if (file == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(file is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('offset');
      try {
        if (!obj.containsKey('offset')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final offset = obj['offset'];
        if (offset == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(offset is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('libId');
      try {
        if (!obj.containsKey('libId')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final libId = obj['libId'];
        if (libId == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(libId is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('displayUri');
      try {
        if (!obj.containsKey('displayUri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final displayUri = obj['displayUri'];
        if (displayUri == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(displayUri is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('rOffset');
      try {
        if (!obj.containsKey('rOffset')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final rOffset = obj['rOffset'];
        if (rOffset == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(rOffset is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('iLength');
      try {
        if (!obj.containsKey('iLength')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final iLength = obj['iLength'];
        if (iLength == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(iLength is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('rLength');
      try {
        if (!obj.containsKey('rLength')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final rLength = obj['rLength'];
        if (rLength == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(rLength is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError(
          'must be of type DartSuggestionSetCompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is DartSuggestionSetCompletionItemResolutionInfo &&
        other.runtimeType == DartSuggestionSetCompletionItemResolutionInfo) {
      return file == other.file &&
          offset == other.offset &&
          libId == other.libId &&
          displayUri == other.displayUri &&
          rOffset == other.rOffset &&
          iLength == other.iLength &&
          rLength == other.rLength &&
          true;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(file, offset, libId, displayUri, rOffset, iLength, rLength);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Element implements ToJsonable {
  static const jsonHandler = LspJsonHandler(Element.canParse, Element.fromJson);

  Element(
      {this.range,
      required this.name,
      required this.kind,
      this.parameters,
      this.typeParameters,
      this.returnType});
  static Element fromJson(Map<String, Object?> json) {
    final rangeJson = json['range'];
    final range = rangeJson != null
        ? Range.fromJson(rangeJson as Map<String, Object?>)
        : null;
    final nameJson = json['name'];
    final name = nameJson as String;
    final kindJson = json['kind'];
    final kind = kindJson as String;
    final parametersJson = json['parameters'];
    final parameters = parametersJson as String?;
    final typeParametersJson = json['typeParameters'];
    final typeParameters = typeParametersJson as String?;
    final returnTypeJson = json['returnType'];
    final returnType = returnTypeJson as String?;
    return Element(
        range: range,
        name: name,
        kind: kind,
        parameters: parameters,
        typeParameters: typeParameters,
        returnType: returnType);
  }

  final String kind;
  final String name;
  final String? parameters;
  final Range? range;
  final String? returnType;
  final String? typeParameters;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    if (range != null) {
      __result['range'] = range?.toJson();
    }
    __result['name'] = name;
    __result['kind'] = kind;
    if (parameters != null) {
      __result['parameters'] = parameters;
    }
    if (typeParameters != null) {
      __result['typeParameters'] = typeParameters;
    }
    if (returnType != null) {
      __result['returnType'] = returnType;
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('range');
      try {
        final range = obj['range'];
        if (range != null && !(Range.canParse(range, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('name');
      try {
        if (!obj.containsKey('name')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final name = obj['name'];
        if (name == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(name is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('kind');
      try {
        if (!obj.containsKey('kind')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final kind = obj['kind'];
        if (kind == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(kind is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('parameters');
      try {
        final parameters = obj['parameters'];
        if (parameters != null && !(parameters is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('typeParameters');
      try {
        final typeParameters = obj['typeParameters'];
        if (typeParameters != null && !(typeParameters is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('returnType');
      try {
        final returnType = obj['returnType'];
        if (returnType != null && !(returnType is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type Element');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Element && other.runtimeType == Element) {
      return range == other.range &&
          name == other.name &&
          kind == other.kind &&
          parameters == other.parameters &&
          typeParameters == other.typeParameters &&
          returnType == other.returnType &&
          true;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(range, name, kind, parameters, typeParameters, returnType);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class FlutterOutline implements ToJsonable {
  static const jsonHandler =
      LspJsonHandler(FlutterOutline.canParse, FlutterOutline.fromJson);

  FlutterOutline(
      {required this.kind,
      this.label,
      this.className,
      this.variableName,
      this.attributes,
      this.dartElement,
      required this.range,
      required this.codeRange,
      this.children});
  static FlutterOutline fromJson(Map<String, Object?> json) {
    final kindJson = json['kind'];
    final kind = kindJson as String;
    final labelJson = json['label'];
    final label = labelJson as String?;
    final classNameJson = json['className'];
    final className = classNameJson as String?;
    final variableNameJson = json['variableName'];
    final variableName = variableNameJson as String?;
    final attributesJson = json['attributes'];
    final attributes = (attributesJson as List<Object?>?)
        ?.map((item) =>
            FlutterOutlineAttribute.fromJson(item as Map<String, Object?>))
        .toList();
    final dartElementJson = json['dartElement'];
    final dartElement = dartElementJson != null
        ? Element.fromJson(dartElementJson as Map<String, Object?>)
        : null;
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    final codeRangeJson = json['codeRange'];
    final codeRange = Range.fromJson(codeRangeJson as Map<String, Object?>);
    final childrenJson = json['children'];
    final children = (childrenJson as List<Object?>?)
        ?.map((item) => FlutterOutline.fromJson(item as Map<String, Object?>))
        .toList();
    return FlutterOutline(
        kind: kind,
        label: label,
        className: className,
        variableName: variableName,
        attributes: attributes,
        dartElement: dartElement,
        range: range,
        codeRange: codeRange,
        children: children);
  }

  final List<FlutterOutlineAttribute>? attributes;
  final List<FlutterOutline>? children;
  final String? className;
  final Range codeRange;
  final Element? dartElement;
  final String kind;
  final String? label;
  final Range range;
  final String? variableName;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['kind'] = kind;
    if (label != null) {
      __result['label'] = label;
    }
    if (className != null) {
      __result['className'] = className;
    }
    if (variableName != null) {
      __result['variableName'] = variableName;
    }
    if (attributes != null) {
      __result['attributes'] =
          attributes?.map((item) => item.toJson()).toList();
    }
    if (dartElement != null) {
      __result['dartElement'] = dartElement?.toJson();
    }
    __result['range'] = range.toJson();
    __result['codeRange'] = codeRange.toJson();
    if (children != null) {
      __result['children'] = children?.map((item) => item.toJson()).toList();
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('kind');
      try {
        if (!obj.containsKey('kind')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final kind = obj['kind'];
        if (kind == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(kind is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('label');
      try {
        final label = obj['label'];
        if (label != null && !(label is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('className');
      try {
        final className = obj['className'];
        if (className != null && !(className is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('variableName');
      try {
        final variableName = obj['variableName'];
        if (variableName != null && !(variableName is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('attributes');
      try {
        final attributes = obj['attributes'];
        if (attributes != null &&
            !((attributes is List<Object?> &&
                (attributes.every((item) =>
                    FlutterOutlineAttribute.canParse(item, reporter)))))) {
          reporter.reportError('must be of type List<FlutterOutlineAttribute>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('dartElement');
      try {
        final dartElement = obj['dartElement'];
        if (dartElement != null && !(Element.canParse(dartElement, reporter))) {
          reporter.reportError('must be of type Element');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('range');
      try {
        if (!obj.containsKey('range')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final range = obj['range'];
        if (range == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(range, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('codeRange');
      try {
        if (!obj.containsKey('codeRange')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final codeRange = obj['codeRange'];
        if (codeRange == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(codeRange, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('children');
      try {
        final children = obj['children'];
        if (children != null &&
            !((children is List<Object?> &&
                (children.every(
                    (item) => FlutterOutline.canParse(item, reporter)))))) {
          reporter.reportError('must be of type List<FlutterOutline>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type FlutterOutline');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is FlutterOutline && other.runtimeType == FlutterOutline) {
      return kind == other.kind &&
          label == other.label &&
          className == other.className &&
          variableName == other.variableName &&
          listEqual(
              attributes,
              other.attributes,
              (FlutterOutlineAttribute a, FlutterOutlineAttribute b) =>
                  a == b) &&
          dartElement == other.dartElement &&
          range == other.range &&
          codeRange == other.codeRange &&
          listEqual(children, other.children,
              (FlutterOutline a, FlutterOutline b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
      kind,
      label,
      className,
      variableName,
      lspHashCode(attributes),
      dartElement,
      range,
      codeRange,
      lspHashCode(children));

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class FlutterOutlineAttribute implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      FlutterOutlineAttribute.canParse, FlutterOutlineAttribute.fromJson);

  FlutterOutlineAttribute(
      {required this.name, required this.label, this.valueRange});
  static FlutterOutlineAttribute fromJson(Map<String, Object?> json) {
    final nameJson = json['name'];
    final name = nameJson as String;
    final labelJson = json['label'];
    final label = labelJson as String;
    final valueRangeJson = json['valueRange'];
    final valueRange = valueRangeJson != null
        ? Range.fromJson(valueRangeJson as Map<String, Object?>)
        : null;
    return FlutterOutlineAttribute(
        name: name, label: label, valueRange: valueRange);
  }

  final String label;
  final String name;
  final Range? valueRange;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['name'] = name;
    __result['label'] = label;
    if (valueRange != null) {
      __result['valueRange'] = valueRange?.toJson();
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('name');
      try {
        if (!obj.containsKey('name')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final name = obj['name'];
        if (name == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(name is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('label');
      try {
        if (!obj.containsKey('label')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final label = obj['label'];
        if (label == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(label is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('valueRange');
      try {
        final valueRange = obj['valueRange'];
        if (valueRange != null && !(Range.canParse(valueRange, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type FlutterOutlineAttribute');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is FlutterOutlineAttribute &&
        other.runtimeType == FlutterOutlineAttribute) {
      return name == other.name &&
          label == other.label &&
          valueRange == other.valueRange &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(name, label, valueRange);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Outline implements ToJsonable {
  static const jsonHandler = LspJsonHandler(Outline.canParse, Outline.fromJson);

  Outline(
      {required this.element,
      required this.range,
      required this.codeRange,
      this.children});
  static Outline fromJson(Map<String, Object?> json) {
    final elementJson = json['element'];
    final element = Element.fromJson(elementJson as Map<String, Object?>);
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    final codeRangeJson = json['codeRange'];
    final codeRange = Range.fromJson(codeRangeJson as Map<String, Object?>);
    final childrenJson = json['children'];
    final children = (childrenJson as List<Object?>?)
        ?.map((item) => Outline.fromJson(item as Map<String, Object?>))
        .toList();
    return Outline(
        element: element,
        range: range,
        codeRange: codeRange,
        children: children);
  }

  final List<Outline>? children;
  final Range codeRange;
  final Element element;
  final Range range;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['element'] = element.toJson();
    __result['range'] = range.toJson();
    __result['codeRange'] = codeRange.toJson();
    if (children != null) {
      __result['children'] = children?.map((item) => item.toJson()).toList();
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('element');
      try {
        if (!obj.containsKey('element')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final element = obj['element'];
        if (element == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Element.canParse(element, reporter))) {
          reporter.reportError('must be of type Element');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('range');
      try {
        if (!obj.containsKey('range')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final range = obj['range'];
        if (range == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(range, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('codeRange');
      try {
        if (!obj.containsKey('codeRange')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final codeRange = obj['codeRange'];
        if (codeRange == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(codeRange, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('children');
      try {
        final children = obj['children'];
        if (children != null &&
            !((children is List<Object?> &&
                (children
                    .every((item) => Outline.canParse(item, reporter)))))) {
          reporter.reportError('must be of type List<Outline>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type Outline');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Outline && other.runtimeType == Outline) {
      return element == other.element &&
          range == other.range &&
          codeRange == other.codeRange &&
          listEqual(
              children, other.children, (Outline a, Outline b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(element, range, codeRange, lspHashCode(children));

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PubPackageCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PubPackageCompletionItemResolutionInfo.canParse,
      PubPackageCompletionItemResolutionInfo.fromJson);

  PubPackageCompletionItemResolutionInfo({required this.packageName});
  static PubPackageCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final packageNameJson = json['packageName'];
    final packageName = packageNameJson as String;
    return PubPackageCompletionItemResolutionInfo(packageName: packageName);
  }

  final String packageName;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['packageName'] = packageName;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('packageName');
      try {
        if (!obj.containsKey('packageName')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final packageName = obj['packageName'];
        if (packageName == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(packageName is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError(
          'must be of type PubPackageCompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is PubPackageCompletionItemResolutionInfo &&
        other.runtimeType == PubPackageCompletionItemResolutionInfo) {
      return packageName == other.packageName && true;
    }
    return false;
  }

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishClosingLabelsParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishClosingLabelsParams.canParse, PublishClosingLabelsParams.fromJson);

  PublishClosingLabelsParams({required this.uri, required this.labels});
  static PublishClosingLabelsParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = uriJson as String;
    final labelsJson = json['labels'];
    final labels = (labelsJson as List<Object?>)
        .map((item) => ClosingLabel.fromJson(item as Map<String, Object?>))
        .toList();
    return PublishClosingLabelsParams(uri: uri, labels: labels);
  }

  final List<ClosingLabel> labels;
  final String uri;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['uri'] = uri;
    __result['labels'] = labels.map((item) => item.toJson()).toList();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final uri = obj['uri'];
        if (uri == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(uri is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('labels');
      try {
        if (!obj.containsKey('labels')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final labels = obj['labels'];
        if (labels == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!((labels is List<Object?> &&
            (labels.every((item) => ClosingLabel.canParse(item, reporter)))))) {
          reporter.reportError('must be of type List<ClosingLabel>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type PublishClosingLabelsParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is PublishClosingLabelsParams &&
        other.runtimeType == PublishClosingLabelsParams) {
      return uri == other.uri &&
          listEqual(labels, other.labels,
              (ClosingLabel a, ClosingLabel b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(uri, lspHashCode(labels));

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishFlutterOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishFlutterOutlineParams.canParse,
      PublishFlutterOutlineParams.fromJson);

  PublishFlutterOutlineParams({required this.uri, required this.outline});
  static PublishFlutterOutlineParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = uriJson as String;
    final outlineJson = json['outline'];
    final outline =
        FlutterOutline.fromJson(outlineJson as Map<String, Object?>);
    return PublishFlutterOutlineParams(uri: uri, outline: outline);
  }

  final FlutterOutline outline;
  final String uri;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['uri'] = uri;
    __result['outline'] = outline.toJson();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final uri = obj['uri'];
        if (uri == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(uri is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('outline');
      try {
        if (!obj.containsKey('outline')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final outline = obj['outline'];
        if (outline == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(FlutterOutline.canParse(outline, reporter))) {
          reporter.reportError('must be of type FlutterOutline');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type PublishFlutterOutlineParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is PublishFlutterOutlineParams &&
        other.runtimeType == PublishFlutterOutlineParams) {
      return uri == other.uri && outline == other.outline && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(uri, outline);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishOutlineParams.canParse, PublishOutlineParams.fromJson);

  PublishOutlineParams({required this.uri, required this.outline});
  static PublishOutlineParams fromJson(Map<String, Object?> json) {
    final uriJson = json['uri'];
    final uri = uriJson as String;
    final outlineJson = json['outline'];
    final outline = Outline.fromJson(outlineJson as Map<String, Object?>);
    return PublishOutlineParams(uri: uri, outline: outline);
  }

  final Outline outline;
  final String uri;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['uri'] = uri;
    __result['outline'] = outline.toJson();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final uri = obj['uri'];
        if (uri == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(uri is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('outline');
      try {
        if (!obj.containsKey('outline')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final outline = obj['outline'];
        if (outline == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Outline.canParse(outline, reporter))) {
          reporter.reportError('must be of type Outline');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type PublishOutlineParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is PublishOutlineParams &&
        other.runtimeType == PublishOutlineParams) {
      return uri == other.uri && outline == other.outline && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(uri, outline);

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class SnippetTextEdit implements TextEdit, ToJsonable {
  static const jsonHandler =
      LspJsonHandler(SnippetTextEdit.canParse, SnippetTextEdit.fromJson);

  SnippetTextEdit(
      {required this.insertTextFormat,
      required this.range,
      required this.newText});
  static SnippetTextEdit fromJson(Map<String, Object?> json) {
    final insertTextFormatJson = json['insertTextFormat'];
    final insertTextFormat =
        InsertTextFormat.fromJson(insertTextFormatJson as int);
    final rangeJson = json['range'];
    final range = Range.fromJson(rangeJson as Map<String, Object?>);
    final newTextJson = json['newText'];
    final newText = newTextJson as String;
    return SnippetTextEdit(
        insertTextFormat: insertTextFormat, range: range, newText: newText);
  }

  final InsertTextFormat insertTextFormat;

  /// The string to be inserted. For delete operations use an empty string.
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  final Range range;

  Map<String, Object?> toJson() {
    var __result = <String, Object?>{};
    __result['insertTextFormat'] = insertTextFormat.toJson();
    __result['range'] = range.toJson();
    __result['newText'] = newText;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('insertTextFormat');
      try {
        if (!obj.containsKey('insertTextFormat')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final insertTextFormat = obj['insertTextFormat'];
        if (insertTextFormat == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(InsertTextFormat.canParse(insertTextFormat, reporter))) {
          reporter.reportError('must be of type InsertTextFormat');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('range');
      try {
        if (!obj.containsKey('range')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final range = obj['range'];
        if (range == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(range, reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('newText');
      try {
        if (!obj.containsKey('newText')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final newText = obj['newText'];
        if (newText == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(newText is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type SnippetTextEdit');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is SnippetTextEdit && other.runtimeType == SnippetTextEdit) {
      return insertTextFormat == other.insertTextFormat &&
          range == other.range &&
          newText == other.newText &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(insertTextFormat, range, newText);

  @override
  String toString() => jsonEncoder.convert(toJson());
}
