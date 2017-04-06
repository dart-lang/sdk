// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N always_put_control_body_on_new_line`

testIfElse() {
  if (false) return; // LINT

  if (false) {} // LINT

  if (false)
    return; // OK

  if (false) { // OK
  }

  if (false)
    return; // OK
  else return; // LINT

  if (false) { } // LINT
  else return; // LINT

  if (false)
    return; // OK
  else
    return; // OK

  if (false){ }// LINT
  else {} // LINT
}

testWhile() {
  while (true) return; // LINT

  while (true) {} // LINT

  while (true)
    return; // OK
}

testForEach(List l) {
  for (var i in l) return; // LINT

  for (var i in l) {} // LINT

  for (var i in l)
    return; // OK
}

testFor() {
  for (;;) return; // LINT

  for (;;) {} // LINT

  for (;;)
    return; // OK
}

testDo() {
  do print(''); // LINT
  while (true);

  do
    print(''); // OK
  while (true);
}
