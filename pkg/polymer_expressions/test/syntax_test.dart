// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:polymer_expressions/polymer_expressions.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:observe/observe.dart';
import 'package:mdv/mdv.dart' as mdv;

main() {
  mdv.initialize();
  useHtmlEnhancedConfiguration();

  group('PolymerExpressions', () {
    var testDiv;

    setUp(() {
      document.body.append(testDiv = new DivElement());
    });

    tearDown(() {
      testDiv.firstChild.remove();
      testDiv = null;
    });

    test('should make two-way bindings to inputs', () {
      testDiv.nodes.add(new Element.html('''
          <template id="test" bind>
            <input id="input" value="{{ firstName }}">
          </template>'''));
      var person = new Person('John', 'Messerly', ['A', 'B', 'C']);
      query('#test')
          ..bindingDelegate = new PolymerExpressions()
          ..model = person;
      return new Future.delayed(new Duration()).then((_) {
        InputElement input = query('#input');
        expect(input.value, 'John');
        input.focus();
        input.value = 'Justin';
        input.blur();
        var event = new Event('change');
        // TODO(justin): figure out how to trigger keyboard events to test
        // two-way bindings
      });
    });

    test('should handle null collections in "in" expressions', () {
      testDiv.nodes.add(new Element.html('''
          <template id="test" bind>
            <template repeat="{{ item in items }}">
              {{ item }}
            </template>
          </template>'''));
      query('#test')
          ..bindingDelegate = new PolymerExpressions(globals: {'items': null})
          ..model = null;
      // the template should be the only node
      expect(testDiv.nodes.length, 1);
      expect(testDiv.nodes[0].id, 'test');
    });
  });
}

class Person extends Object with ChangeNotifierMixin {
  static const _FIRST_NAME = const Symbol('firstName');
  static const _LAST_NAME = const Symbol('lastName');
  static const _ITEMS = const Symbol('items');
  static const _GET_FULL_NAME = const Symbol('getFullName');

  String _firstName;
  String _lastName;
  List<String> _items;

  Person(this._firstName, this._lastName, this._items);

  String get firstName => _firstName;

  void set firstName(String value) {
    _firstName = value;
    notifyChange(new PropertyChangeRecord(_FIRST_NAME));
  }

  String get lastName => _lastName;

  void set lastName(String value) {
    _lastName = value;
    notifyChange(new PropertyChangeRecord(_LAST_NAME));
  }

  String getFullName() => '$_firstName $_lastName';

  List<String> get items => _items;

  void set items(List<String> value) {
    _items = value;
    notifyChange(new PropertyChangeRecord(_ITEMS));
  }

  String toString() => "Person(firstName: $_firstName, lastName: $_lastName)";

}
