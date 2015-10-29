// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:compiler/src/null_compiler_output.dart';
import 'memory_source_file_helper.dart';

Future<Map<String, String>> generate(String code,
    [List<String> options = const []]) {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider({ 'main.dart': code });
  var handler = new FormattingDiagnosticHandler(provider);

  CompilerImpl compiler = new CompilerImpl(provider,
                                   const NullCompilerOutput(),
                                   handler,
                                   libraryRoot,
                                   packageRoot,
                                   options,
                                   {});
  Uri uri = Uri.parse('memory:main.dart');
  return compiler.run(uri).then((success) {
    Expect.isTrue(success);
    Map<String, String> result = new Map<String, String>();
    var backend = compiler.backend;
    for (var element in backend.generatedCode.keys) {
      if (element.compilationUnit.script.readableUri != uri) continue;
      var name = element.name;
      var code = backend.getGeneratedCode(element);
      result[name] = code;
    }
    return result;
  });
}
