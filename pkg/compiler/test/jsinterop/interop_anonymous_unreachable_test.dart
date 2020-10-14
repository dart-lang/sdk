// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library tests.dart2js.interop_anonymous_unreachable_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

testUnreachableCrash() async {
  print("-- unreachable code doesn't crash the compiler --");
  // This test is a regression for Issue #24974
  String generated = await compile("""
        import 'package:js/js.dart';

        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external factory UniqueLongNameForTesting_A();
        }
        main() {}
    """, returnAll: true);

  // the code should not be included in the output either.
  Expect.isFalse(generated.contains("UniqueLongNameForTesting_A"));
}

testTreeShakingJsInteropTypes() async {
  print('-- tree-shaking interop types --');
  String program = """
        import 'package:js/js.dart';

        // reachable and allocated
        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external bool get x;
          external UniqueLongNameForTesting_D get d;
          external UniqueLongNameForTesting_E get e;
          external factory UniqueLongNameForTesting_A(
              {UniqueLongNameForTesting_B arg0});
        }

        // visible through the parameter above, but not used.
        @JS() @anonymous
        class UniqueLongNameForTesting_B {
          external factory UniqueLongNameForTesting_B();
        }

        // unreachable
        @JS() @anonymous
        class UniqueLongNameForTesting_C {
          external factory UniqueLongNameForTesting_C();
        }

        // visible and reached through `d`.
        @JS() @anonymous
        class UniqueLongNameForTesting_D {
          external factory UniqueLongNameForTesting_D();
        }

        // visible through `e`, but not reached.
        @JS() @anonymous
        class UniqueLongNameForTesting_E {
          external factory UniqueLongNameForTesting_E();
        }

        main() {
          print(new UniqueLongNameForTesting_A().x);
          print(new UniqueLongNameForTesting_A().d);
        }
    """;

  print(' - no tree-shaking by default -');
  String generated1 = await compile(program, returnAll: true);
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_A"));
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_D"));

  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_B"));
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_C"));
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_E"));
}

testTreeShakingNativeTypes() async {
  print('-- tree-shaking other native types --');

  String program = """
        import 'dart:html';
        import 'package:js/js.dart';

        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external dynamic get x;
        }

        @JS() @anonymous
        class UniqueLongNameForTesting_B {
          external dynamic get y;
        }

        main() {
          print(new UniqueLongNameForTesting_A().x);
        }
    """;

  print(' - allocation effect of dynamic excludes native types -');
  String generated1 = await compile(program, returnAll: true);
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_A"));
  // any js-interop type could be allocated by `get x`
  Expect.isTrue(generated1.contains("UniqueLongNameForTesting_B"));
  // but we exclude other native types like HTMLAudioElement
  Expect.isFalse(generated1.contains("HTMLAudioElement"));

  print(' - declared native types are included in allocation effect -');
  String program2 = """
        import 'dart:html';
        import 'package:js/js.dart';

        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external AudioElement get x;
        }

        main() {
          print(new UniqueLongNameForTesting_A().x is AudioElement);
        }
    """;

  String generated3 = await compile(program2, returnAll: true);
  Expect.isTrue(generated3.contains("UniqueLongNameForTesting_A"));
  Expect.isTrue(generated3.contains("HTMLAudioElement"));

  program2 = """
        import 'dart:html';
        import 'package:js/js.dart';

        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external dynamic get x;
        }

        main() {
          print(new UniqueLongNameForTesting_A().x is AudioElement);
        }
    """;

  generated3 = await compile(program2, returnAll: true);
  Expect.isTrue(generated3.contains("UniqueLongNameForTesting_A"));
  // This extra check is to make sure that we don't include HTMLAudioElement
  // just because of the is-check. It is optimized away in this case because
  // we believe it was never instantiated.
  Expect.isFalse(generated3.contains("HTMLAudioElement"));
}

main() {
  runTests() async {
    await testUnreachableCrash();
    await testTreeShakingJsInteropTypes();
    await testTreeShakingNativeTypes();
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
