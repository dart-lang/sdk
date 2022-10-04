// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/native_data.dart';
import '../js_backend/field_analysis.dart';
import '../world_interfaces.dart';
import '../universe/member_usage.dart';
import 'element_map.dart';

abstract class KClosedWorld implements BuiltWorld {
  KernelToElementMap get elementMap;
  KElementEnvironment get elementEnvironment;

  KCommonElements get commonElements;

  NativeData get nativeData;

  KFieldAnalysis get fieldAnalysis;

  Iterable<Local> get localFunctions;

  Set<FunctionEntity> get closurizedMembersWithFreeTypeVariables;

  DartTypes get dartTypes;

  BackendUsage get backendUsage;

  Map<MemberEntity, MemberUsage> get liveMemberUsage;

  bool isMemberUsed(MemberEntity member);
}
