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
  method<int>();
}

method<T>() {
  local1() {}
  local2(T t) {}
  local3<S>(S s) {}

  local1();
  local2(null);
  local3(null);
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
  'G': const <String>[],
  'H': const <String>[r'$isG'],
  'I': const <String>[],
  'method_local1': const <String>[r'$signature'],
  'method_local2': const <String>[r'$signature'],
  'method_local3': const <String>[r'$signature'],
};

main() {
  runTest() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': code},
        // TODO(johnniwinther): This test fails if inlining is disabled. This
        // is because the selector for calling `local1` matches `H.call` which
        // is not considered live be resolution. We need to mark function-call
        // selectors separately from dynamic calls and class-calls as to not
        // mix these in codegen. Currently this test works without
        // --disable-inlining, but the option should be re-enabled to ensure
        // the intended coverage.
        options: [Flags.disableRtiOptimization /*, Flags.disableInlining*/]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    RuntimeTypesNeed rtiNeed = closedWorld.rtiNeed;
    ProgramLookup programLookup = new ProgramLookup(compiler);

    List<ClassEntity> closures = <ClassEntity>[];

    void processMember(MemberEntity element) {
      if (element is FunctionEntity) {
        Expect.isTrue(rtiNeed.methodNeedsTypeArguments(element),
            "Expected $element to need type arguments.");
        Expect.isTrue(rtiNeed.methodNeedsSignature(element),
            "Expected $element to need signature.");
        elementEnvironment.forEachNestedClosure(element,
            (FunctionEntity local) {
          closures.add(local.enclosingClass);
        });
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
        if (cls.functionTypeIndex != null) {
          isChecks.add(r'$signature');
        }
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
    closures.forEach(processClass);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
