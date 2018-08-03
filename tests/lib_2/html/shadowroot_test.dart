// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isShadowRoot = predicate((x) => x is ShadowRoot, 'is a ShadowRoot');

  test('ShadowRoot supported', () {
    var isSupported = ShadowRoot.supported;

    // If it's supported, then it should work. Otherwise should fail.
    if (isSupported) {
      var div = new DivElement();
      var shadowRoot = div.createShadowRoot();
      expect(shadowRoot, isShadowRoot);
      expect(div.shadowRoot, shadowRoot);
    } else {
      expect(() => new DivElement().createShadowRoot(), throws);
    }
  });
}
