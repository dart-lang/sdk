// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show min;

import 'package:kernel/ast.dart' as ast;
import 'package:kernel/type_algebra.dart' show Substitution;

bool hasInstantiatorTypeArguments(ast.Class cls) {
  for (ast.Class? c = cls; c != null; c = c.superclass) {
    if (c.typeParameters.isNotEmpty) {
      return true;
    }
  }
  return false;
}

bool _canReuseSuperclassTypeArguments(
  List<ast.DartType> superTypeArgs,
  List<ast.TypeParameter> typeParameters,
  int overlap,
) {
  for (var i = 0; i < overlap; ++i) {
    final superTypeArg = superTypeArgs[superTypeArgs.length - overlap + i];
    final typeParam = typeParameters[i];
    if (!(superTypeArg is ast.TypeParameterType &&
        superTypeArg.parameter == typeParameters[i] &&
        superTypeArg.nullability == typeParam.computeNullabilityFromBound())) {
      return false;
    }
  }
  return true;
}

List<ast.DartType> flattenInstantiatorTypeArguments(
  ast.Class instantiatedClass,
  List<ast.DartType> typeArgs,
) {
  final typeParameters = instantiatedClass.typeParameters;
  assert(typeArgs.length == typeParameters.length);

  final supertype = instantiatedClass.supertype;
  if (supertype == null) {
    return typeArgs;
  }

  final superTypeArgs = flattenInstantiatorTypeArguments(
    supertype.classNode,
    supertype.typeArguments,
  );

  // Shrink type arguments by reusing portion of superclass type arguments
  // if there is an overlapping. This optimization should be consistent with
  // VM in order to correctly reuse instantiator type arguments.
  int overlap = min(superTypeArgs.length, typeArgs.length);
  for (; overlap > 0; --overlap) {
    if (_canReuseSuperclassTypeArguments(
      superTypeArgs,
      typeParameters,
      overlap,
    )) {
      break;
    }
  }

  assert(typeParameters.length == typeArgs.length);

  final substitution = Substitution.fromPairs(typeParameters, typeArgs);

  final flatTypeArgs = <ast.DartType>[];
  for (var type in superTypeArgs) {
    flatTypeArgs.add(substitution.substituteType(type));
  }
  flatTypeArgs.addAll(typeArgs.getRange(overlap, typeArgs.length));

  return flatTypeArgs;
}

List<ast.DartType>? getInstantiatorTypeArguments(
  ast.Class instantiatedClass,
  List<ast.DartType> typeArgs,
) {
  final flatTypeArgs = flattenInstantiatorTypeArguments(
    instantiatedClass,
    typeArgs,
  );
  if (isAllDynamic(flatTypeArgs)) {
    return null;
  }
  return flatTypeArgs;
}

bool isAllDynamic(List<ast.DartType> typeArgs) {
  for (var t in typeArgs) {
    if (t != const ast.DynamicType()) {
      return false;
    }
  }
  return true;
}

/// Calculate index of [tp] in the type arguments vector.
int computeIndexOfTypeParameter(ast.TypeParameter tp) {
  final decl = tp.declaration!;
  int index = decl.typeParameters.indexOf(tp);
  assert(index >= 0);
  if (decl is ast.LocalFunction) {
    ast.TreeNode node = decl.parent!;
    while (node is! ast.Member) {
      if (node is ast.FunctionNode) {
        index += node.typeParameters.length;
      }
      node = node.parent!;
    }
  }
  return index;
}

/// Return enclosing member of the given [node].
ast.Member getEnclosingMember(ast.TreeNode node) {
  do {
    node = node.parent!;
  } while (node is! ast.Member);
  return node;
}

/// Returns true if [field] has a non-trivial initializer.
///
/// VM does not allow field initializer functions for fields
/// with trivial initializers.
bool hasNonTrivialInitializer(ast.Field field) {
  final initializer = field.initializer;
  if (initializer == null) return false;
  if (field.isStatic) {
    return switch (initializer) {
      ast.StringLiteral() ||
      ast.BoolLiteral() ||
      ast.IntLiteral() ||
      ast.DoubleLiteral() ||
      ast.NullLiteral() ||
      ast.ConstantExpression(constant: ast.PrimitiveConstant()) => false,
      _ => true,
    };
  } else {
    return switch (initializer) {
      ast.NullLiteral() ||
      ast.ConstantExpression(constant: ast.NullConstant()) => false,
      _ => true,
    };
  }
}

/// Returns true if [type] references class type parameters.
bool containsClassTypeParameters(ast.DartType type) {
  final visitor = _FindClassTypeParameters();
  type.accept(visitor);
  return visitor.containsClassTypeParams;
}

class _FindClassTypeParameters extends ast.RecursiveVisitor {
  bool containsClassTypeParams = false;

  _FindClassTypeParameters();

  @override
  void visitTypeParameterType(ast.TypeParameterType node) {
    if (node.parameter.declaration is ast.Class) {
      containsClassTypeParams = true;
    }
  }
}

bool hasGenericEnclosingFunction(ast.TreeNode node) {
  for (;;) {
    node = node.parent!;
    if (node is ast.Member) {
      return false;
    }
    if (node is ast.FunctionNode && node.typeParameters.isNotEmpty) {
      return true;
    }
  }
}
