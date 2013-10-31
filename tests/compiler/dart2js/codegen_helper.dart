// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

import 'memory_source_file_helper.dart';

Future<Map<String, String>> generate(String code,
    [List<String> options = const []]) {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider({ 'main.dart': code });
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   null,
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   options);
  Uri uri = Uri.parse('memory:main.dart');
  return compiler.run(uri).then((success) {
    Expect.isTrue(success);
    Map<String, String> result = new Map<String, String>();
    for (var element in compiler.backend.generatedCode.keys) {
      if (element.getCompilationUnit().script.uri != uri) continue;
      var name = element.name;
      var code = compiler.backend.assembleCode(element);
      result[name] = code;
    }
    return result;
  });
}
