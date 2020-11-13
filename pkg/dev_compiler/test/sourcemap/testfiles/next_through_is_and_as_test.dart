// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  /*bl*/
  /*sl:1*/ var i = 42.42;
  /*sl:2*/ var hex = 0x42;
  /*bc:3*/ if (/*bc:4*/ foo() is int) {
    /*bc:5*/ print('foo is int');
  }
  /*bc:6*/ if (i is int) {
    print('i is int');
  }
  /*bc:7*/ if (i is! int) {
    /*bc:8*/ print('i is not int');
  }
  /*bc:9*/ if (hex is int) {
    /*bc:10*/ print('hex is int');
    // ignore: unnecessary_cast
    var x = /*bc:11*/ hex as int;
    /*bc:12*/ if (x.isEven) {
      /*bc:13*/ print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  /*bc:14*/ if (hex is! int) {
    print('hex is not int');
  }
}

dynamic foo() => 42;
