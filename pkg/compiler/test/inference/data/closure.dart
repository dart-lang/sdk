// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  returnInClosure();
  accessInClosure();
  invokeInClosure();
  operatorInClosure();
  assignInClosure();
  assignInTwoClosures();
  accessAssignInClosure();
  accessBeforeAssignInClosure();
  accessAfterAssignInClosure();
  compoundInClosure();
  postfixInClosure();
}

/*member: returnInClosure:[exact=JSUInt31|powerset=0]*/
returnInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31|powerset=0]*/ () {
    return lines;
  });
  return lines;
}

/*member: accessInClosure:[exact=JSUInt31|powerset=0]*/
accessInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool|powerset=0]*/ () {
    return lines. /*[exact=JSUInt31|powerset=0]*/ isEven;
  });
  return lines;
}

/*member: invokeInClosure:[exact=JSUInt31|powerset=0]*/
invokeInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber|powerset=0]*/ () {
    return lines. /*invoke: [exact=JSUInt31|powerset=0]*/ ceilToDouble();
  });
  return lines;
}

/*member: operatorInClosure:[exact=JSUInt31|powerset=0]*/
operatorInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset=0]*/ () {
    return lines /*invoke: [exact=JSUInt31|powerset=0]*/ - 42;
  });
  return lines;
}

/*member: assignInClosure:[subclass=JSInt|powerset=0]*/
assignInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines = -42;
  });
  return lines;
}

/*member: assignInTwoClosures:[subclass=JSInt|powerset=0]*/
assignInTwoClosures() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines = -42;
  });
  local(/*[null|powerset=1]*/ () {
    lines = -87;
  });
  return lines;
}

/*member: accessAssignInClosure:[subclass=JSInt|powerset=0]*/
accessAssignInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines = lines /*invoke: [subclass=JSInt|powerset=0]*/ - 42;
  });
  return lines;
}

/*member: accessBeforeAssignInClosure:[exact=JSUInt31|powerset=0]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines /*invoke: [exact=JSUInt31|powerset=0]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*member: accessAfterAssignInClosure:[exact=JSUInt31|powerset=0]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset=0]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31|powerset=0]*/ - 42;
  });
  return lines;
}

/*member: compoundInClosure:[subclass=JSInt|powerset=0]*/
compoundInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines /*invoke: [subclass=JSInt|powerset=0]*/ -= 42;
  });
  return lines;
}

/*member: postfixInClosure:[subclass=JSPositiveInt|powerset=0]*/
postfixInClosure() {
  /*[null|subclass=Object|powerset=1]*/
  local(/*[subclass=Closure|powerset=0]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset=1]*/ () {
    lines /*invoke: [subclass=JSPositiveInt|powerset=0]*/ ++;
  });
  return lines;
}
