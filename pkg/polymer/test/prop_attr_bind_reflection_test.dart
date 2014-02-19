// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('my-child-element')
class MyChildElement extends PolymerElement {
  @published int camelCase;
  @published int lowercase;

  MyChildElement.created() : super.created();

  // Make this a no-op, so we can verify the initial
  // reflectPropertyToAttribute works.
  observeAttributeProperty(name) { }
}

@CustomTag('my-element')
class MyElement extends PolymerElement {
  @observable int volume = 11;

  MyElement.created() : super.created();
}

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('attribute reflected to property name', () {
    var child = querySelector('my-element')
        .shadowRoot.querySelector('my-child-element');
    expect(child.lowercase, 11);
    expect(child.camelCase, 11);

    expect('11', child.attributes['lowercase']);
    expect('11', child.attributes['camelcase']);
  });
}
