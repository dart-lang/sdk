// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the dart2js copy of [KernelVisitor] generates the expected IR as
/// defined by kernel spec-mode test files.

import 'dart:io';
import 'dart:async';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/js_backend/backend.dart' show JavaScriptBackend;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';

import '../memory_compiler.dart';

const String TESTCASE_DIR = 'pkg/front_end/testcases/';

const List<String> TESTS = const <String>[
  // 'DeltaBlue', Issue 29853: default constructor _not expected
  'argument',
  'arithmetic',
  'async_function',
  'bad_store',
  'call',
  'closure',
  // 'covariant_generic', Issue 29853: typedefs
  'escape',
  'fallthrough',
  'micro',
  // 'named_parameters', Issue 29853: default constructor _not expected
  'null_aware',
  'optional',
  'override',
  'prefer_baseclass',
  // 'redirecting_factory', Issue 29853: redirecting factories
  'static_setter',
  'store_load',
  'stringliteral',
  // 'uninitialized_fields', Issue 29853: default constructor _not expected
  'unused_methods',
  'void-methods',
];

main(List<String> arguments) {
  if (arguments.isEmpty) {
    for (String testName in TESTS) {
      scheduleTest(testName, selected: false);
    }
  } else {
    for (String testName in arguments) {
      scheduleTest(testName, selected: true);
    }
  }
}

scheduleTest(String name, {bool selected}) async {
  test(name, () async {
    Uri uri = Uri.base.resolve(TESTCASE_DIR).resolve('$name.dart');
    var compiler = await newCompiler();
    await compiler.run(uri);
    var loadedLibraries = await compiler.libraryLoader.loadLibrary(uri);
    compiler.processLoadedLibraries(loadedLibraries);
    var library = loadedLibraries.rootLibrary;
    JavaScriptBackend backend = compiler.backend;
    StringBuffer buffer = new StringBuffer();
    Program program = backend.kernelTask.buildProgram(library);
    CoreTypes coreTypes = new CoreTypes(program);
    ClassHierarchy hierarchy = new ClosedWorldClassHierarchy(program);
    new MixinFullResolution(new NoneTarget(null), coreTypes, hierarchy)
        .transform(program.libraries);
    new Printer(buffer).writeLibraryFile(program.mainMethod.enclosingLibrary);
    String actual = buffer.toString();
    String expected =
        new File('${TESTCASE_DIR}/$name.dart.direct.expect').readAsStringSync();
    if (selected) {
      String input = new File('${TESTCASE_DIR}/$name.dart').readAsStringSync();
      print('============================================================');
      print(name);
      print('--input-----------------------------------------------------');
      print(input);
      print('--expected--------------------------------------------------');
      print(expected);
      print('--actual----------------------------------------------------');
      print(actual);
    }
    expect(actual, equals(expected));
  });
}

Future<Compiler> newCompiler() async {
  var compiler = compilerFor(
      options: [Flags.analyzeOnly, Flags.analyzeAll, Flags.useKernel]);
  await compiler.setupSdk();

  // The visitor no longer enqueues elements that are not reachable from the
  // program. The mixin-full resolution transform run by the test expects to
  // find dart.core::Iterator.
  var loadedLibraries =
      await compiler.libraryLoader.loadLibrary(Uri.parse('dart:core'));
  compiler.processLoadedLibraries(loadedLibraries);
  dynamic core = loadedLibraries.rootLibrary;
  compiler.startResolution();
  var cls = core.implementation.localLookup('Iterator');
  cls.ensureResolved(compiler.resolution);
  return compiler;
}
