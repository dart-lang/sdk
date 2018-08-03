// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart' show Printer;
import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;
import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm.dart';
import 'package:test/test.dart';

const bool kDumpActualResult = const bool.fromEnvironment('dump.actual.result');

Future<Component> compileTestCaseToKernelProgram(Uri sourceUri) async {
  final platformKernel =
      computePlatformBinariesLocation().resolve('vm_platform_strong.dill');
  final options = new CompilerOptions()
    ..strongMode = true
    ..target = new VmTarget(new TargetFlags(strongMode: true))
    ..linkedDependencies = <Uri>[platformKernel]
    ..reportMessages = true
    ..onError = (CompilationMessage error) {
      fail("Compilation error: ${error}");
    };

  final Component component = await kernelForProgram(sourceUri, options);

  // Make sure the library name is the same and does not depend on the order
  // of test cases.
  component.mainMethod.enclosingLibrary.name = '#lib';

  return component;
}

String kernelLibraryToString(Library library) {
  final StringBuffer buffer = new StringBuffer();
  new Printer(buffer, showExternal: false, showMetadata: true)
      .writeLibraryFile(library);
  return buffer.toString();
}

class DevNullSink<T> extends Sink<T> {
  @override
  void add(T data) {}

  @override
  void close() {}
}

void ensureKernelCanBeSerializedToBinary(Component component) {
  new BinaryPrinter(new DevNullSink<List<int>>()).writeComponentFile(component);
}

void compareResultWithExpectationsFile(Uri source, String actual) {
  final expectFile = new File(source.toFilePath() + '.expect');
  final expected = expectFile.existsSync() ? expectFile.readAsStringSync() : '';

  if (actual != expected) {
    if (kDumpActualResult) {
      new File(source.toFilePath() + '.actual').writeAsStringSync(actual);
    }
    expect(actual, equals(expected), reason: "Test case: $source");
  }
}
