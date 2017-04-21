// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Null pattern implementation of the [CompilerOutput] interface.

library compiler.null_api;

import '../compiler_new.dart';

/// Null pattern implementation of the [CompilerOutput] interface.
class NullCompilerOutput implements CompilerOutput {
  const NullCompilerOutput();

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    return NullSink.outputProvider(name, extension, type);
  }
}

/// A sink that drains into /dev/null.
class NullSink implements OutputSink {
  final String name;

  NullSink(this.name);

  add(String value) {}

  void close() {}

  toString() => name;

  /// Convenience method for getting an [api.CompilerOutputProvider].
  static NullSink outputProvider(
      String name, String extension, OutputType type) {
    return new NullSink('$name.$extension.$type');
  }
}
