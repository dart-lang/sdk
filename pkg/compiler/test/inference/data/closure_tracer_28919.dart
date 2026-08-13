// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 28919.

/*member: foo1:[null|powerset={null}]*/
foo1() {
  final methods = [];
  var res, sum;
  for (
    int i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ != 3;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++
  ) {
    methods
        . /*invoke: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: null, powerset: {I}{G}{M})*/ add(
          /*[null|powerset={null}]*/ (
            int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ x,
          ) {
            res = x;
            sum = x /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ + i;
          },
        );
  }
  methods /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: null, powerset: {I}{G}{M})*/ [0](
    499,
  );
  probe1res(res);
  probe1sum(sum);
  probe1methods(methods);
}

/*member: probe1res:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
probe1res(/*[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ x) => x;

/*member: probe1sum:[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/
probe1sum(/*[null|subclass=JSPositiveInt|powerset={null}{I}{O}{N}]*/ x) => x;

/*member: probe1methods:Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: null, powerset: {I}{G}{M})*/
probe1methods(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: null, powerset: {I}{G}{M})*/ x,
) => x;

/*member: nonContainer:[exact=JSExtendableArray|powerset={I}{G}{M}]*/
nonContainer(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ choice) {
  var m = choice /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ == 0
      ? []
      : "<String>";
  if (m is! List) throw 123;
  // The union then filter leaves us with a non-container type.
  return m;
}

/*member: foo2:[null|powerset={null}]*/
foo2(int /*[exact=JSUInt31|powerset={I}{O}{N}]*/ choice) {
  final methods = nonContainer(choice);

  /// ignore: unused_local_variable
  var res, sum;
  for (
    int i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ != 3;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++
  ) {
    methods. /*invoke: [exact=JSExtendableArray|powerset={I}{G}{M}]*/ add(
      /*[null|powerset={null}]*/ (
        int
        /*spec.[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
        /*prod.[subclass=JSInt|powerset={I}{O}{N}]*/
        x,
      ) {
        res = x;
        sum = x /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ + i;
      },
    );
  }
  methods /*[exact=JSExtendableArray|powerset={I}{G}{M}]*/ [0](499);
  probe2res(res);
  probe2methods(methods);
}

/*member: probe2res:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
probe2res(
  /*[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
  x,
) => x;

/*member: probe2methods:[exact=JSExtendableArray|powerset={I}{G}{M}]*/
probe2methods(/*[exact=JSExtendableArray|powerset={I}{G}{M}]*/ x) => x;

/*member: main:[null|powerset={null}]*/
main() {
  foo1();
  foo2(0);
  foo2(1);
}
