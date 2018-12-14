// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

const isAsExpression = const TypeMatcher<AsExpression>();

const isAssertInitializer = const TypeMatcher<AssertInitializer>();

const isAssignmentExpression = const TypeMatcher<AssignmentExpression>();

const isAwaitExpression = const TypeMatcher<AwaitExpression>();

const isBinaryExpression = const TypeMatcher<BinaryExpression>();

const isBlock = const TypeMatcher<Block>();

const isBlockFunctionBody = const TypeMatcher<BlockFunctionBody>();

const isClassDeclaration = const TypeMatcher<ClassDeclaration>();

const isClassTypeAlias = const TypeMatcher<ClassTypeAlias>();

const isCompilationUnit = const TypeMatcher<CompilationUnit>();

const isConditionalExpression = const TypeMatcher<ConditionalExpression>();

const isConstructorDeclaration = const TypeMatcher<ConstructorDeclaration>();

const isConstructorFieldInitializer =
    const TypeMatcher<ConstructorFieldInitializer>();

const isDefaultFormalParameter = const TypeMatcher<DefaultFormalParameter>();

const isEmptyFunctionBody = const TypeMatcher<EmptyFunctionBody>();

const isEmptyStatement = const TypeMatcher<EmptyStatement>();

const isExpressionFunctionBody = const TypeMatcher<ExpressionFunctionBody>();

const isExpressionStatement = const TypeMatcher<ExpressionStatement>();

const isFieldDeclaration = const TypeMatcher<FieldDeclaration>();

const isFieldFormalParameter = const TypeMatcher<FieldFormalParameter>();

const isForStatement = const TypeMatcher<ForStatement>();

const isFunctionDeclaration = const TypeMatcher<FunctionDeclaration>();

const isFunctionDeclarationStatement =
    const TypeMatcher<FunctionDeclarationStatement>();

const isFunctionExpression = const TypeMatcher<FunctionExpression>();

const isFunctionTypeAlias = const TypeMatcher<FunctionTypeAlias>();

const isFunctionTypedFormalParameter =
    const TypeMatcher<FunctionTypedFormalParameter>();

const isGenericFunctionType = const TypeMatcher<GenericFunctionType>();

const isIndexExpression = const TypeMatcher<IndexExpression>();

const isInstanceCreationExpression =
    const TypeMatcher<InstanceCreationExpression>();

const isIntegerLiteral = const TypeMatcher<IntegerLiteral>();

const isInterpolationExpression = const TypeMatcher<InterpolationExpression>();

const isInterpolationString = const TypeMatcher<InterpolationString>();

const isIsExpression = const TypeMatcher<IsExpression>();

const isLibraryDirective = const TypeMatcher<LibraryDirective>();

const isMethodDeclaration = const TypeMatcher<MethodDeclaration>();

const isMethodInvocation = const TypeMatcher<MethodInvocation>();

const isNullLiteral = const TypeMatcher<NullLiteral>();

const isParenthesizedExpression = const TypeMatcher<ParenthesizedExpression>();

const isPrefixedIdentifier = const TypeMatcher<PrefixedIdentifier>();

const isPrefixExpression = const TypeMatcher<PrefixExpression>();

const isPropertyAccess = const TypeMatcher<PropertyAccess>();

const isReturnStatement = const TypeMatcher<ReturnStatement>();

const isSimpleFormalParameter = const TypeMatcher<SimpleFormalParameter>();

const isSimpleIdentifier = const TypeMatcher<SimpleIdentifier>();

const isStringInterpolation = const TypeMatcher<StringInterpolation>();

const isSuperExpression = const TypeMatcher<SuperExpression>();

const isTopLevelVariableDeclaration =
    const TypeMatcher<TopLevelVariableDeclaration>();

const isTypeName = const TypeMatcher<TypeName>();

const isVariableDeclarationStatement =
    const TypeMatcher<VariableDeclarationStatement>();
