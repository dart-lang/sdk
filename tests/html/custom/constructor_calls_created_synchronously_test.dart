// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library constructor_calls_created_synchronously_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);

  static int ncallbacks = 0;

  void created() {
    ncallbacks++;
  }
}

loadPolyfills() {
  if (!document.supportsRegister) {
    // Cache blocker is a workaround for:
    // https://code.google.com/p/dart/issues/detail?id=11834
    var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
    return HttpRequest.getString('/root_dart/pkg/custom_element/lib/'
      'custom-elements.debug.js?cacheBlock=$cacheBlocker').then((code) {
      document.head.children.add(new ScriptElement()..text = code);
    });
  }
}

main() {
  useHtmlConfiguration();

  // Adapted from Blink's
  // fast/dom/custom/constructor-calls-created-synchronously test.

  setUp(loadPolyfills);

  test('createdCallback', () {
    document.register(A.tag, A);
    var x = new A();
    expect(A.ncallbacks, 1);
  });
}
