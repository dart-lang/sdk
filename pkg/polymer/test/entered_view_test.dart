// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.entered_view_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@reflectable
class XOuter extends PolymerElement {
  @observable bool expand = false;

  XOuter.created() : super.created();
}

@reflectable
class XInner extends PolymerElement {
  int enteredCount = 0;

  XInner.created() : super.created();

  attached() {
    enteredCount++;
    super.attached();
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();
  Polymer.register('x-inner', XInner);
  Polymer.register('x-outer', XOuter);

  setUp(() => Polymer.onReady);

  test('element created properly', () {
    XOuter outer = querySelector('x-outer');
    outer.expand = true;
    return outer.onMutation(outer.shadowRoot).then((_) {
      // Element upgrade is also using mutation observers. Wait another tick so
      // it goes before we do.
      return new Future(() {
        XInner inner = outer.shadowRoot.querySelector('x-inner');
        expect(inner.enteredCount, 1, reason: 'attached should be called');
      });
    });
  });
});
