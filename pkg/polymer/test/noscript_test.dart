// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';
import 'package:template_binding/template_binding.dart';

main() {
  initPolymer();
  useHtmlConfiguration();
  templateBind(querySelector("#a")).model = "foo";

  setUp(() => Polymer.onReady);

  test('template found with multiple noscript declarations', () {
    expect(querySelector('x-a') is PolymerElement, isTrue);
    expect(querySelector('x-a').shadowRoot.nodes.first.text, 'a');

    expect(querySelector('x-c') is PolymerElement, isTrue);
    expect(querySelector('x-c').shadowRoot.nodes.first.text, 'c');

    expect(querySelector('x-b') is PolymerElement, isTrue);
    expect(querySelector('x-b').shadowRoot.nodes.first.text, 'b');

    expect(querySelector('x-d') is PolymerElement, isTrue);
    expect(querySelector('x-d').shadowRoot.nodes.first.text, 'd');
  });
}
