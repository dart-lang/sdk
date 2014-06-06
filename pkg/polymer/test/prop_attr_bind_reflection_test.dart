// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('my-child-element')
class MyChildElement extends PolymerElement {
  @PublishedProperty(reflect: true) int camelCase;
  @PublishedProperty(reflect: true) int lowercase;

  // TODO(sigmund): remove once codegen in polymer is turned on.
  @reflectable get attributes => super.attributes;

  MyChildElement.created() : super.created();

  // Make this a no-op, so we can verify the initial
  // reflectPropertyToAttribute works.
  @override
  openPropertyObserver() { }
}

@CustomTag('my-element')
class MyElement extends PolymerElement {
  @observable int volume = 11;

  MyElement.created() : super.created();
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('attribute reflected to property name', () {
    var child = querySelector('my-element')
        .shadowRoot.querySelector('my-child-element');
    expect(child.lowercase, 11);
    expect(child.camelCase, 11);

    expect(child.attributes['lowercase'], '11');
    expect(child.attributes['camelcase'], '11');
  });
});
