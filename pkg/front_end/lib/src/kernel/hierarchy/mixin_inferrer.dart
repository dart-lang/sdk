// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchyBase;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/type_algebra.dart';

import '../../base/messages.dart'
    show Message, templateMixinInferenceNoMatchingClass;
import '../../base/problems.dart' show unexpected, unsupported;
import '../../builder/declaration_builders.dart';
import '../../type_inference/type_schema.dart';

class BuilderMixinInferrer {
  final CoreTypes coreTypes;
  final _MixinInferenceSolution _mixinInferenceSolution;
  final List<TypeParameter> typeParametersToSolveFor;
  final ClassBuilder cls;
  final ClassHierarchyBase classHierarchyBase;

  BuilderMixinInferrer(
      this.cls, this.classHierarchyBase, this.typeParametersToSolveFor)
      : coreTypes = classHierarchyBase.coreTypes,
        _mixinInferenceSolution =
            new _MixinInferenceSolution(typeParametersToSolveFor);

  void generateConstraints(
      Class mixinClass, Supertype baseType, Supertype mixinSupertype) {
    if (_mixinInferenceSolution.isUnsolvable) {
      // The currently observed equalities are already unsolvable, and adding
      // more will not change that.
      return;
    }

    if (mixinSupertype.typeArguments.isEmpty) {
      // The supertype constraint isn't generic; it doesn't constrain anything.
    } else if (mixinSupertype.classNode.isAnonymousMixin) {
      // We have either a mixin declaration `mixin M<X0, ..., Xn> on S0, S1` or
      // a VM-style super mixin `abstract class M<X0, ..., Xn> extends S0 with
      // S1` where S0 and S1 are superclass constraints that possibly have type
      // arguments.
      //
      // It has been compiled by naming the superclass to either:
      //
      // abstract class S0&S1<...> extends Object implements S0, S1 {}
      // abstract class M<X0, ..., Xn> extends S0&S1<...> ...
      //
      // for a mixin declaration, or else:
      //
      // abstract class S0&S1<...> = S0 with S1;
      // abstract class M<X0, ..., Xn> extends S0&S1<...>
      //
      // for a VM-style super mixin.  The type parameters of S0&S1 are the X0,
      // ..., Xn that occurred free in S0 and S1.  Treat S0 and S1 as separate
      // supertype constraints by recursively calling this algorithm.
      //
      // In the Dart VM the mixin application classes themselves are all
      // eliminated by translating them to normal classes.  In that case, the
      // mixin appears as the only interface in the introduced class.  We
      // support three forms for the superclass constraints:
      //
      // abstract class S0&S1<...> extends Object implements S0, S1 {}
      // abstract class S0&S1<...> = S0 with S1;
      // abstract class S0&S1<...> extends S0 implements S1 {}
      Class mixinSuperclass = mixinSupertype.classNode;
      if (mixinSuperclass.mixedInType == null &&
          mixinSuperclass.implementedTypes.length != 1 &&
          (mixinSuperclass.superclass != coreTypes.objectClass ||
              mixinSuperclass.implementedTypes.length != 2)) {
        unexpected(
            'Compiler-generated mixin applications have a mixin or else '
                'implement exactly one type',
            '$mixinSuperclass implements '
                '${mixinSuperclass.implementedTypes.length} types',
            mixinSuperclass.fileOffset,
            mixinSuperclass.fileUri);
      }
      Substitution substitution = Substitution.fromSupertype(mixinSupertype);
      Supertype s0, s1;
      if (mixinSuperclass.implementedTypes.length == 2) {
        s0 = mixinSuperclass.implementedTypes[0];
        s1 = mixinSuperclass.implementedTypes[1];
      }
      // Coverage-ignore(suite): Not run.
      else if (mixinSuperclass.implementedTypes.length == 1) {
        s0 = mixinSuperclass.supertype!;
        s1 = mixinSuperclass.implementedTypes.first;
      } else {
        s0 = mixinSuperclass.supertype!;
        s1 = mixinSuperclass.mixedInType!;
      }
      s0 = substitution.substituteSupertype(s0);
      s1 = substitution.substituteSupertype(s1);
      generateConstraints(mixinClass, baseType, s0);
      generateConstraints(mixinClass, baseType, s1);
    } else {
      // Find the type U0 which is baseType as an instance of mixinSupertype's
      // class.
      Supertype? supertype =
          asInstantiationOf(baseType, mixinSupertype.classNode);
      if (supertype == null) {
        // Coverage-ignore-block(suite): Not run.
        reportProblem(
            templateMixinInferenceNoMatchingClass.withArguments(mixinClass.name,
                baseType.classNode.name, mixinSupertype.asInterfaceType),
            mixinClass);
        return;
      }
      InterfaceType u0 = Substitution.fromSupertype(baseType)
          .substituteSupertype(supertype)
          .asInterfaceType;
      // We want to solve U0 = S0 where S0 is mixinSupertype, but we only have
      // a subtype constraints.  Solve for equality by solving
      // both U0 <: S0 and S0 <: U0.
      InterfaceType s0 = mixinSupertype.asInterfaceType;

      _mixinInferenceSolution.addSolutionFor(s0, u0,
          unsupportedErrorReporter: this);
    }
  }

  void infer(Class classNode) {
    Supertype mixedInType = classNode.mixedInType!;
    assert(mixedInType.typeArguments.every((t) => t == const UnknownType()));
    // Note that we have no anonymous mixin applications, they have all
    // been named.  Note also that mixin composition has been translated
    // so that we only have mixin applications of the form `S with M`.
    Supertype baseType = classNode.supertype!;
    Class mixinClass = mixedInType.classNode;
    Supertype mixinSupertype = mixinClass.supertype!;
    // Generate constraints based on the mixin's supertype.
    generateConstraints(mixinClass, baseType, mixinSupertype);
    if (_mixinInferenceSolution.isUnsolvable) {
      // Coverage-ignore-block(suite): Not run.
      reportProblem(
          templateMixinInferenceNoMatchingClass.withArguments(mixinClass.name,
              baseType.classNode.name, mixinSupertype.asInterfaceType),
          mixinClass);
    }
    // Generate new type parameters with the solution as bounds.
    List<TypeParameter> parameters;
    if (_mixinInferenceSolution.isUnsolvable) {
      // Coverage-ignore-block(suite): Not run.
      parameters = [...mixinClass.typeParameters];
    } else {
      parameters = [
        for (TypeParameter typeParameter in mixinClass.typeParameters)
          new TypeParameter(
              typeParameter.name,
              _mixinInferenceSolution.solution[typeParameter] ??
                  typeParameter.bound,
              typeParameter.defaultType)
      ];
    }
    // Bounds might mention the mixin class's type parameters so we have to
    // substitute them before calling instantiate to bounds.
    Substitution substitution = Substitution.fromPairs(
        mixinClass.typeParameters,
        new List<DartType>.generate(
            parameters.length,
            (i) => new TypeParameterType.forAlphaRenaming(
                mixinClass.typeParameters[i], parameters[i])));
    for (TypeParameter p in parameters) {
      p.bound = substitution.substituteType(p.bound);
    }
    // Use instantiate to bounds.
    List<DartType> bounds = calculateBounds(parameters, coreTypes.objectClass);
    for (int i = 0; i < mixedInType.typeArguments.length; ++i) {
      mixedInType.typeArguments[i] = bounds[i];
    }
  }

  Supertype? asInstantiationOf(Supertype type, Class superclass) {
    List<DartType>? arguments = classHierarchyBase.getTypeArgumentsAsInstanceOf(
        type.asInterfaceType, superclass);
    if (arguments == null) return null;
    return new Supertype(superclass, arguments);
  }

  // Coverage-ignore(suite): Not run.
  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }

  // Coverage-ignore(suite): Not run.
  Never reportUnsupportedProblem(String operation) {
    return unsupported(operation, cls.charOffset, cls.fileUri);
  }
}

class _MixinInferenceSolution {
  Map<TypeParameter, DartType>? _typeParameterSolution = {};
  final List<TypeParameter> typeParametersToSolveFor;
  final Map<StructuralParameter, StructuralParameter>
      structuralTypeParameterEqualityAssumptions =
      <StructuralParameter, StructuralParameter>{};

  _MixinInferenceSolution(this.typeParametersToSolveFor);

  Map<TypeParameter, DartType> get solution => _typeParameterSolution!;

  bool get isUnsolvable => _typeParameterSolution == null;

  void addSolutionFor(DartType type1, DartType type2,
      {required BuilderMixinInferrer unsupportedErrorReporter}) {
    if (_typeParameterSolution == null) {
      // The inference has already failed at an earlier stage, so the constraint
      // gathering can stop.
      return;
    }

    _typeParameterSolution = _mergeInferenceByUnificationResults(
        _solveForEquality(type1, type2,
            unsupportedErrorReporter: unsupportedErrorReporter),
        _typeParameterSolution);
  }

  Map<TypeParameter, DartType>? _solveForEquality(
      DartType type1, DartType type2,
      {required BuilderMixinInferrer unsupportedErrorReporter}) {
    assert(!(containsTypeVariable(type1, {...typeParametersToSolveFor}) &&
        containsTypeVariable(type2, {...typeParametersToSolveFor})));
    assert(type1 is! TypedefType);
    assert(type2 is! TypedefType);
    if (type1 is TypeParameterType &&
        typeParametersToSolveFor.contains(type1.parameter)) {
      return <TypeParameter, DartType>{type1.parameter: type2};
    }
    if (type2 is TypeParameterType &&
        // Coverage-ignore(suite): Not run.
        typeParametersToSolveFor.contains(type2.parameter)) {
      // Coverage-ignore-block(suite): Not run.
      return <TypeParameter, DartType>{type2.parameter: type1};
    }
    switch (type1) {
      case AuxiliaryType():
        // Coverage-ignore(suite): Not run.
        return unsupportedErrorReporter.reportUnsupportedProblem(
            "_MixinInferenceSolution._solveForEquality"
            "(${type1.runtimeType}, ${type2.runtimeType})");
      case InvalidType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! InvalidType) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case DynamicType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! DynamicType) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case VoidType():
        if (type2 is! VoidType) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case NeverType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! NeverType) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case NullType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! NullType) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case FunctionType():
        if (type2 is! FunctionType) {
          return null;
        } else {
          if (type1.positionalParameters.length !=
                  type2.positionalParameters.length ||
              type1.requiredParameterCount != type2.requiredParameterCount ||
              type1.namedParameters.length != type2.namedParameters.length ||
              type1.typeParameters.length != type2.typeParameters.length ||
              type1.nullability != type2.nullability) {
            return null;
          }
          for (int i = 0; i < type1.typeParameters.length; i++) {
            structuralTypeParameterEqualityAssumptions[
                type1.typeParameters[i]] = type2.typeParameters[i];
            structuralTypeParameterEqualityAssumptions[
                type2.typeParameters[i]] = type1.typeParameters[i];
          }
          Map<TypeParameter, DartType>? result = _solveForEquality(
              type1.returnType, type2.returnType,
              unsupportedErrorReporter: unsupportedErrorReporter);
          if (result == null) {
            return null;
          }
          for (int i = 0; i < type1.typeParameters.length; i++) {
            result = _mergeInferenceByUnificationResults(
                _solveForEquality(type1.typeParameters[i].bound,
                    type2.typeParameters[i].bound,
                    unsupportedErrorReporter: unsupportedErrorReporter),
                result);
            if (result == null) {
              return null;
            }
          }
          for (int i = 0; i < type1.positionalParameters.length; i++) {
            result = _mergeInferenceByUnificationResults(
                _solveForEquality(type1.positionalParameters[i],
                    type2.positionalParameters[i],
                    unsupportedErrorReporter: unsupportedErrorReporter),
                result);
            if (result == null) {
              return null;
            }
          }
          Map<String, NamedType> namedParameterByName1 = <String, NamedType>{
            for (NamedType namedType in type1.namedParameters)
              namedType // Coverage-ignore(suite): Not run.
                  .name: namedType
          };
          for (NamedType namedType in type2.namedParameters) {
            // Coverage-ignore-block(suite): Not run.
            if (!namedParameterByName1.containsKey(namedType.name)) {
              return null;
            } else {
              result = _mergeInferenceByUnificationResults(
                  _solveForEquality(namedParameterByName1[namedType.name]!.type,
                      namedType.type,
                      unsupportedErrorReporter: unsupportedErrorReporter),
                  result);
              if (result == null) {
                return null;
              }
              namedParameterByName1.remove(namedType.name);
            }
          }
          if (namedParameterByName1.isNotEmpty) {
            return null;
          }
          return result;
        }
      case TypedefType():
        // Coverage-ignore(suite): Not run.
        return unsupportedErrorReporter.reportUnsupportedProblem(
            "_MixinInferenceSolution._solveForEquality"
            "(${type1.runtimeType}, ${type2.runtimeType})");
      case FutureOrType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! FutureOrType) {
          return null;
        } else {
          return _solveForEquality(type1.typeArgument, type2.typeArgument,
              unsupportedErrorReporter: unsupportedErrorReporter);
        }
      case IntersectionType():
        // Coverage-ignore(suite): Not run.
        // Intersection types can't appear in supertypes.
        return unsupportedErrorReporter.reportUnsupportedProblem(
            "_MixinInferenceSolution._solveForEquality"
            "(${type1.runtimeType}, ${type2.runtimeType})");
      case TypeParameterType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! TypeParameterType ||
            type1.parameter != type2.parameter ||
            type1.nullability != type2.nullability) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case StructuralParameterType():
        if (type2 is! StructuralParameterType ||
            structuralTypeParameterEqualityAssumptions[type1.parameter] !=
                type2.parameter ||
            type1.nullability != type2.nullability) {
          return null;
        } else {
          return <TypeParameter, DartType>{};
        }
      case RecordType():
        // Coverage-ignore(suite): Not run.
        if (type2 is! RecordType) {
          return null;
        } else {
          if (type1.positional.length != type2.positional.length ||
              type2.named.length != type2.named.length ||
              type1.nullability != type2.nullability) {
            return null;
          }
          Map<TypeParameter, DartType>? result = {};
          for (int i = 0; i < type1.positional.length; i++) {
            result = _mergeInferenceByUnificationResults(
                _solveForEquality(type1.positional[i], type2.positional[i],
                    unsupportedErrorReporter: unsupportedErrorReporter),
                result);
            if (result == null) {
              return result;
            }
          }
          Map<String, NamedType> namedParameterByName1 = <String, NamedType>{
            for (NamedType namedType in type1.named) namedType.name: namedType
          };
          for (NamedType namedType in type2.named) {
            if (!namedParameterByName1.containsKey(namedType.name)) {
              return null;
            } else {
              result = _mergeInferenceByUnificationResults(
                  _solveForEquality(namedParameterByName1[namedType.name]!.type,
                      namedType.type,
                      unsupportedErrorReporter: unsupportedErrorReporter),
                  result);
              if (result == null) {
                return null;
              }
              namedParameterByName1.remove(namedType.name);
            }
          }
          if (namedParameterByName1.isNotEmpty) {
            return null;
          }
          return result;
        }
      case InterfaceType():
        if (type2 is! InterfaceType) {
          return null;
        } else {
          if (type1.classNode != type2.classNode ||
              type1.nullability != type2.nullability) {
            return null;
          }
          assert(type1.typeArguments.length == type2.typeArguments.length);
          Map<TypeParameter, DartType>? result = {};
          for (int i = 0; i < type1.typeArguments.length; i++) {
            result = _mergeInferenceByUnificationResults(
                _solveForEquality(
                    type1.typeArguments[i], type2.typeArguments[i],
                    unsupportedErrorReporter: unsupportedErrorReporter),
                result);
            if (result == null) {
              return null;
            }
          }
          return result;
        }
      // Coverage-ignore(suite): Not run.
      case ExtensionType():
        if (type2 is! ExtensionType) {
          return null;
        } else {
          if (type1.extensionTypeDeclaration !=
                  type2.extensionTypeDeclaration ||
              type1.nullability != type2.nullability) {
            return null;
          }
          assert(type1.typeArguments.length == type2.typeArguments.length);
          Map<TypeParameter, DartType>? result = {};
          for (int i = 0; i < type1.typeArguments.length; i++) {
            result = _mergeInferenceByUnificationResults(
                _solveForEquality(
                    type1.typeArguments[i], type2.typeArguments[i],
                    unsupportedErrorReporter: unsupportedErrorReporter),
                result);
            if (result == null) {
              return null;
            }
          }
          return result;
        }
    }
  }

  Map<TypeParameter, DartType>? _mergeInferenceByUnificationResults(
      Map<TypeParameter, DartType>? result1,
      Map<TypeParameter, DartType>? result2) {
    if (result1 == null || result2 == null) {
      return null;
    } else {
      for (TypeParameter typeParameter in result1.keys) {
        if (result2.containsKey(typeParameter)) {
          // Coverage-ignore-block(suite): Not run.
          if (result1[typeParameter] != result2[typeParameter]) {
            return null;
          }
        } else {
          result2[typeParameter] = result1[typeParameter]!;
        }
      }
      return result2;
    }
  }
}
