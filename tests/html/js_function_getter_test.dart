// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_function_getter_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/html_individual_config.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var bar = { };

  bar.instanceMember = function() {
    if (this !== bar) {
      throw 'Unexpected this!';
    }
    return arguments.length;
  };

  bar.staticMember = function() {
    return arguments.length * 2;
  };

  bar.dynamicStatic = function() {
    return arguments.length;
  };

  bar.add = function(a, b) {
    return a + b;
  };

  var foo = { 'bar' : bar };
""");
}

typedef int AddFn(int x, int y);

@JS()
abstract class Bar {
  external Function get staticMember;
  external Function get instanceMember;
  external AddFn get add;
  external get dynamicStatic;
  external num get nonFunctionStatic;
}

@JS()
abstract class Foo {
  external Bar get bar;
}

@JS()
external Foo get foo;

main() {
  _injectJs();

  useHtmlIndividualConfiguration();

  group('call getter as function', () {
    test('member function', () {
      expect(foo.bar.instanceMember(), equals(0));
      expect(foo.bar.instanceMember(0), equals(1));
      expect(foo.bar.instanceMember(0, 0), equals(2));
      expect(foo.bar.instanceMember(0, 0, 0, 0, 0, 0), equals(6));
      var instanceMember = foo.bar.instanceMember;
      expect(() => instanceMember(), throws);
      expect(() => instanceMember(0), throws);
      expect(() => instanceMember(0, 0), throws);
      expect(() => instanceMember(0, 0, 0, 0, 0, 0), throws);
    });

    test('static function', () {
      expect(foo.bar.staticMember(), equals(0));
      expect(foo.bar.staticMember(0), equals(2));
      expect(foo.bar.staticMember(0, 0), equals(4));
      expect(foo.bar.staticMember(0, 0, 0, 0, 0, 0), equals(12));
      var staticMember = foo.bar.staticMember;
      expect(staticMember(), equals(0));
      expect(staticMember(0), equals(2));
      expect(staticMember(0, 0), equals(4));
      expect(staticMember(0, 0, 0, 0, 0, 0), equals(12));
    });

    test('static dynamicStatic', () {
      expect(foo.bar.dynamicStatic(), equals(0));
      expect(foo.bar.dynamicStatic(0), equals(1));
      expect(foo.bar.dynamicStatic(0, 0), equals(2));
      expect(foo.bar.dynamicStatic(0, 0, 0, 0, 0, 0), equals(6));
      var dynamicStatic = foo.bar.dynamicStatic;
      expect(dynamicStatic(), equals(0));
      expect(dynamicStatic(0), equals(1));
      expect(dynamicStatic(0, 0), equals(2));
      expect(dynamicStatic(0, 0, 0, 0, 0, 0), equals(6));
    });

    test('typedef function', () {
      expect(foo.bar.add(4, 5), equals(9));
    });
  });
}
