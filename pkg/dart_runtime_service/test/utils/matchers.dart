// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/src/dart_runtime_service.dart';
import 'package:dart_runtime_service/src/exceptions.dart';
import 'package:dart_runtime_service/src/rpc_exceptions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

/// Verifies that [service] requires an authentication code for clients to
/// connect.
void expectAuthenticationCodesEnabled(DartRuntimeService service) {
  expect(service.authCode, isNotNull);
  expect(service.uri.path, endsWith(service.authCode!));
}

/// Verifies that [service] does not require an authentication code for clients
/// to connect.
void expectAuthenticationCodesDisabled(DartRuntimeService service) {
  expect(service.authCode, isNull);
  expect(service.uri.pathSegments, isEmpty);
}

/// Matches exception thrown when `WebSocket.connect` fails due to the
/// underlying HTTP connection not being upgraded to a web socket.
final Matcher throwsConnectionNotUpgradedToWebSocket = throwsA(
  isA<WebSocketException>().having(
    (e) => e.message,
    'message',
    matches(RegExp("^Connection to '.*' was not upgraded to websocket\$")),
  ),
);

/// Matches exception thrown when the [DartRuntimeService] fails to start for
/// any reason.
final Matcher throwsFailedToStartException = throwsA(
  isA<DartRuntimeServiceFailedToStartException>(),
);

/// Matches exception thrown by package:json_rpc_2 when trying to register a
/// service extension that's already registered.
final Matcher throwsServiceAlreadyRegisteredRPCError = throwsA(
  isA<RPCError>().having(
    (e) => e.code,
    'Error code',
    RpcException.serviceAlreadyRegistered.code,
  ),
);
