// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library bindings_test;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:observe/src/dirty_check.dart' show dirtyCheckZone;
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart' show templateBind;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() => dirtyCheckZone().run(() {
  useHtmlConfiguration();

  group('bindings', () {
    var stop = null;
    var messages = [];
    var testDiv;
    setUp(() {
      stop = Logger.root.onRecord.listen((r) => messages.add(r));
      document.body.append(testDiv = new DivElement());
    });

    tearDown(() {
      testDiv.remove();
      testDiv = null;
      stop.cancel();
      stop = null;
      messages = [];
    });

    test('should update binding when data changes', () {
      var model = new NotifyModel();
      var binding = new PolymerExpressions()
          .prepareBinding('x', null, null)(model, null, false);
      expect(binding.value, isNull);
      model.x = "hi";
      return new Future(() {
        expect(binding.value, 'hi');
        expect(messages.length, 0);
      });
    });

    test('should update text content when data changes', () {
      var model = new NotifyModel('abcde');
      var template = templateBind(new Element.html(
          '<template><span>{{x}}</span></template>'));
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        var el = testDiv.query("span");
        expect(el.text, 'abcde');
        expect(model.x, 'abcde');
        model.x = '___';

        return new Future(() {
          expect(model.x, '___');
          expect(el.text, '___');
        });
      });
    });

    test('should log eval exceptions', () {
      var model = new NotifyModel('abcde');
      var template = templateBind(new Element.html(
          '<template><span>{{foo}}</span></template>'));
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        expect(messages.length, 1);
        expect(messages[0].message,
            "Error evaluating expression 'foo': variable 'foo' not found");
      });
    });

    test('should preserve the cursor position', () {
      var model = new NotifyModel('abcde');
      var template = templateBind(new Element.html(
          '<template><input id="i1" value={{x}}></template>'));
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        var el = testDiv.query("#i1");
        var subscription = el.onInput.listen(expectAsync1((_) {}, count: 1));
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
      });
    });
  });
});

@reflectable
class NotifyModel extends ChangeNotifier {
  var _x;
  NotifyModel([this._x]);

  get x => _x;
  set x(value) {
    _x = notifyPropertyChange(#x, _x, value);
  }
}
