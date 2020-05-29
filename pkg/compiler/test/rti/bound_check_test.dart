// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import '../helpers/d8_helper.dart';
import '../helpers/memory_compiler.dart';

const String SOURCE1 = r'''
import 'package:expect/expect.dart';

class A {}
class B {}

method1<T extends A>() {}

class C {
  method2<T, S extends T>() {}
}

main() {
  bool printError(e) {
     print(e); return true;
  }

  method3<T extends B>() {}

  dynamic m1 = method1;
  dynamic m2 = new C().method2;
  dynamic m3 = method3;

  m1<A>();
  Expect.throws(() => m1<B>(), printError);
  m2<A, A>();
  Expect.throws(() => m2<B, A>(), printError);
  m3<B>();
  Expect.throws(() => m3<A>(), printError);
}

''';

const String OUTPUT1 = r'''
TypeError: The type argument 'B' is not a subtype of the type variable bound 'A' of type variable 'T' in 'method1'.
TypeError: The type argument 'A' is not a subtype of the type variable bound 'B' of type variable 'S' in 'method2'.
TypeError: The type argument 'A' is not a subtype of the type variable bound 'B' of type variable 'T' in 'call'.
''';

main(List<String> args) {
  asyncTest(() async {
    await runWithD8(
        memorySourceFiles: {'main.dart': SOURCE1},
        expectedOutput: OUTPUT1,
        printJs: args.contains('-v'),
        options: ['--libraries-spec=$sdkLibrariesSpecificationUri']);
  });
}
