// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch(var e) {
    return true;
  }
}

typedef FList(List l);
typedef FListInt(List<int> l);

FList f() {
  return (List<String> l) => null; // Type of function is a subtype of FList.
}

main() {
  bool got_type_error = false;
  try {
    // Static result type of f(), i.e. FList, is a subtype of FListInt.
    // However, run time type of returned function is not a subtype of FListInt.
    // Run time type check should not be eliminated.
    FListInt fli = f();
  } catch (TypeError error) {
    got_type_error = true;
  }
  // Type error expected in checked mode only.
  Expect.isTrue(got_type_error == isCheckedMode());
}
