// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // make test smaller.
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:template_binding/template_binding.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();

  var testDiv;
  group('enumerate', () {
    setUp(() {
      testDiv = new Element.html('''
          <div id="test">
            <template bind>
              <template repeat="{{entry in this | enumerate}}">
                <div>Item {{ entry.index }} is {{ entry.value }}</div>
              </template>
            </template>
          </div>''');
      TemplateBindExtension.bootstrap(testDiv);
      document.body.nodes.add(testDiv);
    });

    tearDown(() {
      testDiv.remove();
      testDiv = null;
    });

    test('should enumerate item and index', () {
      templateBind(testDiv.query('template'))
          ..bindingDelegate = new PolymerExpressions()
          ..model = toObservable(
              ['hello', 'from', 'polymer', 'expressions']);

      return new Future(() {
        expect(testDiv.queryAll('div').map((n) => n.text), [
          'Item 0 is hello',
          'Item 1 is from',
          'Item 2 is polymer',
          'Item 3 is expressions',
        ]);
      });
    });

    test('should update after changes', () {
      var model = toObservable(
              ['hello', 'from', 'polymer', 'expressions', 'a', 'b', 'c']);

      templateBind(testDiv.query('template'))
          ..bindingDelegate = new PolymerExpressions()
          ..model = model;

      return new Future(() {
        expect(testDiv.queryAll('div').map((n) => n.text), [
          'Item 0 is hello',
          'Item 1 is from',
          'Item 2 is polymer',
          'Item 3 is expressions',
          'Item 4 is a',
          'Item 5 is b',
          'Item 6 is c',
        ]);

        model.removeAt(1);
        model[1] = 'world';
        model[2] = '!';
        model.insert(5, 'e');

        return new Future(() {
          expect(testDiv.queryAll('div').map((n) => n.text), [
            'Item 0 is hello',
            'Item 1 is world',
            'Item 2 is !',
            'Item 3 is a',
            'Item 4 is b',
            'Item 5 is e',
            'Item 6 is c',
          ]);
        });
      });
    });
  });
}
