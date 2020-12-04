// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  /*bl*/
  try {
    /*sl:1*/ throw 'Boom!';
  } /*bc:2*/ on StateError {
    /*nb*/ print('StateError');
  } /*bc:3*/ on ArgumentError catch (e) {
    /*nb*/ print('ArgumentError: $e');
  } catch (e) {
    /*bc:4*/ print(e);
  }
}
