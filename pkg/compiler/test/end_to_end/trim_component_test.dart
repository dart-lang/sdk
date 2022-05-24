// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;
import '../helpers/memory_compiler.dart';

const memorySourceFiles = const {
  'main.dart': '''
// @dart=2.12
import 'used.dart';

void main() {
  foo();
}

''',
  'used.dart': '''
// @dart=2.12

void foo() {
  print('foo');
}
''',
  'unused.dart': '''
// @dart=2.12

void unused() {
  throw 'unused';
}
'''
};

void verifyComponent(
    ir.Component component, List<String> included, List<String> excluded) {
  Set<String> uris = {};
  component.libraries
      .forEach((library) => uris.add(library.importUri.toString()));
  for (String include in included) {
    Expect.isTrue(uris.contains(include));
  }
  for (String exclude in excluded) {
    Expect.isFalse(uris.contains(exclude));
  }
}

Future<List<int>> buildDillAndVerify(
    Map<String, dynamic> memorySourceFiles,
    List<String> flags,
    List<String> includedLibraries,
    List<String> excludedLibraries) async {
  final dillUri = Uri.parse('out.dill');
  final collector = OutputCollector();
  CompilationResult result = await runCompiler(
      memorySourceFiles: memorySourceFiles,
      options: flags,
      outputProvider: collector);
  Expect.isTrue(result.isSuccess);
  Expect.isTrue(collector.binaryOutputMap.containsKey(dillUri));
  List<int> bytes = collector.binaryOutputMap[dillUri].list;
  Expect.isTrue(bytes.isNotEmpty);
  ir.Component component = ir.Component();
  BinaryBuilder(bytes).readComponent(component);
  verifyComponent(component, includedLibraries, excludedLibraries);
  return bytes;
}

void verifyComponentTrim() async {
  List<String> buildDillFromSourceFlags = [
    '--cfe-only',
    '--out=out.dill',
    '--sources=memory:main.dart,memory:used.dart,memory:unused.dart',
    '--sound-null-safety',
  ];
  List<int> bytes = await buildDillAndVerify(
      memorySourceFiles,
      buildDillFromSourceFlags,
      ['memory:main.dart', 'memory:used.dart', 'memory:unused.dart'],
      []);

  // The combination of `--cfe-only` + `--entry-uri` should trigger the
  // component trimming logic.
  List<String> trimDillFlags = [
    '--input-dill=memory:main.dill',
    '--cfe-only',
    '--out=out.dill',
    '--entry-uri=main.dart',
    '--sound-null-safety',
  ];
  List<int> newBytes = await buildDillAndVerify(
      {'main.dill': bytes},
      trimDillFlags,
      ['memory:main.dart', 'memory:used.dart'],
      ['memory:unused.dart']);
  Expect.isTrue(newBytes.length < bytes.length);
}

void main() async {
  await verifyComponentTrim();
}
