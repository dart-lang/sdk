// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsTest;

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'package:expect/expect.dart' show NoInline, AssumeDynamic;

import 'js_type_test_lib.dart';

class Bar {}

@NoInline()
@AssumeDynamic()
confuse(x) => x;

class Is<T> {
  const Is();
  check(o) => o is T;
}

main() {
  useHtmlIndividualConfiguration();

  new Is<Foo>().check(new Bar()); // Bar is instantiated by this code.
  new Is<Foo>().check([]);
  new Is<List>().check([]);

  group('static', () {
    test('not-String', () {
      Foo e = new Foo();
      expect(e is String, isFalse);
    });

    test('not-int', () {
      Foo e = new Foo();
      expect(e is int, isFalse);
    });

    test('not-Null', () {
      Foo e = new Foo();
      expect(e is Null, isFalse);
    });

    test('not-Bar', () {
      Foo e = new Foo();
      expect(e is Bar, isFalse);
    });

    test('is-Foo', () {
      Foo e = new Foo();
      expect(e is Foo, isTrue);
    });

    test('String-not-Foo', () {
      String e = 'hello';
      expect(e is Foo, isFalse);
    });
  });

  group('dynamic', () {
    test('not-String', () {
      var e = confuse(new Foo());
      expect(e is String, isFalse);
    });

    test('not-int', () {
      var e = confuse(new Foo());
      expect(e is int, isFalse);
    });

    test('not-Null', () {
      var e = confuse(new Foo());
      expect(e is Null, isFalse);
    });

    test('not-Bar', () {
      var e = confuse(new Foo());
      expect(e is Bar, isFalse);
    });

    test('is-Foo', () {
      var e = confuse(new Foo());
      expect(e is Foo, isTrue);
    });
  });

  group('dynamic-String-not-Foo', () {
    test('test', () {
      var e = confuse('hello');
      expect(e is Foo, isFalse);
    });
  });

  group('dynamic-null-not-Foo', () {
    test('test', () {
      var e = confuse(null);
      expect(e is Foo, isFalse);
    });
  });

  group('dynamic-type', () {
    test('not-String', () {
      var e = confuse(new Foo());
      expect(const Is<String>().check(e), isFalse);
    });

    test('not-int', () {
      var e = confuse(new Foo());
      expect(const Is<int>().check(e), isFalse);
    });

    test('not-Null', () {
      var e = confuse(new Foo());
      expect(const Is<Null>().check(e), isFalse);
    });

    test('not-Bar', () {
      var e = confuse(new Foo());
      expect(const Is<Bar>().check(e), isFalse);
    });

    test('is-Foo', () {
      var e = confuse(new Foo());
      expect(const Is<Foo>().check(e), isTrue);
    });
  });

  group('dynamic-String-not-dynamic-Foo', () {
    test('test', () {
      var e = confuse('hello');
      expect(const Is<Foo>().check(e), isFalse);
    });
  });

  group('dynamic-null-not-dynamic-Foo', () {
    test('test', () {
      var e = confuse(null);
      expect(const Is<Foo>().check(e), isFalse);
    });
  });
}
