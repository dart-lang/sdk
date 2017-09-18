// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that metadata on a class 'Super' using subtypes of 'Super' are not
// considered as cyclic inheritance or lead to crashes.

@Sub1(0) //# 01: ok
class Super {
  final field;
  @Sub2(1) //# 02: ok
  const Super(this.field);
}

class Sub1 extends Super {
  const Sub1(var field) : super(field);
}

class Sub2 extends Super {
  const Sub2(var field) : super(field);
}

void main() {
  print(new Super(1));
}
