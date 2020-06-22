// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.runtime_types_new;

import 'package:js_runtime/shared/recipe_syntax.dart';

import '../common_elements.dart' show CommonElements, JCommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_model/type_recipe.dart';
import '../js_emitter/js_emitter.dart' show ModularEmitter;
import '../universe/class_hierarchy.dart';
import '../world.dart';
import 'namer.dart';
import 'native_data.dart';
import 'runtime_types_codegen.dart' show RuntimeTypesSubstitutions;

class RecipeEncoding {
  final jsAst.Literal recipe;
  final Set<TypeVariableType> typeVariables;

  const RecipeEncoding(this.recipe, this.typeVariables);
}

abstract class RecipeEncoder {
  /// Returns a [RecipeEncoding] representing the given [recipe] to be
  /// evaluated against a type environment with shape [structure].
  RecipeEncoding encodeRecipe(ModularEmitter emitter,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe);

  jsAst.Literal encodeGroundRecipe(ModularEmitter emitter, TypeRecipe recipe);

  /// Returns a [jsAst.Literal] representing [supertypeArgument] to be evaluated
  /// against a [FullTypeEnvironmentStructure] representing [declaringType]. Any
  /// [TypeVariableType]s appearing in [supertypeArgument] which are declared by
  /// [declaringType] are always encoded as indices and type variables are
  /// assumed to never be erased.
  jsAst.Literal encodeMetadataRecipe(ModularEmitter emitter,
      InterfaceType declaringType, DartType supertypeArgument);
}

class RecipeEncoderImpl implements RecipeEncoder {
  final JClosedWorld _closedWorld;
  final RuntimeTypesSubstitutions _rtiSubstitutions;
  final NativeBasicData _nativeData;
  final JCommonElements commonElements;

  RecipeEncoderImpl(this._closedWorld, this._rtiSubstitutions, this._nativeData,
      this.commonElements);

  @override
  RecipeEncoding encodeRecipe(ModularEmitter emitter,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe) {
    return _RecipeGenerator(this, emitter, environmentStructure, recipe).run();
  }

  @override
  jsAst.Literal encodeGroundRecipe(ModularEmitter emitter, TypeRecipe recipe) {
    return _RecipeGenerator(this, emitter, null, recipe).run().recipe;
  }

  @override
  jsAst.Literal encodeMetadataRecipe(ModularEmitter emitter,
      InterfaceType declaringType, DartType supertypeArgument) {
    return _RecipeGenerator(
            this,
            emitter,
            FullTypeEnvironmentStructure(classType: declaringType),
            TypeExpressionRecipe(supertypeArgument),
            metadata: true)
        .run()
        .recipe;
  }
}

class _RecipeGenerator implements DartTypeVisitor<void, void> {
  final RecipeEncoderImpl _encoder;
  final ModularEmitter _emitter;
  final TypeEnvironmentStructure _environment;
  final TypeRecipe _recipe;
  final bool metadata;

  final List<FunctionTypeVariable> functionTypeVariables = [];
  final Set<TypeVariableType> typeVariables = {};

  // Accumulated recipe.
  final List<jsAst.Literal> _fragments = [];
  final List<int> _codes = [];

  _RecipeGenerator(
      this._encoder, this._emitter, this._environment, this._recipe,
      {this.metadata = false});

  JClosedWorld get _closedWorld => _encoder._closedWorld;
  NativeBasicData get _nativeData => _encoder._nativeData;
  RuntimeTypesSubstitutions get _rtiSubstitutions => _encoder._rtiSubstitutions;

  RecipeEncoding _finishEncoding(jsAst.Literal literal) =>
      RecipeEncoding(literal, typeVariables);

  RecipeEncoding run() {
    _start(_recipe);
    assert(functionTypeVariables.isEmpty);
    if (_fragments.isEmpty) {
      return _finishEncoding(js.string(String.fromCharCodes(_codes)));
    }
    _flushCodes();
    jsAst.LiteralString quote = jsAst.LiteralString('"');
    return _finishEncoding(
        jsAst.StringConcatenation([quote, ..._fragments, quote]));
  }

  void _start(TypeRecipe recipe) {
    if (recipe is TypeExpressionRecipe) {
      visit(recipe.type, null);
    } else if (recipe is SingletonTypeEnvironmentRecipe) {
      visit(recipe.type, null);
    } else if (recipe is FullTypeEnvironmentRecipe) {
      _startFullTypeEnvironmentRecipe(recipe, null);
    }
  }

  void _startFullTypeEnvironmentRecipe(FullTypeEnvironmentRecipe recipe, _) {
    if (recipe.classType == null) {
      _emitCode(Recipe.pushDynamic);
      assert(recipe.types.isNotEmpty);
    } else {
      visit(recipe.classType, null);
      // TODO(sra): The separator can be omitted when the parser will have
      // reduced to the top of stack to an Rti value.
      _emitCode(Recipe.toType);
    }

    if (recipe.types.isNotEmpty) {
      _emitCode(Recipe.startTypeArguments);
      bool first = true;
      for (DartType type in recipe.types) {
        if (!first) {
          _emitCode(Recipe.separator);
        }
        visit(type, _);
        first = false;
      }
      _emitCode(Recipe.endTypeArguments);
    }
  }

  void _emitCode(int code) {
    // TODO(sra): We should permit codes with short escapes (like '\n') for
    // infrequent operators.
    assert(code >= 0x20 && code <= 0x7E && code != 0x22);
    _codes.add(code);
  }

  void _flushCodes() {
    if (_codes.isEmpty) return;
    // TODO(sra): codes need some escaping.
    _fragments.add(StringBackedName(String.fromCharCodes(_codes)));
    _codes.clear();
  }

  void _emitInteger(int value) {
    if (_codes.isEmpty ? _fragments.isNotEmpty : Recipe.isDigit(_codes.last)) {
      _emitCode(Recipe.separator);
    }
    _emitStringUnescaped('$value');
  }

  void _emitStringUnescaped(String string) {
    for (int code in string.codeUnits) {
      _emitCode(code);
    }
  }

  void _emitName(jsAst.Name name) {
    if (_fragments.isNotEmpty && _codes.isEmpty) {
      _emitCode(Recipe.separator);
    }
    _flushCodes();
    _fragments.add(name);
  }

  void _emitExtensionOp(int value) {
    _emitInteger(value);
    _emitCode(Recipe.extensionOp);
  }

  @override
  void visit(DartType type, _) => type.accept(this, _);

  @override
  void visitLegacyType(LegacyType type, _) {
    visit(type.baseType, _);
    _emitCode(Recipe.wrapStar);
  }

  @override
  void visitNullableType(NullableType type, _) {
    visit(type.baseType, _);
    _emitCode(Recipe.wrapQuestion);
  }

  @override
  void visitNeverType(NeverType type, _) {
    _emitExtensionOp(Recipe.pushNeverExtension);
  }

  @override
  void visitTypeVariableType(TypeVariableType type, _) {
    TypeEnvironmentStructure environment = _environment;
    if (environment is SingletonTypeEnvironmentStructure) {
      if (type == environment.variable) {
        _emitInteger(0);
        return;
      }
    }
    if (environment is FullTypeEnvironmentStructure) {
      int index = indexTypeVariable(
          _closedWorld, _rtiSubstitutions, environment, type,
          metadata: metadata);
      if (index != null) {
        _emitInteger(index);
        return;
      }

      jsAst.Name name = _emitter.typeVariableAccessNewRti(type.element);
      _emitName(name);
      typeVariables.add(type);
      return;
    }
    // TODO(sra): Handle missing cases. This just emits some readable junk. The
    // backticks ensure it won't parse at runtime.
    '`$type`'.codeUnits.forEach(_emitCode);
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, _) {
    int position = functionTypeVariables.indexOf(type);
    assert(position >= 0);
    // See [visitFunctionType] for explanation.
    _emitInteger(functionTypeVariables.length - position - 1);
    _emitCode(Recipe.genericFunctionTypeParameterIndex);
  }

  @override
  void visitDynamicType(DynamicType type, _) {
    _emitCode(Recipe.pushDynamic);
  }

  @override
  void visitErasedType(ErasedType type, _) {
    _emitCode(Recipe.pushErased);
  }

  @override
  void visitAnyType(AnyType type, _) {
    _emitExtensionOp(Recipe.pushAnyExtension);
  }

  @override
  void visitInterfaceType(InterfaceType type, _) {
    jsAst.Name name = _emitter.typeAccessNewRti(type.element);
    if (type.typeArguments.isEmpty) {
      // Push the name, which is later converted by an implicit toType
      // operation.
      _emitName(name);
    } else {
      _emitName(name);
      _emitCode(Recipe.startTypeArguments);
      bool first = true;
      for (DartType argumentType in type.typeArguments) {
        if (!first) {
          _emitCode(Recipe.separator);
        }
        if (_nativeData.isJsInteropClass(type.element)) {
          // Emit 'any' type.
          _emitExtensionOp(Recipe.pushAnyExtension);
        } else {
          visit(argumentType, _);
        }
        first = false;
      }
      _emitCode(Recipe.endTypeArguments);
    }
  }

  @override
  void visitFunctionType(FunctionType type, _) {
    if (type.typeVariables.isNotEmpty) {
      // Enter generic function scope.
      //
      // Function type variables are encoded as a modified de Bruin index. We
      // count variables from the current scope outwards, counting the variables
      // in the same scope left-to-right.
      //
      // If we push the current scope's variables in reverse, then the index is
      // the position measured from the end.
      //
      //    foo<AA,BB>() => ...
      //      //^0 ^1
      //    functionTypeVariables: [BB,AA]
      //
      //    foo<AA,BB>() => <UU,VV,WW>() => ...
      //        ^3 ^4        ^0 ^1 ^2
      //    functionTypeVariables: [BB,AA,WW,VV,UU]
      //
      for (FunctionTypeVariable variable in type.typeVariables.reversed) {
        functionTypeVariables.add(variable);
      }
    }

    visit(type.returnType, _);
    _emitCode(Recipe.startFunctionArguments);

    bool first = true;
    for (DartType parameterType in type.parameterTypes) {
      if (!first) {
        _emitCode(Recipe.separator);
      }
      visit(parameterType, _);
      first = false;
    }

    if (type.optionalParameterTypes.isNotEmpty) {
      first = true;
      _emitCode(Recipe.startOptionalGroup);
      for (DartType parameterType in type.optionalParameterTypes) {
        if (!first) {
          _emitCode(Recipe.separator);
        }
        visit(parameterType, _);
        first = false;
      }
      _emitCode(Recipe.endOptionalGroup);
    }

    void emitNamedGroup(
        List<String> names, Set<String> requiredNames, List<DartType> types) {
      assert(names.length == types.length);
      first = true;
      _emitCode(Recipe.startNamedGroup);
      for (int i = 0; i < names.length; i++) {
        if (!first) {
          _emitCode(Recipe.separator);
        }
        _emitStringUnescaped(names[i]);
        _emitCode(requiredNames.contains(names[i])
            ? Recipe.requiredNameSeparator
            : Recipe.nameSeparator);
        visit(types[i], _);
        first = false;
      }
      _emitCode(Recipe.endNamedGroup);
    }

    if (type.namedParameterTypes.isNotEmpty) {
      emitNamedGroup(type.namedParameters, type.requiredNamedParameters,
          type.namedParameterTypes);
    }

    _emitCode(Recipe.endFunctionArguments);

    // Emit generic type bounds.
    if (type.typeVariables.isNotEmpty) {
      bool first = true;
      _emitCode(Recipe.startTypeArguments);
      for (FunctionTypeVariable typeVariable in type.typeVariables) {
        if (!first) {
          _emitCode(Recipe.separator);
        }
        visit(typeVariable.bound, _);
      }
      _emitCode(Recipe.endTypeArguments);
    }

    if (type.typeVariables.isNotEmpty) {
      // Exit generic function scope. Remove the type variables pushed at entry.
      functionTypeVariables.length -= type.typeVariables.length;
    }
  }

  @override
  void visitVoidType(VoidType type, _) {
    _emitCode(Recipe.pushVoid);
  }

  @override
  void visitFutureOrType(FutureOrType type, _) {
    visit(type.typeArgument, _);
    _emitCode(Recipe.wrapFutureOr);
  }
}

bool mustCheckAllSubtypes(JClosedWorld world, ClassEntity cls) =>
    world.isUsedAsMixin(cls) ||
    world.extractTypeArgumentsInterfacesNewRti.contains(cls);

int indexTypeVariable(
    JClosedWorld world,
    RuntimeTypesSubstitutions rtiSubstitutions,
    FullTypeEnvironmentStructure environment,
    TypeVariableType type,
    {bool metadata = false}) {
  int i = environment.bindings.indexOf(type);
  if (i >= 0) {
    // Indices are 1-based since '0' encodes using the entire type for the
    // singleton structure.
    return i + 1;
  }

  TypeVariableEntity element = type.element;
  ClassEntity cls = element.typeDeclaration;

  if (metadata) {
    if (identical(environment.classType.element, cls)) {
      // Indexed class type variables come after the bound function type
      // variables.
      return 1 + environment.bindings.length + element.index;
    }
  }

  // TODO(sra): We might be in a context where the class type variable has an
  // index, even though in the general case it is not at a specific index.

  ClassHierarchy classHierarchy = world.classHierarchy;
  var test = mustCheckAllSubtypes(world, cls)
      ? classHierarchy.anyStrictSubtypeOf
      : classHierarchy.anyStrictSubclassOf;
  if (test(cls, (ClassEntity subclass) {
    return !rtiSubstitutions.isTrivialSubstitution(subclass, cls);
  })) {
    return null;
  }

  // Indexed class type variables come after the bound function type
  // variables.
  return 1 + environment.bindings.length + element.index;
}

class _RulesetEntry {
  Set<InterfaceType> _supertypes = {};
  Map<TypeVariableType, DartType> _typeVariables = {};

  bool get isEmpty => _supertypes.isEmpty && _typeVariables.isEmpty;
  bool get isNotEmpty => _supertypes.isNotEmpty || _typeVariables.isNotEmpty;

  void addAll(Iterable<InterfaceType> supertypes,
      Map<TypeVariableType, DartType> typeVariables) {
    _supertypes.addAll(supertypes);
    _typeVariables.addAll(typeVariables);
  }
}

class Ruleset {
  Map<ClassEntity, ClassEntity> _redirections;
  Map<InterfaceType, _RulesetEntry> _entries;

  Ruleset(this._redirections, this._entries);
  Ruleset.empty() : this({}, {});

  bool get isEmpty => _redirections.isEmpty && _entries.isEmpty;
  bool get isNotEmpty => _redirections.isNotEmpty || _entries.isNotEmpty;

  void addRedirection(ClassEntity redirectee, ClassEntity target) {
    _redirections[redirectee] = target;
  }

  void addEntry(InterfaceType targetType, Iterable<InterfaceType> supertypes,
      Map<TypeVariableType, DartType> typeVariables) {
    _RulesetEntry entry = _entries[targetType] ??= _RulesetEntry();
    entry.addAll(supertypes, typeVariables);
  }
}

class RulesetEncoder {
  final DartTypes _dartTypes;
  final ModularEmitter _emitter;
  final RecipeEncoder _recipeEncoder;

  RulesetEncoder(this._dartTypes, this._emitter, this._recipeEncoder);

  CommonElements get _commonElements => _dartTypes.commonElements;
  ClassEntity get _objectClass => _commonElements.objectClass;

  final _leftBrace = js.stringPart('{');
  final _rightBrace = js.stringPart('}');
  final _leftBracket = js.stringPart('[');
  final _rightBracket = js.stringPart(']');
  final _colon = js.stringPart(':');
  final _comma = js.stringPart(',');
  final _quote = js.stringPart("'");

  bool _isObject(InterfaceType type) => identical(type.element, _objectClass);

  bool _isSyntheticClosure(InterfaceType type) => type.element.isClosure;

  void _preprocessEntry(InterfaceType targetType, _RulesetEntry entry) {
    entry._supertypes.removeWhere((InterfaceType supertype) =>
        _isObject(supertype) ||
        identical(targetType.element, supertype.element));
  }

  void _preprocessRuleset(Ruleset ruleset) {
    ruleset._entries.removeWhere((InterfaceType targetType, _) =>
        _isObject(targetType) || _isSyntheticClosure(targetType));
    ruleset._entries.forEach(_preprocessEntry);
    ruleset._entries.removeWhere((_, _RulesetEntry entry) => entry.isEmpty);
  }

  // TODO(fishythefish): Common substring elimination.

  /// Produces a string readable by `JSON.parse()`.
  jsAst.StringConcatenation encodeRuleset(Ruleset ruleset) {
    _preprocessRuleset(ruleset);
    return _encodeRuleset(ruleset);
  }

  jsAst.StringConcatenation _encodeRuleset(Ruleset ruleset) =>
      js.concatenateStrings([
        _quote,
        _leftBrace,
        ...js.joinLiterals([
          ...ruleset._redirections.entries.map(_encodeRedirection),
          ...ruleset._entries.entries.map(_encodeEntry),
        ], _comma),
        _rightBrace,
        _quote,
      ]);

  jsAst.StringConcatenation _encodeRedirection(
          MapEntry<ClassEntity, ClassEntity> redirection) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeAccessNewRti(redirection.key)),
        _colon,
        js.quoteName(_emitter.typeAccessNewRti(redirection.value)),
      ]);

  jsAst.StringConcatenation _encodeEntry(
          MapEntry<InterfaceType, _RulesetEntry> entry) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeAccessNewRti(entry.key.element)),
        _colon,
        _leftBrace,
        ...js.joinLiterals([
          ...entry.value._supertypes.map((InterfaceType supertype) =>
              _encodeSupertype(entry.key, supertype)),
          ...entry.value._typeVariables.entries.map((mapEntry) =>
              _encodeTypeVariable(entry.key, mapEntry.key, mapEntry.value))
        ], _comma),
        _rightBrace,
      ]);

  jsAst.StringConcatenation _encodeSupertype(
          InterfaceType targetType, InterfaceType supertype) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeAccessNewRti(supertype.element)),
        _colon,
        _leftBracket,
        ...js.joinLiterals(
            supertype.typeArguments.map((DartType supertypeArgument) =>
                _encodeSupertypeArgument(targetType, supertypeArgument)),
            _comma),
        _rightBracket,
      ]);

  jsAst.StringConcatenation _encodeTypeVariable(InterfaceType targetType,
          TypeVariableType typeVariable, DartType supertypeArgument) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeVariableAccessNewRti(typeVariable.element)),
        _colon,
        _encodeSupertypeArgument(targetType, supertypeArgument),
      ]);

  jsAst.Literal _encodeSupertypeArgument(
          InterfaceType targetType, DartType supertypeArgument) =>
      _recipeEncoder.encodeMetadataRecipe(
          _emitter, targetType, supertypeArgument);

  jsAst.StringConcatenation encodeErasedTypes(
          Map<ClassEntity, int> erasedTypes) =>
      js.concatenateStrings([
        _quote,
        _leftBrace,
        ...js.joinLiterals(erasedTypes.entries.map(encodeErasedType), _comma),
        _rightBrace,
        _quote,
      ]);

  jsAst.StringConcatenation encodeErasedType(
          MapEntry<ClassEntity, int> entry) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeAccessNewRti(entry.key)),
        _colon,
        js.number(entry.value),
      ]);

  jsAst.StringConcatenation encodeTypeParameterVariances(
          Map<ClassEntity, List<Variance>> typeParameterVariances) =>
      js.concatenateStrings([
        _quote,
        _leftBrace,
        ...js.joinLiterals(
            typeParameterVariances.entries
                .map(_encodeTypeParameterVariancesForClass),
            _comma),
        _rightBrace,
        _quote,
      ]);

  jsAst.StringConcatenation _encodeTypeParameterVariancesForClass(
          MapEntry<ClassEntity, List<Variance>> classEntry) =>
      js.concatenateStrings([
        js.quoteName(_emitter.typeAccessNewRti(classEntry.key)),
        _colon,
        _leftBracket,
        ...js.joinLiterals(
            classEntry.value.map((v) => js.number(v.index)), _comma),
        _rightBracket
      ]);
}
