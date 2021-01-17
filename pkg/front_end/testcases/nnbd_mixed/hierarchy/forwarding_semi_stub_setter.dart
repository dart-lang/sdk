// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void set setter1(num n) {}
  void set setter2(num n) {}
  void set setter3(num n) {}

  void set setter4(covariant num i) {}
  void set setter5(covariant int i) {}
}

class Interface {
  void set setter1(covariant int i) {}
  void set setter2(covariant int i) {}

  void set setter4(int i) {}
  void set setter5(int i) {}
}

class Class extends Super implements Interface {
  void set setter1(int i);
  void set setter2(String i);
  void set setter3(int i);

  void set setter4(int i);
  void set setter5(num n);
}

main() {}
