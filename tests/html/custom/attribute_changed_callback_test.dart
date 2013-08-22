// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library attribute_changed_callback_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);

  static var attributeChangedInvocations = 0;

  void onAttributeChanged(name, oldValue, newValue) {
    attributeChangedInvocations++;
  }
}

class B extends HtmlElement {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag);

  static var invocations = [];

  void onCreated() {
    invocations.add('created');
  }

  void onAttributeChanged(name, oldValue, newValue) {
    invocations.add('$name: $oldValue => $newValue');
  }
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's fast/dom/custom/attribute-changed-callback test.

  test('transfer attribute changed callback', () {
    document.register(A.tag, A);
    var element = new A();

    element.attributes['a'] = 'b';
    expect(A.attributeChangedInvocations, 1);
  });

  test('add, change and remove an attribute', () {
    document.register(B.tag, B);
    var b = new B();
    b.id = 'x';
    expect(B.invocations, ['created', 'id: null => x']);

    B.invocations = [];
    b.attributes.remove('id');
    expect(B.invocations, ['id: x => null']);

    B.invocations = [];
    b.attributes['data-s'] = 't';
    expect(B.invocations, ['data-s: null => t']);

    B.invocations = [];
    b.classList.toggle('u');
    expect(B.invocations, ['class: null => u']);

    b.attributes['data-v'] = 'w';
    B.invocations = [];
    b.attributes['data-v'] = 'x';
    expect(B.invocations, ['data-v: w => x']);

    B.invocations = [];
    b.attributes['data-v'] = 'x';
    expect(B.invocations, []);
  });
}
