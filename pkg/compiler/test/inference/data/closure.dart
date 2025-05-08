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

/*member: returnInClosure:[exact=JSUInt31|powerset={I}{O}]*/
returnInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSUInt31|powerset={I}{O}]*/ () {
    return lines;
  });
  return lines;
}

/*member: accessInClosure:[exact=JSUInt31|powerset={I}{O}]*/
accessInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[exact=JSBool|powerset={I}{O}]*/ () {
    return lines. /*[exact=JSUInt31|powerset={I}{O}]*/ isEven;
  });
  return lines;
}

/*member: invokeInClosure:[exact=JSUInt31|powerset={I}{O}]*/
invokeInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSNumber|powerset={I}{O}]*/ () {
    return lines. /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ ceilToDouble();
  });
  return lines;
}

/*member: operatorInClosure:[exact=JSUInt31|powerset={I}{O}]*/
operatorInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}{O}]*/ () {
    return lines /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ - 42;
  });
  return lines;
}

/*member: assignInClosure:[subclass=JSInt|powerset={I}{O}]*/
assignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  return lines;
}

/*member: assignInTwoClosures:[subclass=JSInt|powerset={I}{O}]*/
assignInTwoClosures() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = -42;
  });
  local(/*[null|powerset={null}]*/ () {
    lines = -87;
  });
  return lines;
}

/*member: accessAssignInClosure:[subclass=JSInt|powerset={I}{O}]*/
accessAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines = lines /*invoke: [subclass=JSInt|powerset={I}{O}]*/ - 42;
  });
  return lines;
}

/*member: accessBeforeAssignInClosure:[exact=JSUInt31|powerset={I}{O}]*/
accessBeforeAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ - 42;
    lines = 42;
  });
  return lines;
}

/*member: accessAfterAssignInClosure:[exact=JSUInt31|powerset={I}{O}]*/
accessAfterAssignInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[subclass=JSInt|powerset={I}{O}]*/ () {
    lines = 42;
    return lines /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ - 42;
  });
  return lines;
}

/*member: compoundInClosure:[subclass=JSInt|powerset={I}{O}]*/
compoundInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSInt|powerset={I}{O}]*/ -= 42;
  });
  return lines;
}

/*member: postfixInClosure:[subclass=JSPositiveInt|powerset={I}{O}]*/
postfixInClosure() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  local(/*[subclass=Closure|powerset={N}{O}]*/ f) => f();

  int lines = 0;
  local(/*[null|powerset={null}]*/ () {
    lines /*invoke: [subclass=JSPositiveInt|powerset={I}{O}]*/ ++;
  });
  return lines;
}
