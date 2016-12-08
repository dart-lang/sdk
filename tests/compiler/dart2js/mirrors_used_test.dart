// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the @MirrorsUsed annotation suppress hints and that only
/// requested elements are retained for reflection.
library dart2js.test.mirrors_used_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'memory_compiler.dart' show runCompiler;

import 'package:compiler/src/apiimpl.dart' show CompilerImpl;

import 'package:compiler/src/constants/values.dart'
    show ConstantValue, TypeConstantValue;

import 'package:compiler/src/elements/elements.dart' show Element, Elements;

import 'package:compiler/src/js_backend/js_backend.dart' show JavaScriptBackend;

import 'package:compiler/src/js_emitter/full_emitter/emitter.dart' as full
    show Emitter;

import 'package:compiler/src/old_to_new_api.dart'
    show LegacyCompilerDiagnostics;

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
  asyncTest(() async {
    var result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        diagnosticHandler: new LegacyCompilerDiagnostics(expectOnlyVerboseInfo),
        options: ['--enable-experimental-mirrors']);
    CompilerImpl compiler = result.compiler;
    print('');
    List generatedCode =
        Elements.sortedByPosition(compiler.enqueuer.codegen.processedEntities);
    for (var element in generatedCode) {
      print(element);
    }
    print('');

    // This assertion can fail for two reasons:
    // 1. Too many elements retained for reflection.
    // 2. Some code was refactored, and there are more methods.
    // Either situation could be problematic, but in situation 2, it is often
    // acceptable to increase [expectedMethodCount] a little.
    int expectedMethodCount = 466;
    Expect.isTrue(
        generatedCode.length <= expectedMethodCount,
        'Too many compiled methods: '
        '${generatedCode.length} > $expectedMethodCount');

    // The following names should be retained:
    List expectedNames = [
      'Foo', // The name of class Foo.
      r'Foo$', // The name of class Foo's constructor.
      r'get$field'
    ]; // The (getter) name of Foo.field.
    // TODO(ahe): Check for the following names, currently they are not being
    // recorded correctly, but are being emitted.
    [
      'Foo_staticMethod', // The name of Foo.staticMethod.
      r'instanceMethod$0'
    ]; // The name of Foo.instanceMethod.

    // We always include the names of some native classes.
    List<Element> nativeClasses = [
      compiler.coreClasses.intClass,
      compiler.coreClasses.doubleClass,
      compiler.coreClasses.numClass,
      compiler.coreClasses.stringClass,
      compiler.coreClasses.boolClass,
      compiler.coreClasses.nullClass,
      compiler.coreClasses.listClass
    ];
    JavaScriptBackend backend = compiler.backend;
    Iterable<String> nativeNames = nativeClasses.map(backend.namer.className);
    expectedNames = expectedNames.map(backend.namer.asName).toList();
    expectedNames.addAll(nativeNames);

    // Mirrors only work in the full emitter. We can thus be certain that the
    // emitter is the full emitter.
    full.Emitter fullEmitter = backend.emitter.emitter;
    Set recordedNames = new Set()
      ..addAll(fullEmitter.recordedMangledNames)
      ..addAll(fullEmitter.mangledFieldNames.keys)
      ..addAll(fullEmitter.mangledGlobalFieldNames.keys);
    Expect.setEquals(new Set.from(expectedNames), recordedNames);

    for (var library in compiler.libraryLoader.libraries) {
      library.forEachLocalMember((member) {
        if (library == compiler.mainApp && member.name == 'Foo') {
          Expect.isTrue(
              compiler.backend.isAccessibleByReflection(member), '$member');
          member.forEachLocalMember((classMember) {
            Expect.isTrue(
                compiler.backend.isAccessibleByReflection(classMember),
                '$classMember');
          });
        } else {
          Expect.isFalse(
              compiler.backend.isAccessibleByReflection(member), '$member');
        }
      });
    }

    int metadataCount = 0;
    Set<ConstantValue> compiledConstants = backend.constants.compiledConstants;
    // Make sure that most of the metadata constants aren't included in the
    // generated code.
    backend.processMetadata(compiler.enqueuer.resolution.processedEntities,
        (metadata) {
      ConstantValue constant =
          backend.constants.getConstantValueForMetadata(metadata);
      Expect.isFalse(
          compiledConstants.contains(constant), constant.toStructuredText());
      metadataCount++;
    });

    // There should at least be one metadata constant:
    // 1. The constructed constant for 'MirrorsUsed'.
    Expect.isTrue(metadataCount >= 1);

    // The type literal 'Foo' is both used as metadata, and as a plain value in
    // the program. Make sure that it isn't duplicated.
    int fooConstantCount = 0;
    for (ConstantValue constant in compiledConstants) {
      if (constant is TypeConstantValue &&
          '${constant.representedType}' == 'Foo') {
        fooConstantCount++;
      }
    }
    Expect.equals(1, fooConstantCount,
        "The type literal 'Foo' is duplicated or missing.");
  });
}

const MEMORY_SOURCE_FILES = const <String, String>{
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
