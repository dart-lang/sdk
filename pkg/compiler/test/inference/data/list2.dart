// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  boolFlag = !boolFlag;
  data. /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: null, powerset: {I}{G})*/ add(
    100,
  );

  var lists = [
    listEmptyDefault,
    listEmptyGrowable,
    listEmptyFixed,
    listEmptyEither,
    listFilledDefault,
    listFilledGrowable,
    listFilledFixed,
    listFilledEither,
    listGenerateDefault,
    listGenerateGrowable,
    listGenerateFixed,
    listGenerateEither,
    listGenerateBigClosure,
    listOfDefault,
    listOfGrowable,
    listOfFixed,
    listOfEither,
    listFromDefault,
    listFromGrowable,
    listFromFixed,
    listFromEither,
    listUnmodifiable,
  ];
}

/*member: boolFlag:[exact=JSBool|powerset={I}{O}]*/
bool boolFlag = true;

/*member: data:Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=JSInt|powerset={I}{O}], length: null, powerset: {I}{G})*/
List<int> data = [-1, 1];

// -------- List.empty --------

/*member: listEmptyDefault:Container([exact=JSFixedArray|powerset={I}{F}], element: [empty|powerset=empty], length: 0, powerset: {I}{F})*/
get listEmptyDefault => List<int>.empty();

/*member: listEmptyGrowable:Container([exact=JSExtendableArray|powerset={I}{G}], element: [empty|powerset=empty], length: 0, powerset: {I}{G})*/
get listEmptyGrowable => List<int>.empty(growable: true);

/*member: listEmptyFixed:Container([exact=JSFixedArray|powerset={I}{F}], element: [empty|powerset=empty], length: 0, powerset: {I}{F})*/
get listEmptyFixed => List<int>.empty(growable: false);

/*member: listEmptyEither:Container([subclass=JSMutableArray|powerset={I}{GF}], element: [empty|powerset=empty], length: 0, powerset: {I}{GF})*/
get listEmptyEither => List<int>.empty(growable: boolFlag);

// -------- List.filled --------

/*member: listFilledDefault:Container([exact=JSFixedArray|powerset={I}{F}], element: Value([exact=JSString|powerset={I}{O}], value: "x", powerset: {I}{O}), length: 5, powerset: {I}{F})*/
get listFilledDefault => List.filled(5, 'x');

/*member: listFilledGrowable:Container([exact=JSExtendableArray|powerset={I}{G}], element: Value([exact=JSString|powerset={I}{O}], value: "g", powerset: {I}{O}), length: 5, powerset: {I}{G})*/
get listFilledGrowable => List.filled(5, 'g', growable: true);

/*member: listFilledFixed:Container([exact=JSFixedArray|powerset={I}{F}], element: Value([exact=JSString|powerset={I}{O}], value: "f", powerset: {I}{O}), length: 5, powerset: {I}{F})*/
get listFilledFixed => List.filled(5, 'f', growable: false);

/*member: listFilledEither:Container([subclass=JSMutableArray|powerset={I}{GF}], element: Value([exact=JSString|powerset={I}{O}], value: "e", powerset: {I}{O}), length: 5, powerset: {I}{GF})*/
get listFilledEither => List.filled(5, 'e', growable: boolFlag);

// -------- List.generate --------

/*member: listGenerateDefault:Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{G})*/
get listGenerateDefault =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{G})*/ generate(
      8,
      (i) => 'x$i',
    );

/*member: listGenerateGrowable:Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{G})*/
get listGenerateGrowable =>
    List. /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{G})*/ generate(
      8,
      (i) => 'g$i',
      growable: true,
    );

/*member: listGenerateFixed:Container([exact=JSFixedArray|powerset={I}{F}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{F})*/
get listGenerateFixed =>
    List. /*update: Container([exact=JSFixedArray|powerset={I}{F}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{F})*/ generate(
      8,
      (i) => 'f$i',
      growable: false,
    );

/*member: listGenerateEither:Container([subclass=JSMutableArray|powerset={I}{GF}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{GF})*/
get listGenerateEither => List.generate(
  8,
  /*[exact=JSString|powerset={I}{O}]*/ (
    /*[subclass=JSPositiveInt|powerset={I}{O}]*/ i,
  ) => 'e$i',
  growable: boolFlag,
);

/*member: listGenerateBigClosure:Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSString|powerset={I}{O}], length: 8, powerset: {I}{G})*/
get listGenerateBigClosure =>
    List.generate(8, /*[exact=JSString|powerset={I}{O}]*/ (
      /*[subclass=JSPositiveInt|powerset={I}{O}]*/ i,
    ) {
      if (i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ == 1)
        return 'one';
      if (i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ == 2)
        return 'two';
      return '$i';
    });

// -------- List.of --------

/*member: listOfDefault:Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G})*/
get listOfDefault => List.of(data);

/*member: listOfGrowable:Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G})*/
get listOfGrowable => List.of(data, growable: true);

/*member: listOfFixed:Container([exact=JSFixedArray|powerset={I}{F}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{F})*/
get listOfFixed => List.of(data, growable: false);

/*member: listOfEither:Container([subclass=JSMutableArray|powerset={I}{GF}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{GF})*/
get listOfEither => List.of(data, growable: boolFlag);

// -------- List.from --------

/*member: listFromDefault:Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G})*/
get listFromDefault => List.from(data);

/*member: listFromGrowable:Container([exact=JSExtendableArray|powerset={I}{G}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{G})*/
get listFromGrowable => List.from(data, growable: true);

/*member: listFromFixed:Container([exact=JSFixedArray|powerset={I}{F}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{F})*/
get listFromFixed => List.from(data, growable: false);

/*member: listFromEither:Container([subclass=JSMutableArray|powerset={I}{GF}], element: [null|subclass=Object|powerset={null}{IN}{GFUO}], length: null, powerset: {I}{GF})*/
get listFromEither => List.from(data, growable: boolFlag);

// -------- List.unmodifiable --------

/*member: listUnmodifiable:[exact=JSUnmodifiableArray|powerset={I}{U}]*/
get listUnmodifiable => List.unmodifiable(data);
