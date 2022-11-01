// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/synced/embedded_names.dart' show JsGetName;

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../js/js.dart' as jsAst;
import '../universe/selector.dart' show Selector;

import 'namer_migrated.dart';

abstract class ModularNamer {
  jsAst.Name get rtiFieldJsName;
  jsAst.Name aliasedSuperMemberPropertyName(MemberEntity member);
  jsAst.Name asName(String name);
  String breakLabelName(LabelDefinition label);
  String continueLabelName(LabelDefinition label);
  String implicitBreakLabelName(JumpTarget target);
  String implicitContinueLabelName(JumpTarget target);
  jsAst.Name invocationName(Selector selector);
  jsAst.Name instanceFieldPropertyName(FieldEntity element);
  jsAst.Name instanceMethodName(FunctionEntity method);
  jsAst.Name nameForGetInterceptor(Set<ClassEntity> classes);
  jsAst.Name nameForOneShotInterceptor(
      Selector selector, Set<ClassEntity> classes);
  jsAst.Name getNameForJsGetName(Spannable spannable, JsGetName name);
  jsAst.Expression readGlobalObjectForInterceptors();
  jsAst.Expression readGlobalObjectForClass(ClassEntity element);
  jsAst.Expression readGlobalObjectForMember(MemberEntity element);
  String safeVariableName(String name);
  jsAst.Name methodPropertyName(FunctionEntity method);
  jsAst.Name operatorIs(ClassEntity element);
  jsAst.Name lazyInitializerName(FieldEntity element);
  jsAst.Name staticClosureName(FunctionEntity element);
  jsAst.Name className(ClassEntity class_);
  jsAst.Name globalPropertyNameForClass(ClassEntity element);
  jsAst.Name globalPropertyNameForMember(MemberEntity element);
  jsAst.Name globalNameForInterfaceTypeVariable(
      TypeVariableEntity typeVariable);
  String safeVariablePrefixForAsyncRewrite(String name);
  jsAst.Name deriveAsyncBodyName(jsAst.Name original);
}

abstract class Namer extends ModularNamer {
  FixedNames get fixedNames;
  jsAst.Name get noSuchMethodName;
  String get closureInvocationSelectorName;
  jsAst.Name constantName(ConstantValue constant);
  jsAst.Name fieldAccessorName(FieldEntity element);
  jsAst.Name getterForElement(MemberEntity element);
  jsAst.Name getterForMember(Name originalName);
  jsAst.Name invocationMirrorInternalName(Selector selector);
  jsAst.Name setterForMember(MemberEntity element);
  jsAst.Name deriveSetterName(jsAst.Name disambiguatedName);
  jsAst.Name deriveGetterName(jsAst.Name disambiguatedName);
  String get typesOffsetName;
}
