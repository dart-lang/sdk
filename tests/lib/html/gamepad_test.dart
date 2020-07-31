// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/minitest.dart';
import 'dart:html';

main() {
  var isGamepadList =
      predicate((x) => x is List<Gamepad?>, 'is a List<Gamepad?>');

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHtml = r'''
    A large block of text should go here. Click this
    block of text multiple times to see each line
    highlight with every click of the mouse button.
    ''';
    document.body!.append(element);
    return element;
  }

  test("getGamepads", () {
    insertTestDiv();
    var gamepads = window.navigator.getGamepads();
    expect(gamepads, isGamepadList);
    for (var gamepad in gamepads) {
      if (gamepad != null) {
        expect(gamepad.id, isNotNull);
      }
    }
  });
}
