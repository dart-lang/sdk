// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server_client/src/protocol/protocol_base.dart';
import 'package:analysis_server_client/src/protocol/protocol_common.dart';
import 'package:analysis_server_client/src/protocol/protocol_generated.dart';

final Map<String, RefactoringKind> REQUEST_ID_REFACTORING_KINDS =
    HashMap<String, RefactoringKind>();

/// Adds the given [sourceEdits] to the list in [sourceFileEdit].
void addAllEditsForSource(
    SourceFileEdit sourceFileEdit, Iterable<SourceEdit> edits) {
  edits.forEach(sourceFileEdit.add);
}

/// Adds the given [sourceEdit] to the list in [sourceFileEdit].
void addEditForSource(SourceFileEdit sourceFileEdit, SourceEdit sourceEdit) {
  var edits = sourceFileEdit.edits;
  var index = 0;
  while (index < edits.length && edits[index].offset > sourceEdit.offset) {
    index++;
  }
  edits.insert(index, sourceEdit);
}

/// Adds [edit] to the [FileEdit] for the given [file].
void addEditToSourceChange(
    SourceChange change, String file, int fileStamp, SourceEdit edit) {
  var fileEdit = change.getFileEdit(file);
  if (fileEdit == null) {
    fileEdit = SourceFileEdit(file, fileStamp);
    change.addFileEdit(fileEdit);
  }
  fileEdit.add(edit);
}

/// Get the result of applying the edit to the given [code]. Access via
/// SourceEdit.apply().
String applyEdit(String code, SourceEdit edit) {
  if (edit.length < 0) {
    throw RangeError('length is negative');
  }
  return code.replaceRange(edit.offset, edit.end, edit.replacement);
}

/// Get the result of applying a set of [edits] to the given [code]. Edits
/// are applied in the order they appear in [edits]. Access via
/// SourceEdit.applySequence().
String applySequenceOfEdits(String code, Iterable<SourceEdit> edits) {
  edits.forEach((SourceEdit edit) {
    code = edit.apply(code);
  });
  return code;
}

/// Returns the [FileEdit] for the given [file], maybe `null`.
SourceFileEdit getChangeFileEdit(SourceChange change, String file) {
  for (var fileEdit in change.edits) {
    if (fileEdit.file == file) {
      return fileEdit;
    }
  }
  return null;
}

/// Compare the lists [listA] and [listB], using [itemEqual] to compare
/// list elements.
bool listEqual<T1, T2>(
    List<T1> listA, List<T2> listB, bool Function(T1 a, T2 b) itemEqual) {
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
    Map<K, V> mapA, Map<K, V> mapB, bool Function(V a, V b) valueEqual) {
  if (mapA == null) {
    return mapB == null;
  }
  if (mapB == null) {
    return false;
  }
  if (mapA.length != mapB.length) {
    return false;
  }
  for (var key in mapA.keys) {
    if (!mapB.containsKey(key)) {
      return false;
    }
    if (!valueEqual(mapA[key], mapB[key])) {
      return false;
    }
  }
  return true;
}

/// Translate the input [map], applying [keyCallback] to all its keys, and
/// [valueCallback] to all its values.
Map<KR, VR> mapMap<KP, VP, KR, VR>(Map<KP, VP> map,
    {KR Function(KP key) keyCallback, VR Function(VP value) valueCallback}) {
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

RefactoringProblemSeverity maxRefactoringProblemSeverity(
    RefactoringProblemSeverity a, RefactoringProblemSeverity b) {
  if (b == null) {
    return a;
  }
  if (a == null) {
    return b;
  } else if (a == RefactoringProblemSeverity.INFO) {
    return b;
  } else if (a == RefactoringProblemSeverity.WARNING) {
    if (b == RefactoringProblemSeverity.ERROR ||
        b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  } else if (a == RefactoringProblemSeverity.ERROR) {
    if (b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  }
  return a;
}

/// Create a [RefactoringFeedback] corresponding the given [kind].
RefactoringFeedback refactoringFeedbackFromJson(
    JsonDecoder jsonDecoder, String jsonPath, Object json, Map feedbackJson) {
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
RefactoringOptions refactoringOptionsFromJson(JsonDecoder jsonDecoder,
    String jsonPath, Object json, RefactoringKind kind) {
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

/// Type of callbacks used to decode parts of JSON objects. [jsonPath] is a
/// string describing the part of the JSON object being decoded, and [value] is
/// the part to decode.
typedef JsonDecoderCallback<E> = E Function(String jsonPath, Object value);

/// Instances of the class [HasToJson] implement [toJson] method that returns
/// a JSON presentation.
abstract class HasToJson {
  /// Returns a JSON presentation of the object.
  Map<String, Object> toJson();
}

/// Base class for decoding JSON objects. The derived class must implement
/// error reporting logic.
abstract class JsonDecoder {
  /// Retrieve the RefactoringKind that should be assumed when decoding
  /// refactoring feedback objects, or null if no refactoring feedback object is
  /// expected to be encountered.
  RefactoringKind get refactoringKind;

  /// Decode a JSON object that is expected to be a boolean. The strings "true"
  /// and "false" are also accepted.
  bool decodeBool(String jsonPath, Object json) {
    if (json is bool) {
      return json;
    } else if (json == 'true') {
      return true;
    } else if (json == 'false') {
      return false;
    }
    throw mismatch(jsonPath, 'bool', json);
  }

  /// Decode a JSON object that is expected to be a double. A string
  /// representation of a double is also accepted.
  double decodeDouble(String jsonPath, Object json) {
    if (json is double) {
      return json;
    } else if (json is int) {
      return json.toDouble();
    } else if (json is String) {
      var value = double.tryParse(json);
      if (value == null) {
        throw mismatch(jsonPath, 'double', json);
      }
      return value;
    }
    throw mismatch(jsonPath, 'double', json);
  }

  /// Decode a JSON object that is expected to be an integer. A string
  /// representation of an integer is also accepted.
  int decodeInt(String jsonPath, Object json) {
    if (json is int) {
      return json;
    } else if (json is String) {
      var value = int.tryParse(json);
      if (value == null) {
        throw mismatch(jsonPath, 'int', json);
      }
      return value;
    }
    throw mismatch(jsonPath, 'int', json);
  }

  /// Decode a JSON object that is expected to be a List. The [decoder] is used
  /// to decode the items in the list.
  ///
  /// The type parameter [E] is the expected type of the elements in the list.
  List<E> decodeList<E>(String jsonPath, Object json,
      [JsonDecoderCallback<E> decoder]) {
    if (json == null) {
      return <E>[];
    } else if (json is List) {
      var result = <E>[];
      for (var i = 0; i < json.length; i++) {
        result.add(decoder('$jsonPath[$i]', json[i]));
      }
      return result;
    } else {
      throw mismatch(jsonPath, 'List', json);
    }
  }

  /// Decode a JSON object that is expected to be a Map. [keyDecoder] is used
  /// to decode the keys, and [valueDecoder] is used to decode the values.
  Map<K, V> decodeMap<K, V>(String jsonPath, Object jsonData,
      {JsonDecoderCallback<K> keyDecoder,
      JsonDecoderCallback<V> valueDecoder}) {
    if (jsonData == null) {
      return {};
    } else if (jsonData is Map) {
      var result = <K, V>{};
      jsonData.forEach((key, value) {
        K decodedKey;
        if (keyDecoder != null) {
          decodedKey = keyDecoder('$jsonPath.key', key);
        } else {
          decodedKey = key as K;
        }
        if (valueDecoder != null) {
          value = valueDecoder('$jsonPath[${json.encode(key)}]', value);
        }
        result[decodedKey] = value as V;
      });
      return result;
    } else {
      throw mismatch(jsonPath, 'Map', jsonData);
    }
  }

  /// Decode a JSON object that is expected to be a string.
  String decodeString(String jsonPath, Object json) {
    if (json is String) {
      return json;
    } else {
      throw mismatch(jsonPath, 'String', json);
    }
  }

  /// Decode a JSON object that is expected to be one of several choices,
  /// where the choices are disambiguated by the contents of the field [field].
  /// [decoders] is a map from each possible string in the field to the decoder
  /// that should be used to decode the JSON object.
  Object decodeUnion(String jsonPath, Map jsonData, String field,
      Map<String, JsonDecoderCallback> decoders) {
    if (jsonData is Map) {
      if (!jsonData.containsKey(field)) {
        throw missingKey(jsonPath, field);
      }
      var disambiguatorPath = '$jsonPath[${json.encode(field)}]';
      var disambiguator = decodeString(disambiguatorPath, jsonData[field]);
      if (!decoders.containsKey(disambiguator)) {
        throw mismatch(
            disambiguatorPath, 'One of: ${decoders.keys.toList()}', jsonData);
      }
      return decoders[disambiguator](jsonPath, jsonData);
    } else {
      throw mismatch(jsonPath, 'Map', jsonData);
    }
  }

  /// Create an exception to throw if the JSON object at [jsonPath] fails to
  /// match the API definition of [expected].
  dynamic mismatch(String jsonPath, String expected, [Object actual]);

  /// Create an exception to throw if the JSON object at [jsonPath] is missing
  /// the key [key].
  dynamic missingKey(String jsonPath, String key);
}

/// JsonDecoder for decoding requests. Errors are reporting by throwing a
/// [RequestFailure].
class RequestDecoder extends JsonDecoder {
  /// The request being deserialized.
  final Request _request;

  RequestDecoder(this._request);

  @override
  RefactoringKind get refactoringKind {
    // Refactoring feedback objects should never appear in requests.
    return null;
  }

  @override
  dynamic mismatch(String jsonPath, String expected, [Object actual]) {
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
  dynamic missingKey(String jsonPath, String key) {
    return RequestFailure(Response.invalidParameter(
        _request, jsonPath, 'Expected to contain key ${json.encode(key)}'));
  }
}

abstract class RequestParams implements HasToJson {
  /// Return a request whose parameters are taken from this object and that has
  /// the given [id].
  Request toRequest(String id);
}

/// JsonDecoder for decoding responses from the server. This is intended to be
/// used only for testing. Errors are reported using bare [Exception] objects.
class ResponseDecoder extends JsonDecoder {
  @override
  final RefactoringKind refactoringKind;

  ResponseDecoder(this.refactoringKind);

  @override
  dynamic mismatch(String jsonPath, String expected, [Object actual]) {
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
  dynamic missingKey(String jsonPath, String key) {
    return Exception('Missing key $key at $jsonPath');
  }
}

/// The result data associated with a response.
abstract class ResponseResult implements HasToJson {
  /// Return a response whose result data is this object for the request with the
  /// given [id].
  Response toResponse(String id);
}
