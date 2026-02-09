// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_runtime_service.dart';

/// Used to configure the [DartRuntimeService].
class DartRuntimeServiceOptions {
  const DartRuntimeServiceOptions({
    this.enableLogging = false,
    this.port = 0,
    this.disableAuthCodes = false,
    this.sseHandlerPath,
  });

  /// If true, enables log output for the service.
  final bool enableLogging;

  /// The port the service should attempt to bind to.
  ///
  /// Defaults to 0, which will result in the service binding to a random port.
  final int port;

  /// If true, clients will not be required to provide authentication codes to
  /// communicate with the service.
  ///
  /// Defaults to false.
  final bool disableAuthCodes;

  /// If non-null, allow for SSE connections to be established at
  /// [sseHandlerPath].
  ///
  /// Defaults to null.
  final String? sseHandlerPath;

  DartRuntimeServiceOptions copyWith({
    bool? enableLogging,
    int? port,
    bool? disableAuthCodes,
    String? sseHandlerPath,
  }) {
    return DartRuntimeServiceOptions(
      enableLogging: enableLogging ?? this.enableLogging,
      port: port ?? this.port,
      disableAuthCodes: disableAuthCodes ?? this.disableAuthCodes,
      sseHandlerPath: sseHandlerPath ?? this.sseHandlerPath,
    );
  }
}
