// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'memory_source_file_helper.dart';
import "../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart"
    show SourceString;

Map<String, String> generate(String code, [List<String> options = const []]) {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = { 'main.dart': code };
  var provider = new MemorySourceFileProvider();
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   null,
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   options);
  Uri uri = Uri.parse('memory:main.dart');
  Expect.isTrue(compiler.run(uri));
  Map<String, String> result = new Map<String, String>();
  for (var element in compiler.backend.generatedCode.keys) {
    if (element.getCompilationUnit().script.uri != uri) continue;
    var name = element.name.slowToString();
    var code = compiler.backend.assembleCode(element);
    result[name] = code;
  }
  return result;
}
