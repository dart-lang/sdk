// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../js/js.dart' as jsAst;
import '../universe/selector.dart' show Selector;
import 'package:js_shared/synced/embedded_names.dart' show JsGetName;

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
  String safeVariableName(String name);
}

abstract class Namer extends ModularNamer {
  FixedNames get fixedNames;
  jsAst.Name get noSuchMethodName;
  String get closureInvocationSelectorName;
  jsAst.Name getterForElement(MemberEntity element);
  jsAst.Name invocationMirrorInternalName(Selector selector);
  jsAst.Name deriveSetterName(jsAst.Name disambiguatedName);
  jsAst.Name deriveGetterName(jsAst.Name disambiguatedName);
  String get typesOffsetName;
  jsAst.Name operatorIs(ClassEntity element);
}
