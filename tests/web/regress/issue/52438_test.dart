// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Switches generate record accesses on non-existent fields. These accesses
// should be guarded by a type check but Dart2JS does not always promote
// correctly after the type check.

void main() {
  Object r = (1, 2);
  switch (r) {
    case (int _, int _, int c):
      print('Skip, no match');
  }
}
