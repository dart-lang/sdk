// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

void main() {
  Object o = 1;
  try {
    for (int i = 0; o; i++) {}
    throw 'no exception';
  } on TypeError {}
}
