// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('x-html')
class XHtmlElement extends PolymerElement {
  XHtmlElement.created() : super.created();
}

@CustomTag('x-html-two')
class XHtml2Element extends XHtmlElement {
  XHtml2Element.created() : super.created();
}

@CustomTag('x-div')
class XDivElement extends DivElement with Polymer, Observable {
  XDivElement.created() : super.created();
}

@CustomTag('x-div-two')
class XDiv2Element extends XDivElement {
  XDiv2Element.created() : super.created();
}

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('elements upgraded', () {
    expect(querySelector('x-html') is XHtmlElement, isTrue);
    expect(querySelector('x-html-two') is XHtml2Element, isTrue);
    expect(querySelector('#x-div') is XDivElement, isTrue);
    expect(querySelector('#x-div-two') is XDiv2Element, isTrue);
  });
}
