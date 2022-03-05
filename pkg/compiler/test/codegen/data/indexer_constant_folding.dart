// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const kList = ['first', 'second'];
const kMap = {0: 'zero', 1: 'one', 2: "two"};

@pragma('dart2js:noInline')
/*member: list1:function() {
  return "second";
}*/
list1() {
  return kList[1]; // Constant folds to `"second"`.
}

@pragma('dart2js:noInline')
/*member: list2:function() {
  return A.ioore(B.List_first_second, 10);
  return B.List_first_second[10];
}*/
list2() {
  return kList[10]; // Does not constant-fold.
}

@pragma('dart2js:noInline')
/*member: map1:function() {
  return "one";
}*/
map1() {
  return kMap[1]; // Constant folds to `"one"`.
}

@pragma('dart2js:noInline')
/*member: map2:function() {
  return null;
}*/
map2() {
  return kMap[10]; // Constant folds to `null`.
}

/*member: main:ignore*/
main() {
  list1();
  list2();
  map1();
  map2();
}
