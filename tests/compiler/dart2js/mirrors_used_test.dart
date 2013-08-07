// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the @MirrorsUsed annotation suppress hints and that only
/// requested elements are retained for reflection.
library dart2js.test.mirrors_used_test;

import 'package:expect/expect.dart';

import 'memory_compiler.dart' show
    compilerFor;

import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart' show
    Compiler;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart' show
    SourceString;

import
    '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart'
show
    Elements;

void expectOnlyVerboseInfo(Uri uri, int begin, int end, String message, kind) {
  if (kind.name == 'verbose info') {
    print(message);
    return;
  }
  throw '$uri:$begin:$end: $kind: $message';
}

void main() {
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES, diagnosticHandler: expectOnlyVerboseInfo);
  compiler.runCompiler(Uri.parse('memory:main.dart'));

  print('');
  List generatedCode =
      Elements.sortedByPosition(compiler.enqueuer.codegen.generatedCode.keys);
  for (var element in generatedCode) {
    print(element);
  }
  print('');

  // This assertion can fail for two reasons:
  // 1. Too many elements retained for reflection.
  // 2. Some code was refactored, and there are more methods.
  // Either situation could be problematic, but in situation 2, it is often
  // acceptable to increase [expectedMethodCount] a little.
  int expectedMethodCount = 317;
  Expect.isTrue(
      generatedCode.length <= expectedMethodCount,
      'Too many compiled methods: '
      '${generatedCode.length} > $expectedMethodCount');

  for (var library in compiler.libraries.values) {
    library.forEachLocalMember((member) {
      if (library == compiler.mainApp
          && member.name == const SourceString('Foo')) {
        Expect.isTrue(
            compiler.backend.isNeededForReflection(member), '$member');
        member.forEachLocalMember((classMember) {
          Expect.isTrue(
              compiler.backend.isNeededForReflection(classMember),
              '$classMember');
        });
      } else {
        Expect.isFalse(
            compiler.backend.isNeededForReflection(member), '$member');
      }
    });
  }
}

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
@MirrorsUsed(targets: const [Foo], override: '*')
import 'dart:mirrors';

import 'library.dart';

class Foo {
  int field;
  instanceMethod() {}
  static staticMethod() {}
}

unusedFunction() {
}

main() {
  useReflect(Foo);
}
""",
  'library.dart': """
library lib;

import 'dart:mirrors';

useReflect(type) {
  print(new Symbol('Foo'));
  print(MirrorSystem.getName(reflectClass(type).owner.qualifiedName));
}
""",
};
