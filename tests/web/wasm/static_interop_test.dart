// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util';
import 'package:expect/expect.dart';
import 'package:js/js.dart';
import 'static_interop_library.dart';

@JS()
external void eval(String code);

@JS('JSClass')
@staticInterop
class StaticJSClass {
  external factory StaticJSClass.factory(String foo);

  external static String externalStaticMethod();
  static String staticMethod() => 'bar';
}

extension StaticJSClassMethods on StaticJSClass {
  external String foo;
  external String sum(String a, String? b, String c);
  external void doublifyNumbers();
  external set nonNullableInt(int d);
  external int get nonNullableInt;
  external set nullableInt(int? d);
  external int? get nullableInt;
  external int nonNullableIntReturnMethod();
  external int? nullableIntReturnMethod(bool returnNull);
  external String doSum1Or2(String a, [String? b]);
  external String doSumUpTo2([String? a, String? b]);
  external String doSum1Or2NonNull(String a, [String b = 'bar']);
  external String doSumUpTo2NonNull([String a = 'foo', String b = 'bar']);
  external int doIntSum1Or2(int a, [int? b]);
  external int doIntSumUpTo2([int? a, int? b]);
  external int doIntSum1Or2NonNull(int a, [int b = 2]);
  external int doIntSumUpTo2NonNull([int a = 1, int b = 2]);

  @JS('nameInJSMethod')
  external String nameInDartMethod(String a, String b);
  @JS('nameInJSGetter')
  external String get nameInDartGetter;
  @JS('nameInJSSetter')
  external set nameInDartSetter(String v);
  external String get nameInJSSetter;
}

void createClassTest() {
  eval(r'''
    globalThis.JSClass = function(foo) {
      this.foo = foo;
      this.nonNullableInt = 6;
      this.nameInJSGetter = 'foo';
      this.nonNullableIntReturnMethod = function() {
        return 7;
      }
      this.nullableIntReturnMethod = function(returnNull) {
        if (returnNull) {
          return null;
        } else {
          return 8;
        }
      }
      this.sum = function(a, b, c) {
        if (b == null) b = ' ';
        return a + b + c;
      }
      this.doublifyNumbers = function() {
        this.nonNullableInt = 60.5;
        this.nullableInt = 100.5;
      }
      this.doSum1Or2 = function(a, b) {
        return a + (b ?? 'bar');
      }
      this.doSumUpTo2 = function(a, b) {
        return (a ?? 'foo') + (b ?? 'bar');
      }
      this.doSum1Or2NonNull = function(a, b) {
        return (a ?? 'foo') + (b ?? 'bar');
      }
      this.doSumUpTo2NonNull = function(a, b) {
        return (a ?? 'foo') + (b ?? 'bar');
      }
      this.doIntSum1Or2 = function(a, b) {
        return a + (b ?? 2);
      }
      this.doIntSumUpTo2 = function(a, b) {
        return (a ?? 1) + (b ?? 2);
      }
      this.doIntSum1Or2NonNull = function(a, b) {
        return a + (b ?? 2);
      }
      this.doIntSumUpTo2NonNull = function(a, b) {
        return (a ?? 1) + (b ?? 2);
      }
      this.nameInJSMethod = function(a, b) {
        return a + b;
      }
    }
    globalThis.JSClass.externalStaticMethod = function() {
      return 'foo';
    }

    globalThis.library = function() {}
    globalThis.library.libraryTopLevelGetter = 'foo';
    globalThis.library.jsedLibraryTopLevelGetter = 'foo';
    globalThis.library.NamespacedClass = function() {
      this.member = function() {
        return 'foo';
      }
    }
  ''');
  Expect.equals('foo', StaticJSClass.externalStaticMethod());
  Expect.equals('bar', StaticJSClass.staticMethod());

  final foo = StaticJSClass.factory('foo');
  Expect.equals('foo', foo.foo);
  foo.foo = 'bar';
  Expect.equals('bar', foo.foo);
  Expect.equals('hello world!!', foo.sum('hello', null, 'world!!'));
  Expect.equals(null, foo.nullableInt);
  foo.nullableInt = 5;
  Expect.equals(5, foo.nullableInt);
  Expect.equals(6, foo.nonNullableInt);
  foo.nonNullableInt = 16;
  Expect.equals(16, foo.nonNullableInt);
  Expect.equals(7, foo.nonNullableIntReturnMethod());
  Expect.equals(8, foo.nullableIntReturnMethod(false));
  Expect.equals(null, foo.nullableIntReturnMethod(true));
  foo.doublifyNumbers();
  Expect.equals(100, foo.nullableInt);
  Expect.equals(60, foo.nonNullableInt);

  Expect.equals('foobar', foo.doSum1Or2('foo'));
  Expect.equals('foobar', foo.doSum1Or2('foo', 'bar'));
  Expect.equals('foobar', foo.doSumUpTo2());
  Expect.equals('foobar', foo.doSumUpTo2('foo'));
  Expect.equals('foobar', foo.doSumUpTo2('foo', 'bar'));

  Expect.equals('foobar', foo.doSum1Or2NonNull('foo'));
  Expect.equals('foobar', foo.doSum1Or2NonNull('foo', 'bar'));
  Expect.equals('foobar', foo.doSumUpTo2NonNull());
  Expect.equals('foobar', foo.doSumUpTo2NonNull('foo'));
  Expect.equals('foobar', foo.doSumUpTo2NonNull('foo', 'bar'));

  Expect.equals(3, foo.doIntSum1Or2(1));
  Expect.equals(3, foo.doIntSum1Or2(1, 2));
  Expect.equals(3, foo.doIntSumUpTo2());
  Expect.equals(3, foo.doIntSumUpTo2(1));
  Expect.equals(3, foo.doIntSumUpTo2(1, 2));

  Expect.equals(3, foo.doIntSum1Or2NonNull(1));
  Expect.equals(3, foo.doIntSum1Or2NonNull(1, 2));
  Expect.equals(3, foo.doIntSumUpTo2NonNull());
  Expect.equals(3, foo.doIntSumUpTo2NonNull(1));
  Expect.equals(3, foo.doIntSumUpTo2NonNull(1, 2));

  Expect.equals('foobar', foo.nameInDartMethod('foo', 'bar'));
  Expect.equals('foo', foo.nameInDartGetter);
  foo.nameInDartSetter = 'boo';
  Expect.equals('boo', foo.nameInJSSetter);

  Expect.equals('foo', NamespacedClass().member());
  Expect.equals('foo', libraryTopLevelGetter);
  Expect.equals('foo', libraryOtherTopLevelGetter);
}

@JS('JSClass.NestedJSClass')
@staticInterop
class NestedJSClass {
  external factory NestedJSClass.factory(String foo);
}

extension NestedJSClassMethods on NestedJSClass {
  external String foo;
}

void createClassWithNestedJSNameTest() {
  eval(r'''
    globalThis.JSClass = {};
    globalThis.JSClass.NestedJSClass = function(foo) {
      this.foo = foo;
    };
  ''');
  final foo = NestedJSClass.factory('foo');
  Expect.equals(foo.foo, 'foo');
}

@JS('JSParent')
@staticInterop
class StaticJSParent {
  external factory StaticJSParent.factory();
}

extension StaticJSParentMethods on StaticJSParent {
  external set child(StaticJSChild child);
  external String childsFoo();
}

@JS('JSChild')
@staticInterop
class StaticJSChild {
  external factory StaticJSChild.factory();
}

extension StaticJSChildMethods on StaticJSChild {
  external set foo(String s);
}

void setInteropPropertyTest() {
  eval(r'''
    globalThis.JSParent = function() {
      this.child = null;
      this.childsFoo = () => {
        return this.child.foo;
      }
    }

    globalThis.JSChild = function() {
      this.foo = null;
    }
  ''');

  final parent = StaticJSParent.factory();
  final child = StaticJSChild.factory();
  parent.child = child;
  child.foo = 'boo';
  Expect.equals('boo', parent.childsFoo());
}

class DartObject {
  final int x;

  DartObject(this.x);
}

@JS('JSHolder')
@staticInterop
class StaticJSHolder {
  external factory StaticJSHolder.factory(DartObject object);
}

extension StaticJSHolderMethods on StaticJSHolder {
  external DartObject foo;
}

void setDartObjectPropertyTest() {
  eval(r'''
    globalThis.JSHolder = function(foo) {
      this.foo = foo;
    }
  ''');
  final traveler = DartObject(4);
  final holder = StaticJSHolder.factory(traveler);
  Expect.equals(traveler, holder.foo);
}

@JS()
external String get foo;

@JS()
external String? get blu;

@JS('')
external void set baz(String);

@JS('boo.bar')
external String get bam;

@JS('bar')
external String fooBar(String);

void topLevelMethodsTest() {
  eval(r'''
    globalThis.foo = 'bar';
    globalThis.baz = null;
    globalThis.boo = {
      'bar': 'jam'
    }
    globalThis.bar = function(string) {
      return string + ' ' + globalThis.baz;
    }
  ''');

  Expect.equals(foo, 'bar');
  Expect.equals(blu, null);
  Expect.equals(bam, 'jam');
  baz = 'world!';
  Expect.equals(fooBar('hello'), 'hello world!');
}

@JS()
@anonymous
@staticInterop
class AnonymousJSClass {
  external factory AnonymousJSClass.factory(
      {String? foo,
      String bar = 'baz',
      String? bleep,
      int? goo,
      int ooo = 1,
      List<double>? saz,
      List<double> zoo = const [1.0, 2.0]});
}

extension AnonymousJSClassExtension on AnonymousJSClass {
  external String? get foo;
  external String? get bar;
  external String? get bleep;
  external int? get goo;
  external int? get ooo;
  external List<Object?>? saz;
  external List<double>? zoo;
}

void anonymousTest() {
  final anonymousJSClass = AnonymousJSClass.factory(
      foo: 'boo', bleep: 'bleep', saz: const [1.0, 2.0], goo: 0);
  Expect.equals('boo', anonymousJSClass.foo);
  Expect.equals(null, anonymousJSClass.bar);
  Expect.equals('bleep', anonymousJSClass.bleep);
  Expect.equals(0, anonymousJSClass.goo);
  Expect.equals(null, anonymousJSClass.ooo);
  Expect.listEquals(const [1.0, 2.0], anonymousJSClass.saz!);
  Expect.equals(null, anonymousJSClass.zoo);
}

@JS()
@anonymous
@staticInterop
class AnonymousRedirectJSClass {
  external factory AnonymousRedirectJSClass._({String Function(String)? foo});

  factory AnonymousRedirectJSClass.concrete(String Function(String) foo) =>
      AnonymousRedirectJSClass._(foo: allowInterop(foo));
}

extension AnonymousRedirectJSClassExtension on AnonymousRedirectJSClass {
  external String foo(String bar);
}

void concreteFactoryConstructorTest() {
  final anonymousRedirectJSClass =
      AnonymousRedirectJSClass.concrete((String bar) => bar + bar);
  Expect.equals('foofoo', anonymousRedirectJSClass.foo('foo'));
}

@JS()
@staticInterop
class JSArray {}

extension JSArrayExtension on JSArray {
  external Object? operator [](int index);
  external int get length;
  external String get deoptKey;
}

@JS()
external JSArray get arrayObject;

void staticInteropBypassConversionTest() {
  eval(r'''
    globalThis.arrayObject = ['1', '2'];
    globalThis.arrayObject.deoptKey = 'foo';
  ''');

  JSArray a = arrayObject;
  Expect.isTrue(instanceOfString(a, "Array"));
  Expect.equals(2, a.length);
  Expect.equals('foo', a.deoptKey);
}

void main() {
  createClassTest();
  createClassWithNestedJSNameTest();
  setInteropPropertyTest();
  setDartObjectPropertyTest();
  topLevelMethodsTest();
  anonymousTest();
  concreteFactoryConstructorTest();
  staticInteropBypassConversionTest();
}
