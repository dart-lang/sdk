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
}

/*element: dictionaryA1:Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
var dictionaryA1 = {'string': "aString", 'int': 42, 'double': 21.5, 'list': []};

/*element: dictionaryB1:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
var dictionaryB1 = {'string': "aString", 'int': 42, 'double': 21.5, 'list': []};

/*element: otherDict1:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSString]), map: {stringTwo: Value([exact=JSString], value: "anotherString"), intTwo: [exact=JSUInt31]})*/
var otherDict1 = {'stringTwo': "anotherString", 'intTwo': 84};

/*element: int1:[exact=JSUInt31]*/
var int1 = 0;

/*element: anotherInt1:[exact=JSUInt31]*/
var anotherInt1 = 0;

/*element: nullOrInt1:[null|exact=JSUInt31]*/
var nullOrInt1 = 0;

/*element: dynamic1:[null|subclass=Object]*/
var dynamic1 = 0;

/*element: test1:[null]*/
test1() {
  dictionaryA1
      . /*invoke: Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
      addAll(otherDict1);
  dictionaryB1
      . /*invoke: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      addAll({'stringTwo': "anotherString", 'intTwo': 84});
  int1 = dictionaryB1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      ['int'];
  anotherInt1 = otherDict1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSString]), map: {stringTwo: Value([exact=JSString], value: "anotherString"), intTwo: [exact=JSUInt31]})*/
      ['intTwo'];
  dynamic1 = dictionaryA1
      /*Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/ [
      'int'];
  nullOrInt1 = dictionaryB1
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [null|subclass=Object], length: null), stringTwo: Value([null|exact=JSString], value: "anotherString"), intTwo: [null|exact=JSUInt31]})*/
      ['intTwo'];
}

/*element: dictionaryA2:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
var dictionaryA2 = {'string': "aString", 'int': 42, 'double': 21.5, 'list': []};

/*element: dictionaryB2:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), intTwo: [exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
var dictionaryB2 = {'string': "aString", 'intTwo': 42, 'list': []};

/*element: nullOrInt2:[null|exact=JSUInt31]*/
var nullOrInt2 = 0;

/*element: aString2:[exact=JSString]*/
var aString2 = "";

/*element: doubleOrNull2:[null|exact=JSDouble]*/
var doubleOrNull2 = 22.2;

/*element: test2:[null]*/
test2() {
  var union = dictionaryA2
          /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
          ['foo']
      ? dictionaryA2
      : dictionaryB2;
  nullOrInt2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['intTwo'];
  aString2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['string'];
  doubleOrNull2 = union
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {int: [null|exact=JSUInt31], double: [null|exact=JSDouble], string: Value([exact=JSString], value: "aString"), intTwo: [null|exact=JSUInt31], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      ['double'];
}

/*element: dictionary3:Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
var dictionary3 = {'string': "aString", 'int': 42, 'double': 21.5, 'list': []};
/*element: keyD3:Value([exact=JSString], value: "double")*/
var keyD3 = 'double';

/*element: keyI3:Value([exact=JSString], value: "int")*/
var keyI3 = 'int';

/*element: keyN3:Value([exact=JSString], value: "notFoundInMap")*/
var keyN3 = 'notFoundInMap';

/*element: knownDouble3:[exact=JSDouble]*/
var knownDouble3 = 42.2;

/*element: intOrNull3:[null|exact=JSUInt31]*/
var intOrNull3 = dictionary3
    /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
    [keyI3];

/*element: justNull3:[null]*/
var justNull3 = dictionary3
    /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
    [keyN3];

/*element: test3:[null]*/
test3() {
  knownDouble3 = dictionary3
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSDouble], [exact=JSExtendableArray], [exact=JSUInt31], [null|exact=JSString]), map: {string: Value([exact=JSString], value: "aString"), int: [exact=JSUInt31], double: [exact=JSDouble], list: Container([exact=JSExtendableArray], element: [empty], length: 0)})*/
      [keyD3];
  // ignore: unused_local_variable
  var x = [intOrNull3, justNull3];
}

class A4 {
/*element: A4.:[exact=A4]*/
  A4();
/*element: A4.foo4:[exact=JSUInt31]*/
  foo4(
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSString]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ value) {
    return value /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSString]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ [
        'anInt'];
  }
}

class B4 {
/*element: B4.:[exact=B4]*/
  B4();

/*element: B4.foo4:[exact=JSUInt31]*/
  foo4(
      /*Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: Union([exact=JSUInt31], [null|exact=JSString]), map: {anInt: [exact=JSUInt31], aString: Value([exact=JSString], value: "theString")})*/ value) {
    return 0;
  }
}

/*element: test4:[null]*/
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

/*element: dict5:Map([null|subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
var dict5 = makeMap5([1, 2]);

/*element: notInt5:[null|subclass=Object]*/
var notInt5 = 0;

/*element: alsoNotInt5:[null|subclass=Object]*/
var alsoNotInt5 = 0;

/*element: makeMap5:Map([subclass=JsLinkedHashMap], key: [null|subclass=Object], value: [null|subclass=Object])*/
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

/*element: test5:[null]*/
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
