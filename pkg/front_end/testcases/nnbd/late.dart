// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late int lateStaticField;
late final int finalLateStaticField;

class Class {
  late int lateInstanceField;
  late final int finalLateInstanceField = 0;

  static late int lateStaticField;
  static late final int finalLateStaticField = 0;

  method() {
    late int lateVariable;
    late final int lateFinalVariable = 0;
  }
}

main() {}