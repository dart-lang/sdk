// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/elements.dart' show Element;
import 'package:compiler/src/js_backend/backend.dart' as js
    show JavaScriptBackend;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:test/test.dart';

import '../memory_compiler.dart';

Future<String> compile(String code,
    {String entry: 'main',
    bool useKernel: true,
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  List<String> options = <String>[
    Flags.disableInlining,
  ];
  if (disableTypeInference) options.add(Flags.disableTypeInference);
  if (useKernel) options.add(Flags.useKernel);
  options.addAll(extraOptions);

  if (entry != 'main' && !code.contains('main')) {
    code = "$code\n\nmain() => $entry;";
  }
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code}, options: options);
  expect(result.isSuccess, isTrue);
  Compiler compiler = result.compiler;
  Element element = compiler.mainApp.find(entry);
  js.JavaScriptBackend backend = compiler.backend;
  return backend.getGeneratedCode(element);
}

Future check(String code,
    {String entry: 'main',
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  var original = await compile(code,
      entry: entry,
      useKernel: false,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  var kernel = await compile(code,
      entry: entry,
      useKernel: true,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  expect(kernel, original);
}
