// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_util;

import 'dart:async' show Future;
import 'dart:io' show Path;

import '../../../compiler/compiler.dart' as api;
import '../../../compiler/implementation/mirrors/dart2js_mirror.dart' as dart2js
    show analyze, Dart2JsMirrorSystem;
import '../../../compiler/implementation/mirrors/mirrors.dart'
    show MirrorSystem;
import '../../../compiler/implementation/source_file_provider.dart'
    show FormattingDiagnosticHandler, SourceFileProvider,
         CompilerSourceFileProvider;
import '../../../compiler/implementation/filenames.dart'
    show appendSlash, currentDirectory;

// TODO(johnniwinther): Support client configurable providers.

/**
 * Returns a future that completes to a non-null String when [script]
 * has been successfully compiled.
 */
// TODO(amouravski): Remove this method and call dart2js via a process instead.
Future<String> compile(String script,
                       String libraryRoot,
                       {String packageRoot,
                        List<String> options: const <String>[],
                        api.DiagnosticHandler diagnosticHandler}) {
  SourceFileProvider provider = new CompilerSourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  }
  Uri scriptUri = currentDirectory.resolve(script.toString());
  Uri libraryUri = currentDirectory.resolve(appendSlash('$libraryRoot'));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = currentDirectory.resolve(appendSlash('$packageRoot'));
  }
  return api.compile(scriptUri, libraryUri, packageUri,
      provider.readStringFromUri, diagnosticHandler, options);
}

/**
 * Analyzes set of libraries and provides a mirror system which can be used for
 * static inspection of the source code.
 */
Future<MirrorSystem> analyze(List<String> libraries,
                             String libraryRoot,
                             {String packageRoot,
                              List<String> options: const <String>[],
                              api.DiagnosticHandler diagnosticHandler}) {
  SourceFileProvider provider = new CompilerSourceFileProvider();
  if (diagnosticHandler == null) {
    diagnosticHandler =
        new FormattingDiagnosticHandler(provider).diagnosticHandler;
  }
  Uri libraryUri = currentDirectory.resolve(appendSlash('$libraryRoot'));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = currentDirectory.resolve(appendSlash('$packageRoot'));
  }
  List<Uri> librariesUri = <Uri>[];
  for (String library in libraries) {
    librariesUri.add(currentDirectory.resolve(library));
  }
  return dart2js.analyze(librariesUri, libraryUri, packageUri,
                         provider.readStringFromUri, diagnosticHandler,
                         options);
}
