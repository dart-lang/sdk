// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


typedef void funcType(int arg);

class A extends funcType {  // illegal, funcType is not a class
}

main() {
  new A();
}
