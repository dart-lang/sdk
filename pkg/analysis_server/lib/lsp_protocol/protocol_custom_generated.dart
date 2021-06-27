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
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = JsonEncoder.withIndent('    ');

class AnalyzerStatusParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      AnalyzerStatusParams.canParse, AnalyzerStatusParams.fromJson);

  AnalyzerStatusParams({required this.isAnalyzing});
  static AnalyzerStatusParams fromJson(Map<String, dynamic> json) {
    final isAnalyzing = json['isAnalyzing'];
    return AnalyzerStatusParams(isAnalyzing: isAnalyzing);
  }

  final bool isAnalyzing;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['isAnalyzing'] = isAnalyzing;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('isAnalyzing');
      try {
        if (!obj.containsKey('isAnalyzing')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['isAnalyzing'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['isAnalyzing'] is bool)) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, isAnalyzing.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ClosingLabel implements ToJsonable {
  static const jsonHandler =
      LspJsonHandler(ClosingLabel.canParse, ClosingLabel.fromJson);

  ClosingLabel({required this.range, required this.label});
  static ClosingLabel fromJson(Map<String, dynamic> json) {
    final range = Range.fromJson(json['range']);
    final label = json['label'];
    return ClosingLabel(range: range, label: label);
  }

  final String label;
  final Range range;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['range'] = range.toJson();
    __result['label'] = label;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('range');
      try {
        if (!obj.containsKey('range')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['range'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['range'], reporter))) {
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
        if (obj['label'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['label'] is String)) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      CompletionItemResolutionInfo.canParse,
      CompletionItemResolutionInfo.fromJson);

  CompletionItemResolutionInfo({required this.file, required this.offset});
  static CompletionItemResolutionInfo fromJson(Map<String, dynamic> json) {
    if (DartCompletionItemResolutionInfo.canParse(json, nullLspJsonReporter)) {
      return DartCompletionItemResolutionInfo.fromJson(json);
    }
    if (PubPackageCompletionItemResolutionInfo.canParse(
        json, nullLspJsonReporter)) {
      return PubPackageCompletionItemResolutionInfo.fromJson(json);
    }
    final file = json['file'];
    final offset = json['offset'];
    return CompletionItemResolutionInfo(file: file, offset: offset);
  }

  final String file;
  final int offset;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['file'] = file;
    __result['offset'] = offset;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('file');
      try {
        if (!obj.containsKey('file')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['file'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['file'] is String)) {
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
        if (obj['offset'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['offset'] is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
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
      return file == other.file && offset == other.offset && true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
      DartCompletionItemResolutionInfo.canParse,
      DartCompletionItemResolutionInfo.fromJson);

  DartCompletionItemResolutionInfo(
      {required this.libId,
      required this.displayUri,
      required this.rOffset,
      required this.iLength,
      required this.rLength,
      required this.file,
      required this.offset});
  static DartCompletionItemResolutionInfo fromJson(Map<String, dynamic> json) {
    final libId = json['libId'];
    final displayUri = json['displayUri'];
    final rOffset = json['rOffset'];
    final iLength = json['iLength'];
    final rLength = json['rLength'];
    final file = json['file'];
    final offset = json['offset'];
    return DartCompletionItemResolutionInfo(
        libId: libId,
        displayUri: displayUri,
        rOffset: rOffset,
        iLength: iLength,
        rLength: rLength,
        file: file,
        offset: offset);
  }

  final String displayUri;
  final String file;
  final int iLength;
  final int libId;
  final int offset;
  final int rLength;
  final int rOffset;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['libId'] = libId;
    __result['displayUri'] = displayUri;
    __result['rOffset'] = rOffset;
    __result['iLength'] = iLength;
    __result['rLength'] = rLength;
    __result['file'] = file;
    __result['offset'] = offset;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('libId');
      try {
        if (!obj.containsKey('libId')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['libId'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['libId'] is int)) {
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
        if (obj['displayUri'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['displayUri'] is String)) {
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
        if (obj['rOffset'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['rOffset'] is int)) {
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
        if (obj['iLength'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['iLength'] is int)) {
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
        if (obj['rLength'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['rLength'] is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('file');
      try {
        if (!obj.containsKey('file')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['file'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['file'] is String)) {
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
        if (obj['offset'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['offset'] is int)) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type DartCompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is DartCompletionItemResolutionInfo &&
        other.runtimeType == DartCompletionItemResolutionInfo) {
      return libId == other.libId &&
          displayUri == other.displayUri &&
          rOffset == other.rOffset &&
          iLength == other.iLength &&
          rLength == other.rLength &&
          file == other.file &&
          offset == other.offset &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, libId.hashCode);
    hash = JenkinsSmiHash.combine(hash, displayUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, rOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, iLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, rLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartDiagnosticServer implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      DartDiagnosticServer.canParse, DartDiagnosticServer.fromJson);

  DartDiagnosticServer({required this.port});
  static DartDiagnosticServer fromJson(Map<String, dynamic> json) {
    final port = json['port'];
    return DartDiagnosticServer(port: port);
  }

  final int port;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['port'] = port;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('port');
      try {
        if (!obj.containsKey('port')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['port'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['port'] is int)) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

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
  static Element fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final name = json['name'];
    final kind = json['kind'];
    final parameters = json['parameters'];
    final typeParameters = json['typeParameters'];
    final returnType = json['returnType'];
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

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
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
    if (obj is Map<String, dynamic>) {
      reporter.push('range');
      try {
        if (obj['range'] != null && !(Range.canParse(obj['range'], reporter))) {
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
        if (obj['name'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['name'] is String)) {
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
        if (obj['kind'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['kind'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('parameters');
      try {
        if (obj['parameters'] != null && !(obj['parameters'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('typeParameters');
      try {
        if (obj['typeParameters'] != null &&
            !(obj['typeParameters'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('returnType');
      try {
        if (obj['returnType'] != null && !(obj['returnType'] is String)) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeParameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

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
  static FlutterOutline fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    final label = json['label'];
    final className = json['className'];
    final variableName = json['variableName'];
    final attributes = json['attributes']
        ?.map((item) =>
            item != null ? FlutterOutlineAttribute.fromJson(item) : null)
        ?.cast<FlutterOutlineAttribute>()
        ?.toList();
    final dartElement = json['dartElement'] != null
        ? Element.fromJson(json['dartElement'])
        : null;
    final range = Range.fromJson(json['range']);
    final codeRange = Range.fromJson(json['codeRange']);
    final children = json['children']
        ?.map((item) => item != null ? FlutterOutline.fromJson(item) : null)
        ?.cast<FlutterOutline>()
        ?.toList();
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

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
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
    if (obj is Map<String, dynamic>) {
      reporter.push('kind');
      try {
        if (!obj.containsKey('kind')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['kind'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['kind'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('label');
      try {
        if (obj['label'] != null && !(obj['label'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('className');
      try {
        if (obj['className'] != null && !(obj['className'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('variableName');
      try {
        if (obj['variableName'] != null && !(obj['variableName'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('attributes');
      try {
        if (obj['attributes'] != null &&
            !((obj['attributes'] is List &&
                (obj['attributes'].every((item) =>
                    FlutterOutlineAttribute.canParse(item, reporter)))))) {
          reporter.reportError('must be of type List<FlutterOutlineAttribute>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('dartElement');
      try {
        if (obj['dartElement'] != null &&
            !(Element.canParse(obj['dartElement'], reporter))) {
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
        if (obj['range'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['range'], reporter))) {
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
        if (obj['codeRange'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['codeRange'], reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('children');
      try {
        if (obj['children'] != null &&
            !((obj['children'] is List &&
                (obj['children'].every(
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, variableName.hashCode);
    hash = JenkinsSmiHash.combine(hash, lspHashCode(attributes));
    hash = JenkinsSmiHash.combine(hash, dartElement.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeRange.hashCode);
    hash = JenkinsSmiHash.combine(hash, lspHashCode(children));
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class FlutterOutlineAttribute implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      FlutterOutlineAttribute.canParse, FlutterOutlineAttribute.fromJson);

  FlutterOutlineAttribute(
      {required this.name, required this.label, this.valueRange});
  static FlutterOutlineAttribute fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final label = json['label'];
    final valueRange =
        json['valueRange'] != null ? Range.fromJson(json['valueRange']) : null;
    return FlutterOutlineAttribute(
        name: name, label: label, valueRange: valueRange);
  }

  final String label;
  final String name;
  final Range? valueRange;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['name'] = name;
    __result['label'] = label;
    if (valueRange != null) {
      __result['valueRange'] = valueRange?.toJson();
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('name');
      try {
        if (!obj.containsKey('name')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['name'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['name'] is String)) {
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
        if (obj['label'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['label'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('valueRange');
      try {
        if (obj['valueRange'] != null &&
            !(Range.canParse(obj['valueRange'], reporter))) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, valueRange.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

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
  static Outline fromJson(Map<String, dynamic> json) {
    final element = Element.fromJson(json['element']);
    final range = Range.fromJson(json['range']);
    final codeRange = Range.fromJson(json['codeRange']);
    final children = json['children']
        ?.map((item) => item != null ? Outline.fromJson(item) : null)
        ?.cast<Outline>()
        ?.toList();
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

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['element'] = element.toJson();
    __result['range'] = range.toJson();
    __result['codeRange'] = codeRange.toJson();
    if (children != null) {
      __result['children'] = children?.map((item) => item.toJson()).toList();
    }
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('element');
      try {
        if (!obj.containsKey('element')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['element'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Element.canParse(obj['element'], reporter))) {
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
        if (obj['range'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['range'], reporter))) {
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
        if (obj['codeRange'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['codeRange'], reporter))) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('children');
      try {
        if (obj['children'] != null &&
            !((obj['children'] is List &&
                (obj['children']
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeRange.hashCode);
    hash = JenkinsSmiHash.combine(hash, lspHashCode(children));
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PubPackageCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PubPackageCompletionItemResolutionInfo.canParse,
      PubPackageCompletionItemResolutionInfo.fromJson);

  PubPackageCompletionItemResolutionInfo(
      {required this.packageName, required this.file, required this.offset});
  static PubPackageCompletionItemResolutionInfo fromJson(
      Map<String, dynamic> json) {
    final packageName = json['packageName'];
    final file = json['file'];
    final offset = json['offset'];
    return PubPackageCompletionItemResolutionInfo(
        packageName: packageName, file: file, offset: offset);
  }

  final String file;
  final int offset;
  final String packageName;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['packageName'] = packageName;
    __result['file'] = file;
    __result['offset'] = offset;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('packageName');
      try {
        if (!obj.containsKey('packageName')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['packageName'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['packageName'] is String)) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('file');
      try {
        if (!obj.containsKey('file')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['file'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['file'] is String)) {
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
        if (obj['offset'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['offset'] is int)) {
          reporter.reportError('must be of type int');
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
      return packageName == other.packageName &&
          file == other.file &&
          offset == other.offset &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, packageName.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishClosingLabelsParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishClosingLabelsParams.canParse, PublishClosingLabelsParams.fromJson);

  PublishClosingLabelsParams({required this.uri, required this.labels});
  static PublishClosingLabelsParams fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final labels = json['labels']
        ?.map((item) => ClosingLabel.fromJson(item))
        ?.cast<ClosingLabel>()
        ?.toList();
    return PublishClosingLabelsParams(uri: uri, labels: labels);
  }

  final List<ClosingLabel> labels;
  final String uri;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['uri'] = uri;
    __result['labels'] = labels.map((item) => item.toJson()).toList();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['uri'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['uri'] is String)) {
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
        if (obj['labels'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!((obj['labels'] is List &&
            (obj['labels']
                .every((item) => ClosingLabel.canParse(item, reporter)))))) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, lspHashCode(labels));
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishFlutterOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishFlutterOutlineParams.canParse,
      PublishFlutterOutlineParams.fromJson);

  PublishFlutterOutlineParams({required this.uri, required this.outline});
  static PublishFlutterOutlineParams fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final outline = FlutterOutline.fromJson(json['outline']);
    return PublishFlutterOutlineParams(uri: uri, outline: outline);
  }

  final FlutterOutline outline;
  final String uri;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['uri'] = uri;
    __result['outline'] = outline.toJson();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['uri'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['uri'] is String)) {
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
        if (obj['outline'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(FlutterOutline.canParse(obj['outline'], reporter))) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
      PublishOutlineParams.canParse, PublishOutlineParams.fromJson);

  PublishOutlineParams({required this.uri, required this.outline});
  static PublishOutlineParams fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final outline = Outline.fromJson(json['outline']);
    return PublishOutlineParams(uri: uri, outline: outline);
  }

  final Outline outline;
  final String uri;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['uri'] = uri;
    __result['outline'] = outline.toJson();
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('uri');
      try {
        if (!obj.containsKey('uri')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['uri'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['uri'] is String)) {
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
        if (obj['outline'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Outline.canParse(obj['outline'], reporter))) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

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
  static SnippetTextEdit fromJson(Map<String, dynamic> json) {
    final insertTextFormat =
        InsertTextFormat.fromJson(json['insertTextFormat']);
    final range = Range.fromJson(json['range']);
    final newText = json['newText'];
    return SnippetTextEdit(
        insertTextFormat: insertTextFormat, range: range, newText: newText);
  }

  final InsertTextFormat insertTextFormat;

  /// The string to be inserted. For delete operations use an empty string.
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  final Range range;

  Map<String, dynamic> toJson() {
    var __result = <String, dynamic>{};
    __result['insertTextFormat'] = insertTextFormat.toJson();
    __result['range'] = range.toJson();
    __result['newText'] = newText;
    return __result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, dynamic>) {
      reporter.push('insertTextFormat');
      try {
        if (!obj.containsKey('insertTextFormat')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        if (obj['insertTextFormat'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(InsertTextFormat.canParse(obj['insertTextFormat'], reporter))) {
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
        if (obj['range'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(Range.canParse(obj['range'], reporter))) {
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
        if (obj['newText'] == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!(obj['newText'] is String)) {
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
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, insertTextFormat.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, newText.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}
