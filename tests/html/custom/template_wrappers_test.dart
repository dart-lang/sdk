// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_wrappers_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import '../utils.dart';

int createdCount = 0;

class CustomElement extends HtmlElement {
  CustomElement.created() : super.created() {
    ++createdCount;
  }

  void checkCreated() {
  }
}

// Pump custom events polyfill events.
void customElementsTakeRecords() {
  if (js.context != null && js.context.hasProperty('CustomElements')) {
    js.context['CustomElements'].callMethod('takeRecords');
  }
}

main() {
  useHtmlConfiguration();

  var registeredTypes = false;
  setUp(loadPolyfills);

  test('element is upgraded once', () {

    expect(createdCount, 0);
    document.register('x-custom', CustomElement);
    expect(createdCount, 1);

    forceGC();

    return new Future.delayed(new Duration(milliseconds: 50)).then((_) {
      var t = document.querySelector('.t1');

      var fragment = t.content;

      fragment.querySelector('x-custom').checkCreated();
      expect(createdCount, 1);
    });
  });
}


void forceGC() {
  var N = 1000000;
  var M = 1000;
  for (var i = 0; i < M; ++i) {
    var l = new List(N);
  }
}
