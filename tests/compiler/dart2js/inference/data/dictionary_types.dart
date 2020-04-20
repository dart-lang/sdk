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
}

/*member: dictionaryA1:Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
dynamic dictionaryA1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': []
};

/*member: dictionaryB1:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
dynamic dictionaryB1 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': []
};

/*member: otherDict1:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSString], [exact=JSUInt31]), map: {stringTwo: Value([exact=JSString], value: "anotherString"), intTwo: [exact=JSUInt31]})*/
dynamic otherDict1 = {'stringTwo': "anotherString", 'intTwo': 84};

/*member: int1:[exact=JSUInt31]*/
dynamic int1 = 0;

/*member: anotherInt1:[exact=JSUInt31]*/
dynamic anotherInt1 = 0;

/*member: nullOrInt1:[null|exact=JSUInt31]*/
dynamic nullOrInt1 = 0;

/*member: dynamic1:[null|subclass=Object]*/
dynamic dynamic1 = 0;

/*member: test1:[null]*/
test1() {
  dictionaryA1
      . /*invoke: Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
      addAll(otherDict1);
  dictionaryB1
      . /*invoke: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      addAll({'stringTwo': "anotherString", 'intTwo': 84});
  int1 = dictionaryB1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      ['int'];
  anotherInt1 = otherDict1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSString], [exact=JSUInt31]), map: {stringTwo: Value([exact=JSString], value: "anotherString"), intTwo: [exact=JSUInt31]})*/
      ['intTwo'];
  dynamic1 = dictionaryA1
      /*Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/ [
      'int'];
  nullOrInt1 = dictionaryB1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      ['intTwo'];
}

/*member: dictionaryA2:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
dynamic dictionaryA2 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': []
};

/*member: dictionaryB2:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), intTwo: [exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
dynamic dictionaryB2 = {'string': "aString", 'intTwo': 42, 'list': []};

/*member: nullOrInt2:[null|exact=JSUInt31]*/
dynamic nullOrInt2 = 0;

/*member: aString2:[exact=JSString]*/
dynamic aString2 = "";

/*member: doubleOrNull2:[null|exact=JSDouble]*/
dynamic doubleOrNull2 = 22.2;

/*member: test2:[null]*/
test2() {
  var union = dictionaryA2
          /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
          ['foo']
      ? dictionaryA2
      : dictionaryB2;
  nullOrInt2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['intTwo'];
  aString2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['string'];
  doubleOrNull2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['double'];
}

/*member: dictionary3:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
dynamic dictionary3 = {
  'string': "aString",
  'int': 42,
  'double': 21.5,
  'list': []
};
/*member: keyD3:Value([exact=JSString], value: "double")*/
dynamic keyD3 = 'double';

/*member: keyI3:Value([exact=JSString], value: "int")*/
dynamic keyI3 = 'int';

/*member: keyN3:Value([exact=JSString], value: "notFoundInMap")*/
dynamic keyN3 = 'notFoundInMap';

/*member: knownDouble3:[exact=JSDouble]*/
dynamic knownDouble3 = 42.2;

/*member: intOrNull3:[null|exact=JSUInt31]*/
dynamic intOrNull3 = dictionary3
    /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
    [keyI3];

/*member: justNull3:[null]*/
dynamic justNull3 = dictionary3
    /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
    [keyN3];

/*member: test3:[null]*/
test3() {
  knownDouble3 = dictionary3
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSDouble], [exact=JSExtendableArray], [exact=JSString], [exact=JSUInt31]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      [keyD3];
  // ignore: unused_local_variable
  var x = [intOrNull3, justNull3];
}

class A4 {
/*member: A4.:[exact=A4]*/
  A4();
/*member: A4.foo4:[exact=JSUInt31]*/
  foo4(
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSString], [exact=JSUInt31]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ value) {
    return value /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSString], [exact=JSUInt31]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ [
        'anInt'];
  }
}

class B4 {
/*member: B4.:[exact=B4]*/
  B4();

/*member: B4.foo4:[exact=JSUInt31]*/
  foo4(
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union(null, [exact=JSString], [exact=JSUInt31]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ value) {
    return 0;
  }
}

/*member: test4:[null]*/
test4() {
  var dictionary = {'anInt': 42, 'aString': "theString"};
  var it;
  if ([true, false]
      /*Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/
      [0]) {
    it = new A4();
  } else {
    it = new B4();
  }
  print(it. /*invoke: Union([exact=A4], [exact=B4])*/ foo4(
          dictionary) /*invoke: [exact=JSUInt31]*/ +
      2);
}

/*member: dict5:Map([null|subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
dynamic dict5 = makeMap5([1, 2]);

/*member: notInt5:[null|subclass=Object]*/
dynamic notInt5 = 0;

/*member: alsoNotInt5:[null|subclass=Object]*/
dynamic alsoNotInt5 = 0;

/*member: makeMap5:Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
makeMap5(
    /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/ values) {
  return {
    'moo': values
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
        [0],
    'boo': values
        /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
        [1]
  };
}

/*member: test5:[null]*/
test5() {
  dict5
      /*update: Map([null|subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
      ['goo'] = 42;
  var closure =
      /*Map([null|subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
      () => dict5;
  notInt5 = closure()['boo'];
  alsoNotInt5 = dict5
      /*Map([null|subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
      ['goo'];
  print("$notInt5 and $alsoNotInt5.");
}
