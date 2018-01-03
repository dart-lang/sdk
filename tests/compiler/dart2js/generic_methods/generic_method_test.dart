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
test(o) => o is double || o is String || o is int;

genericMethod1<T>(T t) {
  test(t);
  print('genericMethod1:');
  print('$t is $T = ${t is T}');
  print('"foo" is $T = ${"foo" is T}');
  print('');
}

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

main() {
  genericMethod1<int>(0);
  genericMethod2<String, double>(0.5, 'foo');
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

''';

main(List<String> args) {
  asyncTest(() async {
    Compiler compiler = await runWithD8(
        memorySourceFiles: {'main.dart': SOURCE},
        options: [Flags.useKernel, Flags.strongMode, Flags.disableInlining],
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
