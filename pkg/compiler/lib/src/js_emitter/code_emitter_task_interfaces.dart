// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart';
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;

abstract class ModularEmitter {
  jsAst.Expression constructorAccess(ClassEntity e);
  jsAst.Expression constantReference(ConstantValue constant);
  jsAst.Expression isolateLazyInitializerAccess(covariant FieldEntity element);
  jsAst.Expression prototypeAccess(ClassEntity e);
  jsAst.Expression staticClosureAccess(covariant FunctionEntity element);
  jsAst.Expression staticFieldAccess(FieldEntity element);
  jsAst.Expression staticFunctionAccess(FunctionEntity element);
}
