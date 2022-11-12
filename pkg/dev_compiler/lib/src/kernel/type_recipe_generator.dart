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
  var _unboundTypeParameters = <String>[];

  final CoreTypes _coreTypes;

  _TypeRecipeVisitor(this._typeEnvironment, this._coreTypes);

  @override
  String defaultDartType(DartType node) {
    throw UnimplementedError('Unknown DartType: $node');
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
  String visitFunctionType(FunctionType node) {
    var savedUnboundTypeParameters = _unboundTypeParameters;
    // Collect the type parameters introduced by this function type because they
    // might be used later in its definition.
    //
    // For example, the function type `T Function<T, S>(S)` introduces new type
    // parameter types and uses them in the parameter and return types.
    _unboundTypeParameters = [
      for (var parameter in node.typeParameters) parameter.name!,
      ..._unboundTypeParameters
    ];
    // Generate the return type recipe.
    var recipeBuffer = StringBuffer(node.returnType.accept(this));
    // Generate the method parameter recipes.
    recipeBuffer.write(Recipe.startFunctionArgumentsString);
    // Required positional parameters.
    var requiredParameterCount = node.requiredParameterCount;
    var positionalParameters = node.positionalParameters;
    for (var i = 0; i < requiredParameterCount; i++) {
      recipeBuffer.write(positionalParameters[i].accept(this));
      if (i < requiredParameterCount - 1) {
        recipeBuffer.write(Recipe.separatorString);
      }
    }
    var positionalCount = positionalParameters.length;
    // Optional positional parameters.
    if (positionalCount > requiredParameterCount) {
      recipeBuffer.write(Recipe.startOptionalGroupString);
      for (var i = requiredParameterCount; i < positionalCount; i++) {
        recipeBuffer.write(positionalParameters[i].accept(this));
        if (i < positionalCount - 1) {
          recipeBuffer.write(Recipe.separatorString);
        }
      }
      recipeBuffer.write(Recipe.endOptionalGroupString);
    }
    // Named parameters.
    var namedParameters = node.namedParameters;
    var namedCount = namedParameters.length;
    if (namedParameters.isNotEmpty) {
      recipeBuffer.write(Recipe.startNamedGroupString);
      for (var i = 0; i < namedCount; i++) {
        var named = namedParameters[i];
        recipeBuffer.write(named.name);
        recipeBuffer.write(named.isRequired
            ? Recipe.requiredNameSeparatorString
            : Recipe.nameSeparatorString);
        recipeBuffer.write(named.type.accept(this));
        if (i < namedCount - 1) {
          recipeBuffer.write(Recipe.separatorString);
        }
      }
      recipeBuffer.write(Recipe.endNamedGroupString);
    }
    recipeBuffer.write(Recipe.endFunctionArgumentsString);
    // Generate type parameter recipes.
    var typeParameters = node.typeParameters;
    if (typeParameters.isNotEmpty) {
      recipeBuffer.write(Recipe.startTypeArgumentsString);
      recipeBuffer.writeAll(
          typeParameters.map((parameter) => parameter.bound.accept(this)),
          Recipe.separatorString);
      recipeBuffer.write(Recipe.endTypeArgumentsString);
    }
    _unboundTypeParameters = savedUnboundTypeParameters;
    // Add the function type nullability.
    recipeBuffer.write(_nullabilityRecipe(node));
    return recipeBuffer.toString();
  }

  @override
  String visitTypeParameterType(TypeParameterType node) {
    var i = _unboundTypeParameters.indexOf(node.parameter.name!);
    if (i >= 0) {
      return '$i'
          '${Recipe.genericFunctionTypeParameterIndexString}'
          '${_nullabilityRecipe(node)}';
    }
    i = _typeEnvironment.recipeIndexOf(node.parameter);
    if (i < 0) {
      throw UnsupportedError(
          'Type parameter $node was not found in the environment '
          '$_typeEnvironment or in the unbound parameters '
          '$_unboundTypeParameters.');
    }
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
