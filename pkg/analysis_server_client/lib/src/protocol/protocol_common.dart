// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server_client/src/protocol/protocol_util.dart';
import 'package:analysis_server_client/src/protocol/protocol_base.dart';
import 'package:analysis_server_client/src/protocol/protocol_internal.dart';

/// AddContentOverlay
///
/// {
///   "type": "add"
///   "content": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AddContentOverlay implements HasToJson {
  String _content;

  /// The new content of the file.
  String get content => _content;

  /// The new content of the file.
  set content(String value) {
    assert(value != null);
    _content = value;
  }

  AddContentOverlay(String content) {
    this.content = content;
  }

  factory AddContentOverlay.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      if (json['type'] != 'add') {
        throw jsonDecoder.mismatch(jsonPath, 'equal add', json);
      }
      String content;
      if (json.containsKey('content')) {
        content =
            jsonDecoder.decodeString(jsonPath + '.content', json['content']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'content');
      }
      return AddContentOverlay(content);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AddContentOverlay', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['type'] = 'add';
    result['content'] = content;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AddContentOverlay) {
      return content == other.content;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, 704418402);
    hash = JenkinsSmiHash.combine(hash, content.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// AnalysisError
///
/// {
///   "severity": AnalysisErrorSeverity
///   "type": AnalysisErrorType
///   "location": Location
///   "message": String
///   "correction": optional String
///   "code": String
///   "url": optional String
///   "contextMessages": optional List<DiagnosticMessage>
///   "hasFix": optional bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisError implements HasToJson {
  AnalysisErrorSeverity _severity;

  AnalysisErrorType _type;

  Location _location;

  String _message;

  String _correction;

  String _code;

  String _url;

  List<DiagnosticMessage> _contextMessages;

  bool _hasFix;

  /// The severity of the error.
  AnalysisErrorSeverity get severity => _severity;

  /// The severity of the error.
  set severity(AnalysisErrorSeverity value) {
    assert(value != null);
    _severity = value;
  }

  /// The type of the error.
  AnalysisErrorType get type => _type;

  /// The type of the error.
  set type(AnalysisErrorType value) {
    assert(value != null);
    _type = value;
  }

  /// The location associated with the error.
  Location get location => _location;

  /// The location associated with the error.
  set location(Location value) {
    assert(value != null);
    _location = value;
  }

  /// The message to be displayed for this error. The message should indicate
  /// what is wrong with the code and why it is wrong.
  String get message => _message;

  /// The message to be displayed for this error. The message should indicate
  /// what is wrong with the code and why it is wrong.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// The correction message to be displayed for this error. The correction
  /// message should indicate how the user can fix the error. The field is
  /// omitted if there is no correction message associated with the error code.
  String get correction => _correction;

  /// The correction message to be displayed for this error. The correction
  /// message should indicate how the user can fix the error. The field is
  /// omitted if there is no correction message associated with the error code.
  set correction(String value) {
    _correction = value;
  }

  /// The name, as a string, of the error code associated with this error.
  String get code => _code;

  /// The name, as a string, of the error code associated with this error.
  set code(String value) {
    assert(value != null);
    _code = value;
  }

  /// The URL of a page containing documentation associated with this error.
  String get url => _url;

  /// The URL of a page containing documentation associated with this error.
  set url(String value) {
    _url = value;
  }

  /// Additional messages associated with this diagnostic that provide context
  /// to help the user understand the diagnostic.
  List<DiagnosticMessage> get contextMessages => _contextMessages;

  /// Additional messages associated with this diagnostic that provide context
  /// to help the user understand the diagnostic.
  set contextMessages(List<DiagnosticMessage> value) {
    _contextMessages = value;
  }

  /// A hint to indicate to interested clients that this error has an
  /// associated fix (or fixes). The absence of this field implies there are
  /// not known to be fixes. Note that since the operation to calculate whether
  /// fixes apply needs to be performant it is possible that complicated tests
  /// will be skipped and a false negative returned. For this reason, this
  /// attribute should be treated as a "hint". Despite the possibility of false
  /// negatives, no false positives should be returned. If a client sees this
  /// flag set they can proceed with the confidence that there are in fact
  /// associated fixes.
  bool get hasFix => _hasFix;

  /// A hint to indicate to interested clients that this error has an
  /// associated fix (or fixes). The absence of this field implies there are
  /// not known to be fixes. Note that since the operation to calculate whether
  /// fixes apply needs to be performant it is possible that complicated tests
  /// will be skipped and a false negative returned. For this reason, this
  /// attribute should be treated as a "hint". Despite the possibility of false
  /// negatives, no false positives should be returned. If a client sees this
  /// flag set they can proceed with the confidence that there are in fact
  /// associated fixes.
  set hasFix(bool value) {
    _hasFix = value;
  }

  AnalysisError(AnalysisErrorSeverity severity, AnalysisErrorType type,
      Location location, String message, String code,
      {String correction,
      String url,
      List<DiagnosticMessage> contextMessages,
      bool hasFix}) {
    this.severity = severity;
    this.type = type;
    this.location = location;
    this.message = message;
    this.correction = correction;
    this.code = code;
    this.url = url;
    this.contextMessages = contextMessages;
    this.hasFix = hasFix;
  }

  factory AnalysisError.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      AnalysisErrorSeverity severity;
      if (json.containsKey('severity')) {
        severity = AnalysisErrorSeverity.fromJson(
            jsonDecoder, jsonPath + '.severity', json['severity']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'severity');
      }
      AnalysisErrorType type;
      if (json.containsKey('type')) {
        type = AnalysisErrorType.fromJson(
            jsonDecoder, jsonPath + '.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'location');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String correction;
      if (json.containsKey('correction')) {
        correction = jsonDecoder.decodeString(
            jsonPath + '.correction', json['correction']);
      }
      String code;
      if (json.containsKey('code')) {
        code = jsonDecoder.decodeString(jsonPath + '.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      String url;
      if (json.containsKey('url')) {
        url = jsonDecoder.decodeString(jsonPath + '.url', json['url']);
      }
      List<DiagnosticMessage> contextMessages;
      if (json.containsKey('contextMessages')) {
        contextMessages = jsonDecoder.decodeList(
            jsonPath + '.contextMessages',
            json['contextMessages'],
            (String jsonPath, Object json) =>
                DiagnosticMessage.fromJson(jsonDecoder, jsonPath, json));
      }
      bool hasFix;
      if (json.containsKey('hasFix')) {
        hasFix = jsonDecoder.decodeBool(jsonPath + '.hasFix', json['hasFix']);
      }
      return AnalysisError(severity, type, location, message, code,
          correction: correction,
          url: url,
          contextMessages: contextMessages,
          hasFix: hasFix);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisError', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['severity'] = severity.toJson();
    result['type'] = type.toJson();
    result['location'] = location.toJson();
    result['message'] = message;
    if (correction != null) {
      result['correction'] = correction;
    }
    result['code'] = code;
    if (url != null) {
      result['url'] = url;
    }
    if (contextMessages != null) {
      result['contextMessages'] = contextMessages
          .map((DiagnosticMessage value) => value.toJson())
          .toList();
    }
    if (hasFix != null) {
      result['hasFix'] = hasFix;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisError) {
      return severity == other.severity &&
          type == other.type &&
          location == other.location &&
          message == other.message &&
          correction == other.correction &&
          code == other.code &&
          url == other.url &&
          listEqual(contextMessages, other.contextMessages,
              (DiagnosticMessage a, DiagnosticMessage b) => a == b) &&
          hasFix == other.hasFix;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, correction.hashCode);
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, url.hashCode);
    hash = JenkinsSmiHash.combine(hash, contextMessages.hashCode);
    hash = JenkinsSmiHash.combine(hash, hasFix.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// AnalysisErrorSeverity
///
/// enum {
///   INFO
///   WARNING
///   ERROR
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorSeverity implements Enum {
  static const AnalysisErrorSeverity INFO = AnalysisErrorSeverity._('INFO');

  static const AnalysisErrorSeverity WARNING =
      AnalysisErrorSeverity._('WARNING');

  static const AnalysisErrorSeverity ERROR = AnalysisErrorSeverity._('ERROR');

  /// A list containing all of the enum values that are defined.
  static const List<AnalysisErrorSeverity> VALUES = <AnalysisErrorSeverity>[
    INFO,
    WARNING,
    ERROR
  ];

  @override
  final String name;

  const AnalysisErrorSeverity._(this.name);

  factory AnalysisErrorSeverity(String name) {
    switch (name) {
      case 'INFO':
        return INFO;
      case 'WARNING':
        return WARNING;
      case 'ERROR':
        return ERROR;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory AnalysisErrorSeverity.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return AnalysisErrorSeverity(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'AnalysisErrorSeverity', json);
  }

  @override
  String toString() => 'AnalysisErrorSeverity.$name';

  String toJson() => name;
}

/// AnalysisErrorType
///
/// enum {
///   CHECKED_MODE_COMPILE_TIME_ERROR
///   COMPILE_TIME_ERROR
///   HINT
///   LINT
///   STATIC_TYPE_WARNING
///   STATIC_WARNING
///   SYNTACTIC_ERROR
///   TODO
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorType implements Enum {
  static const AnalysisErrorType CHECKED_MODE_COMPILE_TIME_ERROR =
      AnalysisErrorType._('CHECKED_MODE_COMPILE_TIME_ERROR');

  static const AnalysisErrorType COMPILE_TIME_ERROR =
      AnalysisErrorType._('COMPILE_TIME_ERROR');

  static const AnalysisErrorType HINT = AnalysisErrorType._('HINT');

  static const AnalysisErrorType LINT = AnalysisErrorType._('LINT');

  static const AnalysisErrorType STATIC_TYPE_WARNING =
      AnalysisErrorType._('STATIC_TYPE_WARNING');

  static const AnalysisErrorType STATIC_WARNING =
      AnalysisErrorType._('STATIC_WARNING');

  static const AnalysisErrorType SYNTACTIC_ERROR =
      AnalysisErrorType._('SYNTACTIC_ERROR');

  static const AnalysisErrorType TODO = AnalysisErrorType._('TODO');

  /// A list containing all of the enum values that are defined.
  static const List<AnalysisErrorType> VALUES = <AnalysisErrorType>[
    CHECKED_MODE_COMPILE_TIME_ERROR,
    COMPILE_TIME_ERROR,
    HINT,
    LINT,
    STATIC_TYPE_WARNING,
    STATIC_WARNING,
    SYNTACTIC_ERROR,
    TODO
  ];

  @override
  final String name;

  const AnalysisErrorType._(this.name);

  factory AnalysisErrorType(String name) {
    switch (name) {
      case 'CHECKED_MODE_COMPILE_TIME_ERROR':
        return CHECKED_MODE_COMPILE_TIME_ERROR;
      case 'COMPILE_TIME_ERROR':
        return COMPILE_TIME_ERROR;
      case 'HINT':
        return HINT;
      case 'LINT':
        return LINT;
      case 'STATIC_TYPE_WARNING':
        return STATIC_TYPE_WARNING;
      case 'STATIC_WARNING':
        return STATIC_WARNING;
      case 'SYNTACTIC_ERROR':
        return SYNTACTIC_ERROR;
      case 'TODO':
        return TODO;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory AnalysisErrorType.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return AnalysisErrorType(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'AnalysisErrorType', json);
  }

  @override
  String toString() => 'AnalysisErrorType.$name';

  String toJson() => name;
}

/// ChangeContentOverlay
///
/// {
///   "type": "change"
///   "edits": List<SourceEdit>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ChangeContentOverlay implements HasToJson {
  List<SourceEdit> _edits;

  /// The edits to be applied to the file.
  List<SourceEdit> get edits => _edits;

  /// The edits to be applied to the file.
  set edits(List<SourceEdit> value) {
    assert(value != null);
    _edits = value;
  }

  ChangeContentOverlay(List<SourceEdit> edits) {
    this.edits = edits;
  }

  factory ChangeContentOverlay.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      if (json['type'] != 'change') {
        throw jsonDecoder.mismatch(jsonPath, 'equal change', json);
      }
      List<SourceEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      return ChangeContentOverlay(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ChangeContentOverlay', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['type'] = 'change';
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ChangeContentOverlay) {
      return listEqual(
          edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, 873118866);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// CompletionSuggestion
///
/// {
///   "kind": CompletionSuggestionKind
///   "relevance": int
///   "completion": String
///   "displayText": optional String
///   "selectionOffset": int
///   "selectionLength": int
///   "isDeprecated": bool
///   "isPotential": bool
///   "docSummary": optional String
///   "docComplete": optional String
///   "declaringType": optional String
///   "defaultArgumentListString": optional String
///   "defaultArgumentListTextRanges": optional List<int>
///   "element": optional Element
///   "returnType": optional String
///   "parameterNames": optional List<String>
///   "parameterTypes": optional List<String>
///   "requiredParameterCount": optional int
///   "hasNamedParameters": optional bool
///   "parameterName": optional String
///   "parameterType": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSuggestion implements HasToJson {
  CompletionSuggestionKind _kind;

  int _relevance;

  String _completion;

  String _displayText;

  int _selectionOffset;

  int _selectionLength;

  bool _isDeprecated;

  bool _isPotential;

  String _docSummary;

  String _docComplete;

  String _declaringType;

  String _defaultArgumentListString;

  List<int> _defaultArgumentListTextRanges;

  Element _element;

  String _returnType;

  List<String> _parameterNames;

  List<String> _parameterTypes;

  int _requiredParameterCount;

  bool _hasNamedParameters;

  String _parameterName;

  String _parameterType;

  /// The kind of element being suggested.
  CompletionSuggestionKind get kind => _kind;

  /// The kind of element being suggested.
  set kind(CompletionSuggestionKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The relevance of this completion suggestion where a higher number
  /// indicates a higher relevance.
  int get relevance => _relevance;

  /// The relevance of this completion suggestion where a higher number
  /// indicates a higher relevance.
  set relevance(int value) {
    assert(value != null);
    _relevance = value;
  }

  /// The identifier to be inserted if the suggestion is selected. If the
  /// suggestion is for a method or function, the client might want to
  /// additionally insert a template for the parameters. The information
  /// required in order to do so is contained in other fields.
  String get completion => _completion;

  /// The identifier to be inserted if the suggestion is selected. If the
  /// suggestion is for a method or function, the client might want to
  /// additionally insert a template for the parameters. The information
  /// required in order to do so is contained in other fields.
  set completion(String value) {
    assert(value != null);
    _completion = value;
  }

  /// Text to be displayed in, for example, a completion pop-up. This field is
  /// only defined if the displayed text should be different than the
  /// completion. Otherwise it is omitted.
  String get displayText => _displayText;

  /// Text to be displayed in, for example, a completion pop-up. This field is
  /// only defined if the displayed text should be different than the
  /// completion. Otherwise it is omitted.
  set displayText(String value) {
    _displayText = value;
  }

  /// The offset, relative to the beginning of the completion, of where the
  /// selection should be placed after insertion.
  int get selectionOffset => _selectionOffset;

  /// The offset, relative to the beginning of the completion, of where the
  /// selection should be placed after insertion.
  set selectionOffset(int value) {
    assert(value != null);
    _selectionOffset = value;
  }

  /// The number of characters that should be selected after insertion.
  int get selectionLength => _selectionLength;

  /// The number of characters that should be selected after insertion.
  set selectionLength(int value) {
    assert(value != null);
    _selectionLength = value;
  }

  /// True if the suggested element is deprecated.
  bool get isDeprecated => _isDeprecated;

  /// True if the suggested element is deprecated.
  set isDeprecated(bool value) {
    assert(value != null);
    _isDeprecated = value;
  }

  /// True if the element is not known to be valid for the target. This happens
  /// if the type of the target is dynamic.
  bool get isPotential => _isPotential;

  /// True if the element is not known to be valid for the target. This happens
  /// if the type of the target is dynamic.
  set isPotential(bool value) {
    assert(value != null);
    _isPotential = value;
  }

  /// An abbreviated version of the Dartdoc associated with the element being
  /// suggested. This field is omitted if there is no Dartdoc associated with
  /// the element.
  String get docSummary => _docSummary;

  /// An abbreviated version of the Dartdoc associated with the element being
  /// suggested. This field is omitted if there is no Dartdoc associated with
  /// the element.
  set docSummary(String value) {
    _docSummary = value;
  }

  /// The Dartdoc associated with the element being suggested. This field is
  /// omitted if there is no Dartdoc associated with the element.
  String get docComplete => _docComplete;

  /// The Dartdoc associated with the element being suggested. This field is
  /// omitted if there is no Dartdoc associated with the element.
  set docComplete(String value) {
    _docComplete = value;
  }

  /// The class that declares the element being suggested. This field is
  /// omitted if the suggested element is not a member of a class.
  String get declaringType => _declaringType;

  /// The class that declares the element being suggested. This field is
  /// omitted if the suggested element is not a member of a class.
  set declaringType(String value) {
    _declaringType = value;
  }

  /// A default String for use in generating argument list source contents on
  /// the client side.
  String get defaultArgumentListString => _defaultArgumentListString;

  /// A default String for use in generating argument list source contents on
  /// the client side.
  set defaultArgumentListString(String value) {
    _defaultArgumentListString = value;
  }

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  List<int> get defaultArgumentListTextRanges => _defaultArgumentListTextRanges;

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  set defaultArgumentListTextRanges(List<int> value) {
    _defaultArgumentListTextRanges = value;
  }

  /// Information about the element reference being suggested.
  Element get element => _element;

  /// Information about the element reference being suggested.
  set element(Element value) {
    _element = value;
  }

  /// The return type of the getter, function or method or the type of the
  /// field being suggested. This field is omitted if the suggested element is
  /// not a getter, function or method.
  String get returnType => _returnType;

  /// The return type of the getter, function or method or the type of the
  /// field being suggested. This field is omitted if the suggested element is
  /// not a getter, function or method.
  set returnType(String value) {
    _returnType = value;
  }

  /// The names of the parameters of the function or method being suggested.
  /// This field is omitted if the suggested element is not a setter, function
  /// or method.
  List<String> get parameterNames => _parameterNames;

  /// The names of the parameters of the function or method being suggested.
  /// This field is omitted if the suggested element is not a setter, function
  /// or method.
  set parameterNames(List<String> value) {
    _parameterNames = value;
  }

  /// The types of the parameters of the function or method being suggested.
  /// This field is omitted if the parameterNames field is omitted.
  List<String> get parameterTypes => _parameterTypes;

  /// The types of the parameters of the function or method being suggested.
  /// This field is omitted if the parameterNames field is omitted.
  set parameterTypes(List<String> value) {
    _parameterTypes = value;
  }

  /// The number of required parameters for the function or method being
  /// suggested. This field is omitted if the parameterNames field is omitted.
  int get requiredParameterCount => _requiredParameterCount;

  /// The number of required parameters for the function or method being
  /// suggested. This field is omitted if the parameterNames field is omitted.
  set requiredParameterCount(int value) {
    _requiredParameterCount = value;
  }

  /// True if the function or method being suggested has at least one named
  /// parameter. This field is omitted if the parameterNames field is omitted.
  bool get hasNamedParameters => _hasNamedParameters;

  /// True if the function or method being suggested has at least one named
  /// parameter. This field is omitted if the parameterNames field is omitted.
  set hasNamedParameters(bool value) {
    _hasNamedParameters = value;
  }

  /// The name of the optional parameter being suggested. This field is omitted
  /// if the suggestion is not the addition of an optional argument within an
  /// argument list.
  String get parameterName => _parameterName;

  /// The name of the optional parameter being suggested. This field is omitted
  /// if the suggestion is not the addition of an optional argument within an
  /// argument list.
  set parameterName(String value) {
    _parameterName = value;
  }

  /// The type of the options parameter being suggested. This field is omitted
  /// if the parameterName field is omitted.
  String get parameterType => _parameterType;

  /// The type of the options parameter being suggested. This field is omitted
  /// if the parameterName field is omitted.
  set parameterType(String value) {
    _parameterType = value;
  }

  CompletionSuggestion(
      CompletionSuggestionKind kind,
      int relevance,
      String completion,
      int selectionOffset,
      int selectionLength,
      bool isDeprecated,
      bool isPotential,
      {String displayText,
      String docSummary,
      String docComplete,
      String declaringType,
      String defaultArgumentListString,
      List<int> defaultArgumentListTextRanges,
      Element element,
      String returnType,
      List<String> parameterNames,
      List<String> parameterTypes,
      int requiredParameterCount,
      bool hasNamedParameters,
      String parameterName,
      String parameterType}) {
    this.kind = kind;
    this.relevance = relevance;
    this.completion = completion;
    this.displayText = displayText;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
    this.isDeprecated = isDeprecated;
    this.isPotential = isPotential;
    this.docSummary = docSummary;
    this.docComplete = docComplete;
    this.declaringType = declaringType;
    this.defaultArgumentListString = defaultArgumentListString;
    this.defaultArgumentListTextRanges = defaultArgumentListTextRanges;
    this.element = element;
    this.returnType = returnType;
    this.parameterNames = parameterNames;
    this.parameterTypes = parameterTypes;
    this.requiredParameterCount = requiredParameterCount;
    this.hasNamedParameters = hasNamedParameters;
    this.parameterName = parameterName;
    this.parameterType = parameterType;
  }

  factory CompletionSuggestion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      CompletionSuggestionKind kind;
      if (json.containsKey('kind')) {
        kind = CompletionSuggestionKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int relevance;
      if (json.containsKey('relevance')) {
        relevance =
            jsonDecoder.decodeInt(jsonPath + '.relevance', json['relevance']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'relevance');
      }
      String completion;
      if (json.containsKey('completion')) {
        completion = jsonDecoder.decodeString(
            jsonPath + '.completion', json['completion']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'completion');
      }
      String displayText;
      if (json.containsKey('displayText')) {
        displayText = jsonDecoder.decodeString(
            jsonPath + '.displayText', json['displayText']);
      }
      int selectionOffset;
      if (json.containsKey('selectionOffset')) {
        selectionOffset = jsonDecoder.decodeInt(
            jsonPath + '.selectionOffset', json['selectionOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionOffset');
      }
      int selectionLength;
      if (json.containsKey('selectionLength')) {
        selectionLength = jsonDecoder.decodeInt(
            jsonPath + '.selectionLength', json['selectionLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionLength');
      }
      bool isDeprecated;
      if (json.containsKey('isDeprecated')) {
        isDeprecated = jsonDecoder.decodeBool(
            jsonPath + '.isDeprecated', json['isDeprecated']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isDeprecated');
      }
      bool isPotential;
      if (json.containsKey('isPotential')) {
        isPotential = jsonDecoder.decodeBool(
            jsonPath + '.isPotential', json['isPotential']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isPotential');
      }
      String docSummary;
      if (json.containsKey('docSummary')) {
        docSummary = jsonDecoder.decodeString(
            jsonPath + '.docSummary', json['docSummary']);
      }
      String docComplete;
      if (json.containsKey('docComplete')) {
        docComplete = jsonDecoder.decodeString(
            jsonPath + '.docComplete', json['docComplete']);
      }
      String declaringType;
      if (json.containsKey('declaringType')) {
        declaringType = jsonDecoder.decodeString(
            jsonPath + '.declaringType', json['declaringType']);
      }
      String defaultArgumentListString;
      if (json.containsKey('defaultArgumentListString')) {
        defaultArgumentListString = jsonDecoder.decodeString(
            jsonPath + '.defaultArgumentListString',
            json['defaultArgumentListString']);
      }
      List<int> defaultArgumentListTextRanges;
      if (json.containsKey('defaultArgumentListTextRanges')) {
        defaultArgumentListTextRanges = jsonDecoder.decodeList(
            jsonPath + '.defaultArgumentListTextRanges',
            json['defaultArgumentListTextRanges'],
            jsonDecoder.decodeInt);
      }
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      }
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
            jsonPath + '.returnType', json['returnType']);
      }
      List<String> parameterNames;
      if (json.containsKey('parameterNames')) {
        parameterNames = jsonDecoder.decodeList(jsonPath + '.parameterNames',
            json['parameterNames'], jsonDecoder.decodeString);
      }
      List<String> parameterTypes;
      if (json.containsKey('parameterTypes')) {
        parameterTypes = jsonDecoder.decodeList(jsonPath + '.parameterTypes',
            json['parameterTypes'], jsonDecoder.decodeString);
      }
      int requiredParameterCount;
      if (json.containsKey('requiredParameterCount')) {
        requiredParameterCount = jsonDecoder.decodeInt(
            jsonPath + '.requiredParameterCount',
            json['requiredParameterCount']);
      }
      bool hasNamedParameters;
      if (json.containsKey('hasNamedParameters')) {
        hasNamedParameters = jsonDecoder.decodeBool(
            jsonPath + '.hasNamedParameters', json['hasNamedParameters']);
      }
      String parameterName;
      if (json.containsKey('parameterName')) {
        parameterName = jsonDecoder.decodeString(
            jsonPath + '.parameterName', json['parameterName']);
      }
      String parameterType;
      if (json.containsKey('parameterType')) {
        parameterType = jsonDecoder.decodeString(
            jsonPath + '.parameterType', json['parameterType']);
      }
      return CompletionSuggestion(kind, relevance, completion, selectionOffset,
          selectionLength, isDeprecated, isPotential,
          displayText: displayText,
          docSummary: docSummary,
          docComplete: docComplete,
          declaringType: declaringType,
          defaultArgumentListString: defaultArgumentListString,
          defaultArgumentListTextRanges: defaultArgumentListTextRanges,
          element: element,
          returnType: returnType,
          parameterNames: parameterNames,
          parameterTypes: parameterTypes,
          requiredParameterCount: requiredParameterCount,
          hasNamedParameters: hasNamedParameters,
          parameterName: parameterName,
          parameterType: parameterType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'CompletionSuggestion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['relevance'] = relevance;
    result['completion'] = completion;
    if (displayText != null) {
      result['displayText'] = displayText;
    }
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    result['isDeprecated'] = isDeprecated;
    result['isPotential'] = isPotential;
    if (docSummary != null) {
      result['docSummary'] = docSummary;
    }
    if (docComplete != null) {
      result['docComplete'] = docComplete;
    }
    if (declaringType != null) {
      result['declaringType'] = declaringType;
    }
    if (defaultArgumentListString != null) {
      result['defaultArgumentListString'] = defaultArgumentListString;
    }
    if (defaultArgumentListTextRanges != null) {
      result['defaultArgumentListTextRanges'] = defaultArgumentListTextRanges;
    }
    if (element != null) {
      result['element'] = element.toJson();
    }
    if (returnType != null) {
      result['returnType'] = returnType;
    }
    if (parameterNames != null) {
      result['parameterNames'] = parameterNames;
    }
    if (parameterTypes != null) {
      result['parameterTypes'] = parameterTypes;
    }
    if (requiredParameterCount != null) {
      result['requiredParameterCount'] = requiredParameterCount;
    }
    if (hasNamedParameters != null) {
      result['hasNamedParameters'] = hasNamedParameters;
    }
    if (parameterName != null) {
      result['parameterName'] = parameterName;
    }
    if (parameterType != null) {
      result['parameterType'] = parameterType;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionSuggestion) {
      return kind == other.kind &&
          relevance == other.relevance &&
          completion == other.completion &&
          displayText == other.displayText &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength &&
          isDeprecated == other.isDeprecated &&
          isPotential == other.isPotential &&
          docSummary == other.docSummary &&
          docComplete == other.docComplete &&
          declaringType == other.declaringType &&
          defaultArgumentListString == other.defaultArgumentListString &&
          listEqual(defaultArgumentListTextRanges,
              other.defaultArgumentListTextRanges, (int a, int b) => a == b) &&
          element == other.element &&
          returnType == other.returnType &&
          listEqual(parameterNames, other.parameterNames,
              (String a, String b) => a == b) &&
          listEqual(parameterTypes, other.parameterTypes,
              (String a, String b) => a == b) &&
          requiredParameterCount == other.requiredParameterCount &&
          hasNamedParameters == other.hasNamedParameters &&
          parameterName == other.parameterName &&
          parameterType == other.parameterType;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, relevance.hashCode);
    hash = JenkinsSmiHash.combine(hash, completion.hashCode);
    hash = JenkinsSmiHash.combine(hash, displayText.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, isDeprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = JenkinsSmiHash.combine(hash, docSummary.hashCode);
    hash = JenkinsSmiHash.combine(hash, docComplete.hashCode);
    hash = JenkinsSmiHash.combine(hash, declaringType.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultArgumentListString.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultArgumentListTextRanges.hashCode);
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterNames.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterTypes.hashCode);
    hash = JenkinsSmiHash.combine(hash, requiredParameterCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, hasNamedParameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterName.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterType.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// CompletionSuggestionKind
///
/// enum {
///   ARGUMENT_LIST
///   IMPORT
///   IDENTIFIER
///   INVOCATION
///   KEYWORD
///   NAMED_ARGUMENT
///   OPTIONAL_ARGUMENT
///   OVERRIDE
///   PARAMETER
///   PACKAGE_NAME
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSuggestionKind implements Enum {
  /// A list of arguments for the method or function that is being invoked. For
  /// this suggestion kind, the completion field is a textual representation of
  /// the invocation and the parameterNames, parameterTypes, and
  /// requiredParameterCount attributes are defined.
  static const CompletionSuggestionKind ARGUMENT_LIST =
      CompletionSuggestionKind._('ARGUMENT_LIST');

  static const CompletionSuggestionKind IMPORT =
      CompletionSuggestionKind._('IMPORT');

  /// The element identifier should be inserted at the completion location. For
  /// example "someMethod" in import 'myLib.dart' show someMethod;. For
  /// suggestions of this kind, the element attribute is defined and the
  /// completion field is the element's identifier.
  static const CompletionSuggestionKind IDENTIFIER =
      CompletionSuggestionKind._('IDENTIFIER');

  /// The element is being invoked at the completion location. For example,
  /// 'someMethod' in x.someMethod();. For suggestions of this kind, the
  /// element attribute is defined and the completion field is the element's
  /// identifier.
  static const CompletionSuggestionKind INVOCATION =
      CompletionSuggestionKind._('INVOCATION');

  /// A keyword is being suggested. For suggestions of this kind, the
  /// completion is the keyword.
  static const CompletionSuggestionKind KEYWORD =
      CompletionSuggestionKind._('KEYWORD');

  /// A named argument for the current call site is being suggested. For
  /// suggestions of this kind, the completion is the named argument identifier
  /// including a trailing ':' and a space.
  static const CompletionSuggestionKind NAMED_ARGUMENT =
      CompletionSuggestionKind._('NAMED_ARGUMENT');

  static const CompletionSuggestionKind OPTIONAL_ARGUMENT =
      CompletionSuggestionKind._('OPTIONAL_ARGUMENT');

  /// An overriding implementation of a class member is being suggested.
  static const CompletionSuggestionKind OVERRIDE =
      CompletionSuggestionKind._('OVERRIDE');

  static const CompletionSuggestionKind PARAMETER =
      CompletionSuggestionKind._('PARAMETER');

  /// The name of a pub package is being suggested.
  static const CompletionSuggestionKind PACKAGE_NAME =
      CompletionSuggestionKind._('PACKAGE_NAME');

  /// A list containing all of the enum values that are defined.
  static const List<CompletionSuggestionKind> VALUES =
      <CompletionSuggestionKind>[
    ARGUMENT_LIST,
    IMPORT,
    IDENTIFIER,
    INVOCATION,
    KEYWORD,
    NAMED_ARGUMENT,
    OPTIONAL_ARGUMENT,
    OVERRIDE,
    PARAMETER,
    PACKAGE_NAME
  ];

  @override
  final String name;

  const CompletionSuggestionKind._(this.name);

  factory CompletionSuggestionKind(String name) {
    switch (name) {
      case 'ARGUMENT_LIST':
        return ARGUMENT_LIST;
      case 'IMPORT':
        return IMPORT;
      case 'IDENTIFIER':
        return IDENTIFIER;
      case 'INVOCATION':
        return INVOCATION;
      case 'KEYWORD':
        return KEYWORD;
      case 'NAMED_ARGUMENT':
        return NAMED_ARGUMENT;
      case 'OPTIONAL_ARGUMENT':
        return OPTIONAL_ARGUMENT;
      case 'OVERRIDE':
        return OVERRIDE;
      case 'PARAMETER':
        return PARAMETER;
      case 'PACKAGE_NAME':
        return PACKAGE_NAME;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory CompletionSuggestionKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return CompletionSuggestionKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'CompletionSuggestionKind', json);
  }

  @override
  String toString() => 'CompletionSuggestionKind.$name';

  String toJson() => name;
}

/// DiagnosticMessage
///
/// {
///   "message": String
///   "location": Location
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticMessage implements HasToJson {
  String _message;

  Location _location;

  /// The message to be displayed to the user.
  String get message => _message;

  /// The message to be displayed to the user.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// The location associated with or referenced by the message. Clients should
  /// provide the ability to navigate to the location.
  Location get location => _location;

  /// The location associated with or referenced by the message. Clients should
  /// provide the ability to navigate to the location.
  set location(Location value) {
    assert(value != null);
    _location = value;
  }

  DiagnosticMessage(String message, Location location) {
    this.message = message;
    this.location = location;
  }

  factory DiagnosticMessage.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'location');
      }
      return DiagnosticMessage(message, location);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'DiagnosticMessage', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['message'] = message;
    result['location'] = location.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticMessage) {
      return message == other.message && location == other.location;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// Element
///
/// {
///   "kind": ElementKind
///   "name": String
///   "location": optional Location
///   "flags": int
///   "parameters": optional String
///   "returnType": optional String
///   "typeParameters": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Element implements HasToJson {
  static const int FLAG_ABSTRACT = 0x01;
  static const int FLAG_CONST = 0x02;
  static const int FLAG_FINAL = 0x04;
  static const int FLAG_STATIC = 0x08;
  static const int FLAG_PRIVATE = 0x10;
  static const int FLAG_DEPRECATED = 0x20;

  static int makeFlags(
      {bool isAbstract = false,
      bool isConst = false,
      bool isFinal = false,
      bool isStatic = false,
      bool isPrivate = false,
      bool isDeprecated = false}) {
    var flags = 0;
    if (isAbstract) flags |= FLAG_ABSTRACT;
    if (isConst) flags |= FLAG_CONST;
    if (isFinal) flags |= FLAG_FINAL;
    if (isStatic) flags |= FLAG_STATIC;
    if (isPrivate) flags |= FLAG_PRIVATE;
    if (isDeprecated) flags |= FLAG_DEPRECATED;
    return flags;
  }

  ElementKind _kind;

  String _name;

  Location _location;

  int _flags;

  String _parameters;

  String _returnType;

  String _typeParameters;

  /// The kind of the element.
  ElementKind get kind => _kind;

  /// The kind of the element.
  set kind(ElementKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The name of the element. This is typically used as the label in the
  /// outline.
  String get name => _name;

  /// The name of the element. This is typically used as the label in the
  /// outline.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The location of the name in the declaration of the element.
  Location get location => _location;

  /// The location of the name in the declaration of the element.
  set location(Location value) {
    _location = value;
  }

  /// A bit-map containing the following flags:
  ///
  /// - 0x01 - set if the element is explicitly or implicitly abstract
  /// - 0x02 - set if the element was declared to be ‘const’
  /// - 0x04 - set if the element was declared to be ‘final’
  /// - 0x08 - set if the element is a static member of a class or is a
  ///   top-level function or field
  /// - 0x10 - set if the element is private
  /// - 0x20 - set if the element is deprecated
  int get flags => _flags;

  /// A bit-map containing the following flags:
  ///
  /// - 0x01 - set if the element is explicitly or implicitly abstract
  /// - 0x02 - set if the element was declared to be ‘const’
  /// - 0x04 - set if the element was declared to be ‘final’
  /// - 0x08 - set if the element is a static member of a class or is a
  ///   top-level function or field
  /// - 0x10 - set if the element is private
  /// - 0x20 - set if the element is deprecated
  set flags(int value) {
    assert(value != null);
    _flags = value;
  }

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()".
  String get parameters => _parameters;

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()".
  set parameters(String value) {
    _parameters = value;
  }

  /// The return type of the element. If the element is not a method or
  /// function this field will not be defined. If the element does not have a
  /// declared return type, this field will contain an empty string.
  String get returnType => _returnType;

  /// The return type of the element. If the element is not a method or
  /// function this field will not be defined. If the element does not have a
  /// declared return type, this field will contain an empty string.
  set returnType(String value) {
    _returnType = value;
  }

  /// The type parameter list for the element. If the element doesn't have type
  /// parameters, this field will not be defined.
  String get typeParameters => _typeParameters;

  /// The type parameter list for the element. If the element doesn't have type
  /// parameters, this field will not be defined.
  set typeParameters(String value) {
    _typeParameters = value;
  }

  Element(ElementKind kind, String name, int flags,
      {Location location,
      String parameters,
      String returnType,
      String typeParameters}) {
    this.kind = kind;
    this.name = name;
    this.location = location;
    this.flags = flags;
    this.parameters = parameters;
    this.returnType = returnType;
    this.typeParameters = typeParameters;
  }

  factory Element.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      ElementKind kind;
      if (json.containsKey('kind')) {
        kind =
            ElementKind.fromJson(jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      }
      int flags;
      if (json.containsKey('flags')) {
        flags = jsonDecoder.decodeInt(jsonPath + '.flags', json['flags']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'flags');
      }
      String parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeString(
            jsonPath + '.parameters', json['parameters']);
      }
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
            jsonPath + '.returnType', json['returnType']);
      }
      String typeParameters;
      if (json.containsKey('typeParameters')) {
        typeParameters = jsonDecoder.decodeString(
            jsonPath + '.typeParameters', json['typeParameters']);
      }
      return Element(kind, name, flags,
          location: location,
          parameters: parameters,
          returnType: returnType,
          typeParameters: typeParameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Element', json);
    }
  }

  bool get isAbstract => (flags & FLAG_ABSTRACT) != 0;
  bool get isConst => (flags & FLAG_CONST) != 0;
  bool get isFinal => (flags & FLAG_FINAL) != 0;
  bool get isStatic => (flags & FLAG_STATIC) != 0;
  bool get isPrivate => (flags & FLAG_PRIVATE) != 0;
  bool get isDeprecated => (flags & FLAG_DEPRECATED) != 0;

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['name'] = name;
    if (location != null) {
      result['location'] = location.toJson();
    }
    result['flags'] = flags;
    if (parameters != null) {
      result['parameters'] = parameters;
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
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Element) {
      return kind == other.kind &&
          name == other.name &&
          location == other.location &&
          flags == other.flags &&
          parameters == other.parameters &&
          returnType == other.returnType &&
          typeParameters == other.typeParameters;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, flags.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeParameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ElementKind
///
/// enum {
///   CLASS
///   CLASS_TYPE_ALIAS
///   COMPILATION_UNIT
///   CONSTRUCTOR
///   CONSTRUCTOR_INVOCATION
///   ENUM
///   ENUM_CONSTANT
///   EXTENSION
///   FIELD
///   FILE
///   FUNCTION
///   FUNCTION_INVOCATION
///   FUNCTION_TYPE_ALIAS
///   GETTER
///   LABEL
///   LIBRARY
///   LOCAL_VARIABLE
///   METHOD
///   MIXIN
///   PARAMETER
///   PREFIX
///   SETTER
///   TOP_LEVEL_VARIABLE
///   TYPE_PARAMETER
///   UNIT_TEST_GROUP
///   UNIT_TEST_TEST
///   UNKNOWN
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ElementKind implements Enum {
  static const ElementKind CLASS = ElementKind._('CLASS');

  static const ElementKind CLASS_TYPE_ALIAS = ElementKind._('CLASS_TYPE_ALIAS');

  static const ElementKind COMPILATION_UNIT = ElementKind._('COMPILATION_UNIT');

  static const ElementKind CONSTRUCTOR = ElementKind._('CONSTRUCTOR');

  static const ElementKind CONSTRUCTOR_INVOCATION =
      ElementKind._('CONSTRUCTOR_INVOCATION');

  static const ElementKind ENUM = ElementKind._('ENUM');

  static const ElementKind ENUM_CONSTANT = ElementKind._('ENUM_CONSTANT');

  static const ElementKind EXTENSION = ElementKind._('EXTENSION');

  static const ElementKind FIELD = ElementKind._('FIELD');

  static const ElementKind FILE = ElementKind._('FILE');

  static const ElementKind FUNCTION = ElementKind._('FUNCTION');

  static const ElementKind FUNCTION_INVOCATION =
      ElementKind._('FUNCTION_INVOCATION');

  static const ElementKind FUNCTION_TYPE_ALIAS =
      ElementKind._('FUNCTION_TYPE_ALIAS');

  static const ElementKind GETTER = ElementKind._('GETTER');

  static const ElementKind LABEL = ElementKind._('LABEL');

  static const ElementKind LIBRARY = ElementKind._('LIBRARY');

  static const ElementKind LOCAL_VARIABLE = ElementKind._('LOCAL_VARIABLE');

  static const ElementKind METHOD = ElementKind._('METHOD');

  static const ElementKind MIXIN = ElementKind._('MIXIN');

  static const ElementKind PARAMETER = ElementKind._('PARAMETER');

  static const ElementKind PREFIX = ElementKind._('PREFIX');

  static const ElementKind SETTER = ElementKind._('SETTER');

  static const ElementKind TOP_LEVEL_VARIABLE =
      ElementKind._('TOP_LEVEL_VARIABLE');

  static const ElementKind TYPE_PARAMETER = ElementKind._('TYPE_PARAMETER');

  static const ElementKind UNIT_TEST_GROUP = ElementKind._('UNIT_TEST_GROUP');

  static const ElementKind UNIT_TEST_TEST = ElementKind._('UNIT_TEST_TEST');

  static const ElementKind UNKNOWN = ElementKind._('UNKNOWN');

  /// A list containing all of the enum values that are defined.
  static const List<ElementKind> VALUES = <ElementKind>[
    CLASS,
    CLASS_TYPE_ALIAS,
    COMPILATION_UNIT,
    CONSTRUCTOR,
    CONSTRUCTOR_INVOCATION,
    ENUM,
    ENUM_CONSTANT,
    EXTENSION,
    FIELD,
    FILE,
    FUNCTION,
    FUNCTION_INVOCATION,
    FUNCTION_TYPE_ALIAS,
    GETTER,
    LABEL,
    LIBRARY,
    LOCAL_VARIABLE,
    METHOD,
    MIXIN,
    PARAMETER,
    PREFIX,
    SETTER,
    TOP_LEVEL_VARIABLE,
    TYPE_PARAMETER,
    UNIT_TEST_GROUP,
    UNIT_TEST_TEST,
    UNKNOWN
  ];

  @override
  final String name;

  const ElementKind._(this.name);

  factory ElementKind(String name) {
    switch (name) {
      case 'CLASS':
        return CLASS;
      case 'CLASS_TYPE_ALIAS':
        return CLASS_TYPE_ALIAS;
      case 'COMPILATION_UNIT':
        return COMPILATION_UNIT;
      case 'CONSTRUCTOR':
        return CONSTRUCTOR;
      case 'CONSTRUCTOR_INVOCATION':
        return CONSTRUCTOR_INVOCATION;
      case 'ENUM':
        return ENUM;
      case 'ENUM_CONSTANT':
        return ENUM_CONSTANT;
      case 'EXTENSION':
        return EXTENSION;
      case 'FIELD':
        return FIELD;
      case 'FILE':
        return FILE;
      case 'FUNCTION':
        return FUNCTION;
      case 'FUNCTION_INVOCATION':
        return FUNCTION_INVOCATION;
      case 'FUNCTION_TYPE_ALIAS':
        return FUNCTION_TYPE_ALIAS;
      case 'GETTER':
        return GETTER;
      case 'LABEL':
        return LABEL;
      case 'LIBRARY':
        return LIBRARY;
      case 'LOCAL_VARIABLE':
        return LOCAL_VARIABLE;
      case 'METHOD':
        return METHOD;
      case 'MIXIN':
        return MIXIN;
      case 'PARAMETER':
        return PARAMETER;
      case 'PREFIX':
        return PREFIX;
      case 'SETTER':
        return SETTER;
      case 'TOP_LEVEL_VARIABLE':
        return TOP_LEVEL_VARIABLE;
      case 'TYPE_PARAMETER':
        return TYPE_PARAMETER;
      case 'UNIT_TEST_GROUP':
        return UNIT_TEST_GROUP;
      case 'UNIT_TEST_TEST':
        return UNIT_TEST_TEST;
      case 'UNKNOWN':
        return UNKNOWN;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ElementKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ElementKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ElementKind', json);
  }

  @override
  String toString() => 'ElementKind.$name';

  String toJson() => name;
}

/// FoldingKind
///
/// enum {
///   ANNOTATIONS
///   BLOCK
///   CLASS_BODY
///   DIRECTIVES
///   DOCUMENTATION_COMMENT
///   FILE_HEADER
///   FUNCTION_BODY
///   INVOCATION
///   LITERAL
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FoldingKind implements Enum {
  static const FoldingKind ANNOTATIONS = FoldingKind._('ANNOTATIONS');

  static const FoldingKind BLOCK = FoldingKind._('BLOCK');

  static const FoldingKind CLASS_BODY = FoldingKind._('CLASS_BODY');

  static const FoldingKind DIRECTIVES = FoldingKind._('DIRECTIVES');

  static const FoldingKind DOCUMENTATION_COMMENT =
      FoldingKind._('DOCUMENTATION_COMMENT');

  static const FoldingKind FILE_HEADER = FoldingKind._('FILE_HEADER');

  static const FoldingKind FUNCTION_BODY = FoldingKind._('FUNCTION_BODY');

  static const FoldingKind INVOCATION = FoldingKind._('INVOCATION');

  static const FoldingKind LITERAL = FoldingKind._('LITERAL');

  /// A list containing all of the enum values that are defined.
  static const List<FoldingKind> VALUES = <FoldingKind>[
    ANNOTATIONS,
    BLOCK,
    CLASS_BODY,
    DIRECTIVES,
    DOCUMENTATION_COMMENT,
    FILE_HEADER,
    FUNCTION_BODY,
    INVOCATION,
    LITERAL
  ];

  @override
  final String name;

  const FoldingKind._(this.name);

  factory FoldingKind(String name) {
    switch (name) {
      case 'ANNOTATIONS':
        return ANNOTATIONS;
      case 'BLOCK':
        return BLOCK;
      case 'CLASS_BODY':
        return CLASS_BODY;
      case 'DIRECTIVES':
        return DIRECTIVES;
      case 'DOCUMENTATION_COMMENT':
        return DOCUMENTATION_COMMENT;
      case 'FILE_HEADER':
        return FILE_HEADER;
      case 'FUNCTION_BODY':
        return FUNCTION_BODY;
      case 'INVOCATION':
        return INVOCATION;
      case 'LITERAL':
        return LITERAL;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FoldingKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return FoldingKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FoldingKind', json);
  }

  @override
  String toString() => 'FoldingKind.$name';

  String toJson() => name;
}

/// FoldingRegion
///
/// {
///   "kind": FoldingKind
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FoldingRegion implements HasToJson {
  FoldingKind _kind;

  int _offset;

  int _length;

  /// The kind of the region.
  FoldingKind get kind => _kind;

  /// The kind of the region.
  set kind(FoldingKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The offset of the region to be folded.
  int get offset => _offset;

  /// The offset of the region to be folded.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region to be folded.
  int get length => _length;

  /// The length of the region to be folded.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  FoldingRegion(FoldingKind kind, int offset, int length) {
    this.kind = kind;
    this.offset = offset;
    this.length = length;
  }

  factory FoldingRegion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      FoldingKind kind;
      if (json.containsKey('kind')) {
        kind =
            FoldingKind.fromJson(jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return FoldingRegion(kind, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FoldingRegion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FoldingRegion) {
      return kind == other.kind &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// HighlightRegion
///
/// {
///   "type": HighlightRegionType
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class HighlightRegion implements HasToJson {
  HighlightRegionType _type;

  int _offset;

  int _length;

  /// The type of highlight associated with the region.
  HighlightRegionType get type => _type;

  /// The type of highlight associated with the region.
  set type(HighlightRegionType value) {
    assert(value != null);
    _type = value;
  }

  /// The offset of the region to be highlighted.
  int get offset => _offset;

  /// The offset of the region to be highlighted.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region to be highlighted.
  int get length => _length;

  /// The length of the region to be highlighted.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  HighlightRegion(HighlightRegionType type, int offset, int length) {
    this.type = type;
    this.offset = offset;
    this.length = length;
  }

  factory HighlightRegion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      HighlightRegionType type;
      if (json.containsKey('type')) {
        type = HighlightRegionType.fromJson(
            jsonDecoder, jsonPath + '.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return HighlightRegion(type, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'HighlightRegion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['type'] = type.toJson();
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is HighlightRegion) {
      return type == other.type &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// HighlightRegionType
///
/// enum {
///   ANNOTATION
///   BUILT_IN
///   CLASS
///   COMMENT_BLOCK
///   COMMENT_DOCUMENTATION
///   COMMENT_END_OF_LINE
///   CONSTRUCTOR
///   DIRECTIVE
///   DYNAMIC_TYPE
///   DYNAMIC_LOCAL_VARIABLE_DECLARATION
///   DYNAMIC_LOCAL_VARIABLE_REFERENCE
///   DYNAMIC_PARAMETER_DECLARATION
///   DYNAMIC_PARAMETER_REFERENCE
///   ENUM
///   ENUM_CONSTANT
///   FIELD
///   FIELD_STATIC
///   FUNCTION
///   FUNCTION_DECLARATION
///   FUNCTION_TYPE_ALIAS
///   GETTER_DECLARATION
///   IDENTIFIER_DEFAULT
///   IMPORT_PREFIX
///   INSTANCE_FIELD_DECLARATION
///   INSTANCE_FIELD_REFERENCE
///   INSTANCE_GETTER_DECLARATION
///   INSTANCE_GETTER_REFERENCE
///   INSTANCE_METHOD_DECLARATION
///   INSTANCE_METHOD_REFERENCE
///   INSTANCE_SETTER_DECLARATION
///   INSTANCE_SETTER_REFERENCE
///   INVALID_STRING_ESCAPE
///   KEYWORD
///   LABEL
///   LIBRARY_NAME
///   LITERAL_BOOLEAN
///   LITERAL_DOUBLE
///   LITERAL_INTEGER
///   LITERAL_LIST
///   LITERAL_MAP
///   LITERAL_STRING
///   LOCAL_FUNCTION_DECLARATION
///   LOCAL_FUNCTION_REFERENCE
///   LOCAL_VARIABLE
///   LOCAL_VARIABLE_DECLARATION
///   LOCAL_VARIABLE_REFERENCE
///   METHOD
///   METHOD_DECLARATION
///   METHOD_DECLARATION_STATIC
///   METHOD_STATIC
///   PARAMETER
///   SETTER_DECLARATION
///   TOP_LEVEL_VARIABLE
///   PARAMETER_DECLARATION
///   PARAMETER_REFERENCE
///   STATIC_FIELD_DECLARATION
///   STATIC_GETTER_DECLARATION
///   STATIC_GETTER_REFERENCE
///   STATIC_METHOD_DECLARATION
///   STATIC_METHOD_REFERENCE
///   STATIC_SETTER_DECLARATION
///   STATIC_SETTER_REFERENCE
///   TOP_LEVEL_FUNCTION_DECLARATION
///   TOP_LEVEL_FUNCTION_REFERENCE
///   TOP_LEVEL_GETTER_DECLARATION
///   TOP_LEVEL_GETTER_REFERENCE
///   TOP_LEVEL_SETTER_DECLARATION
///   TOP_LEVEL_SETTER_REFERENCE
///   TOP_LEVEL_VARIABLE_DECLARATION
///   TYPE_NAME_DYNAMIC
///   TYPE_PARAMETER
///   UNRESOLVED_INSTANCE_MEMBER_REFERENCE
///   VALID_STRING_ESCAPE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class HighlightRegionType implements Enum {
  static const HighlightRegionType ANNOTATION =
      HighlightRegionType._('ANNOTATION');

  static const HighlightRegionType BUILT_IN = HighlightRegionType._('BUILT_IN');

  static const HighlightRegionType CLASS = HighlightRegionType._('CLASS');

  static const HighlightRegionType COMMENT_BLOCK =
      HighlightRegionType._('COMMENT_BLOCK');

  static const HighlightRegionType COMMENT_DOCUMENTATION =
      HighlightRegionType._('COMMENT_DOCUMENTATION');

  static const HighlightRegionType COMMENT_END_OF_LINE =
      HighlightRegionType._('COMMENT_END_OF_LINE');

  static const HighlightRegionType CONSTRUCTOR =
      HighlightRegionType._('CONSTRUCTOR');

  static const HighlightRegionType DIRECTIVE =
      HighlightRegionType._('DIRECTIVE');

  /// Deprecated - no longer sent.
  static const HighlightRegionType DYNAMIC_TYPE =
      HighlightRegionType._('DYNAMIC_TYPE');

  static const HighlightRegionType DYNAMIC_LOCAL_VARIABLE_DECLARATION =
      HighlightRegionType._('DYNAMIC_LOCAL_VARIABLE_DECLARATION');

  static const HighlightRegionType DYNAMIC_LOCAL_VARIABLE_REFERENCE =
      HighlightRegionType._('DYNAMIC_LOCAL_VARIABLE_REFERENCE');

  static const HighlightRegionType DYNAMIC_PARAMETER_DECLARATION =
      HighlightRegionType._('DYNAMIC_PARAMETER_DECLARATION');

  static const HighlightRegionType DYNAMIC_PARAMETER_REFERENCE =
      HighlightRegionType._('DYNAMIC_PARAMETER_REFERENCE');

  static const HighlightRegionType ENUM = HighlightRegionType._('ENUM');

  static const HighlightRegionType ENUM_CONSTANT =
      HighlightRegionType._('ENUM_CONSTANT');

  /// Deprecated - no longer sent.
  static const HighlightRegionType FIELD = HighlightRegionType._('FIELD');

  /// Deprecated - no longer sent.
  static const HighlightRegionType FIELD_STATIC =
      HighlightRegionType._('FIELD_STATIC');

  /// Deprecated - no longer sent.
  static const HighlightRegionType FUNCTION = HighlightRegionType._('FUNCTION');

  /// Deprecated - no longer sent.
  static const HighlightRegionType FUNCTION_DECLARATION =
      HighlightRegionType._('FUNCTION_DECLARATION');

  static const HighlightRegionType FUNCTION_TYPE_ALIAS =
      HighlightRegionType._('FUNCTION_TYPE_ALIAS');

  /// Deprecated - no longer sent.
  static const HighlightRegionType GETTER_DECLARATION =
      HighlightRegionType._('GETTER_DECLARATION');

  static const HighlightRegionType IDENTIFIER_DEFAULT =
      HighlightRegionType._('IDENTIFIER_DEFAULT');

  static const HighlightRegionType IMPORT_PREFIX =
      HighlightRegionType._('IMPORT_PREFIX');

  static const HighlightRegionType INSTANCE_FIELD_DECLARATION =
      HighlightRegionType._('INSTANCE_FIELD_DECLARATION');

  static const HighlightRegionType INSTANCE_FIELD_REFERENCE =
      HighlightRegionType._('INSTANCE_FIELD_REFERENCE');

  static const HighlightRegionType INSTANCE_GETTER_DECLARATION =
      HighlightRegionType._('INSTANCE_GETTER_DECLARATION');

  static const HighlightRegionType INSTANCE_GETTER_REFERENCE =
      HighlightRegionType._('INSTANCE_GETTER_REFERENCE');

  static const HighlightRegionType INSTANCE_METHOD_DECLARATION =
      HighlightRegionType._('INSTANCE_METHOD_DECLARATION');

  static const HighlightRegionType INSTANCE_METHOD_REFERENCE =
      HighlightRegionType._('INSTANCE_METHOD_REFERENCE');

  static const HighlightRegionType INSTANCE_SETTER_DECLARATION =
      HighlightRegionType._('INSTANCE_SETTER_DECLARATION');

  static const HighlightRegionType INSTANCE_SETTER_REFERENCE =
      HighlightRegionType._('INSTANCE_SETTER_REFERENCE');

  static const HighlightRegionType INVALID_STRING_ESCAPE =
      HighlightRegionType._('INVALID_STRING_ESCAPE');

  static const HighlightRegionType KEYWORD = HighlightRegionType._('KEYWORD');

  static const HighlightRegionType LABEL = HighlightRegionType._('LABEL');

  static const HighlightRegionType LIBRARY_NAME =
      HighlightRegionType._('LIBRARY_NAME');

  static const HighlightRegionType LITERAL_BOOLEAN =
      HighlightRegionType._('LITERAL_BOOLEAN');

  static const HighlightRegionType LITERAL_DOUBLE =
      HighlightRegionType._('LITERAL_DOUBLE');

  static const HighlightRegionType LITERAL_INTEGER =
      HighlightRegionType._('LITERAL_INTEGER');

  static const HighlightRegionType LITERAL_LIST =
      HighlightRegionType._('LITERAL_LIST');

  static const HighlightRegionType LITERAL_MAP =
      HighlightRegionType._('LITERAL_MAP');

  static const HighlightRegionType LITERAL_STRING =
      HighlightRegionType._('LITERAL_STRING');

  static const HighlightRegionType LOCAL_FUNCTION_DECLARATION =
      HighlightRegionType._('LOCAL_FUNCTION_DECLARATION');

  static const HighlightRegionType LOCAL_FUNCTION_REFERENCE =
      HighlightRegionType._('LOCAL_FUNCTION_REFERENCE');

  /// Deprecated - no longer sent.
  static const HighlightRegionType LOCAL_VARIABLE =
      HighlightRegionType._('LOCAL_VARIABLE');

  static const HighlightRegionType LOCAL_VARIABLE_DECLARATION =
      HighlightRegionType._('LOCAL_VARIABLE_DECLARATION');

  static const HighlightRegionType LOCAL_VARIABLE_REFERENCE =
      HighlightRegionType._('LOCAL_VARIABLE_REFERENCE');

  /// Deprecated - no longer sent.
  static const HighlightRegionType METHOD = HighlightRegionType._('METHOD');

  /// Deprecated - no longer sent.
  static const HighlightRegionType METHOD_DECLARATION =
      HighlightRegionType._('METHOD_DECLARATION');

  /// Deprecated - no longer sent.
  static const HighlightRegionType METHOD_DECLARATION_STATIC =
      HighlightRegionType._('METHOD_DECLARATION_STATIC');

  /// Deprecated - no longer sent.
  static const HighlightRegionType METHOD_STATIC =
      HighlightRegionType._('METHOD_STATIC');

  /// Deprecated - no longer sent.
  static const HighlightRegionType PARAMETER =
      HighlightRegionType._('PARAMETER');

  /// Deprecated - no longer sent.
  static const HighlightRegionType SETTER_DECLARATION =
      HighlightRegionType._('SETTER_DECLARATION');

  /// Deprecated - no longer sent.
  static const HighlightRegionType TOP_LEVEL_VARIABLE =
      HighlightRegionType._('TOP_LEVEL_VARIABLE');

  static const HighlightRegionType PARAMETER_DECLARATION =
      HighlightRegionType._('PARAMETER_DECLARATION');

  static const HighlightRegionType PARAMETER_REFERENCE =
      HighlightRegionType._('PARAMETER_REFERENCE');

  static const HighlightRegionType STATIC_FIELD_DECLARATION =
      HighlightRegionType._('STATIC_FIELD_DECLARATION');

  static const HighlightRegionType STATIC_GETTER_DECLARATION =
      HighlightRegionType._('STATIC_GETTER_DECLARATION');

  static const HighlightRegionType STATIC_GETTER_REFERENCE =
      HighlightRegionType._('STATIC_GETTER_REFERENCE');

  static const HighlightRegionType STATIC_METHOD_DECLARATION =
      HighlightRegionType._('STATIC_METHOD_DECLARATION');

  static const HighlightRegionType STATIC_METHOD_REFERENCE =
      HighlightRegionType._('STATIC_METHOD_REFERENCE');

  static const HighlightRegionType STATIC_SETTER_DECLARATION =
      HighlightRegionType._('STATIC_SETTER_DECLARATION');

  static const HighlightRegionType STATIC_SETTER_REFERENCE =
      HighlightRegionType._('STATIC_SETTER_REFERENCE');

  static const HighlightRegionType TOP_LEVEL_FUNCTION_DECLARATION =
      HighlightRegionType._('TOP_LEVEL_FUNCTION_DECLARATION');

  static const HighlightRegionType TOP_LEVEL_FUNCTION_REFERENCE =
      HighlightRegionType._('TOP_LEVEL_FUNCTION_REFERENCE');

  static const HighlightRegionType TOP_LEVEL_GETTER_DECLARATION =
      HighlightRegionType._('TOP_LEVEL_GETTER_DECLARATION');

  static const HighlightRegionType TOP_LEVEL_GETTER_REFERENCE =
      HighlightRegionType._('TOP_LEVEL_GETTER_REFERENCE');

  static const HighlightRegionType TOP_LEVEL_SETTER_DECLARATION =
      HighlightRegionType._('TOP_LEVEL_SETTER_DECLARATION');

  static const HighlightRegionType TOP_LEVEL_SETTER_REFERENCE =
      HighlightRegionType._('TOP_LEVEL_SETTER_REFERENCE');

  static const HighlightRegionType TOP_LEVEL_VARIABLE_DECLARATION =
      HighlightRegionType._('TOP_LEVEL_VARIABLE_DECLARATION');

  static const HighlightRegionType TYPE_NAME_DYNAMIC =
      HighlightRegionType._('TYPE_NAME_DYNAMIC');

  static const HighlightRegionType TYPE_PARAMETER =
      HighlightRegionType._('TYPE_PARAMETER');

  static const HighlightRegionType UNRESOLVED_INSTANCE_MEMBER_REFERENCE =
      HighlightRegionType._('UNRESOLVED_INSTANCE_MEMBER_REFERENCE');

  static const HighlightRegionType VALID_STRING_ESCAPE =
      HighlightRegionType._('VALID_STRING_ESCAPE');

  /// A list containing all of the enum values that are defined.
  static const List<HighlightRegionType> VALUES = <HighlightRegionType>[
    ANNOTATION,
    BUILT_IN,
    CLASS,
    COMMENT_BLOCK,
    COMMENT_DOCUMENTATION,
    COMMENT_END_OF_LINE,
    CONSTRUCTOR,
    DIRECTIVE,
    DYNAMIC_TYPE,
    DYNAMIC_LOCAL_VARIABLE_DECLARATION,
    DYNAMIC_LOCAL_VARIABLE_REFERENCE,
    DYNAMIC_PARAMETER_DECLARATION,
    DYNAMIC_PARAMETER_REFERENCE,
    ENUM,
    ENUM_CONSTANT,
    FIELD,
    FIELD_STATIC,
    FUNCTION,
    FUNCTION_DECLARATION,
    FUNCTION_TYPE_ALIAS,
    GETTER_DECLARATION,
    IDENTIFIER_DEFAULT,
    IMPORT_PREFIX,
    INSTANCE_FIELD_DECLARATION,
    INSTANCE_FIELD_REFERENCE,
    INSTANCE_GETTER_DECLARATION,
    INSTANCE_GETTER_REFERENCE,
    INSTANCE_METHOD_DECLARATION,
    INSTANCE_METHOD_REFERENCE,
    INSTANCE_SETTER_DECLARATION,
    INSTANCE_SETTER_REFERENCE,
    INVALID_STRING_ESCAPE,
    KEYWORD,
    LABEL,
    LIBRARY_NAME,
    LITERAL_BOOLEAN,
    LITERAL_DOUBLE,
    LITERAL_INTEGER,
    LITERAL_LIST,
    LITERAL_MAP,
    LITERAL_STRING,
    LOCAL_FUNCTION_DECLARATION,
    LOCAL_FUNCTION_REFERENCE,
    LOCAL_VARIABLE,
    LOCAL_VARIABLE_DECLARATION,
    LOCAL_VARIABLE_REFERENCE,
    METHOD,
    METHOD_DECLARATION,
    METHOD_DECLARATION_STATIC,
    METHOD_STATIC,
    PARAMETER,
    SETTER_DECLARATION,
    TOP_LEVEL_VARIABLE,
    PARAMETER_DECLARATION,
    PARAMETER_REFERENCE,
    STATIC_FIELD_DECLARATION,
    STATIC_GETTER_DECLARATION,
    STATIC_GETTER_REFERENCE,
    STATIC_METHOD_DECLARATION,
    STATIC_METHOD_REFERENCE,
    STATIC_SETTER_DECLARATION,
    STATIC_SETTER_REFERENCE,
    TOP_LEVEL_FUNCTION_DECLARATION,
    TOP_LEVEL_FUNCTION_REFERENCE,
    TOP_LEVEL_GETTER_DECLARATION,
    TOP_LEVEL_GETTER_REFERENCE,
    TOP_LEVEL_SETTER_DECLARATION,
    TOP_LEVEL_SETTER_REFERENCE,
    TOP_LEVEL_VARIABLE_DECLARATION,
    TYPE_NAME_DYNAMIC,
    TYPE_PARAMETER,
    UNRESOLVED_INSTANCE_MEMBER_REFERENCE,
    VALID_STRING_ESCAPE
  ];

  @override
  final String name;

  const HighlightRegionType._(this.name);

  factory HighlightRegionType(String name) {
    switch (name) {
      case 'ANNOTATION':
        return ANNOTATION;
      case 'BUILT_IN':
        return BUILT_IN;
      case 'CLASS':
        return CLASS;
      case 'COMMENT_BLOCK':
        return COMMENT_BLOCK;
      case 'COMMENT_DOCUMENTATION':
        return COMMENT_DOCUMENTATION;
      case 'COMMENT_END_OF_LINE':
        return COMMENT_END_OF_LINE;
      case 'CONSTRUCTOR':
        return CONSTRUCTOR;
      case 'DIRECTIVE':
        return DIRECTIVE;
      case 'DYNAMIC_TYPE':
        return DYNAMIC_TYPE;
      case 'DYNAMIC_LOCAL_VARIABLE_DECLARATION':
        return DYNAMIC_LOCAL_VARIABLE_DECLARATION;
      case 'DYNAMIC_LOCAL_VARIABLE_REFERENCE':
        return DYNAMIC_LOCAL_VARIABLE_REFERENCE;
      case 'DYNAMIC_PARAMETER_DECLARATION':
        return DYNAMIC_PARAMETER_DECLARATION;
      case 'DYNAMIC_PARAMETER_REFERENCE':
        return DYNAMIC_PARAMETER_REFERENCE;
      case 'ENUM':
        return ENUM;
      case 'ENUM_CONSTANT':
        return ENUM_CONSTANT;
      case 'FIELD':
        return FIELD;
      case 'FIELD_STATIC':
        return FIELD_STATIC;
      case 'FUNCTION':
        return FUNCTION;
      case 'FUNCTION_DECLARATION':
        return FUNCTION_DECLARATION;
      case 'FUNCTION_TYPE_ALIAS':
        return FUNCTION_TYPE_ALIAS;
      case 'GETTER_DECLARATION':
        return GETTER_DECLARATION;
      case 'IDENTIFIER_DEFAULT':
        return IDENTIFIER_DEFAULT;
      case 'IMPORT_PREFIX':
        return IMPORT_PREFIX;
      case 'INSTANCE_FIELD_DECLARATION':
        return INSTANCE_FIELD_DECLARATION;
      case 'INSTANCE_FIELD_REFERENCE':
        return INSTANCE_FIELD_REFERENCE;
      case 'INSTANCE_GETTER_DECLARATION':
        return INSTANCE_GETTER_DECLARATION;
      case 'INSTANCE_GETTER_REFERENCE':
        return INSTANCE_GETTER_REFERENCE;
      case 'INSTANCE_METHOD_DECLARATION':
        return INSTANCE_METHOD_DECLARATION;
      case 'INSTANCE_METHOD_REFERENCE':
        return INSTANCE_METHOD_REFERENCE;
      case 'INSTANCE_SETTER_DECLARATION':
        return INSTANCE_SETTER_DECLARATION;
      case 'INSTANCE_SETTER_REFERENCE':
        return INSTANCE_SETTER_REFERENCE;
      case 'INVALID_STRING_ESCAPE':
        return INVALID_STRING_ESCAPE;
      case 'KEYWORD':
        return KEYWORD;
      case 'LABEL':
        return LABEL;
      case 'LIBRARY_NAME':
        return LIBRARY_NAME;
      case 'LITERAL_BOOLEAN':
        return LITERAL_BOOLEAN;
      case 'LITERAL_DOUBLE':
        return LITERAL_DOUBLE;
      case 'LITERAL_INTEGER':
        return LITERAL_INTEGER;
      case 'LITERAL_LIST':
        return LITERAL_LIST;
      case 'LITERAL_MAP':
        return LITERAL_MAP;
      case 'LITERAL_STRING':
        return LITERAL_STRING;
      case 'LOCAL_FUNCTION_DECLARATION':
        return LOCAL_FUNCTION_DECLARATION;
      case 'LOCAL_FUNCTION_REFERENCE':
        return LOCAL_FUNCTION_REFERENCE;
      case 'LOCAL_VARIABLE':
        return LOCAL_VARIABLE;
      case 'LOCAL_VARIABLE_DECLARATION':
        return LOCAL_VARIABLE_DECLARATION;
      case 'LOCAL_VARIABLE_REFERENCE':
        return LOCAL_VARIABLE_REFERENCE;
      case 'METHOD':
        return METHOD;
      case 'METHOD_DECLARATION':
        return METHOD_DECLARATION;
      case 'METHOD_DECLARATION_STATIC':
        return METHOD_DECLARATION_STATIC;
      case 'METHOD_STATIC':
        return METHOD_STATIC;
      case 'PARAMETER':
        return PARAMETER;
      case 'SETTER_DECLARATION':
        return SETTER_DECLARATION;
      case 'TOP_LEVEL_VARIABLE':
        return TOP_LEVEL_VARIABLE;
      case 'PARAMETER_DECLARATION':
        return PARAMETER_DECLARATION;
      case 'PARAMETER_REFERENCE':
        return PARAMETER_REFERENCE;
      case 'STATIC_FIELD_DECLARATION':
        return STATIC_FIELD_DECLARATION;
      case 'STATIC_GETTER_DECLARATION':
        return STATIC_GETTER_DECLARATION;
      case 'STATIC_GETTER_REFERENCE':
        return STATIC_GETTER_REFERENCE;
      case 'STATIC_METHOD_DECLARATION':
        return STATIC_METHOD_DECLARATION;
      case 'STATIC_METHOD_REFERENCE':
        return STATIC_METHOD_REFERENCE;
      case 'STATIC_SETTER_DECLARATION':
        return STATIC_SETTER_DECLARATION;
      case 'STATIC_SETTER_REFERENCE':
        return STATIC_SETTER_REFERENCE;
      case 'TOP_LEVEL_FUNCTION_DECLARATION':
        return TOP_LEVEL_FUNCTION_DECLARATION;
      case 'TOP_LEVEL_FUNCTION_REFERENCE':
        return TOP_LEVEL_FUNCTION_REFERENCE;
      case 'TOP_LEVEL_GETTER_DECLARATION':
        return TOP_LEVEL_GETTER_DECLARATION;
      case 'TOP_LEVEL_GETTER_REFERENCE':
        return TOP_LEVEL_GETTER_REFERENCE;
      case 'TOP_LEVEL_SETTER_DECLARATION':
        return TOP_LEVEL_SETTER_DECLARATION;
      case 'TOP_LEVEL_SETTER_REFERENCE':
        return TOP_LEVEL_SETTER_REFERENCE;
      case 'TOP_LEVEL_VARIABLE_DECLARATION':
        return TOP_LEVEL_VARIABLE_DECLARATION;
      case 'TYPE_NAME_DYNAMIC':
        return TYPE_NAME_DYNAMIC;
      case 'TYPE_PARAMETER':
        return TYPE_PARAMETER;
      case 'UNRESOLVED_INSTANCE_MEMBER_REFERENCE':
        return UNRESOLVED_INSTANCE_MEMBER_REFERENCE;
      case 'VALID_STRING_ESCAPE':
        return VALID_STRING_ESCAPE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory HighlightRegionType.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return HighlightRegionType(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'HighlightRegionType', json);
  }

  @override
  String toString() => 'HighlightRegionType.$name';

  String toJson() => name;
}

/// KytheEntry
///
/// {
///   "source": KytheVName
///   "kind": optional String
///   "target": optional KytheVName
///   "fact": String
///   "value": optional List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class KytheEntry implements HasToJson {
  KytheVName _source;

  String _kind;

  KytheVName _target;

  String _fact;

  List<int> _value;

  /// The ticket of the source node.
  KytheVName get source => _source;

  /// The ticket of the source node.
  set source(KytheVName value) {
    assert(value != null);
    _source = value;
  }

  /// An edge label. The schema defines which labels are meaningful.
  String get kind => _kind;

  /// An edge label. The schema defines which labels are meaningful.
  set kind(String value) {
    _kind = value;
  }

  /// The ticket of the target node.
  KytheVName get target => _target;

  /// The ticket of the target node.
  set target(KytheVName value) {
    _target = value;
  }

  /// A fact label. The schema defines which fact labels are meaningful.
  String get fact => _fact;

  /// A fact label. The schema defines which fact labels are meaningful.
  set fact(String value) {
    assert(value != null);
    _fact = value;
  }

  /// The String value of the fact.
  List<int> get value => _value;

  /// The String value of the fact.
  set value(List<int> value) {
    _value = value;
  }

  KytheEntry(KytheVName source, String fact,
      {String kind, KytheVName target, List<int> value}) {
    this.source = source;
    this.kind = kind;
    this.target = target;
    this.fact = fact;
    this.value = value;
  }

  factory KytheEntry.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      KytheVName source;
      if (json.containsKey('source')) {
        source = KytheVName.fromJson(
            jsonDecoder, jsonPath + '.source', json['source']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'source');
      }
      String kind;
      if (json.containsKey('kind')) {
        kind = jsonDecoder.decodeString(jsonPath + '.kind', json['kind']);
      }
      KytheVName target;
      if (json.containsKey('target')) {
        target = KytheVName.fromJson(
            jsonDecoder, jsonPath + '.target', json['target']);
      }
      String fact;
      if (json.containsKey('fact')) {
        fact = jsonDecoder.decodeString(jsonPath + '.fact', json['fact']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fact');
      }
      List<int> value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeList(
            jsonPath + '.value', json['value'], jsonDecoder.decodeInt);
      }
      return KytheEntry(source, fact, kind: kind, target: target, value: value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'KytheEntry', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['source'] = source.toJson();
    if (kind != null) {
      result['kind'] = kind;
    }
    if (target != null) {
      result['target'] = target.toJson();
    }
    result['fact'] = fact;
    if (value != null) {
      result['value'] = value;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is KytheEntry) {
      return source == other.source &&
          kind == other.kind &&
          target == other.target &&
          fact == other.fact &&
          listEqual(value, other.value, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, source.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, target.hashCode);
    hash = JenkinsSmiHash.combine(hash, fact.hashCode);
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// KytheVName
///
/// {
///   "signature": String
///   "corpus": String
///   "root": String
///   "path": String
///   "language": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class KytheVName implements HasToJson {
  String _signature;

  String _corpus;

  String _root;

  String _path;

  String _language;

  /// An opaque signature generated by the analyzer.
  String get signature => _signature;

  /// An opaque signature generated by the analyzer.
  set signature(String value) {
    assert(value != null);
    _signature = value;
  }

  /// The corpus of source code this KytheVName belongs to. Loosely, a corpus
  /// is a collection of related files, such as the contents of a given source
  /// repository.
  String get corpus => _corpus;

  /// The corpus of source code this KytheVName belongs to. Loosely, a corpus
  /// is a collection of related files, such as the contents of a given source
  /// repository.
  set corpus(String value) {
    assert(value != null);
    _corpus = value;
  }

  /// A corpus-specific root label, typically a directory path or project
  /// identifier, denoting a distinct subset of the corpus. This may also be
  /// used to designate virtual collections like generated files.
  String get root => _root;

  /// A corpus-specific root label, typically a directory path or project
  /// identifier, denoting a distinct subset of the corpus. This may also be
  /// used to designate virtual collections like generated files.
  set root(String value) {
    assert(value != null);
    _root = value;
  }

  /// A path-structured label describing the “location” of the named object
  /// relative to the corpus and the root.
  String get path => _path;

  /// A path-structured label describing the “location” of the named object
  /// relative to the corpus and the root.
  set path(String value) {
    assert(value != null);
    _path = value;
  }

  /// The language this name belongs to.
  String get language => _language;

  /// The language this name belongs to.
  set language(String value) {
    assert(value != null);
    _language = value;
  }

  KytheVName(String signature, String corpus, String root, String path,
      String language) {
    this.signature = signature;
    this.corpus = corpus;
    this.root = root;
    this.path = path;
    this.language = language;
  }

  factory KytheVName.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String signature;
      if (json.containsKey('signature')) {
        signature = jsonDecoder.decodeString(
            jsonPath + '.signature', json['signature']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'signature');
      }
      String corpus;
      if (json.containsKey('corpus')) {
        corpus = jsonDecoder.decodeString(jsonPath + '.corpus', json['corpus']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'corpus');
      }
      String root;
      if (json.containsKey('root')) {
        root = jsonDecoder.decodeString(jsonPath + '.root', json['root']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'root');
      }
      String path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeString(jsonPath + '.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      String language;
      if (json.containsKey('language')) {
        language =
            jsonDecoder.decodeString(jsonPath + '.language', json['language']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'language');
      }
      return KytheVName(signature, corpus, root, path, language);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'KytheVName', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['signature'] = signature;
    result['corpus'] = corpus;
    result['root'] = root;
    result['path'] = path;
    result['language'] = language;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is KytheVName) {
      return signature == other.signature &&
          corpus == other.corpus &&
          root == other.root &&
          path == other.path &&
          language == other.language;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, signature.hashCode);
    hash = JenkinsSmiHash.combine(hash, corpus.hashCode);
    hash = JenkinsSmiHash.combine(hash, root.hashCode);
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    hash = JenkinsSmiHash.combine(hash, language.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// LinkedEditGroup
///
/// {
///   "positions": List<Position>
///   "length": int
///   "suggestions": List<LinkedEditSuggestion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LinkedEditGroup implements HasToJson {
  List<Position> _positions;

  int _length;

  List<LinkedEditSuggestion> _suggestions;

  /// The positions of the regions that should be edited simultaneously.
  List<Position> get positions => _positions;

  /// The positions of the regions that should be edited simultaneously.
  set positions(List<Position> value) {
    assert(value != null);
    _positions = value;
  }

  /// The length of the regions that should be edited simultaneously.
  int get length => _length;

  /// The length of the regions that should be edited simultaneously.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// Pre-computed suggestions for what every region might want to be changed
  /// to.
  List<LinkedEditSuggestion> get suggestions => _suggestions;

  /// Pre-computed suggestions for what every region might want to be changed
  /// to.
  set suggestions(List<LinkedEditSuggestion> value) {
    assert(value != null);
    _suggestions = value;
  }

  LinkedEditGroup(List<Position> positions, int length,
      List<LinkedEditSuggestion> suggestions) {
    this.positions = positions;
    this.length = length;
    this.suggestions = suggestions;
  }

  factory LinkedEditGroup.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<Position> positions;
      if (json.containsKey('positions')) {
        positions = jsonDecoder.decodeList(
            jsonPath + '.positions',
            json['positions'],
            (String jsonPath, Object json) =>
                Position.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'positions');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      List<LinkedEditSuggestion> suggestions;
      if (json.containsKey('suggestions')) {
        suggestions = jsonDecoder.decodeList(
            jsonPath + '.suggestions',
            json['suggestions'],
            (String jsonPath, Object json) =>
                LinkedEditSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'suggestions');
      }
      return LinkedEditGroup(positions, length, suggestions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'LinkedEditGroup', json);
    }
  }

  /// Construct an empty LinkedEditGroup.
  LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['positions'] =
        positions.map((Position value) => value.toJson()).toList();
    result['length'] = length;
    result['suggestions'] = suggestions
        .map((LinkedEditSuggestion value) => value.toJson())
        .toList();
    return result;
  }

  /// Add a new position and change the length.
  void addPosition(Position position, int length) {
    positions.add(position);
    this.length = length;
  }

  /// Add a new suggestion.
  void addSuggestion(LinkedEditSuggestion suggestion) {
    suggestions.add(suggestion);
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LinkedEditGroup) {
      return listEqual(
              positions, other.positions, (Position a, Position b) => a == b) &&
          length == other.length &&
          listEqual(suggestions, other.suggestions,
              (LinkedEditSuggestion a, LinkedEditSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, positions.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, suggestions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// LinkedEditSuggestion
///
/// {
///   "value": String
///   "kind": LinkedEditSuggestionKind
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LinkedEditSuggestion implements HasToJson {
  String _value;

  LinkedEditSuggestionKind _kind;

  /// The value that could be used to replace all of the linked edit regions.
  String get value => _value;

  /// The value that could be used to replace all of the linked edit regions.
  set value(String value) {
    assert(value != null);
    _value = value;
  }

  /// The kind of value being proposed.
  LinkedEditSuggestionKind get kind => _kind;

  /// The kind of value being proposed.
  set kind(LinkedEditSuggestionKind value) {
    assert(value != null);
    _kind = value;
  }

  LinkedEditSuggestion(String value, LinkedEditSuggestionKind kind) {
    this.value = value;
    this.kind = kind;
  }

  factory LinkedEditSuggestion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeString(jsonPath + '.value', json['value']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'value');
      }
      LinkedEditSuggestionKind kind;
      if (json.containsKey('kind')) {
        kind = LinkedEditSuggestionKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      return LinkedEditSuggestion(value, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'LinkedEditSuggestion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['value'] = value;
    result['kind'] = kind.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LinkedEditSuggestion) {
      return value == other.value && kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// LinkedEditSuggestionKind
///
/// enum {
///   METHOD
///   PARAMETER
///   TYPE
///   VARIABLE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LinkedEditSuggestionKind implements Enum {
  static const LinkedEditSuggestionKind METHOD =
      LinkedEditSuggestionKind._('METHOD');

  static const LinkedEditSuggestionKind PARAMETER =
      LinkedEditSuggestionKind._('PARAMETER');

  static const LinkedEditSuggestionKind TYPE =
      LinkedEditSuggestionKind._('TYPE');

  static const LinkedEditSuggestionKind VARIABLE =
      LinkedEditSuggestionKind._('VARIABLE');

  /// A list containing all of the enum values that are defined.
  static const List<LinkedEditSuggestionKind> VALUES =
      <LinkedEditSuggestionKind>[METHOD, PARAMETER, TYPE, VARIABLE];

  @override
  final String name;

  const LinkedEditSuggestionKind._(this.name);

  factory LinkedEditSuggestionKind(String name) {
    switch (name) {
      case 'METHOD':
        return METHOD;
      case 'PARAMETER':
        return PARAMETER;
      case 'TYPE':
        return TYPE;
      case 'VARIABLE':
        return VARIABLE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory LinkedEditSuggestionKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return LinkedEditSuggestionKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'LinkedEditSuggestionKind', json);
  }

  @override
  String toString() => 'LinkedEditSuggestionKind.$name';

  String toJson() => name;
}

/// Location
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
///   "startLine": int
///   "startColumn": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Location implements HasToJson {
  String _file;

  int _offset;

  int _length;

  int _startLine;

  int _startColumn;

  /// The file containing the range.
  String get file => _file;

  /// The file containing the range.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the range.
  int get offset => _offset;

  /// The offset of the range.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the range.
  int get length => _length;

  /// The length of the range.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The one-based index of the line containing the first character of the
  /// range.
  int get startLine => _startLine;

  /// The one-based index of the line containing the first character of the
  /// range.
  set startLine(int value) {
    assert(value != null);
    _startLine = value;
  }

  /// The one-based index of the column containing the first character of the
  /// range.
  int get startColumn => _startColumn;

  /// The one-based index of the column containing the first character of the
  /// range.
  set startColumn(int value) {
    assert(value != null);
    _startColumn = value;
  }

  Location(
      String file, int offset, int length, int startLine, int startColumn) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
  }

  factory Location.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      int startLine;
      if (json.containsKey('startLine')) {
        startLine =
            jsonDecoder.decodeInt(jsonPath + '.startLine', json['startLine']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'startLine');
      }
      int startColumn;
      if (json.containsKey('startColumn')) {
        startColumn = jsonDecoder.decodeInt(
            jsonPath + '.startColumn', json['startColumn']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'startColumn');
      }
      return Location(file, offset, length, startLine, startColumn);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Location', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['startLine'] = startLine;
    result['startColumn'] = startColumn;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Location) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length &&
          startLine == other.startLine &&
          startColumn == other.startColumn;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, startColumn.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// NavigationRegion
///
/// {
///   "offset": int
///   "length": int
///   "targets": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class NavigationRegion implements HasToJson {
  int _offset;

  int _length;

  List<int> _targets;

  /// The offset of the region from which the user can navigate.
  int get offset => _offset;

  /// The offset of the region from which the user can navigate.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region from which the user can navigate.
  int get length => _length;

  /// The length of the region from which the user can navigate.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The indexes of the targets (in the enclosing navigation response) to
  /// which the given region is bound. By opening the target, clients can
  /// implement one form of navigation. This list cannot be empty.
  List<int> get targets => _targets;

  /// The indexes of the targets (in the enclosing navigation response) to
  /// which the given region is bound. By opening the target, clients can
  /// implement one form of navigation. This list cannot be empty.
  set targets(List<int> value) {
    assert(value != null);
    _targets = value;
  }

  NavigationRegion(int offset, int length, List<int> targets) {
    this.offset = offset;
    this.length = length;
    this.targets = targets;
  }

  factory NavigationRegion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      List<int> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
            jsonPath + '.targets', json['targets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      return NavigationRegion(offset, length, targets);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'NavigationRegion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    result['targets'] = targets;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is NavigationRegion) {
      return offset == other.offset &&
          length == other.length &&
          listEqual(targets, other.targets, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// NavigationTarget
///
/// {
///   "kind": ElementKind
///   "fileIndex": int
///   "offset": int
///   "length": int
///   "startLine": int
///   "startColumn": int
///   "codeOffset": optional int
///   "codeLength": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class NavigationTarget implements HasToJson {
  ElementKind _kind;

  int _fileIndex;

  int _offset;

  int _length;

  int _startLine;

  int _startColumn;

  int _codeOffset;

  int _codeLength;

  /// The kind of the element.
  ElementKind get kind => _kind;

  /// The kind of the element.
  set kind(ElementKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The index of the file (in the enclosing navigation response) to navigate
  /// to.
  int get fileIndex => _fileIndex;

  /// The index of the file (in the enclosing navigation response) to navigate
  /// to.
  set fileIndex(int value) {
    assert(value != null);
    _fileIndex = value;
  }

  /// The offset of the name of the target to which the user can navigate.
  int get offset => _offset;

  /// The offset of the name of the target to which the user can navigate.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the name of the target to which the user can navigate.
  int get length => _length;

  /// The length of the name of the target to which the user can navigate.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The one-based index of the line containing the first character of the
  /// name of the target.
  int get startLine => _startLine;

  /// The one-based index of the line containing the first character of the
  /// name of the target.
  set startLine(int value) {
    assert(value != null);
    _startLine = value;
  }

  /// The one-based index of the column containing the first character of the
  /// name of the target.
  int get startColumn => _startColumn;

  /// The one-based index of the column containing the first character of the
  /// name of the target.
  set startColumn(int value) {
    assert(value != null);
    _startColumn = value;
  }

  /// The offset of the target code to which the user can navigate.
  int get codeOffset => _codeOffset;

  /// The offset of the target code to which the user can navigate.
  set codeOffset(int value) {
    _codeOffset = value;
  }

  /// The length of the target code to which the user can navigate.
  int get codeLength => _codeLength;

  /// The length of the target code to which the user can navigate.
  set codeLength(int value) {
    _codeLength = value;
  }

  NavigationTarget(ElementKind kind, int fileIndex, int offset, int length,
      int startLine, int startColumn,
      {int codeOffset, int codeLength}) {
    this.kind = kind;
    this.fileIndex = fileIndex;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
  }

  factory NavigationTarget.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      ElementKind kind;
      if (json.containsKey('kind')) {
        kind =
            ElementKind.fromJson(jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int fileIndex;
      if (json.containsKey('fileIndex')) {
        fileIndex =
            jsonDecoder.decodeInt(jsonPath + '.fileIndex', json['fileIndex']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fileIndex');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      int startLine;
      if (json.containsKey('startLine')) {
        startLine =
            jsonDecoder.decodeInt(jsonPath + '.startLine', json['startLine']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'startLine');
      }
      int startColumn;
      if (json.containsKey('startColumn')) {
        startColumn = jsonDecoder.decodeInt(
            jsonPath + '.startColumn', json['startColumn']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'startColumn');
      }
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt(jsonPath + '.codeOffset', json['codeOffset']);
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt(jsonPath + '.codeLength', json['codeLength']);
      }
      return NavigationTarget(
          kind, fileIndex, offset, length, startLine, startColumn,
          codeOffset: codeOffset, codeLength: codeLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'NavigationTarget', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['fileIndex'] = fileIndex;
    result['offset'] = offset;
    result['length'] = length;
    result['startLine'] = startLine;
    result['startColumn'] = startColumn;
    if (codeOffset != null) {
      result['codeOffset'] = codeOffset;
    }
    if (codeLength != null) {
      result['codeLength'] = codeLength;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is NavigationTarget) {
      return kind == other.kind &&
          fileIndex == other.fileIndex &&
          offset == other.offset &&
          length == other.length &&
          startLine == other.startLine &&
          startColumn == other.startColumn &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, fileIndex.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, startColumn.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// Occurrences
///
/// {
///   "element": Element
///   "offsets": List<int>
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Occurrences implements HasToJson {
  Element _element;

  List<int> _offsets;

  int _length;

  /// The element that was referenced.
  Element get element => _element;

  /// The element that was referenced.
  set element(Element value) {
    assert(value != null);
    _element = value;
  }

  /// The offsets of the name of the referenced element within the file.
  List<int> get offsets => _offsets;

  /// The offsets of the name of the referenced element within the file.
  set offsets(List<int> value) {
    assert(value != null);
    _offsets = value;
  }

  /// The length of the name of the referenced element.
  int get length => _length;

  /// The length of the name of the referenced element.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  Occurrences(Element element, List<int> offsets, int length) {
    this.element = element;
    this.offsets = offsets;
    this.length = length;
  }

  factory Occurrences.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
            jsonPath + '.offsets', json['offsets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return Occurrences(element, offsets, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Occurrences', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['element'] = element.toJson();
    result['offsets'] = offsets;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Occurrences) {
      return element == other.element &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// Outline
///
/// {
///   "element": Element
///   "offset": int
///   "length": int
///   "codeOffset": int
///   "codeLength": int
///   "children": optional List<Outline>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Outline implements HasToJson {
  Element _element;

  int _offset;

  int _length;

  int _codeOffset;

  int _codeLength;

  List<Outline> _children;

  /// A description of the element represented by this node.
  Element get element => _element;

  /// A description of the element represented by this node.
  set element(Element value) {
    assert(value != null);
    _element = value;
  }

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  int get offset => _offset;

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the element.
  int get length => _length;

  /// The length of the element.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  int get codeOffset => _codeOffset;

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  set codeOffset(int value) {
    assert(value != null);
    _codeOffset = value;
  }

  /// The length of the element code.
  int get codeLength => _codeLength;

  /// The length of the element code.
  set codeLength(int value) {
    assert(value != null);
    _codeLength = value;
  }

  /// The children of the node. The field will be omitted if the node has no
  /// children. Children are sorted by offset.
  List<Outline> get children => _children;

  /// The children of the node. The field will be omitted if the node has no
  /// children. Children are sorted by offset.
  set children(List<Outline> value) {
    _children = value;
  }

  Outline(
      Element element, int offset, int length, int codeOffset, int codeLength,
      {List<Outline> children}) {
    this.element = element;
    this.offset = offset;
    this.length = length;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
    this.children = children;
  }

  factory Outline.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt(jsonPath + '.codeOffset', json['codeOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeOffset');
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt(jsonPath + '.codeLength', json['codeLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeLength');
      }
      List<Outline> children;
      if (json.containsKey('children')) {
        children = jsonDecoder.decodeList(
            jsonPath + '.children',
            json['children'],
            (String jsonPath, Object json) =>
                Outline.fromJson(jsonDecoder, jsonPath, json));
      }
      return Outline(element, offset, length, codeOffset, codeLength,
          children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Outline', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['element'] = element.toJson();
    result['offset'] = offset;
    result['length'] = length;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    if (children != null) {
      result['children'] =
          children.map((Outline value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Outline) {
      return element == other.element &&
          offset == other.offset &&
          length == other.length &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength &&
          listEqual(children, other.children, (Outline a, Outline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, children.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ParameterInfo
///
/// {
///   "kind": ParameterKind
///   "name": String
///   "type": String
///   "defaultValue": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ParameterInfo implements HasToJson {
  ParameterKind _kind;

  String _name;

  String _type;

  String _defaultValue;

  /// The kind of the parameter.
  ParameterKind get kind => _kind;

  /// The kind of the parameter.
  set kind(ParameterKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The name of the parameter.
  String get name => _name;

  /// The name of the parameter.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The type of the parameter.
  String get type => _type;

  /// The type of the parameter.
  set type(String value) {
    assert(value != null);
    _type = value;
  }

  /// The default value for this parameter. This value will be omitted if the
  /// parameter does not have a default value.
  String get defaultValue => _defaultValue;

  /// The default value for this parameter. This value will be omitted if the
  /// parameter does not have a default value.
  set defaultValue(String value) {
    _defaultValue = value;
  }

  ParameterInfo(ParameterKind kind, String name, String type,
      {String defaultValue}) {
    this.kind = kind;
    this.name = name;
    this.type = type;
    this.defaultValue = defaultValue;
  }

  factory ParameterInfo.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      ParameterKind kind;
      if (json.containsKey('kind')) {
        kind = ParameterKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String type;
      if (json.containsKey('type')) {
        type = jsonDecoder.decodeString(jsonPath + '.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      String defaultValue;
      if (json.containsKey('defaultValue')) {
        defaultValue = jsonDecoder.decodeString(
            jsonPath + '.defaultValue', json['defaultValue']);
      }
      return ParameterInfo(kind, name, type, defaultValue: defaultValue);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ParameterInfo', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['name'] = name;
    result['type'] = type;
    if (defaultValue != null) {
      result['defaultValue'] = defaultValue;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ParameterInfo) {
      return kind == other.kind &&
          name == other.name &&
          type == other.type &&
          defaultValue == other.defaultValue;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultValue.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ParameterKind
///
/// enum {
///   OPTIONAL_NAMED
///   OPTIONAL_POSITIONAL
///   REQUIRED_NAMED
///   REQUIRED_POSITIONAL
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ParameterKind implements Enum {
  /// An optional named parameter.
  static const ParameterKind OPTIONAL_NAMED = ParameterKind._('OPTIONAL_NAMED');

  /// An optional positional parameter.
  static const ParameterKind OPTIONAL_POSITIONAL =
      ParameterKind._('OPTIONAL_POSITIONAL');

  /// A required named parameter.
  static const ParameterKind REQUIRED_NAMED = ParameterKind._('REQUIRED_NAMED');

  /// A required positional parameter.
  static const ParameterKind REQUIRED_POSITIONAL =
      ParameterKind._('REQUIRED_POSITIONAL');

  /// A list containing all of the enum values that are defined.
  static const List<ParameterKind> VALUES = <ParameterKind>[
    OPTIONAL_NAMED,
    OPTIONAL_POSITIONAL,
    REQUIRED_NAMED,
    REQUIRED_POSITIONAL
  ];

  @override
  final String name;

  const ParameterKind._(this.name);

  factory ParameterKind(String name) {
    switch (name) {
      case 'OPTIONAL_NAMED':
        return OPTIONAL_NAMED;
      case 'OPTIONAL_POSITIONAL':
        return OPTIONAL_POSITIONAL;
      case 'REQUIRED_NAMED':
        return REQUIRED_NAMED;
      case 'REQUIRED_POSITIONAL':
        return REQUIRED_POSITIONAL;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ParameterKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ParameterKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ParameterKind', json);
  }

  @override
  String toString() => 'ParameterKind.$name';

  String toJson() => name;
}

/// Position
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Position implements HasToJson {
  String _file;

  int _offset;

  /// The file containing the position.
  String get file => _file;

  /// The file containing the position.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the position.
  int get offset => _offset;

  /// The offset of the position.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  Position(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory Position.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return Position(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Position', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Position) {
      return file == other.file && offset == other.offset;
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
}

/// RefactoringKind
///
/// enum {
///   CONVERT_GETTER_TO_METHOD
///   CONVERT_METHOD_TO_GETTER
///   EXTRACT_LOCAL_VARIABLE
///   EXTRACT_METHOD
///   EXTRACT_WIDGET
///   INLINE_LOCAL_VARIABLE
///   INLINE_METHOD
///   MOVE_FILE
///   RENAME
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringKind implements Enum {
  static const RefactoringKind CONVERT_GETTER_TO_METHOD =
      RefactoringKind._('CONVERT_GETTER_TO_METHOD');

  static const RefactoringKind CONVERT_METHOD_TO_GETTER =
      RefactoringKind._('CONVERT_METHOD_TO_GETTER');

  static const RefactoringKind EXTRACT_LOCAL_VARIABLE =
      RefactoringKind._('EXTRACT_LOCAL_VARIABLE');

  static const RefactoringKind EXTRACT_METHOD =
      RefactoringKind._('EXTRACT_METHOD');

  static const RefactoringKind EXTRACT_WIDGET =
      RefactoringKind._('EXTRACT_WIDGET');

  static const RefactoringKind INLINE_LOCAL_VARIABLE =
      RefactoringKind._('INLINE_LOCAL_VARIABLE');

  static const RefactoringKind INLINE_METHOD =
      RefactoringKind._('INLINE_METHOD');

  static const RefactoringKind MOVE_FILE = RefactoringKind._('MOVE_FILE');

  static const RefactoringKind RENAME = RefactoringKind._('RENAME');

  /// A list containing all of the enum values that are defined.
  static const List<RefactoringKind> VALUES = <RefactoringKind>[
    CONVERT_GETTER_TO_METHOD,
    CONVERT_METHOD_TO_GETTER,
    EXTRACT_LOCAL_VARIABLE,
    EXTRACT_METHOD,
    EXTRACT_WIDGET,
    INLINE_LOCAL_VARIABLE,
    INLINE_METHOD,
    MOVE_FILE,
    RENAME
  ];

  @override
  final String name;

  const RefactoringKind._(this.name);

  factory RefactoringKind(String name) {
    switch (name) {
      case 'CONVERT_GETTER_TO_METHOD':
        return CONVERT_GETTER_TO_METHOD;
      case 'CONVERT_METHOD_TO_GETTER':
        return CONVERT_METHOD_TO_GETTER;
      case 'EXTRACT_LOCAL_VARIABLE':
        return EXTRACT_LOCAL_VARIABLE;
      case 'EXTRACT_METHOD':
        return EXTRACT_METHOD;
      case 'EXTRACT_WIDGET':
        return EXTRACT_WIDGET;
      case 'INLINE_LOCAL_VARIABLE':
        return INLINE_LOCAL_VARIABLE;
      case 'INLINE_METHOD':
        return INLINE_METHOD;
      case 'MOVE_FILE':
        return MOVE_FILE;
      case 'RENAME':
        return RENAME;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RefactoringKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return RefactoringKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'RefactoringKind', json);
  }

  @override
  String toString() => 'RefactoringKind.$name';

  String toJson() => name;
}

/// RefactoringMethodParameter
///
/// {
///   "id": optional String
///   "kind": RefactoringMethodParameterKind
///   "type": String
///   "name": String
///   "parameters": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringMethodParameter implements HasToJson {
  String _id;

  RefactoringMethodParameterKind _kind;

  String _type;

  String _name;

  String _parameters;

  /// The unique identifier of the parameter. Clients may omit this field for
  /// the parameters they want to add.
  String get id => _id;

  /// The unique identifier of the parameter. Clients may omit this field for
  /// the parameters they want to add.
  set id(String value) {
    _id = value;
  }

  /// The kind of the parameter.
  RefactoringMethodParameterKind get kind => _kind;

  /// The kind of the parameter.
  set kind(RefactoringMethodParameterKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The type that should be given to the parameter, or the return type of the
  /// parameter's function type.
  String get type => _type;

  /// The type that should be given to the parameter, or the return type of the
  /// parameter's function type.
  set type(String value) {
    assert(value != null);
    _type = value;
  }

  /// The name that should be given to the parameter.
  String get name => _name;

  /// The name that should be given to the parameter.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The parameter list of the parameter's function type. If the parameter is
  /// not of a function type, this field will not be defined. If the function
  /// type has zero parameters, this field will have a value of '()'.
  String get parameters => _parameters;

  /// The parameter list of the parameter's function type. If the parameter is
  /// not of a function type, this field will not be defined. If the function
  /// type has zero parameters, this field will have a value of '()'.
  set parameters(String value) {
    _parameters = value;
  }

  RefactoringMethodParameter(
      RefactoringMethodParameterKind kind, String type, String name,
      {String id, String parameters}) {
    this.id = id;
    this.kind = kind;
    this.type = type;
    this.name = name;
    this.parameters = parameters;
  }

  factory RefactoringMethodParameter.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      }
      RefactoringMethodParameterKind kind;
      if (json.containsKey('kind')) {
        kind = RefactoringMethodParameterKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String type;
      if (json.containsKey('type')) {
        type = jsonDecoder.decodeString(jsonPath + '.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeString(
            jsonPath + '.parameters', json['parameters']);
      }
      return RefactoringMethodParameter(kind, type, name,
          id: id, parameters: parameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RefactoringMethodParameter', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (id != null) {
      result['id'] = id;
    }
    result['kind'] = kind.toJson();
    result['type'] = type;
    result['name'] = name;
    if (parameters != null) {
      result['parameters'] = parameters;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringMethodParameter) {
      return id == other.id &&
          kind == other.kind &&
          type == other.type &&
          name == other.name &&
          parameters == other.parameters;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RefactoringMethodParameterKind
///
/// enum {
///   REQUIRED
///   POSITIONAL
///   NAMED
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringMethodParameterKind implements Enum {
  static const RefactoringMethodParameterKind REQUIRED =
      RefactoringMethodParameterKind._('REQUIRED');

  static const RefactoringMethodParameterKind POSITIONAL =
      RefactoringMethodParameterKind._('POSITIONAL');

  static const RefactoringMethodParameterKind NAMED =
      RefactoringMethodParameterKind._('NAMED');

  /// A list containing all of the enum values that are defined.
  static const List<RefactoringMethodParameterKind> VALUES =
      <RefactoringMethodParameterKind>[REQUIRED, POSITIONAL, NAMED];

  @override
  final String name;

  const RefactoringMethodParameterKind._(this.name);

  factory RefactoringMethodParameterKind(String name) {
    switch (name) {
      case 'REQUIRED':
        return REQUIRED;
      case 'POSITIONAL':
        return POSITIONAL;
      case 'NAMED':
        return NAMED;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RefactoringMethodParameterKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return RefactoringMethodParameterKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
        jsonPath, 'RefactoringMethodParameterKind', json);
  }

  @override
  String toString() => 'RefactoringMethodParameterKind.$name';

  String toJson() => name;
}

/// RefactoringProblem
///
/// {
///   "severity": RefactoringProblemSeverity
///   "message": String
///   "location": optional Location
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringProblem implements HasToJson {
  RefactoringProblemSeverity _severity;

  String _message;

  Location _location;

  /// The severity of the problem being represented.
  RefactoringProblemSeverity get severity => _severity;

  /// The severity of the problem being represented.
  set severity(RefactoringProblemSeverity value) {
    assert(value != null);
    _severity = value;
  }

  /// A human-readable description of the problem being represented.
  String get message => _message;

  /// A human-readable description of the problem being represented.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// The location of the problem being represented. This field is omitted
  /// unless there is a specific location associated with the problem (such as
  /// a location where an element being renamed will be shadowed).
  Location get location => _location;

  /// The location of the problem being represented. This field is omitted
  /// unless there is a specific location associated with the problem (such as
  /// a location where an element being renamed will be shadowed).
  set location(Location value) {
    _location = value;
  }

  RefactoringProblem(RefactoringProblemSeverity severity, String message,
      {Location location}) {
    this.severity = severity;
    this.message = message;
    this.location = location;
  }

  factory RefactoringProblem.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      RefactoringProblemSeverity severity;
      if (json.containsKey('severity')) {
        severity = RefactoringProblemSeverity.fromJson(
            jsonDecoder, jsonPath + '.severity', json['severity']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'severity');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      }
      return RefactoringProblem(severity, message, location: location);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RefactoringProblem', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['severity'] = severity.toJson();
    result['message'] = message;
    if (location != null) {
      result['location'] = location.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringProblem) {
      return severity == other.severity &&
          message == other.message &&
          location == other.location;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RefactoringProblemSeverity
///
/// enum {
///   INFO
///   WARNING
///   ERROR
///   FATAL
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringProblemSeverity implements Enum {
  /// A minor code problem. No example, because it is not used yet.
  static const RefactoringProblemSeverity INFO =
      RefactoringProblemSeverity._('INFO');

  /// A minor code problem. For example names of local variables should be
  /// camel case and start with a lower case letter. Staring the name of a
  /// variable with an upper case is OK from the language point of view, but it
  /// is nice to warn the user.
  static const RefactoringProblemSeverity WARNING =
      RefactoringProblemSeverity._('WARNING');

  /// The refactoring technically can be performed, but there is a logical
  /// problem. For example the name of a local variable being extracted
  /// conflicts with another name in the scope, or duplicate parameter names in
  /// the method being extracted, or a conflict between a parameter name and a
  /// local variable, etc. In some cases the location of the problem is also
  /// provided, so the IDE can show user the location and the problem, and let
  /// the user decide whether they want to perform the refactoring. For example
  /// the name conflict might be expected, and the user wants to fix it
  /// afterwards.
  static const RefactoringProblemSeverity ERROR =
      RefactoringProblemSeverity._('ERROR');

  /// A fatal error, which prevents performing the refactoring. For example the
  /// name of a local variable being extracted is not a valid identifier, or
  /// selection is not a valid expression.
  static const RefactoringProblemSeverity FATAL =
      RefactoringProblemSeverity._('FATAL');

  /// A list containing all of the enum values that are defined.
  static const List<RefactoringProblemSeverity> VALUES =
      <RefactoringProblemSeverity>[INFO, WARNING, ERROR, FATAL];

  @override
  final String name;

  const RefactoringProblemSeverity._(this.name);

  factory RefactoringProblemSeverity(String name) {
    switch (name) {
      case 'INFO':
        return INFO;
      case 'WARNING':
        return WARNING;
      case 'ERROR':
        return ERROR;
      case 'FATAL':
        return FATAL;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RefactoringProblemSeverity.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return RefactoringProblemSeverity(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'RefactoringProblemSeverity', json);
  }

  /// Returns the [RefactoringProblemSeverity] with the maximal severity.
  static RefactoringProblemSeverity max(
          RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>
      maxRefactoringProblemSeverity(a, b);

  @override
  String toString() => 'RefactoringProblemSeverity.$name';

  String toJson() => name;
}

/// RemoveContentOverlay
///
/// {
///   "type": "remove"
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RemoveContentOverlay implements HasToJson {
  RemoveContentOverlay();

  factory RemoveContentOverlay.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      if (json['type'] != 'remove') {
        throw jsonDecoder.mismatch(jsonPath, 'equal remove', json);
      }
      return RemoveContentOverlay();
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RemoveContentOverlay', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['type'] = 'remove';
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RemoveContentOverlay) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, 114870849);
    return JenkinsSmiHash.finish(hash);
  }
}

/// SourceChange
///
/// {
///   "message": String
///   "edits": List<SourceFileEdit>
///   "linkedEditGroups": List<LinkedEditGroup>
///   "selection": optional Position
///   "id": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SourceChange implements HasToJson {
  String _message;

  List<SourceFileEdit> _edits;

  List<LinkedEditGroup> _linkedEditGroups;

  Position _selection;

  String _id;

  /// A human-readable description of the change to be applied.
  String get message => _message;

  /// A human-readable description of the change to be applied.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// A list of the edits used to effect the change, grouped by file.
  List<SourceFileEdit> get edits => _edits;

  /// A list of the edits used to effect the change, grouped by file.
  set edits(List<SourceFileEdit> value) {
    assert(value != null);
    _edits = value;
  }

  /// A list of the linked editing groups used to customize the changes that
  /// were made.
  List<LinkedEditGroup> get linkedEditGroups => _linkedEditGroups;

  /// A list of the linked editing groups used to customize the changes that
  /// were made.
  set linkedEditGroups(List<LinkedEditGroup> value) {
    assert(value != null);
    _linkedEditGroups = value;
  }

  /// The position that should be selected after the edits have been applied.
  Position get selection => _selection;

  /// The position that should be selected after the edits have been applied.
  set selection(Position value) {
    _selection = value;
  }

  /// The optional identifier of the change kind. The identifier remains stable
  /// even if the message changes, or is parameterized.
  String get id => _id;

  /// The optional identifier of the change kind. The identifier remains stable
  /// even if the message changes, or is parameterized.
  set id(String value) {
    _id = value;
  }

  SourceChange(String message,
      {List<SourceFileEdit> edits,
      List<LinkedEditGroup> linkedEditGroups,
      Position selection,
      String id}) {
    this.message = message;
    if (edits == null) {
      this.edits = <SourceFileEdit>[];
    } else {
      this.edits = edits;
    }
    if (linkedEditGroups == null) {
      this.linkedEditGroups = <LinkedEditGroup>[];
    } else {
      this.linkedEditGroups = linkedEditGroups;
    }
    this.selection = selection;
    this.id = id;
  }

  factory SourceChange.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      List<SourceFileEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      List<LinkedEditGroup> linkedEditGroups;
      if (json.containsKey('linkedEditGroups')) {
        linkedEditGroups = jsonDecoder.decodeList(
            jsonPath + '.linkedEditGroups',
            json['linkedEditGroups'],
            (String jsonPath, Object json) =>
                LinkedEditGroup.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'linkedEditGroups');
      }
      Position selection;
      if (json.containsKey('selection')) {
        selection = Position.fromJson(
            jsonDecoder, jsonPath + '.selection', json['selection']);
      }
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      }
      return SourceChange(message,
          edits: edits,
          linkedEditGroups: linkedEditGroups,
          selection: selection,
          id: id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'SourceChange', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['message'] = message;
    result['edits'] =
        edits.map((SourceFileEdit value) => value.toJson()).toList();
    result['linkedEditGroups'] = linkedEditGroups
        .map((LinkedEditGroup value) => value.toJson())
        .toList();
    if (selection != null) {
      result['selection'] = selection.toJson();
    }
    if (id != null) {
      result['id'] = id;
    }
    return result;
  }

  /// Adds [edit] to the [FileEdit] for the given [file].
  void addEdit(String file, int fileStamp, SourceEdit edit) =>
      addEditToSourceChange(this, file, fileStamp, edit);

  /// Adds the given [FileEdit].
  void addFileEdit(SourceFileEdit edit) {
    edits.add(edit);
  }

  /// Adds the given [LinkedEditGroup].
  void addLinkedEditGroup(LinkedEditGroup linkedEditGroup) {
    linkedEditGroups.add(linkedEditGroup);
  }

  /// Returns the [FileEdit] for the given [file], maybe `null`.
  SourceFileEdit getFileEdit(String file) => getChangeFileEdit(this, file);

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SourceChange) {
      return message == other.message &&
          listEqual(edits, other.edits,
              (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          listEqual(linkedEditGroups, other.linkedEditGroups,
              (LinkedEditGroup a, LinkedEditGroup b) => a == b) &&
          selection == other.selection &&
          id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkedEditGroups.hashCode);
    hash = JenkinsSmiHash.combine(hash, selection.hashCode);
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// SourceEdit
///
/// {
///   "offset": int
///   "length": int
///   "replacement": String
///   "id": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SourceEdit implements HasToJson {
  /// Get the result of applying a set of [edits] to the given [code]. Edits
  /// are applied in the order they appear in [edits].
  static String applySequence(String code, Iterable<SourceEdit> edits) =>
      applySequenceOfEdits(code, edits);

  int _offset;

  int _length;

  String _replacement;

  String _id;

  /// The offset of the region to be modified.
  int get offset => _offset;

  /// The offset of the region to be modified.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region to be modified.
  int get length => _length;

  /// The length of the region to be modified.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The code that is to replace the specified region in the original code.
  String get replacement => _replacement;

  /// The code that is to replace the specified region in the original code.
  set replacement(String value) {
    assert(value != null);
    _replacement = value;
  }

  /// An identifier that uniquely identifies this source edit from other edits
  /// in the same response. This field is omitted unless a containing structure
  /// needs to be able to identify the edit for some reason.
  ///
  /// For example, some refactoring operations can produce edits that might not
  /// be appropriate (referred to as potential edits). Such edits will have an
  /// id so that they can be referenced. Edits in the same response that do not
  /// need to be referenced will not have an id.
  String get id => _id;

  /// An identifier that uniquely identifies this source edit from other edits
  /// in the same response. This field is omitted unless a containing structure
  /// needs to be able to identify the edit for some reason.
  ///
  /// For example, some refactoring operations can produce edits that might not
  /// be appropriate (referred to as potential edits). Such edits will have an
  /// id so that they can be referenced. Edits in the same response that do not
  /// need to be referenced will not have an id.
  set id(String value) {
    _id = value;
  }

  SourceEdit(int offset, int length, String replacement, {String id}) {
    this.offset = offset;
    this.length = length;
    this.replacement = replacement;
    this.id = id;
  }

  factory SourceEdit.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String replacement;
      if (json.containsKey('replacement')) {
        replacement = jsonDecoder.decodeString(
            jsonPath + '.replacement', json['replacement']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacement');
      }
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      }
      return SourceEdit(offset, length, replacement, id: id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'SourceEdit', json);
    }
  }

  /// The end of the region to be modified.
  int get end => offset + length;

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    result['replacement'] = replacement;
    if (id != null) {
      result['id'] = id;
    }
    return result;
  }

  /// Get the result of applying the edit to the given [code].
  String apply(String code) => applyEdit(code, this);

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SourceEdit) {
      return offset == other.offset &&
          length == other.length &&
          replacement == other.replacement &&
          id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacement.hashCode);
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// SourceFileEdit
///
/// {
///   "file": FilePath
///   "fileStamp": long
///   "edits": List<SourceEdit>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SourceFileEdit implements HasToJson {
  String _file;

  int _fileStamp;

  List<SourceEdit> _edits;

  /// The file containing the code to be modified.
  String get file => _file;

  /// The file containing the code to be modified.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The modification stamp of the file at the moment when the change was
  /// created, in milliseconds since the "Unix epoch". Will be -1 if the file
  /// did not exist and should be created. The client may use this field to
  /// make sure that the file was not changed since then, so it is safe to
  /// apply the change.
  int get fileStamp => _fileStamp;

  /// The modification stamp of the file at the moment when the change was
  /// created, in milliseconds since the "Unix epoch". Will be -1 if the file
  /// did not exist and should be created. The client may use this field to
  /// make sure that the file was not changed since then, so it is safe to
  /// apply the change.
  set fileStamp(int value) {
    assert(value != null);
    _fileStamp = value;
  }

  /// A list of the edits used to effect the change.
  List<SourceEdit> get edits => _edits;

  /// A list of the edits used to effect the change.
  set edits(List<SourceEdit> value) {
    assert(value != null);
    _edits = value;
  }

  SourceFileEdit(String file, int fileStamp, {List<SourceEdit> edits}) {
    this.file = file;
    this.fileStamp = fileStamp;
    if (edits == null) {
      this.edits = <SourceEdit>[];
    } else {
      this.edits = edits;
    }
  }

  factory SourceFileEdit.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int fileStamp;
      if (json.containsKey('fileStamp')) {
        fileStamp =
            jsonDecoder.decodeInt(jsonPath + '.fileStamp', json['fileStamp']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fileStamp');
      }
      List<SourceEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      return SourceFileEdit(file, fileStamp, edits: edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'SourceFileEdit', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['fileStamp'] = fileStamp;
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  /// Adds the given [Edit] to the list.
  void add(SourceEdit edit) => addEditForSource(this, edit);

  /// Adds the given [Edit]s.
  void addAll(Iterable<SourceEdit> edits) => addAllEditsForSource(this, edits);

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SourceFileEdit) {
      return file == other.file &&
          fileStamp == other.fileStamp &&
          listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, fileStamp.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}
