// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  Object b = true;
  assert(b); // No error
  assert(b, 'should not fail'); // No error
  try {
    assert(false, b); // Type is ok
  } on AssertionError {}
  b = new Object();
  try {
    assert(b);
    assert(false, 'Did not throw');
  } on TypeError {}
  try {
    assert(b, 'type error should occur before assert check');
    assert(false, 'Did not throw');
  } on TypeError {}
}
