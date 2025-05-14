// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 28919.

/*member: foo1:[null|powerset=1]*/
foo1() {
  final methods = [];
  var res, sum;
  for (
    int i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ != 3;
    i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++
  ) {
    methods
        . /*invoke: Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: null, powerset: 0)*/ add(
          /*[null|powerset=1]*/ (int /*[exact=JSUInt31|powerset=0]*/ x) {
            res = x;
            sum = x /*invoke: [exact=JSUInt31|powerset=0]*/ + i;
          },
        );
  }
  methods /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: null, powerset: 0)*/ [0](
    499,
  );
  probe1res(res);
  probe1sum(sum);
  probe1methods(methods);
}

/*member: probe1res:[null|exact=JSUInt31|powerset=1]*/
probe1res(/*[null|exact=JSUInt31|powerset=1]*/ x) => x;

/*member: probe1sum:[null|subclass=JSPositiveInt|powerset=1]*/
probe1sum(/*[null|subclass=JSPositiveInt|powerset=1]*/ x) => x;

/*member: probe1methods:Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: null, powerset: 0)*/
probe1methods(
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: null, powerset: 0)*/ x,
) => x;

/*member: nonContainer:[exact=JSExtendableArray|powerset=0]*/
nonContainer(/*[exact=JSUInt31|powerset=0]*/ choice) {
  var m = choice /*invoke: [exact=JSUInt31|powerset=0]*/ == 0 ? [] : "<String>";
  if (m is! List) throw 123;
  // The union then filter leaves us with a non-container type.
  return m;
}

/*member: foo2:[null|powerset=1]*/
foo2(int /*[exact=JSUInt31|powerset=0]*/ choice) {
  final methods = nonContainer(choice);

  /// ignore: unused_local_variable
  var res, sum;
  for (
    int i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ != 3;
    i /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++
  ) {
    methods. /*invoke: [exact=JSExtendableArray|powerset=0]*/ add(
      /*[null|powerset=1]*/ (
        int
        /*spec.[null|subclass=Object|powerset=1]*/
        /*prod.[subclass=JSInt|powerset=0]*/
        x,
      ) {
        res = x;
        sum = x /*invoke: [subclass=JSInt|powerset=0]*/ + i;
      },
    );
  }
  methods /*[exact=JSExtendableArray|powerset=0]*/ [0](499);
  probe2res(res);
  probe2methods(methods);
}

/*member: probe2res:[null|subclass=JSInt|powerset=1]*/
probe2res(
  /*[null|subclass=JSInt|powerset=1]*/
  x,
) => x;

/*member: probe2methods:[exact=JSExtendableArray|powerset=0]*/
probe2methods(/*[exact=JSExtendableArray|powerset=0]*/ x) => x;

/*member: main:[null|powerset=1]*/
main() {
  foo1();
  foo2(0);
  foo2(1);
}
