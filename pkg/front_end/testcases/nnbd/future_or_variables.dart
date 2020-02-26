// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

FutureOr topLevelField1;
FutureOr<int?> topLevelField2;
FutureOr<FutureOr> topLevelField3;

void toplevelMethod1(
    [FutureOr parameter1,
    FutureOr<int?> parameter2,
    FutureOr<FutureOr> parameter3]) {}

void toplevelMethod2(
    {FutureOr parameter1,
    FutureOr<int?> parameter2,
    FutureOr<FutureOr> parameter3}) {}

class Class1 {
  FutureOr instanceField1;
  FutureOr<int?> instanceField2;
  FutureOr<FutureOr> instanceField3;

  static FutureOr staticField1;
  static FutureOr<int?> staticField2;
  static FutureOr<FutureOr> staticField3;

  void instanceMethod1(
      [FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3]) {}

  void instanceMethod2(
      {FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3}) {}

  static void staticMethod1(
      [FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3]) {}

  static void staticMethod2(
      {FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3}) {}
}

class Class2 {
  FutureOr instanceField1;
  FutureOr<int?> instanceField2;
  FutureOr<FutureOr> instanceField3;

  Class2.constructor1(
      this.instanceField1, this.instanceField2, this.instanceField3);

  Class2.constructor2();
}

main() {
  FutureOr local1;
  FutureOr<int?> local2;
  FutureOr<FutureOr> local3;

  print(local1);
  print(local2);
  print(local3);

  void localFunction1(
      [FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3]) {}

  void localFunction2(
      {FutureOr parameter1,
      FutureOr<int?> parameter2,
      FutureOr<FutureOr> parameter3}) {}
}
