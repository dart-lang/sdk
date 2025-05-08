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
}

/*member: dictionaryA1:Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {N}{O})*/
dynamic dictionaryA1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB1:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}], value: "anotherString", powerset: {null}{I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}]}, powerset: {N}{O})*/
dynamic dictionaryB1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: otherDict1:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), map: {stringTwo: Value([exact=JSString|powerset={I}{O}], value: "anotherString", powerset: {I}{O}), intTwo: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
dynamic otherDict1 = {'stringTwo': "anotherString", 'intTwo': 84};

/*member: int1:[exact=JSUInt31|powerset={I}{O}]*/
dynamic int1 = 0;

/*member: anotherInt1:[exact=JSUInt31|powerset={I}{O}]*/
dynamic anotherInt1 = 0;

/*member: nullOrInt1:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
dynamic nullOrInt1 = 0;

/*member: dynamic1:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
dynamic dynamic1 = 0;

/*member: test1:[null|powerset={null}]*/
test1() {
  dictionaryA1
      . /*invoke: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {N}{O})*/ addAll(
        otherDict1,
      );
  dictionaryB1
      . /*invoke: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}], value: "anotherString", powerset: {null}{I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}]}, powerset: {N}{O})*/ addAll(
        {'stringTwo': "anotherString", 'intTwo': 84},
      );
  int1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}], value: "anotherString", powerset: {null}{I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}]}, powerset: {N}{O})*/
      ['int'];
  anotherInt1 =
      otherDict1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), map: {stringTwo: Value([exact=JSString|powerset={I}{O}], value: "anotherString", powerset: {I}{O}), intTwo: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
      ['intTwo'];
  dynamic1 =
      dictionaryA1 /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [null|subclass=Object|powerset={null}{IN}{GFUO}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {N}{O})*/ ['int'];
  nullOrInt1 =
      dictionaryB1
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G}), stringTwo: Value([null|exact=JSString|powerset={null}{I}{O}], value: "anotherString", powerset: {null}{I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}]}, powerset: {N}{O})*/
      ['intTwo'];
}

/*member: dictionaryA2:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
dynamic dictionaryA2 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};

/*member: dictionaryB2:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), intTwo: [exact=JSUInt31|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
dynamic dictionaryB2 = {'string': "aString", 'intTwo': 42, 'list': []};

/*member: nullOrInt2:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
dynamic nullOrInt2 = 0;

/*member: aString2:[exact=JSString|powerset={I}{O}]*/
dynamic aString2 = "";

/*member: doubleOrNull2:[null|exact=JSNumNotInt|powerset={null}{I}{O}]*/
dynamic doubleOrNull2 = 22.2;

/*member: test2:[null|powerset={null}]*/
test2() {
  var union =
      dictionaryA2
          /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
          ['foo']
          ? dictionaryA2
          : dictionaryB2;
  nullOrInt2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}], string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
      ['intTwo'];
  aString2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}], string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
      ['string'];
  doubleOrNull2 =
      union
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {int: [null|exact=JSUInt31|powerset={null}{I}{O}], double: [null|exact=JSNumNotInt|powerset={null}{I}{O}], string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), intTwo: [null|exact=JSUInt31|powerset={null}{I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
      ['double'];
}

/*member: dictionary3:Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
dynamic dictionary3 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': [],
};
/*member: keyD3:Value([exact=JSString|powerset={I}{O}], value: "double", powerset: {I}{O})*/
dynamic keyD3 = 'double';

/*member: keyI3:Value([exact=JSString|powerset={I}{O}], value: "int", powerset: {I}{O})*/
dynamic keyI3 = 'int';

/*member: keyN3:Value([exact=JSString|powerset={I}{O}], value: "notFoundInMap", powerset: {I}{O})*/
dynamic keyN3 = 'notFoundInMap';

/*member: knownDouble3:[exact=JSNumNotInt|powerset={I}{O}]*/
dynamic knownDouble3 = 42.2;

/*member: intOrNull3:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
dynamic intOrNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
    [keyI3];

/*member: justNull3:[null|powerset={null}]*/
dynamic justNull3 =
    dictionary3
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
    [keyN3];

/*member: test3:[null|powerset={null}]*/
test3() {
  knownDouble3 =
      dictionary3
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSExtendableArray|powerset={I}{G}], [exact=JSNumNotInt|powerset={I}{O}], [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{GO}), map: {string: Value([exact=JSString|powerset={I}{O}], value: "aString", powerset: {I}{O}), int: [exact=JSUInt31|powerset={I}{O}], double: [exact=JSNumNotInt|powerset={I}{O}], list: Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})}, powerset: {N}{O})*/
      [keyD3];
  // ignore: unused_local_variable
  var x = [intOrNull3, justNull3];
}

class A4 {
  /*member: A4.:[exact=A4|powerset={N}{O}]*/
  A4();
  /*member: A4.foo4:[exact=JSUInt31|powerset={I}{O}]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), map: {anInt: [exact=JSUInt31|powerset={I}{O}], aString: Value([exact=JSString|powerset={I}{O}], value: "theString", powerset: {I}{O})}, powerset: {N}{O})*/ value,
  ) {
    return value /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), map: {anInt: [exact=JSUInt31|powerset={I}{O}], aString: Value([exact=JSString|powerset={I}{O}], value: "theString", powerset: {I}{O})}, powerset: {N}{O})*/ ['anInt'];
  }
}

class B4 {
  /*member: B4.:[exact=B4|powerset={N}{O}]*/
  B4();

  /*member: B4.foo4:[exact=JSUInt31|powerset={I}{O}]*/
  foo4(
    /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), map: {anInt: [exact=JSUInt31|powerset={I}{O}], aString: Value([exact=JSString|powerset={I}{O}], value: "theString", powerset: {I}{O})}, powerset: {N}{O})*/ value,
  ) {
    return 0;
  }
}

/*member: test4:[null|powerset={null}]*/
test4() {
  var dictionary = {'anInt': 42, 'aString': "theString"};
  var it;
  if ([true, false]
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSBool|powerset={I}{O}], length: 2, powerset: {I}{G})*/
  [0]) {
    it = A4();
  } else {
    it = B4();
  }
  print(
    it. /*invoke: Union([exact=A4|powerset={N}{O}], [exact=B4|powerset={N}{O}], powerset: {N}{O})*/ foo4(
          dictionary,
        ) /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ +
        2,
  );
}

/*member: dict5:Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {null}{N}{O})*/
dynamic dict5 = makeMap5([1, 2]);

/*member: notInt5:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
dynamic notInt5 = 0;

/*member: alsoNotInt5:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
dynamic alsoNotInt5 = 0;

/*member: makeMap5:Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {N}{O})*/
makeMap5(
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/ values,
) {
  return {
    'moo':
        values
        /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/
        [0],
    'boo':
        values
        /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/
        [1],
  };
}

/*member: test5:[null|powerset={null}]*/
test5() {
  dict5
      /*update: Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {null}{N}{O})*/
      ['goo'] =
      42;
  var closure =
      /*Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {null}{N}{O})*/
      () => dict5;
  notInt5 = closure()['boo'];
  alsoNotInt5 =
      dict5
      /*Map([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|subclass=Object|powerset={null}{IN}{GFUO}], powerset: {null}{N}{O})*/
      ['goo'];
  print("$notInt5 and $alsoNotInt5.");
}
