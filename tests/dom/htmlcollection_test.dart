#library('HTMLCollectionTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

// Test that HTMLCollection implements List<T>
main() {
  HTMLElement insertTestDiv() {
    HTMLElement element = document.createElement('div');
    element.innerHTML = @"""
<div id='allChecked'>
<input type="checkbox" name="c1" value="1" checked="yes">
<input type="checkbox" name="c2" value="2" checked="yes">
<input type="checkbox" name="c3" value="3" checked="yes">
<input type="checkbox" name="c4" value="4" checked="yes">
</div>
<div id='someChecked'>
<input type="checkbox" name="s1" value="1" checked="yes">
<input type="checkbox" name="s2" value="2">
<input type="checkbox" name="s3" value="3" checked="yes">
<input type="checkbox" name="s4" value="4">
</div>
<div id='noneChecked'>
<input type="checkbox" name="n1" value="1">
<input type="checkbox" name="n2" value="2">
<input type="checkbox" name="n3" value="3">
<input type="checkbox" name="n4" value="4">
</div>
<div id='emptyDiv'></div>
""";
    document.body.appendChild(element);
    return element;
  }

  useDomConfiguration();
  test('IsList', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    Expect.isTrue(eachChecked is List);

    document.body.removeChild(root);
  });
  test('Every', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.isTrue(eachChecked.every((x) => x.checked));
    Expect.isFalse(eachChecked.every((x) => !x.checked));
    Expect.isFalse(someChecked.every((x) => x.checked));
    Expect.isFalse(someChecked.every((x) => !x.checked));
    Expect.isFalse(noneChecked.every((x) => x.checked));
    Expect.isTrue(noneChecked.every((x) => !x.checked));

    document.body.removeChild(root);
  });
  test('Some', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.isTrue(eachChecked.some((x) => x.checked));
    Expect.isFalse(eachChecked.some((x) => !x.checked));
    Expect.isTrue(someChecked.some((x) => x.checked));
    Expect.isTrue(someChecked.some((x) => !x.checked));
    Expect.isFalse(noneChecked.some((x) => x.checked));
    Expect.isTrue(noneChecked.some((x) => !x.checked));

    document.body.removeChild(root);
  });
  test('Filter', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, eachChecked.filter((x) => x.checked).length);
    Expect.equals(0, eachChecked.filter((x) => !x.checked).length);
    Expect.equals(2, someChecked.filter((x) => x.checked).length);
    Expect.equals(2, someChecked.filter((x) => !x.checked).length);
    Expect.equals(0, noneChecked.filter((x) => x.checked).length);
    Expect.equals(4, noneChecked.filter((x) => !x.checked).length);

    document.body.removeChild(root);
  });
  test('IsEmpty', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection emptyDiv =
        document.getElementById('emptyDiv').dynamic.children;

    Expect.equals(4, someChecked.length);
    Expect.equals(0, emptyDiv.length);

    Expect.isFalse(someChecked.isEmpty());
    Expect.isTrue(emptyDiv.isEmpty());

    document.body.removeChild(root);
  });

  int countWithForEach(collection, predicate) {
    int count = 0;
    collection.forEach((element) {
        if (predicate(element)) count++;
      });
    return count;
  }

  test('ForEach', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, countWithForEach(eachChecked, (x) => x.checked));
    Expect.equals(0, countWithForEach(eachChecked, (x) => !x.checked));
    Expect.equals(2, countWithForEach(someChecked, (x) => x.checked));
    Expect.equals(2, countWithForEach(someChecked, (x) => !x.checked));
    Expect.equals(0, countWithForEach(noneChecked, (x) => x.checked));
    Expect.equals(4, countWithForEach(noneChecked, (x) => !x.checked));

    document.body.removeChild(root);
  });

  int countWithForLoop(collection, predicate) {
    int count = 0;
    for (var element in collection) {
      if (predicate(element)) count++;
    }
    return count;
  }

  test('ForLoop', () {  // Uses iterator.
    HTMLElement root = insertTestDiv();

    HTMLCollection eachChecked =
        document.getElementById('allChecked').dynamic.children;

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, countWithForLoop(eachChecked, (x) => x.checked));
    Expect.equals(0, countWithForLoop(eachChecked, (x) => !x.checked));
    Expect.equals(2, countWithForLoop(someChecked, (x) => x.checked));
    Expect.equals(2, countWithForLoop(someChecked, (x) => !x.checked));
    Expect.equals(0, countWithForLoop(noneChecked, (x) => x.checked));
    Expect.equals(4, countWithForLoop(noneChecked, (x) => !x.checked));

    document.body.removeChild(root);
  });
  test('Last', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    Expect.equals(4, someChecked.length);

    Expect.equals(someChecked[3], someChecked.last());

    document.body.removeChild(root);
  });
  test('IndexOf', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(0, someChecked.indexOf(someChecked[0], 0));
    Expect.equals(1, someChecked.indexOf(someChecked[1], 0));
    Expect.equals(2, someChecked.indexOf(someChecked[2], 0));
    Expect.equals(3, someChecked.indexOf(someChecked[3], 0));

    Expect.equals(-1, someChecked.indexOf(someChecked[0], 1));
    Expect.equals(-1, someChecked.indexOf(someChecked[1], 2));
    Expect.equals(-1, someChecked.indexOf(someChecked[2], 3));
    Expect.equals(-1, someChecked.indexOf(someChecked[3], 4));


    Expect.equals(-1, someChecked.indexOf(noneChecked[0], 0));
    Expect.equals(-1, noneChecked.indexOf(someChecked[0], 0));
    Expect.equals(-1, someChecked.indexOf(noneChecked[1], 0));
    Expect.equals(-1, noneChecked.indexOf(someChecked[1], 0));

    document.body.removeChild(root);
  });
  test('LastIndexOf', () {
    HTMLElement root = insertTestDiv();

    HTMLCollection someChecked =
        document.getElementById('someChecked').dynamic.children;

    HTMLCollection noneChecked =
        document.getElementById('noneChecked').dynamic.children;

    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(0, someChecked.lastIndexOf(someChecked[0], 3));
    Expect.equals(1, someChecked.lastIndexOf(someChecked[1], 3));
    Expect.equals(2, someChecked.lastIndexOf(someChecked[2], 3));
    Expect.equals(3, someChecked.lastIndexOf(someChecked[3], 3));

    Expect.equals(-1, someChecked.lastIndexOf(someChecked[0], -1));
    Expect.equals(-1, someChecked.lastIndexOf(someChecked[1], 0));
    Expect.equals(-1, someChecked.lastIndexOf(someChecked[2], 1));
    Expect.equals(-1, someChecked.lastIndexOf(someChecked[3], 2));

    Expect.equals(-1, someChecked.lastIndexOf(noneChecked[0], 3));
    Expect.equals(-1, noneChecked.lastIndexOf(someChecked[0], 3));
    Expect.equals(-1, someChecked.lastIndexOf(noneChecked[1], 3));
    Expect.equals(-1, noneChecked.lastIndexOf(someChecked[1], 3));

    document.body.removeChild(root);
  });
}
