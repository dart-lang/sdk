// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:template_binding/template_binding.dart';

@CustomTag('x-target')
class XTarget extends PolymerElement {
  XTarget.created() : super.created();

  final Completer _found = new Completer();
  Future get foundSrc => _found.future;

  // force an mdv binding
  bind(name, value, {oneTime: false}) =>
      nodeBindFallback(this).bind(name, value, oneTime: oneTime);

  inserted() {
    testSrcForMustache();
  }

  attributeChanged(name, oldValue, newValue) {
    testSrcForMustache();
    if (attributes[name] == '../testSource') {
      _found.complete();
    }
  }

  testSrcForMustache() {
    expect(attributes['src'], isNot(matches(Polymer.bindPattern)),
        reason: 'attribute does not contain {{...}}');
  }
}

@CustomTag('x-test')
class XTest extends PolymerElement {
  XTest.created() : super.created();

  @observable var src = 'testSource';
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('mustache attributes', () {
    final xtest = document.querySelector('#test');
    final xtarget = xtest.shadowRoot.querySelector('#target');
    return xtarget.foundSrc;
  });
});
