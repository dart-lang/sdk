// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    show JsonDecoder;

export 'package:analyzer_plugin/src/protocol/protocol_internal.dart'
    show JsonDecoder;

final Map<String, RefactoringKind> REQUEST_ID_REFACTORING_KINDS =
    HashMap<String, RefactoringKind>();

/// Get the result of applying a set of [edits] to the given [code].  Edits
/// are applied in the order they appear in [edits].  Access via
/// SourceEdit.applySequence().
String applySequenceOfEdits(String code, Iterable<SourceEdit> edits) {
  edits.forEach((SourceEdit edit) {
    code = edit.apply(code);
  });
  return code;
}

/// Compare the lists [listA] and [listB], using [itemEqual] to compare
/// list elements.
bool listEqual<T>(
    List<T>? listA, List<T>? listB, bool Function(T a, T b) itemEqual) {
  if (listA == null) {
    return listB == null;
  }
  if (listB == null) {
    return false;
  }
  if (listA.length != listB.length) {
    return false;
  }
  for (var i = 0; i < listA.length; i++) {
    if (!itemEqual(listA[i], listB[i])) {
      return false;
    }
  }
  return true;
}

/// Compare the maps [mapA] and [mapB], using [valueEqual] to compare map
/// values.
bool mapEqual<K, V>(
    Map<K, V>? mapA, Map<K, V>? mapB, bool Function(V a, V b) valueEqual) {
  if (mapA == null) {
    return mapB == null;
  }
  if (mapB == null) {
    return false;
  }
  if (mapA.length != mapB.length) {
    return false;
  }
  for (var entryA in mapA.entries) {
    var key = entryA.key;
    var valueA = entryA.value;
    var valueB = mapB[key];
    if (valueB == null || !valueEqual(valueA, valueB)) {
      return false;
    }
  }
  return true;
}

/// Translate the input [map], applying [keyCallback] to all its keys, and
/// [valueCallback] to all its values.
Map<KR, VR> mapMap<KP, VP, KR, VR>(Map<KP, VP> map,
    {KR Function(KP key)? keyCallback, VR Function(VP value)? valueCallback}) {
  Map<KR, VR> result = HashMap<KR, VR>();
  map.forEach((key, value) {
    KR resultKey;
    VR resultValue;
    if (keyCallback != null) {
      resultKey = keyCallback(key);
    } else {
      resultKey = key as KR;
    }
    if (valueCallback != null) {
      resultValue = valueCallback(value);
    } else {
      resultValue = value as VR;
    }
    result[resultKey] = resultValue;
  });
  return result;
}

/// Create a [RefactoringFeedback] corresponding the given [kind].
RefactoringFeedback? refactoringFeedbackFromJson(
    JsonDecoder jsonDecoder, String jsonPath, Object? json, Map feedbackJson) {
  var kind = jsonDecoder.refactoringKind;
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return ExtractLocalVariableFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return ExtractMethodFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_WIDGET) {
    return ExtractWidgetFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
    return InlineLocalVariableFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_METHOD) {
    return InlineMethodFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return RenameFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}

/// Create a [RefactoringOptions] corresponding the given [kind].
RefactoringOptions? refactoringOptionsFromJson(JsonDecoder jsonDecoder,
    String jsonPath, Object? json, RefactoringKind kind) {
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return ExtractLocalVariableOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return ExtractMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_WIDGET) {
    return ExtractWidgetOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_METHOD) {
    return InlineMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.MOVE_FILE) {
    return MoveFileOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return RenameOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}

/// Instances of the class [HasToJson] implement [toJson] method that returns
/// a JSON presentation.
abstract class HasToJson {
  /// Returns a JSON presentation of the object.
  Map<String, Object> toJson();
}

/// JsonDecoder for decoding requests.  Errors are reporting by throwing a
/// [RequestFailure].
class RequestDecoder extends JsonDecoder {
  /// The request being deserialized.
  final Request _request;

  RequestDecoder(this._request);

  @override
  RefactoringKind? get refactoringKind {
    // Refactoring feedback objects should never appear in requests.
    return null;
  }

  @override
  Object mismatch(String jsonPath, String expected, [Object? actual]) {
    var buffer = StringBuffer();
    buffer.write('Expected to be ');
    buffer.write(expected);
    if (actual != null) {
      buffer.write('; found "');
      buffer.write(json.encode(actual));
      buffer.write('"');
    }
    return RequestFailure(
        Response.invalidParameter(_request, jsonPath, buffer.toString()));
  }

  @override
  Object missingKey(String jsonPath, String key) {
    return RequestFailure(Response.invalidParameter(
        _request, jsonPath, 'Expected to contain key ${json.encode(key)}'));
  }
}

abstract class RequestParams implements HasToJson {
  /// Return a request whose parameters are taken from this object and that has
  /// the given [id].
  Request toRequest(String id);
}

/// JsonDecoder for decoding responses from the server.  This is intended to be
/// used only for testing.  Errors are reported using bare [Exception] objects.
class ResponseDecoder extends JsonDecoder {
  @override
  final RefactoringKind? refactoringKind;

  ResponseDecoder(this.refactoringKind);

  @override
  Object mismatch(String jsonPath, String expected, [Object? actual]) {
    var buffer = StringBuffer();
    buffer.write('Expected ');
    buffer.write(expected);
    if (actual != null) {
      buffer.write(' found "');
      buffer.write(json.encode(actual));
      buffer.write('"');
    }
    buffer.write(' at ');
    buffer.write(jsonPath);
    return Exception(buffer.toString());
  }

  @override
  Object missingKey(String jsonPath, String key) {
    return Exception('Missing key $key at $jsonPath');
  }
}

/// The result data associated with a response.
abstract class ResponseResult implements HasToJson {
  /// Return a response whose result data is this object for the request with
  /// the given [id].
  Response toResponse(String id);
}
