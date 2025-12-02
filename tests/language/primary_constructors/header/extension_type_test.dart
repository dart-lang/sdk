// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The modifier `final` on the representation variable in an extension type
// primary constructor can be specified or omitted.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

extension type ET1(int i);

extension type ET2(final int i);

extension type ET3(i);

extension type ET4(final i);

void main() {
  Expect.equals(1, ET1(1).i);
  Expect.equals(1, ET2(1).i);
  Expect.equals(1, ET3(1).i);
  Expect.equals(1, ET4(1).i);
}
