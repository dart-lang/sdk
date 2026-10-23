// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// `dart:io` and Shelf HTTP server utilities for [DartRuntimeServiceBackend]
/// implementations running on the standalone Dart VM (such as the VM service
/// and DDS backends).
///
/// Re-exports `package:dart_runtime_service/dart_runtime_service.dart` along
/// with [DartRuntimeServiceIoBackend], [DartDevelopmentServiceManager],
/// [DevFS], and DevTools/DTD hosting utilities.
///
/// @docImport 'dart_runtime_service.dart';
/// @docImport 'src/io/dart_development_service_manager.dart';
/// @docImport 'src/io/dart_runtime_service_io_backend.dart';
/// @docImport 'src/io/devfs.dart';
library;

export 'dart_runtime_service.dart';
export 'src/io/dart_development_service_manager.dart';
export 'src/io/dart_runtime_service_io_backend.dart';
export 'src/io/devfs.dart';
export 'src/io/devtools/client.dart';
export 'src/io/devtools/dtd.dart';
export 'src/io/devtools/handler.dart';
export 'src/io/devtools/machine_mode_command_handler.dart';
export 'src/io/devtools/memory_profile.dart';
export 'src/io/devtools/utils.dart';
export 'src/io/devtools/vs_code.dart';
