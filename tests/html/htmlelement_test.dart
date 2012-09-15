#library('ElementTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('InnerHTML', () {
    Element element = new Element.tag('div');
    element.id = 'test';
    element.innerHTML = 'Hello World';
    document.body.nodes.add(element);

    element = document.query('#test');
    Expect.stringEquals('Hello World', element.innerHTML);
    element.remove();
  });
  test('HTMLTable', () {
    Element table = new Element.tag('table');

    TableRowElement row = new Element.tag('tr');
    table.nodes.add(row);

    row.nodes.add(new Element.tag('td'));
    row.nodes.add(new Element.tag('td'));

    Expect.equals(2, row.cells.length);

    TableRowElement headerRow = table.rows[0];
    Expect.equals(2, headerRow.cells.length);
  });
  test('dataAttributes', () {
    Element div = new Element.tag('div');

    Expect.isTrue(div.dataAttributes.isEmpty());
    Expect.equals(null, div.dataAttributes['foo']);
    Expect.isTrue(div.dataAttributes.isEmpty());

    div.dataAttributes['foo'] = 'foo-value';
    Expect.equals('foo-value', div.dataAttributes['foo']);
    Expect.isFalse(div.dataAttributes.isEmpty());

    Expect.isTrue(div.dataAttributes.containsValue('foo-value'));
    Expect.isFalse(div.dataAttributes.containsValue('bar-value'));
    Expect.isTrue(div.dataAttributes.containsKey('foo'));
    Expect.isFalse(div.dataAttributes.containsKey('bar'));

    bool hasBeenInvoked;
    String f() {
      hasBeenInvoked = true;
      return 'bar-value';
    }

    hasBeenInvoked = false;
    Expect.equals('bar-value', div.dataAttributes.putIfAbsent('bar', f));
    Expect.isTrue(hasBeenInvoked);

    hasBeenInvoked = false;
    Expect.equals('bar-value', div.dataAttributes.putIfAbsent('bar', f));
    Expect.isFalse(hasBeenInvoked);

    final keys = <String> [];
    final values = <String> [];
    div.dataAttributes.forEach(void f(String key, String value) {
        keys.add(key);
        values.add(value);
    });
    Expect.setEquals(const <String> ['foo', 'bar'], keys);
    Expect.setEquals(const <String> ['foo-value', 'bar-value'], values);

    Expect.setEquals(const <String> ['foo', 'bar'],
                     new List<String>.from(div.dataAttributes.getKeys()));
    Expect.setEquals(const <String> ['foo-value', 'bar-value'],
                     new List<String>.from(div.dataAttributes.getValues()));

    Expect.equals(2, div.dataAttributes.length);
    Expect.isFalse(div.dataAttributes.isEmpty());

    Expect.isNull(div.dataAttributes.remove('qux'));
    Expect.equals(2, div.dataAttributes.length);
    Expect.isFalse(div.dataAttributes.isEmpty());

    Expect.equals('foo-value', div.dataAttributes.remove('foo'));
    Expect.equals(1, div.dataAttributes.length);
    Expect.isFalse(div.dataAttributes.isEmpty());

    div.dataAttributes.clear();
    Expect.equals(0, div.dataAttributes.length);
    Expect.isTrue(div.dataAttributes.isEmpty());
  });
}
