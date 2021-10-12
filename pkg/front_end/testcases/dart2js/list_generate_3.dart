// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var list1 = List<int>.generate(10, (i) {
  return i;
});

var list2 = List<int>.generate(10, (i) {
  return i;
}, growable: true);

var list3 = List<int>.generate(10, (i) {
  return i;
}, growable: false);

var list4 = List<int>.generate(10, (i) {
  return i;
}, growable: someGrowable);

// Not expanded - complex closure.
var list5 = List<int>.generate(10, (i) {
  if (i.isEven) return i + 1;
  return i - 1;
});

// Not expanded - inscrutable closure.
var list6 = List<int>.generate(10, foo);
int foo(int i) => i;

// Not expanded - inscrutable closure.
var list7 = List<int>.generate(10, bar);
int Function(int) get bar => foo;

bool someGrowable = true;

void main() {
  someGrowable = !someGrowable;
  print([list1, list2, list3, list4, list5, list6, list7]);
}
