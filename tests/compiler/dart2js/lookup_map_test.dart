// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.dart2js.lookup_map_test;

import 'package:test/test.dart';
import 'compiler_helper.dart';

main() {
  test('live entries are kept', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        const map = const LookupMap(const [
            A, "the-text-for-A",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
  });

  test('live entries are kept - single-pair', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        const map = const LookupMap.pair(A, "the-text-for-A");
        main() => print(map[A]);
    """);
    expect(generated, contains("the-text-for-A"));
  });

  test('unused entries are removed', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
        const map = const LookupMap(const [
            A, "the-text-for-A",
            B, "the-text-for-B",
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('unused entries are removed - nested maps', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
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
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
        const map = const LookupMap.pair(A, "the-text-for-A");
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('unused entries are removed - nested single-pair', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
        const map = const LookupMap(const [], const [
          const LookupMap.pair(A, "the-text-for-A"),
          const LookupMap.pair(B, "the-text-for-B"),
        ]);
        main() => print(map[A]);
    """);
    expect(generated, isNot(contains("the-text-for-B")));
  });

  test('works if entries are declared separate from map', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
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
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
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
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
        class C{}
        class D{}
        class E{}
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
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{ A(B x);}
        class B{}
        class C{}
        class D{}
        class E{}
        createA() => new A(map[B][1]());
        createB() => new B();
        const map = const LookupMap(const [
            A, const ["the-text-for-A", createA],
            B, const ["the-text-for-B", createB],
            C, const ["the-text-for-C"],
        ]);
        main() => print(map[A][1]());
    """);
    expect(generated, contains("the-text-for-A"));
    expect(generated, contains("the-text-for-B"));
    expect(generated, isNot(contains("the-text-for-C")));
  });

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

  // regression test for a failure when looking up `dynamic` in a generic.
  test('do not choke on dynamic types', () async {
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


  test('support subclassing LookupMap', () async {
    String generated = await compileAll(r"""
        import 'package:lookup_map/lookup_map.dart';
        class A{}
        class B{}
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
}
