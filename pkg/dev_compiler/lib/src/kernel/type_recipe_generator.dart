// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/synced/recipe_syntax.dart' show Recipe;
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:path/path.dart' as p;

import '../compiler/js_names.dart';
import 'kernel_helpers.dart';
import 'type_environment.dart';

class TypeRecipeGenerator {
  final _TypeRecipeVisitor _recipeVisitor;

  TypeRecipeGenerator(CoreTypes coreTypes)
      : _recipeVisitor =
            _TypeRecipeVisitor(const EmptyTypeEnvironment(), coreTypes);

  GeneratedRecipe recipeInEnvironment(
      DartType type, DDCTypeEnvironment environment) {
    var typeParameterFinder = TypeParameterTypeFinder();
    type.accept(typeParameterFinder);
    _recipeVisitor._typeEnvironment =
        environment.prune(typeParameterFinder.found);
    return GeneratedRecipe(
        type.accept(_recipeVisitor), _recipeVisitor._typeEnvironment);
  }

  String interfaceTypeRecipe(Class node) =>
      _recipeVisitor._interfaceTypeRecipe(node);
}

/// A visitor to generate type recipe strings from a [DartType].
///
/// The recipes are used by the 'dart:_rti' library while running the compiled
/// application.
class _TypeRecipeVisitor extends DartTypeVisitor<String> {
  /// The type environment to evaluate recipes in.
  ///
  /// Used to determine the indices for type variables.
  DDCTypeEnvironment _typeEnvironment;

  final CoreTypes _coreTypes;

  _TypeRecipeVisitor(this._typeEnvironment, this._coreTypes);

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
    // Generate the interface type recipe.
    var recipeBuffer = StringBuffer(_interfaceTypeRecipe(node.classNode));
    // Generate the recipes for all type arguments.
    if (node.typeArguments.isNotEmpty) {
      recipeBuffer.write(Recipe.startTypeArgumentsString);
      recipeBuffer.writeAll(
          node.typeArguments.map((typeArgument) => typeArgument.accept(this)),
          Recipe.separatorString);
      recipeBuffer.write(Recipe.endTypeArgumentsString);
    }
    // Add nullability.
    recipeBuffer.write(_nullabilityRecipe(node));
    return recipeBuffer.toString();
  }

  @override
  String visitFutureOrType(FutureOrType node) =>
      '${node.typeArgument.accept(this)}'
      '${Recipe.wrapFutureOrString}'
      '${_nullabilityRecipe(node)}';

  @override
  String visitFunctionType(FunctionType node) => defaultDartType(node);

  @override
  String visitTypeParameterType(TypeParameterType node) {
    var i = _typeEnvironment.recipeIndexOf(node.parameter);
    return '$i${_nullabilityRecipe(node)}';
  }

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
  String visitNullType(NullType node) =>
      _interfaceTypeRecipe(_coreTypes.deprecatedNullClass);

  @override
  String visitExtensionType(ExtensionType node) => defaultDartType(node);

  @override
  String visitIntersectionType(IntersectionType node) =>
      visitTypeParameterType(node.left);

  /// Returns the recipe for the interface type introduced by [cls].
  String _interfaceTypeRecipe(Class cls) {
    var path = p.withoutExtension(cls.enclosingLibrary.importUri.path);
    var library = pathToJSIdentifier(path);
    return '$library${Recipe.librarySeparatorString}${cls.name}';
  }

  /// Returns the recipe representation of [nullability].
  String _nullabilityRecipe(DartType type) {
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

/// Packages the type recipe and the environment needed to evaluate it at
/// runtime.
///
/// Returned from [TypeRecipeGenerator.recipeInEnvironment].
class GeneratedRecipe {
  /// A type recipe that can be used to evaluate a type at runtime in the
  /// [requiredEnvironment].
  ///
  /// For use with the dart:_rti library.
  final String recipe;

  /// The environment required to properly evaluate [recipe] within.
  ///
  /// This environment has been reduced down to be represented compactly with
  /// only the necessary type parameters.
  final DDCTypeEnvironment requiredEnvironment;

  GeneratedRecipe(this.recipe, this.requiredEnvironment);
}
