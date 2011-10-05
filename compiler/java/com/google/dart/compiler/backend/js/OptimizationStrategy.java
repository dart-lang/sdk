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
import com.google.dart.compiler.backend.common.TypeHeuristic.FieldKind;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.FieldElement;

interface OptimizationStrategy {

  boolean canSkipOperatorShim(DartBinaryExpression expr);

  boolean canSkipOperatorShim(DartUnaryExpression expr);

  boolean canSkipArrayAccessShim(DartArrayAccess array, boolean isAssignee);

  FieldElement findOptimizableFieldElementFor(DartExpression expr, FieldKind fieldKind);

  Element findElementFor(DartMethodInvocation expr);

  boolean canSkipNormalization(DartBinaryExpression expr);

  boolean canSkipNormalization(DartUnaryExpression expr);

  boolean canInlineInitializers(ConstructorElement constructorElement);

  boolean canEmitOptimizedClassConstructor(ClassElement classElement);

  boolean isWhitelistedNativeField(FieldElement field, FieldKind fieldKind);

  boolean canOptimizeFunctionExpressionBind(DartFunctionExpression expr);
}
