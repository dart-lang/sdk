// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';

main() {
  useHtmlIndividualConfiguration();

  group('KeyEvent', () {
    keydownHandlerTest(KeyEvent e) {
      document.body.innerHtml =
          '${document.body.innerHtml}KeyDOWN: CharCode: ${e.charCode}, KeyCode:'
          ' ${e.keyCode}<br />';
      expect(e.charCode, 0);
    }

    keypressHandlerTest(KeyEvent e) {
      document.body.innerHtml =
          '${document.body.innerHtml}KeyPRESS: CharCode: ${e.charCode}, '
          'KeyCode: ${e.keyCode}<br />';
    }

    keyupHandlerTest(KeyEvent e) {
      document.body.innerHtml =
          '${document.body.innerHtml}KeyUP: CharCode: ${e.charCode}, KeyCode:'
          ' ${e.keyCode}<br />';
      expect(e.charCode, 0);
    }

    keyupHandlerTest2(KeyEvent e) {
      document.body.innerHtml =
          '${document.body.innerHtml}A second KeyUP handler: CharCode: '
          '${e.charCode}, KeyCode: ${e.keyCode}<br />';
      expect(e.charCode, 0);
    }

    test('keys', () {
      document.body.innerHtml =
          '${document.body.innerHtml}To test keyboard event values, press some '
          'keys on your keyboard.<br /><br />The charcode for keydown and keyup'
          ' should be 0, and the keycode should (generally) be populated with a'
          ' value. Keycode and charcode should both have values for the '
          'keypress event.';
      KeyboardEventStream.onKeyDown(document.body).listen(keydownHandlerTest);
      KeyboardEventStream.onKeyPress(document.body).listen(keypressHandlerTest);
      KeyboardEventStream.onKeyUp(document.body).listen(keyupHandlerTest);
      KeyboardEventStream.onKeyUp(document.body).listen(keyupHandlerTest2);
    });
  });
}
