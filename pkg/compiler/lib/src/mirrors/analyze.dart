// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_mirrors.analyze;

import 'dart:async';

import 'source_mirrors.dart';
import 'dart2js_mirrors.dart' show Dart2JsMirrorSystem;
import '../../compiler.dart' as api;
import '../apiimpl.dart' as apiimpl;
import '../dart2jslib.dart' show Compiler;

//------------------------------------------------------------------------------
// Analysis entry point.
//------------------------------------------------------------------------------

/**
 * Analyzes set of libraries and provides a mirror system which can be used for
 * static inspection of the source code.
 */
// TODO(johnniwinther): Move this to [compiler/compiler.dart].
Future<MirrorSystem> analyze(List<Uri> libraries,
                             Uri libraryRoot,
                             Uri packageRoot,
                             api.CompilerInputProvider inputProvider,
                             api.DiagnosticHandler diagnosticHandler,
                             [List<String> options = const <String>[]]) {
  if (!libraryRoot.path.endsWith("/")) {
    throw new ArgumentError("libraryRoot must end with a /");
  }
  if (packageRoot != null && !packageRoot.path.endsWith("/")) {
    throw new ArgumentError("packageRoot must end with a /");
  }
  options = new List<String>.from(options);
  options.add('--analyze-only');
  options.add('--analyze-signatures-only');
  options.add('--analyze-all');
  options.add('--categories=Client,Server');
  options.add('--enable-async');

  bool compilationFailed = false;
  void internalDiagnosticHandler(Uri uri, int begin, int end,
                                 String message, api.Diagnostic kind) {
    if (kind == api.Diagnostic.ERROR ||
        kind == api.Diagnostic.CRASH) {
      compilationFailed = true;
    }
    diagnosticHandler(uri, begin, end, message, kind);
  }

  Compiler compiler = new apiimpl.Compiler(inputProvider,
                                           null,
                                           internalDiagnosticHandler,
                                           libraryRoot, packageRoot,
                                           options,
                                           const {});
  compiler.librariesToAnalyzeWhenRun = libraries;
  return compiler.run(null).then((bool success) {
    if (success && !compilationFailed) {
      return new Dart2JsMirrorSystem(compiler);
    } else {
      throw new StateError('Failed to create mirror system.');
    }
  });
}
