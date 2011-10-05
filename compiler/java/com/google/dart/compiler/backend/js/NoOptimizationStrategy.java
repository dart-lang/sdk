// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.backend.common.TypeHeuristic.FieldKind;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldElement;

class NoOptimizationStrategy implements OptimizationStrategy {

  public NoOptimizationStrategy(DartUnit unit, CoreTypeProvider typeProvider) {
  }

  @Override
  public boolean canSkipOperatorShim(DartBinaryExpression x) {
    return false;
  }

  @Override
  public boolean canSkipArrayAccessShim(DartArrayAccess array, boolean isAssignee) {
    return false;
  }

  @Override
  public FieldElement findOptimizableFieldElementFor(DartExpression expr, FieldKind fieldKind) {
    return null;
  }

  @Override
  public Element findElementFor(DartMethodInvocation expr) {
    return (Element) expr.getTargetSymbol();
  }

  @Override
  public boolean canSkipOperatorShim(DartUnaryExpression x) {
    return false;
  }

  @Override
  public boolean canSkipNormalization(DartBinaryExpression receiver) {
    return false;
  }

  @Override
  public boolean canSkipNormalization(DartUnaryExpression expr) {
    return false;
  }

  @Override
  public boolean canInlineInitializers(ConstructorElement constructorElement) {
    return false;
  }

  @Override
  public boolean canEmitOptimizedClassConstructor(ClassElement classElement) {
    return false;
  }

  @Override
  public boolean isWhitelistedNativeField(FieldElement field, FieldKind fieldKind) {
    return false;
  }

  @Override
  public boolean canOptimizeFunctionExpressionBind(DartFunctionExpression expr) {
    return false;
  }
}
