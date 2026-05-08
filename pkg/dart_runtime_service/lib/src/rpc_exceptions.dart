// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

enum RpcException {
  // These error codes must be kept in sync with those in vm/json_stream.h and
  // vmservice.dart.
  invalidParams(code: INVALID_PARAMS, message: 'Invalid parameter.'),
  serverError(code: SERVER_ERROR, message: 'Server error.'),
  methodNotFound(code: METHOD_NOT_FOUND, message: 'Method not found.'),
  internalError(code: INTERNAL_ERROR, message: 'Internal error.'),
  connectionDisposed(code: -32010, message: 'Service connection disposed.'),
  featureDisabled(code: 100, message: 'Feature is disabled.'),
  streamAlreadySubscribed(code: 103, message: 'Stream already subscribed.'),
  streamNotSubscribed(code: 104, message: 'Stream not subscribed.'),
  serviceAlreadyRegistered(code: 111, message: 'Service already registered.'),
  serviceDisappeared(code: 112, message: 'Service has disappeared.'),
  expressionCompilationError(
    code: 113,
    message: 'Expression compilation error.',
  ),
  fileSystemAlreadyExists(code: 1001, message: 'File system already exists.'),
  fileSystemDoesNotExist(code: 1002, message: 'File system does not exist.'),
  fileDoesNotExist(code: 1003, message: 'File does not exist.');

  const RpcException({required this.code, required this.message});

  /// Throws a [json_rpc.RpcException] with [code] and [message].
  Never throwException({Object? data}) => throw toException(data: data);

  /// Throws a [json_rpc.RpcException] with [code] and [message], with [details]
  /// included in the exception's `data` field.
  Never throwExceptionWithDetails({required String details}) =>
      throw toException(data: <String, String>{'details': details});

  /// Builds a [json_rpc.RpcException] with [code] and [message] without
  /// throwing.
  json_rpc.RpcException toException({Object? data}) =>
      json_rpc.RpcException(code, message, data: data);

  /// The JSON-RPC error code.
  final int code;

  /// A human-readable error message.
  final String message;
}
