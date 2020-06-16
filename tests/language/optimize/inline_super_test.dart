// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js issue 6639.

library inline_super_test;

import "package:expect/expect.dart";

part 'inline_super_part.dart';

// Long comment to ensure source positions in the following code are
// larger than the part file.  Best way to ensure that is to include
// the part as a comment:
//
// class Player extends LivingActor {
//   Player (deathCallback) : super(null, deathCallback);
// }

class Percept {}

class Actor {
  final percept;
  Actor(this.percept);
}

class LivingActor extends Actor {
  // The bug occurs when inlining the node [:new Percept():] into
  // [Actor]'s constructor.  When this inlining is being initiated
  // from [Player], we must take care to ensure that we know that we
  // are inlining from this location, and not [Player].
  LivingActor() : super(new Percept());
}

main() {
  Expect.isTrue(new Player().percept is Percept);
}
