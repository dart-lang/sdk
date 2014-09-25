// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.event_controller_test;

import 'dart:async';
import 'dart:js';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

var clickButtonCount = 0;
var clickXDartCount = 0;
var clickXJsCount = 0;

@CustomTag('x-dart')
class XDart extends PolymerElement {
  XDart.created() : super.created();
}

@CustomTag('x-controller')
class XController extends PolymerElement {
  XController.created() : super.created();
  clickButton() {++clickButtonCount;}
  clickXDart() {++clickXDartCount;}
  clickXJs() {++clickXJsCount;}
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('native element eventController is used properly', () {
    var controller = querySelector('x-controller');
    var button = controller.shadowRoot.querySelector('button');
    new JsObject.fromBrowserObject(button)['eventController'] = controller;
    button.remove();
    querySelector('body').append(button);

    button.click();
    expect(clickButtonCount, 1);
  });

  test('dart polymer element eventController is used properly', () {
    var controller = querySelector('x-controller');
    XDart xDart = controller.shadowRoot.querySelector('x-dart');
    xDart.eventController = controller;
    xDart.remove();
    querySelector('body').append(xDart);

    xDart.click();
    expect(clickXDartCount, 1);
  });

  test('js polymer elements eventController is used properly', () {
    var controller = querySelector('x-controller');
    var xJs = controller.shadowRoot.querySelector('x-js');
    new JsObject.fromBrowserObject(xJs)['eventController'] = controller;
    xJs.remove();
    querySelector('body').append(xJs);

    xJs.click();
    expect(clickXJsCount, 1);
  });
});
