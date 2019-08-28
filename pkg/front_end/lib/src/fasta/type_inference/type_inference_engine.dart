// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        Constructor,
        DartType,
        DartTypeVisitor,
        DynamicType,
        Field,
        FunctionType,
        InterfaceType,
        Member,
        NamedType,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../../base/instrumentation.dart' show Instrumentation;

import '../kernel/kernel_builder.dart'
    show ClassHierarchyBuilder, ImplicitFieldType, LibraryBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'type_inferrer.dart' show TypeInferrer;

import 'type_schema_environment.dart' show TypeSchemaEnvironment;

enum Variance {
  covariant,
  contravariant,
  invariant,
}

Variance invertVariance(Variance variance) {
  switch (variance) {
    case Variance.covariant:
      return Variance.contravariant;
    case Variance.contravariant:
      return Variance.covariant;
    case Variance.invariant:
  }
  return variance;
}

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a non-covariant fashion.
class IncludesTypeParametersNonCovariantly extends DartTypeVisitor<bool> {
  Variance _variance;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersNonCovariantly(this._typeParametersToSearchFor,
      {Variance initialVariance})
      : _variance = initialVariance;

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    Variance oldVariance = _variance;
    _variance = Variance.invariant;
    for (TypeParameter parameter in node.typeParameters) {
      if (parameter.bound.accept(this)) return true;
    }
    _variance = invertVariance(oldVariance);
    for (DartType parameter in node.positionalParameters) {
      if (parameter.accept(this)) return true;
    }
    for (NamedType parameter in node.namedParameters) {
      if (parameter.type.accept(this)) return true;
    }
    _variance = oldVariance;
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    for (DartType argument in node.typeArguments) {
      if (argument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return _variance != Variance.covariant &&
        _typeParametersToSearchFor.contains(node.parameter);
  }
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initializers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  ClassHierarchy classHierarchy;

  ClassHierarchyBuilder hierarchyBuilder;

  CoreTypes coreTypes;

  /// Indicates whether the "prepare" phase of type inference is complete.
  bool isTypeInferencePrepared = false;

  TypeSchemaEnvironment typeSchemaEnvironment;

  /// A map containing constructors with initializing formals whose types
  /// need to be inferred.
  ///
  /// This is represented as a map from a constructor to its library
  /// builder because the builder is used to report errors due to cyclic
  /// inference dependencies.
  final Map<Constructor, LibraryBuilder> toBeInferred = {};

  /// A map containing constructors in the process of being inferred.
  ///
  /// This is used to detect cyclic inference dependencies.  It is represented
  /// as a map from a constructor to its library builder because the builder
  /// is used to report errors.
  final Map<Constructor, LibraryBuilder> beingInferred = {};

  final Instrumentation instrumentation;

  TypeInferenceEngine(this.instrumentation);

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(
      Uri uri, InterfaceType thisType, SourceLibraryBuilder library);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(
      Uri uri, InterfaceType thisType, SourceLibraryBuilder library);

  /// Performs the third phase of top level inference, which is to visit all
  /// constructors still needing inference and infer the types of their
  /// initializing formals from the corresponding fields.
  void finishTopLevelInitializingFormals() {
    // Field types have all been inferred so there cannot be a cyclic
    // dependency.
    for (Constructor constructor in toBeInferred.keys) {
      for (VariableDeclaration declaration
          in constructor.function.positionalParameters) {
        inferInitializingFormal(declaration, constructor);
      }
      for (VariableDeclaration declaration
          in constructor.function.namedParameters) {
        inferInitializingFormal(declaration, constructor);
      }
    }
    toBeInferred.clear();
  }

  void inferInitializingFormal(VariableDeclaration formal, Constructor parent) {
    if (formal.type == null) {
      for (Field field in parent.enclosingClass.fields) {
        if (field.name.name == formal.name) {
          TypeInferenceEngine.resolveInferenceNode(field);
          formal.type = field.type;
          return;
        }
      }
      // We did not find the corresponding field, so the program is erroneous.
      // The error should have been reported elsewhere and type inference
      // should continue by inferring dynamic.
      formal.type = const DynamicType();
    }
  }

  /// Gets ready to do top level type inference for the component having the
  /// given [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy);
  }

  static Member resolveInferenceNode(Member member) {
    if (member is Field) {
      DartType type = member.type;
      if (type is ImplicitFieldType) {
        if (type.member.target != member) {
          type.member.inferCopiedType(member);
        } else {
          type.member.inferType();
        }
      }
    }
    return member;
  }
}
