// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A1.:[empty|powerset=empty]*/
class A1 {
  /*member: A1.foo:[null|powerset={null}]*/
  void foo(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ x) => print(x);
}

/*member: B1.:[exact=B1|powerset={N}{O}{N}]*/
class B1 extends A1 with M1 {}

/*member: C1.:[exact=C1|powerset={N}{O}{N}]*/
class C1 with M1 {
  /*member: C1.foo:[null|powerset={null}]*/
  void foo(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ x) => print(x);
}

mixin M1 {
  void foo(x);
  /*member: M1.bar:[null|powerset={null}]*/
  void bar(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ y) {
    /*invoke: [subtype=M1|powerset={N}{O}{N}]*/
    foo(y);
  }
}

/*member: A2.:[empty|powerset=empty]*/
class A2 {
  /*member: A2.foo:[null|powerset={null}]*/
  void foo(/*[empty|powerset=empty]*/ x) => print(x);
}

/*member: B2.:[exact=B2|powerset={N}{O}{N}]*/
class B2 extends A2 with M2 {}

/*member: C2.:[exact=C2|powerset={N}{O}{N}]*/
class C2 with M2 {
  /*member: C2.foo:[null|powerset={null}]*/
  void foo(
    /*Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/ x,
  ) => print(x);
}

mixin M2 {
  /*member: M2.foo:[exact=JSUInt31|powerset={I}{O}{N}]*/
  void foo(
    /*Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/ x,
  ) => 5;
  /*member: M2.bar:[null|powerset={null}]*/
  void bar(
    /*Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/ y,
  ) {
    /*invoke: [subtype=M2|powerset={N}{O}{N}]*/
    foo(y);
  }
}

/*member: getB1:Union([exact=B1|powerset={N}{O}{N}], [exact=C1|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
getB1(
  bool /*Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
  x,
) => x ? B1() : C1();
/*member: getB2:Union([exact=B2|powerset={N}{O}{N}], [exact=C2|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
getB2(
  bool /*Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
  x,
) => x ? B2() : C2();

/*member: main:[null|powerset={null}]*/
main() {
  getB1(
    false,
  ). /*invoke: Union([exact=B1|powerset={N}{O}{N}], [exact=C1|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ bar(
    3,
  );
  getB2(
    false,
  ). /*invoke: Union([exact=B2|powerset={N}{O}{N}], [exact=C2|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ bar(
    "",
  );
}
