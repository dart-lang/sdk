// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: returnInClosure:[exact=JSUInt31|powerset={I}]*/
returnInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31|powerset={I}]*/ () {
    return lines;
  });
  return lines;
}

/*member: accessInClosure:[exact=JSUInt31|powerset={I}]*/
accessInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool|powerset={I}]*/ () {
    return lines. /*[exact=JSUInt31|powerset={I}]*/ isEven;
  });
  return lines;
}

/*member: invokeInClosure:[exact=JSUInt31|powerset={I}]*/
invokeInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber|powerset={I}]*/ () {
    return lines. /*invoke: [exact=JSUInt31|powerset={I}]*/ ceilToDouble();
  });
  return lines;
}

/*member: operatorInClosure:[exact=JSUInt31|powerset={I}]*/
operatorInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}]*/ () {
    return lines /*invoke: [exact=JSUInt31|powerset={I}]*/ - 42;
  });
  return lines;
}

/*member: assignInClosure:[subclass=JSInt|powerset={I}]*/
assignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  return lines;
}

/*member: assignInTwoClosures:[subclass=JSInt|powerset={I}]*/
assignInTwoClosures() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  local(/*[null|powerset={null}]*/ () {
    lines = -87;
  });
  return lines;
}

/*member: accessAssignInClosure:[subclass=JSInt|powerset={I}]*/
accessAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = lines /*invoke: [subclass=JSInt|powerset={I}]*/ - 42;
  });
  return lines;
}

/*member: accessBeforeAssignInClosure:[exact=JSUInt31|powerset={I}]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [exact=JSUInt31|powerset={I}]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*member: accessAfterAssignInClosure:[exact=JSUInt31|powerset={I}]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31|powerset={I}]*/ - 42;
  });
  return lines;
}

/*member: compoundInClosure:[subclass=JSInt|powerset={I}]*/
compoundInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSInt|powerset={I}]*/ -= 42;
  });
  return lines;
}

/*member: postfixInClosure:[subclass=JSPositiveInt|powerset={I}]*/
postfixInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  local(/*[subclass=Closure|powerset={N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ ++;
  });
  return lines;
}
