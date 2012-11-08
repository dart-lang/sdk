library ElementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('InnerHTML', () {
    Element element = new Element.tag('div');
    element.id = 'test';
    element.innerHTML = 'Hello World';
    document.body.nodes.add(element);

    element = document.query('#test');
    expect(element.innerHTML, 'Hello World');
    element.remove();
  });
  test('HTMLTable', () {
    Element table = new Element.tag('table');

    TableRowElement row = new Element.tag('tr');
    table.nodes.add(row);

    row.nodes.add(new Element.tag('td'));
    row.nodes.add(new Element.tag('td'));

    expect(row.cells.length, 2);

    TableRowElement headerRow = table.rows[0];
    expect(headerRow.cells.length, 2);
  });
  test('dataAttributes', () {
    Element div = new Element.tag('div');

    expect(div.dataAttributes.isEmpty, isTrue);
    expect(div.dataAttributes['foo'], isNull);
    expect(div.dataAttributes.isEmpty, isTrue);

    div.dataAttributes['foo'] = 'foo-value';
    expect(div.dataAttributes['foo'], 'foo-value');
    expect(div.dataAttributes.isEmpty, isFalse);

    expect(div.dataAttributes.containsValue('foo-value'), isTrue);
    expect(div.dataAttributes.containsValue('bar-value'), isFalse);
    expect(div.dataAttributes.containsKey('foo'), isTrue);
    expect(div.dataAttributes.containsKey('bar'), isFalse);

    bool hasBeenInvoked;
    String f() {
      hasBeenInvoked = true;
      return 'bar-value';
    }

    hasBeenInvoked = false;
    expect(div.dataAttributes.putIfAbsent('bar', f), 'bar-value');
    expect(hasBeenInvoked, isTrue);

    hasBeenInvoked = false;
    expect(div.dataAttributes.putIfAbsent('bar', f), 'bar-value');
    expect(hasBeenInvoked, isFalse);

    final keys = <String> [];
    final values = <String> [];
    div.dataAttributes.forEach(void f(String key, String value) {
        keys.add(key);
        values.add(value);
    });
    expect(keys, unorderedEquals(['foo', 'bar']));
    expect(values, unorderedEquals(['foo-value', 'bar-value']));

    expect(new List<String>.from(div.dataAttributes.keys), 
        unorderedEquals(['foo', 'bar']));
    expect(new List<String>.from(div.dataAttributes.values),
        unorderedEquals(['foo-value', 'bar-value']));

    expect(div.dataAttributes.length, 2);
    expect(div.dataAttributes.isEmpty, isFalse);

    expect(div.dataAttributes.remove('qux'), isNull);
    expect(div.dataAttributes.length, 2);
    expect(div.dataAttributes.isEmpty, isFalse);

    expect(div.dataAttributes.remove('foo'), 'foo-value');
    expect(div.dataAttributes.length, 1);
    expect(div.dataAttributes.isEmpty, isFalse);

    div.dataAttributes.clear();
    expect(div.dataAttributes.length, 0);
    expect(div.dataAttributes.isEmpty, isTrue);
  });
}
