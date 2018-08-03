// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/23127
// Tests super calls to a custom element upgrade constructor with various
// combinations of parameters and type arguments.

library custom_elements_23127_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/html_individual_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

abstract class B1 extends HtmlElement {
  void action();

  B1.created() : super.created() {
    action();
  }
}

abstract class B1T<T> extends HtmlElement {
  void action();
  var qq = false;
  B1T.created() : super.created() {
    action();
    qq = this is T;
  }
}

abstract class B2 extends HtmlElement {
  void action();
  var qq;
  B2.created([a = 1, b = 2, c = 3])
      : qq = callTwice(() => ++a * ++b), // [a] and [b] are boxed.
        super.created() {
    action();
    qq = [qq, a, b, c];
  }
}

abstract class B2T<T> extends HtmlElement {
  void action();
  var qq;
  B2T.created([a = 1, b = 2, c = 3])
      : qq = callTwice(() => ++a * ++b),
        super.created() {
    action();
    qq = [this is T, qq, a, b, c];
  }
}

class C1 extends B1 {
  int z;
  C1.created() : super.created();
  action() {
    z = 3;
  }
}

class C1T extends B1T {
  int z;
  C1T.created() : super.created();
  action() {
    z = 3;
  }
}

class C2 extends B2 {
  int z;
  C2.created() : super.created(20);
  action() {
    z = 3;
  }
}

class C2T extends B2T {
  int z;
  C2T.created() : super.created(20);
  action() {
    z = 3;
  }
}

var callTwice;

main() {
  useHtmlIndividualConfiguration();

  setUp(() => customElementsReady);

  callTwice = (f) {
    f();
    return f();
  };

  group('baseline', () {
    test('C1', () {
      document.register('x-c1', C1);
      C1 e = document.createElement('x-c1');
      expect(e.z, 3);
    });
  });

  group('c1t', () {
    test('C1T', () {
      document.register('x-c1t', C1T);
      C1T e = document.createElement('x-c1t');
      expect(e.z, 3);
      expect(e.qq, true);
    });
  });

  group('c2', () {
    test('C2', () {
      document.register('x-c2', C2);
      C2 e = document.createElement('x-c2');
      expect(e.z, 3);
      expect(e.qq, [88, 22, 4, 3]);
    });
  });

  group('c2t', () {
    test('C2T', () {
      document.register('x-c2t', C2T);
      C2T e = document.createElement('x-c2t');
      expect(e.z, 3);
      expect(e.qq, [true, 88, 22, 4, 3]);
    });
  });
}
