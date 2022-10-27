// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../js/js.dart' as jsAst;
import '../universe/selector.dart' show Selector;
import 'package:js_shared/synced/embedded_names.dart' show JsGetName;

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
}
