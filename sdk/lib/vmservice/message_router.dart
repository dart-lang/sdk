// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

abstract class MessageRouter {
  Future<Response?> routeRequest(VMService service, Message message);
  void routeResponse(Message message);
}

enum ResponsePayloadKind {
  /// Response payload is a Dart string.
  String,

  /// Response payload is a binary (Uint8List).
  Binary,

  /// Response payload is a string encoded as UTF8 bytes (Uint8List).
  Utf8String,
}

class Response {
  final ResponsePayloadKind kind;
  final payload;

  /// Construct response object with the given [payload] and [kind].
  Response(this.kind, this.payload) {
    assert(() {
      switch (kind) {
        case ResponsePayloadKind.String:
          return payload is String;
        case ResponsePayloadKind.Binary:
        case ResponsePayloadKind.Utf8String:
          return payload is Uint8List;
        default:
          return false;
      }
    }());
  }

  /// Construct a string response from the given [value] by encoding it
  /// as JSON.
  Response.json(Object value)
      : this(ResponsePayloadKind.String, json.encode(value));

  factory Response.internalError(String message) => Response.json({
        'type': 'ServiceError',
        'id': '',
        'kind': 'InternalError',
        'message': message,
      });

  /// Construct response from the response [value] which can be either:
  ///     String: a string
  ///     Binary: a Uint8List
  ///     Utf8String: a single element list containing Uint8List
  factory Response.from(Object value) {
    if (value is String) {
      return Response(ResponsePayloadKind.String, value);
    } else if (value is Uint8List) {
      return Response(ResponsePayloadKind.Binary, value);
    } else if (value is List) {
      assert(value.length == 1);
      return Response(ResponsePayloadKind.Utf8String, value[0] as Uint8List);
    } else if (value is Response) {
      return value;
    } else {
      throw 'Unrecognized response: ${value}';
    }
  }

  /// Decode JSON contained in this response.
  dynamic decodeJson() {
    switch (kind) {
      case ResponsePayloadKind.String:
        return json.decode(payload as String);
      case ResponsePayloadKind.Utf8String:
        return json.fuse(utf8).decode(payload as List<int>);
      case ResponsePayloadKind.Binary:
        throw 'Binary responses can not be decoded';
    }
  }
}
