#library('ElementListTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// Test that List<Element> implements List<T>
main() {
  Element insertTestDiv() {
    Element element = new Element.tag('div');
    element.innerHTML = r"""
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
    document.body.nodes.add(element);
    return element;
  }

  useHtmlConfiguration();
  test('IsList', () {
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    Expect.isTrue(eachChecked is List);

    root.remove();
  });
  test('Every', () {
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.isTrue(eachChecked.every((x) => x.checked));
    Expect.isFalse(eachChecked.every((x) => !x.checked));
    Expect.isFalse(someChecked.every((x) => x.checked));
    Expect.isFalse(someChecked.every((x) => !x.checked));
    Expect.isFalse(noneChecked.every((x) => x.checked));
    Expect.isTrue(noneChecked.every((x) => !x.checked));

    root.remove();
  });
  test('Some', () {
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.isTrue(eachChecked.some((x) => x.checked));
    Expect.isFalse(eachChecked.some((x) => !x.checked));
    Expect.isTrue(someChecked.some((x) => x.checked));
    Expect.isTrue(someChecked.some((x) => !x.checked));
    Expect.isFalse(noneChecked.some((x) => x.checked));
    Expect.isTrue(noneChecked.some((x) => !x.checked));

    root.remove();
  });
  test('Filter', () {
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, eachChecked.filter((x) => x.checked).length);
    Expect.equals(0, eachChecked.filter((x) => !x.checked).length);
    Expect.equals(2, someChecked.filter((x) => x.checked).length);
    Expect.equals(2, someChecked.filter((x) => !x.checked).length);
    Expect.equals(0, noneChecked.filter((x) => x.checked).length);
    Expect.equals(4, noneChecked.filter((x) => !x.checked).length);

    root.remove();
  });
  test('IsEmpty', () {
    Element root = insertTestDiv();

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> emptyDiv =
        document.query('#emptyDiv').elements;

    Expect.equals(4, someChecked.length);
    Expect.equals(0, emptyDiv.length);

    Expect.isFalse(someChecked.isEmpty);
    Expect.isTrue(emptyDiv.isEmpty);

    root.remove();
  });

  int countWithForEach(collection, predicate) {
    int count = 0;
    collection.forEach((element) {
        if (predicate(element)) count++;
      });
    return count;
  }

  test('ForEach', () {
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, countWithForEach(eachChecked, (x) => x.checked));
    Expect.equals(0, countWithForEach(eachChecked, (x) => !x.checked));
    Expect.equals(2, countWithForEach(someChecked, (x) => x.checked));
    Expect.equals(2, countWithForEach(someChecked, (x) => !x.checked));
    Expect.equals(0, countWithForEach(noneChecked, (x) => x.checked));
    Expect.equals(4, countWithForEach(noneChecked, (x) => !x.checked));

    root.remove();
  });

  int countWithForLoop(collection, predicate) {
    int count = 0;
    for (var element in collection) {
      if (predicate(element)) count++;
    }
    return count;
  }

  test('ForLoop', () {  // Uses iterator.
    Element root = insertTestDiv();

    List<Element> eachChecked =
        document.query('#allChecked').elements;

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

    Expect.equals(4, eachChecked.length);
    Expect.equals(4, someChecked.length);
    Expect.equals(4, noneChecked.length);

    Expect.equals(4, countWithForLoop(eachChecked, (x) => x.checked));
    Expect.equals(0, countWithForLoop(eachChecked, (x) => !x.checked));
    Expect.equals(2, countWithForLoop(someChecked, (x) => x.checked));
    Expect.equals(2, countWithForLoop(someChecked, (x) => !x.checked));
    Expect.equals(0, countWithForLoop(noneChecked, (x) => x.checked));
    Expect.equals(4, countWithForLoop(noneChecked, (x) => !x.checked));

    root.remove();
  });
  test('Last', () {
    Element root = insertTestDiv();

    List<Element> someChecked =
        document.query('#someChecked').elements;

    Expect.equals(4, someChecked.length);

    Expect.equals(someChecked[3], someChecked.last);

    root.remove();
  });
  test('IndexOf', () {
    Element root = insertTestDiv();

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

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

    root.remove();
  });
  test('LastIndexOf', () {
    Element root = insertTestDiv();

    List<Element> someChecked =
        document.query('#someChecked').elements;

    List<Element> noneChecked =
        document.query('#noneChecked').elements;

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

    root.remove();
  });
}
