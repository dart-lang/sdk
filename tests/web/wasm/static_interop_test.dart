// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util_wasm';
import 'dart:js_wasm';

import 'package:expect/expect.dart';

@JS('JSClass')
@staticInterop
class StaticJSClass {
  external factory StaticJSClass.factory(String foo);
}

extension StaticJSClassMethods on StaticJSClass {
  external String foo;
  external String sum(String a, String? b, String c);
}

void createClassTest() {
  eval(r'''
    globalThis.JSClass = function(foo) {
      this.foo = foo;
      this.sum = function(a, b, c) {
        if (b == null) b = ' ';
        return a + b + c;
      }
    }
  ''');
  final foo = StaticJSClass.factory('foo');
  Expect.equals(foo.foo, 'foo');
  foo.foo = 'bar';
  Expect.equals(foo.foo, 'bar');
  Expect.equals('hello world!!', foo.sum('hello', null, 'world!!'));
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

void main() {
  createClassTest();
  setInteropPropertyTest();
  setDartObjectPropertyTest();
}
