// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/js_model/js_strategy.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/d8_helper.dart';
import '../helpers/memory_compiler.dart';

const String SOURCE = r'''
@pragma('dart2js:noInline')
method1<T>(T t) {
  print('method1:');
  print('$t is $T = ${t is T}');
  print('"foo" is $T = ${"foo" is T}');
  print('');
}

@pragma('dart2js:noInline')
method2<T, S>(S s, T t) {
  print('method2:');
  print('$t is $T = ${t is T}');
  print('$s is $T = ${s is T}');
  print('$t is $S = ${t is S}');
  print('$s is $S = ${s is S}');
  print('');
}

@pragma('dart2js:tryInline')
method3<T, S>(T t, S s) {
  print('method3:');
  print('$t is $T = ${t is T}');
  print('$s is $T = ${s is T}');
  print('$t is $S = ${t is S}');
  print('$s is $S = ${s is S}');
  print('');
}

class Class1<T> {
  final int index;

  Class1(this.index);

  String toString() => 'c$index';
}

method4<T>(int index) => new Class1<T>(index);

testMethod4() {
  print('method4:');
  var c1 = method4<int>(1);
  var c2 = method4<String>(2);
  print('$c1 is Class1<int> = ${c1 is Class1<int>}');
  print('$c2 is Class1<int> = ${c2 is Class1<int>}');
  print('$c1 is Class1<String> = ${c1 is Class1<String>}');
  print('$c2 is Class1<String> = ${c2 is Class1<String>}');
  print('');
}

class Class2 {
  @pragma('dart2js:tryInline')
  method5<T>(T t) {
    print('Class2.method5:');
    print('$t is $T = ${t is T}');
    print('"foo" is $T = ${"foo" is T}');
    print('');
  }

  @pragma('dart2js:noInline')
  method6(o) {
    print('Class2.method6:');
    print('$o is int = ${o is int}');
    print('$o is String = ${o is String}');
    print('');
  }
}

class Class3 {
  @pragma('dart2js:noInline')
  method6<T>(T t) {
    print('Class3.method6:');
    print('$t is $T = ${t is T}');
    print('"foo" is $T = ${"foo" is T}');
    print('');
  }
}

class Class4<T> {
  Function method7<Q>() {
    foo(T t, Q q) => '';
    return foo;
  }
}

// Nested generic local function.
outside<T>() {
  nested<T>(T t) => '';
  return nested;
}

main(args) {
  method1<int>(0);
  method2<String, double>(0.5, 'foo');
  method3<double, String>(1.5, 'bar');
  testMethod4();
  new Class2().method5<int>(0);
  new Class3().method6<int>(0);
  dynamic c3 = args != null ? new Class3() : new Class2();
  c3.method6(0); // Missing type arguments.
  try {
    dynamic c2 = args == null ? new Class3() : new Class2();
    c2.method6(0); // Valid call.
    c2.method6<int>(0); // Extra type arguments.
  } catch (e) {
    print('noSuchMethod: Class2.method6<int>');
    print('');
  }
  var c = new Class4<bool>();
  print((c.method7<int>()).runtimeType);
  outside();
}
''';

const String OUTPUT = r'''
method1:
0 is int = true
"foo" is int = false

method2:
foo is String = true
0.5 is String = false
foo is double = false
0.5 is double = true

method3:
1.5 is double = true
bar is double = false
1.5 is String = false
bar is String = true

method4:
c1 is Class1<int> = true
c2 is Class1<int> = false
c1 is Class1<String> = false
c2 is Class1<String> = true

Class2.method5:
0 is int = true
"foo" is int = false

Class3.method6:
0 is int = true
"foo" is int = false

Class3.method6:
0 is dynamic = true
"foo" is dynamic = true

Class2.method6:
0 is int = true
0 is String = false

noSuchMethod: Class2.method6<int>

(bool, int) => String
''';

main(List<String> args) {
  asyncTest(() async {
    D8Result result = await runWithD8(memorySourceFiles: {
      'main.dart': SOURCE
    }, options: [
      Flags.disableRtiOptimization,
      '--libraries-spec=$sdkLibrariesSpecificationUri',
    ], expectedOutput: OUTPUT, printJs: args.contains('-v'));
    Compiler compiler = result.compilationResult.compiler;
    JsBackendStrategy backendStrategy = compiler.backendStrategy;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

    void checkMethod(String methodName,
        {String className, int expectedParameterCount}) {
      FunctionEntity method;
      if (className != null) {
        ClassEntity cls = elementEnvironment.lookupClass(
            elementEnvironment.mainLibrary, className);
        Expect.isNotNull(cls, "Class '$className' not found.");
        method = elementEnvironment.lookupClassMember(cls, methodName);
        Expect.isNotNull(method, "Method '$methodName' not found in $cls.");
      } else {
        method = elementEnvironment.lookupLibraryMember(
            elementEnvironment.mainLibrary, methodName);
        Expect.isNotNull(method, "Method '$methodName' not found.");
      }
      js.Fun fun = backendStrategy.generatedCode[method];
      Expect.equals(expectedParameterCount, fun.params.length,
          "Unexpected parameter count for $method:\n${js.nodeToString(fun)}");
    }

    checkMethod('method1', expectedParameterCount: 2);
    checkMethod('method2', expectedParameterCount: 4);
    checkMethod('method6', className: 'Class2', expectedParameterCount: 1);
    checkMethod('method6', className: 'Class3', expectedParameterCount: 2);
  });
}
