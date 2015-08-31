// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsArrayTest;

import 'dart:html';
import 'dart:js';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var foo = {
    x: 3,
    z: 40, // Not specified in typed Dart API so should fail in checked mode.
    multiplyByX: function(arg) { return arg * this.x; },
    // This function can be torn off without having to bind this.
    multiplyBy2: function(arg) { return arg * 2; }
  };

  var foob = {
    x: 8,
    y: "why",
    multiplyByX: function(arg) { return arg * this.x; }
  };

  var bar = {
    x: "foo",
    multiplyByX: true
  };

  var selection = ["a", "b", "c", foo, bar];  
  selection.doubleLength = function() { return this.length * 2; };
""");
}

abstract class Foo {
  int get x;
  set x(int v);
  num multiplyByX(num y);
  num multiplyBy2(num y);
}

abstract class Foob extends Foo {
  final String y;
}

abstract class Bar {
  String get x;
  bool get multiplyByX;
}

class Baz {}

// This class shows the pattern used by APIs such as jQuery that add methods
// to Arrays.
abstract class Selection implements List {
  num doubleLength();
}

Foo get foo => context['foo'];
Foob get foob => context['foob'];
Bar get bar => context['bar'];
Selection get selection => context['selection'];

main() {
  // Call experimental API to register Dart interfaces implemented by
  // JavaScript classes.
  registerJsInterfaces([Foo, Foob, Bar, Selection]);

  _injectJs();

  useHtmlConfiguration();

  group('property', () {
    test('get', () {
      expect(foo.x, equals(3));
      expect(foob.x, equals(8));
      expect(foob.y, equals("why"));

      // Exists in JS but not in API.
      expect(() => foo.z, throws);
      expect(bar.multiplyByX, isTrue);
    });
    test('set', () {
      foo.x = 42;
      expect(foo.x, equals(42));
      // Property tagged as read only in typed API.
      expect(() => foob.y = "bla", throws);
      expect(() => foo.unknownName = 42, throws);
    });
  });

  group('method', () {
    test('call', () {
      foo.x = 100;
      expect(foo.multiplyByX(4), equals(400));
      foob.x = 10;
      expect(foob.multiplyByX(4), equals(40));
    });

    test('tearoff', () {
      foo.x = 10;
      // TODO(jacobr): should we automatically bind "this" for tearoffs of JS
      // objects?
      JsFunction multiplyBy2 = foo.multiplyBy2;
      expect(multiplyBy2(5), equals(10));
    });
  });

  group('type check', () {
    test('js interfaces', () {
      expect(foo is JsObject, isTrue);
      // Cross-casts are allowed.
      expect(foo is Bar, isTrue);
      expect(selection is JsArray, isTrue);

      // We do know at runtime whether something is a JsArray or not.
      expect(foo is JsArray, isFalse);
    });

    test('dart interfaces', () {
      expect(foo is Function, isFalse);
      expect(selection is List, isTrue);
    });
  });

  group("registration", () {
    test('repeated fails', () {
      // The experimental registerJsInterfaces API has already been called so
      // it cannot be called a second time.
      expect(() => registerJsInterfaces([Baz]), throws);
    });
  });
}
