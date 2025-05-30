// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for client code that needs to interact with the requests, responses
/// and notifications that are part of the analysis server's wire protocol.
library;

import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

export 'package:analyzer_plugin/protocol/protocol.dart' show Enum;

/// A notification that can be sent from the server about an event that
/// occurred.
///
/// Clients may not extend, implement or mix-in this class.
class Notification {
  /// The name of the JSON attribute containing the name of the event that
  /// triggered the notification.
  static const String EVENT = 'event';

  /// The name of the JSON attribute containing the result values.
  static const String PARAMS = 'params';

  /// The name of the event that triggered the notification.
  final String event;

  /// A table mapping the names of notification parameters to their values, or
  /// `null` if there are no notification parameters.
  final Map<String, Object?>? params;

  /// Initialize a newly created [Notification] to have the given [event] name.
  /// If [params] is provided, it will be used as the params; otherwise no
  /// params will be used.
  Notification(this.event, [this.params]);

  /// Initialize a newly created instance based on the given JSON data.
  factory Notification.fromJson(Map<Object?, Object?> json) {
    return Notification(
      json[Notification.EVENT] as String,
      json[Notification.PARAMS] as Map<String, Object?>?,
    );
  }

  /// Return a table representing the structure of the Json object that will be
  /// sent to the client to represent this response.
  Map<String, Object> toJson() {
    var jsonObject = <String, Object>{};
    jsonObject[EVENT] = event;
    var params = this.params;
    if (params != null) {
      jsonObject[PARAMS] = params;
    }
    return jsonObject;
  }
}

/// A request that was received from the client.
///
/// Clients may not extend, implement or mix-in this class.
class Request extends RequestOrResponse {
  /// The name of the JSON attribute containing the id of the request.
  static const String ID = 'id';

  /// The name of the JSON attribute containing the name of the request.
  static const String METHOD = 'method';

  /// The name of the JSON attribute containing the request parameters.
  static const String PARAMS = 'params';

  /// The name of the optional JSON attribute indicating the time (milliseconds
  /// since epoch) at which the client made the request.
  static const String CLIENT_REQUEST_TIME = 'clientRequestTime';

  /// The unique identifier used to identify this request.
  @override
  final String id;

  /// The method being requested.
  final String method;

  /// A table mapping the names of request parameters to their values.
  final Map<String, Object?> params;

  /// The time (milliseconds since epoch) at which the client made the request
  /// or `null` if this information is not provided by the client.
  final int? clientRequestTime;

  /// Initialize a newly created [Request] to have the given [id] and [method]
  /// name. If [params] is supplied, it is used as the "params" map for the
  /// request. Otherwise an empty "params" map is allocated.
  Request(
    this.id,
    this.method, [
    Map<String, Object?>? params,
    this.clientRequestTime,
  ]) : params = params ?? <String, Object?>{};

  @override
  int get hashCode {
    return id.hashCode;
  }

  /// Returns the amount of time (in milliseconds) since the client sent this
  /// request or `null` if the client did not provide [clientRequestTime].
  int? get timeSinceRequest {
    var clientRequestTime = this.clientRequestTime;
    return clientRequestTime != null
        ? DateTime.now().millisecondsSinceEpoch - clientRequestTime
        : null;
  }

  @override
  bool operator ==(Object other) {
    return other is Request &&
        id == other.id &&
        method == other.method &&
        clientRequestTime == other.clientRequestTime &&
        _equalMaps(params, other.params);
  }

  /// Return a table representing the structure of the Json object that will be
  /// sent to the client to represent this response.
  Map<String, Object> toJson() {
    var jsonObject = <String, Object>{};
    jsonObject[ID] = id;
    jsonObject[METHOD] = method;
    if (params.isNotEmpty) {
      jsonObject[PARAMS] = params;
    }
    var clientRequestTime = this.clientRequestTime;
    if (clientRequestTime != null) {
      jsonObject[CLIENT_REQUEST_TIME] = clientRequestTime;
    }
    return jsonObject;
  }

  bool _equalLists(List<Object?> first, List<Object?> second) {
    var length = first.length;
    if (length != second.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (!_equalObjects(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  bool _equalMaps(Map<Object?, Object?> first, Map<Object?, Object?> second) {
    if (first.length != second.length) {
      return false;
    }
    for (var key in first.keys) {
      if (!second.containsKey(key)) {
        return false;
      }
      if (!_equalObjects(first[key], second[key])) {
        return false;
      }
    }
    return true;
  }

  bool _equalObjects(Object? first, Object? second) {
    if (first == null) {
      return second == null;
    }
    if (second == null) {
      return false;
    }
    if (first is Map) {
      if (second is Map) {
        return _equalMaps(first, second);
      }
      return false;
    }
    if (first is List) {
      if (second is List) {
        return _equalLists(first, second);
      }
      return false;
    }
    return first == second;
  }

  /// Return a request parsed from the given json, or `null` if the [data] is
  /// not a valid json representation of a request. The [data] is expected to
  /// have the following format:
  ///
  ///   {
  ///     'clientRequestTime': millisecondsSinceEpoch
  ///     'id': String,
  ///     'method': methodName,
  ///     'params': {
  ///       parameter_name: value
  ///     }
  ///   }
  ///
  /// where both the parameters and clientRequestTime are optional.
  ///
  /// The parameters can contain any number of name/value pairs. The
  /// clientRequestTime must be an int representing the time at which the client
  /// issued the request (milliseconds since epoch).
  static Request? fromJson(Map<String, Object?> result) {
    var id = result[Request.ID];
    var method = result[Request.METHOD];
    if (id is! String || method is! String) {
      return null;
    }
    var time = result[Request.CLIENT_REQUEST_TIME];
    if (time is! int?) {
      return null;
    }
    var params = result[Request.PARAMS];
    if (params is Map<String, Object?>?) {
      return Request(id, method, params, time);
    } else {
      return null;
    }
  }

  /// Return a request parsed from the given [data], or `null` if the [data] is
  /// not a valid json representation of a request. The [data] is expected to
  /// have the following format:
  ///
  ///   {
  ///     'clientRequestTime': millisecondsSinceEpoch
  ///     'id': String,
  ///     'method': methodName,
  ///     'params': {
  ///       parameter_name: value
  ///     }
  ///   }
  ///
  /// where both the parameters and clientRequestTime are optional.
  ///
  /// The parameters can contain any number of name/value pairs. The
  /// clientRequestTime must be an int representing the time at which the client
  /// issued the request (milliseconds since epoch).
  static Request? fromString(String data) {
    try {
      var result = json.decode(data);
      if (result is Map<String, Object?>) {
        return Request.fromJson(result);
      }
      return null;
    } catch (exception) {
      return null;
    }
  }
}

/// An exception that occurred during the handling of a request that requires
/// that an error be returned to the client.
///
/// Clients may not extend, implement or mix-in this class.
class RequestFailure implements Exception {
  /// The response to be returned as a result of the failure.
  final Response response;

  /// Initialize a newly created exception to return the given response.
  RequestFailure(this.response);
}

/// An object that can handle requests and produce responses for them.
///
/// Clients may not extend, implement or mix-in this class.
abstract class RequestHandler {
  /// Attempt to handle the given [request]. If the request is not recognized by
  /// this handler, return `null` so that other handlers will be given a chance
  /// to handle it. Otherwise, return the response that should be passed back to
  /// the client.
  Response? handleRequest(Request request, CancellationToken cancellationToken);
}

/// A request or response that was received from the client.
///
/// Clients may not extend, implement or mix-in this class.
abstract class RequestOrResponse {
  /// The unique identifier associated with this request or response.
  String get id;
}

/// A response to a request.
///
/// Clients may not extend, implement or mix-in this class.
class Response extends RequestOrResponse {
  /// The name of the JSON attribute containing the id of the request for which
  /// this is a response.
  static const String ID = 'id';

  /// The name of the JSON attribute containing the error message.
  static const String ERROR = 'error';

  /// The name of the JSON attribute containing the result values.
  static const String RESULT = 'result';

  /// The unique identifier used to identify the request that this response is
  /// associated with.
  @override
  final String id;

  /// The error that was caused by attempting to handle the request, or `null`
  /// if there was no error.
  final RequestError? error;

  /// A table mapping the names of result fields to their values.  Should be
  /// `null` if there is no result to send.
  Map<String, Object?>? result;

  /// Initialize a newly created instance to represent a response to a request
  /// with the given [id].  If [_result] is provided, it will be used as the
  /// result; otherwise an empty result will be used.  If an [error] is provided
  /// then the response will represent an error condition.
  Response(this.id, {this.result, this.error});

  /// Initialize a newly created instance to represent the CONTENT_MODIFIED
  /// error condition.
  Response.contentModified(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.CONTENT_MODIFIED,
          'File was modified before the operation completed.',
        ),
      );

  /// Create and return the `DEBUG_PORT_COULD_NOT_BE_OPENED` error response.
  Response.debugPortCouldNotBeOpened(Request request, Object? error)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.DEBUG_PORT_COULD_NOT_BE_OPENED,
          '$error',
        ),
      );

  /// Initialize a newly created instance to represent the FILE_NOT_ANALYZED
  /// error condition.
  Response.fileNotAnalyzed(Request request, String file)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.FILE_NOT_ANALYZED,
          'File is not analyzed: $file.',
        ),
      );

  /// Initialize a newly created instance to represent the FORMAT_INVALID_FILE
  /// error condition.
  Response.formatInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.FORMAT_INVALID_FILE,
          'Error during `${request.method}`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the FORMAT_WITH_ERROR
  /// error condition.
  Response.formatWithErrors(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.FORMAT_WITH_ERRORS,
          'Error during `edit.format`: source contains syntax errors.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_ERRORS_INVALID_FILE error condition.
  Response.getErrorsInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_ERRORS_INVALID_FILE,
          'Error during `analysis.getErrors`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_FIXES_INVALID_FILE error condition.
  Response.getFixesInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_FIXES_INVALID_FILE,
          'Error during `edit.getFixes`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_IMPORTED_ELEMENTS_INVALID_FILE error condition.
  Response.getImportedElementsInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_IMPORTED_ELEMENTS_INVALID_FILE,
          'Error during `analysis.getImportedElements`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_NAVIGATION_INVALID_FILE error condition.
  Response.getNavigationInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_NAVIGATION_INVALID_FILE,
          'Error during `analysis.getNavigation`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_REACHABLE_SOURCES_INVALID_FILE error condition.
  Response.getReachableSourcesInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_REACHABLE_SOURCES_INVALID_FILE,
          'Error during `analysis.getReachableSources`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_SIGNATURE_INVALID_FILE error condition.
  Response.getSignatureInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_SIGNATURE_INVALID_FILE,
          'Error during `analysis.getSignature`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_SIGNATURE_INVALID_OFFSET error condition.
  Response.getSignatureInvalidOffset(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_SIGNATURE_INVALID_OFFSET,
          'Error during `analysis.getSignature`: invalid offset.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// GET_SIGNATURE_UNKNOWN_FUNCTION error condition.
  Response.getSignatureUnknownFunction(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.GET_SIGNATURE_UNKNOWN_FUNCTION,
          'Error during `analysis.getSignature`: unknown function.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// IMPORT_ELEMENTS_INVALID_FILE error condition.
  Response.importElementsInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.IMPORT_ELEMENTS_INVALID_FILE,
          'Error during `edit.importElements`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by an analysis.reanalyze [request] that specifies an analysis root that is
  /// not in the current list of analysis roots.
  Response.invalidAnalysisRoot(Request request, String rootPath)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.INVALID_ANALYSIS_ROOT,
          'Invalid analysis root: $rootPath',
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by a [request] that specifies an execution context whose context root does
  /// not exist.
  Response.invalidExecutionContext(Request request, String contextId)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.INVALID_EXECUTION_CONTEXT,
          'Invalid execution context: $contextId',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// INVALID_FILE_PATH_FORMAT error condition.
  Response.invalidFilePathFormat(Request request, Object? path)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.INVALID_FILE_PATH_FORMAT,
          'Invalid file path format: $path',
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by a [request] that had invalid parameter.  [path] is the path to the
  /// invalid parameter, in JavaScript notation (e.g. "foo.bar" means that the
  /// parameter "foo" contained a key "bar" whose value was the wrong type).
  /// [expectation] is a description of the type of data that was expected.
  Response.invalidParameter(Request request, String path, String expectation)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.INVALID_PARAMETER,
          "Invalid parameter '$path'. $expectation.",
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by a malformed request.
  Response.invalidRequestFormat()
    : this(
        '',
        error: RequestError(
          RequestErrorCode.INVALID_REQUEST,
          'Invalid request',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// ORGANIZE_DIRECTIVES_ERROR error condition.
  Response.organizeDirectivesError(Request request, String message)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.ORGANIZE_DIRECTIVES_ERROR,
          message,
        ),
      );

  /// Initialize a newly created instance to represent the
  /// REFACTORING_REQUEST_CANCELLED error condition.
  Response.refactoringRequestCancelled(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.REFACTORING_REQUEST_CANCELLED,
          'The `edit.getRefactoring` request was cancelled.',
        ),
      );

  /// Initialize a newly created instance to represent the SERVER_ERROR error
  /// condition.
  factory Response.serverError(
    Request request,
    Object? exception,
    Object? stackTrace,
  ) {
    var error = RequestError(
      RequestErrorCode.SERVER_ERROR,
      exception.toString(),
    );
    if (stackTrace != null) {
      error.stackTrace = stackTrace.toString();
    }
    return Response(request.id, error: error);
  }

  /// Initialize a newly created instance to represent the
  /// SORT_MEMBERS_INVALID_FILE error condition.
  Response.sortMembersInvalidFile(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.SORT_MEMBERS_INVALID_FILE,
          'Error during `edit.sortMembers`: invalid file.',
        ),
      );

  /// Initialize a newly created instance to represent the
  /// SORT_MEMBERS_PARSE_ERRORS error condition.
  Response.sortMembersParseErrors(Request request, int numErrors)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.SORT_MEMBERS_PARSE_ERRORS,
          'Error during `edit.sortMembers`: file has $numErrors scan/parse errors.',
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by a [request] that cannot be handled by any known handlers.
  Response.unknownRequest(Request request)
    : this(
        request.id,
        error: RequestError(
          RequestErrorCode.UNKNOWN_REQUEST,
          'Unknown request',
        ),
      );

  /// Initialize a newly created instance to represent an error condition caused
  /// by a [request] for a service that is not supported.
  Response.unsupportedFeature(String requestId, String message)
    : this(
        requestId,
        error: RequestError(RequestErrorCode.UNSUPPORTED_FEATURE, message),
      );

  /// Return a table representing the structure of the Json object that will be
  /// sent to the client to represent this response.
  Map<String, Object> toJson() {
    var jsonObject = <String, Object>{};
    jsonObject[ID] = id;
    var error = this.error;
    if (error != null) {
      jsonObject[ERROR] = error.toJson(clientUriConverter: null);
    }
    var result = this.result;
    if (result != null) {
      jsonObject[RESULT] = result;
    }
    return jsonObject;
  }

  /// Initialize a newly created instance based on the given JSON data.
  static Response? fromJson(Map<String, Object?> json) {
    try {
      var id = json[Response.ID];
      if (id is! String) {
        return null;
      }

      RequestError? decodedError;
      var error = json[Response.ERROR];
      if (error is Map) {
        decodedError = RequestError.fromJson(
          ResponseDecoder(null),
          '.error',
          error,
          clientUriConverter: null,
        );
      }

      Map<String, Object?>? decodedResult;
      var result = json[Response.RESULT];
      if (result is Map<String, Object?>) {
        decodedResult = result;
      }

      return Response(id, error: decodedError, result: decodedResult);
    } catch (exception) {
      return null;
    }
  }

  /// Return a response parsed from the given [data], or `null` if the [data] is
  /// not a valid json representation of a response. The [data] is expected to
  /// have the following format:
  ///
  ///   {
  ///     'id': String,
  ///     'result': {
  ///       parameter_name: value
  ///     }
  ///   }
  ///
  /// where the result is optional.
  ///
  /// The result can contain any number of name/value pairs.
  static Response? fromString(String data) {
    try {
      var result = json.decode(data);
      if (result is Map<String, Object?>) {
        return Response.fromJson(result);
      }
      return null;
    } catch (exception) {
      return null;
    }
  }
}
