// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  const Base();

  @override
  // ignore: unnecessary_overrides
  String toString() => super.toString();
}

class Child extends Base {
  @override
  // ignore: unnecessary_overrides
  String toString() => super.toString();
}

class Other {
  @override
  String toString({bool? someArg1, bool? someArg2}) => super.toString();
}
