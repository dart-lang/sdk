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
import 'package:smoke/mirrors.dart' as smoke;
import 'package:template_binding/template_binding.dart' show
    TemplateBindExtension, templateBind;
import 'package:unittest/html_config.dart';

import 'package:unittest/unittest.dart';

var testDiv;

main() => dirtyCheckZone().run(() {
  useHtmlConfiguration();
  smoke.useMirrors();

  group('bindings', () {
    var stop = null;
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

    // regression test for issue 19296
    test('should not throw when data changes', () {
      var model = new NotifyModel();
      var tag = new Element.html('<template>'
          '<template repeat="{{ i in x }}">{{ i }}</template></template>');
      TemplateBindExtension.bootstrap(tag);
      var template = templateBind(tag);
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        model.x = [1, 2, 3];
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text,'123');
      });
    });


    test('should update text content when data changes', () {
      var model = new NotifyModel('abcde');
      var tag = new Element.html(
      '<template><span>{{x}}</span></template>');
      TemplateBindExtension.bootstrap(tag);
      var template = templateBind(tag);
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
        var tag = new Element.html(
        '<template><span>{{foo}}</span></template>');
        TemplateBindExtension.bootstrap(tag);
        var template = templateBind(tag);
        testDiv.append(template.createInstance(model,
            new PolymerExpressions()));

        return _nextMicrotask(null);
      }, onError: (e) {
        expect('$e', startsWith("Error evaluating expression 'foo':"));
        completer.complete(true);
      });
      return completer.future;
    });

    test('detects changes to ObservableList', () {
      var list = new ObservableList.from([1, 2, 3]);

      var tag = new Element.html('<template>{{x[1]}}</template>');
      TemplateBindExtension.bootstrap(tag);
      var template = templateBind(tag);

      var model = new NotifyModel(list);
      testDiv.append(template.createInstance(model, new PolymerExpressions()));

      return new Future(() {
        expect(testDiv.text, '2');
        list[1] = 10;
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, '10');
        list[1] = 11;
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, '11');
        list[0] = 9;
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, '11');
        list.removeAt(0);
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, '3');
        list.add(90);
        list.removeAt(0);
      }).then(_nextMicrotask).then((_) {
        expect(testDiv.text, '90');
      });
    });

    test('detects changes to ObservableMap keys/values', () {
      var map = new ObservableMap.from({'a': 1, 'b': 2});

      var tag = new Element.html('<template>'
          '<template repeat="{{k in x.keys}}">{{k}}:{{x[k]}},</template>'
          '</template>');
      TemplateBindExtension.bootstrap(tag);
      var template = templateBind(tag);

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

    // TODO(sigmund): enable this test (issue 19105)
    // _cursorPositionTest(false);
    _cursorPositionTest(true);

    // Regression tests for issue 18792.
    for (var usePolymer in [true, false]) {
      // We run these tests both with PolymerExpressions and with the default
      // delegate to ensure the results are consistent. The expressions on these
      // tests use syntax common to both delegates.
      var name = usePolymer ? 'polymer-expressions' : 'default';
      group('$name delegate', () {
        // Use <option template repeat="{{y}}" value="{{}}">item {{}}
        _initialSelectTest('{{y}}', '{{}}', usePolymer);
        _updateSelectTest('{{y}}', '{{}}', usePolymer);
      });
    }

    group('polymer-expressions delegate, polymer syntax', () {
        // Use <option template repeat="{{i in y}}" value="{{i}}">item {{i}}
      _initialSelectTest('{{i in y}}', '{{i}}', true);
      _updateSelectTest('{{i in y}}', '{{i}}', true);
    });
  });
});


_cursorPositionTest(bool usePolymer) {
  test('should preserve the cursor position', () {
    var model = new NotifyModel('abcde');

    var tag = new Element.html(
        '<template><input id="i1" value={{x}}></template>');
    TemplateBindExtension.bootstrap(tag);
    var template = templateBind(tag);

    var delegate = usePolymer ? new PolymerExpressions() : null;
    testDiv.append(template.createInstance(model, delegate));

    var el;
    return new Future(() {
      el = testDiv.query("#i1");
      var subscription = el.onInput.listen(expectAsync((_) {}, count: 1));
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
    }).then(_nextMicrotask).then((_) {
      // Nothing changes on the next micro task.
      expect(el.selectionStart, 4);
      expect(el.selectionEnd, 4);
    }).then((_) => window.animationFrame).then((_) {
      // ... or on the next animation frame.
      expect(el.selectionStart, 4);
      expect(el.selectionEnd, 4);
    }).then(_afterTimeout).then((_) {
      // ... or later.
      expect(el.selectionStart, 4);
      expect(el.selectionEnd, 4);
    });
  });
}

_initialSelectTest(String repeatExp, String valueExp, bool usePolymer) {
  test('initial select value is set correctly', () {
    var list = const ['a', 'b'];

    var tag = new Element.html('<template>'
        '<select value="{{x}}">'
        '<option template repeat="$repeatExp" value="$valueExp">item $valueExp'
        '</option></select></template>',
        treeSanitizer: _nullTreeSanitizer);
    TemplateBindExtension.bootstrap(tag);
    var template = templateBind(tag);

    var model = new NotifyModel('b', list);
    var delegate = usePolymer ? new PolymerExpressions() : null;
    testDiv.append(template.createInstance(model, delegate));

    expect(testDiv.querySelector('select').value, 'b');
    return new Future(() {
      expect(model.x, 'b');
      expect(testDiv.querySelector('select').value, 'b');
    });
  });
}

_updateSelectTest(String repeatExp, String valueExp, bool usePolymer) {
  test('updates to select value propagate correctly', () {
    var list = const ['a', 'b'];

    var tag = new Element.html('<template>'
        '<select value="{{x}}">'
        '<option template repeat="$repeatExp" value="$valueExp">item $valueExp'
        '</option></select></template>',
        treeSanitizer: _nullTreeSanitizer);
    TemplateBindExtension.bootstrap(tag);
    var template = templateBind(tag);

    var model = new NotifyModel('a', list);
    var delegate = usePolymer ? new PolymerExpressions() : null;
    testDiv.append(template.createInstance(model, delegate));

    expect(testDiv.querySelector('select').value, 'a');
    return new Future(() {
      expect(testDiv.querySelector('select').value, 'a');
      model.x = 'b';
    }).then(_nextMicrotask).then((_) {
      expect(testDiv.querySelector('select').value, 'b');
    });
  });
}

_nextMicrotask(_) => new Future(() {});
_afterTimeout(_) => new Future.delayed(new Duration(milliseconds: 30), () {});

@reflectable
class NotifyModel extends ChangeNotifier {
  var _x;
  var _y;
  NotifyModel([this._x, this._y]);

  get x => _x;
  set x(value) {
    _x = notifyPropertyChange(#x, _x, value);
  }

  get y => _y;
  set y(value) {
    _y = notifyPropertyChange(#y, _y, value);
  }
}

class _NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}
final _nullTreeSanitizer = new _NullTreeSanitizer();
