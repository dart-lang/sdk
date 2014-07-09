// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('inner-element')
class InnerElement extends PolymerElement {
  @published int number;
  @published bool boolean;
  @published String string;

  InnerElement.created() : super.created();
}

@CustomTag('outer-element')
class OuterElement extends PolymerElement {
  @observable int number = 1;
  @observable bool boolean = false;
  @observable String string = 'a';

  OuterElement.created() : super.created();
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);
  
  test('inner element gets initial values', () {
    var outer = querySelector('outer-element');
    var inner = outer.shadowRoot.querySelector('inner-element');
    
    expect(inner.number, 1);
    expect(inner.boolean, false);
    expect(inner.string, 'a');
  });

  test('inner element updates the outer element', () {
    var outer = querySelector('outer-element');
    var inner = outer.shadowRoot.querySelector('inner-element');
    
    // Toggle the value in the child and make sure that propagates around.
    inner.number = 2;
    inner.boolean = true;
    inner.string = 'b';
    return new Future(() {}).then((_) {
      expect(outer.number, 2);
      expect(outer.boolean, true);
      expect(outer.string, 'b');
      
      inner.number = 1;
      inner.boolean = false;
      inner.string = 'a';
    }).then((_) => new Future(() {})).then((_) {
      expect(outer.number, 1);
      expect(outer.boolean, false);
      expect(outer.string, 'a');
    });
  });
  
  test('outer element updates the inner element', () {
    var outer = querySelector('outer-element');
    var inner = outer.shadowRoot.querySelector('inner-element');
    
    // Toggle the value in the parent and make sure that propagates around.
    outer.number = 2;
    outer.boolean = true;
    outer.string = 'b';
    return new Future(() {}).then((_) {
      expect(inner.number, 2);
      expect(inner.boolean, true);
      expect(inner.string, 'b');
      
      outer.number = 1;
      outer.boolean = false;
      outer.string = 'a';
    }).then((_) => new Future(() {})).then((_) {
      expect(inner.number, 1);
      expect(inner.boolean, false);
      expect(inner.string, 'a');
    });
  });
});
