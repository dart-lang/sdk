// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/
void main() {
  /*bl*/ /*sl:1*/ var count = 0;
  for (/*sl:2*/ var i = 0;
      /*sl:3*/ /*sl:8*/ /*sl:13*/ /*sl:17*/ /*nbb:18:21*/ i < 42;
      /*sl:7*/ /*sl:12*/ /*sl:16*/ /*nbb:17:21*/ ++i) {
    /*sl:4*/ /*sl:9*/ /*sl:14*/ /*sl:18*/ /*nbb:19:21*/ if (i == 2) {
      /*sl:15*/ continue;
    }
    /*sl:5*/ /*sl:10*/ /*sl:19*/ if (i == 3) {
      /*sl:20*/ break;
    }
    /*sl:6*/ /*sl:11*/ count++;
  }
  /*s:21*/ print(count);
}
