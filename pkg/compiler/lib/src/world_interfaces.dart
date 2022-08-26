// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'elements/entities.dart';
import 'inferrer/abstract_value_domain.dart';
import 'universe/selector.dart';

/// Common superinterface for [OpenWorld] and [JClosedWorld].
abstract class World {}

abstract class JClosedWorld implements World {
  bool includesClosureCall(Selector selector, AbstractValue receiver);
  Iterable<MemberEntity> locateMembers(
      Selector selector, AbstractValue receiver);
  bool fieldNeverChanges(MemberEntity element);
}
