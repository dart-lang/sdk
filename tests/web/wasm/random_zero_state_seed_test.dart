// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:expect/expect.dart';

void main() {
  final random = Random(0x7ffffbffffdfffff);
  final ints = List.generate(20, (_) => random.nextInt(1000));
  Expect.isTrue(ints.toSet().length > 1, 'nextInt is stuck: $ints');
  final doubles = List.generate(20, (_) => random.nextDouble());
  Expect.isTrue(doubles.toSet().length > 1, 'nextDouble is stuck: $doubles');
  final bools = List.generate(20, (_) => random.nextBool());
  Expect.isTrue(bools.toSet().length > 1, 'nextBool is stuck: $bools');
}
