// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.html.mirrors_test;

@MirrorsUsed(targets: const [A, B])
import 'dart:mirrors';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import '../utils.dart';

/// Regression test for a tricky mirrors+custom_elements issue:
/// dart2js mirrors cache dispatch information on the Object's constructor.
/// This was failing for custom elements on IE 10, because the constructor was
/// HTMLUnknownElement for all of them. So mirrors called the wrong method.
main() {
  useHtmlConfiguration();

  var registered = false;
  setUp(() => customElementsReady.then((_) {
        if (!registered) {
          registered = true;
          document.registerElement(A.tag, A);
          document.registerElement(B.tag, B);
        }
      }));

  test('dynamic dispatch', () {
    var a = new A();
    expect(a.fooBar, 1);
    reflect(a).setField(#fooBar, 123);
    expect(a.fooBar, 123);

    // Even though A was set first, B.fooBar= should dispatch to B.
    var b = new B();
    expect(b.fooBar, 2);
    expect(b._fooBarSet, 0);
    reflect(b).setField(#fooBar, 123);
    expect(b.fooBar, 123);
    expect(b._fooBarSet, 1);
  });
}

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);
  A.created() : super.created();

  int fooBar = 1;
}

class B extends HtmlElement {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag);
  B.created() : super.created();

  int _fooBar = 2;
  int _fooBarSet = 0;

  int get fooBar => _fooBar;
  set fooBar(value) {
    _fooBarSet++;
    _fooBar = value;
  }
}
