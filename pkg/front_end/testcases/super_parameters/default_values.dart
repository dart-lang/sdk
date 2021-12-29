// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S1 {
  int s;
  S1([int x = 0]) : s = x - 1;
}

class C1 extends S1 {
  int c;
  C1([super.x]) : c = x + 1; // Ok.
}

class S2 {
  int s;
  S2({int x = 0}) : s = x - 1;
}

class C2 extends S2 {
  int c;
  C2({super.x}) : c = x + 1; // Ok.
}

class S3 {
  int s;
  S3([int x = 0]) : s = x - 1;
}

class C3 extends S3 {
  int c;
  C3([super.x = 42]) : c = x + 1; // Ok.
}

class S4 {
  int s;
  S4({int x = 0}) : s = x - 1;
}

class C4 extends S4 {
  int c;
  C4({super.x = 42}) : c = x + 1; // Ok.
}

class S5 {
  num a;
  S5([num x = 3.14]) : a = x - 1;
}

class C5 extends S5 {
  C5([int super.x]); // Error.
}

class S6 {
  num? a;
  S6([num? x = 3.14]) : a = x;
}

class C6 extends S6 {
  int? b;
  C6([int? super.x]); // Ok.
}

class S7 {
  int s;
  S7([int x = 0]) : s = x - 1;
}

class C7 extends S7 {
  int c;
  C7([super.x]) : c = x + 1;
}

class CC7 extends C7 {
  int cc;
  CC7([super.x]) : cc = x * 1;
}

class S8 {
  int s;
  S8([int x = 0]) : s = x - 1;
}

class CC8 extends C8 {
  int cc;
  CC8([super.x]) : cc = x * 1;
}

class C8 extends S8 {
  int c;
  C8([super.x]) : c = x + 1;
}

class CC9 extends C9 {
  int cc;
  CC9([super.x]) : cc = x * 1;
}

class C9 extends S9 {
  int c;
  C9([super.x]) : c = x + 1;
}

class S9 {
  int s;
  S9([int x = 0]) : s = x - 1;
}

main() {}
