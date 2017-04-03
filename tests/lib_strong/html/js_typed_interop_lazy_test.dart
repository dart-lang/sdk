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

// This class would cause compile time issues if JS classes are not properly lazy.
class FooImpl extends Foo<LazyClass> {
  LazyClass get obj => new LazyClass(100);
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
      document.body.append(new ScriptElement()
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
      var anon = new AnonClass(a: 42);
      expect(anon is! LazyClass, isTrue);
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
      expect(<AnonClass>[] is! List<LazyClass>, isTrue);
      expect(<int>[] is! List<LazyClass>, isTrue);
      expect(<LazyClass>[] is List<LazyClass>, isTrue);

      var listLazyClass = <LazyClass>[];
      Object instanceLazyObject = l;
      expect(() => listLazyClass.add(42 as dynamic), throws);
      // Regression test for bug where this call failed.
      listLazyClass.add(instanceLazyObject);
      listLazyClass.add(null);

      dynamic listLazyClassDynamic = listLazyClass;
      expect(() => listLazyClassDynamic.add(42), throws);
      // Regression test for bug where this call failed.
      listLazyClassDynamic.add(instanceLazyObject);
      listLazyClassDynamic.add(null);

      var genericClass = new ExampleGenericClass<LazyClass>();
      genericClass.add(instanceLazyObject);
      expect(() => genericClass.add(42 as dynamic), throws);
      genericClass.add(null);

      dynamic genericClassDynamic = genericClass;
      genericClassDynamic.add(instanceLazyObject);
      expect(() => genericClassDynamic.add(42), throws);
      genericClassDynamic.add(null);
    });
  });
}
