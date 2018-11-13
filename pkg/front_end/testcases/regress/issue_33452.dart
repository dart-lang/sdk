// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ExistingClass {
  ExistingClass.existingConstructor();
}

main() {
  var x = new ExistingClass.nonExistingConstructor();
  x = new ExistingClass();
  x = new ExistingClass<String>();
  x = new ExistingClass<String>.nonExistingConstructor();
  x = new ExistingClass<String, String>.nonExistingConstructor();
  x = new NonExistingClass();
}
