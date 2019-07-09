// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerOptions, DiagnosticMessage;
import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:test/test.dart';
import 'package:vm/bytecode/gen_bytecode.dart' show generateBytecode;
import 'package:vm/bytecode/options.dart' show BytecodeOptions;
import 'package:vm/kernel_front_end.dart' show runWithFrontEndCompilerContext;

import '../common_test_utils.dart';

final String pkgVmDir = Platform.script.resolve('../..').toFilePath();

runTestCase(Uri source) async {
  // Certain tests require super-mixin semantics which is used in Flutter.
  bool enableSuperMixins = source.pathSegments.last == 'super_calls.dart';

  Component component = await compileTestCaseToKernelProgram(source,
      enableSuperMixins: enableSuperMixins);

  final options = new CompilerOptions()
    ..onDiagnostic = (DiagnosticMessage message) {
      fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
    };

  final mainLibrary = component.mainMethod.enclosingLibrary;

  await runWithFrontEndCompilerContext(source, options, component, () {
    // Need to omit source positions from bytecode as they are different on
    // Linux and Windows (due to differences in newline characters).
    generateBytecode(component,
        options: new BytecodeOptions(
            enableAsserts: true, omitAssertSourcePositions: true),
        libraries: [mainLibrary]);
  });

  component.libraries.removeWhere((lib) => lib != mainLibrary);
  String actual = kernelComponentToString(component);

  // Remove absolute library URIs.
  actual = actual.replaceAll(new Uri.file(pkgVmDir).toString(), '#pkg/vm');

  compareResultWithExpectationsFile(source, actual);
}

main() {
  group('gen-bytecode', () {
    final testCasesDir = new Directory(pkgVmDir + '/testcases/bytecode');

    for (var entry
        in testCasesDir.listSync(recursive: true, followLinks: false)) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
