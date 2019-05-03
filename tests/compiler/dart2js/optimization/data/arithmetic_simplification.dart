// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test constant folding on numbers.

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
int confuse(int x) => x;

/*element: intPlusZero:Specializer=[Add,BitAnd]*/
@pragma('dart2js:noInline')
intPlusZero() {
  int x = confuse(0);
  return (x & 1) + 0;
}

/*element: zeroPlusInt:Specializer=[Add,BitAnd]*/
@pragma('dart2js:noInline')
zeroPlusInt() {
  int x = confuse(0);
  return 0 + (x & 1);
}

/*element: numPlusZero:Specializer=[Add]*/
@pragma('dart2js:noInline')
numPlusZero() {
  num x = confuse(0);
  return x + 0;
}

/*element: zeroPlusNum:Specializer=[Add]*/
@pragma('dart2js:noInline')
zeroPlusNum() {
  num x = confuse(0);
  return 0 + x;
}

/*element: intTimesOne:Specializer=[BitAnd,Multiply]*/
@pragma('dart2js:noInline')
intTimesOne() {
  int x = confuse(0);
  return (x & 1) * 1;
}

/*element: oneTimesInt:Specializer=[BitAnd,Multiply]*/
@pragma('dart2js:noInline')
oneTimesInt() {
  int x = confuse(0);
  return 1 * (x & 1);
}

/*element: numTimesOne:Specializer=[Multiply]*/
@pragma('dart2js:noInline')
numTimesOne() {
  num x = confuse(0);
  return x * 1;
}

/*element: oneTimesNum:Specializer=[Multiply]*/
@pragma('dart2js:noInline')
oneTimesNum() {
  num x = confuse(0);
  return 1 * x;
}

main() {
  intPlusZero();
  zeroPlusInt();
  numPlusZero();
  zeroPlusNum();
  intTimesOne();
  oneTimesInt();
  numTimesOne();
  oneTimesNum();
}
