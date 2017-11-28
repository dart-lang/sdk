// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
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

/*element: returnInClosure:[exact=JSUInt31]*/
returnInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31]*/ () {
    return lines;
  });
  return lines;
}

/*element: accessInClosure:[exact=JSUInt31]*/
accessInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool]*/ () {
    return lines. /*[exact=JSUInt31]*/ isEven;
  });
  return lines;
}

/*element: invokeInClosure:[exact=JSUInt31]*/
invokeInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber]*/ () {
    return lines. /*invoke: [exact=JSUInt31]*/ ceilToDouble();
  });
  return lines;
}

/*element: operatorInClosure:[exact=JSUInt31]*/
operatorInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt]*/ () {
    return lines /*invoke: [exact=JSUInt31]*/ - 42;
  });
  return lines;
}

/*element: assignInClosure:[subclass=JSInt]*/
assignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = /*invoke: [exact=JSUInt31]*/ -42;
  });
  return lines;
}

/*element: assignInTwoClosures:[subclass=JSInt]*/
assignInTwoClosures() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = /*invoke: [exact=JSUInt31]*/ -42;
  });
  local(/*[null]*/ () {
    lines = /*invoke: [exact=JSUInt31]*/ -87;
  });
  return lines;
}

/*element: accessAssignInClosure:[subclass=JSInt]*/
accessAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines = lines /*invoke: [subclass=JSInt]*/ - 42;
  });
  return lines;
}

/*element: accessBeforeAssignInClosure:[exact=JSUInt31]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [exact=JSUInt31]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*element: accessAfterAssignInClosure:[exact=JSUInt31]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31]*/ - 42;
  });
  return lines;
}

/*element: compoundInClosure:[subclass=JSInt]*/
compoundInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [subclass=JSInt]*/ -= 42;
  });
  return lines;
}

/*element: postfixInClosure:[subclass=JSPositiveInt]*/
postfixInClosure() {
  /*[null|subclass=Object]*/ local(/*[subclass=Closure]*/ f) => f();

  int lines = 0;
  local(/*[null]*/ () {
    lines /*invoke: [subclass=JSPositiveInt]*/ ++;
  });
  return lines;
}
