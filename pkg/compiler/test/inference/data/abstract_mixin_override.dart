// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A1.:[exact=A1|powerset={N}]*/
class A1 {
  /*member: A1.foo:[null|powerset={null}]*/
  void foo(/*[exact=JSUInt31|powerset={I}]*/ x) => print(x);
}

/*member: B1.:[exact=B1|powerset={N}]*/
class B1 extends A1 with M1 {}

/*member: C1.:[exact=C1|powerset={N}]*/
class C1 with M1 {
  /*member: C1.foo:[null|powerset={null}]*/
  void foo(/*[exact=JSUInt31|powerset={I}]*/ x) => print(x);
}

mixin M1 {
  void foo(x);
  /*member: M1.bar:[null|powerset={null}]*/
  void bar(/*[exact=JSUInt31|powerset={I}]*/ y) {
    /*invoke: [subtype=M1|powerset={N}]*/
    foo(y);
  }
}

/*member: A2.:[exact=A2|powerset={N}]*/
class A2 {
  /*member: A2.foo:[null|powerset={null}]*/
  void foo(/*[empty|powerset=empty]*/ x) => print(x);
}

/*member: B2.:[exact=B2|powerset={N}]*/
class B2 extends A2 with M2 {}

/*member: C2.:[exact=C2|powerset={N}]*/
class C2 with M2 {
  /*member: C2.foo:[null|powerset={null}]*/
  void foo(
    /*Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/ x,
  ) => print(x);
}

mixin M2 {
  /*member: M2.foo:[exact=JSUInt31|powerset={I}]*/
  void foo(
    /*Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/ x,
  ) => 5;
  /*member: M2.bar:[null|powerset={null}]*/
  void bar(
    /*Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/ y,
  ) {
    /*invoke: [subtype=M2|powerset={N}]*/
    foo(y);
  }
}

/*member: getB1:Union([exact=B1|powerset={N}], [exact=C1|powerset={N}], powerset: {N})*/
getB1(
  bool /*Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/ x,
) => x ? B1() : C1();
/*member: getB2:Union([exact=B2|powerset={N}], [exact=C2|powerset={N}], powerset: {N})*/
getB2(
  bool /*Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/ x,
) => x ? B2() : C2();

/*member: main:[null|powerset={null}]*/
main() {
  getB1(
    false,
  ). /*invoke: Union([exact=B1|powerset={N}], [exact=C1|powerset={N}], powerset: {N})*/ bar(
    3,
  );
  getB2(
    false,
  ). /*invoke: Union([exact=B2|powerset={N}], [exact=C2|powerset={N}], powerset: {N})*/ bar(
    "",
  );
}
