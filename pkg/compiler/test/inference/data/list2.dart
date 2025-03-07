// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  boolFlag = !boolFlag;
  data. /*invoke: Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: null, powerset: 0)*/ add(
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

/*member: boolFlag:[exact=JSBool|powerset=0]*/
bool boolFlag = true;

/*member: data:Container([exact=JSExtendableArray|powerset=0], element: [subclass=JSInt|powerset=0], length: null, powerset: 0)*/
List<int> data = [-1, 1];

// -------- List.empty --------

/*member: listEmptyDefault:Container([exact=JSFixedArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
get listEmptyDefault => List<int>.empty();

/*member: listEmptyGrowable:Container([exact=JSExtendableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
get listEmptyGrowable => List<int>.empty(growable: true);

/*member: listEmptyFixed:Container([exact=JSFixedArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
get listEmptyFixed => List<int>.empty(growable: false);

/*member: listEmptyEither:Container([subclass=JSMutableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)*/
get listEmptyEither => List<int>.empty(growable: boolFlag);

// -------- List.filled --------

/*member: listFilledDefault:Container([exact=JSFixedArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "x", powerset: 0), length: 5, powerset: 0)*/
get listFilledDefault => List.filled(5, 'x');

/*member: listFilledGrowable:Container([exact=JSExtendableArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "g", powerset: 0), length: 5, powerset: 0)*/
get listFilledGrowable => List.filled(5, 'g', growable: true);

/*member: listFilledFixed:Container([exact=JSFixedArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "f", powerset: 0), length: 5, powerset: 0)*/
get listFilledFixed => List.filled(5, 'f', growable: false);

/*member: listFilledEither:Container([subclass=JSMutableArray|powerset=0], element: Value([exact=JSString|powerset=0], value: "e", powerset: 0), length: 5, powerset: 0)*/
get listFilledEither => List.filled(5, 'e', growable: boolFlag);

// -------- List.generate --------

/*member: listGenerateDefault:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/
get listGenerateDefault =>
    List. /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/ generate(
      8,
      (i) => 'x$i',
    );

/*member: listGenerateGrowable:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/
get listGenerateGrowable =>
    List. /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/ generate(
      8,
      (i) => 'g$i',
      growable: true,
    );

/*member: listGenerateFixed:Container([exact=JSFixedArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/
get listGenerateFixed =>
    List. /*update: Container([exact=JSFixedArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/ generate(
      8,
      (i) => 'f$i',
      growable: false,
    );

/*member: listGenerateEither:Container([subclass=JSMutableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/
get listGenerateEither => List.generate(
  8,
  /*[exact=JSString|powerset=0]*/ (/*[subclass=JSPositiveInt|powerset=0]*/ i) =>
      'e$i',
  growable: boolFlag,
);

/*member: listGenerateBigClosure:Container([exact=JSExtendableArray|powerset=0], element: [exact=JSString|powerset=0], length: 8, powerset: 0)*/
get listGenerateBigClosure => List.generate(8, /*[exact=JSString|powerset=0]*/ (
  /*[subclass=JSPositiveInt|powerset=0]*/ i,
) {
  if (i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ == 1) return 'one';
  if (i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ == 2) return 'two';
  return '$i';
});

// -------- List.of --------

/*member: listOfDefault:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listOfDefault => List.of(data);

/*member: listOfGrowable:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listOfGrowable => List.of(data, growable: true);

/*member: listOfFixed:Container([exact=JSFixedArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listOfFixed => List.of(data, growable: false);

/*member: listOfEither:Container([subclass=JSMutableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listOfEither => List.of(data, growable: boolFlag);

// -------- List.from --------

/*member: listFromDefault:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listFromDefault => List.from(data);

/*member: listFromGrowable:Container([exact=JSExtendableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listFromGrowable => List.from(data, growable: true);

/*member: listFromFixed:Container([exact=JSFixedArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listFromFixed => List.from(data, growable: false);

/*member: listFromEither:Container([subclass=JSMutableArray|powerset=0], element: [null|subclass=Object|powerset=1], length: null, powerset: 0)*/
get listFromEither => List.from(data, growable: boolFlag);

// -------- List.unmodifiable --------

/*member: listUnmodifiable:[exact=JSUnmodifiableArray|powerset=0]*/
get listUnmodifiable => List.unmodifiable(data);
