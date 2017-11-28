import 'dart:html';

import 'package:expect/minitest.dart';

bool isChecked(Element e) => (e as CheckboxInputElement).checked;
bool isUnchecked(Element e) => !(e as CheckboxInputElement).checked;

// Test that List<Element> implements List<T>
main() {
  Element insertTestDiv() {
    Element element = new Element.tag('div');
    element.innerHtml = r"""
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
    document.body.append(element);
    return element;
  }

  test('IsList', () {
    Element root = insertTestDiv();

    List<Element> eachChecked = document.query('#allChecked').children;

    expect(eachChecked is List, isTrue);

    root.remove();
  });
  test('Every', () {
    Element root = insertTestDiv();

    List<Element> eachChecked = document.query('#allChecked').children;

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(eachChecked.length, 4);
    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(eachChecked.every(isChecked), isTrue);
    expect(eachChecked.every(isUnchecked), isFalse);
    expect(someChecked.every(isChecked), isFalse);
    expect(someChecked.every(isUnchecked), isFalse);
    expect(noneChecked.every(isChecked), isFalse);
    expect(noneChecked.every(isUnchecked), isTrue);

    root.remove();
  });
  test('Some', () {
    Element root = insertTestDiv();

    List<Element> eachChecked = document.query('#allChecked').children;

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(eachChecked.length, 4);
    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(eachChecked.any(isChecked), isTrue);
    expect(eachChecked.any(isUnchecked), isFalse);
    expect(someChecked.any(isChecked), isTrue);
    expect(someChecked.any(isUnchecked), isTrue);
    expect(noneChecked.any(isChecked), isFalse);
    expect(noneChecked.any(isUnchecked), isTrue);

    root.remove();
  });
  test('Filter', () {
    Element root = insertTestDiv();

    List<Element> eachChecked = document.query('#allChecked').children;

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(eachChecked.length, 4);
    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(eachChecked.where(isChecked).length, 4);
    expect(eachChecked.where(isUnchecked).length, 0);
    expect(someChecked.where(isChecked).length, 2);
    expect(someChecked.where(isUnchecked).length, 2);
    expect(noneChecked.where(isChecked).length, 0);
    expect(noneChecked.where(isUnchecked).length, 4);

    root.remove();
  });
  test('IsEmpty', () {
    Element root = insertTestDiv();

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> emptyDiv = document.query('#emptyDiv').children;

    expect(someChecked.length, 4);
    expect(emptyDiv.length, 0);

    expect(someChecked.isEmpty, isFalse);
    expect(emptyDiv.isEmpty, isTrue);

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

    List<Element> eachChecked = document.query('#allChecked').children;

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(eachChecked.length, 4);
    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(countWithForEach(eachChecked, isChecked), 4);
    expect(countWithForEach(eachChecked, isUnchecked), 0);
    expect(countWithForEach(someChecked, isChecked), 2);
    expect(countWithForEach(someChecked, isUnchecked), 2);
    expect(countWithForEach(noneChecked, isChecked), 0);
    expect(countWithForEach(noneChecked, isUnchecked), 4);

    root.remove();
  });

  int countWithForLoop(collection, predicate) {
    int count = 0;
    for (var element in collection) {
      if (predicate(element)) count++;
    }
    return count;
  }

  test('ForLoop', () {
    // Uses iterator.
    Element root = insertTestDiv();

    List<Element> eachChecked = document.query('#allChecked').children;

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(eachChecked.length, 4);
    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(countWithForLoop(eachChecked, isChecked), 4);
    expect(countWithForLoop(eachChecked, isUnchecked), 0);
    expect(countWithForLoop(someChecked, isChecked), 2);
    expect(countWithForLoop(someChecked, isUnchecked), 2);
    expect(countWithForLoop(noneChecked, isChecked), 0);
    expect(countWithForLoop(noneChecked, isUnchecked), 4);

    root.remove();
  });
  test('Last', () {
    Element root = insertTestDiv();

    List<Element> someChecked = document.query('#someChecked').children;

    expect(someChecked.length, 4);

    expect(someChecked.last, equals(someChecked[3]));

    root.remove();
  });
  test('IndexOf', () {
    Element root = insertTestDiv();

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(someChecked.indexOf(someChecked[0], 0), 0);
    expect(someChecked.indexOf(someChecked[1], 0), 1);
    expect(someChecked.indexOf(someChecked[2], 0), 2);
    expect(someChecked.indexOf(someChecked[3], 0), 3);

    expect(someChecked.indexOf(someChecked[0], 1), -1);
    expect(someChecked.indexOf(someChecked[1], 2), -1);
    expect(someChecked.indexOf(someChecked[2], 3), -1);
    expect(someChecked.indexOf(someChecked[3], 4), -1);

    expect(someChecked.indexOf(noneChecked[0], 0), -1);
    expect(noneChecked.indexOf(someChecked[0], 0), -1);
    expect(someChecked.indexOf(noneChecked[1], 0), -1);
    expect(noneChecked.indexOf(someChecked[1], 0), -1);

    root.remove();
  });
  test('LastIndexOf', () {
    Element root = insertTestDiv();

    List<Element> someChecked = document.query('#someChecked').children;

    List<Element> noneChecked = document.query('#noneChecked').children;

    expect(someChecked.length, 4);
    expect(noneChecked.length, 4);

    expect(someChecked.lastIndexOf(someChecked[0], 3), 0);
    expect(someChecked.lastIndexOf(someChecked[1], 3), 1);
    expect(someChecked.lastIndexOf(someChecked[2], 3), 2);
    expect(someChecked.lastIndexOf(someChecked[3], 3), 3);

    expect(someChecked.lastIndexOf(someChecked[0], -1), -1);
    expect(someChecked.lastIndexOf(someChecked[1], 0), -1);
    expect(someChecked.lastIndexOf(someChecked[2], 1), -1);
    expect(someChecked.lastIndexOf(someChecked[3], 2), -1);

    expect(someChecked.lastIndexOf(noneChecked[0], 3), -1);
    expect(noneChecked.lastIndexOf(someChecked[0], 3), -1);
    expect(someChecked.lastIndexOf(noneChecked[1], 3), -1);
    expect(noneChecked.lastIndexOf(someChecked[1], 3), -1);

    root.remove();
  });
}
