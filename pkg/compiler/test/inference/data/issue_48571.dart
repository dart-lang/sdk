// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: Base.:[subclass=Base|powerset=0]*/
abstract class Base {}

/*member: Child1.:[exact=Child1|powerset=0]*/
class Child1 extends Base {}

/*member: Child2.:[exact=Child2|powerset=0]*/
class Child2 extends Base {}

/*member: trivial:Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/
bool trivial(/*[exact=JSBool|powerset=0]*/ x) => true;

/*member: either:Union([exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 0)*/
Base either =
    DateTime.now()
                . /*[exact=DateTime|powerset=0]*/ millisecondsSinceEpoch /*invoke: [subclass=JSInt|powerset=0]*/ >
            0
        ? Child2()
        : Child1();

/*member: test1:Union(null, [exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 1)*/
test1() {
  Base child = either;
  if (trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test2:Union(null, [exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 1)*/
test2() {
  Base child = either;
  if (child is Child1 || trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test3:[null|exact=Child2|powerset=1]*/
test3() {
  Base child = either;
  if (trivial(child is Child1 && true) && child is Child2) return child;
  return null;
}

/*member: test4:[null|exact=Child2|powerset=1]*/
test4() {
  Base child = either;
  if (child is Child2 && trivial(child is Child1 && true)) return child;
  return null;
}

/*member: test5:Union(null, [exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 1)*/
test5() {
  Base child = either;
  if ((child is Child1 && true) /*invoke: [exact=JSBool|powerset=0]*/ == false)
    return child;
  return null;
}

/*member: test6:Union(null, [exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 1)*/
test6() {
  Base child = either;
  if (trivial(child is Child1 ? false : true)) return child;
  return null;
}

/*member: test7:Union(null, [exact=Child1|powerset=0], [exact=Child2|powerset=0], powerset: 1)*/
test7() {
  Base child = either;
  if (trivial(trivial(child is Child1 && true))) return child;
  return null;
}

/*member: main:[null|powerset=1]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
}
