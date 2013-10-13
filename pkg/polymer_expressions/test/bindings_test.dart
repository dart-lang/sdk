// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library bindings_test;

import 'dart:async';
import 'dart:html';
import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/observe.dart';
import 'package:observe/src/microtask.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() {
  mdv.initialize();
  useHtmlConfiguration();

  group('cursor position tests', () {
    var testDiv;
    setUp(() {
      document.body.append(testDiv = new DivElement());
    });

    tearDown(() {
      testDiv.remove();
      testDiv = null;
    });

    test('cursor position test', wrapMicrotask(() {
      var model = new NotifyModel('abcde');
      var template = new Element.html(
          '<template><input id="i1" value={{x}}></template>');
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      performMicrotaskCheckpoint();
      var el = testDiv.query("#i1");
      var subscription = el.onInput.listen(expectAsync1((_) {
        performMicrotaskCheckpoint();
      }, count: 1));
      el.focus();

      expect(el.value, 'abcde');
      expect(model.x, 'abcde');

      el.selectionStart = 3;
      el.selectionEnd = 3;
      expect(el.selectionStart, 3);
      expect(el.selectionEnd, 3);

      el.value = 'abc de';
      // Updating the input value programatically (even to the same value in
      // Chrome) loses the selection position.
      expect(el.selectionStart, 6);
      expect(el.selectionEnd, 6);

      el.selectionStart = 4;
      el.selectionEnd = 4;

      expect(model.x, 'abcde');
      el.dispatchEvent(new Event('input'));
      expect(model.x, 'abc de');
      expect(el.value, 'abc de');

      // But propagating observable values through reassign the value and
      // selection will be preserved.
      expect(el.selectionStart, 4);
      expect(el.selectionEnd, 4);

      subscription.cancel();
    }));
  });
}

class NotifyModel extends ChangeNotifierBase {
  var _x;
  NotifyModel([this._x]);

  get x => _x;
  set x(value) {
    _x = notifyPropertyChange(const Symbol('x'), _x, value);
  }
}
