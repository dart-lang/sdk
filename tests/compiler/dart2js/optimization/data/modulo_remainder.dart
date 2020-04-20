// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: mod1:Specializer=[Modulo]*/
@pragma('dart2js:noInline')
mod1(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a % 2;
  // present: ' % 2'
  // absent: '$mod'
}

/*member: mod2:Specializer=[!Modulo]*/
@pragma('dart2js:noInline')
mod2(param) {
  var a = param ? 0xFFFFFFFF : -0.0;
  return a % 2;
  // Cannot optimize due to potential -0.
  // present: '$mod'
  // absent: ' % 2'
}

/*member: mod3:Specializer=[Modulo]*/
@pragma('dart2js:noInline')
mod3(param) {
  var a = param ? 0xFFFFFFFF : -0.0;
  return (a + 1) % 2;
  // 'a + 1' cannot be -0.0, so we can optimize.
  // present: ' % 2'
  // absent: '$mod'
}

/*member: rem1:Specializer=[Remainder]*/
@pragma('dart2js:noInline')
rem1(param) {
  var a = param ? 0xFFFFFFFF : 1;
  return a.remainder(2);
  // Above can be compiled to '%'.
  // present: ' % 2'
  // absent: 'remainder'
}

/*member: rem2:Specializer=[Remainder]*/
@pragma('dart2js:noInline')
rem2(param) {
  var a = param ? 123.4 : -1;
  return a.remainder(3);
  // Above can be compiled to '%'.
  // present: ' % 3'
  // absent: 'remainder'
}

/*member: rem3:Specializer=[!Remainder]*/
@pragma('dart2js:noInline')
rem3(param) {
  var a = param ? 123 : null;
  return 100.remainder(a);
  // No specialization for possibly null inputs.
  // present: 'remainder'
  // absent: '%'
}

main() {
  mod1(true);
  mod1(false);
  mod2(true);
  mod2(false);
  mod3(true);
  mod3(false);

  rem1(true);
  rem1(false);
  rem2(true);
  rem2(false);
  rem3(true);
  rem3(false);
}
