// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:noInline')
// No code to construct unused map.
/*member: foo1:function() {
  return;
}*/
void foo1() {
  var x = {};
  return;
}

@pragma('dart2js:noInline')
// No code to construct unused maps.
/*member: foo2:function() {
  return;
}*/
void foo2() {
  var x = {};
  var y = <String, String>{};
  return;
}

@pragma('dart2js:noInline')
// No code to construct maps which become unused after list is removed.
/*member: foo3:function() {
  return;
}*/
void foo3() {
  var x = [{}, {}];
  return;
}

@pragma('dart2js:noInline')
// Constructor is inlined, allocation is removed, leaving maps unused.
/*member: foo4:function() {
  return;
}*/
void foo4() {
  var x = AAA4({});
  return;
}

class AAA4 {
  Map<String, String> field1 = {};
  Map<String, int> field2;
  AAA4(this.field2);
}

/*member: main:ignore*/
main() {
  foo1();
  foo2();
  foo3();
  foo4();
}
