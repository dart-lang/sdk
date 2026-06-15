// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

VMRef toVMRef(VM vm) => VMRef(name: vm.name);

int _nextId = 0;
String createId() {
  _nextId++;
  return '$_nextId';
}

final _logger = Logger('Utilities');

void safeUnawaited(
  Future<void> future, {
  void Function(Object, StackTrace)? onError,
}) {
  onError ??= (Object error, StackTrace stackTrace) =>
      _logger.warning('Error in unawaited Future:', error, stackTrace);
  unawaited(future.catchError(onError));
}

/// Throws an [RPCError] if the [asyncCallback] has an exception.
///
/// Only throws a new exception if the original exception type was not
/// [RPCError] or [SentinelException] (the two supported exception types of
/// package:vm_service).
Future<T> wrapInErrorHandlerAsync<T>(
  String command,
  Future<T> Function() asyncCallback,
) {
  return asyncCallback().catchError((Object error) {
    return Future<T>.error(
      RPCError(
        command,
        RPCErrorKind.kInternalError.code,
        'Unexpected DWDS error for $command: $error',
      ),
    );
  }, test: (e) => e is! RPCError && e is! SentinelException);
}
