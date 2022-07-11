// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/elements.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'inferrer/abstract_value_domain.dart';
import 'js_backend/annotations.dart';
import 'js_backend/native_data.dart';
import 'universe/class_hierarchy.dart';
import 'universe/selector.dart';

/// Common superinterface for [OpenWorld] and [JClosedWorld].
abstract class World {}

abstract class JClosedWorld implements World {
  AbstractValueDomain get abstractValueDomain;
  JCommonElements get commonElements;
  ClassHierarchy get classHierarchy;
  DartTypes get dartTypes;
  NativeData get nativeData;
  AnnotationsData get annotationsData;
  bool includesClosureCall(Selector selector, AbstractValue? receiver);
  Iterable<MemberEntity> locateMembers(
      Selector selector, AbstractValue? receiver);
  bool fieldNeverChanges(MemberEntity element);
}
