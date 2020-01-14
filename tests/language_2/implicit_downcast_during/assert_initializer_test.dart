// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C.oneArg(Object x) : assert(x);
  C.twoArgs(Object x, Object y) : assert(x, y);
}

void main() {
  Object b = true;
  new C.oneArg(b); // No error
  assert(b, 'should not fail'); // No error
  try {
    new C.twoArgs(false, b); // Type is ok
  } on AssertionError {}
  b = new Object();
  try {
    new C.oneArg(b);
    assert(false, 'Did not throw');
  } on TypeError {}
  try {
    new C.twoArgs(b, 'type error should occur before assert check');
    assert(false, 'Did not throw');
  } on TypeError {}
}
