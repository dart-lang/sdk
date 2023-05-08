// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dart2wasm/target.dart' show WasmTarget;
import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerOptions,
        DiagnosticMessage,
        computePlatformBinariesLocation,
        kernelForModule,
        kernelForProgram,
        NnbdMode,
        parseExperimentalArguments,
        parseExperimentalFlags;
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart' show Printer;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/target/targets.dart';
import 'package:test/test.dart';

/// Environment define to update expectation files on failures.
const kUpdateExpectations = 'updateExpectations';

/// Environment define to dump actual results alongside expectations.
const kDumpActualResult = 'dump.actual.result';

Future<Component> compileTestCaseToKernelProgram(Uri sourceUri,
    {required Target target,
    List<String>? experimentalFlags,
    Map<String, String>? environmentDefines,
    Uri? packagesFileUri,
    List<Uri>? linkedDependencies}) async {
  Directory? tempDirectory;
  try {
    final platformFileName = (target is WasmTarget)
        ? 'dart2wasm_platform.dill'
        : 'vm_platform_strong.dill';
    final platformKernel =
        computePlatformBinariesLocation().resolve(platformFileName);
    environmentDefines ??= <String, String>{};
    final options = new CompilerOptions()
      ..target = target
      ..additionalDills = <Uri>[platformKernel]
      ..environmentDefines = environmentDefines
      ..packagesFileUri = packagesFileUri
      ..nnbdMode = NnbdMode.Strong
      ..explicitExperimentalFlags =
          parseExperimentalFlags(parseExperimentalArguments(experimentalFlags),
              onError: (String message) {
        throw message;
      })
      ..onDiagnostic = (DiagnosticMessage message) {
        fail("Compilation error: ${message.plainTextFormatted.join('\n')}");
      };
    if (linkedDependencies != null) {
      final Component component =
          (await kernelForModule(linkedDependencies, options)).component!;
      tempDirectory = await Directory.systemTemp.createTemp();
      Uri uri = tempDirectory.uri.resolve("generated.dill");
      File generated = new File.fromUri(uri);
      IOSink sink = generated.openWrite();
      try {
        new BinaryPrinter(sink).writeComponentFile(component);
      } finally {
        await sink.close();
      }
      options..additionalDills = <Uri>[platformKernel, uri];
    }

    final Component component =
        (await kernelForProgram(sourceUri, options))!.component!;

    // Make sure the library name is the same and does not depend on the order
    // of test cases.
    component.mainMethod!.enclosingLibrary.name = '#lib';
    return component;
  } finally {
    await tempDirectory?.delete(recursive: true);
  }
}

/// Returns a human-readable string representation of [library].
///
/// If [removeSelectorIds] is provided, selector ids above 99 are removed.
/// Extra libraries apart from the main library are passed to the front-end as
/// additional dills, which places them last in the library list, causing them
/// to have very high (and often changing) selector IDs.
String kernelLibraryToString(Library library,
    {bool removeSelectorIds = false}) {
  final StringBuffer buffer = new StringBuffer();
  final printer = new Printer(buffer, showMetadata: true);
  printer.writeLibraryFile(library);
  printer.writeConstantTable(library.enclosingComponent!);
  String result = buffer.toString();
  final libraryName = library.name;
  if (libraryName != null) {
    result = result.replaceAll(library.importUri.toString(), library.name!);
  }
  if (removeSelectorIds) {
    result = result
        .replaceAll(RegExp(r',methodOrSetterSelectorId:\d{3,}'), '')
        .replaceAll(RegExp(r',getterSelectorId:\d{3,}'), '');
  }
  return result;
}

String kernelComponentToString(Component component) {
  final StringBuffer buffer = new StringBuffer();
  new Printer(buffer, showMetadata: true).writeComponentFile(component);
  final mainLibrary = component.mainMethod!.enclosingLibrary;
  return buffer
      .toString()
      .replaceAll(mainLibrary.importUri.toString(), mainLibrary.name!);
}

class DevNullSink<T> implements Sink<T> {
  @override
  void add(T data) {}

  @override
  void close() {}
}

void ensureKernelCanBeSerializedToBinary(Component component) {
  new BinaryPrinter(new DevNullSink<List<int>>()).writeComponentFile(component);
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
  int i = 0;
  for (; i < actualLines.length && i < expectedLines.length; ++i) {
    if (actualLines[i] != expectedLines[i]) {
      return new Difference(i + 1, actualLines[i], expectedLines[i]);
    }
  }
  return new Difference(
      i + 1,
      i < actualLines.length ? actualLines[i] : '<END>',
      i < expectedLines.length ? expectedLines[i] : '<END>');
}

void compareResultWithExpectationsFile(
  Uri source,
  String actual, {
  String expectFilePostfix = '',
}) {
  final expectFile =
      new File('${source.toFilePath()}$expectFilePostfix.expect');
  final expected = expectFile.existsSync() ? expectFile.readAsStringSync() : '';

  if (actual != expected) {
    if (bool.fromEnvironment(kUpdateExpectations)) {
      expectFile.writeAsStringSync(actual);
      print("  Updated $expectFile");
    } else {
      if (bool.fromEnvironment(kDumpActualResult)) {
        new File(source.toFilePath() + '.actual').writeAsStringSync(actual);
      }
      Difference diff = findFirstDifference(actual, expected);
      fail("""

Result is different for the test case $source

The first difference is at line ${diff.line}.
Actual:   ${diff.actual}
Expected: ${diff.expected}

This failure can be caused by changes in the front-end if it starts generating
different kernel AST for the same Dart programs.

In order to re-generate expectations run tests with -D$kUpdateExpectations=true VM option:

  tools/test.py -m release --vm-options -D$kUpdateExpectations=true pkg/vm/

In order to dump actual results into .actual files run tests with -D$kDumpActualResult=true VM option:

  tools/test.py -m release --vm-options -D$kDumpActualResult=true pkg/vm/

""");
    }
  }
}
