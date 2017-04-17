import 'dart:html';

import 'package:expect/minitest.dart';

import 'utils.dart';

main() {
  test('InnerHTML', () {
    Element element = new Element.tag('div');
    element.id = 'test';
    element.innerHtml = 'Hello World';
    document.body.append(element);

    element = document.query('#test');
    expect(element.innerHtml, 'Hello World');
    element.remove();
  });
  test('HTMLTable', () {
    TableElement table = new Element.tag('table');

    TableRowElement row = new Element.tag('tr');
    table.append(row);

    row.append(new Element.tag('td'));
    row.append(new Element.tag('td'));

    expect(row.cells.length, 2);

    TableRowElement headerRow = table.rows[0];
    expect(headerRow.cells.length, 2);
  });
  test('dataset', () {
    Element div = new Element.tag('div');

    expect(div.dataset.isEmpty, isTrue);
    expect(div.dataset['foo'], isNull);
    expect(div.dataset.isEmpty, isTrue);

    div.dataset['foo'] = 'foo-value';
    expect(div.dataset['foo'], 'foo-value');
    expect(div.dataset.isEmpty, isFalse);

    expect(div.dataset.containsValue('foo-value'), isTrue);
    expect(div.dataset.containsValue('bar-value'), isFalse);
    expect(div.dataset.containsKey('foo'), isTrue);
    expect(div.dataset.containsKey('bar'), isFalse);

    bool hasBeenInvoked;
    String f() {
      hasBeenInvoked = true;
      return 'bar-value';
    }

    hasBeenInvoked = false;
    expect(div.dataset.putIfAbsent('bar', f), 'bar-value');
    expect(hasBeenInvoked, isTrue);

    hasBeenInvoked = false;
    expect(div.dataset.putIfAbsent('bar', f), 'bar-value');
    expect(hasBeenInvoked, isFalse);

    final keys = <String>[];
    final values = <String>[];
    div.dataset.forEach((String key, String value) {
      keys.add(key);
      values.add(value);
    });
    expect(keys, unorderedEquals(['foo', 'bar']));
    expect(values, unorderedEquals(['foo-value', 'bar-value']));

    expect(new List<String>.from(div.dataset.keys),
        unorderedEquals(['foo', 'bar']));
    expect(new List<String>.from(div.dataset.values),
        unorderedEquals(['foo-value', 'bar-value']));

    expect(div.dataset.length, 2);
    expect(div.dataset.isEmpty, isFalse);

    expect(div.dataset.remove('qux'), isNull);
    expect(div.dataset.length, 2);
    expect(div.dataset.isEmpty, isFalse);

    expect(div.dataset.remove('foo'), 'foo-value');
    expect(div.dataset.length, 1);
    expect(div.dataset.isEmpty, isFalse);

    div.dataset.clear();
    expect(div.dataset.length, 0);
    expect(div.dataset.isEmpty, isTrue);

    Element otherDiv = new Element.html(
        '<div id="dataDiv" data-my-message="Hello World"></div>',
        treeSanitizer: new NullTreeSanitizer());
    expect(otherDiv.dataset.containsKey('myMessage'), isTrue);

    Element anotherDiv = new Element.html(
        '<div id="dataDiv" data-eggs="bacon"></div>',
        treeSanitizer: new NullTreeSanitizer());
    expect(anotherDiv.dataset.containsKey('eggs'), isTrue);
  });
}
