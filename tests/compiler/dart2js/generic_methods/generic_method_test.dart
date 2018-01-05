// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js/js.dart' as js;
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../kernel/compiler_helper.dart';

const String SOURCE = r'''
import 'package:meta/dart2js.dart';

// TODO(johnniwinther): Remove these when the needed RTI is correctly computed
// for function type variables.
test(o) => o is double || o is String || o is int;

@noInline
genericMethod1<T>(T t) {
  test(t);
  print('genericMethod1:');
  print('$t is $T = ${t is T}');
  print('"foo" is $T = ${"foo" is T}');
  print('');
}

@noInline
genericMethod2<T, S>(S s, T t) {
  test(t);
  test(s);
  print('genericMethod2:');
  print('$t is $T = ${t is T}');
  print('$s is $T = ${s is T}');
  print('$t is $S = ${t is S}');
  print('$s is $S = ${s is S}');
  print('');
}

@tryInline
genericMethod3<T, S>(T t, S s) {
  test(t);
  test(s);
  print('genericMethod3:');
  print('$t is $T = ${t is T}');
  print('$s is $T = ${s is T}');
  print('$t is $S = ${t is S}');
  print('$s is $S = ${s is S}');
  print('');
}

class Class<T> {
  final int index;

  Class(this.index);

  String toString() => 'c$index';
}

genericMethod4<T>(int index) => new Class<T>(index);

testGenericMethod4() {
  print('genericMethod4:');
  var c1 = genericMethod4<int>(1);
  var c2 = genericMethod4<String>(2);
  print('$c1 is Class<int> = ${c1 is Class<int>}');
  print('$c2 is Class<int> = ${c2 is Class<int>}');
  print('$c1 is Class<String> = ${c1 is Class<String>}');
  print('$c2 is Class<String> = ${c2 is Class<String>}');
  print('');
}

main() {
  genericMethod1<int>(0);
  genericMethod2<String, double>(0.5, 'foo');
  genericMethod3<double, String>(1.5, 'bar');
  testGenericMethod4();
}
''';

const String OUTPUT = r'''
genericMethod1:
0 is int = true
"foo" is int = false

genericMethod2:
foo is String = true
0.5 is String = false
foo is double = false
0.5 is double = true

genericMethod3:
1.5 is double = true
bar is double = false
1.5 is String = false
bar is String = true

genericMethod4:
c1 is Class<int> = true
c2 is Class<int> = false
c1 is Class<String> = false
c2 is Class<String> = true

''';

main(List<String> args) {
  asyncTest(() async {
    Compiler compiler = await runWithD8(
        memorySourceFiles: {'main.dart': SOURCE},
        options: [Flags.useKernel, Flags.strongMode],
        expectedOutput: OUTPUT,
        printJs: args.contains('-v'));
    ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

    void checkMethod(String name, int expectedParameterCount) {
      FunctionEntity function = elementEnvironment.lookupLibraryMember(
          elementEnvironment.mainLibrary, name);
      Expect.isNotNull(function, "Method '$name' not found.");
      js.Fun fun = compiler.backend.generatedCode[function];
      Expect.equals(expectedParameterCount, fun.params.length,
          "Unexpected parameter count for $function:\n${js.nodeToString(fun)}");
    }

    checkMethod('genericMethod1', 2);
    checkMethod('genericMethod2', 4);
  });
}
