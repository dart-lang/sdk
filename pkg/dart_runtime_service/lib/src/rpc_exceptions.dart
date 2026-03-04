// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

enum RpcException {
  // These error codes must be kept in sync with those in vm/json_stream.h and
  // vmservice.dart.
  serverError(code: SERVER_ERROR, message: 'Server error'),
  methodNotFound(code: METHOD_NOT_FOUND, message: 'Method not found'),
  connectionDisposed(code: -32010, message: 'Service connection disposed.'),
  featureDisabled(code: 100, message: 'Feature is disabled.'),
  streamAlreadySubscribed(code: 103, message: 'Stream already subscribed.'),
  streamNotSubscribed(code: 104, message: 'Stream not subscribed.'),
  serviceAlreadyRegistered(code: 111, message: 'Service already registered.'),
  serviceDisappeared(code: 112, message: 'Service has disappeared.');

  const RpcException({required this.code, required this.message});

  /// Throws a [json_rpc.RpcException] with [code] and [message].
  Never throwException() => throw json_rpc.RpcException(code, message);

  /// The JSON-RPC error code.
  final int code;

  /// A human-readable error message.
  final String message;
}
