// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/backend.dart' as js
    show JavaScriptBackend;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:js_ast/js_ast.dart' as jsAst;
import 'package:test/test.dart';

import '../equivalence/check_functions.dart';
import '../memory_compiler.dart';

Future<jsAst.Expression> compile(String code,
    {dynamic lookup: 'main',
    bool useKernel: false,
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  List<String> options = <String>[
    Flags.disableInlining,
  ];
  if (disableTypeInference) options.add(Flags.disableTypeInference);
  if (!useKernel) options.add(Flags.useOldFrontend);
  options.addAll(extraOptions);

  if (lookup is String && lookup != 'main' && !code.contains('main')) {
    code = "$code\n\nmain() => $lookup;";
  }
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code}, options: options);
  expect(result.isSuccess, isTrue);
  Compiler compiler = result.compiler;
  ElementEnvironment elementEnvironment =
      compiler.backendClosedWorldForTesting.elementEnvironment;
  MemberEntity element;
  if (lookup is String) {
    LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
    element = elementEnvironment.lookupLibraryMember(mainLibrary, lookup);
  } else {
    element = lookup(compiler);
  }
  js.JavaScriptBackend backend = compiler.backend;
  return backend.generatedCode[element];
}

/// Checks that the given Dart [code] compiles to the same JS in kernel and
/// normal mode.
///
/// The function to check at the end is given by [lookup]. If [lookup] is a
/// String, then the generated code for a top-level element named [lookup] is
/// checked. Otherwise, [lookup] is a function that takes a [Compiler] and
/// returns an [MemberEntity], and the returned [MemberEntity] is checked.
Future check(String code,
    {dynamic lookup: 'main',
    bool disableTypeInference: true,
    List<String> extraOptions: const <String>[]}) async {
  jsAst.Expression original = await compile(code,
      lookup: lookup,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  jsAst.Expression kernel = await compile(code,
      lookup: lookup,
      useKernel: true,
      disableTypeInference: disableTypeInference,
      extraOptions: extraOptions);
  expect(areJsNodesEquivalent(original, kernel), isTrue);
}
