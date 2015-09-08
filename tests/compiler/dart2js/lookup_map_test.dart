// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.dart2js.lookup_map_test;

import 'package:test/test.dart';
import 'compiler_helper.dart';

main() {
  Map<String, String> testDeclarations = {
    'types': r'''
      import 'package:lookup_map/lookup_map.dart';
      class A {}
      class B {}
      class C {}
      class D {}
      class E {}''',

    'const keys': r'''
      import 'package:lookup_map/lookup_map.dart';
      class Key { final name; const Key(this.name); }
      const A = const Key("A");
      const B = const Key("B");
      const C = const Key("C");
      const D = const Key("D");
      const E = const Key("E");''',

    'mixed keys': r'''
      import 'package:lookup_map/lookup_map.dart';
      class Key { final name; const Key(this.name); }
      const A = const Key("A");
      class B {}
      const C = const Key("C");
      class D {}
      const E = const Key("E");''',
  };

  testDeclarations.forEach((name, declarations) {
    group(name, () => _commonTests(declarations));
  });
  group('generic', _genericTests);
  group('metadata', _metadataTests);
  group('unsupported', _unsupportedKeysTests);
  group('mirrors', _mirrorsTests);
}

/// Common tests for both declarations that use Types or other const expressions
/// as keys. The argument [declaration] should contain a declaration for
/// constant keys named `A`, `B`, `C`, `D`, and `E`.
_commonTests(String declarations) {
  test('live entries are kept', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap(const [
            A, "the-text-for-A",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
  });

  test('live entries are kept - single-pair', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap.pair(A, "the-text-for-A");
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
  });

  test('unused entries are removed', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('unused entries are removed - nested maps', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap(const [], const [
          const LookupMap(const [
              A, "the-text-for-A",
              B, "the-text-for-B",
          ]),
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('unused entries are removed - single-pair', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap.pair(A, "the-text-for-A");
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('unused entries are removed - nested single-pair', () async {
    String generated = await compileAll("""
        import 'package:lookup_map/lookup_map.dart';
        $declarations
        const map = const LookupMap(const [], const [
          const LookupMap.pair(A, "the-text-for-A"),
          const LookupMap.pair(B, "the-text-for-B"),
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('works if entries are declared separate from map', () async {
    String generated = await compileAll("""
        $declarations
        const entries = const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ];
        const map = const LookupMap(entries);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('escaping entries disable tree-shaking', () async {
    String generated = await compileAll("""
        $declarations
        const entries = const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ];
        const map = const LookupMap(entries);
        main() {
          entries.forEach(print);
          print(map[A]);
        }
    """);
    expect(generated, contains("the-text-for-B"));
  });

  test('uses include recursively reachable data', () async {
    String generated = await compileAll("""
        $declarations
        const map = const LookupMap(const [
            A, const ["the-text-for-A", B],
            B, const ["the-text-for-B", C],
            C, const ["the-text-for-C"],
            D, const ["the-text-for-D", E],
            E, const ["the-text-for-E"],
        ]);
        main() => print(map[map[A][1]]);
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, contains("the-text-for-C"));
    expect(generated, isNot(contains("the-text-for-D")));
    expect(generated, isNot(contains("the-text-for-E")));
  });

  test('uses are found through newly discovered code', () async {
    String generated = await compileAll("""
        $declarations
        f1() => map[B][1]();
        f2() => E;
        const map = const LookupMap(const [
            A, const ["the-text-for-A", f1],
            B, const ["the-text-for-B", f2],
            C, const ["the-text-for-C"],
            D, const ["the-text-for-D"],
            E, const ["the-text-for-E"],
        ]);
        main() => print(map[A][1]());
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, isNot(contains("the-text-for-C")));
    expect(generated, isNot(contains("the-text-for-C")));
    expect(generated, contains("the-text-for-E"));
  });

  test('support subclassing LookupMap', () async {
    String generated = await compileAll("""
        $declarations
        class S extends LookupMap {
          const S(list) : super(list);
        }
        const map = const S(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ]);

        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('constants keys are processed recursively', () async {
    String generated = await compileAll("""
        $declarations

        const nested = const [ B ];
        const map = const LookupMap(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ]);
        main() => print(map[nested]);
    """);
    expect(generated, isNot(contains("the-text-for-A")));
    expect(generated, contains("the-text-for-B"));
  });
}

/// Tests specific to type keys, we ensure that generic type arguments are
/// considered.
_genericTests() {
  test('generic type allocations are considered used', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class M<T>{ get type => T; }
        const map = const LookupMap(const [
            A, "the-text-for-A",
        ]);
        main() => print(map[new M<A>().type]);
    """);
    expect(generated, contains("the-text-for-A"));
  });

  test('generics in type signatures are ignored', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
        class M<T>{ get type => T; }
        _factory(M<B> t) => t;
        const map = const LookupMap(const [
            A, const ["the-text-for-A", _factory],
            B, "the-text-for-B",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  // regression test for a failure when looking up `dynamic` in a generic.
  test('do not choke with dynamic type arguments', () async {
    await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class M<T>{ get type => T; }
        const map = const LookupMap(const [
            A, "the-text-for-A",
        ]);
        main() => print(map[new M<dynamic>().type]);
    """);
  });
}

/// Sanity checks about metadata: it is ignored for codegen even though it is
/// visited during resolution.
_metadataTests() {
  test('metadata is ignored', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{ const A(); }

        @A()
        class M {}
        const map = const LookupMap(const [
            A, "the-text-for-A",
        ]);
        main() => print(map[M]);
    """);
    expect(generated, isNot(contains("the-text-for-A")));
  });

  test('shared constants used in metadata are ignored', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        const annot = const B(foo: A);

        @B(foo: annot)
        class A{ const A(); }
        class B{ final Type foo; const B({this.foo}); }

        class M {}
        const map = const LookupMap(const [
            A, const ["the-text-for-A", annot]
        ]);
        main() => print(map[M]);
    """);
    expect(generated, isNot(contains("the-text-for-A")));
  });
}

_unsupportedKeysTests() {
  test('primitive and string keys are always kept', () async {
    String generated = await compileAll("""
        import 'package:lookup_map/lookup_map.dart';
        const A = "A";
        const B = "B";
        const map = const LookupMap(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
            3, "the-text-for-3",
            1.1, "the-text-for-1.1",
            false, "the-text-for-false",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, contains("the-text-for-3"));
    expect(generated, contains("the-text-for-1.1"));
    expect(generated, contains("the-text-for-false"));
  });

  test('non-type const keys implementing equals are not removed', () async {
    String generated = await compileAll("""
        import 'package:lookup_map/lookup_map.dart';
        class Key {
          final name;
          const Key(this.name);
          int get hashCode => name.hashCode * 13;
          operator ==(other) => other is Key && name == other.name;
        }
        const A = const Key("A");
        const B = const Key("B");
        const map = const LookupMap(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-B"));
  });
}

_mirrorsTests() {
  test('retain entries if mirrors keep the type', () async {
    String generated = await compileAll("""
        import 'dart:mirrors';
        import 'package:lookup_map/lookup_map.dart';
        class A {}
        class B {}
        class C {}
        const map = const LookupMap(const [
          A, "the-text-for-A",
          B, "the-text-for-B",
          C, "the-text-for-C",
        ]);
        main() {
          reflectType(A);
          print(map[A]);
        }
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, contains("the-text-for-C"));
  });

  test('exclude entries if MirrorsUsed also exclude the type', () async {
    String generated = await compileAll("""
        library foo;
        @MirrorsUsed(targets: const [B])
        import 'dart:mirrors';
        import 'package:lookup_map/lookup_map.dart';
        class A {}
        class B {}
        class C {}
        const map = const LookupMap(const [
          A, "the-text-for-A",
          B, "the-text-for-B",
          C, "the-text-for-C",
        ]);
        main() {
          reflectType(A);
          print(map[A]);
        }
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, isNot(contains("the-text-for-C")));
  });
}
