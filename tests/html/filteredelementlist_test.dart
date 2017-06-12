library filteredelementlist_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:html_common';

main() {
  var t1 = new Text('T1'),
      t2 = new Text('T2'),
      t3 = new Text('T3'),
      t4 = new Text('T4');

  var d1 = new DivElement(), d2 = new DivElement(), d3 = new DivElement();

  createTestDiv() {
    var testDiv = new DivElement();
    testDiv
      ..append(t1)
      ..append(d1)
      ..append(t2)
      ..append(d2)
      ..append(t3)
      ..append(d3)
      ..append(t4);
    return testDiv;
  }

  useHtmlConfiguration();

  test('FilteredElementList.insert test', () {
    var i = new DivElement();

    // Insert before first element
    var nodeList = createTestDiv();
    var elementList = new FilteredElementList(nodeList);
    elementList.insert(0, i);
    expect(nodeList.childNodes[0], t1);
    expect(nodeList.childNodes[1], i);
    expect(nodeList.childNodes[2], d1);

    // Insert in middle
    nodeList = createTestDiv();
    elementList = new FilteredElementList(nodeList);
    elementList.insert(1, i);
    expect(nodeList.childNodes[2], t2);
    expect(nodeList.childNodes[3], i);
    expect(nodeList.childNodes[4], d2);

    // Insert before last element
    nodeList = createTestDiv();
    elementList = new FilteredElementList(nodeList);
    elementList.insert(2, i);
    expect(nodeList.childNodes[4], t3);
    expect(nodeList.childNodes[5], i);
    expect(nodeList.childNodes[6], d3);
  });

  test('FilteredElementList.insertAll test', () {
    var i1 = new DivElement(), i2 = new DivElement();

    var it = [i1, i2];

    // Insert before first element
    var nodeList = createTestDiv();
    var elementList = new FilteredElementList(nodeList);
    elementList.insertAll(0, it);
    expect(nodeList.childNodes[0], t1);
    expect(nodeList.childNodes[1], i1);
    expect(nodeList.childNodes[2], i2);
    expect(nodeList.childNodes[3], d1);

    // Insert in middle
    nodeList = createTestDiv();
    elementList = new FilteredElementList(nodeList);
    elementList.insertAll(1, it);
    expect(nodeList.childNodes[2], t2);
    expect(nodeList.childNodes[3], i1);
    expect(nodeList.childNodes[4], i2);
    expect(nodeList.childNodes[5], d2);

    // Insert before last element
    nodeList = createTestDiv();
    elementList = new FilteredElementList(nodeList);
    elementList.insertAll(2, it);
    expect(nodeList.childNodes[4], t3);
    expect(nodeList.childNodes[5], i1);
    expect(nodeList.childNodes[6], i2);
    expect(nodeList.childNodes[7], d3);
  });

  test('FilteredElementList.insertAndRemove', () {
    var emptyDiv = new DivElement();
    var elementList = new FilteredElementList(emptyDiv);
    expect(() => elementList[0], throwsA(isRangeError));
    expect(() => elementList.insert(2, new BRElement()), throwsA(isRangeError));
    var br = new BRElement();
    elementList.insert(0, br);
    expect(elementList.removeLast(), br);
    elementList.add(br);
    expect(elementList.remove(br), isTrue);
    var br2 = new BRElement();
    elementList.add(br);
    expect(elementList.remove(br2), isFalse);
    expect(elementList[0], br);
    expect(() => elementList[1], throwsA(isRangeError));
  });
}
