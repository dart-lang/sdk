// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.type_recipe;

import '../elements/entities.dart' show ClassEntity;
import '../elements/types.dart';
import '../diagnostics/invariant.dart';
import '../diagnostics/spannable.dart' show CURRENT_ELEMENT_SPANNABLE;
import '../serialization/serialization.dart';
import '../util/util.dart' show Hashing;

abstract class TypeRecipeDomain {
  /// Detect if a recipe evaluates to its input environment.
  ///
  /// Returns `true` if [recipe] evaluates in an environment with [structure] to
  /// the environment. This is typically a recipe that selects the entire input.
  bool isIdentity(TypeRecipe recipe, TypeEnvironmentStructure structure);

  /// Detect if a recipe evaluates to its input environment.
  ///
  /// Returns `true` if [recipe] evaluates in an environment with
  /// [environmentStructure] to the environment, where the environment is known
  /// to be an instance type of exactly the class [classEntity].
  ///
  /// This is a special case of [isIdentity] where we have additional
  /// information about the input environment that is not encoded in the
  /// environment structure.
  // TODO(sra): Consider extending TypeEnvironmentStructure to encode when the
  // classType is an exact type. Then the [classEntity] parameter would not be
  // needed.
  bool isReconstruction(ClassEntity classEntity,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe);

  /// Tries to evaluate [recipe] against a fixed environment [environmentRecipe]
  /// having structure [environmentStructure].
  ///
  /// May return `null` if the evaluation is too complex.
  TypeRecipe foldLoadEval(TypeRecipe environmentRecipe,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe);

  /// Partial constant folding of a type expression when the environment is
  /// created by binding a ground term.
  ///
  /// An 'original' environment is extended with [bindArgument] to produce an
  /// intermediate environment with structure [environmentStructure]. [recipe]
  /// is evaluated against this intermediate environment to produce a result.
  ///
  /// Returns the structure of the 'original' environment and a recipe that
  /// evaluates against that structure to produce the same result.
  ///
  /// [bindArgument] must be a ground term, i.e. have no type variables.
  TypeRecipeAndEnvironmentStructure foldBindLoadEval(
    TypeRecipe bindArgument,
    TypeEnvironmentStructure environmentStructure,
    TypeRecipe recipe,
  );

  /// Combines [recipe1] and [recipe2] into a single recipe that can be
  /// evaluated against [environmentStructure1]. ([recipe1] produces an
  /// intermediate type or environment value that conforms to the layout
  /// described by [environmentStructure2].)
  TypeRecipeAndEnvironmentStructure foldEvalEval(
    TypeEnvironmentStructure environmentStructure1,
    TypeRecipe recipe1,
    TypeEnvironmentStructure environmentStructure2,
    TypeRecipe recipe2,
  );
}

/// A type recipe and the structure of the type environment against which it is
/// evaluated.
class TypeRecipeAndEnvironmentStructure {
  final TypeRecipe recipe;
  final TypeEnvironmentStructure environmentStructure;

  TypeRecipeAndEnvironmentStructure(this.recipe, this.environmentStructure);
}

/// A TypeEnvironmentStructure describes the shape or layout of a reified type
/// environment.
///
/// A type environment maps type parameter variables to type values. The type
/// variables are mostly elided in the runtime representation, replaced by
/// indexes into the reified environment.
abstract class TypeEnvironmentStructure {
  /// Structural equality on [TypeEnvironmentStructure].
  static bool same(TypeEnvironmentStructure a, TypeEnvironmentStructure b) {
    if (a is SingletonTypeEnvironmentStructure) {
      if (b is SingletonTypeEnvironmentStructure) {
        return a.variable == b.variable;
      }
      return false;
    }
    return _sameFullStructure(a, b);
  }

  static bool _sameFullStructure(
      FullTypeEnvironmentStructure a, FullTypeEnvironmentStructure b) {
    if (a.classType != b.classType) return false;
    List<TypeVariableType> aBindings = a.bindings;
    List<TypeVariableType> bBindings = b.bindings;
    if (aBindings.length != bBindings.length) return false;
    for (int i = 0; i < aBindings.length; i++) {
      if (aBindings[i] != bBindings[i]) return false;
    }
    return true;
  }
}

/// A singleton type environment maps a binds a single value.
class SingletonTypeEnvironmentStructure extends TypeEnvironmentStructure {
  final TypeVariableType variable;

  SingletonTypeEnvironmentStructure(this.variable);

  @override
  String toString() => 'SingletonTypeEnvironmentStructure($variable)';
}

/// A type environment containing an interface type and/or a tuple of function
/// type parameters.
class FullTypeEnvironmentStructure extends TypeEnvironmentStructure {
  final InterfaceType classType;
  final List<TypeVariableType> bindings;

  FullTypeEnvironmentStructure({this.classType, this.bindings = const []});

  @override
  String toString() => 'FullTypeEnvironmentStructure($classType, $bindings)';
}

/// A TypeRecipe is evaluated against a type environment to produce either a
/// type, or another type environment.
abstract class TypeRecipe {
  /// Tag used for identifying serialized [TypeRecipe] objects in a debugging
  /// data stream.
  static const String tag = 'type-recipe';

  int /*?*/ _hashCode;

  TypeRecipe();

  @override
  int get hashCode => _hashCode ??= _computeHashCode();

  int _computeHashCode();

  factory TypeRecipe.readFromDataSource(DataSource source) {
    TypeRecipe recipe;
    source.begin(tag);
    _TypeRecipeKind kind = source.readEnum(_TypeRecipeKind.values);
    switch (kind) {
      case _TypeRecipeKind.expression:
        recipe = TypeExpressionRecipe._readFromDataSource(source);
        break;
      case _TypeRecipeKind.singletonEnvironment:
        recipe = SingletonTypeEnvironmentRecipe._readFromDataSource(source);
        break;
      case _TypeRecipeKind.fullEnvironment:
        recipe = FullTypeEnvironmentRecipe._readFromDataSource(source);
        break;
    }
    source.end(tag);
    return recipe;
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(_kind);
    _writeToDataSink(sink);
    sink.end(tag);
  }

  _TypeRecipeKind get _kind;
  void _writeToDataSink(DataSink sink);

  /// Returns `true` is [recipeB] evaluated in an environment described by
  /// [structureB] gives the same type as [recipeA] evaluated in environment
  /// described by [structureA].
  static bool yieldsSameType(
      TypeRecipe recipeA,
      TypeEnvironmentStructure structureA,
      TypeRecipe recipeB,
      TypeEnvironmentStructure structureB) {
    if (recipeA == recipeB &&
        TypeEnvironmentStructure.same(structureA, structureB)) {
      return true;
    }

    // TODO(sra): Type recipes that are different but equal modulo naming also
    // yield the same type, e.g. `List<X> @X` and `List<Y> @Y`.
    return false;
  }
}

enum _TypeRecipeKind { expression, singletonEnvironment, fullEnvironment }

/// A recipe that yields a reified type.
class TypeExpressionRecipe extends TypeRecipe {
  final DartType type;

  TypeExpressionRecipe(this.type);

  static TypeExpressionRecipe _readFromDataSource(DataSource source) {
    return TypeExpressionRecipe(source.readDartType());
  }

  @override
  _TypeRecipeKind get _kind => _TypeRecipeKind.expression;

  @override
  void _writeToDataSink(DataSink sink) {
    sink.writeDartType(type);
  }

  @override
  int _computeHashCode() => type.hashCode * 7;

  @override
  bool operator ==(other) {
    return other is TypeExpressionRecipe && type == other.type;
  }

  @override
  String toString() => 'TypeExpressionRecipe($type)';
}

/// A recipe that yields a reified type environment.
abstract class TypeEnvironmentRecipe extends TypeRecipe {}

/// A recipe that yields a reified type environment that binds a single generic
/// function type parameter.
class SingletonTypeEnvironmentRecipe extends TypeEnvironmentRecipe {
  final DartType type;

  SingletonTypeEnvironmentRecipe(this.type);

  static SingletonTypeEnvironmentRecipe _readFromDataSource(DataSource source) {
    return SingletonTypeEnvironmentRecipe(source.readDartType());
  }

  @override
  _TypeRecipeKind get _kind => _TypeRecipeKind.singletonEnvironment;

  @override
  void _writeToDataSink(DataSink sink) {
    sink.writeDartType(type);
  }

  @override
  int _computeHashCode() => type.hashCode * 11;

  @override
  bool operator ==(other) {
    return other is SingletonTypeEnvironmentRecipe && type == other.type;
  }

  @override
  String toString() => 'SingletonTypeEnvironmentRecipe($type)';
}

/// A recipe that yields a reified type environment that binds a class instance
/// type and/or a tuple of types, usually generic function type arguments.
///
/// With no class is also used as a tuple of types.
class FullTypeEnvironmentRecipe extends TypeEnvironmentRecipe {
  /// Type expression for the interface type of a class scope.  `null` for
  /// environments outside a class scope or a class scope where no supertype is
  /// generic, or where optimization has determined that no use of the
  /// environment requires any of the class type variables.
  final InterfaceType classType;

  // Type expressions for the tuple of function type arguments.
  final List<DartType> types;

  FullTypeEnvironmentRecipe({this.classType, this.types = const []});

  static FullTypeEnvironmentRecipe _readFromDataSource(DataSource source) {
    InterfaceType classType =
        source.readDartType(allowNull: true) as InterfaceType;
    List<DartType> types = source.readDartTypes(emptyAsNull: true) ?? const [];
    return FullTypeEnvironmentRecipe(classType: classType, types: types);
  }

  @override
  _TypeRecipeKind get _kind => _TypeRecipeKind.fullEnvironment;

  @override
  void _writeToDataSink(DataSink sink) {
    sink.writeDartType(classType, allowNull: true);
    sink.writeDartTypes(types, allowNull: false);
  }

  @override
  int _computeHashCode() {
    return Hashing.listHash(types, Hashing.objectHash(classType, 0));
  }

  @override
  bool operator ==(other) {
    return other is FullTypeEnvironmentRecipe && _equal(this, other);
  }

  static bool _equal(FullTypeEnvironmentRecipe a, FullTypeEnvironmentRecipe b) {
    if (a.classType != b.classType) return false;
    List<DartType> aTypes = a.types;
    List<DartType> bTypes = b.types;
    if (aTypes.length != bTypes.length) return false;
    for (int i = 0; i < aTypes.length; i++) {
      if (aTypes[i] != bTypes[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'FullTypeEnvironmentRecipe($classType, $types)';
}

class TypeRecipeDomainImpl implements TypeRecipeDomain {
  final DartTypes _dartTypes;

  const TypeRecipeDomainImpl(this._dartTypes);

  @override
  bool isIdentity(TypeRecipe recipe, TypeEnvironmentStructure structure) {
    if (structure is SingletonTypeEnvironmentStructure &&
        recipe is TypeExpressionRecipe) {
      if (structure.variable == recipe.type) return true;
    }
    return false;
  }

  @override
  bool isReconstruction(ClassEntity classEntity,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe) {
    if (environmentStructure is FullTypeEnvironmentStructure &&
        environmentStructure.bindings.isEmpty) {
      InterfaceType classType = environmentStructure.classType;
      if (classType.element == classEntity) {
        if (recipe is TypeExpressionRecipe && recipe.type == classType) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  TypeRecipe foldLoadEval(TypeRecipe environmentRecipe,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe) {
    if (environmentStructure is SingletonTypeEnvironmentStructure) {
      if (environmentRecipe is TypeExpressionRecipe) {
        List<TypeVariableType> variables = [environmentStructure.variable];
        List<DartType> replacements = [environmentRecipe.type];
        return _Substitution(_dartTypes, null, null, variables, replacements)
            .substituteRecipe(recipe);
      }
      failedAt(CURRENT_ELEMENT_SPANNABLE,
          'Expected a TypeExpressionRecipe: $environmentRecipe');
      return null;
    }

    if (environmentStructure is FullTypeEnvironmentStructure) {
      if (environmentStructure.classType != null) {
        if (environmentRecipe is TypeExpressionRecipe) {
          assert(environmentStructure.bindings.isEmpty);
          return _Substitution(_dartTypes, environmentStructure.classType,
                  environmentRecipe.type, null, null)
              .substituteRecipe(recipe);
        }
        return null;
      }
      if (environmentRecipe is TypeExpressionRecipe) {
        // Is this possible?
        return null;
      }
      if (environmentRecipe is FullTypeEnvironmentRecipe) {
        return _Substitution(
                _dartTypes,
                environmentStructure.classType,
                environmentRecipe.classType,
                environmentStructure.bindings,
                environmentRecipe.types)
            .substituteRecipe(recipe);
      }
      return null;
    }

    failedAt(CURRENT_ELEMENT_SPANNABLE,
        'Unknown environmentStructure: $environmentStructure');
    return null;
  }

  @override
  TypeRecipeAndEnvironmentStructure foldBindLoadEval(TypeRecipe bindArgument,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe) {
    // 'Bind' adds variables to the environment. We fold 'bind' of a ground type
    // by removing the added variables and replacing them in the recipe with the
    // constant type values.

    if (environmentStructure is FullTypeEnvironmentStructure) {
      List<DartType> replacements;
      if (bindArgument is TypeExpressionRecipe) {
        // Bind call adds a single binding.
        replacements = [bindArgument.type];
      } else if (bindArgument is FullTypeEnvironmentRecipe) {
        replacements = bindArgument.types;
      } else {
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            'Unexpected bindArgument: $bindArgument');
      }
      List<TypeVariableType> bindings = environmentStructure.bindings;
      int index = bindings.length - replacements.length;
      List<TypeVariableType> replacedVariables = bindings.sublist(index);
      List<TypeVariableType> remainingVariables = bindings.sublist(0, index);
      TypeRecipe newRecipe =
          _Substitution(_dartTypes, null, null, replacedVariables, replacements)
              .substituteRecipe(recipe);
      if (newRecipe == null) return null;
      TypeEnvironmentStructure newEnvironmentStructure =
          FullTypeEnvironmentStructure(
              classType: environmentStructure.classType,
              bindings: remainingVariables);
      return TypeRecipeAndEnvironmentStructure(
          newRecipe, newEnvironmentStructure);
    }

    failedAt(CURRENT_ELEMENT_SPANNABLE,
        'unexpected bind on environment with structure $environmentStructure');
    return null;
  }

  @override
  TypeRecipeAndEnvironmentStructure foldEvalEval(
      TypeEnvironmentStructure environmentStructure1,
      TypeRecipe recipe1,
      TypeEnvironmentStructure environmentStructure2,
      TypeRecipe recipe2) {
    if (environmentStructure2 is SingletonTypeEnvironmentStructure &&
        recipe1 is TypeExpressionRecipe) {
      TypeRecipe newRecipe = _Substitution(
          _dartTypes,
          null,
          null,
          [environmentStructure2.variable],
          [recipe1.type]).substituteRecipe(recipe2);
      if (newRecipe == null) return null;
      return TypeRecipeAndEnvironmentStructure(
          newRecipe, environmentStructure1);
    }

    if (environmentStructure2 is FullTypeEnvironmentStructure &&
        recipe1 is TypeExpressionRecipe) {
      assert(environmentStructure2.bindings.isEmpty);
      TypeRecipe newRecipe = _Substitution(_dartTypes,
              environmentStructure2.classType, recipe1.type, null, null)
          .substituteRecipe(recipe2);
      if (newRecipe == null) return null;
      return TypeRecipeAndEnvironmentStructure(
          newRecipe, environmentStructure1);
    }

    if (environmentStructure2 is FullTypeEnvironmentStructure &&
        recipe1 is FullTypeEnvironmentRecipe) {
      TypeRecipe newRecipe = _Substitution(
              _dartTypes,
              environmentStructure2.classType,
              recipe1.classType,
              environmentStructure2.bindings,
              recipe1.types)
          .substituteRecipe(recipe2);
      if (newRecipe == null) return null;
      return TypeRecipeAndEnvironmentStructure(
          newRecipe, environmentStructure1);
    }

    return null;
  }
}

/// Substitution algorithm for transforming a TypeRecipe by substitution of
/// bindings of a type environment.
///
/// Since the general case of a type environment has class type variables (bound
/// by a class instance type) and method type variable bindings, both are
/// provided. The class type variables can be implicit (e.g. CodeUnits defines
/// ListMixin.E), whereas the method type variables are always bound explicitly.
///
/// A [_Substitution] contains the bindings and the state required to perform
/// a single substitution.
class _Substitution extends DartTypeSubstitutionVisitor<Null> {
  @override
  final DartTypes dartTypes;
  final Map<DartType, DartType> _lookupCache = {};
  final Map<DartType, int> _counts = {};
  bool _failed = false;

  final InterfaceType _classEnvironment;
  final InterfaceType _classValue;
  final List<TypeVariableType> _variables;
  final List<DartType> _replacements;

  _Substitution(this.dartTypes, this._classEnvironment, this._classValue,
      this._variables, this._replacements)
      : assert(_variables?.length == _replacements?.length);

  // Returns `null` if declined.
  TypeRecipe substituteRecipe(TypeRecipe recipe) {
    if (recipe is TypeExpressionRecipe) {
      DartType result = _substituteType(recipe.type);
      if (_failed) return null;
      return TypeExpressionRecipe(result);
    }
    if (recipe is FullTypeEnvironmentRecipe) {
      DartType newClass = _substitutePossiblyNullType(recipe.classType);
      List<DartType> newTypes = recipe.types.map(_substituteType).toList();
      if (_failed) return null;
      return FullTypeEnvironmentRecipe(classType: newClass, types: newTypes);
    }

    failedAt(CURRENT_ELEMENT_SPANNABLE, 'Unexpected recipe: $recipe');
    return null;
  }

  DartType _substituteType(DartType type) => visit(type, null);

  DartType _substitutePossiblyNullType(DartType type) =>
      type == null ? null : visit(type, null);

  // Returns `null` if not bound.
  DartType _lookupTypeVariableType(TypeVariableType type) {
    if (_variables != null) {
      int index = _variables.indexOf(type);
      if (index >= 0) return _replacements[index];
    }
    if (_classEnvironment == null) return null;

    if (_classEnvironment.element == _classValue.element) {
      int index = _classEnvironment.typeArguments.indexOf(type);
      if (index >= 0) return _classValue.typeArguments[index];
      return null;
    }
    // TODO(sra): Lookup type variable of supertype (e.g. ListMixin.E of
    // CodeUnits).
    _failed = true;
    return null;
  }

  @override
  DartType substituteTypeVariableType(
      TypeVariableType variable, Null argument, bool freshReference) {
    DartType replacement =
        _lookupCache[variable] ??= _lookupTypeVariableType(variable);
    if (replacement == null) return variable; // not substituted.
    if (!freshReference) return replacement;
    int count = _counts[variable] = (_counts[variable] ?? 0) + 1;
    if (count > 1) {
      // If the replacement is 'big', duplicating it can grow the term, perhaps
      // exponentially given a sufficently pathological input.
      // TODO(sra): Fix exponential terms by encoding a DAG in recipes to avoid
      // linearization.
      if (replacement is FunctionType ||
          replacement is InterfaceType &&
              replacement.typeArguments.isNotEmpty ||
          replacement is FutureOrType) {
        _failed = true;
      }
    }
    return replacement;
  }
}
