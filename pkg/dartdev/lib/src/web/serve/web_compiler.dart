// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:dartdev/src/web/project.dart';

/// A compiler that `dart serve` can serve an app from.
abstract interface class WebCompiler {
  /// The project being compiled.
  WebProject get project;

  /// Compiles the whole app.
  ///
  /// Returns the compile errors, or an empty list if there are none.
  Future<List<String>> compile();

  /// The compiled file at the URL [path] (without a leading `/`), or `null`
  /// if there is none.
  Uint8List? compiledFile(String path);

  /// Stops the compiler and deletes its temporary files.
  Future<void> shutdown();
}
