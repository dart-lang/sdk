// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N curly_braces_in_flow_control_structures`

testIfElse() {
  if (false) return; // OK

  if (false) {} // OK

  if (false)
    return; // LINT

  if (false) { // OK
  }

  if (false)
    return; // LINT
  else return; // LINT

  if (false) {
  }
  else if (false) { // OK
  }
  else {
  }

  if (false)
    return; // LINT
  else if (false)
    return; // LINT
  else
    return; // LINT

  if (false) { // OK
  } else if (false) { // OK
  } else { // OK
  }

  if (false) { } // OK
  else return; // LINT

  if (false)
    return; // LINT
  else
    return; // LINT

  if (false){ }// OK
  else {} // OK

  if (false) print( // LINT
    'First argument'
    'Second argument');

  if (false) { print('should be on next line'); // OK
  }
}

testWhile() {
  while (true) return; // LINT

  while (true) {} // OK

  while (true)
    return; // LINT
}

testForEach(List l) {
  for (var i in l) return; // LINT

  for (var i in l) {} // OK

  for (var i in l)
    return; // LINT
}

testFor() {
  for (;;) return; // LINT

  for (;;) {} // OK

  for (;;)
    return; // LINT
}

testDo() {
  do print(''); while (true); // LINT
  do print(''); // LINT
  while (true);

  do
    print(''); // LINT
  while (true);

  do {print('');} // OK
  while (true);
}
