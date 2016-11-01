// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the dart2js copy of [KernelVisitor] generates the expected IR as
/// defined by kernel spec-mode test files.

import 'dart:io';
import 'package:compiler/src/compiler.dart' show Compiler;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/js_backend/backend.dart' show JavaScriptBackend;
import 'package:compiler/src/commandline_options.dart' show Flags;
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';
import 'package:path/path.dart' as pathlib;
import 'package:test/test.dart';

import '../memory_compiler.dart';

const String TESTCASE_DIR = 'third_party/pkg/kernel/testcases/';

const List<String> SKIP_TESTS = const <String>[];

main(List<String> arguments) {
  Compiler compiler = compilerFor(
      options: [Flags.analyzeOnly, Flags.analyzeMain, Flags.useKernel]);
  Directory directory = new Directory('${TESTCASE_DIR}/input');
  for (FileSystemEntity file in directory.listSync()) {
    if (file is File && file.path.endsWith('.dart')) {
      String name = pathlib.basenameWithoutExtension(file.path);
      bool selected = arguments.contains(name);
      if (!selected) {
        if (arguments.isNotEmpty) continue;
        if (SKIP_TESTS.contains(name)) continue;
      }

      test(name, () async {
        LibraryElement library = await compiler.analyzeUri(file.absolute.uri);
        JavaScriptBackend backend = compiler.backend;
        StringBuffer buffer = new StringBuffer();
        Program program = backend.kernelTask.buildProgram(library);
        new MixinFullResolution().transform(program);
        new Printer(buffer)
            .writeLibraryFile(program.mainMethod.enclosingLibrary);
        String actual = buffer.toString();
        String expected =
            new File('${TESTCASE_DIR}/spec-mode/$name.baseline.txt')
                .readAsStringSync();
        if (selected) {
          String input =
              new File('${TESTCASE_DIR}/input/$name.dart').readAsStringSync();
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
  }
}
