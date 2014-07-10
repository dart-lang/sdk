// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.poi;

import 'dart:async' show
    Future;

import 'dart:io' show
    Platform;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    reuseCompiler;

import 'package:compiler/implementation/source_file_provider.dart' show
    FormattingDiagnosticHandler,
    SourceFileProvider;

import 'package:compiler/compiler.dart' as api show
    Diagnostic;

Future doneFuture;

void main(List<String> arguments) {
  Uri script = Uri.base.resolve(arguments.first);
  int position = int.parse(arguments[1]);
  FormattingDiagnosticHandler handler = new FormattingDiagnosticHandler();
  handler
      ..verbose = true
      ..enableColors = true;

  Uri libraryRoot = Uri.base.resolve('sdk/');
  Uri packageRoot = Uri.base.resolveUri(
      new Uri.file('${Platform.packageRoot}/'));

  var options = [
      '--analyze-main',
      '--analyze-only',
      '--no-source-maps',
      '--verbose',
      '--categories=Client,Server',
  ];

  var cachedCompiler = null;
  cachedCompiler = reuseCompiler(
      diagnosticHandler: handler,
      inputProvider: handler.provider,
      options: options,
      cachedCompiler: cachedCompiler,
      libraryRoot: libraryRoot,
      packageRoot: packageRoot,
      packagesAreImmutable: true);

  doneFuture = cachedCompiler.run(script).then((success) {
    if (success != true) {
      throw 'Compilation failed';
    }
    handler(
        script, position, position + 1,
        'Point of interest.', api.Diagnostic.HINT);
  });
}
