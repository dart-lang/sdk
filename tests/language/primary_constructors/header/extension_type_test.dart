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

extension type ET5({required int i});

extension type ET6({int i = 0});

extension type ET7({int? i});

extension type ET8([int? i]);

void main() {
  Expect.equals(1, ET1(1).i);
  Expect.equals(1, ET2(1).i);
  Expect.equals(1, ET3(1).i);
  Expect.equals(1, ET4(1).i);
  Expect.equals(1, ET5(i: 1).i);
  Expect.equals(0, ET6().i);
  Expect.equals(1, ET6(i: 1).i);
  Expect.equals(null, ET7().i);
  Expect.equals(1, ET7(i: 1).i);
  Expect.equals(null, ET8().i);
  Expect.equals(1, ET8(1).i);
}
