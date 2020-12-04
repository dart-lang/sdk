// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: returnInClosure:[exact=JSUInt31]*/
returnInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31]*/ () {
    return lines;
  });
  return lines;
}

/*member: accessInClosure:[exact=JSUInt31]*/
accessInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool]*/ () {
    return lines. /*[exact=JSUInt31]*/ isEven;
  });
  return lines;
}

/*member: invokeInClosure:[exact=JSUInt31]*/
invokeInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber]*/ () {
    return lines. /*invoke: [exact=JSUInt31]*/ ceilToDouble();
  });
  return lines;
}

/*member: operatorInClosure:[exact=JSUInt31]*/
operatorInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt]*/ () {
    return lines /*invoke: [exact=JSUInt31]*/ - 42;
  });
  return lines;
}

/*member: assignInClosure:[subclass=JSInt]*/
assignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = -42;
  });
  return lines;
}

/*member: assignInTwoClosures:[subclass=JSInt]*/
assignInTwoClosures() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = -42;
  });
  local(/*[null]*/ () {
    lines = -87;
  });
  return lines;
}

/*member: accessAssignInClosure:[subclass=JSInt]*/
accessAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = lines /*invoke: [subclass=JSInt]*/ - 42;
  });
  return lines;
}

/*member: accessBeforeAssignInClosure:[exact=JSUInt31]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [exact=JSUInt31]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*member: accessAfterAssignInClosure:[exact=JSUInt31]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31]*/ - 42;
  });
  return lines;
}

/*member: compoundInClosure:[subclass=JSInt]*/
compoundInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [subclass=JSInt]*/ -= 42;
  });
  return lines;
}

/*member: postfixInClosure:[subclass=JSPositiveInt]*/
postfixInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [subclass=JSPositiveInt]*/ ++;
  });
  return lines;
}
