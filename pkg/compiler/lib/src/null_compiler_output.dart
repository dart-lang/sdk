// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Null pattern implementation of the [api.CompilerOutput] interface.

library compiler.null_api;

import '../compiler_api.dart' as api;

/// Null pattern implementation of the [api.CompilerOutput] interface.
class NullCompilerOutput implements api.CompilerOutput {
  const NullCompilerOutput();

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    return NullSink.outputProvider(name, extension, type);
  }

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) {
    return NullBinarySink(uri);
  }
}

/// A sink that discards the data.
class NullSink implements api.OutputSink {
  final String name;

  NullSink(this.name);

  @override
  void add(String value) {}

  @override
  void close() {}

  @override
  String toString() => name;

  /// Convenience method for getting an [api.CompilerOutputProvider].
  static NullSink outputProvider(
      String name, String extension, api.OutputType type) {
    return NullSink('$name.$extension.$type');
  }
}

class NullBinarySink implements api.BinaryOutputSink {
  final Uri uri;

  NullBinarySink(this.uri);

  @override
  void add(List<int> buffer, [int start = 0, int? end]) {}

  @override
  void close() {}

  @override
  String toString() => 'NullBinarySink($uri)';
}
