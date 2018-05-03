// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import '../kernel/compiler_helper.dart';

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

const String SOURCE2 = r'''
import 'package:expect/expect.dart';

class A {}
class B {}

class C<T extends A>{
}

class D<T> extends C<T> {}

main() {
  bool printError(e) {
     print(e); return true;
  }

  new C<A>();
  Expect.throws(() => new C<B>(), printError);
  new D<A>();
  Expect.throws(() => new D<B>(), printError);
}
''';

const String OUTPUT2 = r'''
TypeError: Can't create an instance of malbounded type 'C<B>': 'B' is not a subtype of bound 'A' type variable 'C.T' of type 'C<C.T>'.
TypeError: Can't create an instance of malbounded type 'D<B>': 'B' is not a subtype of bound 'A' type variable 'C.T' of type 'C<C.T>' on the supertype 'C<B>' of 'D<B>'.
''';

main(List<String> args) {
  asyncTest(() async {
    await runWithD8(memorySourceFiles: {
      'main.dart': SOURCE1
    }, options: [
      Flags.strongMode,
    ], expectedOutput: OUTPUT1, printJs: args.contains('-v'));
    await runWithD8(
        memorySourceFiles: {'main.dart': SOURCE2},
        options: [Flags.enableCheckedMode],
        expectedOutput: OUTPUT2,
        printJs: args.contains('-v'));
  });
}
