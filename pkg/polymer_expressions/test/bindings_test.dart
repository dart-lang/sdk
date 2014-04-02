// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library bindings_test;

import 'dart:async';
import 'dart:html';

import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // make test smaller.
import 'package:observe/src/dirty_check.dart' show dirtyCheckZone;
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart' show templateBind;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

main() => dirtyCheckZone().run(() {
  useHtmlConfiguration();

  group('bindings', () {
    var stop = null;
    var testDiv;
    setUp(() {
      document.body.append(testDiv = new DivElement());
    });

    tearDown(() {
      testDiv.remove();
      testDiv = null;
    });

    test('should update binding when data changes', () {
      var model = new NotifyModel();
      var binding = new PolymerExpressions()
          .prepareBinding('x', null, null)(model, null, false);
      expect(binding.value, isNull);
      model.x = "hi";
      return new Future(() {
        expect(binding.value, 'hi');
      });
    });

    test('should update text content when data changes', () {
      var model = new NotifyModel('abcde');
      var template = templateBind(new Element.html(
          '<template><span>{{x}}</span></template>'));
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      var el;
      return new Future(() {
        el = testDiv.query("span");
        expect(el.text, 'abcde');
        expect(model.x, 'abcde');
        model.x = '___';
      }).then(_nextMicrotask).then((_) {
        expect(model.x, '___');
        expect(el.text, '___');
      });
    });

    test('should log eval exceptions', () {
      var model = new NotifyModel('abcde');
      var completer = new Completer();
      runZoned(() {
        var template = templateBind(new Element.html(
            '<template><span>{{foo}}</span></template>'));
        testDiv.append(template.createInstance(model,
            new PolymerExpressions()));

        return _nextMicrotask(null);
      }, onError: (e) {
        expect('$e', startsWith("Error evaluating expression 'foo':"));
        completer.complete(true);
      });
      return completer.future;
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


    test('detects changes to ObservableMap keys/values', () {
      var map = new ObservableMap.from({'a': 1, 'b': 2});
      var template = templateBind(new Element.html('<template>'
          '<template repeat="{{k in x.keys}}">{{k}}:{{x[k]}},</template>'
          '</template>'));
      var model = new NotifyModel(map);
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        expect(testDiv.text, 'a:1,b:2,');
        map.remove('b');
        map['c'] = 3;
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, 'a:1,c:3,');
        map['a'] = 4;
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, 'a:4,c:3,');
      });
    });
  });
});

_nextMicrotask(_) => new Future(() {});

@reflectable
class NotifyModel extends ChangeNotifier {
  var _x;
  NotifyModel([this._x]);

  get x => _x;
  set x(value) {
    _x = notifyPropertyChange(#x, _x, value);
  }
}
