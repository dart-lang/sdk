// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;
import 'dart:_internal' as internal;

/// Load a dynamic module from [uri] and execute its entry point method.
///
/// Entry point method is a no-argument method annotated with
/// `@pragma('dyn-module:entry-point')`.
///
/// This API is experimental, can be changed or removed
/// without a notice.
///
/// Returns a future containing the result of the entry point method.
Future<Object?> loadModuleFromUri(Uri uri) =>
    internal.loadDynamicModule(uri: uri);

/// Load a dynamic module from [bytes] and execute its entry point method.
///
/// Entry point method is a no-argument method annotated with
/// `@pragma('dyn-module:entry-point')`.
///
/// This API is experimental, can be changed or removed
/// without a notice.
///
/// Returns a future containing the result of the entry point method.
Future<Object?> loadModuleFromBytes(Uint8List bytes) =>
    internal.loadDynamicModule(bytes: bytes);
