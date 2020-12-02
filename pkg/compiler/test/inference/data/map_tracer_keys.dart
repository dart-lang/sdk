// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}

/*member: aDouble1:[null|exact=JSDouble]*/
dynamic aDouble1 = 42.5;

/*member: aList1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList1 = [42];

/*member: consume1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume1(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*member: test1:[null]*/
test1() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble], map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: [null|exact=JSDouble]})*/
      ['d'] = 5.5;
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble], map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: [null|exact=JSDouble]})*/
      keys) {
    aDouble1 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble], map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: [null|exact=JSDouble]})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume1(aList1);
}

/*member: aDouble2:[null|exact=JSDouble]*/
dynamic aDouble2 = 42.5;

/*member: aList2:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
dynamic aList2 = [42];

/*member: consume2:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
consume2(
        /*Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ x) =>
    x;

/*member: test2:[null]*/
test2() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble])*/
      [aList2] = 5.5;
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Map([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble])*/
      keys) {
    aDouble2 = theMap
        /*Map([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble])*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume2(aList2);
}

/*member: aDouble3:Union(null, [exact=JSDouble], [exact=JSExtendableArray])*/
dynamic aDouble3 = 42.5;

/*member: aList3:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList3 = [42];

/*member: consume3:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume3(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*member: test3:[null]*/
test3() {
  dynamic theMap = <dynamic, dynamic>{'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
      ['d'] = aList3;
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
      keys) {
    aDouble3 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume3(aList3);
}

/*member: aDouble4:[null|exact=JSDouble]*/
dynamic aDouble4 = 42.5;

/*member: aList4:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList4 = [42];

/*member: consume4:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume4(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*member: test4:[null]*/
test4() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': 5.5};
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble], map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: [exact=JSDouble]})*/
      keys) {
    aDouble4 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSDouble], map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: [exact=JSDouble]})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume4(aList4);
}

/*member: aDouble5:[null|exact=JSDouble]*/
dynamic aDouble5 = 42.5;

/*member: aList5:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
dynamic aList5 = [42];

/*member: consume5:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
consume5(
        /*Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ x) =>
    x;

/*member: test5:[null]*/
test5() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, aList5: 5.5};
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Map([subclass=JsLinkedHashMap], key: Union([exact=JSExtendableArray], [exact=JSString]), value: [null|exact=JSDouble])*/
      keys) {
    aDouble5 = theMap
        /*Map([subclass=JsLinkedHashMap], key: Union([exact=JSExtendableArray], [exact=JSString]), value: [null|exact=JSDouble])*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume5(aList5);
}

/*member: aDouble6:Union(null, [exact=JSDouble], [exact=JSExtendableArray])*/
dynamic aDouble6 = 42.5;
/*member: aList6:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList6 = [42];

/*member: consume6:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume6(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*member: test6:[null]*/
test6() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': aList6};
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
      keys) {
    aDouble6 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume6(aList6);
}
