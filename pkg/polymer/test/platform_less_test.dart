// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.layout_test;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

int elementsReadied = 0;

@CustomTag('x-import')
class XImport extends PolymerElement {
  XImport.created() : super.created();

  ready() {
    elementsReadied++;
  }
}

@CustomTag('x-main')
class XMain extends PolymerElement {
  XMain.created() : super.created();

  ready() {
    elementsReadied++;
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('platform-less configuration', () {
    var jsDoc = new JsObject.fromBrowserObject(document);
    var htmlImports = context['HTMLImports'];

    if (!ShadowRoot.supported || !(new LinkElement()).supportsImport) return;

    expect(elementsReadied, 2, reason: 'imported elements upgraded');
  });

});
