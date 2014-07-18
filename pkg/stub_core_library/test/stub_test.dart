// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stub_core_libraries.test;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stub_core_library/stub_core_library.dart';
import 'package:unittest/unittest.dart';

String sandbox;

main() {
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('stub_core_library_').path;
  });

  tearDown(() => new Directory(sandbox).deleteSync(recursive: true));

  group("imports", () {
    test("dart: imports are preserved by default", () {
      expectStub("""
        import "dart:core";
        import "dart:html";
        import "dart:fblthp";
      """, """
        import "dart:core";
        import "dart:html";
        import "dart:fblthp";
      """);
    });

    test("internal dart: imports are removed", () {
      expectStub("""
        import "dart:_internal";
        import "dart:_blink" as _blink;
        import "dart:_fblthp";
      """, "");
    });

    test("replaced imports are replaced", () {
      expectStub("""
        import "dart:html";
        import "foo.dart" as foo;
      """, """
        import "dart_html.dart";
        import "bar.dart" as foo;
      """, {
        "dart:html": "dart_html.dart",
        "foo.dart": "bar.dart"
      });
    });

    test("exports are replaced as well", () {
      expectStub("""
        export "dart:html";
        export "foo.dart" show foo;
      """, """
        export "dart_html.dart";
        export "bar.dart" show foo;
      """, {
        "dart:html": "dart_html.dart",
        "foo.dart": "bar.dart"
      });
    });
  });

  test("a parted file is stubbed and included inline", () {
    new File(p.join(sandbox, "part.dart")).writeAsStringSync("""
      part of lib;
      void foo() => print('foo!');
    """);

    expectStub("""
      library lib;
      part "part.dart";
    """, """
      library lib;
      void foo() { ${unsupported("foo()")}; }
    """);
  });

  test("a class declaration's native clause is removed", () {
    expectStub("class Foo native 'Foo' {}", "class Foo {}");
  });

  group("constructors", () {
    test("a constructor's body is stubbed out", () {
      expectStub("""
        class Foo {
          Foo() { print("Created a foo!"); }
        }
      """, """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
        }
      """);
    });

    test("a constructor's empty body is stubbed out", () {
      expectStub("class Foo { Foo(); }", """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
        }
      """);
    });

    test("a constructor's external declaration is removed", () {
      expectStub("class Foo { external Foo(); }", """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
        }
      """);
    });

    test("a constructor's field initializers are removed", () {
      expectStub("""
        class Foo {
          final _field1;
          final _field2;

          Foo()
            : _field1 = 1,
              _field2 = 2;
        }
      """, """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
        }
      """);
    });

    test("a constructor's redirecting initializers are removed", () {
      expectStub("""
        class Foo {
          Foo() : this.create();
          Foo.create();
        }
      """, """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
          Foo.create() { ${unsupported("new Foo.create()")}; }
        }
      """);
    });

    test("a constructor's superclass calls are preserved", () {
      expectStub("""
        class Foo {
          Foo(int i, int j, {int k});
        }

        class Bar extends Foo {
          Bar() : super(1, 2, k: 3);
        }
      """, """
        class Foo {
          Foo(int i, int j, {int k}) { ${unsupported("new Foo()")}; }
        }

        class Bar extends Foo {
          Bar()
              : super(${unsupported("new Bar()")}, null) {
            ${unsupported("new Bar()")};
          }
        }
      """);
    });

    test("a constructor's initializing formals are replaced with normal "
        "parameters", () {
      expectStub("""
        class Foo {
          final int _i;
          var _j;
          final List<int> _k;

          Foo(this._i, this._j, this._k);
        }
      """, """
        class Foo {
          Foo(int _i, _j, List<int> _k) { ${unsupported("new Foo()")}; }
        }
      """);
    });

    test("a const constructor isn't stubbed", () {
      expectStub("class Foo { const Foo(); }", "class Foo { const Foo(); }");
    });

    test("a const constructor's superclass calls are fully preserved", () {
      expectStub("""
        class Foo {
          const Foo(int i, int j, int k);
        }

        class Bar extends Foo {
          const Bar() : super(1, 2, 3);
        }
      """, """
        class Foo {
          const Foo(int i, int j, int k);
        }

        class Bar extends Foo {
          const Bar() : super(1, 2, 3);
        }
      """);
    });

    test("a redirecting const constructor stops redirecting", () {
      expectStub("""
        class Foo {
          const Foo.named(int i, int j, int k)
              : this(i, j, k);
          const Foo(int i, int j, int k);
        }
      """, """
        class Foo {
          const Foo.named(int i, int j, int k);
          const Foo(int i, int j, int k);
        }
      """);
    });
  });

  group("functions", () {
    test("stubs a top-level function", () {
      expectStub("void foo() => print('hello!');",
          "void foo() { ${unsupported('foo()')}; }");
    });

    test("stubs a private top-level function", () {
      expectStub("void _foo() => print('hello!');",
          "void _foo() { ${unsupported('_foo()')}; }");
    });

    test("stubs a method", () {
      expectStub("""
        class Foo {
          foo() => print("hello!");
        }
      """, """
        class Foo {
          foo() { ${unsupported('Foo.foo()')}; }
        }
      """);
    });

    test("empties a method in an unconstructable class", () {
      expectStub("""
        class Foo {
          Foo();
          foo() => print("hello!");
        }
      """, """
        class Foo {
          Foo() { ${unsupported('new Foo()')}; }
          foo() {}
        }
      """);
    });

    test("removes a private instance method", () {
      expectStub("""
        class Foo {
          _foo() => print("hello!");
        }
      """, "class Foo {}");
    });

    test("stubs a private static method", () {
      expectStub("""
        class Foo {
          static _foo() => print("hello!");
        }
      """, """
        class Foo {
          static _foo() { ${unsupported('Foo._foo()')}; }
        }
      """);
    });

    test("preserves an abstract instance method", () {
      expectStub("abstract class Foo { foo(); }",
          "abstract class Foo { foo(); }");
    });

    test("removes a native function body", () {
      expectStub("void foo() native 'foo';",
          "void foo() { ${unsupported('foo()')}; }");
    });
  });

  group("top-level fields", () {
    test("stubs out a top-level field", () {
      expectStub("int foo;", """
        int get foo => ${unsupported('foo')};
        set foo(int _) { ${unsupported('foo=')}; }
      """);
    });

    test("stubs out a top-level field with a value", () {
      expectStub("int foo = 12;", """
        int get foo => ${unsupported('foo')};
        set foo(int _) { ${unsupported('foo=')}; }
      """);
    });

    test("stubs out a final top-level field", () {
      expectStub("final int foo = 12;",
          "int get foo => ${unsupported('foo')};");
    });

    test("preserves a const top-level field", () {
      expectStub("const foo = 12;", "const foo = 12;");
    });

    test("removes a private top-level field", () {
      expectStub("int _foo = 12;", "");
    });

    test("preserves a private const top-level field", () {
      expectStub("const _foo = 12;", "const _foo = 12;");
    });

    test("splits a multiple-declaration top-level field", () {
      expectStub("int foo, bar, baz;", """
        int get foo => ${unsupported('foo')};
        set foo(int _) { ${unsupported('foo=')}; }
        int get bar => ${unsupported('bar')};
        set bar(int _) { ${unsupported('bar=')}; }
        int get baz => ${unsupported('baz')};
        set baz(int _) { ${unsupported('baz=')}; }
      """);
    });
  });

  group("instance fields", () {
    test("stubs out an instance field", () {
      expectStub("class Foo { int foo; }", """
        class Foo {
          int get foo => ${unsupported('Foo.foo')};
          set foo(int _) { ${unsupported('Foo.foo=')}; }
        }
      """);
    });

    test("stubs out an instance field with a value", () {
      expectStub("class Foo { int foo = 12; }", """
        class Foo {
          int get foo => ${unsupported('Foo.foo')};
          set foo(int _) { ${unsupported('Foo.foo=')}; }
        }
      """);
    });

    test("stubs out a final instance field", () {
      expectStub("class Foo { final int foo = 12; }", """
        class Foo {
           int get foo => ${unsupported('Foo.foo')};
        }
      """);
    });

    test("removes a private instance field", () {
      expectStub("class Foo { int _foo = 12; }", "class Foo { }");
    });

    test("stubs out a static instance field", () {
      expectStub("class Foo { static int foo = 12; }", """
        class Foo {
           static int get foo => ${unsupported('Foo.foo')};
           static set foo(int _) { ${unsupported('Foo.foo=')}; }
        }
      """);
    });

    test("removes a private static instance field", () {
      expectStub("class Foo { static int _foo = 12; }", "class Foo { }");
    });

    test("preserves a static const instance field", () {
      expectStub("class Foo { static const foo = 12; }",
          "class Foo { static const foo = 12; }");
    });

    test("nulls a field for an unconstructable class", () {
      expectStub("""
        class Foo {
          Foo();
          final foo = 12;
        }
      """, """
        class Foo {
          Foo() { ${unsupported("new Foo()")}; }
          final foo = null;
        }
      """);
    });

    test("splits a multiple-declaration instance field", () {
      expectStub("class Foo { int foo, bar, baz; }", """
        class Foo {
          int get foo => ${unsupported('Foo.foo')};
          set foo(int _) { ${unsupported('Foo.foo=')}; }
          int get bar => ${unsupported('Foo.bar')};
          set bar(int _) { ${unsupported('Foo.bar=')}; }
          int get baz => ${unsupported('Foo.baz')};
          set baz(int _) { ${unsupported('Foo.baz=')}; }
        }
      """);
    });
  });
}

/// Expects that [source] will transform into [expected] when stubbed.
void expectStub(String source, String expected,
    [Map<String, String> importReplacements]) {
  expect(stubCode(source, p.join(sandbox, 'source.dart'), importReplacements),
      equalsIgnoringWhitespace(expected));
}

/// Returns code for throwing an [UnsupportedError] for the given name.
String unsupported(String name) => 'throw new UnsupportedError("$name is '
    'unsupported on this platform.")';
