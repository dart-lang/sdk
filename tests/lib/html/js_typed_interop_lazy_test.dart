// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_lazy_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS('someProperty')
external get foo;

@JS('baz.bar')
external get bar;

@JS('baz.LazyClass')
class LazyClass {
  external factory LazyClass(a);
  external get a;
}

@JS('baz.foo.NestedLazyClass')
class NestedLazyClass {
  external factory NestedLazyClass(a);
  external get a;
}

@anonymous
@JS('some.bogus.ignored.js.path')
class AnonClass {
  external factory AnonClass({a});
  external get a;
}

@anonymous
@JS()
class AnonClass2 {
  external factory AnonClass2({b});
  external get b;
}

abstract class Foo<T> {
  T get obj;
}

class Mock1LazyClass implements LazyClass {
  noSuchMethod(Invocation i) => i.memberName == #a ? 42 : null;
}

class Mock2LazyClass implements LazyClass {
  get a => 42;
}

class Mock1NestedLazyClass implements NestedLazyClass {
  noSuchMethod(Invocation i) => i.memberName == #a ? 42 : null;
}

class Mock2NestedLazyClass implements NestedLazyClass {
  get a => 42;
}

class Other {
  noSuchMethod(Invocation i) {}
}

// Test that the lazy JS classes can be used as a generic type argument.
class FooImpl extends Foo<LazyClass> {
  LazyClass get obj => new LazyClass(100);
}

class NestedFooImpl extends Foo<NestedLazyClass> {
  NestedLazyClass get obj => new NestedLazyClass(100);
}

class ExampleGenericClass<T> {
  String add(T foo) {
    return foo.toString();
  }
}

main() {
  group('lazy property', () {
    test('simple', () {
      expect(foo, isNull);
      js_util.setProperty(window, 'someProperty', 42);
      expect(foo, equals(42));
    });

    test('nested', () {
      js_util.setProperty(window, 'baz', js_util.newObject());
      expect(bar, isNull);
      js_util.setProperty(window, 'baz', js_util.jsify({'bar': 100}));
      expect(bar, equals(100));
    });
  });

  group('lazy class', () {
    test('type literal', () {
      // Fine because we can determine the class literals are equal without
      // having to determine what (non-existant) JS type they correspond to.
      var x = LazyClass;
      var y = LazyClass;
      expect(x == y, isTrue);
    });

    test('reference in type parameter', () {
      var o = new FooImpl();
      expect(o is Foo<LazyClass>, isTrue);
    });

    test('create instance', () {
      var anon = new AnonClass(a: 42);
      // Until LazyClass is defined, fall back to Anon behavior.
      expect(anon is LazyClass, isTrue); //# 01: ok
      expect(new Object() is! LazyClass, isTrue);

      document.body!.append(new ScriptElement()
        ..type = 'text/javascript'
        ..innerHtml = r"""
window.baz = {};

baz.LazyClass = function LazyClass(a) {
  this.a = a;
};
""");
      var l = new LazyClass(42);
      expect(l.a, equals(42));
      expect(l is LazyClass, isTrue);
      expect(l is AnonClass, isTrue);
      expect((l as AnonClass) == l, isTrue);
      expect((l as AnonClass2) == l, isTrue);
      expect(anon is AnonClass, isTrue);
      expect(anon is AnonClass2, isTrue);

      // Sanity check that is and as are not broken.
      expect(new Object() is! LazyClass, isTrue);
      expect(new Object() is! AnonClass, isTrue);
      expect(new Object() is! AnonClass2, isTrue);

      expect(<AnonClass>[] is List<AnonClass>, isTrue);
      // TODO(jacobr): why doesn't this test pass?
      // expect(<AnonClass>[] is List<AnonClass2>, isTrue);
      expect(<int>[] is! List<AnonClass>, isTrue);
      expect(<AnonClass>[] is! List<LazyClass>, isTrue); //# 01: ok
      expect(<int>[] is! List<LazyClass>, isTrue);
      expect(<LazyClass>[] is List<LazyClass>, isTrue);

      var listLazyClass = <LazyClass?>[];
      Object instanceLazyObject = l;
      expect(() => listLazyClass.add(42 as dynamic), throws); //# 01: ok
      // Regression test for bug where this call failed.
      listLazyClass.add(instanceLazyObject as LazyClass?);
      listLazyClass.add(null);

      dynamic listLazyClassDynamic = listLazyClass;
      expect(() => listLazyClassDynamic.add(42), throws); //# 01: ok
      // Regression test for bug where this call failed.
      listLazyClassDynamic.add(instanceLazyObject);
      listLazyClassDynamic.add(null);

      var genericClass = new ExampleGenericClass<LazyClass?>();
      genericClass.add(instanceLazyObject as LazyClass?);
      expect(() => genericClass.add(42 as dynamic), throws); //# 01: ok
      genericClass.add(null);

      dynamic genericClassDynamic = genericClass;
      genericClassDynamic.add(instanceLazyObject);
      expect(() => genericClassDynamic.add(42), throws); //# 01: ok
      genericClassDynamic.add(null);
    });

    test('mocks', () {
      var mock1 = new Mock1LazyClass();
      expect(mock1 is LazyClass, isTrue);
      expect((mock1 as dynamic) as LazyClass, equals(mock1));
      expect(mock1.a, equals(42));

      var mock2 = new Mock2LazyClass();
      expect(mock2 is LazyClass, isTrue);
      expect((mock2 as dynamic) as LazyClass, equals(mock2));
      expect(mock2.a, equals(42));

      Object other = new Other();
      expect(other is LazyClass, isFalse);
    });
  });

  group('nested lazy class', () {
    test('type literal', () {
      // Fine because we can determine the class literals are equal without
      // having to determine what (non-existant) JS type they correspond to.
      var x = NestedLazyClass;
      var y = NestedLazyClass;
      expect(x == y, isTrue);
    });

    test('reference in type parameter', () {
      var o = new NestedFooImpl();
      expect(o is Foo<NestedLazyClass>, isTrue);
    });

    test('create instance', () {
      var anon = new AnonClass(a: 42);
      // Until NestedLazyClass is defined, fall back to Anon behavior.
      expect(anon is NestedLazyClass, isTrue); //# 01: ok
      expect(new Object() is! NestedLazyClass, isTrue);

      document.body!.append(new ScriptElement()
        ..type = 'text/javascript'
        ..innerHtml = r"""
window.baz = window.baz || {};
window.baz.foo = {};

baz.foo.NestedLazyClass = function NestedLazyClass(a) {
  this.a = a;
};
""");
      var l = new NestedLazyClass(42);
      expect(l.a, equals(42));
      expect(l is NestedLazyClass, isTrue);
      expect(l is AnonClass, isTrue);
      expect((l as AnonClass) == l, isTrue);
      expect((l as AnonClass2) == l, isTrue);
      expect(anon is AnonClass, isTrue);
      expect(anon is AnonClass2, isTrue);

      // Sanity check that is and as are not broken.
      expect(new Object() is! NestedLazyClass, isTrue);
      expect(new Object() is! AnonClass, isTrue);
      expect(new Object() is! AnonClass2, isTrue);

      expect(<AnonClass>[] is List<AnonClass>, isTrue);
      // TODO(jacobr): why doesn't this test pass?
      // expect(<AnonClass>[] is List<AnonClass2>, isTrue);
      expect(<int>[] is! List<AnonClass>, isTrue);
      expect(<AnonClass>[] is! List<NestedLazyClass>, isTrue); //# 01: ok
      expect(<int>[] is! List<NestedLazyClass>, isTrue);
      expect(<NestedLazyClass>[] is List<NestedLazyClass>, isTrue);

      var listLazyClass = <NestedLazyClass?>[];
      Object instanceLazyObject = l;
      expect(() => listLazyClass.add(42 as dynamic), throws); //# 01: ok
      // Regression test for bug where this call failed.
      listLazyClass.add(instanceLazyObject as NestedLazyClass?);
      listLazyClass.add(null);

      dynamic listLazyClassDynamic = listLazyClass;
      expect(() => listLazyClassDynamic.add(42), throws); //# 01: ok
      // Regression test for bug where this call failed.
      listLazyClassDynamic.add(instanceLazyObject);
      listLazyClassDynamic.add(null);

      var genericClass = new ExampleGenericClass<NestedLazyClass?>();
      genericClass.add(instanceLazyObject as NestedLazyClass?);
      expect(() => genericClass.add(42 as dynamic), throws); //# 01: ok
      genericClass.add(null);

      dynamic genericClassDynamic = genericClass;
      genericClassDynamic.add(instanceLazyObject);
      expect(() => genericClassDynamic.add(42), throws); //# 01: ok
      genericClassDynamic.add(null);
    });

    test('mocks', () {
      var mock1 = new Mock1NestedLazyClass();
      expect(mock1 is NestedLazyClass, isTrue);
      expect((mock1 as dynamic) as NestedLazyClass, equals(mock1));
      expect(mock1.a, equals(42));

      var mock2 = new Mock2NestedLazyClass();
      expect(mock2 is NestedLazyClass, isTrue);
      expect((mock2 as dynamic) as NestedLazyClass, equals(mock2));
      expect(mock2.a, equals(42));

      Object other = new Other();
      expect(other is NestedLazyClass, isFalse);
    });
  });
}
