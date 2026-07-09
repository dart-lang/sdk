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

/*member: returnInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
returnInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ () {
    return lines;
  });
  return lines;
}

/*member: accessInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
accessInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool|powerset={I}{O}{N}]*/ () {
    return lines. /*[exact=JSUInt31|powerset={I}{O}{N}]*/ isEven;
  });
  return lines;
}

/*member: invokeInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
invokeInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber|powerset={I}{O}{N}]*/ () {
    return lines
        . /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ ceilToDouble();
  });
  return lines;
}

/*member: operatorInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
operatorInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}{O}{N}]*/ () {
    return lines /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ - 42;
  });
  return lines;
}

/*member: assignInClosure:[subclass=JSInt|powerset={I}{O}{N}]*/
assignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  return lines;
}

/*member: assignInTwoClosures:[subclass=JSInt|powerset={I}{O}{N}]*/
assignInTwoClosures() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  local(/*[null|powerset={null}]*/ () {
    lines = -87;
  });
  return lines;
}

/*member: accessAssignInClosure:[subclass=JSInt|powerset={I}{O}{N}]*/
accessAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = lines /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ - 42;
  });
  return lines;
}

/*member: accessBeforeAssignInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*member: accessAfterAssignInClosure:[exact=JSUInt31|powerset={I}{O}{N}]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}{O}{N}]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ - 42;
  });
  return lines;
}

/*member: compoundInClosure:[subclass=JSInt|powerset={I}{O}{N}]*/
compoundInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSInt|powerset={I}{O}{N}]*/ -= 42;
  });
  return lines;
}

/*member: postfixInClosure:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
postfixInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  local(/*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSPositiveInt|powerset={I}{O}{N}]*/ ++;
  });
  return lines;
}
