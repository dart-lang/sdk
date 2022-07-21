// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/backend_usage.dart';
import '../world_interfaces.dart';

abstract class KClosedWorld implements BuiltWorld {
  KElementEnvironment get elementEnvironment;

  KCommonElements get commonElements;

  Iterable<Local> get localFunctions;

  Set<FunctionEntity> get closurizedMembersWithFreeTypeVariables;

  DartTypes get dartTypes;

  BackendUsage get backendUsage;

  bool isMemberUsed(MemberEntity member);
}
