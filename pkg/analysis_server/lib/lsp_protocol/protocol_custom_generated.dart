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

typedef DocumentUri = String;
typedef LSPAny = Object?;
typedef LSPObject = Object;
typedef TextDocumentEditEdits
    = List<Either3<AnnotatedTextEdit, SnippetTextEdit, TextEdit>>;

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
      return _canParseBool(obj, reporter, 'isAnalyzing',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type AnalyzerStatusParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyzerStatusParams &&
        other.runtimeType == AnalyzerStatusParams &&
        isAnalyzing == other.isAnalyzing;
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

  @override
  bool operator ==(Object other) {
    return other is ClosingLabel &&
        other.runtimeType == ClosingLabel &&
        label == other.label &&
        range == other.range;
  }

  @override
  int get hashCode => Object.hash(
        label,
        range,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Information about one of the arguments needed by the command.
///
/// A list of parameters is sent in the `data` field of the `CodeAction`
/// returned by the server. The values of the parameters should appear in the
/// `args` field of the `Command` sent to the server in the same order as the
/// corresponding parameters.
class CommandParameter implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    CommandParameter.canParse,
    CommandParameter.fromJson,
  );

  CommandParameter({
    required this.defaultValue,
    required this.label,
    required this.type,
  });
  static CommandParameter fromJson(Map<String, Object?> json) {
    final defaultValueJson = json['defaultValue'];
    final defaultValue = defaultValueJson as String;
    final labelJson = json['label'];
    final label = labelJson as String;
    final typeJson = json['type'];
    final type = CommandParameterType.fromJson(typeJson as String);
    return CommandParameter(
      defaultValue: defaultValue,
      label: label,
      type: type,
    );
  }

  /// The default value for the parameter.
  final String defaultValue;

  /// A human-readable label to be displayed in the UI affordance used to prompt
  /// the user for the value of the parameter.
  final String label;

  /// The type of the value of the parameter.
  final CommandParameterType type;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['defaultValue'] = defaultValue;
    result['label'] = label;
    result['type'] = type.toJson();
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'defaultValue',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      if (!_canParseString(obj, reporter, 'label',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseCommandParameterType(obj, reporter, 'type',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type CommandParameter');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is CommandParameter &&
        other.runtimeType == CommandParameter &&
        defaultValue == other.defaultValue &&
        label == other.label &&
        type == other.type;
  }

  @override
  int get hashCode => Object.hash(
        defaultValue,
        label,
        type,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// The type of the value associated with a CommandParameter. All values are
/// encoded as strings, but the type indicates how the string will be decoded by
/// the server.
class CommandParameterType implements ToJsonable {
  const CommandParameterType(this._value);
  const CommandParameterType.fromJson(this._value);

  final String _value;

  static bool canParse(Object? obj, LspJsonReporter reporter) => obj is String;

  /// The type associated with a bool value.
  ///
  /// The value must either be `'true'` or `'false'`.
  static const boolean = CommandParameterType('boolean');

  /// The type associated with a value representing a path to a file.
  static const filePath = CommandParameterType('filePath');

  /// The type associated with a string value.
  static const string = CommandParameterType('string');

  @override
  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) =>
      other is CommandParameterType && other._value == _value;
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = LspJsonHandler(
    CompletionItemResolutionInfo.canParse,
    CompletionItemResolutionInfo.fromJson,
  );

  static CompletionItemResolutionInfo fromJson(Map<String, Object?> json) {
    if (DartNotImportedCompletionResolutionInfo.canParse(
        json, nullLspJsonReporter)) {
      return DartNotImportedCompletionResolutionInfo.fromJson(json);
    }
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
    return other is CompletionItemResolutionInfo &&
        other.runtimeType == CompletionItemResolutionInfo;
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
      return _canParseInt(obj, reporter, 'port',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type DartDiagnosticServer');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DartDiagnosticServer &&
        other.runtimeType == DartDiagnosticServer &&
        port == other.port;
  }

  @override
  int get hashCode => port.hashCode;

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartNotImportedCompletionResolutionInfo
    implements CompletionItemResolutionInfo, ToJsonable {
  static const jsonHandler = LspJsonHandler(
    DartNotImportedCompletionResolutionInfo.canParse,
    DartNotImportedCompletionResolutionInfo.fromJson,
  );

  DartNotImportedCompletionResolutionInfo({
    required this.file,
    required this.libraryUri,
  });
  static DartNotImportedCompletionResolutionInfo fromJson(
      Map<String, Object?> json) {
    final fileJson = json['file'];
    final file = fileJson as String;
    final libraryUriJson = json['libraryUri'];
    final libraryUri = libraryUriJson as String;
    return DartNotImportedCompletionResolutionInfo(
      file: file,
      libraryUri: libraryUri,
    );
  }

  /// The file where the completion is being inserted.
  ///
  /// This is used to compute where to add the import.
  final String file;

  /// The URI to be imported if this completion is selected.
  final String libraryUri;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['file'] = file;
    result['libraryUri'] = libraryUri;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'file',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'libraryUri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type DartNotImportedCompletionResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DartNotImportedCompletionResolutionInfo &&
        other.runtimeType == DartNotImportedCompletionResolutionInfo &&
        file == other.file &&
        libraryUri == other.libraryUri;
  }

  @override
  int get hashCode => Object.hash(
        file,
        libraryUri,
      );

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
    required this.file,
    required this.libId,
  });
  static DartSuggestionSetCompletionItemResolutionInfo fromJson(
      Map<String, Object?> json) {
    final fileJson = json['file'];
    final file = fileJson as String;
    final libIdJson = json['libId'];
    final libId = libIdJson as int;
    return DartSuggestionSetCompletionItemResolutionInfo(
      file: file,
      libId: libId,
    );
  }

  final String file;
  final int libId;

  @override
  Map<String, Object?> toJson() {
    var result = <String, Object?>{};
    result['file'] = file;
    result['libId'] = libId;
    return result;
  }

  static bool canParse(Object? obj, LspJsonReporter reporter) {
    if (obj is Map<String, Object?>) {
      if (!_canParseString(obj, reporter, 'file',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseInt(obj, reporter, 'libId',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type DartSuggestionSetCompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DartSuggestionSetCompletionItemResolutionInfo &&
        other.runtimeType == DartSuggestionSetCompletionItemResolutionInfo &&
        file == other.file &&
        libId == other.libId;
  }

  @override
  int get hashCode => Object.hash(
        file,
        libId,
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

  @override
  bool operator ==(Object other) {
    return other is FlutterOutline &&
        other.runtimeType == FlutterOutline &&
        listEqual(attributes, other.attributes,
            (FlutterOutlineAttribute a, FlutterOutlineAttribute b) => a == b) &&
        listEqual(children, other.children,
            (FlutterOutline a, FlutterOutline b) => a == b) &&
        className == other.className &&
        codeRange == other.codeRange &&
        dartElement == other.dartElement &&
        kind == other.kind &&
        label == other.label &&
        range == other.range &&
        variableName == other.variableName;
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

  @override
  bool operator ==(Object other) {
    return other is FlutterOutlineAttribute &&
        other.runtimeType == FlutterOutlineAttribute &&
        label == other.label &&
        name == other.name &&
        valueRange == other.valueRange;
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
  final LSPAny params;

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

  @override
  bool operator ==(Object other) {
    return other is Message &&
        other.runtimeType == Message &&
        clientRequestTime == other.clientRequestTime &&
        jsonrpc == other.jsonrpc;
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
  final LSPAny params;

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

  @override
  bool operator ==(Object other) {
    return other is Outline &&
        other.runtimeType == Outline &&
        listEqual(children, other.children, (Outline a, Outline b) => a == b) &&
        codeRange == other.codeRange &&
        element == other.element &&
        range == other.range;
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
      return _canParseString(obj, reporter, 'packageName',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError(
          'must be of type PubPackageCompletionItemResolutionInfo');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PubPackageCompletionItemResolutionInfo &&
        other.runtimeType == PubPackageCompletionItemResolutionInfo &&
        packageName == other.packageName;
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
      if (!_canParseListClosingLabel(obj, reporter, 'labels',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishClosingLabelsParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PublishClosingLabelsParams &&
        other.runtimeType == PublishClosingLabelsParams &&
        listEqual(
            labels, other.labels, (ClosingLabel a, ClosingLabel b) => a == b) &&
        uri == other.uri;
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
      if (!_canParseFlutterOutline(obj, reporter, 'outline',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishFlutterOutlineParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PublishFlutterOutlineParams &&
        other.runtimeType == PublishFlutterOutlineParams &&
        outline == other.outline &&
        uri == other.uri;
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
      if (!_canParseOutline(obj, reporter, 'outline',
          allowsUndefined: false, allowsNull: false)) {
        return false;
      }
      return _canParseString(obj, reporter, 'uri',
          allowsUndefined: false, allowsNull: false);
    } else {
      reporter.reportError('must be of type PublishOutlineParams');
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PublishOutlineParams &&
        other.runtimeType == PublishOutlineParams &&
        outline == other.outline &&
        uri == other.uri;
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

  @override
  final int? clientRequestTime;
  final Either2<int, String> id;
  @override
  final String jsonrpc;
  @override
  final Method method;
  @override
  final LSPAny params;

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

  @override
  bool operator ==(Object other) {
    return other is ResponseError &&
        other.runtimeType == ResponseError &&
        code == other.code &&
        data == other.data &&
        message == other.message;
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

  @override
  final int? clientRequestTime;
  final ResponseError? error;
  final Either2<int, String>? id;
  @override
  final String jsonrpc;
  final LSPAny result;

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

  @override
  bool operator ==(Object other) {
    return other is SnippetTextEdit &&
        other.runtimeType == SnippetTextEdit &&
        insertTextFormat == other.insertTextFormat &&
        newText == other.newText &&
        range == other.range;
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

  @override
  bool operator ==(Object other) {
    return other is ValidateRefactorResult &&
        other.runtimeType == ValidateRefactorResult &&
        message == other.message &&
        valid == other.valid;
  }

  @override
  int get hashCode => Object.hash(
        message,
        valid,
      );

  @override
  String toString() => jsonEncoder.convert(toJson());
}

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

bool _canParseCommandParameterType(
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
        !CommandParameterType.canParse(value, reporter)) {
      reporter.reportError('must be of type CommandParameterType');
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

Either2<int, String> _eitherIntString(Object? value) {
  return value is int
      ? Either2.t1(value)
      : value is String
          ? Either2.t2(value)
          : throw '$value was not one of (int, String)';
}
