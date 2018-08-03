// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/runtime_types.dart';
import 'package:compiler/src/js_emitter/model.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/program_lookup.dart';
import '../memory_compiler.dart';

const String code = '''
class A {}
class B<T> {}
class C<T> implements B<T> {}
class D<T> implements B<int> {}
class E<T> extends B<T> {}
class F<T> extends B<List<T>>{}
class G {
  call() {}
} 
class H implements G {
  call() {}
}
class I<T> {
  call(T t) {}
}

main() {
  new A();
  new C();
  new D();
  new E();
  new F();
  new H();
  new I();
}
''';

const Map<String, List<String>> expectedIsChecksMap =
    const <String, List<String>>{
  'A': const <String>[],
  'B': const <String>[],
  'C': const <String>[r'$isB'],
  'D': const <String>[r'$isB', r'$asB'],
  'E': const <String>[],
  'F': const <String>[r'$asB'],
  'G': const <String>[r'$isFunction'],
  'H': const <String>[r'$isFunction', r'$isG'],
  'I': const <String>[r'$isFunction', r'$signature'],
};

main() {
  runTest() async {
    CompilationResult result = await runCompiler(memorySourceFiles: {
      'main.dart': code
    }, options: [
      Flags.noPreviewDart2,
      Flags.disableRtiOptimization,
      Flags.disableInlining
    ]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    RuntimeTypesNeed rtiNeed = closedWorld.rtiNeed;
    ProgramLookup programLookup = new ProgramLookup(compiler);

    void processMember(MemberEntity element) {
      if (element is FunctionEntity) {
        Expect.isTrue(rtiNeed.methodNeedsTypeArguments(element),
            "Expected $element to need type arguments.");
        Expect.isTrue(rtiNeed.methodNeedsSignature(element),
            "Expected $element to need signature.");
      }
    }

    void processClass(ClassEntity element) {
      Expect.isTrue(closedWorld.rtiNeed.classNeedsTypeArguments(element));
      elementEnvironment.forEachConstructor(element, processMember);
      elementEnvironment.forEachLocalClassMember(element, processMember);

      List<String> expectedIsChecks = expectedIsChecksMap[element.name];
      if (expectedIsChecks != null) {
        Class cls = programLookup.getClass(element);
        List<String> isChecks = cls.isChecks.map((m) => m.name.key).toList();
        Expect.setEquals(
            expectedIsChecks,
            isChecks,
            "Unexpected is checks for $element: "
            "Expected $expectedIsChecks, actual $isChecks.");
      }
    }

    LibraryEntity library = elementEnvironment.mainLibrary;
    elementEnvironment.forEachClass(library, processClass);
    elementEnvironment.forEachLibraryMember(library, processMember);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
