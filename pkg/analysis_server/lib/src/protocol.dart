// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protocol;

import 'dart:collection';
import 'dart:convert';

part 'generated_protocol.dart';

final Map<String, RefactoringKind> REQUEST_ID_REFACTORING_KINDS =
    new HashMap<String, RefactoringKind>();

/**
 * Translate the input [map], applying [keyCallback] to all its keys, and
 * [valueCallback] to all its values.
 */
mapMap(Map map, {dynamic keyCallback(key), dynamic valueCallback(value)}) {
  Map result = {};
  map.forEach((key, value) {
    if (keyCallback != null) {
      key = keyCallback(key);
    }
    if (valueCallback != null) {
      value = valueCallback(value);
    }
    result[key] = value;
  });
  return result;
}

/**
 * Adds the given [sourceEdits] to the list in [sourceFileEdit].
 */
void _addAllEditsForSource(
    SourceFileEdit sourceFileEdit, Iterable<SourceEdit> edits) {
  edits.forEach(sourceFileEdit.add);
}

/**
 * Adds the given [sourceEdit] to the list in [sourceFileEdit].
 */
void _addEditForSource(SourceFileEdit sourceFileEdit, SourceEdit sourceEdit) {
  List<SourceEdit> edits = sourceFileEdit.edits;
  int index = 0;
  while (index < edits.length && edits[index].offset > sourceEdit.offset) {
    index++;
  }
  edits.insert(index, sourceEdit);
}

/**
 * Adds [edit] to the [FileEdit] for the given [file].
 */
void _addEditToSourceChange(
    SourceChange change, String file, int fileStamp, SourceEdit edit) {
  SourceFileEdit fileEdit = change.getFileEdit(file);
  if (fileEdit == null) {
    fileEdit = new SourceFileEdit(file, fileStamp);
    change.addFileEdit(fileEdit);
  }
  fileEdit.add(edit);
}

/**
 * Get the result of applying the edit to the given [code].  Access via
 * SourceEdit.apply().
 */
String _applyEdit(String code, SourceEdit edit) {
  if (edit.length < 0) {
    throw new RangeError('length is negative');
  }
  return code.replaceRange(edit.offset, edit.end, edit.replacement);
}

/**
 * Get the result of applying a set of [edits] to the given [code].  Edits
 * are applied in the order they appear in [edits].  Access via
 * SourceEdit.applySequence().
 */
String _applySequence(String code, Iterable<SourceEdit> edits) {
  edits.forEach((SourceEdit edit) {
    code = edit.apply(code);
  });
  return code;
}

/**
 * Returns the [FileEdit] for the given [file], maybe `null`.
 */
SourceFileEdit _getChangeFileEdit(SourceChange change, String file) {
  for (SourceFileEdit fileEdit in change.edits) {
    if (fileEdit.file == file) {
      return fileEdit;
    }
  }
  return null;
}

/**
 * Compare the lists [listA] and [listB], using [itemEqual] to compare
 * list elements.
 */
bool _listEqual(List listA, List listB, bool itemEqual(a, b)) {
  if (listA == null) {
    return listB == null;
  }
  if (listB == null) {
    return false;
  }
  if (listA.length != listB.length) {
    return false;
  }
  for (int i = 0; i < listA.length; i++) {
    if (!itemEqual(listA[i], listB[i])) {
      return false;
    }
  }
  return true;
}

/**
 * Compare the maps [mapA] and [mapB], using [valueEqual] to compare map
 * values.
 */
bool _mapEqual(Map mapA, Map mapB, bool valueEqual(a, b)) {
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

RefactoringProblemSeverity _maxRefactoringProblemSeverity(
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

/**
 * Create a [RefactoringFeedback] corresponding the given [kind].
 */
RefactoringFeedback _refactoringFeedbackFromJson(
    JsonDecoder jsonDecoder, String jsonPath, Object json, Map feedbackJson) {
  RefactoringKind kind = jsonDecoder.refactoringKind;
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return new ExtractLocalVariableFeedback.fromJson(
        jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return new ExtractMethodFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_LOCAL_VARIABLE) {
    return new InlineLocalVariableFeedback.fromJson(
        jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_METHOD) {
    return new InlineMethodFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return new RenameFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}

/**
 * Create a [RefactoringOptions] corresponding the given [kind].
 */
RefactoringOptions _refactoringOptionsFromJson(JsonDecoder jsonDecoder,
    String jsonPath, Object json, RefactoringKind kind) {
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return new ExtractLocalVariableOptions.fromJson(
        jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return new ExtractMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_METHOD) {
    return new InlineMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.MOVE_FILE) {
    return new MoveFileOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return new RenameOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}

/**
 * Type of callbacks used to decode parts of JSON objects.  [jsonPath] is a
 * string describing the part of the JSON object being decoded, and [value] is
 * the part to decode.
 */
typedef Object JsonDecoderCallback(String jsonPath, Object value);

/**
 * Instances of the class [DomainHandler] implement a [RequestHandler] and
 * also startup and shutdown methods.
 */
abstract class DomainHandler extends RequestHandler {
  /**
   * Perform any operations associated with the shutdown of the domain. It is
   * not guaranteed that this method will be called. If it is, it will be
   * called after the last [Request] has been made.
   */
  void shutdown() {}

  /**
   * Perform any operations associated with the startup of the domain. This
   * will be called before the first [Request].
   */
  void startup() {}
}

/**
 * Classes implementing [Enum] represent enumerated types in the protocol.
 */
abstract class Enum {
  /**
   * The name of the enumerated value.  This should match the name of the
   * static getter which provides access to this enumerated value.
   */
  String get name;
}

/**
 * Instances of the class [HasToJson] implement [toJson] method that returns
 * a JSON presentation.
 */
abstract class HasToJson {
  /**
   * Returns a JSON presentation of the object.
   */
  Map<String, Object> toJson();
}

/**
 * Base class for decoding JSON objects.  The derived class must implement
 * error reporting logic.
 */
abstract class JsonDecoder {
  /**
   * Retrieve the RefactoringKind that should be assumed when decoding
   * refactoring feedback objects, or null if no refactoring feedback object is
   * expected to be encountered.
   */
  RefactoringKind get refactoringKind;

  /**
   * Create an exception to throw if the JSON object at [jsonPath] fails to
   * match the API definition of [expected].
   */
  dynamic mismatch(String jsonPath, String expected, [Object actual]);

  /**
   * Create an exception to throw if the JSON object at [jsonPath] is missing
   * the key [key].
   */
  dynamic missingKey(String jsonPath, String key);

  /**
   * Decode a JSON object that is expected to be a boolean.  The strings "true"
   * and "false" are also accepted.
   */
  bool _decodeBool(String jsonPath, Object json) {
    if (json is bool) {
      return json;
    } else if (json == 'true') {
      return true;
    } else if (json == 'false') {
      return false;
    }
    throw mismatch(jsonPath, 'bool', json);
  }

  /**
   * Decode a JSON object that is expected to be an integer.  A string
   * representation of an integer is also accepted.
   */
  int _decodeInt(String jsonPath, Object json) {
    if (json is int) {
      return json;
    } else if (json is String) {
      return int.parse(json, onError: (String value) {
        throw mismatch(jsonPath, 'int', json);
      });
    }
    throw mismatch(jsonPath, 'int', json);
  }

  /**
   * Decode a JSON object that is expected to be a List.  [decoder] is used to
   * decode the items in the list.
   */
  List _decodeList(String jsonPath, Object json,
      [JsonDecoderCallback decoder]) {
    if (json == null) {
      return [];
    } else if (json is List) {
      List result = [];
      for (int i = 0; i < json.length; i++) {
        result.add(decoder('$jsonPath[$i]', json[i]));
      }
      return result;
    } else {
      throw mismatch(jsonPath, 'List', json);
    }
  }

  /**
   * Decode a JSON object that is expected to be a Map.  [keyDecoder] is used
   * to decode the keys, and [valueDecoder] is used to decode the values.
   */
  Map _decodeMap(String jsonPath, Object json,
      {JsonDecoderCallback keyDecoder, JsonDecoderCallback valueDecoder}) {
    if (json == null) {
      return {};
    } else if (json is Map) {
      Map result = {};
      json.forEach((String key, value) {
        Object decodedKey;
        if (keyDecoder != null) {
          decodedKey = keyDecoder('$jsonPath.key', key);
        } else {
          decodedKey = key;
        }
        if (valueDecoder != null) {
          value = valueDecoder('$jsonPath[${JSON.encode(key)}]', value);
        }
        result[decodedKey] = value;
      });
      return result;
    } else {
      throw mismatch(jsonPath, 'Map', json);
    }
  }

  /**
   * Decode a JSON object that is expected to be a string.
   */
  String _decodeString(String jsonPath, Object json) {
    if (json is String) {
      return json;
    } else {
      throw mismatch(jsonPath, 'String', json);
    }
  }

  /**
   * Decode a JSON object that is expected to be one of several choices,
   * where the choices are disambiguated by the contents of the field [field].
   * [decoders] is a map from each possible string in the field to the decoder
   * that should be used to decode the JSON object.
   */
  Object _decodeUnion(String jsonPath, Map json, String field,
      Map<String, JsonDecoderCallback> decoders) {
    if (json is Map) {
      if (!json.containsKey(field)) {
        throw missingKey(jsonPath, field);
      }
      var disambiguatorPath = '$jsonPath[${JSON.encode(field)}]';
      String disambiguator = _decodeString(disambiguatorPath, json[field]);
      if (!decoders.containsKey(disambiguator)) {
        throw mismatch(
            disambiguatorPath, 'One of: ${decoders.keys.toList()}', json);
      }
      return decoders[disambiguator](jsonPath, json);
    } else {
      throw mismatch(jsonPath, 'Map', json);
    }
  }
}

/**
 * Instances of the class [Notification] represent a notification from the
 * server about an event that occurred.
 */
class Notification {
  /**
   * The name of the JSON attribute containing the name of the event that
   * triggered the notification.
   */
  static const String EVENT = 'event';

  /**
   * The name of the JSON attribute containing the result values.
   */
  static const String PARAMS = 'params';

  /**
   * The name of the event that triggered the notification.
   */
  final String event;

  /**
   * A table mapping the names of notification parameters to their values, or
   * null if there are no notification parameters.
   */
  Map<String, Object> _params;

  /**
   * Initialize a newly created [Notification] to have the given [event] name.
   * If [_params] is provided, it will be used as the params; otherwise no
   * params will be used.
   */
  Notification(this.event, [this._params]);

  /**
   * Initialize a newly created instance based upon the given JSON data
   */
  factory Notification.fromJson(Map<String, Object> json) {
    return new Notification(
        json[Notification.EVENT], json[Notification.PARAMS]);
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = {};
    jsonObject[EVENT] = event;
    if (_params != null) {
      jsonObject[PARAMS] = _params;
    }
    return jsonObject;
  }
}

/**
 * Instances of the class [Request] represent a request that was received.
 */
class Request {
  /**
   * The name of the JSON attribute containing the id of the request.
   */
  static const String ID = 'id';

  /**
   * The name of the JSON attribute containing the name of the request.
   */
  static const String METHOD = 'method';

  /**
   * The name of the JSON attribute containing the request parameters.
   */
  static const String PARAMS = 'params';

  /**
   * The name of the optional JSON attribute indicating the time
   * (milliseconds since epoch) at which the client made the request.
   */
  static const String CLIENT_REQUEST_TIME = 'clientRequestTime';

  /**
   * The unique identifier used to identify this request.
   */
  final String id;

  /**
   * The method being requested.
   */
  final String method;

  /**
   * A table mapping the names of request parameters to their values.
   */
  final Map<String, Object> _params;

  /**
   * The time (milliseconds since epoch) at which the client made the request
   * or `null` if this information is not provided by the client.
   */
  final int clientRequestTime;

  /**
   * Initialize a newly created [Request] to have the given [id] and [method]
   * name.  If [params] is supplied, it is used as the "params" map for the
   * request.  Otherwise an empty "params" map is allocated.
   */
  Request(this.id, this.method,
      [Map<String, Object> params, this.clientRequestTime])
      : _params = params != null ? params : new HashMap<String, Object>();

  /**
   * Return a request parsed from the given json, or `null` if the [data] is
   * not a valid json representation of a request. The [data] is expected to
   * have the following format:
   *
   *   {
   *     'clientRequestTime': millisecondsSinceEpoch
   *     'id': String,
   *     'method': methodName,
   *     'params': {
   *       paramter_name: value
   *     }
   *   }
   *
   * where both the parameters and clientRequestTime are optional.
   * The parameters can contain any number of name/value pairs.
   * The clientRequestTime must be an int representing the time at which
   * the client issued the request (milliseconds since epoch).
   */
  factory Request.fromJson(Map<String, dynamic> result) {
    var id = result[Request.ID];
    var method = result[Request.METHOD];
    if (id is! String || method is! String) {
      return null;
    }
    var time = result[Request.CLIENT_REQUEST_TIME];
    if (time != null && time is! int) {
      return null;
    }
    var params = result[Request.PARAMS];
    if (params is Map || params == null) {
      return new Request(id, method, params, time);
    } else {
      return null;
    }
  }

  /**
   * Return a request parsed from the given [data], or `null` if the [data] is
   * not a valid json representation of a request. The [data] is expected to
   * have the following format:
   *
   *   {
   *     'clientRequestTime': millisecondsSinceEpoch
   *     'id': String,
   *     'method': methodName,
   *     'params': {
   *       paramter_name: value
   *     }
   *   }
   *
   * where both the parameters and clientRequestTime are optional.
   * The parameters can contain any number of name/value pairs.
   * The clientRequestTime must be an int representing the time at which
   * the client issued the request (milliseconds since epoch).
   */
  factory Request.fromString(String data) {
    try {
      var result = JSON.decode(data);
      if (result is Map) {
        return new Request.fromJson(result);
      }
      return null;
    } catch (exception) {
      return null;
    }
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = new HashMap<String, Object>();
    jsonObject[ID] = id;
    jsonObject[METHOD] = method;
    if (_params.isNotEmpty) {
      jsonObject[PARAMS] = _params;
    }
    if (clientRequestTime != null) {
      jsonObject[CLIENT_REQUEST_TIME] = clientRequestTime;
    }
    return jsonObject;
  }
}

/**
 * JsonDecoder for decoding requests.  Errors are reporting by throwing a
 * [RequestFailure].
 */
class RequestDecoder extends JsonDecoder {
  /**
   * The request being deserialized.
   */
  final Request _request;

  RequestDecoder(this._request);

  RefactoringKind get refactoringKind {
    // Refactoring feedback objects should never appear in requests.
    return null;
  }

  @override
  dynamic mismatch(String jsonPath, String expected, [Object actual]) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Expected to be ');
    buffer.write(expected);
    if (actual != null) {
      buffer.write('; found "');
      buffer.write(JSON.encode(actual));
      buffer.write('"');
    }
    return new RequestFailure(
        new Response.invalidParameter(_request, jsonPath, buffer.toString()));
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new RequestFailure(new Response.invalidParameter(
        _request, jsonPath, 'Expected to contain key ${JSON.encode(key)}'));
  }
}

/**
 * Instances of the class [RequestFailure] represent an exception that occurred
 * during the handling of a request that requires that an error be returned to
 * the client.
 */
class RequestFailure implements Exception {
  /**
   * The response to be returned as a result of the failure.
   */
  final Response response;

  /**
   * Initialize a newly created exception to return the given reponse.
   */
  RequestFailure(this.response);
}

/**
 * Instances of the class [RequestHandler] implement a handler that can handle
 * requests and produce responses for them.
 */
abstract class RequestHandler {
  /**
   * Attempt to handle the given [request]. If the request is not recognized by
   * this handler, return `null` so that other handlers will be given a chance
   * to handle it. Otherwise, return the response that should be passed back to
   * the client.
   */
  Response handleRequest(Request request);
}

/**
 * Instances of the class [Response] represent a response to a request.
 */
class Response {
  /**
   * The [Response] instance that is returned when a real [Response] cannot
   * be provided at the moment.
   */
  static final Response DELAYED_RESPONSE = new Response('DELAYED_RESPONSE');

  /**
   * The name of the JSON attribute containing the id of the request for which
   * this is a response.
   */
  static const String ID = 'id';

  /**
   * The name of the JSON attribute containing the error message.
   */
  static const String ERROR = 'error';

  /**
   * The name of the JSON attribute containing the result values.
   */
  static const String RESULT = 'result';

  /**
   * The unique identifier used to identify the request that this response is
   * associated with.
   */
  final String id;

  /**
   * The error that was caused by attempting to handle the request, or `null` if
   * there was no error.
   */
  final RequestError error;

  /**
   * A table mapping the names of result fields to their values.  Should be
   * null if there is no result to send.
   */
  Map<String, Object> _result;

  /**
   * Initialize a newly created instance to represent a response to a request
   * with the given [id].  If [_result] is provided, it will be used as the
   * result; otherwise an empty result will be used.  If an [error] is provided
   * then the response will represent an error condition.
   */
  Response(this.id, {Map<String, Object> result, this.error})
      : _result = result;

  /**
   * Initialize a newly created instance to represent the
   * FILE_NOT_ANALYZED error condition.
   */
  Response.fileNotAnalyzed(Request request, String file)
      : this(request.id,
            error: new RequestError(RequestErrorCode.FILE_NOT_ANALYZED,
                'File is not analyzed: $file.'));

  /**
   * Initialize a newly created instance to represent the FORMAT_INVALID_FILE
   * error condition.
   */
  Response.formatInvalidFile(Request request)
      : this(request.id,
            error: new RequestError(RequestErrorCode.FORMAT_INVALID_FILE,
                'Error during `edit.format`: invalid file.'));

  /**
   * Initialize a newly created instance to represent the FORMAT_WITH_ERROR
   * error condition.
   */
  Response.formatWithErrors(Request request)
      : this(request.id,
            error: new RequestError(RequestErrorCode.FORMAT_WITH_ERRORS,
                'Error during `edit.format`: source contains syntax errors.'));

  /**
   * Initialize a newly created instance based upon the given JSON data
   */
  factory Response.fromJson(Map<String, Object> json) {
    try {
      Object id = json[Response.ID];
      if (id is! String) {
        return null;
      }
      Object error = json[Response.ERROR];
      RequestError decodedError;
      if (error is Map) {
        decodedError = new RequestError.fromJson(
            new ResponseDecoder(null), '.error', error);
      }
      Object result = json[Response.RESULT];
      Map<String, Object> decodedResult;
      if (result is Map) {
        decodedResult = result;
      }
      return new Response(id, error: decodedError, result: decodedResult);
    } catch (exception) {
      return null;
    }
  }

  /**
   * Initialize a newly created instance to represent the
   * GET_ERRORS_INVALID_FILE error condition.
   */
  Response.getErrorsInvalidFile(Request request)
      : this(request.id,
            error: new RequestError(RequestErrorCode.GET_ERRORS_INVALID_FILE,
                'Error during `analysis.getErrors`: invalid file.'));

  /**
   * Initialize a newly created instance to represent the
   * GET_NAVIGATION_INVALID_FILE error condition.
   */
  Response.getNavigationInvalidFile(Request request)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.GET_NAVIGATION_INVALID_FILE,
                'Error during `analysis.getNavigation`: invalid file.'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by an analysis.reanalyze [request] that specifies an analysis root that is
   * not in the current list of analysis roots.
   */
  Response.invalidAnalysisRoot(Request request, String rootPath)
      : this(request.id,
            error: new RequestError(RequestErrorCode.INVALID_ANALYSIS_ROOT,
                "Invalid analysis root: $rootPath"));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] that specifies an execution context whose context root does
   * not exist.
   */
  Response.invalidExecutionContext(Request request, String contextId)
      : this(request.id,
            error: new RequestError(RequestErrorCode.INVALID_EXECUTION_CONTEXT,
                "Invalid execution context: $contextId"));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] that had invalid parameter.  [path] is the path to the
   * invalid parameter, in Javascript notation (e.g. "foo.bar" means that the
   * parameter "foo" contained a key "bar" whose value was the wrong type).
   * [expectation] is a description of the type of data that was expected.
   */
  Response.invalidParameter(Request request, String path, String expectation)
      : this(request.id,
            error: new RequestError(RequestErrorCode.INVALID_PARAMETER,
                "Invalid parameter '$path'. $expectation."));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a malformed request.
   */
  Response.invalidRequestFormat()
      : this('',
            error: new RequestError(
                RequestErrorCode.INVALID_REQUEST, 'Invalid request'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a request that requires an index, but indexing is disabled.
   */
  Response.noIndexGenerated(Request request)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.NO_INDEX_GENERATED, 'Indexing is disabled'));

  /**
   * Initialize a newly created instance to represent the
   * ORGANIZE_DIRECTIVES_ERROR error condition.
   */
  Response.organizeDirectivesError(Request request, String message)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.ORGANIZE_DIRECTIVES_ERROR, message));

  /**
   * Initialize a newly created instance to represent the
   * REFACTORING_REQUEST_CANCELLED error condition.
   */
  Response.refactoringRequestCancelled(Request request)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.REFACTORING_REQUEST_CANCELLED,
                'The `edit.getRefactoring` request was cancelled.'));

  /**
   * Initialize a newly created instance to represent the SERVER_ERROR error
   * condition.
   */
  factory Response.serverError(Request request, exception, stackTrace) {
    RequestError error =
        new RequestError(RequestErrorCode.SERVER_ERROR, exception.toString());
    if (stackTrace != null) {
      error.stackTrace = stackTrace.toString();
    }
    return new Response(request.id, error: error);
  }

  /**
   * Initialize a newly created instance to represent the
   * SORT_MEMBERS_INVALID_FILE error condition.
   */
  Response.sortMembersInvalidFile(Request request)
      : this(request.id,
            error: new RequestError(RequestErrorCode.SORT_MEMBERS_INVALID_FILE,
                'Error during `edit.sortMembers`: invalid file.'));

  /**
   * Initialize a newly created instance to represent the
   * SORT_MEMBERS_PARSE_ERRORS error condition.
   */
  Response.sortMembersParseErrors(Request request, int numErrors)
      : this(request.id,
            error: new RequestError(RequestErrorCode.SORT_MEMBERS_PARSE_ERRORS,
                'Error during `edit.sortMembers`: file has $numErrors scan/parse errors.'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a `analysis.setPriorityFiles` [request] that includes one or more files
   * that are not being analyzed.
   */
  Response.unanalyzedPriorityFiles(String requestId, String fileNames)
      : this(requestId,
            error: new RequestError(RequestErrorCode.UNANALYZED_PRIORITY_FILES,
                "Unanalyzed files cannot be a priority: '$fileNames'"));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] that cannot be handled by any known handlers.
   */
  Response.unknownRequest(Request request)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.UNKNOWN_REQUEST, 'Unknown request'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] referencing a source that does not exist.
   */
  Response.unknownSource(Request request)
      : this(request.id,
            error: new RequestError(
                RequestErrorCode.UNKNOWN_SOURCE, 'Unknown source'));

  Response.unsupportedFeature(String requestId, String message)
      : this(requestId,
            error: new RequestError(
                RequestErrorCode.UNSUPPORTED_FEATURE, message));

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = new HashMap<String, Object>();
    jsonObject[ID] = id;
    if (error != null) {
      jsonObject[ERROR] = error.toJson();
    }
    if (_result != null) {
      jsonObject[RESULT] = _result;
    }
    return jsonObject;
  }
}

/**
 * JsonDecoder for decoding responses from the server.  This is intended to be
 * used only for testing.  Errors are reported using bare [Exception] objects.
 */
class ResponseDecoder extends JsonDecoder {
  final RefactoringKind refactoringKind;

  ResponseDecoder(this.refactoringKind);

  @override
  dynamic mismatch(String jsonPath, String expected, [Object actual]) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Expected ');
    buffer.write(expected);
    if (actual != null) {
      buffer.write(' found "');
      buffer.write(JSON.encode(actual));
      buffer.write('"');
    }
    buffer.write(' at ');
    buffer.write(jsonPath);
    return new Exception(buffer.toString());
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new Exception('Missing key $key at $jsonPath');
  }
}

/**
 * Jenkins hash function, optimized for small integers.  Borrowed from
 * sdk/lib/math/jenkins_smi_hash.dart.
 *
 * TODO(paulberry): Move to somewhere that can be shared with other code.
 */
class _JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(a, b) => finish(combine(combine(0, a), b));

  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
