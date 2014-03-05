// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the @MirrorsUsed annotation suppress hints and that only
/// requested elements are retained for reflection.
library dart2js.test.mirrors_used_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'memory_compiler.dart' show
    compilerFor;

import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart' show
    Compiler;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart' show
    Constant,
    TypeConstant;

import
    '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart'
show
    Elements;

void expectOnlyVerboseInfo(Uri uri, int begin, int end, String message, kind) {
  if (kind.name == 'verbose info') {
    print(message);
    return;
  }
  if (message.contains('methods retained for use by dart:mirrors out of')) {
    print(message);
    return;
  }
  if (kind.name == 'info') return;

  // TODO(aprelev@gmail.com): Remove once dartbug.com/13907 is fixed.
  if (message.contains("Warning: 'typedef' not allowed here")) return;

  throw '$uri:$begin:$end: $kind: $message';
}

void main() {
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES, diagnosticHandler: expectOnlyVerboseInfo);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
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
    int expectedMethodCount = 375;
    Expect.isTrue(
        generatedCode.length <= expectedMethodCount,
        'Too many compiled methods: '
        '${generatedCode.length} > $expectedMethodCount');

    // The following names should be retained:
    List expectedNames = [
        'Foo', // The name of class Foo.
        r'Foo$', // The name of class Foo's constructor.
        r'get$field']; // The (getter) name of Foo.field.
    // TODO(ahe): Check for the following names, currently they are not being
    // recorded correctly, but are being emitted.
    [
        'Foo_staticMethod', // The name of Foo.staticMethod.
        r'instanceMethod$0']; // The name of Foo.instanceMethod.
    Set recordedNames = new Set()
        ..addAll(compiler.backend.emitter.recordedMangledNames)
        ..addAll(compiler.backend.emitter.mangledFieldNames.keys)
        ..addAll(compiler.backend.emitter.mangledGlobalFieldNames.keys);
    Expect.setEquals(new Set.from(expectedNames), recordedNames);

    for (var library in compiler.libraries.values) {
      library.forEachLocalMember((member) {
        if (library == compiler.mainApp && member.name == 'Foo') {
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

    // There should at least be one metadata constant:
    // 1. The constructed constant for 'MirrorsUsed'.
    Expect.isTrue(compiler.backend.metadataConstants.length >= 1);

    // Make sure that most of the metadata constants aren't included in the
    // generated code.
    for (var dependency in compiler.backend.metadataConstants) {
      Constant constant = dependency.constant;
      Expect.isFalse(
          compiler.constantHandler.compiledConstants.contains(constant),
          '$constant');
    }

    // The type literal 'Foo' is both used as metadata, and as a plain value in
    // the program. Make sure that it isn't duplicated.
    int fooConstantCount = 0;
    for (Constant constant in compiler.constantHandler.compiledConstants) {
      if (constant is TypeConstant && '${constant.representedType}' == 'Foo') {
        fooConstantCount++;
      }
    }
    Expect.equals(
        1, fooConstantCount,
        "The type literal 'Foo' is duplicated or missing.");
  }));
}

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
// The repeated constant value for symbols and targets used to crash dart2js in
// host-checked mode, and could potentially lead to other problems.
@MirrorsUsed(symbols: 'Foo', targets: 'Foo', override: '*')
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
