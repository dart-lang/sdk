// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the new compiler API in '../compiler_new.dart' through the
/// old compiler API in '../compiler.dart'.

library compiler.api.legacy;

import 'dart:async' show EventSink, Future;

import '../compiler.dart';
import '../compiler_new.dart';
import 'null_compiler_output.dart' show NullSink;

/// Implementation of [CompilerInput] using a [CompilerInputProvider].
class LegacyCompilerInput implements CompilerInput {
  final CompilerInputProvider _inputProvider;

  LegacyCompilerInput(this._inputProvider);

  @override
  Future readFromUri(Uri uri) {
    return _inputProvider(uri);
  }
}

/// Implementation of [CompilerDiagnostics] using a [DiagnosticHandler].
class LegacyCompilerDiagnostics implements CompilerDiagnostics {
  final DiagnosticHandler _handler;

  LegacyCompilerDiagnostics(this._handler);

  @override
  void report(
      var code, Uri uri, int begin, int end, String message, Diagnostic kind) {
    _handler(uri, begin, end, message, kind);
  }
}

/// Implementation of [CompilerOutput] using an optional
/// [CompilerOutputProvider].
class LegacyCompilerOutput implements CompilerOutput {
  final CompilerOutputProvider _outputProvider;

  LegacyCompilerOutput([this._outputProvider]);

  @override
  EventSink<String> createEventSink(String name, String extension) {
    if (_outputProvider != null) return _outputProvider(name, extension);
    return NullSink.outputProvider(name, extension);
  }
}
