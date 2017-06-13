// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Implementation of the new compiler API in '../compiler_new.dart' through the
/// old compiler API in '../compiler.dart'.

library compiler.api.legacy;

import 'dart:async' show EventSink, Future;

import '../compiler.dart';
import '../compiler_new.dart';
import 'io/source_file.dart';
import 'null_compiler_output.dart' show NullSink;

/// Implementation of [CompilerInput] using a [CompilerInputProvider].
class LegacyCompilerInput implements CompilerInput {
  final CompilerInputProvider _inputProvider;

  LegacyCompilerInput(this._inputProvider);

  @override
  Future<Input> readFromUri(Uri uri, {InputKind inputKind: InputKind.utf8}) {
    return _inputProvider(uri).then((/*String|List<int>*/ data) {
      switch (inputKind) {
        case InputKind.utf8:
          SourceFile sourceFile;
          if (data is List<int>) {
            sourceFile = new Utf8BytesSourceFile(uri, data);
          } else if (data is String) {
            sourceFile = new StringSourceFile.fromUri(uri, data);
          } else {
            throw "Expected a 'String' or a 'List<int>' from the input "
                "provider, but got: ${Error.safeToString(data)}.";
          }
          return sourceFile;
        case InputKind.binary:
          if (data is String) {
            data = data.codeUnits;
          }
          return new Binary(uri, data);
      }
    });
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
// TODO(johnniwinther): Change Pub to use the new interface and remove this.
class LegacyCompilerOutput implements CompilerOutput {
  final CompilerOutputProvider _outputProvider;

  LegacyCompilerOutput([this._outputProvider]);

  @override
  OutputSink createOutputSink(String name, String extension, OutputType type) {
    if (_outputProvider != null) {
      switch (type) {
        case OutputType.info:
          if (extension == '') {
            // Needed to make Pub generate the same output name.
            extension = 'deferred_map';
          }
          break;
        default:
      }
      return new LegacyOutputSink(_outputProvider(name, extension));
    }
    return NullSink.outputProvider(name, extension, type);
  }
}

class LegacyOutputSink implements OutputSink {
  final EventSink<String> sink;

  LegacyOutputSink(this.sink);

  @override
  void add(String event) => sink.add(event);

  @override
  void close() => sink.close();
}
