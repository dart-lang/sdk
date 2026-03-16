// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:cfg/ir/global_context.dart';
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        computePlatformBinariesLocation,
        CfeDiagnosticMessage,
        kernelForProgram;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:cfg/front_end/ast_to_ir.dart';
import 'package:cfg/front_end/recognized_methods.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/ir_to_text.dart';
import 'package:cfg/ir/ssa_computation.dart';
import 'package:cfg/passes/constant_propagation.dart';
import 'package:cfg/passes/control_flow_optimizations.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/passes/simplification.dart';
import 'package:cfg/passes/value_numbering.dart';
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import 'package:vm/modular/target/vm.dart';

/// Environment define to update expectation files on failures.
const kUpdateExpectations = 'updateExpectations';

final String dartSdkPkgDir = Platform.script.resolve('../..').toFilePath();

Future<void> runTestCase(Uri source) async {
  final target = VmTarget(TargetFlags());
  Component component = await compileTestCaseToKernelProgram(
    source,
    target: target,
  );
  final coreTypes = CoreTypes(component);
  final hierarchy = ClassHierarchy(component, coreTypes);
  final typeEnvironment = TypeEnvironment(coreTypes, hierarchy);

  String actual = GlobalContext.withContext(
    GlobalContext(typeEnvironment: typeEnvironment),
    () {
      final compileAndDump = CompileAndDumpIr();

      final mainLibrary = component.mainMethod!.enclosingLibrary;
      mainLibrary.accept(compileAndDump);

      return compileAndDump.buffer.toString();
    },
  );

  // Remove absolute library URIs.
  actual = actual.replaceAll(
    new Uri.file(dartSdkPkgDir).toString(),
    'DART_SDK/pkg/',
  );

  compareResultWithExpectationsFile(source, actual);
}

Future<Component> compileTestCaseToKernelProgram(
  Uri sourceUri, {
  required Target target,
}) async {
  final platformKernel = computePlatformBinariesLocation().resolve(
    'vm_platform.dill',
  );
  final options = CompilerOptions()
    ..target = target
    ..additionalDills = <Uri>[platformKernel]
    ..environmentDefines = {}
    ..onDiagnostic = (CfeDiagnosticMessage message) {
      fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
    };

  final Component component = (await kernelForProgram(
    sourceUri,
    options,
  ))!.component!;

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  component.mainMethod!.enclosingLibrary.name = '#lib';
  return component;
}

class CompileAndDumpIr extends RecursiveVisitor {
  final FunctionRegistry functionRegistry = FunctionRegistry();
  final RecognizedMethods recognizedMethods = CommonRecognizedMethods();
  final buffer = StringBuffer();

  @override
  void visitProcedure(Procedure node) {
    if (node.isAbstract) {
      return;
    }
    compileAndDumpFunction(
      functionRegistry.getFunction(
        node,
        isGetter: node.isGetter,
        isSetter: node.isSetter,
      ),
    );
  }

  @override
  void visitField(Field node) {
    if (node.isAbstract) {
      return;
    }
    if (node.hasGetter && !node.isStatic) {
      compileAndDumpFunction(
        functionRegistry.getFunction(node, isGetter: true),
      );
    }
    if (node.hasSetter && !node.isStatic) {
      compileAndDumpFunction(
        functionRegistry.getFunction(node, isSetter: true),
      );
    }
    if ((node.isStatic || node.isLate) && node.initializer != null) {
      compileAndDumpFunction(
        functionRegistry.getFunction(node, isInitializer: true),
      );
    }
  }

  @override
  void visitConstructor(Constructor node) {
    compileAndDumpFunction(functionRegistry.getFunction(node));
  }

  void compileAndDumpFunction(CFunction function) {
    final graph = AstToIr(
      function,
      functionRegistry,
      recognizedMethods,
      enableAsserts: true,
      typeParametersStyle: .separateFunctionAndClassTypeParameters,
    ).buildFlowGraph();
    final pipeline = Pipeline([
      SSAComputation(),
      ValueNumbering(simplification: Simplification()),
      ConstantPropagation(),
      ControlFlowOptimizations(),
    ]);
    pipeline.run(graph);
    buffer.writeln('--- $function');
    buffer.writeln(
      IrToText(graph, printDominators: true, printLoops: true).toString(),
    );
  }
}

class Difference {
  final int line;
  final String actual;
  final String expected;

  Difference(this.line, this.actual, this.expected);
}

Difference findFirstDifference(String actual, String expected) {
  final actualLines = actual.split('\n');
  final expectedLines = expected.split('\n');
  var i = 0;
  for (; i < actualLines.length && i < expectedLines.length; ++i) {
    if (actualLines[i] != expectedLines[i]) {
      return Difference(i + 1, actualLines[i], expectedLines[i]);
    }
  }
  return Difference(
    i + 1,
    i < actualLines.length ? actualLines[i] : '<END>',
    i < expectedLines.length ? expectedLines[i] : '<END>',
  );
}

void compareResultWithExpectationsFile(
  Uri source,
  String actual, {
  String expectFilePostfix = '',
}) {
  final baseFilename = '${source.toFilePath()}$expectFilePostfix';
  final expectFile = new File('$baseFilename.expect');
  final expected = expectFile.existsSync() ? expectFile.readAsStringSync() : '';

  if (actual != expected) {
    if (bool.fromEnvironment(kUpdateExpectations)) {
      expectFile.writeAsStringSync(actual);
      print("  Updated $expectFile");
    } else {
      Difference diff = findFirstDifference(actual, expected);
      fail("""

Result is different for the test case $source

The first difference is at line ${diff.line}.
Actual:   ${diff.actual}
Expected: ${diff.expected}

This failure can be caused by changes in the front-end if it starts generating
different kernel AST for the same Dart programs.

In order to re-generate expectations run test with -D$kUpdateExpectations=true VM option:

  dart -DupdateExpectations=true pkg/cfg/test/ir_test.dart

""");
    }
  }
}

void main() {
  group('ir-test', () {
    final testCasesDir = new Directory(dartSdkPkgDir + 'cfg/testcases');

    for (var entry in testCasesDir.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entry.path.endsWith(".dart")) {
        test(entry.path, () => runTestCase(entry.uri));
      }
    }
  });
}
