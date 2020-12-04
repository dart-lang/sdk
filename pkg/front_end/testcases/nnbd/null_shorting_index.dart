// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  Class2? get field => null;
  int operator [](int index) => index;
  void operator []=(int index, int value) {}
}

class Class2 {
  int field = 42;
}

extension Extension on Class2 {
  int operator [](int index) => field;
  void operator []=(int index, int value) {
    field = value;
  }
}

main() {
  Class1? c1;
  c1?[0];
  c1?[0] = 1;
  c1?[0] = 1 + c1[0];
  c1?[0] += 1;
  c1?[0] += 1 + c1[0];
  ++c1?[0];
  c1?[0]++;
  c1?[0] ??= 1;
  c1?[0] ??= 1 + c1[1];

  Class2? c2;
  c2?[0];
  c2?[0] = 1;
  c2?[0] = 1 + c2[0];
  c2?[0] += 1;
  c2?[0] += 1 + c2[0];
  ++c2?[0];
  c2?[0]++;
  c2?[0] ??= 1;
  c2?[0] ??= 1 + c2[1];

  Extension(c2)?[0];
  Extension(c2)?[0] = 1;
  Extension(c2)?[0] = 1 + Extension(c2)[0];
  Extension(c2)?[0] += 1;
  Extension(c2)?[0] += 1 + Extension(c2)[0];
  ++Extension(c2)?[0];
  Extension(c2)?[0]++;
  Extension(c2)?[0] ??= 1;
  Extension(c2)?[0] ??= 1 + Extension(c2)[1];

  c1?.field?[0];
  c1?.field?[0] = 1;
  c1?.field?[0] = 1 + c1[0];
  c1?.field?[0] += 1;
  c1?.field?[0] += 1 + c1[0];
  ++c1?.field?[0];
  c1?.field?[0]++;
  c1?.field?[0] ??= 1;
  c1?.field?[0] ??= 1 + c1[1];

  Extension(c1?.field)?[0];
  Extension(c1?.field)?[0] = 1;
  Extension(c1?.field)?[0] = 1 + (Extension(c2)?[0]! as int);
  Extension(c1?.field)?[0] += 1;
  Extension(c1?.field)?[0] += 1 + (Extension(c2)?[0]! as int);
  ++Extension(c1?.field)?[0];
  Extension(c1?.field)?[0]++;
  Extension(c1?.field)?[0] ??= 1;
  Extension(c1?.field)?[0] ??= 1 + (Extension(c2)?[1]! as int);
}
