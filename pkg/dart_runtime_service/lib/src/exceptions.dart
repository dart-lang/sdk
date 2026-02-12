// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_runtime_service.dart';

/// The base type for all exceptions thrown by the [DartRuntimeService].
abstract base class DartRuntimeServiceException implements Exception {
  const DartRuntimeServiceException({required this.message});

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the [DartRuntimeService] fails to start for any reason.
final class DartRuntimeServiceFailedToStartException
    extends DartRuntimeServiceException {
  const DartRuntimeServiceFailedToStartException({required String message})
    : super(message: 'Failed to start: $message');
}
