// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_function_declarations_over_variables`

void main() {
  thisIsGood() { // OK
    print('this is good');
  }

  var ok = () { // OK
    print('this is ok');
  };
  ok = (){
    print('this is still ok');
  };

  var bad1 = () { // LINT
    print('this is bad');
  };

  var bad2 = bad1; // OK

  bad2 = bad1; // OK

  bad2 = () { // OK
    print('this is bad');
  };

  var bad3 = print; // OK

  bad3 = print; // OK
}
