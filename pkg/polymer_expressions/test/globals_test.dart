// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/observe.dart';
import 'package:observe/src/microtask.dart';
import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';

main() {
  mdv.initialize();
  useHtmlEnhancedConfiguration();

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
      document.body.nodes.add(testDiv);
    });

    tearDown(() {
      testDiv..unbindAll()..remove();
      testDiv = null;
    });

    test('should enumerate item and index', wrapMicrotask(() {
      testDiv.query('template')
          ..bindingDelegate = new PolymerExpressions()
          ..model = toObservable(
              ['hello', 'from', 'polymer', 'expressions']);

      performMicrotaskCheckpoint();

      expect(testDiv.queryAll('div').map((n) => n.text), [
        'Item 0 is hello',
        'Item 1 is from',
        'Item 2 is polymer',
        'Item 3 is expressions',
      ]);
    }));
  });
}
