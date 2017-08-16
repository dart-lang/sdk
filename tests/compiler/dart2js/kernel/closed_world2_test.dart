// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Partial test that the closed world computed from [WorldImpact]s derived from
// kernel is equivalent to the original computed from resolution.
library dart2js.kernel.closed_world2_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/js_backend/backend_usage.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/util/util.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';
import '../serialization/helper.dart';
import '../equivalence/check_functions.dart';
import 'compiler_helper.dart';
import 'test_helpers.dart';

const SOURCE = const {
  'main.dart': '''
import 'dart:html';
import 'dart:typed_data';
import 'package:expect/expect.dart';

class ClassWithSetter {
  void set setter(_) {}
}

class Mixin {
  method1() {}
  method2() {}
  method3() {}
}
class Class1 = Object with Mixin;
class Class2 extends Object with Mixin {
  method3() {}
}
 
method1() {} // Deliberately the same name as the instance member in Mixin.

class ClassWithCallBase {
  void call() {}
}

class ClassWithCallRequired {
  void call(int i) {}
}

class ClassWithCallGeneric<T> {
  void call(T t) {}
}

class ClassWithCallOptional<T> {
  void call([T t]) {}
}

class ClassWithCallNamed<T> {
  void call({T t}) {}
}

class ClassWithCallGetter {
  int get call => 0;
}

class ClassWithCallSetter {
  void set call(int i) {}
}

// Inherits the call type:
class ClassWithCall1 extends ClassWithCallBase {}
class ClassWithCall2 extends ClassWithCallRequired {}
class ClassWithCall3 extends ClassWithCallGeneric<String> {}
class ClassWithCall4 extends ClassWithCallOptional<String> {}
class ClassWithCall5 extends ClassWithCallNamed<String> {}

// Inherits the same call type twice:
class ClassWithCall6 extends ClassWithCallRequired
    implements ClassWithCallGeneric<int> {}

// Inherits different but compatible call types:
class ClassWithCall7 extends ClassWithCallRequired
    implements ClassWithCallGeneric<String> {}
class ClassWithCall8 extends ClassWithCallRequired
    implements ClassWithCallOptional<int> {}
class ClassWithCall9 extends ClassWithCallRequired
    implements ClassWithCallOptional<String> {}
class ClassWithCall10 extends ClassWithCallBase
    implements ClassWithCallNamed<String> {}

// Inherits incompatible call types:
class ClassWithCall11 extends ClassWithCallNamed<int>
    implements ClassWithCallOptional<int> {}
class ClassWithCall12 extends ClassWithCallGetter {}
class ClassWithCall13 extends ClassWithCallSetter {}
class ClassWithCall14 extends ClassWithCallBase
    implements ClassWithCallGetter {}
class ClassWithCall15 extends ClassWithCallBase
    implements ClassWithCallSetter {}

class ClassImplementsFunction implements Function {}

@NoInline()
main() {
  print('Hello World');
  ''.contains; // Trigger member closurization.
  new Element.div();
  new ClassWithSetter().setter = null;
  new Class1().method1();
  new Class2().method2();
  new Class2().method3();
  null is List<int>; // Use generic test
  method1(); // Both top level and instance method named 'method1' are live.
  #main; // Use a const symbol.
  const Symbol('foo'); // Use the const Symbol constructor directly
  new Int8List(0); // Use redirect factory to abstract native class

  new ClassWithCall1();
  new ClassWithCall2();
  new ClassWithCall3();
  new ClassWithCall4();
  new ClassWithCall5();
  new ClassWithCall6();
  new ClassWithCall7();
  new ClassWithCall8();
  new ClassWithCall9();
  new ClassWithCall10();
  new ClassWithCall11();
  new ClassWithCall12();
  new ClassWithCall13();
  new ClassWithCall14();
  new ClassWithCall15();
  new ClassImplementsFunction();
}
'''
};

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

enum ResultKind { crashes, errors, warnings, success, failure }

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  enableDebugMode();

  print('---- analyze-only ------------------------------------------------');
  DiagnosticCollector collector = new DiagnosticCollector();
  Compiler compiler1 = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      diagnosticHandler: collector,
      options: [Flags.analyzeOnly, Flags.enableAssertMessage]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler1.resolution.retainCachesForTesting = true;
  await compiler1.run(entryPoint);
  if (collector.crashes.isNotEmpty) {
    print('Skipping due to crashes.');
    return ResultKind.crashes;
  }
  if (collector.errors.isNotEmpty && skipErrors) {
    print('Skipping due to errors.');
    return ResultKind.errors;
  }
  if (collector.warnings.isNotEmpty && skipWarnings) {
    print('Skipping due to warnings.');
    return ResultKind.warnings;
  }
  Expect.isFalse(compiler1.compilationFailed);
  ResolutionEnqueuer enqueuer1 = compiler1.enqueuer.resolution;
  ClosedWorld closedWorld1 = compiler1.resolutionWorldBuilder.closeWorld();
  BackendUsage backendUsage1 = closedWorld1.backendUsage;

  Pair<Compiler, Compiler> compilers =
      await analyzeOnly(entryPoint, memorySourceFiles, printSteps: true);
  Compiler compiler = compilers.a;
  compiler.resolutionWorldBuilder.closeWorld();
  ElementEnvironment environment1 =
      compiler.frontendStrategy.elementEnvironment;

  Compiler compiler2 = compilers.b;
  KernelFrontEndStrategy frontendStrategy = compiler2.frontendStrategy;
  KernelToElementMapForImpact elementMap = frontendStrategy.elementMap;
  Expect.isFalse(compiler2.compilationFailed);

  KernelEquivalence equivalence = new KernelEquivalence(elementMap);
  TestStrategy strategy = equivalence.defaultStrategy;

  ElementEnvironment environment2 =
      compiler2.frontendStrategy.elementEnvironment;
  checkElementEnvironment(
      environment1,
      environment2,
      compiler1.frontendStrategy.dartTypes,
      compiler2.frontendStrategy.dartTypes,
      strategy);

  ResolutionEnqueuer enqueuer2 = compiler2.enqueuer.resolution;
  ClosedWorld closedWorld2 = compiler2.resolutionWorldBuilder.closeWorld();
  BackendUsage backendUsage2 = closedWorld2.backendUsage;

  checkNativeClasses(compiler1, compiler2, strategy);

  checkBackendUsage(backendUsage1, backendUsage2, strategy);

  checkResolutionEnqueuers(backendUsage1, backendUsage2, enqueuer1, enqueuer2,
      elementEquivalence: (a, b) => equivalence.entityEquivalence(a, b),
      typeEquivalence: (DartType a, DartType b) {
        return equivalence.typeEquivalence(unalias(a), b);
      },
      elementFilter: elementFilter,
      verbose: arguments.verbose);

  checkClosedWorlds(closedWorld1, closedWorld2,
      strategy: equivalence.defaultStrategy, verbose: arguments.verbose);

  return ResultKind.success;
}
