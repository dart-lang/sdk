// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/
void main() {
  /*bl*/ /*sl:1*/ var data = [1, 2, 3];
  for (
      // comment forcing formatting
      /*sl:3*/ /*sl:5*/ /*sl:7*/ /*sl:8*/ var datapoint
      // comment forcing formatting
      in
      // comment forcing formatting
      /*sl:2*/ data
      // comment forcing formatting
      ) {
    /*sl:4*/ /*sl:6*/ /*sl:8*/ print(datapoint);
  }
  /*sl:9 */ print('Done');
}
