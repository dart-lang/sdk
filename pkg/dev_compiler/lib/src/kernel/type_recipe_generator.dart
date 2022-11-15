// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/synced/recipe_syntax.dart' show Recipe;
import 'package:kernel/ast.dart';
import 'package:path/path.dart' as p;

import '../compiler/js_names.dart';

/// A visitor to generate type recipe strings from a [DartType].
///
/// The recipes are used by the 'dart:_rti' library while running the compiled
/// application.
class TypeRecipeGenerator extends DartTypeVisitor<String> {
  @override
  String defaultDartType(DartType node) {
    return 'TODO';
  }

  @override
  String visitDynamicType(DynamicType node) => Recipe.pushDynamicString;

  @override
  String visitVoidType(VoidType node) => Recipe.pushVoidString;

  @override
  String visitInterfaceType(InterfaceType node) {
    var recipe = interfaceTypeRecipe(node.classNode);
    if (node.typeArguments.isEmpty) {
      return '$recipe${_nullabilityRecipe(node)}';
    }
    return 'TODO';
  }

  @override
  String visitFutureOrType(FutureOrType node) =>
      '${node.typeArgument.accept(this)}'
      '${Recipe.wrapFutureOrString}'
      '${_nullabilityRecipe(node)}';

  @override
  String visitFunctionType(FunctionType node) => defaultDartType(node);

  @override
  String visitTypeParameterType(TypeParameterType node) =>
      defaultDartType(node);

  @override
  String visitTypedefType(TypedefType node) => defaultDartType(node);

  @override
  String visitNeverType(NeverType node) =>
      // Normalize Never? -> Null
      node.nullability == Nullability.nullable
          ? visitNullType(const NullType())
          : '${Recipe.pushNeverExtensionString}'
              '${Recipe.extensionOpString}'
              '${_nullabilityRecipe(node)}';

  @override
  String visitNullType(NullType node) => defaultDartType(node);

  @override
  String visitExtensionType(ExtensionType node) => defaultDartType(node);

  @override
  String visitIntersectionType(IntersectionType node) =>
      visitTypeParameterType(node.left);

  /// Returns the recipe for the interface type introduced by [cls].
  static String interfaceTypeRecipe(Class cls) {
    var path = p.withoutExtension(cls.enclosingLibrary.importUri.path);
    var library = pathToJSIdentifier(path);
    return '$library${Recipe.librarySeparatorString}${cls.name}';
  }

  /// Returns the recipe representation of [nullability].
  static String _nullabilityRecipe(DartType type) {
    switch (type.declaredNullability) {
      case Nullability.undetermined:
        if (type is TypeParameterType) {
          // Type parameters are expected to appear with undetermined
          // nullability since they could be instantiated with nullable type.
          // In this case we allow the type to flow without adding any
          // nullability information.
          return '';
        }
        throw UnsupportedError('Undetermined nullability.');
      case Nullability.nullable:
        return Recipe.wrapQuestionString;
      case Nullability.nonNullable:
        return '';
      case Nullability.legacy:
        return Recipe.wrapStarString;
    }
  }
}
