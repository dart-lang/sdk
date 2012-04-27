// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
// An interface with a constructor declared must have a default clause

interface IA { 
  IA(); // Compile time error here
} 

main() {
  try {
    IA value = new IA();
  } catch(Exception e) {
    print ("Got exception" + e);
    // compile-time error should not be catchable
  }
}
