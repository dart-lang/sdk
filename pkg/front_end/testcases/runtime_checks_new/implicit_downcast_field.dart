// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

Object o = 1;
bool topLevelValue = o;

class C {
  static bool staticValue = o;
  bool instanceValue = o;
}

main() {
  try {
    topLevelValue;
    throw 'no exception';
  } on TypeError {}
  try {
    C.staticValue;
    throw 'no exception';
  } on TypeError {}
  try {
    new C();
    throw 'no exception';
  } on TypeError {}
}
