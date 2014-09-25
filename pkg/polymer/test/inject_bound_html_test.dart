// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @observable String bar = "baz";

  XFoo.created() : super.created();

  @ComputedProperty('bar')
  String get ignore => readValue(#bar);
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('can inject bound html fragments', () {
    XFoo xFoo = querySelector('x-foo');
    DivElement injectDiv = xFoo.$['inject'];
    xFoo.injectBoundHTML('<span>{{bar}}</span>', injectDiv);
    expect(injectDiv.innerHtml, '<span>baz</span>');

    xFoo.bar = 'bat';
    return new Future(() {}).then((_) {
      expect(injectDiv.innerHtml, '<span>bat</span>');
    });
  });
});
