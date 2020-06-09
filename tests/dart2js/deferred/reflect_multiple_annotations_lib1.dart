// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

topLevelF() => 1;

@MetaA("one")
@MetaA(topLevelF)
myFunction1(@MetaA("param") f1) {
  return f1;
  return f1;
}

class MetaA {
  final value;
  const MetaA(this.value);

  static isCheck(v) => v is MetaA;

  String toString() => "MetaA($value)";
}
