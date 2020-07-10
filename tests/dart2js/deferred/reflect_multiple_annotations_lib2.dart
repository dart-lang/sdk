// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MetaB("lib")
library foo;

@MetaB("class")
class A {}

class MetaB {
  final value;
  const MetaB(this.value);

  String toString() => "MetaB($value)";
}
