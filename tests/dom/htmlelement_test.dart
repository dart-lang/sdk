#library('HTMLElementTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();
  test('InnerHTML', () {
    HTMLElement element = document.createElement('div');
    element.id = 'test';
    element.innerHTML = 'Hello World';
    document.body.appendChild(element);

    element = document.getElementById('test');
    Expect.stringEquals('Hello World', element.innerHTML);
    document.body.removeChild(element);
  });
  test('HTMLTable', () {
    HTMLElement table = document.createElement('table');

    HTMLTableRowElement row = document.createElement('tr');
    table.appendChild(row);

    row.appendChild(document.createElement('td'));
    row.appendChild(document.createElement('td'));

    Expect.equals(2, row.cells.length);

    HTMLTableRowElement headerRow = table.rows.item(0);
    Expect.equals(2, headerRow.cells.length);
  });
  test('Dataset', () {
    HTMLElement div = document.createElement('div');

    Expect.isTrue(div.dataset.isEmpty());
    Expect.equals('', div.dataset['foo']);
    Expect.isTrue(div.dataset.isEmpty());

    div.dataset['foo'] = 'foo-value';
    Expect.equals('foo-value', div.dataset['foo']);
    Expect.isFalse(div.dataset.isEmpty());

    Expect.isTrue(div.dataset.containsValue('foo-value'));
    Expect.isFalse(div.dataset.containsValue('bar-value'));
    Expect.isTrue(div.dataset.containsKey('foo'));
    Expect.isFalse(div.dataset.containsKey('bar'));

    bool hasBeenInvoked;
    String f() {
      hasBeenInvoked = true;
      return 'bar-value';
    }

    hasBeenInvoked = false;
    Expect.equals('bar-value', div.dataset.putIfAbsent('bar', f));
    Expect.isTrue(hasBeenInvoked);

    hasBeenInvoked = false;
    Expect.equals('bar-value', div.dataset.putIfAbsent('bar', f));
    Expect.isFalse(hasBeenInvoked);

    final keys = <String> [];
    final values = <String> [];
    div.dataset.forEach(void f(String key, String value) {
        keys.add(key);
        values.add(value);
    });
    Expect.setEquals(const <String> ['foo', 'bar'], keys);
    Expect.setEquals(const <String> ['foo-value', 'bar-value'], values);

    Expect.setEquals(const <String> ['foo', 'bar'],
                     new List<String>.from(div.dataset.getKeys()));
    Expect.setEquals(const <String> ['foo-value', 'bar-value'],
                     new List<String>.from(div.dataset.getValues()));

    Expect.equals(2, div.dataset.length);
    Expect.isFalse(div.dataset.isEmpty());

    Expect.isNull(div.dataset.remove('qux'));
    Expect.equals(2, div.dataset.length);
    Expect.isFalse(div.dataset.isEmpty());

    Expect.equals('foo-value', div.dataset.remove('foo'));
    Expect.equals(1, div.dataset.length);
    Expect.isFalse(div.dataset.isEmpty());

    div.dataset.clear();
    Expect.equals(0, div.dataset.length);
    Expect.isTrue(div.dataset.isEmpty());
  });
}
