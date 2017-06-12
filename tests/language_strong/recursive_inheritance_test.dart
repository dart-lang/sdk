// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for recursive inheritance patterns
abstract class Comparable<T> {
  int compareTo(T a);
}

class MI<T extends MI<T>> {}

class _MI extends MI<_MI> {}

class PMI<T extends Comparable<T>> extends MI<PMI<T>> {}

class _PMI extends PMI<_PMI> implements Comparable<_PMI> {
  int compareTo(_PMI other) => throw new UnimplementedError();
}

void main() {
  MI a = new MI<_MI>();
  PMI b = new PMI<_PMI>();
  a = b;
  Expect.isTrue(a is MI);
  Expect.isTrue(b is PMI);
  Expect.isTrue(b is MI);
  Expect.isTrue(b is MI<PMI>);
}
