// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

/**
 * An interface for enumerated types in the protocol.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Enum {
  /**
   * The name of the enumerated value. This should match the name of the static
   * getter which provides access to this enumerated value.
   */
  String get name;
}

/**
 * A notification that can be sent to the server about an event that occurred.
 *
 * Clients may not extend, implement or mix-in this class.
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
   * `null` if there are no notification parameters.
   */
  final Map<String, Object> params;

  /**
   * Initialize a newly created [Notification] to have the given [event] name.
   * If [params] is provided, it will be used as the params; otherwise no
   * params will be used.
   */
  Notification(this.event, [this.params]);

  /**
   * Initialize a newly created instance based on the given JSON data.
   */
  factory Notification.fromJson(Map json) {
    return new Notification(json[Notification.EVENT],
        json[Notification.PARAMS] as Map<String, Object>);
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = {};
    jsonObject[EVENT] = event;
    if (params != null) {
      jsonObject[PARAMS] = params;
    }
    return jsonObject;
  }
}

/**
 * A request that was received from the server.
 *
 * Clients may not extend, implement or mix-in this class.
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
   * The name of the optional JSON attribute indicating the time (milliseconds
   * since epoch) at which the server made the request.
   */
  static const String SERVER_REQUEST_TIME = 'serverRequestTime';

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
  final Map<String, Object> params;

  /**
   * The time (milliseconds since epoch) at which the server made the request,
   * or `null` if this information is not provided by the server.
   */
  final int serverRequestTime;

  /**
   * Initialize a newly created [Request] to have the given [id] and [method]
   * name. If [params] is supplied, it is used as the "params" map for the
   * request. Otherwise an empty "params" map is allocated.
   */
  Request(this.id, this.method,
      [Map<String, Object> params, this.serverRequestTime])
      : params = params ?? <String, Object>{};

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
   *
   * The parameters can contain any number of name/value pairs. The
   * clientRequestTime must be an int representing the time at which the client
   * issued the request (milliseconds since epoch).
   */
  factory Request.fromJson(Map<String, Object> result) {
    var id = result[Request.ID];
    var method = result[Request.METHOD];
    if (id is! String || method is! String) {
      return null;
    }
    var time = result[Request.SERVER_REQUEST_TIME];
    if (time != null && time is! int) {
      return null;
    }
    var params = result[Request.PARAMS];
    if (params is Map || params == null) {
      return new Request(id, method, params as Map<String, Object>, time);
    } else {
      return null;
    }
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is Request &&
        id == other.id &&
        method == other.method &&
        serverRequestTime == other.serverRequestTime &&
        _equalMaps(params, other.params);
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the server to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = <String, Object>{};
    jsonObject[ID] = id;
    jsonObject[METHOD] = method;
    if (params.isNotEmpty) {
      jsonObject[PARAMS] = params;
    }
    if (serverRequestTime != null) {
      jsonObject[SERVER_REQUEST_TIME] = serverRequestTime;
    }
    return jsonObject;
  }

  bool _equalLists(List first, List second) {
    if (first == null) {
      return second == null;
    }
    if (second == null) {
      return false;
    }
    int length = first.length;
    if (length != second.length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (!_equalObjects(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  bool _equalMaps(Map first, Map second) {
    if (first == null) {
      return second == null;
    }
    if (second == null) {
      return false;
    }
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

  bool _equalObjects(Object first, Object second) {
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
}

/**
 * A collection of utility methods that create instances of the generated class
 * [RequestError].
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RequestErrorFactory {
  /**
   * Return a request error representing an error condition caused by a
   * [request] that had an invalid edit object.
   */
  static RequestError invalidOverlayChangeInvalidEdit() => new RequestError(
      RequestErrorCode.INVALID_OVERLAY_CHANGE,
      'Invalid overlay change: invalid edit');

  /**
   * Return a request error representing an error condition caused by a
   * [request] that attempted to change an existing overlay when no overlay
   * existed.
   */
  static RequestError invalidOverlayChangeNoContent() => new RequestError(
      RequestErrorCode.INVALID_OVERLAY_CHANGE,
      'Invalid overlay change: no content to change');

  /**
   * Return a request error representing an error condition caused by a request
   * that had an invalid parameter. The [path] is the path to the invalid
   * parameter, in Javascript notation (e.g. "foo.bar" means that the parameter
   * "foo" contained a key "bar" whose value was the wrong type). The
   * [expectation] is a description of the type of data that was expected.
   */
  static RequestError invalidParameter(String path, String expectation) =>
      new RequestError(RequestErrorCode.INVALID_PARAMETER,
          "Invalid parameter '$path'. $expectation.");

  /**
   * Return a request error representing an error that occurred in the plugin.
   */
  static RequestError pluginError(exception, String stackTrace) =>
      new RequestError(RequestErrorCode.PLUGIN_ERROR, exception.toString(),
          stackTrace: stackTrace);

  /**
   * Return a request error representing an error condition caused by a request
   * with the given [method] that cannot be handled by any known handlers.
   */
  static RequestError unknownRequest(String method) => new RequestError(
      RequestErrorCode.UNKNOWN_REQUEST, 'Unknown request: $method');
}

/**
 * An exception that occurred during the handling of a request that requires
 * that an error be returned to the server.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RequestFailure implements Exception {
  /**
   * A description of the error that was encountered.
   */
  final RequestError error;

  /**
   * Initialize a newly created exception to return a response with the given
   * [error].
   */
  RequestFailure(this.error);
}

/**
 * A response to the server.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Response {
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
   * The name of the JSON attribute containing the time at which the request was
   * handled by the plugin.
   */
  static const String REQUEST_TIME = 'requestTime';

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
   * The time at which the request was handled by the plugin.
   */
  final int requestTime;

  /**
   * A table mapping the names of result fields to their values.  Should be
   * `null` if there is no result to send.
   */
  Map<String, Object> result;

  /**
   * Initialize a newly created instance to represent a response to a request
   * with the given [id].  If [_result] is provided, it will be used as the
   * result; otherwise an empty result will be used.  If an [error] is provided
   * then the response will represent an error condition.
   */
  Response(this.id, this.requestTime, {this.error, Map<String, Object> result})
      : result = result;

  /**
   * Initialize a newly created instance based on the given JSON data.
   */
  factory Response.fromJson(Map json) {
    try {
      Object id = json[ID];
      if (id is! String) {
        return null;
      }
      Object error = json[ERROR];
      RequestError decodedError;
      if (error is Map) {
        decodedError = new RequestError.fromJson(
            new ResponseDecoder(null), '.error', error);
      }
      Object requestTime = json[REQUEST_TIME];
      if (requestTime is! int) {
        return null;
      }
      Object result = json[RESULT];
      Map<String, Object> decodedResult;
      if (result is Map) {
        decodedResult = result as Map<String, Object>;
      }
      return new Response(id, requestTime,
          error: decodedError, result: decodedResult);
    } catch (exception) {
      return null;
    }
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = <String, Object>{};
    jsonObject[ID] = id;
    if (error != null) {
      jsonObject[ERROR] = error.toJson();
    }
    jsonObject[REQUEST_TIME] = requestTime;
    if (result != null) {
      jsonObject[RESULT] = result;
    }
    return jsonObject;
  }
}
