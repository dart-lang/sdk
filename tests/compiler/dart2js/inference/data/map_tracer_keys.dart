// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}

/*element: aDouble1:[null|exact=JSDouble]*/
dynamic aDouble1 = 42.5;

/*element: aList1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList1 = [42];

/*element: consume1:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume1(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*element: test1:[null]*/
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

/*element: aDouble2:[null|exact=JSDouble]*/
dynamic aDouble2 = 42.5;

/*element: aList2:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
dynamic aList2 = [42];

/*element: consume2:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
consume2(
        /*Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ x) =>
    x;

/*element: test2:[null]*/
test2() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Map([subclass=JsLinkedHashMap], key: Union([exact=JSExtendableArray], [exact=JSString]), value: [null|exact=JSDouble])*/
      [aList2] = 5.5;
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Map([subclass=JsLinkedHashMap], key: Union([exact=JSExtendableArray], [exact=JSString]), value: [null|exact=JSDouble])*/
      keys) {
    aDouble2 = theMap
        /*Map([subclass=JsLinkedHashMap], key: Union([exact=JSExtendableArray], [exact=JSString]), value: [null|exact=JSDouble])*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume2(aList2);
}

/*element: aDouble3:Union([exact=JSDouble], [null|exact=JSExtendableArray])*/
dynamic aDouble3 = 42.5;

/*element: aList3:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
dynamic aList3 = [42];

/*element: consume3:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
consume3(
        /*Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ x) =>
    x;

/*element: test3:[null]*/
test3() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [null|exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)})*/
      ['d'] = aList3;
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [null|exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)})*/
      keys) {
    aDouble3 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [null|exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([null|exact=JSExtendableArray], element: [null|subclass=Object], length: null)})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume3(aList3);
}

/*element: aDouble4:[null|exact=JSDouble]*/
dynamic aDouble4 = 42.5;

/*element: aList4:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList4 = [42];

/*element: consume4:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume4(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*element: test4:[null]*/
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

/*element: aDouble5:[null|exact=JSDouble]*/
dynamic aDouble5 = 42.5;

/*element: aList5:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
dynamic aList5 = [42];

/*element: consume5:Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/
consume5(
        /*Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null)*/ x) =>
    x;

/*element: test5:[null]*/
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

/*element: aDouble6:Union([null|exact=JSDouble], [null|exact=JSExtendableArray])*/
dynamic aDouble6 = 42.5;
/*element: aList6:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
dynamic aList6 = [42];

/*element: consume6:Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
consume6(
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/ x) =>
    x;

/*element: test6:[null]*/
test6() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': aList6};
  /*iterator: [exact=LinkedHashMapKeyIterable]*/
  /*current: [exact=LinkedHashMapKeyIterator]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator]*/
  for (var key in theMap.
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [null|exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
      keys) {
    aDouble6 = theMap
        /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([null|exact=JSDouble], [null|exact=JSExtendableArray]), map: {a: [exact=JSDouble], b: [exact=JSDouble], c: [exact=JSDouble], d: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume6(aList6);
}
