// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:collection/collection.dart' show QueueList;

import 'package:analysis_server_client/src/protocol/protocol_internal.dart';

// ignore_for_file: flutter_style_todos

/// AddContentOverlay
///
///     {
///       "type": "add"
///       "content": String
///       "version": optional int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class AddContentOverlay implements HasToJson {
  /// The new content of the file.
  String content;

  /// An optional version number for the document. Version numbers allow the
  /// server to tag edits with the version of the document they apply to which
  /// can avoid applying edits to documents that have already been updated
  /// since the edits were computed.
  ///
  /// If version numbers are supplied with AddContentOverlay and
  /// ChangeContentOverlay, they must be increasing (but not necessarily
  /// consecutive) numbers.
  int? version;

  AddContentOverlay(this.content, {this.version});

  factory AddContentOverlay.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'AddContentOverlay'", json);
    }
    if (json['type'] != 'add') {
      throw jsonDecoder.mismatch(jsonPath, "equal to 'add'", json);
    }
    String content;
    if (json case {'content': var encodedContent}) {
      content = jsonDecoder.decodeString('$jsonPath.content', encodedContent);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'content'", json);
    }
    int? version;
    if (json case {'version': var encodedVersion}) {
      version = jsonDecoder.decodeInt('$jsonPath.version', encodedVersion);
    }
    return AddContentOverlay(content, version: version);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['type'] = 'add';
    result['content'] = content;
    if (version case var version?) {
      result['version'] = version;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AddContentOverlay) {
      return content == other.content && version == other.version;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(704418402, content, version);
}

/// AnalysisError
///
///     {
///       "severity": AnalysisErrorSeverity
///       "type": AnalysisErrorType
///       "location": Location
///       "message": String
///       "correction": optional String
///       "code": String
///       "url": optional String
///       "contextMessages": optional List<DiagnosticMessage>
///       "hasFix": optional bool
///     }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisError implements HasToJson {
  /// The severity of the error.
  AnalysisErrorSeverity severity;

  /// The type of the error.
  AnalysisErrorType type;

  /// The location associated with the error.
  Location location;

  /// The message to be displayed for this error. The message should indicate
  /// what is wrong with the code and why it is wrong.
  String message;

  /// The correction message to be displayed for this error. The correction
  /// message should indicate how the user can fix the error. The field is
  /// omitted if there is no correction message associated with the error code.
  String? correction;

  /// The name, as a string, of the error code associated with this error.
  String code;

  /// The URL of a page containing documentation associated with this error.
  String? url;

  /// Additional messages associated with this diagnostic that provide context
  /// to help the user understand the diagnostic.
  List<DiagnosticMessage>? contextMessages;

  /// A hint to indicate to interested clients that this error has an
  /// associated fix (or fixes). The absence of this field implies there are
  /// not known to be fixes. Note that since the operation to calculate whether
  /// fixes apply needs to be performant it is possible that complicated tests
  /// will be skipped and a false negative returned. For this reason, this
  /// attribute should be treated as a "hint". Despite the possibility of false
  /// negatives, no false positives should be returned. If a client sees this
  /// flag set they can proceed with the confidence that there are in fact
  /// associated fixes.
  bool? hasFix;

  AnalysisError(
    this.severity,
    this.type,
    this.location,
    this.message,
    this.code, {
    this.correction,
    this.url,
    this.contextMessages,
    this.hasFix,
  });

  factory AnalysisError.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'AnalysisError'", json);
    }
    AnalysisErrorSeverity severity;
    if (json case {'severity': var encodedSeverity}) {
      severity = AnalysisErrorSeverity.fromJson(
        jsonDecoder,
        '$jsonPath.severity',
        encodedSeverity,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'severity'", json);
    }
    AnalysisErrorType type;
    if (json case {'type': var encodedType}) {
      type = AnalysisErrorType.fromJson(
        jsonDecoder,
        '$jsonPath.type',
        encodedType,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'type'", json);
    }
    Location location;
    if (json case {'location': var encodedLocation}) {
      location = Location.fromJson(
        jsonDecoder,
        '$jsonPath.location',
        encodedLocation,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'location'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    String? correction;
    if (json case {'correction': var encodedCorrection}) {
      correction = jsonDecoder.decodeString(
        '$jsonPath.correction',
        encodedCorrection,
      );
    }
    String code;
    if (json case {'code': var encodedCode}) {
      code = jsonDecoder.decodeString('$jsonPath.code', encodedCode);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'code'", json);
    }
    String? url;
    if (json case {'url': var encodedUrl}) {
      url = jsonDecoder.decodeString('$jsonPath.url', encodedUrl);
    }
    List<DiagnosticMessage>? contextMessages;
    if (json case {'contextMessages': var encodedContextMessages}) {
      contextMessages = jsonDecoder.decodeList(
        '$jsonPath.contextMessages',
        encodedContextMessages,
        (String jsonPath, Object? json) =>
            DiagnosticMessage.fromJson(jsonDecoder, jsonPath, json),
      );
    }
    bool? hasFix;
    if (json case {'hasFix': var encodedHasFix}) {
      hasFix = jsonDecoder.decodeBool('$jsonPath.hasFix', encodedHasFix);
    }
    return AnalysisError(
      severity,
      type,
      location,
      message,
      code,
      correction: correction,
      url: url,
      contextMessages: contextMessages,
      hasFix: hasFix,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['severity'] = severity.toJson();
    result['type'] = type.toJson();
    result['location'] = location.toJson();
    result['message'] = message;
    if (correction case var correction?) {
      result['correction'] = correction;
    }
    result['code'] = code;
    if (url case var url?) {
      result['url'] = url;
    }
    if (contextMessages case var contextMessages?) {
      result['contextMessages'] = contextMessages
          .map((DiagnosticMessage value) => value.toJson())
          .toList();
    }
    if (hasFix case var hasFix?) {
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
          listEqual(
            contextMessages,
            other.contextMessages,
            (DiagnosticMessage a, DiagnosticMessage b) => a == b,
          ) &&
          hasFix == other.hasFix;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    severity,
    type,
    location,
    message,
    correction,
    code,
    url,
    Object.hashAll(contextMessages ?? []),
    hasFix,
  );
}

/// AnalysisErrorSeverity
///
///     enum {
///       INFO
///       WARNING
///       ERROR
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum AnalysisErrorSeverity {
  INFO,

  WARNING,

  ERROR;

  factory AnalysisErrorSeverity.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'AnalysisErrorSeverity'", json);
  }

  @override
  String toString() => 'AnalysisErrorSeverity.$name';

  String toJson() => name;
}

/// AnalysisErrorType
///
///     enum {
///       CHECKED_MODE_COMPILE_TIME_ERROR
///       COMPILE_TIME_ERROR
///       HINT
///       LINT
///       STATIC_TYPE_WARNING
///       STATIC_WARNING
///       SYNTACTIC_ERROR
///       TODO
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum AnalysisErrorType {
  CHECKED_MODE_COMPILE_TIME_ERROR,

  COMPILE_TIME_ERROR,

  HINT,

  LINT,

  STATIC_TYPE_WARNING,

  STATIC_WARNING,

  SYNTACTIC_ERROR,

  TODO;

  factory AnalysisErrorType.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'AnalysisErrorType'", json);
  }

  @override
  String toString() => 'AnalysisErrorType.$name';

  String toJson() => name;
}

/// AssistDescription
///
///     {
///       "id": String
///       "message": String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class AssistDescription implements HasToJson {
  /// The ID.
  String id;

  /// The message that is presented to the user, to carry out this assist.
  String message;

  AssistDescription(this.id, this.message);

  factory AssistDescription.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'AssistDescription'", json);
    }
    String id;
    if (json case {'id': var encodedId}) {
      id = jsonDecoder.decodeString('$jsonPath.id', encodedId);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'id'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    return AssistDescription(id, message);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['message'] = message;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AssistDescription) {
      return id == other.id && message == other.message;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(id, message);
}

/// ChangeContentOverlay
///
///     {
///       "type": "change"
///       "edits": List<SourceEdit>
///       "version": optional int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class ChangeContentOverlay implements HasToJson {
  /// The edits to be applied to the file.
  List<SourceEdit> edits;

  /// An optional version number for the document. Version numbers allow the
  /// server to tag edits with the version of the document they apply to which
  /// can avoid applying edits to documents that have already been updated
  /// since the edits were computed.
  ///
  /// If version numbers are supplied with AddContentOverlay and
  /// ChangeContentOverlay, they must be increasing (but not necessarily
  /// consecutive) numbers.
  int? version;

  ChangeContentOverlay(this.edits, {this.version});

  factory ChangeContentOverlay.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'ChangeContentOverlay'", json);
    }
    if (json['type'] != 'change') {
      throw jsonDecoder.mismatch(jsonPath, "equal to 'change'", json);
    }
    List<SourceEdit> edits;
    if (json case {'edits': var encodedEdits}) {
      edits = jsonDecoder.decodeList(
        '$jsonPath.edits',
        encodedEdits,
        (String jsonPath, Object? json) =>
            SourceEdit.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'edits'", json);
    }
    int? version;
    if (json case {'version': var encodedVersion}) {
      version = jsonDecoder.decodeInt('$jsonPath.version', encodedVersion);
    }
    return ChangeContentOverlay(edits, version: version);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['type'] = 'change';
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    if (version case var version?) {
      result['version'] = version;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ChangeContentOverlay) {
      return listEqual(
            edits,
            other.edits,
            (SourceEdit a, SourceEdit b) => a == b,
          ) &&
          version == other.version;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(873118866, Object.hashAll(edits), version);
}

/// CompletionSuggestion
///
///     {
///       "kind": CompletionSuggestionKind
///       "relevance": int
///       "completion": String
///       "displayText": optional String
///       "replacementOffset": optional int
///       "replacementLength": optional int
///       "selectionOffset": int
///       "selectionLength": int
///       "isDeprecated": bool
///       "isPotential": bool
///       "docSummary": optional String
///       "docComplete": optional String
///       "declaringType": optional String
///       "defaultArgumentListString": optional String
///       "defaultArgumentListTextRanges": optional List<int>
///       "element": optional Element
///       "returnType": optional String
///       "parameterNames": optional List<String>
///       "parameterTypes": optional List<String>
///       "requiredParameterCount": optional int
///       "hasNamedParameters": optional bool
///       "parameterName": optional String
///       "parameterType": optional String
///       "libraryUri": optional String
///       "isNotImported": optional bool
///     }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSuggestion implements HasToJson {
  /// The kind of element being suggested.
  CompletionSuggestionKind kind;

  /// The relevance of this completion suggestion where a higher number
  /// indicates a higher relevance.
  int relevance;

  /// The identifier to be inserted if the suggestion is selected. If the
  /// suggestion is for a method or function, the client might want to
  /// additionally insert a template for the parameters. The information
  /// required in order to do so is contained in other fields.
  String completion;

  /// Text to be displayed in, for example, a completion pop-up. This field is
  /// only defined if the displayed text should be different than the
  /// completion. Otherwise it is omitted.
  String? displayText;

  /// The offset of the start of the text to be replaced. If supplied, this
  /// should be used in preference to the offset provided on the containing
  /// completion results. This value may be provided independently of
  /// replacementLength (for example if only one differs from the completion
  /// result value).
  int? replacementOffset;

  /// The length of the text to be replaced. If supplied, this should be used
  /// in preference to the offset provided on the containing completion
  /// results. This value may be provided independently of replacementOffset
  /// (for example if only one differs from the completion result value).
  int? replacementLength;

  /// The offset, relative to the beginning of the completion, of where the
  /// selection should be placed after insertion.
  int selectionOffset;

  /// The number of characters that should be selected after insertion.
  int selectionLength;

  /// True if the suggested element is deprecated.
  bool isDeprecated;

  /// True if the element is not known to be valid for the target. This happens
  /// if the type of the target is dynamic.
  bool isPotential;

  /// An abbreviated version of the Dartdoc associated with the element being
  /// suggested. This field is omitted if there is no Dartdoc associated with
  /// the element.
  String? docSummary;

  /// The Dartdoc associated with the element being suggested. This field is
  /// omitted if there is no Dartdoc associated with the element.
  String? docComplete;

  /// The class that declares the element being suggested. This field is
  /// omitted if the suggested element is not a member of a class.
  String? declaringType;

  /// A default String for use in generating argument list source contents on
  /// the client side.
  String? defaultArgumentListString;

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  List<int>? defaultArgumentListTextRanges;

  /// Information about the element reference being suggested.
  Element? element;

  /// The return type of the getter, function or method or the type of the
  /// field being suggested. This field is omitted if the suggested element is
  /// not a getter, function or method.
  String? returnType;

  /// The names of the parameters of the function or method being suggested.
  /// This field is omitted if the suggested element is not a setter, function
  /// or method.
  List<String>? parameterNames;

  /// The types of the parameters of the function or method being suggested.
  /// This field is omitted if the parameterNames field is omitted.
  List<String>? parameterTypes;

  /// The number of required parameters for the function or method being
  /// suggested. This field is omitted if the parameterNames field is omitted.
  int? requiredParameterCount;

  /// True if the function or method being suggested has at least one named
  /// parameter. This field is omitted if the parameterNames field is omitted.
  bool? hasNamedParameters;

  /// The name of the optional parameter being suggested. This field is omitted
  /// if the suggestion is not the addition of an optional argument within an
  /// argument list.
  String? parameterName;

  /// The type of the options parameter being suggested. This field is omitted
  /// if the parameterName field is omitted.
  String? parameterType;

  /// This field is omitted if `getSuggestions` was used rather than
  /// `getSuggestions2`.
  ///
  /// This field is omitted if this suggestion corresponds to a locally
  /// declared element.
  ///
  /// If this suggestion corresponds to an already imported element, then this
  /// field is the URI of a library that provides this element, not the URI of
  /// the library where the element is declared.
  ///
  /// If this suggestion corresponds to an element from a not yet imported
  /// library, this field is the URI of a library that could be imported to
  /// make this suggestion accessible in the file where completion was
  /// requested, such as `package:foo/bar.dart` or
  /// `file:///home/me/workspace/foo/test/bar_test.dart`.
  String? libraryUri;

  /// True if the suggestion is for an element from a not yet imported library.
  /// This field is omitted if the element is declared locally, or is from
  /// library is already imported, so that the suggestion can be inserted as
  /// is, or if `getSuggestions` was used rather than `getSuggestions2`.
  bool? isNotImported;

  CompletionSuggestion(
    this.kind,
    this.relevance,
    this.completion,
    this.selectionOffset,
    this.selectionLength,
    this.isDeprecated,
    this.isPotential, {
    this.displayText,
    this.replacementOffset,
    this.replacementLength,
    this.docSummary,
    this.docComplete,
    this.declaringType,
    this.defaultArgumentListString,
    this.defaultArgumentListTextRanges,
    this.element,
    this.returnType,
    this.parameterNames,
    this.parameterTypes,
    this.requiredParameterCount,
    this.hasNamedParameters,
    this.parameterName,
    this.parameterType,
    this.libraryUri,
    this.isNotImported,
  });

  factory CompletionSuggestion.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'CompletionSuggestion'", json);
    }
    CompletionSuggestionKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = CompletionSuggestionKind.fromJson(
        jsonDecoder,
        '$jsonPath.kind',
        encodedKind,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    int relevance;
    if (json case {'relevance': var encodedRelevance}) {
      relevance = jsonDecoder.decodeInt(
        '$jsonPath.relevance',
        encodedRelevance,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'relevance'", json);
    }
    String completion;
    if (json case {'completion': var encodedCompletion}) {
      completion = jsonDecoder.decodeString(
        '$jsonPath.completion',
        encodedCompletion,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'completion'", json);
    }
    String? displayText;
    if (json case {'displayText': var encodedDisplayText}) {
      displayText = jsonDecoder.decodeString(
        '$jsonPath.displayText',
        encodedDisplayText,
      );
    }
    int? replacementOffset;
    if (json case {'replacementOffset': var encodedReplacementOffset}) {
      replacementOffset = jsonDecoder.decodeInt(
        '$jsonPath.replacementOffset',
        encodedReplacementOffset,
      );
    }
    int? replacementLength;
    if (json case {'replacementLength': var encodedReplacementLength}) {
      replacementLength = jsonDecoder.decodeInt(
        '$jsonPath.replacementLength',
        encodedReplacementLength,
      );
    }
    int selectionOffset;
    if (json case {'selectionOffset': var encodedSelectionOffset}) {
      selectionOffset = jsonDecoder.decodeInt(
        '$jsonPath.selectionOffset',
        encodedSelectionOffset,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'selectionOffset'", json);
    }
    int selectionLength;
    if (json case {'selectionLength': var encodedSelectionLength}) {
      selectionLength = jsonDecoder.decodeInt(
        '$jsonPath.selectionLength',
        encodedSelectionLength,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'selectionLength'", json);
    }
    bool isDeprecated;
    if (json case {'isDeprecated': var encodedIsDeprecated}) {
      isDeprecated = jsonDecoder.decodeBool(
        '$jsonPath.isDeprecated',
        encodedIsDeprecated,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isDeprecated'", json);
    }
    bool isPotential;
    if (json case {'isPotential': var encodedIsPotential}) {
      isPotential = jsonDecoder.decodeBool(
        '$jsonPath.isPotential',
        encodedIsPotential,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'isPotential'", json);
    }
    String? docSummary;
    if (json case {'docSummary': var encodedDocSummary}) {
      docSummary = jsonDecoder.decodeString(
        '$jsonPath.docSummary',
        encodedDocSummary,
      );
    }
    String? docComplete;
    if (json case {'docComplete': var encodedDocComplete}) {
      docComplete = jsonDecoder.decodeString(
        '$jsonPath.docComplete',
        encodedDocComplete,
      );
    }
    String? declaringType;
    if (json case {'declaringType': var encodedDeclaringType}) {
      declaringType = jsonDecoder.decodeString(
        '$jsonPath.declaringType',
        encodedDeclaringType,
      );
    }
    String? defaultArgumentListString;
    if (json case {
      'defaultArgumentListString': var encodedDefaultArgumentListString,
    }) {
      defaultArgumentListString = jsonDecoder.decodeString(
        '$jsonPath.defaultArgumentListString',
        encodedDefaultArgumentListString,
      );
    }
    List<int>? defaultArgumentListTextRanges;
    if (json case {
      'defaultArgumentListTextRanges': var encodedDefaultArgumentListTextRanges,
    }) {
      defaultArgumentListTextRanges = jsonDecoder.decodeList(
        '$jsonPath.defaultArgumentListTextRanges',
        encodedDefaultArgumentListTextRanges,
        jsonDecoder.decodeInt,
      );
    }
    Element? element;
    if (json case {'element': var encodedElement}) {
      element = Element.fromJson(
        jsonDecoder,
        '$jsonPath.element',
        encodedElement,
      );
    }
    String? returnType;
    if (json case {'returnType': var encodedReturnType}) {
      returnType = jsonDecoder.decodeString(
        '$jsonPath.returnType',
        encodedReturnType,
      );
    }
    List<String>? parameterNames;
    if (json case {'parameterNames': var encodedParameterNames}) {
      parameterNames = jsonDecoder.decodeList(
        '$jsonPath.parameterNames',
        encodedParameterNames,
        jsonDecoder.decodeString,
      );
    }
    List<String>? parameterTypes;
    if (json case {'parameterTypes': var encodedParameterTypes}) {
      parameterTypes = jsonDecoder.decodeList(
        '$jsonPath.parameterTypes',
        encodedParameterTypes,
        jsonDecoder.decodeString,
      );
    }
    int? requiredParameterCount;
    if (json case {
      'requiredParameterCount': var encodedRequiredParameterCount,
    }) {
      requiredParameterCount = jsonDecoder.decodeInt(
        '$jsonPath.requiredParameterCount',
        encodedRequiredParameterCount,
      );
    }
    bool? hasNamedParameters;
    if (json case {'hasNamedParameters': var encodedHasNamedParameters}) {
      hasNamedParameters = jsonDecoder.decodeBool(
        '$jsonPath.hasNamedParameters',
        encodedHasNamedParameters,
      );
    }
    String? parameterName;
    if (json case {'parameterName': var encodedParameterName}) {
      parameterName = jsonDecoder.decodeString(
        '$jsonPath.parameterName',
        encodedParameterName,
      );
    }
    String? parameterType;
    if (json case {'parameterType': var encodedParameterType}) {
      parameterType = jsonDecoder.decodeString(
        '$jsonPath.parameterType',
        encodedParameterType,
      );
    }
    String? libraryUri;
    if (json case {'libraryUri': var encodedLibraryUri}) {
      libraryUri = jsonDecoder.decodeString(
        '$jsonPath.libraryUri',
        encodedLibraryUri,
      );
    }
    bool? isNotImported;
    if (json case {'isNotImported': var encodedIsNotImported}) {
      isNotImported = jsonDecoder.decodeBool(
        '$jsonPath.isNotImported',
        encodedIsNotImported,
      );
    }
    return CompletionSuggestion(
      kind,
      relevance,
      completion,
      selectionOffset,
      selectionLength,
      isDeprecated,
      isPotential,
      displayText: displayText,
      replacementOffset: replacementOffset,
      replacementLength: replacementLength,
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
      parameterType: parameterType,
      libraryUri: libraryUri,
      isNotImported: isNotImported,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['relevance'] = relevance;
    result['completion'] = completion;
    if (displayText case var displayText?) {
      result['displayText'] = displayText;
    }
    if (replacementOffset case var replacementOffset?) {
      result['replacementOffset'] = replacementOffset;
    }
    if (replacementLength case var replacementLength?) {
      result['replacementLength'] = replacementLength;
    }
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    result['isDeprecated'] = isDeprecated;
    result['isPotential'] = isPotential;
    if (docSummary case var docSummary?) {
      result['docSummary'] = docSummary;
    }
    if (docComplete case var docComplete?) {
      result['docComplete'] = docComplete;
    }
    if (declaringType case var declaringType?) {
      result['declaringType'] = declaringType;
    }
    if (defaultArgumentListString case var defaultArgumentListString?) {
      result['defaultArgumentListString'] = defaultArgumentListString;
    }
    if (defaultArgumentListTextRanges case var defaultArgumentListTextRanges?) {
      result['defaultArgumentListTextRanges'] = defaultArgumentListTextRanges;
    }
    if (element case var element?) {
      result['element'] = element.toJson();
    }
    if (returnType case var returnType?) {
      result['returnType'] = returnType;
    }
    if (parameterNames case var parameterNames?) {
      result['parameterNames'] = parameterNames;
    }
    if (parameterTypes case var parameterTypes?) {
      result['parameterTypes'] = parameterTypes;
    }
    if (requiredParameterCount case var requiredParameterCount?) {
      result['requiredParameterCount'] = requiredParameterCount;
    }
    if (hasNamedParameters case var hasNamedParameters?) {
      result['hasNamedParameters'] = hasNamedParameters;
    }
    if (parameterName case var parameterName?) {
      result['parameterName'] = parameterName;
    }
    if (parameterType case var parameterType?) {
      result['parameterType'] = parameterType;
    }
    if (libraryUri case var libraryUri?) {
      result['libraryUri'] = libraryUri;
    }
    if (isNotImported case var isNotImported?) {
      result['isNotImported'] = isNotImported;
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
          replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength &&
          isDeprecated == other.isDeprecated &&
          isPotential == other.isPotential &&
          docSummary == other.docSummary &&
          docComplete == other.docComplete &&
          declaringType == other.declaringType &&
          defaultArgumentListString == other.defaultArgumentListString &&
          listEqual(
            defaultArgumentListTextRanges,
            other.defaultArgumentListTextRanges,
            (int a, int b) => a == b,
          ) &&
          element == other.element &&
          returnType == other.returnType &&
          listEqual(
            parameterNames,
            other.parameterNames,
            (String a, String b) => a == b,
          ) &&
          listEqual(
            parameterTypes,
            other.parameterTypes,
            (String a, String b) => a == b,
          ) &&
          requiredParameterCount == other.requiredParameterCount &&
          hasNamedParameters == other.hasNamedParameters &&
          parameterName == other.parameterName &&
          parameterType == other.parameterType &&
          libraryUri == other.libraryUri &&
          isNotImported == other.isNotImported;
    }
    return false;
  }

  @override
  int get hashCode => Object.hashAll([
    kind,
    relevance,
    completion,
    displayText,
    replacementOffset,
    replacementLength,
    selectionOffset,
    selectionLength,
    isDeprecated,
    isPotential,
    docSummary,
    docComplete,
    declaringType,
    defaultArgumentListString,
    Object.hashAll(defaultArgumentListTextRanges ?? []),
    element,
    returnType,
    Object.hashAll(parameterNames ?? []),
    Object.hashAll(parameterTypes ?? []),
    requiredParameterCount,
    hasNamedParameters,
    parameterName,
    parameterType,
    libraryUri,
    isNotImported,
  ]);
}

/// CompletionSuggestionKind
///
///     enum {
///       ARGUMENT_LIST
///       IMPORT
///       IDENTIFIER
///       INVOCATION
///       KEYWORD
///       NAMED_ARGUMENT
///       OPTIONAL_ARGUMENT
///       OVERRIDE
///       PARAMETER
///       PACKAGE_NAME
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum CompletionSuggestionKind {
  /// A list of arguments for the method or function that is being invoked. For
  /// this suggestion kind, the completion field is a textual representation of
  /// the invocation and the parameterNames, parameterTypes, and
  /// requiredParameterCount attributes are defined.
  ARGUMENT_LIST,

  IMPORT,

  /// The element identifier should be inserted at the completion location. For
  /// example "someMethod" in `import 'myLib.dart' show someMethod;`. For
  /// suggestions of this kind, the element attribute is defined and the
  /// completion field is the element's identifier.
  IDENTIFIER,

  /// The element is being invoked at the completion location. For example,
  /// 'someMethod' in `x.someMethod();`. For suggestions of this kind, the
  /// element attribute is defined and the completion field is the element's
  /// identifier.
  INVOCATION,

  /// A keyword is being suggested. For suggestions of this kind, the
  /// completion is the keyword.
  KEYWORD,

  /// A named argument for the current call site is being suggested. For
  /// suggestions of this kind, the completion is the named argument identifier
  /// including a trailing ':' and a space.
  NAMED_ARGUMENT,

  OPTIONAL_ARGUMENT,

  /// An overriding implementation of a class member is being suggested.
  OVERRIDE,

  PARAMETER,

  /// The name of a pub package is being suggested.
  PACKAGE_NAME;

  factory CompletionSuggestionKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'CompletionSuggestionKind'", json);
  }

  @override
  String toString() => 'CompletionSuggestionKind.$name';

  String toJson() => name;
}

/// DiagnosticMessage
///
///     {
///       "message": String
///       "location": Location
///     }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticMessage implements HasToJson {
  /// The message to be displayed to the user.
  String message;

  /// The location associated with or referenced by the message. Clients should
  /// provide the ability to navigate to the location.
  Location location;

  DiagnosticMessage(this.message, this.location);

  factory DiagnosticMessage.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'DiagnosticMessage'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    Location location;
    if (json case {'location': var encodedLocation}) {
      location = Location.fromJson(
        jsonDecoder,
        '$jsonPath.location',
        encodedLocation,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'location'", json);
    }
    return DiagnosticMessage(message, location);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(message, location);
}

/// Element
///
///     {
///       "kind": ElementKind
///       "name": String
///       "location": optional Location
///       "flags": int
///       "parameters": optional String
///       "returnType": optional String
///       "typeParameters": optional String
///       "aliasedType": optional String
///       "extendedType": optional String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class Element implements HasToJson {
  static const int FLAG_ABSTRACT = 0x01;
  static const int FLAG_CONST = 0x02;
  static const int FLAG_FINAL = 0x04;
  static const int FLAG_STATIC = 0x08;
  static const int FLAG_PRIVATE = 0x10;
  static const int FLAG_DEPRECATED = 0x20;

  static int makeFlags({
    bool isAbstract = false,
    bool isConst = false,
    bool isFinal = false,
    bool isStatic = false,
    bool isPrivate = false,
    bool isDeprecated = false,
  }) {
    var flags = 0;
    if (isAbstract) flags |= FLAG_ABSTRACT;
    if (isConst) flags |= FLAG_CONST;
    if (isFinal) flags |= FLAG_FINAL;
    if (isStatic) flags |= FLAG_STATIC;
    if (isPrivate) flags |= FLAG_PRIVATE;
    if (isDeprecated) flags |= FLAG_DEPRECATED;
    return flags;
  }

  /// The kind of the element.
  ElementKind kind;

  /// The name of the element. This is typically used as the label in the
  /// outline.
  String name;

  /// The location of the name in the declaration of the element.
  Location? location;

  /// A bit-map containing the following flags:
  ///
  /// - 0x01 - set if the element is explicitly or implicitly abstract
  /// - 0x02 - set if the element was declared to be 'const'
  /// - 0x04 - set if the element was declared to be 'final'
  /// - 0x08 - set if the element is a static member of a class or is a
  ///   top-level function or field
  /// - 0x10 - set if the element is private
  /// - 0x20 - set if the element is deprecated
  int flags;

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()".
  String? parameters;

  /// The return type of the element. If the element is not a method or
  /// function this field will not be defined. If the element does not have a
  /// declared return type, this field will contain an empty string.
  String? returnType;

  /// The type parameter list for the element. If the element doesn't have type
  /// parameters, this field will not be defined.
  String? typeParameters;

  /// If the element is a type alias, this field is the aliased type. Otherwise
  /// this field will not be defined.
  String? aliasedType;

  /// If the element is an extension, this field is the name of the type that
  /// is extended. This can be useful to show in UIs for unnamed extension, for
  /// example "extension on {extendedType}". This field might not be defined
  /// even for an extension in the case of invalid code.
  String? extendedType;

  Element(
    this.kind,
    this.name,
    this.flags, {
    this.location,
    this.parameters,
    this.returnType,
    this.typeParameters,
    this.aliasedType,
    this.extendedType,
  });

  factory Element.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'Element'", json);
    }
    ElementKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = ElementKind.fromJson(jsonDecoder, '$jsonPath.kind', encodedKind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    Location? location;
    if (json case {'location': var encodedLocation}) {
      location = Location.fromJson(
        jsonDecoder,
        '$jsonPath.location',
        encodedLocation,
      );
    }
    int flags;
    if (json case {'flags': var encodedFlags}) {
      flags = jsonDecoder.decodeInt('$jsonPath.flags', encodedFlags);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'flags'", json);
    }
    String? parameters;
    if (json case {'parameters': var encodedParameters}) {
      parameters = jsonDecoder.decodeString(
        '$jsonPath.parameters',
        encodedParameters,
      );
    }
    String? returnType;
    if (json case {'returnType': var encodedReturnType}) {
      returnType = jsonDecoder.decodeString(
        '$jsonPath.returnType',
        encodedReturnType,
      );
    }
    String? typeParameters;
    if (json case {'typeParameters': var encodedTypeParameters}) {
      typeParameters = jsonDecoder.decodeString(
        '$jsonPath.typeParameters',
        encodedTypeParameters,
      );
    }
    String? aliasedType;
    if (json case {'aliasedType': var encodedAliasedType}) {
      aliasedType = jsonDecoder.decodeString(
        '$jsonPath.aliasedType',
        encodedAliasedType,
      );
    }
    String? extendedType;
    if (json case {'extendedType': var encodedExtendedType}) {
      extendedType = jsonDecoder.decodeString(
        '$jsonPath.extendedType',
        encodedExtendedType,
      );
    }
    return Element(
      kind,
      name,
      flags,
      location: location,
      parameters: parameters,
      returnType: returnType,
      typeParameters: typeParameters,
      aliasedType: aliasedType,
      extendedType: extendedType,
    );
  }

  bool get isAbstract => (flags & FLAG_ABSTRACT) != 0;
  bool get isConst => (flags & FLAG_CONST) != 0;
  bool get isFinal => (flags & FLAG_FINAL) != 0;
  bool get isStatic => (flags & FLAG_STATIC) != 0;
  bool get isPrivate => (flags & FLAG_PRIVATE) != 0;
  bool get isDeprecated => (flags & FLAG_DEPRECATED) != 0;

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['name'] = name;
    if (location case var location?) {
      result['location'] = location.toJson();
    }
    result['flags'] = flags;
    if (parameters case var parameters?) {
      result['parameters'] = parameters;
    }
    if (returnType case var returnType?) {
      result['returnType'] = returnType;
    }
    if (typeParameters case var typeParameters?) {
      result['typeParameters'] = typeParameters;
    }
    if (aliasedType case var aliasedType?) {
      result['aliasedType'] = aliasedType;
    }
    if (extendedType case var extendedType?) {
      result['extendedType'] = extendedType;
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
          typeParameters == other.typeParameters &&
          aliasedType == other.aliasedType &&
          extendedType == other.extendedType;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    name,
    location,
    flags,
    parameters,
    returnType,
    typeParameters,
    aliasedType,
    extendedType,
  );
}

/// ElementKind
///
///     enum {
///       CLASS
///       CLASS_TYPE_ALIAS
///       COMPILATION_UNIT
///       CONSTRUCTOR
///       CONSTRUCTOR_INVOCATION
///       ENUM
///       ENUM_CONSTANT
///       EXTENSION
///       EXTENSION_TYPE
///       FIELD
///       FILE
///       FUNCTION
///       FUNCTION_INVOCATION
///       FUNCTION_TYPE_ALIAS
///       GETTER
///       LABEL
///       LIBRARY
///       LOCAL_VARIABLE
///       METHOD
///       MIXIN
///       PARAMETER
///       PREFIX
///       SETTER
///       TOP_LEVEL_VARIABLE
///       TYPE_ALIAS
///       TYPE_PARAMETER
///       UNIT_TEST_GROUP
///       UNIT_TEST_TEST
///       UNKNOWN
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum ElementKind {
  CLASS,

  CLASS_TYPE_ALIAS,

  COMPILATION_UNIT,

  CONSTRUCTOR,

  CONSTRUCTOR_INVOCATION,

  ENUM,

  ENUM_CONSTANT,

  EXTENSION,

  EXTENSION_TYPE,

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

  TYPE_ALIAS,

  TYPE_PARAMETER,

  UNIT_TEST_GROUP,

  UNIT_TEST_TEST,

  UNKNOWN;

  factory ElementKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'ElementKind'", json);
  }

  @override
  String toString() => 'ElementKind.$name';

  String toJson() => name;
}

/// FixDescription
///
///     {
///       "id": String
///       "message": String
///       "codes": List<String>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class FixDescription implements HasToJson {
  /// The ID.
  String id;

  /// The message that is presented to the user, to carry out this fix.
  String message;

  /// The IDs of the diagnostic codes with which this fix was registered.
  List<String> codes;

  FixDescription(this.id, this.message, this.codes);

  factory FixDescription.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'FixDescription'", json);
    }
    String id;
    if (json case {'id': var encodedId}) {
      id = jsonDecoder.decodeString('$jsonPath.id', encodedId);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'id'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    List<String> codes;
    if (json case {'codes': var encodedCodes}) {
      codes = jsonDecoder.decodeList(
        '$jsonPath.codes',
        encodedCodes,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'codes'", json);
    }
    return FixDescription(id, message, codes);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['id'] = id;
    result['message'] = message;
    result['codes'] = codes;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FixDescription) {
      return id == other.id &&
          message == other.message &&
          listEqual(codes, other.codes, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(id, message, Object.hashAll(codes));
}

/// FoldingKind
///
///     enum {
///       ANNOTATIONS
///       BLOCK
///       CLASS_BODY
///       COMMENT
///       DIRECTIVES
///       DOCUMENTATION_COMMENT
///       FILE_HEADER
///       FUNCTION_BODY
///       INVOCATION
///       LITERAL
///       PARAMETERS
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum FoldingKind {
  ANNOTATIONS,

  BLOCK,

  CLASS_BODY,

  COMMENT,

  DIRECTIVES,

  DOCUMENTATION_COMMENT,

  FILE_HEADER,

  FUNCTION_BODY,

  INVOCATION,

  LITERAL,

  PARAMETERS;

  factory FoldingKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'FoldingKind'", json);
  }

  @override
  String toString() => 'FoldingKind.$name';

  String toJson() => name;
}

/// FoldingRegion
///
///     {
///       "kind": FoldingKind
///       "offset": int
///       "length": int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class FoldingRegion implements HasToJson {
  /// The kind of the region.
  FoldingKind kind;

  /// The offset of the region to be folded.
  int offset;

  /// The length of the region to be folded.
  int length;

  FoldingRegion(this.kind, this.offset, this.length);

  factory FoldingRegion.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'FoldingRegion'", json);
    }
    FoldingKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = FoldingKind.fromJson(jsonDecoder, '$jsonPath.kind', encodedKind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return FoldingRegion(kind, offset, length);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(kind, offset, length);
}

/// HighlightRegion
///
///     {
///       "type": HighlightRegionType
///       "offset": int
///       "length": int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class HighlightRegion implements HasToJson {
  /// The type of highlight associated with the region.
  HighlightRegionType type;

  /// The offset of the region to be highlighted.
  int offset;

  /// The length of the region to be highlighted.
  int length;

  HighlightRegion(this.type, this.offset, this.length);

  factory HighlightRegion.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'HighlightRegion'", json);
    }
    HighlightRegionType type;
    if (json case {'type': var encodedType}) {
      type = HighlightRegionType.fromJson(
        jsonDecoder,
        '$jsonPath.type',
        encodedType,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'type'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return HighlightRegion(type, offset, length);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(type, offset, length);
}

/// HighlightRegionType
///
///     enum {
///       ANNOTATION
///       BUILT_IN
///       CLASS
///       COMMENT_BLOCK
///       COMMENT_DOCUMENTATION
///       COMMENT_END_OF_LINE
///       CONSTRUCTOR
///       CONSTRUCTOR_TEAR_OFF
///       DIRECTIVE
///       DYNAMIC_TYPE
///       DYNAMIC_LOCAL_VARIABLE_DECLARATION
///       DYNAMIC_LOCAL_VARIABLE_REFERENCE
///       DYNAMIC_PARAMETER_DECLARATION
///       DYNAMIC_PARAMETER_REFERENCE
///       ENUM
///       ENUM_CONSTANT
///       EXTENSION
///       EXTENSION_TYPE
///       FIELD
///       FIELD_STATIC
///       FUNCTION
///       FUNCTION_DECLARATION
///       FUNCTION_TYPE_ALIAS
///       GETTER_DECLARATION
///       IDENTIFIER_DEFAULT
///       IMPORT_PREFIX
///       INSTANCE_FIELD_DECLARATION
///       INSTANCE_FIELD_REFERENCE
///       INSTANCE_GETTER_DECLARATION
///       INSTANCE_GETTER_REFERENCE
///       INSTANCE_METHOD_DECLARATION
///       INSTANCE_METHOD_REFERENCE
///       INSTANCE_METHOD_TEAR_OFF
///       INSTANCE_SETTER_DECLARATION
///       INSTANCE_SETTER_REFERENCE
///       INVALID_STRING_ESCAPE
///       KEYWORD
///       LABEL
///       LIBRARY_NAME
///       LITERAL_BOOLEAN
///       LITERAL_DOUBLE
///       LITERAL_INTEGER
///       LITERAL_LIST
///       LITERAL_MAP
///       LITERAL_RECORD
///       LITERAL_STRING
///       LOCAL_FUNCTION_DECLARATION
///       LOCAL_FUNCTION_REFERENCE
///       LOCAL_FUNCTION_TEAR_OFF
///       LOCAL_VARIABLE
///       LOCAL_VARIABLE_DECLARATION
///       LOCAL_VARIABLE_REFERENCE
///       METHOD
///       METHOD_DECLARATION
///       METHOD_DECLARATION_STATIC
///       METHOD_STATIC
///       MIXIN
///       PARAMETER
///       SETTER_DECLARATION
///       TOP_LEVEL_VARIABLE
///       PARAMETER_DECLARATION
///       PARAMETER_REFERENCE
///       STATIC_FIELD_DECLARATION
///       STATIC_GETTER_DECLARATION
///       STATIC_GETTER_REFERENCE
///       STATIC_METHOD_DECLARATION
///       STATIC_METHOD_REFERENCE
///       STATIC_METHOD_TEAR_OFF
///       STATIC_SETTER_DECLARATION
///       STATIC_SETTER_REFERENCE
///       TOP_LEVEL_FUNCTION_DECLARATION
///       TOP_LEVEL_FUNCTION_REFERENCE
///       TOP_LEVEL_FUNCTION_TEAR_OFF
///       TOP_LEVEL_GETTER_DECLARATION
///       TOP_LEVEL_GETTER_REFERENCE
///       TOP_LEVEL_SETTER_DECLARATION
///       TOP_LEVEL_SETTER_REFERENCE
///       TOP_LEVEL_VARIABLE_DECLARATION
///       TYPE_ALIAS
///       TYPE_NAME_DYNAMIC
///       TYPE_PARAMETER
///       UNRESOLVED_INSTANCE_MEMBER_REFERENCE
///       VALID_STRING_ESCAPE
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum HighlightRegionType {
  ANNOTATION,

  /// Deprecated - no longer sent, KEYWORD used instead.
  BUILT_IN,

  CLASS,

  COMMENT_BLOCK,

  COMMENT_DOCUMENTATION,

  COMMENT_END_OF_LINE,

  CONSTRUCTOR,

  CONSTRUCTOR_TEAR_OFF,

  DIRECTIVE,

  /// Deprecated - no longer sent.
  DYNAMIC_TYPE,

  DYNAMIC_LOCAL_VARIABLE_DECLARATION,

  DYNAMIC_LOCAL_VARIABLE_REFERENCE,

  DYNAMIC_PARAMETER_DECLARATION,

  DYNAMIC_PARAMETER_REFERENCE,

  ENUM,

  ENUM_CONSTANT,

  EXTENSION,

  EXTENSION_TYPE,

  /// Deprecated - no longer sent.
  FIELD,

  /// Deprecated - no longer sent.
  FIELD_STATIC,

  /// Deprecated - no longer sent.
  FUNCTION,

  /// Deprecated - no longer sent.
  FUNCTION_DECLARATION,

  FUNCTION_TYPE_ALIAS,

  /// Deprecated - no longer sent.
  GETTER_DECLARATION,

  IDENTIFIER_DEFAULT,

  IMPORT_PREFIX,

  INSTANCE_FIELD_DECLARATION,

  INSTANCE_FIELD_REFERENCE,

  INSTANCE_GETTER_DECLARATION,

  INSTANCE_GETTER_REFERENCE,

  INSTANCE_METHOD_DECLARATION,

  INSTANCE_METHOD_REFERENCE,

  INSTANCE_METHOD_TEAR_OFF,

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

  LITERAL_RECORD,

  LITERAL_STRING,

  LOCAL_FUNCTION_DECLARATION,

  LOCAL_FUNCTION_REFERENCE,

  LOCAL_FUNCTION_TEAR_OFF,

  /// Deprecated - no longer sent.
  LOCAL_VARIABLE,

  LOCAL_VARIABLE_DECLARATION,

  LOCAL_VARIABLE_REFERENCE,

  /// Deprecated - no longer sent.
  METHOD,

  /// Deprecated - no longer sent.
  METHOD_DECLARATION,

  /// Deprecated - no longer sent.
  METHOD_DECLARATION_STATIC,

  /// Deprecated - no longer sent.
  METHOD_STATIC,

  MIXIN,

  /// Deprecated - no longer sent.
  PARAMETER,

  /// Deprecated - no longer sent.
  SETTER_DECLARATION,

  /// Deprecated - no longer sent.
  TOP_LEVEL_VARIABLE,

  PARAMETER_DECLARATION,

  PARAMETER_REFERENCE,

  STATIC_FIELD_DECLARATION,

  STATIC_GETTER_DECLARATION,

  STATIC_GETTER_REFERENCE,

  STATIC_METHOD_DECLARATION,

  STATIC_METHOD_REFERENCE,

  STATIC_METHOD_TEAR_OFF,

  STATIC_SETTER_DECLARATION,

  STATIC_SETTER_REFERENCE,

  TOP_LEVEL_FUNCTION_DECLARATION,

  TOP_LEVEL_FUNCTION_REFERENCE,

  TOP_LEVEL_FUNCTION_TEAR_OFF,

  TOP_LEVEL_GETTER_DECLARATION,

  TOP_LEVEL_GETTER_REFERENCE,

  TOP_LEVEL_SETTER_DECLARATION,

  TOP_LEVEL_SETTER_REFERENCE,

  TOP_LEVEL_VARIABLE_DECLARATION,

  TYPE_ALIAS,

  TYPE_NAME_DYNAMIC,

  TYPE_PARAMETER,

  UNRESOLVED_INSTANCE_MEMBER_REFERENCE,

  VALID_STRING_ESCAPE;

  factory HighlightRegionType.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'HighlightRegionType'", json);
  }

  @override
  String toString() => 'HighlightRegionType.$name';

  String toJson() => name;
}

/// LinkedEditGroup
///
///     {
///       "positions": List<Position>
///       "length": int
///       "suggestions": List<LinkedEditSuggestion>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class LinkedEditGroup implements HasToJson {
  /// The positions of the regions (after applying the relevant edits) that
  /// should be edited simultaneously.
  List<Position> positions;

  /// The length of the regions that should be edited simultaneously.
  int length;

  /// Pre-computed suggestions for what every region might want to be changed
  /// to.
  List<LinkedEditSuggestion> suggestions;

  LinkedEditGroup(this.positions, this.length, this.suggestions);

  factory LinkedEditGroup.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'LinkedEditGroup'", json);
    }
    List<Position> positions;
    if (json case {'positions': var encodedPositions}) {
      positions = jsonDecoder.decodeList(
        '$jsonPath.positions',
        encodedPositions,
        (String jsonPath, Object? json) =>
            Position.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'positions'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    List<LinkedEditSuggestion> suggestions;
    if (json case {'suggestions': var encodedSuggestions}) {
      suggestions = jsonDecoder.decodeList(
        '$jsonPath.suggestions',
        encodedSuggestions,
        (String jsonPath, Object? json) =>
            LinkedEditSuggestion.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'suggestions'", json);
    }
    return LinkedEditGroup(positions, length, suggestions);
  }

  /// Construct an empty LinkedEditGroup.
  LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['positions'] = positions
        .map((Position value) => value.toJson())
        .toList();
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
            positions,
            other.positions,
            (Position a, Position b) => a == b,
          ) &&
          length == other.length &&
          listEqual(
            suggestions,
            other.suggestions,
            (LinkedEditSuggestion a, LinkedEditSuggestion b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(positions),
    length,
    Object.hashAll(suggestions),
  );
}

/// LinkedEditSuggestion
///
///     {
///       "value": String
///       "kind": LinkedEditSuggestionKind
///     }
///
/// Clients may not extend, implement or mix-in this class.
class LinkedEditSuggestion implements HasToJson {
  /// The value that could be used to replace all of the linked edit regions.
  String value;

  /// The kind of value being proposed.
  LinkedEditSuggestionKind kind;

  LinkedEditSuggestion(this.value, this.kind);

  factory LinkedEditSuggestion.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'LinkedEditSuggestion'", json);
    }
    String value;
    if (json case {'value': var encodedValue}) {
      value = jsonDecoder.decodeString('$jsonPath.value', encodedValue);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'value'", json);
    }
    LinkedEditSuggestionKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = LinkedEditSuggestionKind.fromJson(
        jsonDecoder,
        '$jsonPath.kind',
        encodedKind,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    return LinkedEditSuggestion(value, kind);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(value, kind);
}

/// LinkedEditSuggestionKind
///
///     enum {
///       METHOD
///       PARAMETER
///       TYPE
///       VARIABLE
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum LinkedEditSuggestionKind {
  METHOD,

  PARAMETER,

  TYPE,

  VARIABLE;

  factory LinkedEditSuggestionKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'LinkedEditSuggestionKind'", json);
  }

  @override
  String toString() => 'LinkedEditSuggestionKind.$name';

  String toJson() => name;
}

/// Location
///
///     {
///       "file": FilePath
///       "offset": int
///       "length": int
///       "startLine": int
///       "startColumn": int
///       "endLine": optional int
///       "endColumn": optional int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class Location implements HasToJson {
  /// The file containing the range.
  String file;

  /// The offset of the range.
  int offset;

  /// The length of the range.
  int length;

  /// The one-based index of the line containing the first character of the
  /// range.
  int startLine;

  /// The one-based index of the column containing the first character of the
  /// range.
  int startColumn;

  /// The one-based index of the line containing the character immediately
  /// following the range.
  int? endLine;

  /// The one-based index of the column containing the character immediately
  /// following the range.
  int? endColumn;

  Location(
    this.file,
    this.offset,
    this.length,
    this.startLine,
    this.startColumn, {
    this.endLine,
    this.endColumn,
  });

  factory Location.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'Location'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file = jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    int startLine;
    if (json case {'startLine': var encodedStartLine}) {
      startLine = jsonDecoder.decodeInt(
        '$jsonPath.startLine',
        encodedStartLine,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'startLine'", json);
    }
    int startColumn;
    if (json case {'startColumn': var encodedStartColumn}) {
      startColumn = jsonDecoder.decodeInt(
        '$jsonPath.startColumn',
        encodedStartColumn,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'startColumn'", json);
    }
    int? endLine;
    if (json case {'endLine': var encodedEndLine}) {
      endLine = jsonDecoder.decodeInt('$jsonPath.endLine', encodedEndLine);
    }
    int? endColumn;
    if (json case {'endColumn': var encodedEndColumn}) {
      endColumn = jsonDecoder.decodeInt(
        '$jsonPath.endColumn',
        encodedEndColumn,
      );
    }
    return Location(
      file,
      offset,
      length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['startLine'] = startLine;
    result['startColumn'] = startColumn;
    if (endLine case var endLine?) {
      result['endLine'] = endLine;
    }
    if (endColumn case var endColumn?) {
      result['endColumn'] = endColumn;
    }
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
          startColumn == other.startColumn &&
          endLine == other.endLine &&
          endColumn == other.endColumn;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    file,
    offset,
    length,
    startLine,
    startColumn,
    endLine,
    endColumn,
  );
}

/// NavigationRegion
///
///     {
///       "offset": int
///       "length": int
///       "targets": List<int>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class NavigationRegion implements HasToJson {
  /// The offset of the region from which the user can navigate.
  int offset;

  /// The length of the region from which the user can navigate.
  int length;

  /// The indexes of the targets (in the enclosing navigation response) to
  /// which the given region is bound. By opening the target, clients can
  /// implement one form of navigation. This list cannot be empty.
  List<int> targets;

  NavigationRegion(this.offset, this.length, this.targets);

  factory NavigationRegion.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'NavigationRegion'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    List<int> targets;
    if (json case {'targets': var encodedTargets}) {
      targets = jsonDecoder.decodeList(
        '$jsonPath.targets',
        encodedTargets,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'targets'", json);
    }
    return NavigationRegion(offset, length, targets);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(offset, length, Object.hashAll(targets));
}

/// NavigationTarget
///
///     {
///       "kind": ElementKind
///       "fileIndex": int
///       "offset": int
///       "length": int
///       "startLine": int
///       "startColumn": int
///       "codeOffset": optional int
///       "codeLength": optional int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class NavigationTarget implements HasToJson {
  /// The kind of the element.
  ElementKind kind;

  /// The index of the file (in the enclosing navigation response) to navigate
  /// to.
  int fileIndex;

  /// The offset of the name of the target to which the user can navigate.
  int offset;

  /// The length of the name of the target to which the user can navigate.
  int length;

  /// The one-based index of the line containing the first character of the
  /// name of the target.
  int startLine;

  /// The one-based index of the column containing the first character of the
  /// name of the target.
  int startColumn;

  /// The offset of the target code to which the user can navigate.
  int? codeOffset;

  /// The length of the target code to which the user can navigate.
  int? codeLength;

  NavigationTarget(
    this.kind,
    this.fileIndex,
    this.offset,
    this.length,
    this.startLine,
    this.startColumn, {
    this.codeOffset,
    this.codeLength,
  });

  factory NavigationTarget.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'NavigationTarget'", json);
    }
    ElementKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = ElementKind.fromJson(jsonDecoder, '$jsonPath.kind', encodedKind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    int fileIndex;
    if (json case {'fileIndex': var encodedFileIndex}) {
      fileIndex = jsonDecoder.decodeInt(
        '$jsonPath.fileIndex',
        encodedFileIndex,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'fileIndex'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    int startLine;
    if (json case {'startLine': var encodedStartLine}) {
      startLine = jsonDecoder.decodeInt(
        '$jsonPath.startLine',
        encodedStartLine,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'startLine'", json);
    }
    int startColumn;
    if (json case {'startColumn': var encodedStartColumn}) {
      startColumn = jsonDecoder.decodeInt(
        '$jsonPath.startColumn',
        encodedStartColumn,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'startColumn'", json);
    }
    int? codeOffset;
    if (json case {'codeOffset': var encodedCodeOffset}) {
      codeOffset = jsonDecoder.decodeInt(
        '$jsonPath.codeOffset',
        encodedCodeOffset,
      );
    }
    int? codeLength;
    if (json case {'codeLength': var encodedCodeLength}) {
      codeLength = jsonDecoder.decodeInt(
        '$jsonPath.codeLength',
        encodedCodeLength,
      );
    }
    return NavigationTarget(
      kind,
      fileIndex,
      offset,
      length,
      startLine,
      startColumn,
      codeOffset: codeOffset,
      codeLength: codeLength,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['fileIndex'] = fileIndex;
    result['offset'] = offset;
    result['length'] = length;
    result['startLine'] = startLine;
    result['startColumn'] = startColumn;
    if (codeOffset case var codeOffset?) {
      result['codeOffset'] = codeOffset;
    }
    if (codeLength case var codeLength?) {
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
  int get hashCode => Object.hash(
    kind,
    fileIndex,
    offset,
    length,
    startLine,
    startColumn,
    codeOffset,
    codeLength,
  );
}

/// Occurrences
///
///     {
///       "element": Element
///       "offsets": List<int>
///       "length": int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class Occurrences implements HasToJson {
  /// The element that was referenced.
  Element element;

  /// The offsets of the name of the referenced element within the file.
  List<int> offsets;

  /// The length of the name of the referenced element.
  int length;

  Occurrences(this.element, this.offsets, this.length);

  factory Occurrences.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'Occurrences'", json);
    }
    Element element;
    if (json case {'element': var encodedElement}) {
      element = Element.fromJson(
        jsonDecoder,
        '$jsonPath.element',
        encodedElement,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'element'", json);
    }
    List<int> offsets;
    if (json case {'offsets': var encodedOffsets}) {
      offsets = jsonDecoder.decodeList(
        '$jsonPath.offsets',
        encodedOffsets,
        jsonDecoder.decodeInt,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offsets'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    return Occurrences(element, offsets, length);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(element, Object.hashAll(offsets), length);
}

/// Outline
///
///     {
///       "element": Element
///       "offset": int
///       "length": int
///       "codeOffset": int
///       "codeLength": int
///       "children": optional List<Outline>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class Outline implements HasToJson {
  /// A description of the element represented by this node.
  Element element;

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  int offset;

  /// The length of the element.
  int length;

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  int codeOffset;

  /// The length of the element code.
  int codeLength;

  /// The children of the node. The field will be omitted if the node has no
  /// children. Children are sorted by offset.
  List<Outline>? children;

  Outline(
    this.element,
    this.offset,
    this.length,
    this.codeOffset,
    this.codeLength, {
    this.children,
  });

  factory Outline.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'Outline'", json);
    }
    Element element;
    if (json case {'element': var encodedElement}) {
      element = Element.fromJson(
        jsonDecoder,
        '$jsonPath.element',
        encodedElement,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'element'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    int codeOffset;
    if (json case {'codeOffset': var encodedCodeOffset}) {
      codeOffset = jsonDecoder.decodeInt(
        '$jsonPath.codeOffset',
        encodedCodeOffset,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'codeOffset'", json);
    }
    int codeLength;
    if (json case {'codeLength': var encodedCodeLength}) {
      codeLength = jsonDecoder.decodeInt(
        '$jsonPath.codeLength',
        encodedCodeLength,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'codeLength'", json);
    }
    List<Outline>? children;
    if (json case {'children': var encodedChildren}) {
      children = jsonDecoder.decodeList(
        '$jsonPath.children',
        encodedChildren,
        (String jsonPath, Object? json) =>
            Outline.fromJson(jsonDecoder, jsonPath, json),
      );
    }
    return Outline(
      element,
      offset,
      length,
      codeOffset,
      codeLength,
      children: children,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['element'] = element.toJson();
    result['offset'] = offset;
    result['length'] = length;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    if (children case var children?) {
      result['children'] = children
          .map((Outline value) => value.toJson())
          .toList();
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
  int get hashCode => Object.hash(
    element,
    offset,
    length,
    codeOffset,
    codeLength,
    Object.hashAll(children ?? []),
  );
}

/// ParameterInfo
///
///     {
///       "kind": ParameterKind
///       "name": String
///       "type": String
///       "defaultValue": optional String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class ParameterInfo implements HasToJson {
  /// The kind of the parameter.
  ParameterKind kind;

  /// The name of the parameter.
  String name;

  /// The type of the parameter.
  String type;

  /// The default value for this parameter. This value will be omitted if the
  /// parameter does not have a default value.
  String? defaultValue;

  ParameterInfo(this.kind, this.name, this.type, {this.defaultValue});

  factory ParameterInfo.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'ParameterInfo'", json);
    }
    ParameterKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = ParameterKind.fromJson(jsonDecoder, '$jsonPath.kind', encodedKind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    String type;
    if (json case {'type': var encodedType}) {
      type = jsonDecoder.decodeString('$jsonPath.type', encodedType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'type'", json);
    }
    String? defaultValue;
    if (json case {'defaultValue': var encodedDefaultValue}) {
      defaultValue = jsonDecoder.decodeString(
        '$jsonPath.defaultValue',
        encodedDefaultValue,
      );
    }
    return ParameterInfo(kind, name, type, defaultValue: defaultValue);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['kind'] = kind.toJson();
    result['name'] = name;
    result['type'] = type;
    if (defaultValue case var defaultValue?) {
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
  int get hashCode => Object.hash(kind, name, type, defaultValue);
}

/// ParameterKind
///
///     enum {
///       OPTIONAL_NAMED
///       OPTIONAL_POSITIONAL
///       REQUIRED_NAMED
///       REQUIRED_POSITIONAL
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum ParameterKind {
  /// An optional named parameter.
  OPTIONAL_NAMED,

  /// An optional positional parameter.
  OPTIONAL_POSITIONAL,

  /// A required named parameter.
  REQUIRED_NAMED,

  /// A required positional parameter.
  REQUIRED_POSITIONAL;

  factory ParameterKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'ParameterKind'", json);
  }

  @override
  String toString() => 'ParameterKind.$name';

  String toJson() => name;
}

/// PluginDetails
///
///     {
///       "name": String
///       "lintRules": List<String>
///       "warningRules": List<String>
///       "assists": List<AssistDescription>
///       "fixes": List<FixDescription>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginDetails implements HasToJson {
  /// The name of the plugin.
  String name;

  /// A list of the IDs of the analysis rules which have been registered as
  /// lint rules.
  List<String> lintRules;

  /// A list of the IDs of the analysis rules which have been registered as
  /// warning rules.
  List<String> warningRules;

  /// A list of the descriptions of registered assists.
  List<AssistDescription> assists;

  /// A list of the descriptions of registered fixes.
  List<FixDescription> fixes;

  PluginDetails(
    this.name,
    this.lintRules,
    this.warningRules,
    this.assists,
    this.fixes,
  );

  factory PluginDetails.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'PluginDetails'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    List<String> lintRules;
    if (json case {'lintRules': var encodedLintRules}) {
      lintRules = jsonDecoder.decodeList(
        '$jsonPath.lintRules',
        encodedLintRules,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'lintRules'", json);
    }
    List<String> warningRules;
    if (json case {'warningRules': var encodedWarningRules}) {
      warningRules = jsonDecoder.decodeList(
        '$jsonPath.warningRules',
        encodedWarningRules,
        jsonDecoder.decodeString,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'warningRules'", json);
    }
    List<AssistDescription> assists;
    if (json case {'assists': var encodedAssists}) {
      assists = jsonDecoder.decodeList(
        '$jsonPath.assists',
        encodedAssists,
        (String jsonPath, Object? json) =>
            AssistDescription.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'assists'", json);
    }
    List<FixDescription> fixes;
    if (json case {'fixes': var encodedFixes}) {
      fixes = jsonDecoder.decodeList(
        '$jsonPath.fixes',
        encodedFixes,
        (String jsonPath, Object? json) =>
            FixDescription.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'fixes'", json);
    }
    return PluginDetails(name, lintRules, warningRules, assists, fixes);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['name'] = name;
    result['lintRules'] = lintRules;
    result['warningRules'] = warningRules;
    result['assists'] = assists
        .map((AssistDescription value) => value.toJson())
        .toList();
    result['fixes'] = fixes
        .map((FixDescription value) => value.toJson())
        .toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PluginDetails) {
      return name == other.name &&
          listEqual(
            lintRules,
            other.lintRules,
            (String a, String b) => a == b,
          ) &&
          listEqual(
            warningRules,
            other.warningRules,
            (String a, String b) => a == b,
          ) &&
          listEqual(
            assists,
            other.assists,
            (AssistDescription a, AssistDescription b) => a == b,
          ) &&
          listEqual(
            fixes,
            other.fixes,
            (FixDescription a, FixDescription b) => a == b,
          );
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAll(lintRules),
    Object.hashAll(warningRules),
    Object.hashAll(assists),
    Object.hashAll(fixes),
  );
}

/// PluginPrint
///
///     {
///       "pluginName": String
///       "message": String
///       "timestamp": int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class PluginPrint implements HasToJson {
  /// The name of the plugin which called 'print'.
  String pluginName;

  /// The message which has been printed.
  String message;

  /// The timestamp, in milliseconds since the epoch, of when the message was
  /// requested to be printed.
  int timestamp;

  PluginPrint(this.pluginName, this.message, this.timestamp);

  factory PluginPrint.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'PluginPrint'", json);
    }
    String pluginName;
    if (json case {'pluginName': var encodedPluginName}) {
      pluginName = jsonDecoder.decodeString(
        '$jsonPath.pluginName',
        encodedPluginName,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'pluginName'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    int timestamp;
    if (json case {'timestamp': var encodedTimestamp}) {
      timestamp = jsonDecoder.decodeInt(
        '$jsonPath.timestamp',
        encodedTimestamp,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'timestamp'", json);
    }
    return PluginPrint(pluginName, message, timestamp);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['pluginName'] = pluginName;
    result['message'] = message;
    result['timestamp'] = timestamp;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PluginPrint) {
      return pluginName == other.pluginName &&
          message == other.message &&
          timestamp == other.timestamp;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(pluginName, message, timestamp);
}

/// Position
///
///     {
///       "file": FilePath
///       "offset": int
///     }
///
/// Clients may not extend, implement or mix-in this class.
class Position implements HasToJson {
  /// The file containing the position.
  String file;

  /// The offset of the position.
  int offset;

  Position(this.file, this.offset);

  factory Position.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'Position'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file = jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    return Position(file, offset);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => Object.hash(file, offset);
}

/// RefactoringKind
///
///     enum {
///       CONVERT_GETTER_TO_METHOD
///       CONVERT_METHOD_TO_GETTER
///       EXTRACT_LOCAL_VARIABLE
///       EXTRACT_METHOD
///       EXTRACT_WIDGET
///       INLINE_LOCAL_VARIABLE
///       INLINE_METHOD
///       MOVE_FILE
///       RENAME
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum RefactoringKind {
  CONVERT_GETTER_TO_METHOD,

  CONVERT_METHOD_TO_GETTER,

  EXTRACT_LOCAL_VARIABLE,

  EXTRACT_METHOD,

  EXTRACT_WIDGET,

  INLINE_LOCAL_VARIABLE,

  INLINE_METHOD,

  MOVE_FILE,

  RENAME;

  factory RefactoringKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'RefactoringKind'", json);
  }

  @override
  String toString() => 'RefactoringKind.$name';

  String toJson() => name;
}

/// RefactoringMethodParameter
///
///     {
///       "id": optional String
///       "kind": RefactoringMethodParameterKind
///       "type": String
///       "name": String
///       "parameters": optional String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringMethodParameter implements HasToJson {
  /// The unique identifier of the parameter. Clients may omit this field for
  /// the parameters they want to add.
  String? id;

  /// The kind of the parameter.
  RefactoringMethodParameterKind kind;

  /// The type that should be given to the parameter, or the return type of the
  /// parameter's function type.
  String type;

  /// The name that should be given to the parameter.
  String name;

  /// The parameter list of the parameter's function type. If the parameter is
  /// not of a function type, this field will not be defined. If the function
  /// type has zero parameters, this field will have a value of '()'.
  String? parameters;

  RefactoringMethodParameter(
    this.kind,
    this.type,
    this.name, {
    this.id,
    this.parameters,
  });

  factory RefactoringMethodParameter.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(
        jsonPath,
        "'RefactoringMethodParameter'",
        json,
      );
    }
    String? id;
    if (json case {'id': var encodedId}) {
      id = jsonDecoder.decodeString('$jsonPath.id', encodedId);
    }
    RefactoringMethodParameterKind kind;
    if (json case {'kind': var encodedKind}) {
      kind = RefactoringMethodParameterKind.fromJson(
        jsonDecoder,
        '$jsonPath.kind',
        encodedKind,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'kind'", json);
    }
    String type;
    if (json case {'type': var encodedType}) {
      type = jsonDecoder.decodeString('$jsonPath.type', encodedType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'type'", json);
    }
    String name;
    if (json case {'name': var encodedName}) {
      name = jsonDecoder.decodeString('$jsonPath.name', encodedName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'name'", json);
    }
    String? parameters;
    if (json case {'parameters': var encodedParameters}) {
      parameters = jsonDecoder.decodeString(
        '$jsonPath.parameters',
        encodedParameters,
      );
    }
    return RefactoringMethodParameter(
      kind,
      type,
      name,
      id: id,
      parameters: parameters,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    if (id case var id?) {
      result['id'] = id;
    }
    result['kind'] = kind.toJson();
    result['type'] = type;
    result['name'] = name;
    if (parameters case var parameters?) {
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
  int get hashCode => Object.hash(id, kind, type, name, parameters);
}

/// RefactoringMethodParameterKind
///
///     enum {
///       REQUIRED
///       POSITIONAL
///       NAMED
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum RefactoringMethodParameterKind {
  REQUIRED,

  POSITIONAL,

  NAMED;

  factory RefactoringMethodParameterKind.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
      jsonPath,
      "'RefactoringMethodParameterKind'",
      json,
    );
  }

  @override
  String toString() => 'RefactoringMethodParameterKind.$name';

  String toJson() => name;
}

/// RefactoringProblem
///
///     {
///       "severity": RefactoringProblemSeverity
///       "message": String
///       "location": optional Location
///     }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringProblem implements HasToJson {
  /// The severity of the problem being represented.
  RefactoringProblemSeverity severity;

  /// A human-readable description of the problem being represented.
  String message;

  /// The location of the problem being represented. This field is omitted
  /// unless there is a specific location associated with the problem (such as
  /// a location where an element being renamed will be shadowed).
  Location? location;

  RefactoringProblem(this.severity, this.message, {this.location});

  factory RefactoringProblem.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'RefactoringProblem'", json);
    }
    RefactoringProblemSeverity severity;
    if (json case {'severity': var encodedSeverity}) {
      severity = RefactoringProblemSeverity.fromJson(
        jsonDecoder,
        '$jsonPath.severity',
        encodedSeverity,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'severity'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    Location? location;
    if (json case {'location': var encodedLocation}) {
      location = Location.fromJson(
        jsonDecoder,
        '$jsonPath.location',
        encodedLocation,
      );
    }
    return RefactoringProblem(severity, message, location: location);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['severity'] = severity.toJson();
    result['message'] = message;
    if (location case var location?) {
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
  int get hashCode => Object.hash(severity, message, location);
}

/// RefactoringProblemSeverity
///
///     enum {
///       INFO
///       WARNING
///       ERROR
///       FATAL
///     }
///
/// Clients may not extend, implement or mix-in this class.
enum RefactoringProblemSeverity {
  /// A minor code problem. No example, because it is not used yet.
  INFO,

  /// A minor code problem. For example names of local variables should be
  /// camel case and start with a lower case letter. Staring the name of a
  /// variable with an upper case is OK from the language point of view, but it
  /// is nice to warn the user.
  WARNING,

  /// The refactoring technically can be performed, but there is a logical
  /// problem. For example the name of a local variable being extracted
  /// conflicts with another name in the scope, or duplicate parameter names in
  /// the method being extracted, or a conflict between a parameter name and a
  /// local variable, etc. In some cases the location of the problem is also
  /// provided, so the IDE can show user the location and the problem, and let
  /// the user decide whether they want to perform the refactoring. For example
  /// the name conflict might be expected, and the user wants to fix it
  /// afterwards.
  ERROR,

  /// A fatal error, which prevents performing the refactoring. For example the
  /// name of a local variable being extracted is not a valid identifier, or
  /// selection is not a valid expression.
  FATAL;

  factory RefactoringProblemSeverity.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    if (json is String) {
      try {
        return values.byName(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "'RefactoringProblemSeverity'", json);
  }

  /// Returns the [RefactoringProblemSeverity] with the maximal severity.
  static RefactoringProblemSeverity? max(
    RefactoringProblemSeverity? a,
    RefactoringProblemSeverity? b,
  ) => maxRefactoringProblemSeverity(a, b);

  @override
  String toString() => 'RefactoringProblemSeverity.$name';

  String toJson() => name;
}

/// RemoveContentOverlay
///
///     {
///       "type": "remove"
///     }
///
/// Clients may not extend, implement or mix-in this class.
class RemoveContentOverlay implements HasToJson {
  RemoveContentOverlay();

  factory RemoveContentOverlay.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'RemoveContentOverlay'", json);
    }
    if (json['type'] != 'remove') {
      throw jsonDecoder.mismatch(jsonPath, "equal to 'remove'", json);
    }
    return RemoveContentOverlay();
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
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
  int get hashCode => 114870849;
}

/// SourceChange
///
///     {
///       "message": String
///       "edits": List<SourceFileEdit>
///       "linkedEditGroups": List<LinkedEditGroup>
///       "selection": optional Position
///       "selectionLength": optional int
///       "id": optional String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class SourceChange implements HasToJson {
  /// A human-readable description of the change to be applied.
  ///
  /// If this change includes multiple edits made for different reasons (such
  /// as during a bulk fix operation), the individual items in `edits` may
  /// contain more specific descriptions.
  String message;

  /// A list of the edits used to effect the change, grouped by file.
  List<SourceFileEdit> edits;

  /// A list of the linked editing groups used to customize the changes that
  /// were made.
  List<LinkedEditGroup> linkedEditGroups;

  /// The position that should be selected after the edits have been applied.
  Position? selection;

  /// The length of the selection (starting at Position) that should be
  /// selected after the edits have been applied.
  int? selectionLength;

  /// The optional identifier of the change kind. The identifier remains stable
  /// even if the message changes, or is parameterized.
  String? id;

  SourceChange(
    this.message, {
    List<SourceFileEdit>? edits,
    List<LinkedEditGroup>? linkedEditGroups,
    this.selection,
    this.selectionLength,
    this.id,
  }) : edits = edits ?? <SourceFileEdit>[],
       linkedEditGroups = linkedEditGroups ?? <LinkedEditGroup>[];

  factory SourceChange.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'SourceChange'", json);
    }
    String message;
    if (json case {'message': var encodedMessage}) {
      message = jsonDecoder.decodeString('$jsonPath.message', encodedMessage);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'message'", json);
    }
    List<SourceFileEdit> edits;
    if (json case {'edits': var encodedEdits}) {
      edits = jsonDecoder.decodeList(
        '$jsonPath.edits',
        encodedEdits,
        (String jsonPath, Object? json) =>
            SourceFileEdit.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'edits'", json);
    }
    List<LinkedEditGroup> linkedEditGroups;
    if (json case {'linkedEditGroups': var encodedLinkedEditGroups}) {
      linkedEditGroups = jsonDecoder.decodeList(
        '$jsonPath.linkedEditGroups',
        encodedLinkedEditGroups,
        (String jsonPath, Object? json) =>
            LinkedEditGroup.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'linkedEditGroups'", json);
    }
    Position? selection;
    if (json case {'selection': var encodedSelection}) {
      selection = Position.fromJson(
        jsonDecoder,
        '$jsonPath.selection',
        encodedSelection,
      );
    }
    int? selectionLength;
    if (json case {'selectionLength': var encodedSelectionLength}) {
      selectionLength = jsonDecoder.decodeInt(
        '$jsonPath.selectionLength',
        encodedSelectionLength,
      );
    }
    String? id;
    if (json case {'id': var encodedId}) {
      id = jsonDecoder.decodeString('$jsonPath.id', encodedId);
    }
    return SourceChange(
      message,
      edits: edits,
      linkedEditGroups: linkedEditGroups,
      selection: selection,
      selectionLength: selectionLength,
      id: id,
    );
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['message'] = message;
    result['edits'] = edits
        .map((SourceFileEdit value) => value.toJson())
        .toList();
    result['linkedEditGroups'] = linkedEditGroups
        .map((LinkedEditGroup value) => value.toJson())
        .toList();
    if (selection case var selection?) {
      result['selection'] = selection.toJson();
    }
    if (selectionLength case var selectionLength?) {
      result['selectionLength'] = selectionLength;
    }
    if (id case var id?) {
      result['id'] = id;
    }
    return result;
  }

  /// Adds [edit] to the [FileEdit] for the given [file].
  ///
  /// If [insertBeforeExisting] is `true`, inserts made at the same offset as
  /// other edits will be inserted such that they appear before them in the
  /// resulting document.
  void addEdit(
    String file,
    int fileStamp,
    SourceEdit edit, {
    bool insertBeforeExisting = false,
  }) => addEditToSourceChange(
    this,
    file,
    fileStamp,
    edit,
    insertBeforeExisting: insertBeforeExisting,
  );

  /// Adds the given [FileEdit].
  void addFileEdit(SourceFileEdit edit) {
    edits.add(edit);
  }

  /// Adds the given [LinkedEditGroup].
  void addLinkedEditGroup(LinkedEditGroup linkedEditGroup) {
    linkedEditGroups.add(linkedEditGroup);
  }

  /// Returns the [FileEdit] for the given [file], maybe `null`.
  SourceFileEdit? getFileEdit(String file) => getChangeFileEdit(this, file);

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SourceChange) {
      return message == other.message &&
          listEqual(
            edits,
            other.edits,
            (SourceFileEdit a, SourceFileEdit b) => a == b,
          ) &&
          listEqual(
            linkedEditGroups,
            other.linkedEditGroups,
            (LinkedEditGroup a, LinkedEditGroup b) => a == b,
          ) &&
          selection == other.selection &&
          selectionLength == other.selectionLength &&
          id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
    message,
    Object.hashAll(edits),
    Object.hashAll(linkedEditGroups),
    selection,
    selectionLength,
    id,
  );
}

/// SourceEdit
///
///     {
///       "offset": int
///       "length": int
///       "replacement": String
///       "id": optional String
///       "description": optional String
///     }
///
/// Clients may not extend, implement or mix-in this class.
class SourceEdit implements HasToJson {
  /// Get the result of applying a set of [edits] to the given [code]. Edits
  /// are applied in the order they appear in [edits].
  static String applySequence(String code, List<SourceEdit> edits) =>
      applySequenceOfEdits(code, edits);

  /// The offset of the region to be modified.
  int offset;

  /// The length of the region to be modified.
  int length;

  /// The code that is to replace the specified region in the original code.
  String replacement;

  /// An identifier that uniquely identifies this source edit from other edits
  /// in the same response. This field is omitted unless a containing structure
  /// needs to be able to identify the edit for some reason.
  ///
  /// For example, some refactoring operations can produce edits that might not
  /// be appropriate (referred to as potential edits). Such edits will have an
  /// id so that they can be referenced. Edits in the same response that do not
  /// need to be referenced will not have an id.
  String? id;

  /// A human readable description of the change made by this edit.
  ///
  /// This description should be short and suitable to use as a heading with
  /// changes grouped by it. For example, a change made as part of a quick-fix
  /// may use the message "Replace final with var", allowing multiple changes
  /// and multiple applications of the fix to be grouped together.
  ///
  /// This value may be more specific than any value in an enclosing
  /// `SourceChange.message` which could contain edits made for different
  /// reasons (such as during a bulk fix operation).
  String? description;

  SourceEdit(
    this.offset,
    this.length,
    this.replacement, {
    this.id,
    this.description,
  });

  factory SourceEdit.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'SourceEdit'", json);
    }
    int offset;
    if (json case {'offset': var encodedOffset}) {
      offset = jsonDecoder.decodeInt('$jsonPath.offset', encodedOffset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'offset'", json);
    }
    int length;
    if (json case {'length': var encodedLength}) {
      length = jsonDecoder.decodeInt('$jsonPath.length', encodedLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'length'", json);
    }
    String replacement;
    if (json case {'replacement': var encodedReplacement}) {
      replacement = jsonDecoder.decodeString(
        '$jsonPath.replacement',
        encodedReplacement,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'replacement'", json);
    }
    String? id;
    if (json case {'id': var encodedId}) {
      id = jsonDecoder.decodeString('$jsonPath.id', encodedId);
    }
    String? description;
    if (json case {'description': var encodedDescription}) {
      description = jsonDecoder.decodeString(
        '$jsonPath.description',
        encodedDescription,
      );
    }
    return SourceEdit(
      offset,
      length,
      replacement,
      id: id,
      description: description,
    );
  }

  /// The end of the region to be modified.
  int get end => offset + length;

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['offset'] = offset;
    result['length'] = length;
    result['replacement'] = replacement;
    if (id case var id?) {
      result['id'] = id;
    }
    if (description case var description?) {
      result['description'] = description;
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
          id == other.id &&
          description == other.description;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(offset, length, replacement, id, description);
}

/// SourceFileEdit
///
///     {
///       "file": FilePath
///       "fileStamp": long
///       "edits": List<SourceEdit>
///     }
///
/// Clients may not extend, implement or mix-in this class.
class SourceFileEdit implements HasToJson {
  /// The file containing the code to be modified.
  String file;

  /// The modification stamp of the file at the moment when the change was
  /// created, in milliseconds since the "Unix epoch". Will be -1 if the file
  /// did not exist and should be created. The client may use this field to
  /// make sure that the file was not changed since then, so it is safe to
  /// apply the change.
  int fileStamp;

  /// A list of the edits used to effect the change.
  List<SourceEdit> edits;

  SourceFileEdit(this.file, this.fileStamp, {List<SourceEdit>? edits})
    : edits = edits ?? QueueList<SourceEdit>();

  factory SourceFileEdit.fromJson(
    JsonDecoder jsonDecoder,
    String jsonPath,
    Object? json,
  ) {
    json ??= {};
    if (json is! Map) {
      throw jsonDecoder.mismatch(jsonPath, "'SourceFileEdit'", json);
    }
    String file;
    if (json case {'file': var encodedFile}) {
      file = jsonDecoder.decodeString('$jsonPath.file', encodedFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'file'", json);
    }
    int fileStamp;
    if (json case {'fileStamp': var encodedFileStamp}) {
      fileStamp = jsonDecoder.decodeInt(
        '$jsonPath.fileStamp',
        encodedFileStamp,
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'fileStamp'", json);
    }
    List<SourceEdit> edits;
    if (json case {'edits': var encodedEdits}) {
      edits = jsonDecoder.decodeList(
        '$jsonPath.edits',
        encodedEdits,
        (String jsonPath, Object? json) =>
            SourceEdit.fromJson(jsonDecoder, jsonPath, json),
      );
    } else {
      throw jsonDecoder.mismatch(jsonPath, "'edits'", json);
    }
    return SourceFileEdit(file, fileStamp, edits: edits);
  }

  @override
  Map<String, Object> toJson() {
    var result = <String, Object>{};
    result['file'] = file;
    result['fileStamp'] = fileStamp;
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  /// Adds the given [Edit] to the list.
  ///
  /// If [insertBeforeExisting] is `true`, inserts made at the same offset as
  /// other edits will be inserted such that they appear before them in the
  /// resulting document.
  void add(SourceEdit edit, {bool insertBeforeExisting = false}) =>
      addEditForSource(this, edit, insertBeforeExisting: insertBeforeExisting);

  /// Adds the given [Edit]s.
  ///
  /// If [insertBeforeExisting] is `true`, inserts made at the same offset as
  /// other edits will be inserted such that they appear before them in the
  /// resulting document.
  void addAll(
    Iterable<SourceEdit> edits, {
    bool insertBeforeExisting = false,
  }) => addAllEditsForSource(
    this,
    edits,
    insertBeforeExisting: insertBeforeExisting,
  );

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
  int get hashCode => Object.hash(file, fileStamp, Object.hashAll(edits));
}
