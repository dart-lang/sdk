// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class State<U, T> {
  T? t;
  U? u;
  State(List l) {
    t = l[0] is T ? l[0] : null;
    u = l[1] is U ? l[1] : null;
  }
}
/** DIFF **/
/*
@@ -2,7 +2,7 @@
 // for details. All rights reserved. Use of this source code is governed by a
 // BSD-style license that can be found in the LICENSE file.
 
-class State<T, U> {
+class State<U, T> {
   T? t;
   U? u;
   State(List l) {
*/
