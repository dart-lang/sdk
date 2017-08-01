// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/elements.dart'
    show Element, LibraryElement;
import 'package:compiler/src/js_backend/backend.dart' as js
    show JavaScriptBackend;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:test/test.dart';

import '../memory_compiler.dart';

Future<String> compile(String code,
    {dynamic lookup: 'main',
    bool useKernelInSsa: true,
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  List<String> options = <String>[
    Flags.disableInlining,
  ];
  if (disableTypeInference) options.add(Flags.disableTypeInference);
  if (useKernelInSsa) options.add(Flags.useKernelInSsa);
  options.addAll(extraOptions);

  if (lookup is String && lookup != 'main' && !code.contains('main')) {
    code = "$code\n\nmain() => $lookup;";
  }
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code}, options: options);
  expect(result.isSuccess, isTrue);
  Compiler compiler = result.compiler;
  LibraryElement mainApp =
      compiler.frontendStrategy.elementEnvironment.mainLibrary;
  Element element;
  if (lookup is String) {
    element = mainApp.find(lookup);
  } else {
    element = lookup(compiler);
  }
  js.JavaScriptBackend backend = compiler.backend;
  return backend.getGeneratedCode(element);
}

/// Checks that the given Dart [code] compiles to the same JS in kernel and
/// normal mode.
///
/// The function to check at the end is given by [lookup]. If [lookup] is a
/// String, then the generated code for a top-level element named [lookup] is
/// checked. Otherwise, [lookup] is a function that takes a [Compiler] and
/// returns an [Element], and the returned [Element] is checked.
Future check(String code,
    {dynamic lookup: 'main',
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  var original = await compile(code,
      lookup: lookup,
      useKernelInSsa: false,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  var kernel = await compile(code,
      lookup: lookup,
      useKernelInSsa: true,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  expect(kernel, original);
}
