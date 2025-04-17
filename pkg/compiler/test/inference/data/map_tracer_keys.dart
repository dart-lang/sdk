// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
}

/*member: aDouble1:[null|exact=JSNumNotInt|powerset={null}{I}]*/
dynamic aDouble1 = 42.5;

/*member: aList1:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
dynamic aList1 = [42];

/*member: consume1:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
consume1(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/ x,
) => x;

/*member: test1:[null|powerset={null}]*/
test1() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: [null|exact=JSNumNotInt|powerset={null}{I}]}, powerset: {N})*/
      ['d'] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: [null|exact=JSNumNotInt|powerset={null}{I}]}, powerset: {N})*/
          keys) {
    aDouble1 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: [null|exact=JSNumNotInt|powerset={null}{I}]}, powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume1(aList1);
}

/*member: aDouble2:[null|exact=JSNumNotInt|powerset={null}{I}]*/
dynamic aDouble2 = 42.5;

/*member: aList2:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
dynamic aList2 = [42];

/*member: consume2:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
consume2(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/ x,
) => x;

/*member: test2:[null|powerset={null}]*/
test2() {
  dynamic theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], powerset: {N})*/
      [aList2] =
      5.5;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], powerset: {N})*/
          keys) {
    aDouble2 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume2(aList2);
}

/*member: aDouble3:Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I})*/
dynamic aDouble3 = 42.5;

/*member: aList3:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
dynamic aList3 = [42];

/*member: consume3:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
consume3(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/ x,
) => x;

/*member: test3:[null|powerset={null}]*/
test3() {
  dynamic theMap = <dynamic, dynamic>{'a': 2.2, 'b': 3.3, 'c': 4.4};
  theMap
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I}), map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {null}{I})}, powerset: {N})*/
      ['d'] =
      aList3;
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I}), map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {null}{I})}, powerset: {N})*/
          keys) {
    aDouble3 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I}), map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {null}{I})}, powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume3(aList3);
}

/*member: aDouble4:[null|exact=JSNumNotInt|powerset={null}{I}]*/
dynamic aDouble4 = 42.5;

/*member: aList4:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
dynamic aList4 = [42];

/*member: consume4:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
consume4(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/ x,
) => x;

/*member: test4:[null|powerset={null}]*/
test4() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: [exact=JSNumNotInt|powerset={I}]}, powerset: {N})*/
          keys) {
    aDouble4 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSNumNotInt|powerset={null}{I}], map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: [exact=JSNumNotInt|powerset={I}]}, powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume4(aList4);
}

/*member: aDouble5:[null|exact=JSNumNotInt|powerset={null}{I}]*/
dynamic aDouble5 = 42.5;

/*member: aList5:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
dynamic aList5 = [42];

/*member: consume5:Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/
consume5(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [null|subclass=Object|powerset={null}{IN}], length: null, powerset: {I})*/ x,
) => x;

/*member: test5:[null|powerset={null}]*/
test5() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, aList5: 5.5};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Map([exact=JsLinkedHashMap|powerset={N}], key: Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], powerset: {I}), value: [null|exact=JSNumNotInt|powerset={null}{I}], powerset: {N})*/
          keys) {
    aDouble5 =
        theMap
        /*Map([exact=JsLinkedHashMap|powerset={N}], key: Union([exact=JSExtendableArray|powerset={I}], [exact=JSString|powerset={I}], powerset: {I}), value: [null|exact=JSNumNotInt|powerset={null}{I}], powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume5(aList5);
}

/*member: aDouble6:Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I})*/
dynamic aDouble6 = 42.5;
/*member: aList6:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
dynamic aList6 = [42];

/*member: consume6:Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
consume6(
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/ x,
) => x;

/*member: test6:[null|powerset={null}]*/
test6() {
  var theMap = {'a': 2.2, 'b': 3.3, 'c': 4.4, 'd': aList6};
  /*iterator: [exact=LinkedHashMapKeysIterable|powerset={N}]*/
  /*current: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  /*moveNext: [exact=LinkedHashMapKeyIterator|powerset={N}]*/
  for (var key
      in theMap
          .
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I}), map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})}, powerset: {N})*/
          keys) {
    aDouble6 =
        theMap
        /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: Union(null, [exact=JSExtendableArray|powerset={I}], [exact=JSNumNotInt|powerset={I}], powerset: {null}{I}), map: {a: [exact=JSNumNotInt|powerset={I}], b: [exact=JSNumNotInt|powerset={I}], c: [exact=JSNumNotInt|powerset={I}], d: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})}, powerset: {N})*/
        [key];
  }
  // We have to reference it somewhere, so that it always gets resolved.
  consume6(aList6);
}
