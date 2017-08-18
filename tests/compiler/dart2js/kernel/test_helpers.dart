// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.equivalence;

import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/common/work.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/kernel/elements.dart';
import 'package:compiler/src/kernel/kelements.dart' show KLocalFunction;
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/ssa/kernel_impact.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/util/util.dart';

class KernelEquivalence {
  final WorldDeconstructionForTesting testing;

  /// Set of mixin applications assumed to be equivalent.
  ///
  /// We need co-inductive reasoning because mixin applications are compared
  /// structurally and therefore, in the case of generic mixin applications,
  /// meet themselves through the equivalence check of their type variables.
  Set<Pair<ClassEntity, ClassEntity>> assumedMixinApplications =
      new Set<Pair<ClassEntity, ClassEntity>>();

  KernelEquivalence(KernelToElementMap builder)
      : testing = new WorldDeconstructionForTesting(builder);

  TestStrategy get defaultStrategy => new TestStrategy(
      elementEquivalence: entityEquivalence,
      typeEquivalence: typeEquivalence,
      constantEquivalence: constantEquivalence,
      constantValueEquivalence: constantValueEquivalence);

  bool entityEquivalence(Element a, Entity b, {TestStrategy strategy}) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    strategy ??= defaultStrategy;
    switch (a.kind) {
      case ElementKind.GENERATIVE_CONSTRUCTOR:
        if (b is IndexedConstructor && b.isGenerativeConstructor) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass);
        }
        return false;
      case ElementKind.FACTORY_CONSTRUCTOR:
        if (b is IndexedConstructor && b.isFactoryConstructor) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass);
        }
        return false;
      case ElementKind.GENERATIVE_CONSTRUCTOR_BODY:
        ConstructorBodyElement aConstructorBody = a;
        if (b is ConstructorBodyEntity) {
          return entityEquivalence(aConstructorBody.constructor, b.constructor);
        }
        return false;
      case ElementKind.CLASS:
        if (b is IndexedClass) {
          List<InterfaceType> aMixinTypes = [];
          List<InterfaceType> bMixinTypes = [];
          ClassElement aClass = a;
          if (aClass.isUnnamedMixinApplication) {
            if (!testing.isUnnamedMixinApplication(b)) {
              return false;
            }
            while (aClass.isMixinApplication) {
              MixinApplicationElement aMixinApplication = aClass;
              aMixinTypes.add(aMixinApplication.mixinType);
              aClass = aMixinApplication.superclass;
            }
            IndexedClass bClass = b;
            while (bClass != null) {
              InterfaceType mixinType = testing.getMixinTypeForClass(bClass);
              if (mixinType == null) break;
              bMixinTypes.add(mixinType);
              bClass = testing.getSuperclassForClass(bClass);
            }
            if (aMixinTypes.isNotEmpty || aMixinTypes.isNotEmpty) {
              Pair<ClassEntity, ClassEntity> pair =
                  new Pair<ClassEntity, ClassEntity>(aClass, bClass);
              if (assumedMixinApplications.contains(pair)) {
                return true;
              } else {
                assumedMixinApplications.add(pair);
                bool result = strategy.testTypeLists(
                    a, b, 'mixinTypes', aMixinTypes, bMixinTypes);
                assumedMixinApplications.remove(pair);
                return result;
              }
            }
          } else {
            if (testing.isUnnamedMixinApplication(b)) {
              return false;
            }
          }
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(a, b, 'library', a.library, b.library);
        }
        return false;
      case ElementKind.LIBRARY:
        if (b is IndexedLibrary) {
          LibraryElement libraryA = a;
          return libraryA.canonicalUri == b.canonicalUri;
        }
        return false;
      case ElementKind.FUNCTION:
        if (b is IndexedFunction && b.isFunction) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass) &&
              strategy.testElements(a, b, 'library', a.library, b.library);
        } else if (b is KLocalFunction) {
          LocalFunctionElement aLocalFunction = a;
          return strategy.test(a, b, 'name', a.name, b.name ?? '') &&
              strategy.testElements(a, b, 'executableContext',
                  aLocalFunction.executableContext, b.executableContext) &&
              strategy.testElements(a, b, 'memberContext',
                  aLocalFunction.memberContext, b.memberContext);
        }
        return false;
      case ElementKind.GETTER:
        if (b is IndexedFunction && b.isGetter) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass) &&
              strategy.testElements(a, b, 'library', a.library, b.library);
        }
        return false;
      case ElementKind.SETTER:
        if (b is IndexedFunction && b.isSetter) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass) &&
              strategy.testElements(a, b, 'library', a.library, b.library);
        }
        return false;
      case ElementKind.FIELD:
        if (b is IndexedField) {
          return strategy.test(a, b, 'name', a.name, b.name) &&
              strategy.testElements(
                  a, b, 'enclosingClass', a.enclosingClass, b.enclosingClass) &&
              strategy.testElements(a, b, 'library', a.library, b.library);
        }
        return false;
      case ElementKind.TYPE_VARIABLE:
        if (b is IndexedTypeVariable) {
          TypeVariableElement aElement = a;
          return strategy.test(a, b, 'index', aElement.index, b.index) &&
              strategy.testElements(a, b, 'typeDeclaration',
                  aElement.typeDeclaration, b.typeDeclaration);
        }
        return false;
      default:
        throw new UnsupportedError('Unsupported equivalence: '
            '$a (${a.runtimeType}) vs $b (${b.runtimeType})');
    }
  }

  bool typeEquivalence(ResolutionDartType a, DartType b,
      {TestStrategy strategy}) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    a = unalias(a);
    strategy ??= defaultStrategy;
    switch (a.kind) {
      case ResolutionTypeKind.DYNAMIC:
        return b is DynamicType;
      case ResolutionTypeKind.VOID:
        return b is VoidType;
      case ResolutionTypeKind.INTERFACE:
        if (b is InterfaceType) {
          ResolutionInterfaceType aType = a;
          return strategy.testElements(a, b, 'element', a.element, b.element) &&
              strategy.testTypeLists(
                  a, b, 'typeArguments', aType.typeArguments, b.typeArguments);
        }
        return false;
      case ResolutionTypeKind.TYPE_VARIABLE:
        if (b is TypeVariableType) {
          return strategy.testElements(a, b, 'element', a.element, b.element);
        }
        return false;
      case ResolutionTypeKind.FUNCTION:
        if (b is FunctionType) {
          ResolutionFunctionType aType = a;
          return strategy.testTypes(
                  a, b, 'returnType', aType.returnType, b.returnType) &&
              strategy.testTypeLists(a, b, 'parameterTypes',
                  aType.parameterTypes, b.parameterTypes) &&
              strategy.testTypeLists(a, b, 'optionalParameterTypes',
                  aType.optionalParameterTypes, b.optionalParameterTypes) &&
              strategy.testLists(a, b, 'namedParameters', aType.namedParameters,
                  b.namedParameters) &&
              strategy.testTypeLists(a, b, 'namedParameterTypes',
                  aType.namedParameterTypes, b.namedParameterTypes);
        }
        return false;
      default:
        throw new UnsupportedError('Unsupported equivalence: '
            '$a (${a.runtimeType}) vs $b (${b.runtimeType})');
    }
  }

  bool constantEquivalence(ConstantExpression exp1, ConstantExpression exp2,
      {TestStrategy strategy}) {
    strategy ??= defaultStrategy;
    return areConstantsEquivalent(exp1, exp2, strategy: strategy);
  }

  bool constantValueEquivalence(ConstantValue value1, ConstantValue value2,
      {TestStrategy strategy}) {
    strategy ??= defaultStrategy;
    return areConstantValuesEquivalent(value1, value2, strategy: strategy);
  }
}

class KernelTestWorkItemBuilder implements WorkItemBuilder {
  final Compiler _compiler;

  KernelTestWorkItemBuilder(this._compiler);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return new KernelTestWorkItem(
        _compiler, _compiler.backend.impactTransformer, entity);
  }
}

class KernelTestWorkItem implements ResolutionWorkItem {
  final Compiler _compiler;
  final ImpactTransformer _impactTransformer;
  final MemberElement element;

  KernelTestWorkItem(this._compiler, this._impactTransformer, this.element);

  @override
  WorldImpact run() {
    ResolutionImpact resolutionImpact = build(_compiler, element.resolvedAst);
    return _impactTransformer.transformResolutionImpact(resolutionImpact);
  }
}

/// Visitor the performers unaliasing of all typedefs nested within a
/// [ResolutionDartType].
class Unaliaser
    extends BaseResolutionDartTypeVisitor<dynamic, ResolutionDartType> {
  const Unaliaser();

  @override
  ResolutionDartType visit(ResolutionDartType type, [_]) =>
      // ignore: ARGUMENT_TYPE_NOT_ASSIGNABLE
      type.accept(this, null);

  @override
  ResolutionDartType visitType(ResolutionDartType type, _) => type;

  List<ResolutionDartType> visitList(List<ResolutionDartType> types) =>
      types.map(visit).toList();

  @override
  ResolutionDartType visitInterfaceType(ResolutionInterfaceType type, _) {
    return type.createInstantiation(visitList(type.typeArguments));
  }

  @override
  ResolutionDartType visitTypedefType(ResolutionTypedefType type, _) {
    return visit(type.unaliased);
  }

  @override
  ResolutionDartType visitFunctionType(ResolutionFunctionType type, _) {
    return new ResolutionFunctionType.synthesized(
        visit(type.returnType),
        visitList(type.parameterTypes),
        visitList(type.optionalParameterTypes),
        type.namedParameters,
        visitList(type.namedParameterTypes));
  }
}

/// Perform unaliasing of all typedefs nested within a [ResolutionDartType].
ResolutionDartType unalias(ResolutionDartType type) {
  return const Unaliaser().visit(type);
}

bool elementFilter(Entity element) {
  if (element is ConstructorElement && element.isRedirectingFactory) {
    // Redirecting factory constructors are skipped in kernel.
    return false;
  }
  if (element is ClassElement) {
    for (ConstructorElement constructor in element.constructors) {
      if (!constructor.isRedirectingFactory) {
        return true;
      }
    }
    // The class cannot itself be instantiated.
    return false;
  }
  return true;
}
