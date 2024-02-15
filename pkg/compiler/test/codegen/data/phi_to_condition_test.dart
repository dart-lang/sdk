// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:never-inline')
/*member: foo1:function(a, b) {
  var changed = a !== b;
  if (changed)
    A.log("changed");
  return changed;
}*/
foo1(int a, int b) {
  bool changed = false;
  if (a != b) {
    changed = true;
    log('changed');
  }
  return changed;
}

@pragma('dart2js:never-inline')
/*member: log:ignore*/
void log(String s) {}

/*member: main:ignore*/
main() {
  foo1(1, 2);
  foo1(2, 1);
}
