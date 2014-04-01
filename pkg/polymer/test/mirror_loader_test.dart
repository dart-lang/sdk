// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('x-a')
class XA extends PolymerElement {
  final String x = "a";
  XA.created() : super.created();
}

// The next classes are here as a regression test for darbug.com/17929. Our
// loader was incorrectly trying to retrieve the reflectiveType of these
// classes.
class Foo<T> {}

@CustomTag('x-b')
class XB<T> extends PolymerElement {
  final String x = "a";
  XB.created() : super.created();
}

main() {
  useHtmlConfiguration();

  runZoned(() {
    initPolymer().run(() {
      setUp(() => Polymer.onReady);

      test('XA was registered correctly', () {
        expect(querySelector('x-a').shadowRoot.nodes.first.text, 'a');
      });

      test('XB was not registered', () {
        expect(querySelector('x-b').shadowRoot, null);
      });
    });
  }, onError: (e) {
    expect(e is UnsupportedError, isTrue);
    expect('$e', contains(
        'Custom element classes cannot have type-parameters: XB'));
  });
}
