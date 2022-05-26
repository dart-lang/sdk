// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

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
    AnalyzerStatusParams.canParse,
    AnalyzerStatusParams.fromJson,
  );

  AnalyzerStatusParams({
    required this.isAnalyzing,
  });
  static AnalyzerStatusParams fromJson(Map<String, Object?> json) {
    final isAnalyzingJson = json['isAnalyzing'];
    final isAnalyzing = isAnalyzingJson as bool;
    return AnalyzerStatusParams(
      isAnalyzing: isAnalyzing,
    );
  }

  final bool isAnalyzing;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['isAnalyzing'] = isAnalyzing;
    return result;
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
        if (isAnalyzing is! bool) {
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
  static const jsonHandler = LspJsonHandler(
    ClosingLabel.canParse,
    ClosingLabel.fromJson,
  );

  ClosingLabel({
    required this.label,
    required this.range,
  });
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

  final String label;
  final Range range;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['label'] = label;
    result['range'] = range.toJson();
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (label is! String) {
          reporter.reportError('must be of type String');
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
        if (!Range.canParse(range, reporter)) {
          reporter.reportError('must be of type Range');
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
      return label == other.label && range == other.range && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        label,
        range,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    CompletionItemResolutionInfo.canParse,
    CompletionItemResolutionInfo.fromJson,
  );

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

  @override
  Map<String, Object?> toJson() => {};

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
    DartDiagnosticServer.canParse,
    DartDiagnosticServer.fromJson,
  );

  DartDiagnosticServer({
    required this.port,
  });
  static DartDiagnosticServer fromJson(Map<String, Object?> json) {
    final portJson = json['port'];
    final port = portJson as int;
    return DartDiagnosticServer(
      port: port,
    );
  }

  final int port;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['port'] = port;
    return result;
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
        if (port is! int) {
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
    DartSuggestionSetCompletionItemResolutionInfo.fromJson,
  );

  DartSuggestionSetCompletionItemResolutionInfo({
    required this.displayUri,
    required this.file,
    required this.iLength,
    required this.libId,
    required this.offset,
    required this.rLength,
    required this.rOffset,
  });
  static DartSuggestionSetCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final displayUriJson = json['displayUri'];
    final displayUri = displayUriJson as String;
    final fileJson = json['file'];
    final file = fileJson as String;
    final iLengthJson = json['iLength'];
    final iLength = iLengthJson as int;
    final libIdJson = json['libId'];
    final libId = libIdJson as int;
    final offsetJson = json['offset'];
    final offset = offsetJson as int;
    final rLengthJson = json['rLength'];
    final rLength = rLengthJson as int;
    final rOffsetJson = json['rOffset'];
    final rOffset = rOffsetJson as int;
    return DartSuggestionSetCompletionItemResolutionInfo(
      displayUri: displayUri,
      file: file,
      iLength: iLength,
      libId: libId,
      offset: offset,
      rLength: rLength,
      rOffset: rOffset,
    );
  }

  final String displayUri;
  final String file;
  final int iLength;
  final int libId;
  final int offset;
  final int rLength;
  final int rOffset;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['displayUri'] = displayUri;
    result['file'] = file;
    result['iLength'] = iLength;
    result['libId'] = libId;
    result['offset'] = offset;
    result['rLength'] = rLength;
    result['rOffset'] = rOffset;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (displayUri is! String) {
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
        final file = obj['file'];
        if (file == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (file is! String) {
          reporter.reportError('must be of type String');
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
        if (iLength is! int) {
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
        if (libId is! int) {
          reporter.reportError('must be of type int');
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
        if (offset is! int) {
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
        if (rLength is! int) {
          reporter.reportError('must be of type int');
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
        if (rOffset is! int) {
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
      return displayUri == other.displayUri &&
          file == other.file &&
          iLength == other.iLength &&
          libId == other.libId &&
          offset == other.offset &&
          rLength == other.rLength &&
          rOffset == other.rOffset &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        displayUri,
        file,
        iLength,
        libId,
        offset,
        rLength,
        rOffset,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Element implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Element.canParse,
    Element.fromJson,
  );

  Element({
    required this.kind,
    required this.name,
    this.parameters,
    this.range,
    this.returnType,
    this.typeParameters,
  });
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

  final String kind;
  final String name;
  final String? parameters;
  final Range? range;
  final String? returnType;
  final String? typeParameters;

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
        if (kind is! String) {
          reporter.reportError('must be of type String');
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
        if (name is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('parameters');
      try {
        final parameters = obj['parameters'];
        if (parameters != null && parameters is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('range');
      try {
        final range = obj['range'];
        if (range != null && !Range.canParse(range, reporter)) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('returnType');
      try {
        final returnType = obj['returnType'];
        if (returnType != null && returnType is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('typeParameters');
      try {
        final typeParameters = obj['typeParameters'];
        if (typeParameters != null && typeParameters is! String) {
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
      return kind == other.kind &&
          name == other.name &&
          parameters == other.parameters &&
          range == other.range &&
          returnType == other.returnType &&
          typeParameters == other.typeParameters &&
          true;
    }
    return false;
  }

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
  String toString() => jsonEncoder.convert(toJson());
}

class FlutterOutline implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    FlutterOutline.canParse,
    FlutterOutline.fromJson,
  );

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

  final List<FlutterOutlineAttribute>? attributes;
  final List<FlutterOutline>? children;
  final String? className;
  final Range codeRange;
  final Element? dartElement;
  final String kind;
  final String? label;
  final Range range;
  final String? variableName;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('attributes');
      try {
        final attributes = obj['attributes'];
        if (attributes != null &&
            (attributes is! List<Object?> ||
                attributes.any((item) =>
                    !FlutterOutlineAttribute.canParse(item, reporter)))) {
          reporter.reportError('must be of type List<FlutterOutlineAttribute>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('children');
      try {
        final children = obj['children'];
        if (children != null &&
            (children is! List<Object?> ||
                children
                    .any((item) => !FlutterOutline.canParse(item, reporter)))) {
          reporter.reportError('must be of type List<FlutterOutline>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('className');
      try {
        final className = obj['className'];
        if (className != null && className is! String) {
          reporter.reportError('must be of type String');
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
        if (!Range.canParse(codeRange, reporter)) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('dartElement');
      try {
        final dartElement = obj['dartElement'];
        if (dartElement != null && !Element.canParse(dartElement, reporter)) {
          reporter.reportError('must be of type Element');
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
        if (kind is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('label');
      try {
        final label = obj['label'];
        if (label != null && label is! String) {
          reporter.reportError('must be of type String');
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
        if (!Range.canParse(range, reporter)) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('variableName');
      try {
        final variableName = obj['variableName'];
        if (variableName != null && variableName is! String) {
          reporter.reportError('must be of type String');
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
      return listEqual(
              attributes,
              other.attributes,
              (FlutterOutlineAttribute a, FlutterOutlineAttribute b) =>
                  a == b) &&
          listEqual(children, other.children,
              (FlutterOutline a, FlutterOutline b) => a == b) &&
          className == other.className &&
          codeRange == other.codeRange &&
          dartElement == other.dartElement &&
          kind == other.kind &&
          label == other.label &&
          range == other.range &&
          variableName == other.variableName &&
          true;
    }
    return false;
  }

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
  String toString() => jsonEncoder.convert(toJson());
}

class FlutterOutlineAttribute implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    FlutterOutlineAttribute.canParse,
    FlutterOutlineAttribute.fromJson,
  );

  FlutterOutlineAttribute({
    required this.label,
    required this.name,
    this.valueRange,
  });
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

  final String label;
  final String name;
  final Range? valueRange;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (label is! String) {
          reporter.reportError('must be of type String');
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
        if (name is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('valueRange');
      try {
        final valueRange = obj['valueRange'];
        if (valueRange != null && !Range.canParse(valueRange, reporter)) {
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
      return label == other.label &&
          name == other.name &&
          valueRange == other.valueRange &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        label,
        name,
        valueRange,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class IncomingMessage implements Message, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    IncomingMessage.canParse,
    IncomingMessage.fromJson,
  );

  IncomingMessage({
    this.clientRequestTime,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
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

  @override
  final int? clientRequestTime;
  @override
  final String jsonrpc;
  final Method method;
  final Object? params;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('clientRequestTime');
      try {
        final clientRequestTime = obj['clientRequestTime'];
        if (clientRequestTime != null && clientRequestTime is! int) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('jsonrpc');
      try {
        if (!obj.containsKey('jsonrpc')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final jsonrpc = obj['jsonrpc'];
        if (jsonrpc == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (jsonrpc is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('method');
      try {
        if (!obj.containsKey('method')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final method = obj['method'];
        if (method == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!Method.canParse(method, reporter)) {
          reporter.reportError('must be of type Method');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type IncomingMessage');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is IncomingMessage && other.runtimeType == IncomingMessage) {
      return clientRequestTime == other.clientRequestTime &&
          jsonrpc == other.jsonrpc &&
          method == other.method &&
          params == other.params &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
        method,
        params,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Message implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Message.canParse,
    Message.fromJson,
  );

  Message({
    this.clientRequestTime,
    required this.jsonrpc,
  });
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

  final int? clientRequestTime;
  final String jsonrpc;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (clientRequestTime != null) {
      result['clientRequestTime'] = clientRequestTime;
    }
    result['jsonrpc'] = jsonrpc;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('clientRequestTime');
      try {
        final clientRequestTime = obj['clientRequestTime'];
        if (clientRequestTime != null && clientRequestTime is! int) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('jsonrpc');
      try {
        if (!obj.containsKey('jsonrpc')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final jsonrpc = obj['jsonrpc'];
        if (jsonrpc == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (jsonrpc is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type Message');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Message && other.runtimeType == Message) {
      return clientRequestTime == other.clientRequestTime &&
          jsonrpc == other.jsonrpc &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class NotificationMessage implements IncomingMessage, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    NotificationMessage.canParse,
    NotificationMessage.fromJson,
  );

  NotificationMessage({
    this.clientRequestTime,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
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

  @override
  final int? clientRequestTime;
  @override
  final String jsonrpc;
  @override
  final Method method;
  @override
  final Object? params;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('clientRequestTime');
      try {
        final clientRequestTime = obj['clientRequestTime'];
        if (clientRequestTime != null && clientRequestTime is! int) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('jsonrpc');
      try {
        if (!obj.containsKey('jsonrpc')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final jsonrpc = obj['jsonrpc'];
        if (jsonrpc == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (jsonrpc is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('method');
      try {
        if (!obj.containsKey('method')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final method = obj['method'];
        if (method == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!Method.canParse(method, reporter)) {
          reporter.reportError('must be of type Method');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type NotificationMessage');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is NotificationMessage &&
        other.runtimeType == NotificationMessage) {
      return clientRequestTime == other.clientRequestTime &&
          jsonrpc == other.jsonrpc &&
          method == other.method &&
          params == other.params &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        jsonrpc,
        method,
        params,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Outline implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    Outline.canParse,
    Outline.fromJson,
  );

  Outline({
    this.children,
    required this.codeRange,
    required this.element,
    required this.range,
  });
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

  final List<Outline>? children;
  final Range codeRange;
  final Element element;
  final Range range;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('children');
      try {
        final children = obj['children'];
        if (children != null &&
            (children is! List<Object?> ||
                children.any((item) => !Outline.canParse(item, reporter)))) {
          reporter.reportError('must be of type List<Outline>');
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
        if (!Range.canParse(codeRange, reporter)) {
          reporter.reportError('must be of type Range');
          return false;
        }
      } finally {
        reporter.pop();
      }
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
        if (!Element.canParse(element, reporter)) {
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
        if (!Range.canParse(range, reporter)) {
          reporter.reportError('must be of type Range');
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
      return listEqual(
              children, other.children, (Outline a, Outline b) => a == b) &&
          codeRange == other.codeRange &&
          element == other.element &&
          range == other.range &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        lspHashCode(children),
        codeRange,
        element,
        range,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PubPackageCompletionItemResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PubPackageCompletionItemResolutionInfo.canParse,
    PubPackageCompletionItemResolutionInfo.fromJson,
  );

  PubPackageCompletionItemResolutionInfo({
    required this.packageName,
  });
  static PubPackageCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final packageNameJson = json['packageName'];
    final packageName = packageNameJson as String;
    return PubPackageCompletionItemResolutionInfo(
      packageName: packageName,
    );
  }

  final String packageName;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['packageName'] = packageName;
    return result;
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
        if (packageName is! String) {
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
    PublishClosingLabelsParams.canParse,
    PublishClosingLabelsParams.fromJson,
  );

  PublishClosingLabelsParams({
    required this.labels,
    required this.uri,
  });
  static PublishClosingLabelsParams fromJson(Map<String, Object?> json) {
    final labelsJson = json['labels'];
    final labels = (labelsJson as List<Object?>)
        .map((item) => ClosingLabel.fromJson(item as Map<String, Object?>))
        .toList();
    final uriJson = json['uri'];
    final uri = uriJson as String;
    return PublishClosingLabelsParams(
      labels: labels,
      uri: uri,
    );
  }

  final List<ClosingLabel> labels;
  final String uri;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['labels'] = labels.map((item) => item.toJson()).toList();
    result['uri'] = uri;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (labels is! List<Object?> ||
            labels.any((item) => !ClosingLabel.canParse(item, reporter))) {
          reporter.reportError('must be of type List<ClosingLabel>');
          return false;
        }
      } finally {
        reporter.pop();
      }
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
        if (uri is! String) {
          reporter.reportError('must be of type String');
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
      return listEqual(labels, other.labels,
              (ClosingLabel a, ClosingLabel b) => a == b) &&
          uri == other.uri &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        lspHashCode(labels),
        uri,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishFlutterOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PublishFlutterOutlineParams.canParse,
    PublishFlutterOutlineParams.fromJson,
  );

  PublishFlutterOutlineParams({
    required this.outline,
    required this.uri,
  });
  static PublishFlutterOutlineParams fromJson(Map<String, Object?> json) {
    final outlineJson = json['outline'];
    final outline =
        FlutterOutline.fromJson(outlineJson as Map<String, Object?>);
    final uriJson = json['uri'];
    final uri = uriJson as String;
    return PublishFlutterOutlineParams(
      outline: outline,
      uri: uri,
    );
  }

  final FlutterOutline outline;
  final String uri;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['outline'] = outline.toJson();
    result['uri'] = uri;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (!FlutterOutline.canParse(outline, reporter)) {
          reporter.reportError('must be of type FlutterOutline');
          return false;
        }
      } finally {
        reporter.pop();
      }
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
        if (uri is! String) {
          reporter.reportError('must be of type String');
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
      return outline == other.outline && uri == other.uri && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        outline,
        uri,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishOutlineParams implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    PublishOutlineParams.canParse,
    PublishOutlineParams.fromJson,
  );

  PublishOutlineParams({
    required this.outline,
    required this.uri,
  });
  static PublishOutlineParams fromJson(Map<String, Object?> json) {
    final outlineJson = json['outline'];
    final outline = Outline.fromJson(outlineJson as Map<String, Object?>);
    final uriJson = json['uri'];
    final uri = uriJson as String;
    return PublishOutlineParams(
      outline: outline,
      uri: uri,
    );
  }

  final Outline outline;
  final String uri;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['outline'] = outline.toJson();
    result['uri'] = uri;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
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
        if (!Outline.canParse(outline, reporter)) {
          reporter.reportError('must be of type Outline');
          return false;
        }
      } finally {
        reporter.pop();
      }
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
        if (uri is! String) {
          reporter.reportError('must be of type String');
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
      return outline == other.outline && uri == other.uri && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        outline,
        uri,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RequestMessage implements IncomingMessage, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    RequestMessage.canParse,
    RequestMessage.fromJson,
  );

  RequestMessage({
    this.clientRequestTime,
    required this.id,
    required this.jsonrpc,
    required this.method,
    this.params,
  });
  static RequestMessage fromJson(Map<String, Object?> json) {
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final idJson = json['id'];
    final id = idJson is int
        ? Either2<int, String>.t1(idJson)
        : (idJson is String
            ? Either2<int, String>.t2(idJson)
            : (throw '''$idJson was not one of (int, String)'''));
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

  @override
  final int? clientRequestTime;
  final Either2<int, String> id;
  @override
  final String jsonrpc;
  @override
  final Method method;
  @override
  final Object? params;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('clientRequestTime');
      try {
        final clientRequestTime = obj['clientRequestTime'];
        if (clientRequestTime != null && clientRequestTime is! int) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('id');
      try {
        if (!obj.containsKey('id')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final id = obj['id'];
        if (id == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (id is! int && id is! String) {
          reporter.reportError('must be of type Either2<int, String>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('jsonrpc');
      try {
        if (!obj.containsKey('jsonrpc')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final jsonrpc = obj['jsonrpc'];
        if (jsonrpc == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (jsonrpc is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('method');
      try {
        if (!obj.containsKey('method')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final method = obj['method'];
        if (method == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!Method.canParse(method, reporter)) {
          reporter.reportError('must be of type Method');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type RequestMessage');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is RequestMessage && other.runtimeType == RequestMessage) {
      return clientRequestTime == other.clientRequestTime &&
          id == other.id &&
          jsonrpc == other.jsonrpc &&
          method == other.method &&
          params == other.params &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        id,
        jsonrpc,
        method,
        params,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ResponseError implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ResponseError.canParse,
    ResponseError.fromJson,
  );

  ResponseError({
    required this.code,
    this.data,
    required this.message,
  });
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

  final ErrorCodes code;

  /// A string that contains additional information about the error. Can be
  /// omitted.
  final String? data;
  final String message;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('code');
      try {
        if (!obj.containsKey('code')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final code = obj['code'];
        if (code == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (!ErrorCodes.canParse(code, reporter)) {
          reporter.reportError('must be of type ErrorCodes');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('data');
      try {
        final data = obj['data'];
        if (data != null && data is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('message');
      try {
        if (!obj.containsKey('message')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final message = obj['message'];
        if (message == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (message is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type ResponseError');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is ResponseError && other.runtimeType == ResponseError) {
      return code == other.code &&
          data == other.data &&
          message == other.message &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        code,
        data,
        message,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ResponseMessage implements Message, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ResponseMessage.canParse,
    ResponseMessage.fromJson,
  );

  ResponseMessage({
    this.clientRequestTime,
    this.error,
    this.id,
    required this.jsonrpc,
    this.result,
  });
  static ResponseMessage fromJson(Map<String, Object?> json) {
    final clientRequestTimeJson = json['clientRequestTime'];
    final clientRequestTime = clientRequestTimeJson as int?;
    final errorJson = json['error'];
    final error = errorJson != null
        ? ResponseError.fromJson(errorJson as Map<String, Object?>)
        : null;
    final idJson = json['id'];
    final id = idJson == null
        ? null
        : (idJson is int
            ? Either2<int, String>.t1(idJson)
            : (idJson is String
                ? Either2<int, String>.t2(idJson)
                : (throw '''$idJson was not one of (int, String)''')));
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

  @override
  final int? clientRequestTime;
  final ResponseError? error;
  final Either2<int, String>? id;
  @override
  final String jsonrpc;
  final Object? result;

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

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('clientRequestTime');
      try {
        final clientRequestTime = obj['clientRequestTime'];
        if (clientRequestTime != null && clientRequestTime is! int) {
          reporter.reportError('must be of type int');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('error');
      try {
        final error = obj['error'];
        if (error != null && !ResponseError.canParse(error, reporter)) {
          reporter.reportError('must be of type ResponseError');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('id');
      try {
        if (!obj.containsKey('id')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final id = obj['id'];
        if (id != null && id is! int && id is! String) {
          reporter.reportError('must be of type Either2<int, String>');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('jsonrpc');
      try {
        if (!obj.containsKey('jsonrpc')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final jsonrpc = obj['jsonrpc'];
        if (jsonrpc == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (jsonrpc is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type ResponseMessage');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is ResponseMessage && other.runtimeType == ResponseMessage) {
      return clientRequestTime == other.clientRequestTime &&
          error == other.error &&
          id == other.id &&
          jsonrpc == other.jsonrpc &&
          result == other.result &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        clientRequestTime,
        error,
        id,
        jsonrpc,
        result,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class SnippetTextEdit implements TextEdit, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    SnippetTextEdit.canParse,
    SnippetTextEdit.fromJson,
  );

  SnippetTextEdit({
    required this.insertTextFormat,
    required this.newText,
    required this.range,
  });
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

  final InsertTextFormat insertTextFormat;

  /// The string to be inserted. For delete operations use an empty string.
  @override
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  @override
  final Range range;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['insertTextFormat'] = insertTextFormat.toJson();
    result['newText'] = newText;
    result['range'] = range.toJson();
    return result;
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
        if (!InsertTextFormat.canParse(insertTextFormat, reporter)) {
          reporter.reportError('must be of type InsertTextFormat');
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
        if (newText is! String) {
          reporter.reportError('must be of type String');
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
        if (!Range.canParse(range, reporter)) {
          reporter.reportError('must be of type Range');
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
          newText == other.newText &&
          range == other.range &&
          true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        insertTextFormat,
        newText,
        range,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ValidateRefactorResult implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    ValidateRefactorResult.canParse,
    ValidateRefactorResult.fromJson,
  );

  ValidateRefactorResult({
    this.message,
    required this.valid,
  });
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

  final String? message;
  final bool valid;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    if (message != null) {
      result['message'] = message;
    }
    result['valid'] = valid;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      reporter.push('message');
      try {
        final message = obj['message'];
        if (message != null && message is! String) {
          reporter.reportError('must be of type String');
          return false;
        }
      } finally {
        reporter.pop();
      }
      reporter.push('valid');
      try {
        if (!obj.containsKey('valid')) {
          reporter.reportError('must not be undefined');
          return false;
        }
        final valid = obj['valid'];
        if (valid == null) {
          reporter.reportError('must not be null');
          return false;
        }
        if (valid is! bool) {
          reporter.reportError('must be of type bool');
          return false;
        }
      } finally {
        reporter.pop();
      }
      return true;
    } else {
      reporter.reportError('must be of type ValidateRefactorResult');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is ValidateRefactorResult &&
        other.runtimeType == ValidateRefactorResult) {
      return message == other.message && valid == other.valid && true;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        message,
        valid,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}
