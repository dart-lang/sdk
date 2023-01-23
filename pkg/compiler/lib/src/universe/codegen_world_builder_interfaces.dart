// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/use.dart';
import 'member_usage.dart';

abstract class CodegenWorldBuilderImplForEnqueuer {
  Iterable<ClassEntity> get directlyInstantiatedClasses;

  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed);

  void processClassMembers(ClassEntity cls, MemberUsedCallback memberUsed,
      {bool checkEnqueuerConsistency = false});

  void registerDynamicUse(DynamicUse dynamicUse, MemberUsedCallback memberUsed);

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed);

  void registerTypeVariableTypeLiteral(TypeVariableType typeVariable);

  void registerConstTypeLiteral(DartType type);

  void registerTypeArgument(DartType type);

  void registerConstructorReference(InterfaceType type);

  bool registerConstantUse(ConstantUse use);

  void registerIsCheck(covariant DartType type);

  void registerNamedTypeVariableNewRti(TypeVariableType type);
}
