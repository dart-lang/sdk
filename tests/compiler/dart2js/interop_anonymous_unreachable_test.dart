// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.dart2js.interop_anonymous_unreachable_test;

import 'package:test/test.dart';
import 'compiler_helper.dart';

main() {
  test("unreachable code doesn't crash the compiler", () async {
    // This test is a regression for Issue #24974
    String generated = await compile(
        """
        import 'package:js/js.dart';

        @JS() @anonymous
        class UniqueLongNameForTesting_A {
          external factory UniqueLongNameForTesting_A();
        }
        main() {}
    """,
        returnAll: true);

    // the code should not be included in the output either.
    expect(generated, isNot(contains("UniqueLongNameForTesting_A")));
  });

  group('tree-shaking interop types', () {
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

    test('no tree-shaking by default', () async {
      String generated = await compile(program, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      expect(generated.contains("UniqueLongNameForTesting_D"), isTrue);

      expect(generated.contains("UniqueLongNameForTesting_B"), isTrue);
      expect(generated.contains("UniqueLongNameForTesting_C"), isTrue);
      expect(generated.contains("UniqueLongNameForTesting_E"), isTrue);
    });

    test('tree-shake when using flag', () async {
      String generated = await compile(program,
          trustJSInteropTypeAnnotations: true, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      expect(generated.contains("UniqueLongNameForTesting_D"), isTrue);

      expect(generated.contains("UniqueLongNameForTesting_B"), isFalse);
      expect(generated.contains("UniqueLongNameForTesting_C"), isFalse);
      expect(generated.contains("UniqueLongNameForTesting_E"), isFalse);
    });
  });

  group('tree-shaking other native types', () {
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

    test('allocation effect of dynamic excludes native types', () async {
      String generated = await compile(program, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      // any js-interop type could be allocated by `get x`
      expect(generated.contains("UniqueLongNameForTesting_B"), isTrue);
      // but we exclude other native types like HTMLAudioElement
      expect(generated.contains("HTMLAudioElement"), isFalse);
    });

    test('allocation effect of dynamic excludes native types [flag]', () async {
      // Trusting types doesn't make a difference.
      String generated = await compile(program,
          trustJSInteropTypeAnnotations: true, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      expect(generated.contains("UniqueLongNameForTesting_B"), isTrue);
      expect(generated.contains("HTMLAudioElement"), isFalse);
    });

    test('declared native types are included in allocation effect', () async {
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

      String generated = await compile(program2, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      expect(generated.contains("HTMLAudioElement"), isTrue);

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

      generated = await compile(program2, returnAll: true);
      expect(generated.contains("UniqueLongNameForTesting_A"), isTrue);
      // This extra check is to make sure that we don't include HTMLAudioElement
      // just because of the is-check. It is optimized away in this case because
      // we believe it was never instantiated.
      expect(generated.contains("HTMLAudioElement"), isFalse);
    });
  });
}
