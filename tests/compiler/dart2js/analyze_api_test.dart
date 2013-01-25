// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import 'dart:uri';
import 'dart:io';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide Compiler;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/libraries.dart';

class CollectingDiagnosticHandler extends FormattingDiagnosticHandler {
  bool hasWarnings = false;
  bool hasErrors = false;

  CollectingDiagnosticHandler(SourceFileProvider provider) : super(provider);

  void diagnosticHandler(Uri uri, int begin, int end, String message,
                         api.Diagnostic kind) {
    if (kind == api.Diagnostic.WARNING) {
      hasWarnings = true;
    }
    if (kind == api.Diagnostic.ERROR) {
      hasErrors = true;
    }
    super.diagnosticHandler(uri, begin, end, message, kind);
  }
}

void main() {
  Uri currentWorkingDirectory = getCurrentDirectory();
  var libraryRoot = currentWorkingDirectory.resolve('sdk/');
  var uriList = new List<Uri>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      uriList.add(new Uri.fromComponents(scheme: 'dart', path: name));
    }
  });
  var provider = new SourceFileProvider();
  var handler = new CollectingDiagnosticHandler(provider);
  var compiler = new Compiler(
      provider.readStringFromUri,
      handler.diagnosticHandler,
      libraryRoot, libraryRoot,
      <String>['--analyze-only', '--analyze-all',
               '--categories=Client,Server']);
  compiler.librariesToAnalyzeWhenRun = uriList;
  compiler.run(null);
  Expect.isFalse(handler.hasWarnings);
  Expect.isFalse(handler.hasErrors);
}
