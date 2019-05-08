// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is capable of producing linked summaries from unlinked
/// ones (or prelinked ones).  It functions by building a miniature
/// element model to represent the contents of the summaries, and then
/// scanning the element model to gather linked information and adding
/// it to the summary data structures.
///
/// The reason we use a miniature element model to do the linking
/// (rather than resynthesizing the full element model from the
/// summaries) is that it is expected that we will only need to
/// traverse a small subset of the element properties in order to link.
/// Resynthesizing only those properties that we need should save
/// substantial CPU time.
///
/// The element model implements the same interfaces as the full
/// element model, so we can re-use code elsewhere in the analysis
/// engine to do the linking.  However, only a small subset of the
/// methods and getters defined in the full element model are
/// implemented here.  To avoid static warnings, each element model
/// class contains an implementation of `noSuchMethod`.
///
/// The miniature element model follows the following design
/// principles:
///
/// - With few exceptions, resynthesis is done incrementally on demand,
///   so that we don't pay the cost of resynthesizing elements (or
///   properties of elements) that aren't referenced from a part of the
///   element model that is relevant to linking.
///
/// - Computation of values in the miniature element model is similar
///   to the task model, but much lighter weight.  Instead of declaring
///   tasks and their relationships using classes, each task is simply
///   a method (frequently a getter) that computes a value.  Instead of
///   using a general purpose cache, values are cached by the methods
///   themselves in private fields (with `null` typically representing
///   "not yet cached").
///
/// - No attempt is made to detect cyclic dependencies due to bugs in
///   the analyzer.  This saves time because dependency evaluation
///   doesn't have to be a separate step from evaluating a value; we
///   can simply call the getter.
///
/// - However, for cases where cyclic dependencies may occur in the
///   absence of analyzer bugs (e.g. because of errors in the code
///   being analyzed, or cycles between top level and static variables
///   undergoing type inference), we do precompute dependencies, and we
///   use Tarjan's strongly connected components algorithm to detect
///   cycles.
///
/// - As much as possible, bookkeeping data is pointed to directly by
///   the element objects, rather than being stored in maps.
///
/// - Where possible, we favor method dispatch instead of "is" and "as"
///   checks.  E.g. see [ReferenceableElementForLink.asConstructor].
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/expr_builder.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/task/strong_mode.dart';

final _typesWithImplicitArguments = new Expando();

bool isIncrementOrDecrement(UnlinkedExprAssignOperator operator) {
  switch (operator) {
    case UnlinkedExprAssignOperator.prefixDecrement:
    case UnlinkedExprAssignOperator.prefixIncrement:
    case UnlinkedExprAssignOperator.postfixDecrement:
    case UnlinkedExprAssignOperator.postfixIncrement:
      return true;
    default:
      return false;
  }
}

/// Link together the build unit consisting of [libraryUris], using
/// [getDependency] to fetch the [LinkedLibrary] objects from other
/// build units, and [getUnit] to fetch the [UnlinkedUnit] objects from
/// both this build unit and other build units.
///
/// The [strong] flag controls whether type inference is performed in strong
/// mode or spec mode.  Note that in spec mode, the only types that are inferred
/// are the types of initializing formals, which are inferred from the types of
/// the corresponding fields.
///
/// If [getAst] is provided, it is used to obtain ASTs of source files in this
/// build unit, and these ASTs are used for type inference.
///
/// A map is returned whose keys are the URIs of the libraries in this
/// build unit, and whose values are the corresponding
/// [LinkedLibraryBuilder]s.
Map<String, LinkedLibraryBuilder> link(
    Set<String> libraryUris,
    GetDependencyCallback getDependency,
    GetUnitCallback getUnit,
    DeclaredVariables declaredVariables,
    AnalysisOptions analysisOptions,
    [GetAstCallback getAst]) {
  Map<String, LinkedLibraryBuilder> linkedLibraries =
      setupForLink(libraryUris, getUnit, declaredVariables);
  _relink(linkedLibraries, getDependency, getUnit, getAst, analysisOptions);
  return linkedLibraries;
}

/// Prepare to link together the build unit consisting of [libraryUris], using
/// [getUnit] to fetch the [UnlinkedUnit] objects from both this build unit and
/// other build units.
///
/// The libraries are prelinked, and a map is returned whose keys are the URIs
/// of the libraries in this build unit, and whose values are the corresponding
/// [LinkedLibraryBuilder]s.
Map<String, LinkedLibraryBuilder> setupForLink(Set<String> libraryUris,
    GetUnitCallback getUnit, DeclaredVariables declaredVariables) {
  Map<String, LinkedLibraryBuilder> linkedLibraries =
      <String, LinkedLibraryBuilder>{};
  for (String absoluteUri in libraryUris) {
    linkedLibraries[absoluteUri] = prelink(
        absoluteUri,
        getUnit(absoluteUri),
        getUnit,
        (String absoluteUri) => getUnit(absoluteUri)?.publicNamespace,
        declaredVariables);
  }
  return linkedLibraries;
}

/// Collects all the type references appearing on the "right hand side" of a
/// typedef.
///
/// The "right hand side" of a typedef is the type appearing after the "=" in a
/// new style typedef declaration, or for an old style typedef declaration, the
/// type that *would* appear after the "=" if it were converted to a new style
/// typedef declaration.  This means that type parameter declarations and their
/// bounds are not included.
List<EntityRef> _collectTypedefRhsTypes(UnlinkedTypedef unlinkedTypedef) {
  var types = <EntityRef>[];
  void visitParams(List<UnlinkedParam> params) {
    for (var param in params) {
      var type = param.type;
      if (type != null) {
        types.add(type);
      }
      if (param.isFunctionTyped) {
        visitParams(param.parameters);
      }
    }
  }

  var returnType = unlinkedTypedef.returnType;
  if (returnType != null) {
    types.add(returnType);
  }
  visitParams(unlinkedTypedef.parameters);
  return types;
}

/// Create an [EntityRefBuilder] representing the given [type], in a form
/// suitable for inclusion in [LinkedUnit.types].  [compilationUnit] is the
/// compilation unit in which the type will be used.  If [slot] is provided, it
/// is stored in [EntityRefBuilder.slot].
EntityRefBuilder _createLinkedType(
    DartType type,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterSerializationContext typeParameterContext,
    {int slot}) {
  EntityRefBuilder result = new EntityRefBuilder(slot: slot);
  if (type is InterfaceType) {
    ClassElementForLink element = type.element;
    result.reference = compilationUnit.addReference(element);
    _storeTypeArguments(
        type.typeArguments, result, compilationUnit, typeParameterContext);
    return result;
  } else if (type.isDynamic) {
    result.reference = compilationUnit.addRawReference('dynamic');
    return result;
  } else if (type is VoidTypeImpl) {
    result.reference = compilationUnit.addRawReference('void');
    return result;
  } else if (type is BottomTypeImpl) {
    result.reference = compilationUnit.addRawReference('*bottom*');
    return result;
  } else if (type is TypeParameterType) {
    TypeParameterElementImpl element = type.element;
    var deBruijnIndex = typeParameterContext?.computeDeBruijnIndex(element);
    if (deBruijnIndex != null) {
      result.paramReference = deBruijnIndex;
    } else {
      throw new StateError('The type parameter $type (in ${element?.location}) '
          'is out of scope.');
    }
    return result;
  } else if (type is FunctionType) {
    Element element = type.element;
    if (element is FunctionElementForLink_FunctionTypedParam) {
      result.reference =
          compilationUnit.addReference(element.typeParameterContext);
      result.implicitFunctionTypeIndices = element.implicitFunctionTypeIndices;
      _storeTypeArguments(
          type.typeArguments, result, compilationUnit, typeParameterContext);
      return result;
    }
    if (element is TopLevelFunctionElementForLink) {
      result.reference = compilationUnit.addReference(element);
      _storeTypeArguments(
          type.typeArguments, result, compilationUnit, typeParameterContext);
      return result;
    }
    if (element is MethodElementForLink) {
      result.reference = compilationUnit.addReference(element);
      _storeTypeArguments(
          type.typeArguments, result, compilationUnit, typeParameterContext);
      return result;
    }
    if (element is FunctionTypeAliasElementForLink) {
      result.reference = compilationUnit.addReference(element);
      _storeTypeArguments(
          type.typeArguments, result, compilationUnit, typeParameterContext);
      return result;
    }
    if (element is FunctionElement) {
      // We store all function elements by value.  Synthetic elements, e.g.
      // created for LUB, don't have actual elements; and local functions
      // are not exposed from element model.
      _storeFunctionElementByValue(result, element, compilationUnit);
      // TODO(paulberry): do I need to store type arguments?
      return result;
    }
    if (element is GenericFunctionTypeElementImpl) {
      // Function types are their own type parameter context
      typeParameterContext =
          new InlineFunctionTypeParameterContext(element, typeParameterContext);
      result.entityKind = EntityRefKind.genericFunctionType;
      result.syntheticReturnType = _createLinkedType(
          type.returnType, compilationUnit, typeParameterContext);
      result.syntheticParams = type.parameters
          .map((ParameterElement param) => _serializeSyntheticParam(
              param, compilationUnit, typeParameterContext))
          .toList();
      _storeTypeArguments(
          type.typeArguments, result, compilationUnit, typeParameterContext);
      return result;
    }
    // TODO(paulberry): implement other cases.
    throw new UnimplementedError('${element.runtimeType}');
  }
  // TODO(paulberry): implement other cases.
  throw new UnimplementedError('${type.runtimeType}');
}

DartType _dynamicIfBottom(DartType type) {
  if (type == null || type.isBottom) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

DartType _dynamicIfNull(DartType type) {
  if (type == null || type.isBottom || type.isDartCoreNull) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

/// Given [libraries] (a map from URI to [LinkedLibraryBuilder]
/// containing correct prelinked information), rebuild linked
/// information, using [getDependency] to fetch the [LinkedLibrary]
/// objects from other build units, and [getUnit] to fetch the
/// [UnlinkedUnit] objects from both this build unit and other build
/// units.
///
/// If a non-null [getAst] is provided, it is used to obtain ASTs of source
/// files in this build unit, and these ASTs are used for type inference.
///
/// The [strong] flag controls whether type inference is performed in strong
/// mode or spec mode.  Note that in spec mode, the only types that are inferred
/// are the types of initializing formals, which are inferred from the types of
/// the corresponding fields.
void _relink(
    Map<String, LinkedLibraryBuilder> libraries,
    GetDependencyCallback getDependency,
    GetUnitCallback getUnit,
    GetAstCallback getAst,
    AnalysisOptions analysisOptions) {
  new Linker(libraries, getDependency, getUnit, getAst, analysisOptions).link();
}

/// Create an [UnlinkedParam] representing the given [parameter], which should
/// be a parameter of a synthetic function type (e.g. one produced during type
/// inference as a result of computing the least upper bound of two function
/// types).
UnlinkedParamBuilder _serializeSyntheticParam(
    ParameterElement parameter,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterSerializationContext typeParameterContext) {
  UnlinkedParamBuilder b = new UnlinkedParamBuilder();
  b.name = parameter.name;
  if (parameter.isRequiredPositional) {
    b.kind = UnlinkedParamKind.requiredPositional;
  } else if (parameter.isRequiredNamed) {
    b.kind = UnlinkedParamKind.requiredNamed;
  } else if (parameter.isOptionalPositional) {
    b.kind = UnlinkedParamKind.optionalPositional;
  } else if (parameter.isOptionalNamed) {
    b.kind = UnlinkedParamKind.optionalNamed;
  }
  DartType type = parameter.type;
  if (!parameter.hasImplicitType) {
    if (type is FunctionType && type.element.isSynthetic) {
      b.isFunctionTyped = true;
      b.type = _createLinkedType(
          type.returnType, compilationUnit, typeParameterContext);
      b.parameters = type.parameters
          .map((parameter) => _serializeSyntheticParam(
              parameter, compilationUnit, typeParameterContext))
          .toList();
    } else {
      b.type = _createLinkedType(type, compilationUnit, typeParameterContext);
    }
  }
  return b;
}

/// Create an [UnlinkedTypeParamBuilder] representing the given [typeParameter],
/// which should be a type parameter of a synthetic function type (e.g. one
/// produced during type inference as a result of computing the least upper
/// bound of two function types).
UnlinkedTypeParamBuilder _serializeSyntheticTypeParameter(
    TypeParameterElement typeParameter,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterSerializationContext typeParameterContext) {
  TypeParameterElementImpl impl = typeParameter as TypeParameterElementImpl;
  EntityRefBuilder boundBuilder = typeParameter.bound != null
      ? _createLinkedType(
          typeParameter.bound, compilationUnit, typeParameterContext)
      : null;
  CodeRangeBuilder codeRangeBuilder =
      new CodeRangeBuilder(offset: impl.codeOffset, length: impl.codeLength);
  return new UnlinkedTypeParamBuilder(
      name: typeParameter.name,
      nameOffset: typeParameter.nameOffset,
      bound: boundBuilder,
      codeRange: codeRangeBuilder);
}

/// Store the given function [element] into the [entity] by value.
void _storeFunctionElementByValue(
    EntityRefBuilder entity,
    FunctionElement element,
    CompilationUnitElementInBuildUnit compilationUnit) {
  // Element is a local function, or a synthetic function element that was
  // generated on the fly to represent a type that has no associated source
  // code location. Store it as value.
  if (element is FunctionElementImpl) {
    entity.syntheticReturnType =
        _createLinkedType(element.returnType, compilationUnit, element);
    entity.entityKind = EntityRefKind.syntheticFunction;
    entity.syntheticParams = element.parameters
        .map((ParameterElement param) =>
            _serializeSyntheticParam(param, compilationUnit, element))
        .toList();
    entity.typeParameters = element.typeParameters
        .map((TypeParameterElement e) =>
            _serializeSyntheticTypeParameter(e, compilationUnit, element))
        .toList();
  }
}

/// Store the given [typeArguments] in [encodedType], using [compilationUnit]
/// and [typeParameterContext] to serialize them.
void _storeTypeArguments(
    List<DartType> typeArguments,
    EntityRefBuilder encodedType,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterSerializationContext typeParameterContext) {
  int count = typeArguments.length;
  List<EntityRefBuilder> encodedTypeArguments =
      new List<EntityRefBuilder>(count);
  for (int i = 0; i < count; i++) {
    encodedTypeArguments[i] = _createLinkedType(
        typeArguments[i], compilationUnit, typeParameterContext);
  }
  encodedType.typeArguments = encodedTypeArguments;
}

/// Type of the callback used by [link] to request [CompilationUnit] objects.
typedef CompilationUnit GetAstCallback(String absoluteUri);

/// Type of the callback used by [link] and [relink] to request
/// [LinkedLibrary] objects from other build units.
typedef LinkedLibrary GetDependencyCallback(String absoluteUri);

/// Type of the callback used by [link] and [relink] to request
/// [UnlinkedUnit] objects.
typedef UnlinkedUnit GetUnitCallback(String absoluteUri);

class AnalysisSessionForLink implements AnalysisSession {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing a class or enum resynthesized from a summary
/// during linking.
abstract class ClassElementForLink
    with ReferenceableElementForLink
    implements AbstractClassElementImpl {
  Map<String, ReferenceableElementForLink> _containedNames;

  @override
  final CompilationUnitElementForLink enclosingElement;

  /// TODO(brianwilkerson) This appears to be unused and might be removable.
  bool hasBeenInferred;

  DartType _typeWithDefaultBounds;

  ClassElementForLink(CompilationUnitElementForLink enclosingElement)
      : enclosingElement = enclosingElement,
        hasBeenInferred = !enclosingElement.isInBuildUnit;

  @override
  List<PropertyAccessorElementForLink> get accessors;

  @override
  ClassElementForLink get asClass => this;

  @override
  ConstructorElementForLink get asConstructor => unnamedConstructor;

  @override
  DartType get asStaticType =>
      enclosingElement.enclosingElement._linker.typeProvider.typeType;

  @override
  List<ConstructorElementForLink> get constructors;

  @override
  CompilationUnitElementForLink get enclosingUnit => enclosingElement;

  @override
  List<FieldElementForLink> get fields;

  /// Indicates whether this is the core class `Object`.
  bool get isObject;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  Source get librarySource => library.source;

  @override
  get linkedNode => null;

  @override
  List<MethodElementForLink> get methods;

  @override
  String get name;

  DartType get typeWithDefaultBounds => _typeWithDefaultBounds ??=
      enclosingElement.library._linker.typeSystem.instantiateToBounds(type);

  @override
  ConstructorElementForLink get unnamedConstructor;

  @override
  ReferenceableElementForLink getContainedName(String name) {
    if (_containedNames == null) {
      _containedNames = <String, ReferenceableElementForLink>{};
      // TODO(paulberry): what's the correct way to handle name conflicts?
      for (ConstructorElementForLink constructor in constructors) {
        _containedNames[constructor.name] = constructor;
      }
      for (PropertyAccessorElementForLink accessor in accessors) {
        _containedNames[accessor.name] = accessor;
      }
      for (MethodElementForLink method in methods) {
        _containedNames[method.name] = method;
      }
    }
    return _containedNames.putIfAbsent(
        name, () => UndefinedElementForLink.instance);
  }

  @override
  FieldElement getField(String name) {
    for (FieldElement fieldElement in fields) {
      if (name == fieldElement.name) {
        return fieldElement;
      }
    }
    return null;
  }

  @override
  PropertyAccessorElement getGetter(String getterName) {
    for (PropertyAccessorElement accessor in accessors) {
      if (accessor.isGetter && accessor.name == getterName) {
        return accessor;
      }
    }
    return null;
  }

  @override
  MethodElement getMethod(String methodName) {
    for (MethodElement method in methods) {
      if (method.name == methodName) {
        return method;
      }
    }
    return null;
  }

  /// Perform type inference and cycle detection on this class and
  /// store the resulting information in [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit);

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    return AbstractClassElementImpl.lookUpMethodInClass(
        this, methodName, library);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing a class resynthesized from a summary during
/// linking.
class ClassElementForLink_Class extends ClassElementForLink
    with TypeParameterizedElementMixin, SimplyBoundableForLinkMixin
    implements ClassElementImpl {
  /// The unlinked representation of the class in the summary.
  final UnlinkedClass _unlinkedClass;

  @override
  final bool isMixin;

  /// If non-null, the AST for the class or mixin declaration; this is used to
  /// obtain initializer expressions for type inference.
  final ClassOrMixinDeclaration _astForInference;

  List<ConstructorElementForLink> _constructors;
  ConstructorElementForLink _unnamedConstructor;
  bool _unnamedConstructorComputed = false;
  List<FieldElementForLink_ClassField> _fields;
  InterfaceType _supertype;
  InterfaceType _type;
  List<MethodElementForLink> _methods;
  List<InterfaceType> _mixins;
  List<InterfaceType> _interfaces;
  List<InterfaceType> _superclassConstraints;
  List<PropertyAccessorElementForLink> _accessors;

  ClassElementForLink_Class(CompilationUnitElementForLink enclosingElement,
      this._unlinkedClass, this.isMixin, this._astForInference)
      : super(enclosingElement) {
    _initSimplyBoundable();
  }

  @override
  List<PropertyAccessorElementForLink> get accessors {
    if (_accessors == null) {
      _accessors = <PropertyAccessorElementForLink>[];
      Map<String, SyntheticVariableElementForLink> syntheticVariables =
          <String, SyntheticVariableElementForLink>{};
      for (UnlinkedExecutable unlinkedExecutable
          in _unlinkedClass.executables) {
        if (unlinkedExecutable.kind == UnlinkedExecutableKind.getter ||
            unlinkedExecutable.kind == UnlinkedExecutableKind.setter) {
          String name = unlinkedExecutable.name;
          if (unlinkedExecutable.kind == UnlinkedExecutableKind.setter) {
            assert(name.endsWith('='));
            name = name.substring(0, name.length - 1);
          }
          SyntheticVariableElementForLink syntheticVariable = syntheticVariables
              .putIfAbsent(name, () => new SyntheticVariableElementForLink());
          PropertyAccessorElementForLink_Executable accessor =
              new PropertyAccessorElementForLink_Executable(enclosingElement,
                  this, unlinkedExecutable, syntheticVariable);
          _accessors.add(accessor);
          if (unlinkedExecutable.kind == UnlinkedExecutableKind.getter) {
            syntheticVariable._getter = accessor;
          } else {
            syntheticVariable._setter = accessor;
          }
        }
      }
      for (FieldElementForLink_ClassField field in fields) {
        _accessors.add(field.getter);
        if (!field.isConst && !field.isFinal) {
          _accessors.add(field.setter);
        }
      }
    }
    return _accessors;
  }

  @override
  List<ConstructorElementForLink> get constructors {
    if (_constructors == null) {
      _constructors = <ConstructorElementForLink>[];
      for (UnlinkedExecutable unlinkedExecutable
          in _unlinkedClass.executables) {
        if (unlinkedExecutable.kind == UnlinkedExecutableKind.constructor) {
          _constructors
              .add(new ConstructorElementForLink(this, unlinkedExecutable));
        }
      }
      if (_constructors.isEmpty) {
        _unnamedConstructorComputed = true;
        _unnamedConstructor = new ConstructorElementForLink_Synthetic(this);
        _constructors.add(_unnamedConstructor);
      }
    }
    return _constructors;
  }

  @override
  ContextForLink get context => enclosingUnit.context;

  @override
  String get displayName => _unlinkedClass.name;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  List<FieldElementForLink_ClassField> get fields {
    if (_fields == null) {
      _fields = <FieldElementForLink_ClassField>[];
      List<Expression> initializerExpressionsForInference;
      if (_astForInference != null) {
        initializerExpressionsForInference = [];
        for (var member in _astForInference.members) {
          if (member is FieldDeclaration) {
            for (var variable in member.fields.variables) {
              initializerExpressionsForInference.add(variable.initializer);
            }
          }
        }
        assert(initializerExpressionsForInference.length ==
            _unlinkedClass.fields.length);
      }
      for (int i = 0; i < _unlinkedClass.fields.length; i++) {
        var field = _unlinkedClass.fields[i];
        _fields.add(new FieldElementForLink_ClassField(
            this,
            field,
            initializerExpressionsForInference == null
                ? null
                : initializerExpressionsForInference[i]));
      }
    }
    return _fields;
  }

  @override
  String get identifier => name;

  @override
  List<InterfaceType> get interfaces => _interfaces ??=
      _unlinkedClass.interfaces.map(_computeInterfaceType).toList();

  @override
  bool get isAbstract => _unlinkedClass.isAbstract;

  @override
  bool get isEnum => false;

  @override
  bool get isMixinApplication => _unlinkedClass.isMixinApplication;

  @override
  bool get isObject => _unlinkedClass.hasNoSupertype;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  List<MethodElementForLink> get methods {
    if (_methods == null) {
      _methods = <MethodElementForLink>[];
      for (UnlinkedExecutable unlinkedExecutable
          in _unlinkedClass.executables) {
        if (unlinkedExecutable.kind ==
            UnlinkedExecutableKind.functionOrMethod) {
          _methods.add(new MethodElementForLink(this, unlinkedExecutable));
        }
      }
    }
    return _methods;
  }

  @override
  List<InterfaceType> get mixins {
    if (_mixins == null) {
      // Note: in the event of a loop in the class hierarchy, the calls to
      // collectAllSupertypes below will wind up reentrantly calling
      // this.mixins.  So to prevent infinite recursion we need to set _mixins
      // to non-null now.  It's ok that we populate it gradually; in the event
      // of a reentrant call, the user's code is known to have errors, so it's
      // ok if the reentrant call doesn't return the complete set of mixins; we
      // just need to ensure that analysis terminates.
      _mixins = <InterfaceType>[];
      List<InterfaceType> supertypesForMixinInference; // populated lazily
      for (var entity in _unlinkedClass.mixins) {
        var mixin = _computeInterfaceType(entity);
        var mixinElement = mixin.element;
        var slot = entity.refinedSlot;
        if (slot != 0 && mixinElement.typeParameters.isNotEmpty) {
          CompilationUnitElementForLink enclosingElement =
              this.enclosingElement;
          if (enclosingElement is CompilationUnitElementInBuildUnit) {
            var mixinSupertypeConstraints = context.typeSystem
                .gatherMixinSupertypeConstraintsForInference(mixinElement);
            if (mixinSupertypeConstraints.isNotEmpty) {
              if (supertypesForMixinInference == null) {
                supertypesForMixinInference = <InterfaceType>[];
                ClassElementImpl.collectAllSupertypes(
                    supertypesForMixinInference, supertype, type);
                for (var previousMixin in _mixins) {
                  ClassElementImpl.collectAllSupertypes(
                      supertypesForMixinInference, previousMixin, type);
                }
              }
              var matchingInterfaceTypes = _findInterfaceTypesForConstraints(
                  mixinSupertypeConstraints, supertypesForMixinInference);
              // Note: if matchingInterfaceType is null, that's an error.  Also,
              // if there are multiple matching interface types that use
              // different type parameters, that's also an error.  But we can't
              // report errors from the linker, so we just use the
              // first matching interface type (if there is one).  The error
              // detection logic is implemented in the ErrorVerifier.
              if (matchingInterfaceTypes != null) {
                // Try to pattern match matchingInterfaceTypes against
                // mixinSupertypeConstraints to find the correct set of type
                // parameters to apply to the mixin.
                var inferredMixin = context.typeSystem
                    .matchSupertypeConstraints(mixinElement,
                        mixinSupertypeConstraints, matchingInterfaceTypes);
                if (inferredMixin != null) {
                  mixin = inferredMixin;
                  enclosingElement._storeLinkedType(slot, mixin, this);
                }
              }
            }
          } else {
            var refinedMixin = enclosingElement.getLinkedType(this, slot);
            if (refinedMixin is InterfaceType) {
              mixin = refinedMixin;
            }
          }
        }
        _mixins.add(mixin);
        if (supertypesForMixinInference != null) {
          ClassElementImpl.collectAllSupertypes(
              supertypesForMixinInference, mixin, type);
        }
      }
    }
    return _mixins;
  }

  @override
  String get name => _unlinkedClass.name;

  @override
  AnalysisSession get session => enclosingUnit.session;

  @override
  List<InterfaceType> get superclassConstraints {
    if (_superclassConstraints == null) {
      if (isMixin) {
        _superclassConstraints = _unlinkedClass.superclassConstraints
            .map(_computeInterfaceType)
            .toList();
        if (_superclassConstraints.isEmpty) {
          _superclassConstraints = [
            enclosingElement.enclosingElement._linker.typeProvider.objectType
          ];
        }
      } else {
        _superclassConstraints = const <InterfaceType>[];
      }
    }
    return _superclassConstraints;
  }

  @override
  InterfaceType get supertype {
    if (isObject) {
      return null;
    }
    return _supertype ??= _computeInterfaceType(_unlinkedClass.supertype);
  }

  @override
  InterfaceType get type =>
      _type ??= buildType((int i) => typeParameterTypes[i], null);

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedClass.typeParameters;

  @override
  ConstructorElementForLink get unnamedConstructor {
    if (!_unnamedConstructorComputed) {
      for (ConstructorElementForLink constructor in constructors) {
        if (constructor.name.isEmpty) {
          _unnamedConstructor = constructor;
          break;
        }
      }
      _unnamedConstructorComputed = true;
    }
    return _unnamedConstructor;
  }

  @override
  int get version => 0;

  @override
  int get _notSimplyBoundedSlot => _unlinkedClass.notSimplyBoundedSlot;

  @override
  List<EntityRef> get _rhsTypesForSimplyBoundable => const [];

  @override
  List<UnlinkedTypeParam> get _typeParametersForSimplyBoundable {
    return _unlinkedClass.typeParameters;
  }

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    int numTypeParameters = _unlinkedClass.typeParameters.length;
    if (numTypeParameters != 0) {
      List<DartType> typeArguments =
          new List<DartType>.generate(numTypeParameters, getTypeArgument);
      if (typeArguments.contains(null)) {
        return context.typeSystem.instantiateToBounds(this.type);
      } else {
        return new InterfaceTypeImpl.elementWithNameAndArgs(
            this, name, () => typeArguments);
      }
    } else {
      return _type ??= new InterfaceTypeImpl(this);
    }
  }

  @override
  ConstructorElement getNamedConstructor(String name) =>
      ClassElementImpl.getNamedConstructorFromList(name, constructors);

  @override
  PropertyAccessorElement getSetter(String setterName) =>
      AbstractClassElementImpl.getSetterFromAccessors(setterName, accessors);

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    // Force mixins to be inferred by calling this.mixins.  We don't need the
    // return value from the getter; we just need it to execute and record the
    // mixin inference results as a side effect.
    this.mixins;

    _linkSimplyBoundable();

    for (ConstructorElementForLink constructorElement in constructors) {
      constructorElement.link(compilationUnit);
    }
    for (MethodElementForLink methodElement in methods) {
      methodElement.link(compilationUnit);
    }
    for (PropertyAccessorElementForLink propertyAccessorElement in accessors) {
      propertyAccessorElement.link(compilationUnit);
    }
    for (FieldElementForLink_ClassField fieldElement in fields) {
      fieldElement.link(compilationUnit);
    }
  }

  @override
  String toString() => '$enclosingElement.$name';

  /// Convert [typeRef] into an [InterfaceType].
  InterfaceType _computeInterfaceType(EntityRef typeRef) {
    if (typeRef != null) {
      DartType type = enclosingElement.resolveTypeRef(this, typeRef);
      if (type is InterfaceType && !type.element.isEnum) {
        return type;
      }
      // In the event that the `typeRef` isn't an interface type (which may
      // happen in the event of erroneous code) just fall through and pretend
      // the supertype is `Object`.
    }
    return enclosingElement.enclosingElement._linker.typeProvider.objectType;
  }

  InterfaceType _findInterfaceTypeForElement(
      ClassElement element, List<InterfaceType> interfaceTypes) {
    for (var interfaceType in interfaceTypes) {
      if (interfaceType.element == element) return interfaceType;
    }
    return null;
  }

  List<InterfaceType> _findInterfaceTypesForConstraints(
      List<InterfaceType> constraints, List<InterfaceType> interfaceTypes) {
    var result = <InterfaceType>[];
    for (var constraint in constraints) {
      var interfaceType =
          _findInterfaceTypeForElement(constraint.element, interfaceTypes);
      if (interfaceType == null) {
        // No matching interface type found, so inference fails.
        return null;
      }
      result.add(interfaceType);
    }
    return result;
  }
}

/// Element representing an enum resynthesized from a summary during
/// linking.
class ClassElementForLink_Enum extends ClassElementForLink
    implements EnumElementImpl {
  /// The unlinked representation of the enum in the summary.
  final UnlinkedEnum _unlinkedEnum;

  InterfaceType _type;
  List<FieldElementForLink> _fields;
  List<PropertyAccessorElementForLink> _accessors;
  DartType _valuesType;

  ClassElementForLink_Enum(
      CompilationUnitElementForLink enclosingElement, this._unlinkedEnum)
      : super(enclosingElement);

  @override
  List<PropertyAccessorElementForLink> get accessors {
    if (_accessors == null) {
      _accessors = <PropertyAccessorElementForLink>[];
      for (FieldElementForLink field in fields) {
        _accessors.add(field.getter);
      }
    }
    return _accessors;
  }

  @override
  List<ConstructorElementForLink> get constructors => const [];

  @override
  String get displayName => _unlinkedEnum.name;

  @override
  List<FieldElementForLink> get fields {
    if (_fields == null) {
      _fields = <FieldElementForLink>[];
      _fields.add(new FieldElementForLink_EnumField_values(this));
      for (UnlinkedEnumValue value in _unlinkedEnum.values) {
        _fields.add(new FieldElementForLink_EnumField_value(this, value));
      }
      _fields.add(new FieldElementForLink_EnumField_index(this));
    }
    return _fields;
  }

  @override
  List<InterfaceType> get interfaces => const [];

  @override
  bool get isAbstract => false;

  @override
  bool get isEnum => true;

  @override
  bool get isMixin => false;

  @override
  bool get isObject => false;

  @override
  List<MethodElementForLink> get methods => const [];

  @override
  List<InterfaceType> get mixins => const [];

  @override
  String get name => _unlinkedEnum.name;

  @override
  List<InterfaceType> get superclassConstraints => const [];

  @override
  InterfaceType get supertype => library._linker.typeProvider.objectType;

  @override
  InterfaceType get type => _type ??= new InterfaceTypeImpl(this);

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  ConstructorElementForLink get unnamedConstructor => null;

  /// Get the type of the enum's static member `values`.
  DartType get valuesType =>
      _valuesType ??= library._linker.typeProvider.listType.instantiate([type]);

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      type;

  @override
  ConstructorElement getNamedConstructor(String name) => null;

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {}

  @override
  String toString() => '$enclosingElement.$name';
}

/// Element representing a compilation unit resynthesized from a
/// summary during linking.
abstract class CompilationUnitElementForLink
    implements CompilationUnitElementImpl, ResynthesizerContext {
  final _UnitResynthesizer _unitResynthesizer;

  /// The unlinked representation of the compilation unit in the
  /// summary.
  final UnlinkedUnit _unlinkedUnit;

  /// For each entry in [UnlinkedUnit.references], the element referred
  /// to by the reference, or `null` if it hasn't been located yet.
  final List<_ReferenceInfo> _references;

  /// The absolute URI of this compilation unit.
  final String _absoluteUri;

  List<ClassElementForLink_Class> _mixins;
  List<ClassElementForLink_Class> _types;
  Map<String, ReferenceableElementForLink> _containedNames;
  List<TopLevelVariableElementForLink> _topLevelVariables;
  List<ClassElementForLink_Enum> _enums;
  List<TopLevelFunctionElementForLink> _functions;
  List<PropertyAccessorElementForLink> _accessors;
  List<FunctionTypeAliasElementForLink> _functionTypeAliases;

  /// Index of this unit in the list of units in the enclosing library.
  final int unitNum;

  @override
  final Source source;

  /// If non-null, the AST for the compilation unit; this is used to obtain
  /// initializer expressions for type inference.
  final CompilationUnit _astForInference;

  CompilationUnitElementForLink(UnlinkedUnit unlinkedUnit, this.unitNum,
      int numReferences, this._absoluteUri, this._astForInference)
      : _references = new List<_ReferenceInfo>(numReferences),
        _unlinkedUnit = unlinkedUnit,
        source = new InSummarySource(Uri.parse(_absoluteUri), null),
        _unitResynthesizer = new _UnitResynthesizer() {
    _unitResynthesizer._unit = this;
  }

  @override
  List<PropertyAccessorElementForLink> get accessors {
    if (_accessors == null) {
      _accessors = <PropertyAccessorElementForLink>[];
      Map<String, SyntheticVariableElementForLink> syntheticVariables =
          <String, SyntheticVariableElementForLink>{};
      for (UnlinkedExecutable unlinkedExecutable in _unlinkedUnit.executables) {
        if (unlinkedExecutable.kind == UnlinkedExecutableKind.getter ||
            unlinkedExecutable.kind == UnlinkedExecutableKind.setter) {
          String name = unlinkedExecutable.name;
          if (unlinkedExecutable.kind == UnlinkedExecutableKind.setter) {
            assert(name.endsWith('='));
            name = name.substring(0, name.length - 1);
          }
          SyntheticVariableElementForLink syntheticVariable = syntheticVariables
              .putIfAbsent(name, () => new SyntheticVariableElementForLink());
          PropertyAccessorElementForLink_Executable accessor =
              new PropertyAccessorElementForLink_Executable(
                  this, null, unlinkedExecutable, syntheticVariable);
          _accessors.add(accessor);
          if (unlinkedExecutable.kind == UnlinkedExecutableKind.getter) {
            syntheticVariable._getter = accessor;
          } else {
            syntheticVariable._setter = accessor;
          }
        }
      }
      for (TopLevelVariableElementForLink variable in topLevelVariables) {
        _accessors.add(variable.getter);
        if (!variable.isConst && !variable.isFinal) {
          _accessors.add(variable.setter);
        }
      }
    }
    return _accessors;
  }

  @override
  ContextForLink get context => library.context;

  @override
  LibraryElementForLink get enclosingElement;

  @override
  List<ClassElementForLink_Enum> get enums {
    if (_enums == null) {
      _enums = <ClassElementForLink_Enum>[];
      for (UnlinkedEnum unlinkedEnum in _unlinkedUnit.enums) {
        _enums.add(new ClassElementForLink_Enum(this, unlinkedEnum));
      }
    }
    return _enums;
  }

  @override
  List<TopLevelFunctionElementForLink> get functions {
    if (_functions == null) {
      _functions = <TopLevelFunctionElementForLink>[];
      for (UnlinkedExecutable executable in _unlinkedUnit.executables) {
        if (executable.kind == UnlinkedExecutableKind.functionOrMethod) {
          _functions.add(new TopLevelFunctionElementForLink(this, executable));
        }
      }
    }
    return _functions;
  }

  @override
  List<FunctionTypeAliasElementForLink> get functionTypeAliases =>
      _functionTypeAliases ??= _unlinkedUnit.typedefs.map((UnlinkedTypedef t) {
        if (t.style == TypedefStyle.functionType) {
          return new FunctionTypeAliasElementForLink(this, t);
        } else if (t.style == TypedefStyle.genericFunctionType) {
          return new GenericTypeAliasElementForLink(this, t);
        } else {
          throw new StateError('Unhandled style of typedef: ${t.style}');
        }
      }).toList();

  @override
  String get identifier => _absoluteUri;

  /// Indicates whether this compilation element is part of the build unit
  /// currently being linked.
  bool get isInBuildUnit;

  /// Determine whether type inference is complete in this compilation unit.
  bool get isTypeInferenceComplete {
    LibraryCycleForLink libraryCycleForLink = library.libraryCycleForLink;
    if (libraryCycleForLink == null) {
      return true;
    } else {
      return libraryCycleForLink._node.isEvaluated;
    }
  }

  @override
  LibraryElementForLink get library => enclosingElement;

  @override
  List<ClassElementForLink_Class> get mixins {
    if (_mixins == null) {
      List<MixinDeclaration> declarationsForInference;
      if (_astForInference != null) {
        declarationsForInference = [];
        for (var declaration in _astForInference.declarations) {
          if (declaration is MixinDeclaration) {
            declarationsForInference.add(declaration);
          }
        }
        assert(declarationsForInference.length == _unlinkedUnit.mixins.length);
      }
      _mixins = <ClassElementForLink_Class>[];
      for (int i = 0; i < _unlinkedUnit.mixins.length; i++) {
        var unlinkedClass = _unlinkedUnit.mixins[i];
        _mixins.add(new ClassElementForLink_Class(
            this,
            unlinkedClass,
            true,
            declarationsForInference == null
                ? null
                : declarationsForInference[i]));
      }
    }
    return _mixins;
  }

  @override
  ResynthesizerContext get resynthesizerContext => this;

  @override
  AnalysisSession get session => library.session;

  @override
  List<TopLevelVariableElementForLink> get topLevelVariables {
    if (_topLevelVariables == null) {
      List<Expression> initializerExpressionsForInference;
      if (_astForInference != null) {
        initializerExpressionsForInference = [];
        for (var declaration in _astForInference.declarations) {
          if (declaration is TopLevelVariableDeclaration) {
            for (var variable in declaration.variables.variables) {
              initializerExpressionsForInference.add(variable.initializer);
            }
          }
        }
        assert(initializerExpressionsForInference.length ==
            _unlinkedUnit.variables.length);
      }
      _topLevelVariables = <TopLevelVariableElementForLink>[];
      for (int i = 0; i < _unlinkedUnit.variables.length; i++) {
        var unlinkedVariable = _unlinkedUnit.variables[i];
        _topLevelVariables.add(new TopLevelVariableElementForLink(
            this,
            unlinkedVariable,
            initializerExpressionsForInference == null
                ? null
                : initializerExpressionsForInference[i]));
      }
    }
    return _topLevelVariables;
  }

  @override
  List<ClassElementForLink_Class> get types {
    if (_types == null) {
      List<ClassDeclaration> declarationsForInference;
      if (_astForInference != null) {
        declarationsForInference = [];
        for (var declaration in _astForInference.declarations) {
          if (declaration is ClassDeclaration) {
            declarationsForInference.add(declaration);
          } else if (declaration is ClassTypeAlias) {
            declarationsForInference.add(null);
          }
        }
        assert(declarationsForInference.length == _unlinkedUnit.classes.length);
      }
      _types = <ClassElementForLink_Class>[];
      for (int i = 0; i < _unlinkedUnit.classes.length; i++) {
        var unlinkedClass = _unlinkedUnit.classes[i];
        _types.add(new ClassElementForLink_Class(
            this,
            unlinkedClass,
            false,
            declarationsForInference == null
                ? null
                : declarationsForInference[i]));
      }
    }
    return _types;
  }

  /// The linked representation of the compilation unit in the summary.
  LinkedUnit get _linkedUnit;

  /// Search the unit for a top level element with the given [name].
  /// If no name is found, return the singleton instance of
  /// [UndefinedElementForLink].
  ReferenceableElementForLink getContainedName(name) {
    if (_containedNames == null) {
      _containedNames = <String, ReferenceableElementForLink>{};
      // TODO(paulberry): what's the correct way to handle name conflicts?
      for (ClassElementForLink_Class type in types) {
        _containedNames[type.name] = type;
      }
      for (ClassElementForLink_Class mixin in mixins) {
        _containedNames[mixin.name] = mixin;
      }
      for (ClassElementForLink_Enum enm in enums) {
        _containedNames[enm.name] = enm;
      }
      for (TopLevelFunctionElementForLink function in functions) {
        _containedNames[function.name] = function;
      }
      for (PropertyAccessorElementForLink accessor in accessors) {
        _containedNames[accessor.name] = accessor;
      }
      for (FunctionTypeAliasElementForLink functionTypeAlias
          in functionTypeAliases) {
        _containedNames[functionTypeAlias.name] = functionTypeAlias;
      }
      // TODO(paulberry): fill in other top level entities (typedefs
      // and executables).
    }
    return _containedNames.putIfAbsent(
        name, () => UndefinedElementForLink.instance);
  }

  /// Compute the type referred to by the given linked type [slot] (interpreted
  /// in [context]).  If there is no inferred type in the
  /// given slot, `dynamic` is returned.
  DartType getLinkedType(ElementImpl context, int slot);

  @override
  ClassElement getType(String className) =>
      CompilationUnitElementImpl.getTypeFromTypes(className, types);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Return the class element for the constructor referred to by the given
  /// [index] in [UnlinkedUnit.references].  If the reference is unresolved,
  /// return [UndefinedElementForLink.instance].
  ReferenceableElementForLink resolveConstructorClassRef(int index) {
    LinkedReference linkedReference = _linkedUnit.references[index];
    if (linkedReference.kind == ReferenceKind.classOrEnum) {
      return resolveRef(index);
    }
    if (index < _unlinkedUnit.references.length) {
      UnlinkedReference unlinkedReference = _unlinkedUnit.references[index];
      return resolveRef(unlinkedReference.prefixReference);
    }
    return UndefinedElementForLink.instance;
  }

  /// Return the element referred to by the given [index] in
  /// [UnlinkedUnit.references].  If the reference is unresolved,
  /// return [UndefinedElementForLink.instance].
  ReferenceableElementForLink resolveRef(int index) =>
      resolveRefToInfo(index).element;

  _ReferenceInfo resolveRefToInfo(int index) {
    if (_references[index] == null) {
      UnlinkedReference unlinkedReference =
          index < _unlinkedUnit.references.length
              ? _unlinkedUnit.references[index]
              : null;
      LinkedReference linkedReference = _linkedUnit.references[index];
      String name = unlinkedReference == null
          ? linkedReference.name
          : unlinkedReference.name;
      int containingReference = unlinkedReference == null
          ? linkedReference.containingReference
          : unlinkedReference.prefixReference;
      _ReferenceInfo enclosingInfo = containingReference != 0
          ? resolveRefToInfo(containingReference)
          : null;
      ReferenceableElementForLink element;
      if (containingReference != 0 &&
          _linkedUnit.references[containingReference].kind !=
              ReferenceKind.prefix) {
        element = enclosingInfo.element.getContainedName(name);
      } else if (linkedReference.dependency == 0) {
        if (linkedReference.kind == ReferenceKind.unresolved) {
          element = UndefinedElementForLink.instance;
        } else if (name == 'void') {
          element = enclosingElement._linker.voidElement;
        } else if (name == '*bottom*') {
          element = enclosingElement._linker.bottomElement;
        } else if (name == 'dynamic') {
          element = enclosingElement._linker.dynamicElement;
        } else {
          element = enclosingElement.getContainedName(name);
        }
      } else {
        LibraryElementForLink dependency =
            enclosingElement.buildImportedLibrary(linkedReference.dependency);
        element = dependency.getContainedName(name);
      }
      _references[index] = new _ReferenceInfo(
          enclosingInfo, element, name, linkedReference.numTypeParameters != 0);
    }
    return _references[index];
  }

  @override
  DartType resolveTypeRef(ElementImpl context, EntityRef entity,
      {bool defaultVoid: false,
      bool instantiateToBoundsAllowed: true,
      bool declaredType: false}) {
    if (entity == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return DynamicTypeImpl.instance;
      }
    }
    if (entity.paramReference != 0) {
      return context.typeParameterContext
          .getTypeParameterType(entity.paramReference);
    } else if (entity.entityKind == EntityRefKind.genericFunctionType) {
      return new GenericFunctionTypeElementForLink(
              this,
              context,
              entity.typeParameters,
              entity.syntheticReturnType,
              entity.syntheticParams)
          .type;
    } else if (entity.syntheticReturnType != null) {
      FunctionElementImpl element =
          new FunctionElementForLink_Synthetic(this, context, entity);
      return element.type;
    } else if (entity.implicitFunctionTypeIndices.isNotEmpty) {
      DartType type = resolveRef(entity.reference).asStaticType;
      for (int index in entity.implicitFunctionTypeIndices) {
        type = (type as FunctionType).parameters[index].type;
      }
      return type;
    } else {
      ReferenceableElementForLink element = resolveRef(entity.reference);
      bool implicitTypeArgumentsInUse = false;

      DartType getTypeArgument(int i) {
        if (i < entity.typeArguments.length) {
          return resolveTypeRef(context, entity.typeArguments[i]);
        } else {
          implicitTypeArgumentsInUse = true;
          if (!instantiateToBoundsAllowed) {
            // Do not allow buildType to instantiate the bounds; force dynamic.
            return DynamicTypeImpl.instance;
          } else {
            return null;
          }
        }
      }

      var type = element.buildType(
          getTypeArgument, entity.implicitFunctionTypeIndices);
      if (implicitTypeArgumentsInUse) {
        _typesWithImplicitArguments[type] = true;
      }
      return type;
    }
  }

  @override
  String toString() => enclosingElement.toString();
}

/// Element representing a compilation unit which is part of the build
/// unit being linked.
class CompilationUnitElementInBuildUnit extends CompilationUnitElementForLink {
  @override
  final LinkedUnitBuilder _linkedUnit;

  @override
  final LibraryElementInBuildUnit enclosingElement;

  CompilationUnitElementInBuildUnit(
      this.enclosingElement,
      UnlinkedUnit unlinkedUnit,
      this._linkedUnit,
      int unitNum,
      String absoluteUri,
      CompilationUnit astForInference)
      : super(unlinkedUnit, unitNum, unlinkedUnit.references.length,
            absoluteUri, astForInference);

  @override
  bool get isInBuildUnit => true;

  @override
  LibraryElementInBuildUnit get library => enclosingElement;

  /// If this compilation unit already has a reference in its references table
  /// matching [dependency], [name], [numTypeParameters], [unitNum],
  /// [containingReference], and [kind], return its index.  Otherwise add a new
  /// reference to the table and return its index.
  int addRawReference(String name,
      {int dependency: 0,
      int numTypeParameters: 0,
      int unitNum: 0,
      int containingReference: 0,
      ReferenceKind kind: ReferenceKind.classOrEnum}) {
    List<LinkedReferenceBuilder> linkedReferences = _linkedUnit.references;
    List<UnlinkedReference> unlinkedReferences = _unlinkedUnit.references;
    for (int i = 0; i < linkedReferences.length; i++) {
      LinkedReferenceBuilder linkedReference = linkedReferences[i];
      int candidateContainingReference = i < unlinkedReferences.length
          ? unlinkedReferences[i].prefixReference
          : linkedReference.containingReference;
      if (candidateContainingReference != 0 &&
          linkedReferences[candidateContainingReference].kind ==
              ReferenceKind.prefix) {
        // We don't need to match containing references when they are prefixes,
        // since the relevant information is in linkedReference.dependency.
        candidateContainingReference = 0;
      }
      if (linkedReference.dependency == dependency &&
          (i < unlinkedReferences.length
                  ? unlinkedReferences[i].name
                  : linkedReference.name) ==
              name &&
          linkedReference.numTypeParameters == numTypeParameters &&
          linkedReference.unit == unitNum &&
          candidateContainingReference == containingReference &&
          linkedReference.kind == kind) {
        return i;
      }
    }
    int result = linkedReferences.length;
    linkedReferences.add(new LinkedReferenceBuilder(
        dependency: dependency,
        name: name,
        numTypeParameters: numTypeParameters,
        unit: unitNum,
        containingReference: containingReference,
        kind: kind));
    return result;
  }

  /// If this compilation unit already has a reference in its references table
  /// to [element], return its index.  Otherwise add a new reference to the
  /// table and return its index.
  int addReference(Element element) {
    if (element is ClassElementForLink) {
      return addRawReference(element.name,
          dependency: library.addDependency(element.library),
          numTypeParameters: element.typeParameters.length,
          unitNum: element.enclosingElement.unitNum);
    } else if (element is FunctionTypeAliasElementForLink) {
      return addRawReference(element.name,
          dependency: library.addDependency(element.library),
          numTypeParameters: element.typeParameters.length,
          unitNum: element.enclosingElement.unitNum,
          kind: ReferenceKind.typedef);
    } else if (element is ExecutableElementForLink_NonLocal) {
      ClassElementForLink_Class enclosingClass = element.enclosingClass;
      ReferenceKind kind;
      switch (element.serializedExecutable.kind) {
        case UnlinkedExecutableKind.functionOrMethod:
          kind = enclosingClass != null
              ? ReferenceKind.method
              : ReferenceKind.topLevelFunction;
          break;
        case UnlinkedExecutableKind.setter:
          kind = ReferenceKind.propertyAccessor;
          break;
        default:
          // TODO(paulberry): implement other cases as necessary
          throw new UnimplementedError('${element.serializedExecutable.kind}');
      }
      if (enclosingClass == null) {
        return addRawReference(element.name,
            numTypeParameters: element.typeParameters.length,
            dependency:
                library.addDependency(element.library as LibraryElementForLink),
            unitNum: element.compilationUnit.unitNum,
            kind: kind);
      } else {
        return addRawReference(element.name,
            numTypeParameters: element.typeParameters.length,
            containingReference: addReference(enclosingClass),
            kind: kind);
      }
    } else if (element is FunctionElementForLink_Initializer) {
      return addRawReference('',
          containingReference: addReference(element.enclosingElement),
          kind: ReferenceKind.function);
    } else if (element is TopLevelVariableElementForLink) {
      return addRawReference(element.name,
          dependency: library.addDependency(element.library),
          unitNum: element.compilationUnit.unitNum,
          kind: ReferenceKind.topLevelPropertyAccessor);
    } else if (element is FieldElementForLink_ClassField) {
      ClassElementForLink_Class enclosingClass = element.enclosingElement;
      // Note: even if the class has type parameters, we don't need to set
      // numTypeParameters because numTypeParameters does not count type
      // parameters of parent elements (see
      // [LinkedReference.numTypeParameters]).
      return addRawReference(element.name,
          containingReference: addReference(enclosingClass),
          kind: ReferenceKind.propertyAccessor);
    }
    // TODO(paulberry): implement other cases
    throw new UnimplementedError('${element.runtimeType}');
  }

  @override
  DartType getLinkedType(ElementImpl context, int slot) {
    // This method should only be called on compilation units that come from
    // dependencies, never on compilation units that are part of the current
    // build unit.
    throw new StateError(
        'Linker tried to access linked type from current build unit');
  }

  /// Perform type inference and const cycle detection on this
  /// compilation unit.
  void link() {
    new InstanceMemberInferrer(
      library._linker.typeProvider,
      library._linker.inheritanceManager,
    ).inferCompilationUnit(this);
    for (TopLevelVariableElementForLink variable in topLevelVariables) {
      variable.link(this);
    }
    for (ClassElementForLink classElement in types) {
      classElement.link(this);
    }
    for (ClassElementForLink classElement in mixins) {
      classElement.link(this);
    }
    for (var functionTypeAlias in functionTypeAliases) {
      functionTypeAlias.link(this);
    }
  }

  /// Throw away any information stored in the summary by a previous call to
  /// [link].
  void unlink() {
    _linkedUnit.constCycles.clear();
    _linkedUnit.parametersInheritingCovariant.clear();
    _linkedUnit.references.length = _unlinkedUnit.references.length;
    _linkedUnit.types.clear();
    _linkedUnit.notSimplyBounded.clear();
  }

  /// Store the fact that the given [slot] represents a constant constructor
  /// that is part of a cycle.
  void _storeConstCycle(int slot) {
    _linkedUnit.constCycles.add(slot);
  }

  /// Store the fact that the given [slot] represents a parameter that inherits
  /// `@covariant` behavior.
  void _storeInheritsCovariant(int slot) {
    _linkedUnit.parametersInheritingCovariant.add(slot);
  }

  /// Store the given [linkedType] in the given [slot] of the this compilation
  /// unit's linked type list.
  void _storeLinkedType(int slot, DartType linkedType,
      TypeParameterSerializationContext typeParameterContext) {
    if (slot != 0) {
      if (linkedType != null && !linkedType.isDynamic) {
        _linkedUnit.types.add(_createLinkedType(
            linkedType, this, typeParameterContext,
            slot: slot));
      }
    }
  }

  /// Store the given error [error] in the given [slot].
  void _storeLinkedTypeError(int slot, TopLevelInferenceErrorBuilder error) {
    if (slot != 0) {
      if (error != null) {
        error.slot = slot;
        _linkedUnit.topLevelInferenceErrors.add(error);
      }
    }
  }
}

/// Element representing a compilation unit which is depended upon
/// (either directly or indirectly) by the build unit being linked.
///
/// TODO(paulberry): ensure that inferred types in dependencies are properly
/// resynthesized.
class CompilationUnitElementInDependency extends CompilationUnitElementForLink {
  @override
  final LinkedUnit _linkedUnit;

  /// Set of slot ids corresponding to parameters that inherit `covariant`.
  Set<int> parametersInheritingCovariant;

  List<EntityRef> _linkedTypeRefs;

  @override
  final LibraryElementInDependency enclosingElement;

  CompilationUnitElementInDependency(
      this.enclosingElement,
      UnlinkedUnit unlinkedUnit,
      LinkedUnit linkedUnit,
      int unitNum,
      String absoluteUri)
      : _linkedUnit = linkedUnit,
        super(unlinkedUnit, unitNum, linkedUnit.references.length, absoluteUri,
            null) {
    parametersInheritingCovariant =
        _linkedUnit.parametersInheritingCovariant.toSet();
    // Make one pass through the linked types to determine the lengths for
    // _linkedTypeRefs and _linkedTypes.  TODO(paulberry): add an int to the
    // summary to make this unnecessary.
    int maxLinkedTypeSlot = 0;
    for (EntityRef ref in _linkedUnit.types) {
      if (ref.slot > maxLinkedTypeSlot) {
        maxLinkedTypeSlot = ref.slot;
      }
    }
    // Initialize _linkedTypeRefs.
    _linkedTypeRefs = new List<EntityRef>(maxLinkedTypeSlot + 1);
    for (EntityRef ref in _linkedUnit.types) {
      _linkedTypeRefs[ref.slot] = ref;
    }
  }

  @override
  bool get isInBuildUnit => false;

  @override
  DartType getLinkedType(ElementImpl context, int slot) {
    if (slot < _linkedTypeRefs.length) {
      return resolveTypeRef(context, _linkedTypeRefs[slot]);
    } else {
      return DynamicTypeImpl.instance;
    }
  }
}

/// Instance of [ConstNode] representing a constant constructor.
class ConstConstructorNode extends ConstNode {
  /// The [ConstructorElement] to which this node refers.
  final ConstructorElementForLink constructorElement;

  /// Once this node has been evaluated, indicates whether the
  /// constructor is free of constant evaluation cycles.
  bool isCycleFree = false;

  ConstConstructorNode(this.constructorElement);

  @override
  List<ConstNode> computeDependencies() {
    List<ConstNode> dependencies = <ConstNode>[];
    void safeAddDependency(ConstNode target) {
      if (target != null) {
        dependencies.add(target);
      }
    }

    UnlinkedExecutable unlinkedExecutable =
        constructorElement.serializedExecutable;
    ClassElementForLink_Class enclosingClass =
        constructorElement.enclosingElement;
    ConstructorElementForLink redirectedConstructor =
        _getFactoryRedirectedConstructor();
    if (redirectedConstructor != null) {
      if (redirectedConstructor._constNode != null) {
        safeAddDependency(redirectedConstructor._constNode);
      }
    } else if (unlinkedExecutable.isFactory) {
      // Factory constructor, but getConstRedirectedConstructor returned
      // null.  This can happen if we're visiting one of the special external
      // const factory constructors in the SDK, or if the code contains
      // errors (such as delegating to a non-const constructor, or delegating
      // to a constructor that can't be resolved).  In any of these cases,
      // we'll evaluate calls to this constructor without having to refer to
      // any other constants.  So we don't need to report any dependencies.
    } else {
      ClassElementForLink superClass = enclosingClass.supertype?.element;
      bool defaultSuperInvocationNeeded = true;
      for (UnlinkedConstructorInitializer constructorInitializer
          in constructorElement.serializedExecutable.constantInitializers) {
        if (constructorInitializer.kind ==
            UnlinkedConstructorInitializerKind.superInvocation) {
          defaultSuperInvocationNeeded = false;
          if (superClass != null && !superClass.isObject) {
            ConstructorElementForLink constructor = superClass
                .getContainedName(constructorInitializer.name)
                .asConstructor;
            safeAddDependency(constructor?._constNode);
          }
        } else if (constructorInitializer.kind ==
            UnlinkedConstructorInitializerKind.thisInvocation) {
          defaultSuperInvocationNeeded = false;
          ConstructorElementForLink constructor = constructorElement
              .enclosingClass
              .getContainedName(constructorInitializer.name)
              .asConstructor;
          safeAddDependency(constructor?._constNode);
        }
        CompilationUnitElementForLink compilationUnit =
            constructorElement.enclosingElement.enclosingElement;
        collectDependencies(
            dependencies, constructorInitializer.expression, compilationUnit);
        for (UnlinkedExpr unlinkedConst in constructorInitializer.arguments) {
          collectDependencies(dependencies, unlinkedConst, compilationUnit);
        }
      }

      if (defaultSuperInvocationNeeded) {
        // No explicit superconstructor invocation found, so we need to
        // manually insert a reference to the implicit superconstructor.
        if (superClass != null && !superClass.isObject) {
          ConstructorElementForLink unnamedConstructor =
              superClass.unnamedConstructor;
          safeAddDependency(unnamedConstructor?._constNode);
        }
      }
      for (FieldElementForLink field in enclosingClass.fields) {
        // Note: non-static const isn't allowed but we handle it anyway so
        // that we won't be confused by incorrect code.
        if ((field.isFinal || field.isConst) && !field.isStatic) {
          safeAddDependency(field.getter.asConstVariable);
        }
      }
      for (ParameterElementForLink parameterElement
          in constructorElement.parameters) {
        safeAddDependency(parameterElement._constNode);
      }
    }
    return dependencies;
  }

  /// If [constructorElement] redirects to another constructor via a factory
  /// redirect, return the constructor it redirects to.
  ConstructorElementForLink _getFactoryRedirectedConstructor() {
    EntityRef redirectedConstructor =
        constructorElement.serializedExecutable.redirectedConstructor;
    if (redirectedConstructor != null) {
      return constructorElement.compilationUnit
          .resolveRef(redirectedConstructor.reference)
          .asConstructor;
    } else {
      return null;
    }
  }
}

/// Specialization of [DependencyWalker] for detecting constant
/// evaluation cycles.
class ConstDependencyWalker extends DependencyWalker<ConstNode> {
  @override
  void evaluate(ConstNode v) {
    if (v is ConstConstructorNode) {
      v.isCycleFree = true;
    }
    v.isEvaluated = true;
  }

  @override
  void evaluateScc(List<ConstNode> scc) {
    for (ConstNode v in scc) {
      if (v is ConstConstructorNode) {
        v.isCycleFree = false;
      }
      v.isEvaluated = true;
    }
  }
}

/// Specialization of [Node] used to construct the constant evaluation
/// dependency graph.
abstract class ConstNode extends Node<ConstNode> {
  @override
  bool isEvaluated = false;

  /// Collect the dependencies in [unlinkedConst] (which should be
  /// interpreted relative to [compilationUnit]) and store them in
  /// [dependencies].
  void collectDependencies(
      List<ConstNode> dependencies,
      UnlinkedExpr unlinkedConst,
      CompilationUnitElementForLink compilationUnit) {
    if (unlinkedConst == null) {
      return;
    }
    int refPtr = 0;
    int intPtr = 0;
    for (UnlinkedExprOperation operation in unlinkedConst.operations) {
      switch (operation) {
        case UnlinkedExprOperation.pushInt:
          intPtr++;
          break;
        case UnlinkedExprOperation.pushLongInt:
          int numInts = unlinkedConst.ints[intPtr++];
          intPtr += numInts;
          break;
        case UnlinkedExprOperation.concatenate:
          intPtr++;
          break;
        case UnlinkedExprOperation.pushReference:
          EntityRef ref = unlinkedConst.references[refPtr++];
          ConstVariableNode variable =
              compilationUnit.resolveRef(ref.reference).asConstVariable;
          if (variable != null) {
            dependencies.add(variable);
          }
          break;
        case UnlinkedExprOperation.makeUntypedList:
        case UnlinkedExprOperation.makeUntypedMap:
        case UnlinkedExprOperation.makeUntypedSet:
        case UnlinkedExprOperation.makeUntypedSetOrMap:
        case UnlinkedExprOperation.forParts:
        case UnlinkedExprOperation.variableDeclaration:
        case UnlinkedExprOperation.forInitializerDeclarationsUntyped:
          intPtr++;
          break;
        case UnlinkedExprOperation.assignToRef:
        case UnlinkedExprOperation.forEachPartsWithTypedDeclaration:
          refPtr++;
          break;
        case UnlinkedExprOperation.invokeMethodRef:
          EntityRef ref = unlinkedConst.references[refPtr++];
          ConstVariableNode variable =
              compilationUnit.resolveRef(ref.reference).asConstVariable;
          if (variable != null) {
            dependencies.add(variable);
          }
          intPtr += 2;
          int numTypeArguments = unlinkedConst.ints[intPtr++];
          refPtr += numTypeArguments;
          break;
        case UnlinkedExprOperation.invokeMethod:
          intPtr += 2;
          int numTypeArguments = unlinkedConst.ints[intPtr++];
          refPtr += numTypeArguments;
          break;
        case UnlinkedExprOperation.makeTypedList:
        case UnlinkedExprOperation.makeTypedSet:
        case UnlinkedExprOperation.forInitializerDeclarationsTyped:
          refPtr++;
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedMap:
        case UnlinkedExprOperation.makeTypedMap2:
          refPtr += 2;
          intPtr++;
          break;
        case UnlinkedExprOperation.invokeConstructor:
          EntityRef ref = unlinkedConst.references[refPtr++];
          ConstructorElementForLink element =
              compilationUnit.resolveRef(ref.reference).asConstructor;
          if (element?._constNode != null) {
            dependencies.add(element._constNode);
          }
          intPtr += 2;
          break;
        case UnlinkedExprOperation.typeCast:
        case UnlinkedExprOperation.typeCheck:
          refPtr++;
          break;
        case UnlinkedExprOperation.pushLocalFunctionReference:
          intPtr += 2;
          break;
        default:
          break;
      }
    }
    assert(refPtr == unlinkedConst.references.length);
    assert(intPtr == unlinkedConst.ints.length);
  }
}

/// Instance of [ConstNode] representing a parameter with a default
/// value.
class ConstParameterNode extends ConstNode {
  /// The [ParameterElement] to which this node refers.
  final ParameterElementForLink parameterElement;

  ConstParameterNode(this.parameterElement);

  @override
  List<ConstNode> computeDependencies() {
    List<ConstNode> dependencies = <ConstNode>[];
    collectDependencies(
        dependencies,
        parameterElement.unlinkedParam.initializer?.bodyExpr,
        parameterElement.compilationUnit);
    return dependencies;
  }
}

/// Element representing a constructor resynthesized from a summary
/// during linking.
class ConstructorElementForLink extends ExecutableElementForLink_NonLocal
    with ReferenceableElementForLink
    implements ConstructorElementImpl {
  /// If this is a `const` constructor and the enclosing library is
  /// part of the build unit being linked, the constructor's node in
  /// the constant evaluation dependency graph.  Otherwise `null`.
  ConstConstructorNode _constNode;

  ConstructorElementForLink(ClassElementForLink_Class enclosingClass,
      UnlinkedExecutable unlinkedExecutable)
      : super(enclosingClass.enclosingElement, enclosingClass,
            unlinkedExecutable) {
    if (enclosingClass.enclosingElement.isInBuildUnit &&
        serializedExecutable != null &&
        serializedExecutable.constCycleSlot != 0) {
      _constNode = new ConstConstructorNode(this);
    }
  }

  @override
  ConstructorElementForLink get asConstructor => this;

  @override
  ClassElementImpl get enclosingElement => super.enclosingClass;

  @override
  String get identifier => name;

  @override
  bool get isConst => serializedExecutable.isConst;

  @override
  bool get isCycleFree {
    if (!_constNode.isEvaluated) {
      new ConstDependencyWalker().walk(_constNode);
    }
    return _constNode.isCycleFree;
  }

  @override
  DartType get returnType => enclosingElement.type;

  @override
  List<TypeParameterElement> get typeParameters => const [];

  /// Perform const cycle detection on this constructor.
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (_constNode != null && !isCycleFree) {
      compilationUnit._storeConstCycle(serializedExecutable.constCycleSlot);
    }
    // TODO(paulberry): call super.
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A synthetic constructor.
class ConstructorElementForLink_Synthetic extends ConstructorElementForLink {
  ConstructorElementForLink_Synthetic(
      ClassElementForLink_Class enclosingElement)
      : super(enclosingElement, null);

  @override
  String get name => '';

  @override
  List<ParameterElement> get parameters => const <ParameterElement>[];
}

/// Instance of [ConstNode] representing a constant field or constant
/// top level variable.
class ConstVariableNode extends ConstNode {
  /// The [FieldElement] or [TopLevelVariableElement] to which this
  /// node refers.
  final VariableElementForLink variableElement;

  ConstVariableNode(this.variableElement);

  @override
  List<ConstNode> computeDependencies() {
    List<ConstNode> dependencies = <ConstNode>[];
    collectDependencies(
        dependencies,
        variableElement.unlinkedVariable.initializer?.bodyExpr,
        variableElement.compilationUnit);
    return dependencies;
  }
}

/// Stub implementation of [AnalysisContext] which provides just those methods
/// needed during linking.
class ContextForLink implements AnalysisContext {
  final Linker _linker;

  ContextForLink(this._linker);

  @override
  AnalysisOptions get analysisOptions => _linker.analysisOptions;

  @override
  TypeProvider get typeProvider => _linker.typeProvider;

  @override
  TypeSystem get typeSystem => _linker.typeSystem;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * An instance of [DependencyWalker] contains the core algorithms for
 * walking a dependency graph and evaluating nodes in a safe order.
 */
abstract class DependencyWalker<NodeType extends Node<NodeType>> {
  /**
   * Called by [walk] to evaluate a single non-cyclical node, after
   * all that node's dependencies have been evaluated.
   */
  void evaluate(NodeType v);

  /**
   * Called by [walk] to evaluate a strongly connected component
   * containing one or more nodes.  All dependencies of the strongly
   * connected component have been evaluated.
   */
  void evaluateScc(List<NodeType> scc);

  /**
   * Walk the dependency graph starting at [startingPoint], finding
   * strongly connected components and evaluating them in a safe order
   * by calling [evaluate] and [evaluateScc].
   *
   * This is an implementation of Tarjan's strongly connected
   * components algorithm
   * (https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm).
   */
  void walk(NodeType startingPoint) {
    // TODO(paulberry): consider rewriting in a non-recursive way so
    // that long dependency chains don't cause stack overflow.

    // TODO(paulberry): in the event that an exception occurs during
    // the walk, restore the state of the [Node] data structures so
    // that further evaluation will be safe.

    // The index which will be assigned to the next node that is
    // freshly visited.
    int index = 1;

    // Stack of nodes which have been seen so far and whose strongly
    // connected component is still being determined.  Nodes are only
    // popped off the stack when they are evaluated, so sometimes the
    // stack contains nodes that were visited after the current node.
    List<NodeType> stack = <NodeType>[];

    void strongConnect(NodeType node) {
      bool hasTrivialCycle = false;

      // Assign the current node an index and add it to the stack.  We
      // haven't seen any of its dependencies yet, so set its lowLink
      // to its index, indicating that so far it is the only node in
      // its strongly connected component.
      node._index = node._lowLink = index++;
      stack.add(node);

      // Consider the node's dependencies one at a time.
      for (NodeType dependency in Node.getDependencies(node)) {
        // If the dependency has already been evaluated, it can't be
        // part of this node's strongly connected component, so we can
        // skip it.
        if (dependency.isEvaluated) {
          continue;
        }
        if (identical(node, dependency)) {
          // If a node includes itself as a dependency, there is no need to
          // explore the dependency further.
          hasTrivialCycle = true;
        } else if (dependency._index == 0) {
          // The dependency hasn't been seen yet, so recurse on it.
          strongConnect(dependency);
          // If the dependency's lowLink refers to a node that was
          // visited before the current node, that means that the
          // current node, the dependency, and the node referred to by
          // the dependency's lowLink are all part of the same
          // strongly connected component, so we need to update the
          // current node's lowLink accordingly.
          if (dependency._lowLink < node._lowLink) {
            node._lowLink = dependency._lowLink;
          }
        } else {
          // The dependency has already been seen, so it is part of
          // the current node's strongly connected component.  If it
          // was visited earlier than the current node's lowLink, then
          // it is a new addition to the current node's strongly
          // connected component, so we need to update the current
          // node's lowLink accordingly.
          if (dependency._index < node._lowLink) {
            node._lowLink = dependency._index;
          }
        }
      }

      // If the current node's lowLink is the same as its index, then
      // we have finished visiting a strongly connected component, so
      // pop the stack and evaluate it before moving on.
      if (node._lowLink == node._index) {
        // The strongly connected component has only one node.  If there is a
        // cycle, it's a trivial one.
        if (identical(stack.last, node)) {
          stack.removeLast();
          if (hasTrivialCycle) {
            evaluateScc(<NodeType>[node]);
          } else {
            evaluate(node);
          }
        } else {
          // There are multiple nodes in the strongly connected
          // component.
          List<NodeType> scc = <NodeType>[];
          while (true) {
            NodeType otherNode = stack.removeLast();
            scc.add(otherNode);
            if (identical(otherNode, node)) {
              break;
            }
          }
          evaluateScc(scc);
        }
      }
    }

    // Kick off the algorithm starting with the starting point.
    strongConnect(startingPoint);
  }
}

/// Base class for executable elements resynthesized from a summary during
/// linking.
abstract class ExecutableElementForLink
    with TypeParameterizedElementMixin, ParameterParentElementForLink
    implements ExecutableElementImpl {
  /// The unlinked representation of the method in the summary.
  final UnlinkedExecutable serializedExecutable;

  DartType _declaredReturnType;
  DartType _inferredReturnType;
  FunctionTypeImpl _type;
  String _name;
  String _displayName;

  final CompilationUnitElementForLink compilationUnit;

  ExecutableElementForLink(this.compilationUnit, this.serializedExecutable);

  @override
  ContextForLink get context => compilationUnit.context;

  /// If the executable element had an explicitly declared return type, return
  /// it.  Otherwise return `null`.
  DartType get declaredReturnType {
    if (serializedExecutable.returnType == null) {
      return null;
    } else {
      return _declaredReturnType ??=
          compilationUnit.resolveTypeRef(this, serializedExecutable.returnType);
    }
  }

  @override
  String get displayName {
    if (_displayName == null) {
      _displayName = serializedExecutable.name;
      if (serializedExecutable.kind == UnlinkedExecutableKind.setter) {
        _displayName = _displayName.substring(0, _displayName.length - 1);
      }
    }
    return _displayName;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit => compilationUnit;

  /// Return a list containing all of the functions defined within this
  /// executable element.
  List<FunctionElement> get functions {
    return [];
  }

  @override
  bool get hasImplicitReturnType => serializedExecutable.returnType == null;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  /// Return the inferred return type of the executable element.  Should only be
  /// called if no return type was explicitly declared.
  DartType get inferredReturnType {
    // We should only try to infer a return type when none is explicitly
    // declared.
    assert(serializedExecutable.returnType == null);
    if (Linker._initializerTypeInferenceCycle != null &&
        Linker._initializerTypeInferenceCycle ==
            compilationUnit.library.libraryCycleForLink) {
      // We are currently computing the type of an initializer expression in the
      // current library cycle, so type inference results should be ignored.
      return _computeDefaultReturnType();
    }
    if (_inferredReturnType == null) {
      if (serializedExecutable.kind == UnlinkedExecutableKind.constructor) {
        // TODO(paulberry): implement.
        throw new UnimplementedError();
      } else if (compilationUnit.isInBuildUnit) {
        _inferredReturnType = _computeDefaultReturnType();
      } else {
        _inferredReturnType = compilationUnit.getLinkedType(
            this, serializedExecutable.inferredReturnTypeSlot);
      }
    }
    return _inferredReturnType;
  }

  @override
  bool get isAbstract => serializedExecutable.isAbstract;

  @override
  bool get isGenerator => serializedExecutable.isGenerator;

  @override
  bool get isStatic => serializedExecutable.isStatic;

  @override
  bool get isSynthetic => false;

  @override
  LibraryElement get library => enclosingElement.library;

  @override
  get linkedNode => null;

  @override
  String get name {
    if (_name == null) {
      _name = serializedExecutable.name;
      if (_name == '-' && serializedExecutable.parameters.isEmpty) {
        _name = 'unary-';
      }
    }
    return _name;
  }

  @override
  DartType get returnType => declaredReturnType ?? inferredReturnType;

  @override
  void set returnType(DartType inferredType) {
    _inferredReturnType = inferredType;
  }

  @override
  AnalysisSession get session => compilationUnit.session;

  @override
  FunctionTypeImpl get type => _type ??= new FunctionTypeImpl(this);

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters => serializedExecutable.parameters;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      serializedExecutable.typeParameters;

  @override
  bool isAccessibleIn(LibraryElement library) =>
      !Identifier.isPrivateName(name) || identical(this.library, library);

  /// Compute the default return type for this type of executable element (if no
  /// return type is declared and strong mode type inference cannot infer a
  /// better return type).
  DartType _computeDefaultReturnType() {
    var kind = serializedExecutable.kind;
    var isMethod = kind == UnlinkedExecutableKind.functionOrMethod;
    var isSetter = kind == UnlinkedExecutableKind.setter;
    if ((isSetter || isMethod && serializedExecutable.name == '[]=')) {
      // In strong mode, setters and `[]=` operators without an explicit
      // return type are considered to return `void`.
      return VoidTypeImpl.instance;
    } else {
      return DynamicTypeImpl.instance;
    }
  }
}

/// Base class for executable elements that are resynthesized from a summary
/// during linking and are not local functions.
abstract class ExecutableElementForLink_NonLocal
    extends ExecutableElementForLink {
  /// Return the class in which this executable appears, maybe `null` for a
  /// top-level function.
  final ClassElementForLink_Class enclosingClass;

  ExecutableElementForLink_NonLocal(
      CompilationUnitElementForLink compilationUnit,
      this.enclosingClass,
      UnlinkedExecutable unlinkedExecutable)
      : super(compilationUnit, unlinkedExecutable);

  @override
  Element get enclosingElement => enclosingClass ?? compilationUnit;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      enclosingClass;

  /// Store the results of type inference for this method in [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (serializedExecutable.returnType == null) {
      compilationUnit._storeLinkedType(
          serializedExecutable.inferredReturnTypeSlot,
          inferredReturnType,
          this);
    }
    for (ParameterElementForLink parameterElement in parameters) {
      parameterElement.link(compilationUnit);
    }
  }
}

class ExprTypeComputer {
  final ExprBuilder _builder;

  final AstRewriteVisitor _astRewriteVisitor;

  final ResolverVisitor _resolverVisitor;

  final TypeResolverVisitor _typeResolverVisitor;

  final VariableResolverVisitor _variableResolverVisitor;

  final PartialResolverVisitor _partialResolverVisitor;

  final Linker _linker;

  FunctionElementForLink_Local _functionElement;

  factory ExprTypeComputer(FunctionElementForLink_Local functionElement) {
    ClassElement enclosingClass =
        functionElement.getAncestor((e) => e is ClassElement);
    CompilationUnitElementForLink unit = functionElement.compilationUnit;
    LibraryElementForLink library = unit.enclosingElement;
    Linker linker = library._linker;
    TypeProvider typeProvider = linker.typeProvider;
    var unlinkedExecutable = functionElement.serializedExecutable;
    UnlinkedExpr unlinkedConst = unlinkedExecutable.bodyExpr;
    var errorListener = AnalysisErrorListener.NULL_LISTENER;
    var source = unit.source;
    var astRewriteVisitor = new AstRewriteVisitor(
        linker.typeSystem, library, source, typeProvider, errorListener);
    EnclosedScope nameScope = new LibraryScope(library);
    if (enclosingClass != null) {
      nameScope = new ClassScope(
          new TypeParameterScope(nameScope, enclosingClass), enclosingClass);
    }
    var inheritance = new InheritanceManager2(linker.typeSystem);
    // Note: this is a bit of a hack; we ought to use the feature set for the
    // compilation unit being analyzed, but that's not feasible because sumaries
    // don't record the feature set.  This should be resolved when we switch to
    // the "summary2" mechanism.
    var featureSet = FeatureSet.fromEnableFlags([]);
    var resolverVisitor = new ResolverVisitor(
        inheritance, library, source, typeProvider, errorListener,
        featureSet: featureSet,
        nameScope: nameScope,
        propagateTypes: false,
        reportConstEvaluationErrors: false);
    var typeResolverVisitor = new TypeResolverVisitor(
        library, source, typeProvider, errorListener,
        nameScope: nameScope);
    var variableResolverVisitor = new VariableResolverVisitor(
        library, source, typeProvider, errorListener,
        nameScope: nameScope, localVariableInfo: LocalVariableInfo());
    var partialResolverVisitor = new PartialResolverVisitor(
        inheritance, library, source, typeProvider, errorListener, featureSet,
        nameScope: nameScope);
    return new ExprTypeComputer._(
        unit._unitResynthesizer,
        astRewriteVisitor,
        resolverVisitor,
        typeResolverVisitor,
        variableResolverVisitor,
        partialResolverVisitor,
        linker,
        errorListener,
        functionElement,
        unlinkedConst,
        unlinkedExecutable.localFunctions);
  }

  ExprTypeComputer._(
      UnitResynthesizer unitResynthesizer,
      this._astRewriteVisitor,
      this._resolverVisitor,
      this._typeResolverVisitor,
      this._variableResolverVisitor,
      this._partialResolverVisitor,
      this._linker,
      AnalysisErrorListener _errorListener,
      this._functionElement,
      UnlinkedExpr unlinkedConst,
      List<UnlinkedExecutable> localFunctions)
      : _builder = new ExprBuilder(
            unitResynthesizer, _functionElement, unlinkedConst,
            requireValidConst: false,
            localFunctions: localFunctions,
            becomeSetOrMap: false);

  TopLevelInferenceErrorKind get errorKind {
    // TODO(paulberry): should we return TopLevelInferenceErrorKind.assignment
    // sometimes?
    return null;
  }

  DartType compute() {
    Expression expression;
    if (_linker.getAst != null) {
      var expressionForInference = _functionElement._expressionForInference;
      if (expressionForInference != null) {
        expression = AstCloner().cloneNode(expressionForInference);
        expression.accept(LocalElementBuilder(ElementHolder(), null));
      }
    } else if (_builder.hasNonEmptyExpr) {
      expression = _builder.build();
    }
    if (expression == null) {
      // No function body was stored for this function, so we can't infer its
      // return type.  Assume `dynamic`.
      return DynamicTypeImpl.instance;
    }
    var container =
        astFactory.expressionFunctionBody(null, null, expression, null);
    expression.accept(_astRewriteVisitor);
    expression = container.expression;
    if (_linker.getAst != null) {
      expression.accept(_typeResolverVisitor);
    }
    expression.accept(_variableResolverVisitor);
    if (_linker.getAst != null) {
      expression.accept(_partialResolverVisitor);
    }
    expression.accept(_resolverVisitor);
    return expression.staticType;
  }
}

/// Element representing a field resynthesized from a summary during
/// linking.
abstract class FieldElementForLink implements FieldElement {
  @override
  PropertyAccessorElementForLink get getter;

  @override
  PropertyAccessorElementForLink get setter;
}

/// Specialization of [FieldElementForLink] for class fields.
class FieldElementForLink_ClassField extends VariableElementForLink
    implements FieldElementForLink {
  @override
  final ClassElementForLink_Class enclosingElement;

  /// If this is an instance field, the type that was computed by
  /// [InstanceMemberInferrer] (if any).  Otherwise `null`.
  DartType _inferredInstanceType;

  TopLevelInferenceErrorBuilder _inferenceError;

  FieldElementForLink_ClassField(ClassElementForLink_Class enclosingElement,
      UnlinkedVariable unlinkedVariable, Expression initializerForInference)
      : enclosingElement = enclosingElement,
        super(unlinkedVariable, enclosingElement.enclosingElement,
            initializerForInference);

  @override
  bool get isLate => unlinkedVariable.isLate;

  @override
  bool get isStatic => unlinkedVariable.isStatic;

  @override
  DartType get type {
    if (declaredType != null) {
      return declaredType;
    }
    if (Linker._isPerformingVariableTypeInference && !isStatic) {
      return DynamicTypeImpl.instance;
    }
    return inferredType;
  }

  @override
  void set type(DartType inferredType) {
    assert(!isStatic);
    assert(_inferredInstanceType == null);
    _inferredInstanceType = inferredType;
  }

  @override
  TypeParameterizedElementMixin get _typeParameterContext => enclosingElement;

  /// Store the results of type inference for this field in
  /// [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (hasImplicitType) {
      compilationUnit._storeLinkedType(
          unlinkedVariable.inferredTypeSlot,
          isStatic ? inferredType : _inferredInstanceType,
          _typeParameterContext);
      compilationUnit._storeLinkedTypeError(
          unlinkedVariable.inferredTypeSlot, _inferenceError);
      if (initializer != null) {
        compilationUnit._storeLinkedTypeError(
            unlinkedVariable.inferredTypeSlot, initializer._inferenceError);
        initializer.link(compilationUnit);
      }
    }
  }

  void setInferenceError(TopLevelInferenceErrorBuilder error) {
    assert(_inferenceError == null);
    _inferenceError = error;
  }

  @override
  String toString() => '$enclosingElement.$name';
}

/// Specialization of [FieldElementForLink] for enum fields.
class FieldElementForLink_EnumField extends FieldElementForLink
    implements FieldElement {
  PropertyAccessorElementForLink_EnumField _getter;

  @override
  final ClassElementForLink_Enum enclosingElement;

  FieldElementForLink_EnumField(this.enclosingElement);

  @override
  PropertyAccessorElementForLink_EnumField get getter =>
      _getter ??= new PropertyAccessorElementForLink_EnumField(this);

  @override
  bool get isSynthetic => false;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Specialization of [FieldElementForLink] for the 'index' enum field.
class FieldElementForLink_EnumField_index
    extends FieldElementForLink_EnumField {
  FieldElementForLink_EnumField_index(ClassElementForLink_Enum enclosingElement)
      : super(enclosingElement);

  @override
  bool get isStatic => false;

  @override
  String get name => 'index';

  @override
  DartType get type =>
      enclosingElement.enclosingElement.library._linker.typeProvider.intType;
}

/// Specialization of [FieldElementForLink] for enum fields.
class FieldElementForLink_EnumField_value
    extends FieldElementForLink_EnumField {
  /// The unlinked representation of the field in the summary.
  final UnlinkedEnumValue unlinkedEnumValue;

  FieldElementForLink_EnumField_value(
      ClassElementForLink_Enum enclosingElement, this.unlinkedEnumValue)
      : super(enclosingElement);

  @override
  bool get isStatic => true;

  @override
  String get name => unlinkedEnumValue.name;

  @override
  DartType get type => enclosingElement.type;
}

/// Specialization of [FieldElementForLink] for the 'values' enum field.
class FieldElementForLink_EnumField_values
    extends FieldElementForLink_EnumField {
  FieldElementForLink_EnumField_values(
      ClassElementForLink_Enum enclosingElement)
      : super(enclosingElement);

  @override
  bool get isStatic => true;

  @override
  String get name => 'values';

  @override
  DartType get type => enclosingElement.valuesType;
}

class FieldFormalParameterElementForLink extends ParameterElementForLink
    implements FieldFormalParameterElement {
  FieldElement _field;
  DartType _type;

  FieldFormalParameterElementForLink(
      ParameterParentElementForLink enclosingElement,
      UnlinkedParam unlinkedParam,
      TypeParameterizedElementMixin typeParameterContext,
      CompilationUnitElementForLink compilationUnit,
      int parameterIndex)
      : super(enclosingElement, unlinkedParam, typeParameterContext,
            compilationUnit, parameterIndex);

  @override
  FieldElement get field {
    if (_field == null) {
      Element enclosingConstructor = enclosingElement;
      if (enclosingConstructor is ConstructorElement) {
        Element enclosingClass = enclosingConstructor.enclosingElement;
        if (enclosingClass is ClassElement) {
          FieldElement field = enclosingClass.getField(unlinkedParam.name);
          if (field != null && !field.isSynthetic) {
            _field = field;
          }
        }
      }
    }
    return _field;
  }

  @override
  bool get isInitializingFormal => true;

  @override
  DartType get type {
    return _type ??= field?.type ?? DynamicTypeImpl.instance;
  }
}

/// Element representing a function-typed parameter resynthesied from a summary
/// during linking.
class FunctionElementForLink_FunctionTypedParam
    with ParameterParentElementForLink
    implements FunctionElement {
  @override
  final ParameterElementForLink enclosingElement;

  @override
  final TypeParameterizedElementMixin typeParameterContext;

  @override
  final List<UnlinkedParam> unlinkedParameters;

  DartType _returnType;
  List<int> _implicitFunctionTypeIndices;

  FunctionElementForLink_FunctionTypedParam(this.enclosingElement,
      this.typeParameterContext, this.unlinkedParameters);

  @override
  List<int> get implicitFunctionTypeIndices {
    if (_implicitFunctionTypeIndices == null) {
      _implicitFunctionTypeIndices = enclosingElement
          .enclosingElement.implicitFunctionTypeIndices
          .toList();
      _implicitFunctionTypeIndices.add(enclosingElement._parameterIndex);
    }
    return _implicitFunctionTypeIndices;
  }

  @override
  bool get isSynthetic => true;

  @override
  DartType get returnType {
    if (_returnType == null) {
      if (enclosingElement.unlinkedParam.type == null) {
        _returnType = DynamicTypeImpl.instance;
      } else {
        _returnType = enclosingElement.compilationUnit.resolveTypeRef(
            enclosingElement, enclosingElement.unlinkedParam.type);
      }
    }
    return _returnType;
  }

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing the initializer expression of a variable.
class FunctionElementForLink_Initializer
    with ReferenceableElementForLink, TypeParameterizedElementMixin
    implements FunctionElementForLink_Local {
  /// The variable for which this element is the initializer.
  final VariableElementForLink _variable;

  @override
  final Expression _expressionForInference;

  /// The type inference node for this function, or `null` if it hasn't been
  /// computed yet.
  TypeInferenceNode _typeInferenceNode;

  List<FunctionElementForLink_Local_NonSynthetic> _functions;
  DartType _inferredReturnType;
  TopLevelInferenceErrorBuilder _inferenceError;

  FunctionElementForLink_Initializer(
      this._variable, this._expressionForInference);

  @override
  TypeInferenceNode get asTypeInferenceNode =>
      _typeInferenceNode ??= new TypeInferenceNode(this);

  @override
  CompilationUnitElementForLink get compilationUnit =>
      _variable.compilationUnit;

  @override
  VariableElementForLink get enclosingElement => _variable;

  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      _variable.enclosingElement is ClassElementForLink
          ? _variable.enclosingElement
          : null;

  @override
  CompilationUnitElementForLink get enclosingUnit => _variable.compilationUnit;

  @override
  List<FunctionElementForLink_Local_NonSynthetic> get functions =>
      _functions ??= _computeFunctions();

  @override
  String get identifier => '';

  @override
  bool get isAsynchronous => serializedExecutable.isAsynchronous;

  @override
  get linkedNode => null;

  @override
  DartType get returnType {
    // If this is a variable whose type needs inferring, infer it.
    if (_variable.hasImplicitType) {
      return _variable.inferredType;
    } else {
      // There's no reason linking should need to access the type of
      // this FunctionElement, since the variable doesn't need its
      // type inferred.
      assert(false);
      // But for robustness, return the dynamic type.
      return DynamicTypeImpl.instance;
    }
  }

  @override
  void set returnType(DartType newType) {
    // InstanceMemberInferrer stores the new type both here and on the variable
    // element.  We don't need to record both values, so we ignore it here.
  }

  @override
  UnlinkedExecutable get serializedExecutable =>
      _variable.unlinkedVariable.initializer;

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams => const [];

  @override
  bool get _hasTypeBeenInferred => _inferredReturnType != null;

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) {
    return ElementImpl.getAncestorStatic(enclosingElement, predicate);
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    List<FunctionElementForLink_Local_NonSynthetic> functions = this.functions;
    return index < functions.length ? functions[index] : null;
  }

  /// Store the results of type inference for this initializer in
  /// [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(
        serializedExecutable.inferredReturnTypeSlot,
        _inferredReturnType,
        typeParameterContext);
    for (FunctionElementForLink_Local_NonSynthetic function in functions) {
      function.link(compilationUnit);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => _variable.toString();

  List<FunctionElementForLink_Local_NonSynthetic> _computeFunctions() {
    var localFunctionsFromSummary =
        _variable.unlinkedVariable.initializer.localFunctions;
    var count = localFunctionsFromSummary.length;
    var result = List<FunctionElementForLink_Local_NonSynthetic>(count);
    for (int i = 0; i < count; i++) {
      result[i] = FunctionElementForLink_Local_NonSynthetic(
          _variable.compilationUnit,
          this,
          localFunctionsFromSummary[i],
          i == 0 ? _expressionForInference : null);
    }
    return result;
  }

  @override
  void _setInferenceError(TopLevelInferenceErrorBuilder error) {
    assert(!_hasTypeBeenInferred);
    _inferenceError = error;
  }

  @override
  void _setInferredType(DartType type) {
    assert(!_hasTypeBeenInferred);
    _inferredReturnType = type;
    _variable._inferredType = _dynamicIfNull(type);
  }
}

/// Element representing a local function (possibly a closure).
abstract class FunctionElementForLink_Local
    implements
        ExecutableElementForLink,
        FunctionElementImpl,
        ReferenceableElementForLink {
  /// If this function element represents the initializer of a field or a
  /// top-level variable, returns the AST for the initializer expression; this
  /// is used for inferring the expression type.
  Expression get _expressionForInference;

  /// Indicates whether type inference has completed for this function.
  bool get _hasTypeBeenInferred;

  /// Stores the given [error] as the type inference error for this function.
  /// Should only be called if [_hasTypeBeenInferred] is `false`.
  void _setInferenceError(TopLevelInferenceErrorBuilder error);

  /// Stores the given [type] as the inferred return type for this function.
  /// Should only be called if [_hasTypeBeenInferred] is `false`.
  void _setInferredType(DartType type);
}

/// Element representing a local function (possibly a closure) inside another
/// executable.
class FunctionElementForLink_Local_NonSynthetic extends ExecutableElementForLink
    with ReferenceableElementForLink
    implements FunctionElementForLink_Local {
  @override
  final ExecutableElementForLink enclosingElement;

  @override
  final Expression _expressionForInference;

  List<FunctionElementForLink_Local_NonSynthetic> _functions;

  /// The type inference node for this function, or `null` if it hasn't been
  /// computed yet.
  TypeInferenceNode _typeInferenceNode;

  FunctionElementForLink_Local_NonSynthetic(
      CompilationUnitElementForLink compilationUnit,
      this.enclosingElement,
      UnlinkedExecutable unlinkedExecutable,
      this._expressionForInference)
      : super(compilationUnit, unlinkedExecutable);

  @override
  TypeInferenceNode get asTypeInferenceNode =>
      _typeInferenceNode ??= new TypeInferenceNode(this);

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      enclosingElement;

  @override
  List<FunctionElementForLink_Local_NonSynthetic> get functions =>
      _functions ??= serializedExecutable.localFunctions
          .map((UnlinkedExecutable ex) =>
              new FunctionElementForLink_Local_NonSynthetic(
                  compilationUnit, this, ex, null))
          .toList();

  @override
  String get identifier {
    String identifier = serializedExecutable.name;
    Element enclosing = this.enclosingElement;
    if (enclosing is ExecutableElementForLink) {
      int id =
          ElementImpl.findElementIndexUsingIdentical(enclosing.functions, this);
      identifier += "@$id";
    }
    return identifier;
  }

  @override
  bool get isAsynchronous => serializedExecutable.isAsynchronous;

  @override
  bool get _hasTypeBeenInferred => _inferredReturnType != null;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    assert(implicitFunctionTypeIndices.isEmpty);
    return type;
  }

  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) {
    return ElementImpl.getAncestorStatic(enclosingElement, predicate);
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    List<FunctionElementForLink_Local_NonSynthetic> functions = this.functions;
    return index < functions.length ? functions[index] : null;
  }

  /// Store the results of type inference for this function in
  /// [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (serializedExecutable.returnType == null) {
      compilationUnit._storeLinkedType(
          serializedExecutable.inferredReturnTypeSlot,
          inferredReturnType,
          this);
    }
    for (FunctionElementForLink_Local_NonSynthetic function in functions) {
      function.link(compilationUnit);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => enclosingElement.toString();

  @override
  void _setInferenceError(TopLevelInferenceErrorBuilder error) {}

  @override
  void _setInferredType(DartType type) {
    // TODO(paulberry): store the inferred return type in the summary.
    assert(!_hasTypeBeenInferred);
    _inferredReturnType = _dynamicIfBottom(type);
  }
}

/// Synthetic function element which is created for local functions.
class FunctionElementForLink_Synthetic extends ExecutableElementForLink
    with ReferenceableElementForLink
    implements FunctionElementForLink_Local {
  @override
  final Element enclosingElement;

  final EntityRef _entityRef;

  FunctionElementForLink_Synthetic(
      CompilationUnitElementForLink compilationUnit,
      this.enclosingElement,
      this._entityRef)
      : super(compilationUnit, null);

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext {
    if (enclosingElement is TypeParameterizedElementMixin) {
      return enclosingElement;
    }
    return null;
  }

  @override
  DartType get returnType {
    return _declaredReturnType ??= enclosingUnit.resynthesizerContext
        .resolveTypeRef(this, _entityRef.syntheticReturnType);
  }

  @override
  List<UnlinkedParam> get unlinkedParameters => _entityRef.syntheticParams;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams => _entityRef.typeParameters;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing a typedef resynthesized from a summary during linking.
class FunctionTypeAliasElementForLink
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink,
        SimplyBoundableForLinkMixin
    implements FunctionTypeAliasElement, ElementImpl {
  @override
  final CompilationUnitElementForLink enclosingElement;

  /// The unlinked representation of the typedef in the summary.
  final UnlinkedTypedef _unlinkedTypedef;

  FunctionTypeImpl _type;
  DartType _returnType;
  GenericFunctionTypeElementForLink _function;

  FunctionTypeAliasElementForLink(
      this.enclosingElement, this._unlinkedTypedef) {
    _initSimplyBoundable();
  }

  @override
  DartType get asStaticType {
    return enclosingElement.enclosingElement._linker.typeProvider.typeType;
  }

  @override
  ContextForLink get context => enclosingElement.context;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementForLink get enclosingUnit => enclosingElement;

  @override
  GenericFunctionTypeElementImpl get function =>
      _function ??= new GenericFunctionTypeElementForLink(enclosingUnit, this,
          const [], _unlinkedTypedef.returnType, _unlinkedTypedef.parameters);

  @override
  String get identifier => _unlinkedTypedef.name;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  get linkedNode => null;

  @override
  String get name => _unlinkedTypedef.name;

  @override
  DartType get returnType => _returnType ??=
      enclosingElement.resolveTypeRef(this, _unlinkedTypedef.returnType);

  @override
  AnalysisSession get session => enclosingElement.session;

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters => _unlinkedTypedef.parameters;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedTypedef.typeParameters;

  @override
  int get _notSimplyBoundedSlot => _unlinkedTypedef.notSimplyBoundedSlot;

  @override
  List<EntityRef> get _rhsTypesForSimplyBoundable =>
      _collectTypedefRhsTypes(_unlinkedTypedef);

  @override
  List<UnlinkedTypeParam> get _typeParametersForSimplyBoundable =>
      _unlinkedTypedef.typeParameters;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    int numTypeParameters = _unlinkedTypedef.typeParameters.length;
    if (numTypeParameters != 0) {
      List<DartType> typeArguments =
          new List<DartType>.generate(numTypeParameters, getTypeArgument);
      if (typeArguments.contains(null)) {
        return context.typeSystem
            .instantiateToBounds(new FunctionTypeImpl.forTypedef(this));
      } else {
        return GenericTypeAliasElementImpl.doInstantiate(this, typeArguments);
      }
    } else {
      return _type ??= new FunctionTypeImpl.forTypedef(this);
    }
  }

  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    _linkSimplyBoundable();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Element representing a generic function resynthesized from a summary during
/// linking.
class GenericFunctionTypeElementForLink
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink
    implements GenericFunctionTypeElementImpl, ElementImpl {
  @override
  final CompilationUnitElementForLink enclosingUnit;

  @override
  final ElementImpl enclosingElement;

  @override
  final List<UnlinkedTypeParam> unlinkedTypeParams;

  /// The representation of the generic function's return type in the summary.
  final EntityRef _unlinkedReturnType;

  @override
  final List<UnlinkedParam> unlinkedParameters;

  DartType _returnType;
  FunctionTypeImpl _type;

  GenericFunctionTypeElementForLink(
      this.enclosingUnit,
      this.enclosingElement,
      this.unlinkedTypeParams,
      this._unlinkedReturnType,
      this.unlinkedParameters);

  @override
  DartType get asStaticType {
    return enclosingUnit.enclosingElement._linker.typeProvider.typeType;
  }

  @override
  ContextForLink get context => enclosingElement.context;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext {
    return enclosingElement.typeParameterContext;
  }

  @override
  String get identifier => name;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  get linkedNode => null;

  @override
  String get name => '-';

  @override
  DartType get returnType =>
      _returnType ??= enclosingUnit.resolveTypeRef(this, _unlinkedReturnType);

  @override
  AnalysisSession get session => enclosingElement.session;

  @override
  FunctionType get type {
    return _type ??= new FunctionTypeImpl(this);
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Element representing a generic typedef resynthesized from a summary during
/// linking.
class GenericTypeAliasElementForLink
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink,
        SimplyBoundableForLinkMixin
    implements FunctionTypeAliasElementForLink, GenericTypeAliasElementImpl {
  @override
  final CompilationUnitElementForLink enclosingElement;

  /// The unlinked representation of the typedef in the summary.
  final UnlinkedTypedef _unlinkedTypedef;

  GenericFunctionTypeElementForLink _function;

  GenericTypeAliasElementForLink(this.enclosingElement, this._unlinkedTypedef) {
    _initSimplyBoundable();
  }

  @override
  DartType get asStaticType {
    return enclosingElement.enclosingElement._linker.typeProvider.typeType;
  }

  @override
  ContextForLink get context => enclosingElement.context;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementForLink get enclosingUnit => enclosingElement;

  @override
  GenericFunctionTypeElementImpl get function {
    var unlinkedType = _unlinkedTypedef.returnType;
    return _function ??= new GenericFunctionTypeElementForLink(
        enclosingUnit,
        this,
        unlinkedType.typeParameters,
        unlinkedType.syntheticReturnType,
        unlinkedType.syntheticParams);
  }

  @override
  String get identifier => _unlinkedTypedef.name;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  get linkedNode => null;

  @override
  String get name => _unlinkedTypedef.name;

  @override
  DartType get returnType => enclosingElement.resolveTypeRef(
      this, _unlinkedTypedef.returnType.syntheticReturnType);

  @override
  AnalysisSession get session => enclosingElement.session;

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters =>
      _unlinkedTypedef.returnType.syntheticParams;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams {
    var result = _unlinkedTypedef.typeParameters.toList();
    result.addAll(_unlinkedTypedef.returnType.typeParameters);
    return result;
  }

  @override
  int get _notSimplyBoundedSlot => _unlinkedTypedef.notSimplyBoundedSlot;

  @override
  List<EntityRef> get _rhsTypesForSimplyBoundable =>
      _collectTypedefRhsTypes(_unlinkedTypedef);

  @override
  List<UnlinkedTypeParam> get _typeParametersForSimplyBoundable =>
      _unlinkedTypedef.typeParameters;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    int numTypeParameters = _unlinkedTypedef.typeParameters.length;
    if (numTypeParameters != 0) {
      List<DartType> typeArguments =
          new List<DartType>.generate(numTypeParameters, getTypeArgument);
      if (typeArguments.contains(null)) {
        return context.typeSystem
            .instantiateToBounds(new FunctionTypeImpl.forTypedef(this));
      } else {
        return GenericTypeAliasElementImpl.doInstantiate(this, typeArguments);
      }
    } else {
      return new FunctionTypeImpl.forTypedef(this);
    }
  }

  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    _linkSimplyBoundable();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Context for serializing a possibly generic function type that is used in
/// another context.
class InlineFunctionTypeParameterContext
    implements TypeParameterSerializationContext {
  final GenericFunctionTypeElementImpl _functionTypeElement;

  final TypeParameterSerializationContext _usageContext;

  InlineFunctionTypeParameterContext(
      this._functionTypeElement, this._usageContext);

  @override
  int computeDeBruijnIndex(TypeParameterElement typeParameter,
      {int offset: 0}) {
    var typeFormals = _functionTypeElement.typeParameters;
    var numTypeFormals = typeFormals.length;
    for (int i = 0; i < numTypeFormals; i++) {
      if (typeFormals[i] == typeParameter) return i + offset + 1;
    }
    return _usageContext.computeDeBruijnIndex(typeParameter,
        offset: offset + numTypeFormals);
  }
}

/// Specialization of [DependencyWalker] for linking library cycles.
class LibraryCycleDependencyWalker extends DependencyWalker<LibraryCycleNode> {
  @override
  void evaluate(LibraryCycleNode v) {
    v.link();
  }

  @override
  void evaluateScc(List<LibraryCycleNode> scc) {
    // There should never be a cycle among library cycles.
    throw new StateError('Cycle among library cycles');
  }
}

/// An instance of [LibraryCycleForLink] represents a single library cycle
/// discovered during linking; it consists of one or more libraries in the build
/// unit being linked.
class LibraryCycleForLink {
  /// The libraries in the cycle.
  final List<LibraryElementInBuildUnit> libraries;

  /// The library cycles which this library depends on.
  final List<LibraryCycleForLink> dependencies;

  /// The [LibraryCycleNode] for this library cycle.
  LibraryCycleNode _node;

  LibraryCycleForLink(this.libraries, this.dependencies) {
    _node = new LibraryCycleNode(this);
  }

  LibraryCycleNode get node => _node;

  /// Link this library cycle and any library cycles it depends on.  Does
  /// nothing if this library cycle has already been linked.
  void ensureLinked() {
    if (!node.isEvaluated) {
      new LibraryCycleDependencyWalker().walk(node);
    }
  }
}

/// Specialization of [Node] used to link library cycles in proper dependency
/// order.
class LibraryCycleNode extends Node<LibraryCycleNode> {
  /// The library cycle this [Node] represents.
  final LibraryCycleForLink libraryCycle;

  /// Indicates whether this library cycle has been linked yet.
  bool _isLinked = false;

  LibraryCycleNode(this.libraryCycle);

  @override
  bool get isEvaluated => _isLinked;

  @override
  List<LibraryCycleNode> computeDependencies() => libraryCycle.dependencies
      .map((LibraryCycleForLink cycle) => cycle.node)
      .toList();

  /// Link this library cycle.
  void link() {
    for (LibraryElementInBuildUnit library in libraryCycle.libraries) {
      library.link();
    }
    _isLinked = true;
  }
}

/// Specialization of [DependencyWalker] for computing library cycles.
class LibraryDependencyWalker extends DependencyWalker<LibraryNode> {
  @override
  void evaluate(LibraryNode v) => evaluateScc(<LibraryNode>[v]);

  @override
  void evaluateScc(List<LibraryNode> scc) {
    Set<LibraryCycleForLink> dependentCycles = new Set<LibraryCycleForLink>();
    for (LibraryNode node in scc) {
      for (LibraryNode dependency in Node.getDependencies(node)) {
        if (dependency.isEvaluated) {
          dependentCycles.add(dependency._libraryCycle);
        }
      }
    }
    LibraryCycleForLink cycle = new LibraryCycleForLink(
        scc.map((LibraryNode n) => n.library).toList(),
        dependentCycles.toList());
    for (LibraryNode node in scc) {
      node._libraryCycle = cycle;
    }
  }
}

/// Element representing a library resynthesied from a summary during
/// linking.  The type parameter, [UnitElement], represents the type
/// that will be used for the compilation unit elements.
abstract class LibraryElementForLink<
        UnitElement extends CompilationUnitElementForLink>
    extends LibraryResynthesizerContextMixin implements LibraryElementImpl {
  final _LibraryResynthesizer resynthesizer;

  /// Pointer back to the linker.
  final Linker _linker;

  /// The absolute URI of this library.
  final Uri _absoluteUri;

  List<UnitElement> _units;
  List<UnitElement> _parts;
  final Map<String, ReferenceableElementForLink> _containedNames =
      <String, ReferenceableElementForLink>{};
  final List<LibraryElementForLink> _dependencies = <LibraryElementForLink>[];
  UnlinkedUnit _unlinkedDefiningUnit;
  List<LibraryElementForLink> _importedLibraries;
  List<LibraryElementForLink> _exportedLibraries;

  Namespace _exportNamespace;

  Namespace _publicNamespace;

  FunctionElement _loadLibraryFunction;

  LibraryElementForLink(this._linker, this._absoluteUri)
      : resynthesizer = new _LibraryResynthesizer() {
    resynthesizer._library = this;
    if (_linkedLibrary != null) {
      _dependencies.length = _linkedLibrary.dependencies.length;
    }
  }

  @override
  ContextForLink get context => _linker.context;

  @override
  UnitElement get definingCompilationUnit => units[0];

  @override
  Element get enclosingElement => null;

  @override
  List<LibraryElementForLink> get exportedLibraries =>
      _exportedLibraries ??= _linkedLibrary.exportDependencies
          .map(buildImportedLibrary)
          .where((library) => library != null)
          .toList();

  @override
  Namespace get exportNamespace =>
      _exportNamespace ??= resynthesizerContext.buildExportNamespace();

  @override
  String get identifier => _absoluteUri.toString();

  @override
  List<LibraryElementForLink> get importedLibraries => _importedLibraries ??=
      _linkedLibrary.importDependencies.map(buildImportedLibrary).toList();

  @override
  bool get isDartAsync => _absoluteUri.toString() == 'dart:async';

  @override
  bool get isDartCore => _absoluteUri.toString() == 'dart:core';

  @override
  bool get isInSdk => _absoluteUri.scheme == 'dart';

  @override
  bool get isSynthetic => _linkedLibrary == null;

  /// If this library is part of the build unit being linked, return the library
  /// cycle it is part of.  Otherwise return `null`.
  LibraryCycleForLink get libraryCycleForLink;

  @override
  FunctionElement get loadLibraryFunction => _loadLibraryFunction ??=
      LibraryElementImpl.createLoadLibraryFunctionForLibrary(
          _linker.typeProvider, this);

  @override
  String get name {
    return _unlinkedDefiningUnit.libraryName;
  }

  List<UnitElement> get parts => _parts ??= units.sublist(1);

  @override
  Namespace get publicNamespace =>
      _publicNamespace ??= resynthesizerContext.buildPublicNamespace();

  @override
  LibraryResynthesizerContext get resynthesizerContext => this;

  @override
  AnalysisSession get session => _linker.session;

  @override
  Source get source => definingCompilationUnit.source;

  @override
  List<UnitElement> get units {
    if (_units == null) {
      UnlinkedUnit definingUnit = unlinkedDefiningUnit;
      _units = <UnitElement>[
        _makeUnitElement(definingUnit, 0, _absoluteUri.toString())
      ];
      int numParts = definingUnit.parts.length;
      for (int i = 0; i < numParts; i++) {
        String partRelativeUriStr = definingUnit.publicNamespace.parts[i];

        if (partRelativeUriStr.isEmpty) {
          continue;
        }

        Uri partRelativeUri;
        try {
          partRelativeUri = Uri.parse(partRelativeUriStr);
        } on FormatException {
          continue;
        }

        String partAbsoluteUri =
            resolveRelativeUri(_absoluteUri, partRelativeUri).toString();
        UnlinkedUnit partUnit = _linker.getUnit(partAbsoluteUri);
        _units.add(_makeUnitElement(
            partUnit ?? new UnlinkedUnitBuilder(), i + 1, partAbsoluteUri));
      }
    }
    return _units;
  }

  @override
  UnlinkedUnit get unlinkedDefiningUnit => _unlinkedDefiningUnit ??=
      _linker.getUnit(_absoluteUri.toString()) ?? new UnlinkedUnitBuilder();

  List<LinkedExportName> get _linkedExportNames =>
      _linkedLibrary == null ? [] : _linkedLibrary.exportNames;

  /// The linked representation of the library in the summary.
  LinkedLibrary get _linkedLibrary;

  /// Return the [LibraryElement] corresponding to the given dependency [index].
  LibraryElementForLink buildImportedLibrary(int index) {
    LibraryElementForLink result = _dependencies[index];
    if (result == null) {
      Uri uri;
      String uriStr = _linkedLibrary.dependencies[index].uri;
      if (uriStr.isEmpty) {
        uri = _absoluteUri;
      } else {
        try {
          uri = Uri.parse(uriStr);
        } on FormatException {
          return null;
        }
      }

      result = _linker.getLibrary(uri);
      _dependencies[index] = result;
    }
    return result;
  }

  /// Search all the units for a top level element with the given
  /// [name].  If no name is found, return the singleton instance of
  /// [UndefinedElementForLink].
  ReferenceableElementForLink getContainedName(String name) =>
      _containedNames.putIfAbsent(name, () {
        for (UnitElement unit in units) {
          ReferenceableElementForLink element = unit.getContainedName(name);
          if (!identical(element, UndefinedElementForLink.instance)) {
            return element;
          }
        }
        return UndefinedElementForLink.instance;
      });

  @override
  List<ImportElement> getImportsWithPrefix(PrefixElement prefixElement) =>
      LibraryElementImpl.getImportsWithPrefixFromImports(
          prefixElement, imports);

  @override
  ClassElement getType(String className) => LibraryElementImpl.getTypeFromParts(
      className, definingCompilationUnit, parts);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => _absoluteUri.toString();

  /// Create a [UnitElement] for one of the library's compilation
  /// units.
  UnitElement _makeUnitElement(
      UnlinkedUnit unlinkedUnit, int i, String absoluteUri);
}

/// Element representing a library which is part of the build unit
/// being linked.
class LibraryElementInBuildUnit
    extends LibraryElementForLink<CompilationUnitElementInBuildUnit> {
  @override
  final LinkedLibraryBuilder _linkedLibrary;

  /// The [LibraryNode] representing this library in the library dependency
  /// graph.
  LibraryNode _libraryNode;

  List<ImportElement> _imports;

  List<PrefixElement> _prefixes;

  LibraryElementInBuildUnit(Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri) {
    _libraryNode = new LibraryNode(this);
  }

  @override
  List<ImportElement> get imports =>
      _imports ??= LibraryElementImpl.buildImportsFromSummary(this,
          _unlinkedDefiningUnit.imports, _linkedLibrary.importDependencies);

  @override
  LibraryCycleForLink get libraryCycleForLink {
    if (!_libraryNode.isEvaluated) {
      new LibraryDependencyWalker().walk(_libraryNode);
    }
    return _libraryNode._libraryCycle;
  }

  @override
  List<PrefixElement> get prefixes =>
      _prefixes ??= LibraryElementImpl.buildPrefixesFromImports(imports);

  /// If this library already has a dependency in its dependencies table
  /// matching [library], return its index.  Otherwise add a new dependency to
  /// table and return its index.
  int addDependency(LibraryElementForLink library) {
    for (int i = 0; i < _linkedLibrary.dependencies.length; i++) {
      if (identical(buildImportedLibrary(i), library)) {
        return i;
      }
    }
    int result = _linkedLibrary.dependencies.length;
    Uri libraryUri = library._absoluteUri;
    List<String> partsRelativeToDependency =
        library.unlinkedDefiningUnit.publicNamespace.parts;
    List<String> partsAbsolute = partsRelativeToDependency
        .map((partUri) =>
            resolveRelativeUri(libraryUri, Uri.parse(partUri)).toString())
        .toList();
    _linkedLibrary.dependencies.add(new LinkedDependencyBuilder(
        parts: partsAbsolute, uri: libraryUri.toString()));
    _dependencies.add(library);
    return result;
  }

  /// Perform type inference and const cycle detection on this library.
  void link() {
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.link();
    }
  }

  /// Throw away any information stored in the summary by a previous call to
  /// [link].
  void unlink() {
    _linkedLibrary.dependencies.length =
        _linkedLibrary.numPrelinkedDependencies;
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.unlink();
    }
  }

  @override
  CompilationUnitElementInBuildUnit _makeUnitElement(
      UnlinkedUnit unlinkedUnit, int i, String absoluteUri) {
    var astNodeForInference =
        _linker.getAst == null ? null : _linker.getAst(absoluteUri);
    return new CompilationUnitElementInBuildUnit(this, unlinkedUnit,
        _linkedLibrary.units[i], i, absoluteUri, astNodeForInference);
  }
}

/// Element representing a library which is depended upon (either
/// directly or indirectly) by the build unit being linked.
class LibraryElementInDependency
    extends LibraryElementForLink<CompilationUnitElementInDependency> {
  @override
  final LinkedLibrary _linkedLibrary;

  LibraryElementInDependency(
      Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri);

  @override
  LibraryCycleForLink get libraryCycleForLink => null;

  @override
  CompilationUnitElementInDependency _makeUnitElement(
          UnlinkedUnit unlinkedUnit, int i, String absoluteUri) =>
      new CompilationUnitElementInDependency(
          this,
          unlinkedUnit,
          _linkedLibrary == null
              ? new LinkedUnitBuilder()
              : _linkedLibrary.units[i],
          i,
          absoluteUri);
}

/// Specialization of [Node] used to construct the library dependency graph.
class LibraryNode extends Node<LibraryNode> {
  /// The library this [Node] represents.
  final LibraryElementInBuildUnit library;

  /// The library cycle to which [library] belongs, if it has been computed.
  /// Otherwise `null`.
  LibraryCycleForLink _libraryCycle;

  LibraryNode(this.library);

  @override
  bool get isEvaluated => _libraryCycle != null;

  @override
  List<LibraryNode> computeDependencies() {
    // Note: we only need to consider dependencies within the build unit being
    // linked; dependencies in other build units can't participate in library
    // cycles with us.
    List<LibraryNode> dependencies = <LibraryNode>[];
    for (LibraryElement dependency in library.importedLibraries) {
      if (dependency is LibraryElementInBuildUnit) {
        dependencies.add(dependency._libraryNode);
      }
    }
    for (LibraryElement dependency in library.exportedLibraries) {
      if (dependency is LibraryElementInBuildUnit) {
        dependencies.add(dependency._libraryNode);
      }
    }
    return dependencies;
  }
}

/// Instances of [Linker] contain the necessary information to link
/// together a single build unit.
class Linker {
  /// During linking, if type inference is currently being performed on the
  /// initializer of a static or instance variable, the library cycle in
  /// which inference is being performed.  Otherwise, `null`.
  ///
  /// This allows us to suppress instance member type inference results from a
  /// library cycle while doing inference on the right hand sides of static and
  /// instance variables in that same cycle.
  static LibraryCycleForLink _initializerTypeInferenceCycle;

  /// If a top-level or an instance variable type inference is in progress,
  /// this flag it set to `true`.  It is used to prevent type inference for
  /// other instance variables (when they don't have declared type).
  static bool _isPerformingVariableTypeInference = false;

  /// Callback to ask the client for a [LinkedLibrary] for a
  /// dependency.
  final GetDependencyCallback getDependency;

  /// Callback to ask the client for an [UnlinkedUnit].
  final GetUnitCallback getUnit;

  /// Callback to ask the client for a [CompilationUnit].
  final GetAstCallback getAst;

  /// Map containing all library elements accessed during linking,
  /// whether they are part of the build unit being linked or whether
  /// they are dependencies.
  final Map<Uri, LibraryElementForLink> _libraries =
      <Uri, LibraryElementForLink>{};

  /// List of library elements for the libraries in the build unit
  /// being linked.
  final List<LibraryElementInBuildUnit> _librariesInBuildUnit =
      <LibraryElementInBuildUnit>[];

  LibraryElementForLink _coreLibrary;

  LibraryElementForLink _asyncLibrary;
  TypeProviderForLink _typeProvider;
  TypeSystem _typeSystem;
  SpecialTypeElementForLink _voidElement;
  SpecialTypeElementForLink _dynamicElement;
  SpecialTypeElementForLink _bottomElement;
  InheritanceManager2 _inheritanceManager;
  ContextForLink _context;
  AnalysisSessionForLink _session;

  /// Gets an instance of [AnalysisOptions] for use during linking.
  final AnalysisOptions analysisOptions;

  Linker(Map<String, LinkedLibraryBuilder> linkedLibraries, this.getDependency,
      this.getUnit, this.getAst, this.analysisOptions) {
    // Create elements for the libraries to be linked.  The rest of
    // the element model will be created on demand.
    linkedLibraries
        .forEach((String absoluteUri, LinkedLibraryBuilder linkedLibrary) {
      Uri uri = Uri.parse(absoluteUri);
      _librariesInBuildUnit.add(_libraries[uri] =
          new LibraryElementInBuildUnit(this, uri, linkedLibrary));
    });
  }

  /// Get the library element for `dart:async`.
  LibraryElementForLink get asyncLibrary =>
      _asyncLibrary ??= getLibrary(Uri.parse('dart:async'));

  /// Get the element representing the "bottom" type.
  SpecialTypeElementForLink get bottomElement => _bottomElement ??=
      new SpecialTypeElementForLink(this, BottomTypeImpl.instance);

  /// Get a stub implementation of [AnalysisContext] which can be used during
  /// linking.
  get context => _context ??= new ContextForLink(this);

  /// Get the library element for `dart:core`.
  LibraryElementForLink get coreLibrary =>
      _coreLibrary ??= getLibrary(Uri.parse('dart:core'));

  /// Get the element representing `dynamic`.
  SpecialTypeElementForLink get dynamicElement => _dynamicElement ??=
      new SpecialTypeElementForLink(this, DynamicTypeImpl.instance);

  /// Get an instance of [InheritanceManager2] for use during linking.
  InheritanceManager2 get inheritanceManager =>
      _inheritanceManager ??= new InheritanceManager2(typeSystem);

  /// Get a stub implementation of [AnalysisContext] which can be used during
  /// linking.
  get session => _session ??= new AnalysisSessionForLink();

  /// Indicates whether type inference should use strong mode rules.
  @deprecated
  bool get strongMode => true;

  /// Get an instance of [TypeProvider] for use during linking.
  TypeProviderForLink get typeProvider =>
      _typeProvider ??= new TypeProviderForLink(this);

  /// Get an instance of [TypeSystem] for use during linking.
  TypeSystem get typeSystem =>
      _typeSystem ??= new Dart2TypeSystem(typeProvider);

  /// Get the element representing `void`.
  SpecialTypeElementForLink get voidElement => _voidElement ??=
      new SpecialTypeElementForLink(this, VoidTypeImpl.instance);

  /// Get the library element for the library having the given [uri].
  LibraryElementForLink getLibrary(Uri uri) => _libraries.putIfAbsent(
      uri,
      () => new LibraryElementInDependency(
          this, uri, getDependency(uri.toString())));

  /// Perform type inference and const cycle detection on all libraries
  /// in the build unit being linked.
  void link() {
    // Link library cycles in appropriate dependency order.
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.libraryCycleForLink.ensureLinked();
    }
    // TODO(paulberry): set dependencies.
  }

  /// Throw away any information stored in the summary by a previous call to
  /// [link].
  void unlink() {
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.unlink();
    }
  }
}

/// Element representing a method resynthesized from a summary during linking.
class MethodElementForLink extends ExecutableElementForLink_NonLocal
    with ReferenceableElementForLink
    implements MethodElementImpl {
  MethodElementForLink(ClassElementForLink_Class enclosingClass,
      UnlinkedExecutable unlinkedExecutable)
      : super(enclosingClass.enclosingElement, enclosingClass,
            unlinkedExecutable);

  @override
  DartType get asStaticType => type;

  @override
  ClassElementImpl get enclosingElement => super.enclosingClass;

  @override
  String get identifier => name;

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    // TODO(paulberry): implement.
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/**
 * Instances of [Node] represent nodes in a dependency graph.  The
 * type parameter, [NodeType], is the derived type (this affords some
 * extra type safety by making it difficult to accidentally construct
 * bridges between unrelated dependency graphs).
 */
abstract class Node<NodeType> {
  /**
   * Index used by Tarjan's strongly connected components algorithm.
   * Zero means the node has not been visited yet; a nonzero value
   * counts the order in which the node was visited.
   */
  int _index = 0;

  /**
   * Low link used by Tarjan's strongly connected components
   * algorithm.  This represents the smallest [_index] of all the nodes
   * in the strongly connected component to which this node belongs.
   */
  int _lowLink = 0;

  List<NodeType> _dependencies;

  /**
   * Indicates whether this node has been evaluated yet.
   */
  bool get isEvaluated;

  /**
   * Compute the dependencies of this node.
   */
  List<NodeType> computeDependencies();

  /**
   * Gets the dependencies of the given node, computing them if necessary.
   */
  static List<NodeType> getDependencies<NodeType>(Node<NodeType> node) {
    return node._dependencies ??= node.computeDependencies();
  }
}

/// Element used for references that result from trying to access a non-static
/// member of an element that is not a container (e.g. accessing the "length"
/// property of a constant).
///
/// Accesses to a chain of non-static members separated by '.' are handled by
/// creating a [NonstaticMemberElementForLink] that points to another
/// [NonstaticMemberElementForLink], to whatever nesting level is necessary.
class NonstaticMemberElementForLink with ReferenceableElementForLink {
  /// The [ReferenceableElementForLink] which is the target of the non-static
  /// reference.
  final ReferenceableElementForLink _target;

  /// The name of the non-static members that is being accessed.
  final String _name;

  /// The library in which the access occurs.  This determines whether private
  /// names are accessible.
  final LibraryElementForLink _library;

  /// Whether the [_element] was computed (even if to `null`).
  bool _elementReady = false;

  /// The cached [ExecutableElement] represented by this element.
  ExecutableElement _element;

  NonstaticMemberElementForLink(this._library, this._target, this._name);

  @override
  ConstVariableNode get asConstVariable => _target.asConstVariable;

  /// Return the [ExecutableElement] represented by this element.
  ExecutableElement get asExecutableElement {
    if (!_elementReady) {
      _elementReady = true;
      DartType targetType = _target.asStaticType;
      if (targetType.isDynamic) {
        targetType = _library._linker.typeProvider.objectType;
      }
      if (targetType is InterfaceType) {
        _element =
            targetType.lookUpInheritedGetterOrMethod(_name, library: _library);
      }
      // TODO(paulberry): handle .call on function types and .toString or
      // .hashCode on all types.
    }
    return _element;
  }

  @override
  DartType get asStaticType {
    ExecutableElement element = asExecutableElement;
    if (element != null) {
      if (element is PropertyAccessorElement) {
        return element.returnType;
      } else {
        // Method tear-off
        return element.type;
      }
    }
    return DynamicTypeImpl.instance;
  }

  @override
  TypeInferenceNode get asTypeInferenceNode => _target.asTypeInferenceNode;

  @override
  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(_library, this, name);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$_target.(dynamic)$_name';
}

/// Element representing a function or method parameter resynthesized
/// from a summary during linking.
class ParameterElementForLink implements ParameterElementImpl {
  /// The unlinked representation of the parameter in the summary.
  final UnlinkedParam unlinkedParam;

  /// The innermost enclosing element that can declare type parameters.
  final TypeParameterizedElementMixin _typeParameterContext;

  /// If this parameter has a default value and the enclosing library
  /// is part of the build unit being linked, the parameter's node in
  /// the constant evaluation dependency graph.  Otherwise `null`.
  ConstNode _constNode;

  /// The compilation unit in which this parameter appears.
  final CompilationUnitElementForLink compilationUnit;

  /// The index of this parameter within [enclosingElement]'s parameter list.
  final int _parameterIndex;

  @override
  final ParameterParentElementForLink enclosingElement;

  DartType _inferredType;
  TopLevelInferenceErrorBuilder _inferenceError;
  DartType _declaredType;
  bool _inheritsCovariant = false;

  ParameterElementForLink(this.enclosingElement, this.unlinkedParam,
      this._typeParameterContext, this.compilationUnit, this._parameterIndex) {
    if (unlinkedParam.initializer?.bodyExpr != null) {
      _constNode = new ConstParameterNode(this);
    }
    if (compilationUnit is CompilationUnitElementInDependency) {
      _inheritsCovariant =
          (compilationUnit as CompilationUnitElementInDependency)
              .parametersInheritingCovariant
              .contains(unlinkedParam.inheritsCovariantSlot);
    }
  }

  factory ParameterElementForLink.forFactory(
      ParameterParentElementForLink enclosingElement,
      UnlinkedParam unlinkedParameter,
      TypeParameterizedElementMixin typeParameterContext,
      CompilationUnitElementForLink compilationUnit,
      int parameterIndex) {
    if (unlinkedParameter.isInitializingFormal) {
      return new FieldFormalParameterElementForLink(
          enclosingElement,
          unlinkedParameter,
          typeParameterContext,
          typeParameterContext.enclosingUnit.resynthesizerContext
              as CompilationUnitElementForLink,
          parameterIndex);
    } else {
      return new ParameterElementForLink(
          enclosingElement,
          unlinkedParameter,
          typeParameterContext,
          typeParameterContext.enclosingUnit.resynthesizerContext
              as CompilationUnitElementForLink,
          parameterIndex);
    }
  }

  @override
  String get displayName => unlinkedParam.name;

  @override
  bool get hasImplicitType =>
      !unlinkedParam.isFunctionTyped && unlinkedParam.type == null;

  @override
  String get identifier => name;

  @override
  bool get inheritsCovariant => _inheritsCovariant;

  @override
  void set inheritsCovariant(bool value) {
    _inheritsCovariant = value;
  }

  @override
  FunctionElement get initializer => null;

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant => unlinkedParam.isExplicitlyCovariant;

  @override
  bool get isInitializingFormal => unlinkedParam.isInitializingFormal;

  @override
  bool get isNamed =>
      parameterKind == ParameterKind.NAMED ||
      parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isNotOptional =>
      parameterKind == ParameterKind.REQUIRED ||
      parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isOptional =>
      parameterKind == ParameterKind.NAMED ||
      parameterKind == ParameterKind.POSITIONAL;

  @override
  bool get isOptionalNamed => parameterKind == ParameterKind.NAMED;

  @override
  bool get isOptionalPositional => parameterKind == ParameterKind.POSITIONAL;

  @override
  bool get isPositional =>
      parameterKind == ParameterKind.POSITIONAL ||
      parameterKind == ParameterKind.REQUIRED;

  @override
  bool get isRequiredNamed => parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isRequiredPositional => parameterKind == ParameterKind.REQUIRED;

  @override
  get linkedNode => null;

  @override
  String get name => unlinkedParam.name;

  @override
  ParameterKind get parameterKind {
    switch (unlinkedParam.kind) {
      case UnlinkedParamKind.requiredPositional:
        return ParameterKind.REQUIRED;
      case UnlinkedParamKind.requiredNamed:
        return ParameterKind.NAMED_REQUIRED;
      case UnlinkedParamKind.optionalPositional:
        return ParameterKind.POSITIONAL;
      case UnlinkedParamKind.optionalNamed:
        return ParameterKind.NAMED;
    }
    return null;
  }

  @override
  DartType get type {
    if (_inferredType != null) {
      return _inferredType;
    } else if (_declaredType == null) {
      if (unlinkedParam.isFunctionTyped) {
        _declaredType = new FunctionTypeImpl(
            new FunctionElementForLink_FunctionTypedParam(
                this, _typeParameterContext, unlinkedParam.parameters));
      } else if (unlinkedParam.type == null) {
        if (!compilationUnit.isInBuildUnit) {
          _inferredType = compilationUnit.getLinkedType(
              this, unlinkedParam.inferredTypeSlot);
          return _inferredType;
        } else {
          _declaredType = DynamicTypeImpl.instance;
        }
      } else {
        _declaredType =
            compilationUnit.resolveTypeRef(this, unlinkedParam.type);
      }
    }
    return _declaredType;
  }

  @override
  void set type(DartType inferredType) {
    assert(_inferredType == null);
    _inferredType = inferredType;
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext {
    return _typeParameterContext;
  }

  /// Store the results of type inference for this parameter in
  /// [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(
        unlinkedParam.inferredTypeSlot, _inferredType, _typeParameterContext);
    compilationUnit._storeLinkedTypeError(
        unlinkedParam.inferredTypeSlot, _inferenceError);
    if (inheritsCovariant) {
      compilationUnit
          ._storeInheritsCovariant(unlinkedParam.inheritsCovariantSlot);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void setInferenceError(TopLevelInferenceErrorBuilder error) {
    assert(_inferenceError == null);
    _inferenceError = error;
  }
}

/// Element representing the parameter of a synthetic setter for a variable
/// resynthesized during linking.
class ParameterElementForLink_VariableSetter implements ParameterElementImpl {
  @override
  final PropertyAccessorElementForLink_Variable enclosingElement;

  @override
  bool inheritsCovariant = false;

  ParameterElementForLink_VariableSetter(this.enclosingElement);

  @override
  bool get isCovariant => isExplicitlyCovariant || inheritsCovariant;

  @override
  bool get isExplicitlyCovariant => enclosingElement.variable.isCovariant;

  bool get isInitializingFormal => unlinkedParam.isInitializingFormal;

  @override
  bool get isNamed =>
      parameterKind == ParameterKind.NAMED ||
      parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isNotOptional =>
      parameterKind == ParameterKind.REQUIRED ||
      parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isOptional =>
      parameterKind == ParameterKind.NAMED ||
      parameterKind == ParameterKind.POSITIONAL;

  @override
  bool get isOptionalNamed => parameterKind == ParameterKind.NAMED;

  @override
  bool get isOptionalPositional => parameterKind == ParameterKind.POSITIONAL;

  @override
  bool get isPositional =>
      parameterKind == ParameterKind.POSITIONAL ||
      parameterKind == ParameterKind.REQUIRED;

  @override
  bool get isRequiredNamed => parameterKind == ParameterKind.NAMED_REQUIRED;

  @override
  bool get isRequiredPositional => parameterKind == ParameterKind.REQUIRED;

  @override
  bool get isSynthetic => true;

  @override
  String get name => 'x';

  @override
  ParameterKind get parameterKind => ParameterKind.REQUIRED;

  @override
  DartType get type => enclosingElement.variable.type;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mixin used by elements that can have parameters.
abstract class ParameterParentElementForLink implements Element {
  List<ParameterElement> _parameters;

  /// Get the appropriate integer list to store in
  /// [EntityRef.implicitFunctionTypeIndices] to refer to this element.  For an
  /// element representing a function-typed parameter, this should return a
  /// non-empty list.  For an element representing an executable, this should
  /// return the empty list.
  List<int> get implicitFunctionTypeIndices;

  /// Get all the parameters of this element.
  List<ParameterElement> get parameters {
    if (_parameters == null) {
      List<UnlinkedParam> unlinkedParameters = this.unlinkedParameters;
      int numParameters = unlinkedParameters.length;
      _parameters = new List<ParameterElement>(numParameters);
      for (int i = 0; i < numParameters; i++) {
        UnlinkedParam unlinkedParam = unlinkedParameters[i];
        _parameters[i] = new ParameterElementForLink.forFactory(
            this,
            unlinkedParam,
            typeParameterContext,
            typeParameterContext.enclosingUnit.resynthesizerContext
                as CompilationUnitElementForLink,
            i);
      }
    }
    return _parameters;
  }

  /// Get the innermost enclosing element that can declare type parameters
  /// (which may be [this], or may be a parent when there are function-typed
  /// parameters).
  TypeParameterizedElementMixin get typeParameterContext;

  /// Get the list of unlinked parameters of this element.
  List<UnlinkedParam> get unlinkedParameters;
}

/// Element representing a getter or setter resynthesized from a summary during
/// linking.
abstract class PropertyAccessorElementForLink
    implements PropertyAccessorElementImpl, ReferenceableElementForLink {
  void link(CompilationUnitElementInBuildUnit compilationUnit);
}

/// Specialization of [PropertyAccessorElementForLink] for synthetic accessors
/// implied by the synthetic fields of an enum declaration.
class PropertyAccessorElementForLink_EnumField
    with ReferenceableElementForLink
    implements PropertyAccessorElementForLink {
  @override
  final FieldElementForLink_EnumField variable;

  FunctionTypeImpl _type;

  PropertyAccessorElementForLink_EnumField(this.variable);

  @override
  DartType get asStaticType => returnType;

  @override
  Element get enclosingElement => variable.enclosingElement;

  @override
  bool get isAbstract => false;

  @override
  bool get isGetter => true;

  @override
  bool get isSetter => false;

  @override
  bool get isStatic => variable.isStatic;

  @override
  bool get isSynthetic => true;

  @override
  ElementKind get kind => ElementKind.GETTER;

  @override
  LibraryElementForLink get library =>
      variable.enclosingElement.enclosingElement.enclosingElement;

  @override
  String get name => variable.name;

  @override
  List<ParameterElement> get parameters => const [];

  @override
  DartType get returnType => variable.type;

  @override
  FunctionTypeImpl get type => _type ??= new FunctionTypeImpl(this);

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(library, this, name);
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    // TODO(paulberry): implement (should return the synthetic function element
    // for the enum field's initializer).
    return null;
  }

  @override
  bool isAccessibleIn(LibraryElement library) =>
      !Identifier.isPrivateName(name) || identical(this.library, library);

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Specialization of [PropertyAccessorElementForLink] for non-synthetic
/// accessors explicitly declared in the source code.
class PropertyAccessorElementForLink_Executable
    extends ExecutableElementForLink_NonLocal
    with ReferenceableElementForLink
    implements PropertyAccessorElementForLink {
  @override
  PropertyInducingElement variable;

  PropertyAccessorElementForLink_Executable(
      CompilationUnitElementForLink enclosingUnit,
      ClassElementForLink_Class enclosingClass,
      UnlinkedExecutable unlinkedExecutable,
      this.variable)
      : super(enclosingUnit, enclosingClass, unlinkedExecutable);

  @override
  DartType get asStaticType => returnType;

  @override
  PropertyAccessorElementForLink_Executable get correspondingGetter =>
      variable.getter;

  @override
  bool get isGetter =>
      serializedExecutable.kind == UnlinkedExecutableKind.getter;

  @override
  bool get isSetter =>
      serializedExecutable.kind == UnlinkedExecutableKind.setter;

  @override
  bool get isStatic => enclosingClass == null || super.isStatic;

  @override
  ElementKind get kind =>
      serializedExecutable.kind == UnlinkedExecutableKind.getter
          ? ElementKind.GETTER
          : ElementKind.SETTER;

  @override
  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(
        library as LibraryElementForLink, this, name);
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    // TODO(paulberry): implement
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Specialization of [PropertyAccessorElementForLink] for synthetic accessors
/// implied by a field or variable declaration.
class PropertyAccessorElementForLink_Variable
    with ReferenceableElementForLink
    implements PropertyAccessorElementForLink {
  @override
  final bool isSetter;

  final VariableElementForLink variable;
  FunctionTypeImpl _type;
  ParameterElementForLink_VariableSetter _parameter;
  List<ParameterElement> _parameters;

  PropertyAccessorElementForLink_Variable(this.variable, this.isSetter);

  @override
  ConstVariableNode get asConstVariable => variable._constNode;

  @override
  DartType get asStaticType => returnType;

  @override
  TypeInferenceNode get asTypeInferenceNode => variable._typeInferenceNode;

  @override
  String get displayName => variable.displayName;

  @override
  Element get enclosingElement => variable.enclosingElement;

  @override
  bool get isAbstract => false;

  @override
  bool get isGetter => !isSetter;

  @override
  bool get isStatic => variable.isStatic;

  @override
  bool get isSynthetic => true;

  @override
  ElementKind get kind => isSetter ? ElementKind.SETTER : ElementKind.GETTER;

  @override
  LibraryElementForLink get library =>
      variable.compilationUnit.enclosingElement;

  @override
  String get name => isSetter ? '${variable.name}=' : variable.name;

  @override
  List<ParameterElement> get parameters {
    if (_parameters == null) {
      _parameters = <ParameterElementForLink_VariableSetter>[];
      if (isSetter) {
        _parameter = new ParameterElementForLink_VariableSetter(this);
        _parameters.add(_parameter);
      }
    }
    return _parameters;
  }

  @override
  DartType get returnType {
    if (isSetter) {
      return VoidTypeImpl.instance;
    } else {
      return variable.type;
    }
  }

  @override
  FunctionTypeImpl get type => _type ??= new FunctionTypeImpl(this);

  @override
  List<TypeParameterElement> get typeParameters {
    // TODO(paulberry): is this correct for fields in generic classes?
    return const [];
  }

  @override
  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(library, this, name);
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    if (index == 0) {
      return variable.initializer;
    } else {
      return null;
    }
  }

  @override
  bool isAccessibleIn(LibraryElement library) =>
      !Identifier.isPrivateName(name) || identical(this.library, library);

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (isSetter && _parameter != null) {
      if (_parameter.inheritsCovariant) {
        compilationUnit._storeInheritsCovariant(
            variable.unlinkedVariable.inheritsCovariantSlot);
      }
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Base class representing an element which can be the target of a reference.
/// When used as a mixin, implements the default behavior shared by most
/// elements.
mixin ReferenceableElementForLink implements Element {
  /// If this element is a class reference, return it. Otherwise return `null`.
  ClassElementForLink get asClass => null;

  /// If this element can be used in a constructor invocation context,
  /// return the associated constructor (which may be `this` or some
  /// other element).  Otherwise return `null`.
  ConstructorElementForLink get asConstructor => null;

  /// If this element can be used in a getter context to refer to a
  /// constant variable, return the [ConstVariableNode] for the
  /// constant value.  Otherwise return `null`.
  ConstVariableNode get asConstVariable => null;

  /// Return the static type (possibly inferred) of the entity referred to by
  /// this element.
  DartType get asStaticType => DynamicTypeImpl.instance;

  /// If this element can be used in a getter context as a type inference
  /// dependency, return the [TypeInferenceNode] for the inferred type.
  /// Otherwise return `null`.
  TypeInferenceNode get asTypeInferenceNode => null;

  /// See [TypeParameterElement.isSimplyBounded].
  bool get isSimplyBounded => true;

  @override
  ElementLocation get location => new ElementLocationImpl.con1(this);

  /// If non-null, the [SimplyBoundedNode] for determining whether this element
  /// is simply bounded.
  ///
  /// If null, this element is known to be simply bounded based on its unlinked
  /// representation alone (for example, it is a class declaration with no type
  /// parameters, or it is a class declaration whose type parameters all lack
  /// explicit bounds).  Or it is an element for which simple boundedness is
  /// not relevant.
  SimplyBoundedNode get _simplyBoundedNode => null;

  /// Return the type indicated by this element when it is used in a
  /// type instantiation context.  If this element can't legally be
  /// instantiated as a type, return the dynamic type.
  ///
  /// If the type is parameterized, [getTypeArgument] will be called to retrieve
  /// the type parameters.  It should return `null` for unspecified type
  /// parameters.
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  /// If this element contains other named elements, return the
  /// contained element having the given [name].  If this element can't
  /// contain other named elements, or it doesn't contain an element
  /// with the given name, return the singleton of
  /// [UndefinedElementForLink].
  ReferenceableElementForLink getContainedName(String name) {
    // TODO(paulberry): handle references to `call` for function types.
    return UndefinedElementForLink.instance;
  }

  /// If this element contains local functions, return the contained local
  /// function having the given [index].  If this element doesn't contain local
  /// functions, or the index is out of range, return `null`.
  FunctionElementForLink_Local getLocalFunction(int index) => null;
}

/// Mixin providing the implementation of
/// [ReferenceableElementForLink.isSimplyBounded] for elements representing a
/// type.
abstract class SimplyBoundableForLinkMixin
    implements ReferenceableElementForLink {
  @override
  SimplyBoundedNode _simplyBoundedNode;

  CompilationUnitElementForLink get enclosingUnit;

  @override
  bool get isSimplyBounded {
    var slot = _notSimplyBoundedSlot;
    if (slot == 0) return true;
    if (enclosingUnit.isInBuildUnit) {
      assert(_simplyBoundedNode.isEvaluated);
      return _simplyBoundedNode.isSimplyBounded;
    } else {
      return !enclosingUnit._linkedUnit.notSimplyBounded.contains(slot);
    }
  }

  int get _notSimplyBoundedSlot;

  List<EntityRef> get _rhsTypesForSimplyBoundable;

  List<UnlinkedTypeParam> get _typeParametersForSimplyBoundable;

  void _initSimplyBoundable() {
    if (enclosingUnit.isInBuildUnit && _notSimplyBoundedSlot != 0) {
      _simplyBoundedNode = SimplyBoundedNode(enclosingUnit,
          _typeParametersForSimplyBoundable, _rhsTypesForSimplyBoundable);
    }
  }

  void _linkSimplyBoundable() {
    if (_simplyBoundedNode != null) {
      if (!_simplyBoundedNode.isEvaluated) {
        new SimplyBoundedDependencyWalker().walk(_simplyBoundedNode);
      }
      if (!_simplyBoundedNode.isSimplyBounded) {
        enclosingUnit._linkedUnit.notSimplyBounded.add(_notSimplyBoundedSlot);
      }
    }
  }
}

/// Specialization of [DependencyWalker] for evaluating whether types are simply
/// bounded.
class SimplyBoundedDependencyWalker
    extends DependencyWalker<SimplyBoundedNode> {
  @override
  void evaluate(SimplyBoundedNode v) {
    v._evaluate();
  }

  @override
  void evaluateScc(List<SimplyBoundedNode> scc) {
    for (var node in scc) {
      node._markCircular();
    }
  }
}

/// Specialization of [Node] used to construct the dependency graph for
/// evaluating whether types are simply bounded.
class SimplyBoundedNode extends Node<SimplyBoundedNode> {
  /// The compilation unit enclosing the type whose simple-boundedness we need
  /// to check
  final CompilationUnitElementForLink _unit;

  /// The type parameters of the type whose simple-boundedness we need to check
  final List<UnlinkedTypeParam> _typeParameters;

  /// If the type whose simple-boundedness we need to check is a typedef, the
  /// types appering in its "right hand side"
  final List<EntityRef> _rhsTypes;

  @override
  bool isEvaluated = false;

  /// After execution of [_evaluate], indicates whether the type is
  /// simply bounded.
  ///
  /// Prior to execution of [computeDependencies], `true`.
  ///
  /// Between execution of [computeDependencies] and [_evaluate], `true`
  /// indicates that the type is simply bounded only if all of its dependencies
  /// are simply bounded; `false` indicates that the type is not simply bounded.
  bool isSimplyBounded = true;

  SimplyBoundedNode(this._unit, this._typeParameters, this._rhsTypes);

  @override
  List<SimplyBoundedNode> computeDependencies() {
    var dependencies = <SimplyBoundedNode>[];
    for (var typeParameter in _typeParameters) {
      var bound = typeParameter.bound;
      if (bound != null) {
        if (!_visitType(dependencies, bound, true)) {
          // Note: we might consider setting isEvaluated=true here to prevent an
          // unnecessary call to SimplyBoundedDependencyWalker.evaluate.
          // However, we'd have to be careful to make sure this doesn't violate
          // an invariant of the DependencyWalker algorithm, since normally it
          // only expects isEvaluated to change during a call to .evaluate or
          // .evaluateScc.
          isSimplyBounded = false;
          return const [];
        }
      }
    }
    for (var type in _rhsTypes) {
      if (!_visitType(dependencies, type, false)) {
        // Note: we might consider setting isEvaluated=true here to prevent an
        // unnecessary call to SimplyBoundedDependencyWalker.evaluate.
        // However, we'd have to be careful to make sure this doesn't violate
        // an invariant of the DependencyWalker algorithm, since normally it
        // only expects isEvaluated to change during a call to .evaluate or
        // .evaluateScc.
        isSimplyBounded = false;
        return const [];
      }
    }
    return dependencies;
  }

  void _evaluate() {
    for (var dependency in _dependencies) {
      if (!dependency.isSimplyBounded) {
        isSimplyBounded = false;
        break;
      }
    }
    isEvaluated = true;
  }

  void _markCircular() {
    isSimplyBounded = false;
    isEvaluated = true;
  }

  /// Visits the parameters in [params], storing the [SimplyBoundedNode] for any
  /// types they reference in [dependencies].
  ///
  /// If a type is found that is already known to be not simply bounded (because
  /// it is in another build unit), or [disallowTypeParamReferences] is `true`
  /// and a reference to a type parameter is found, `false` is returned and
  /// further visiting is short-circuited.  Otherwise `true` is returned.
  bool _visitParams(List<SimplyBoundedNode> dependencies,
      List<UnlinkedParam> params, bool disallowTypeParamReferences) {
    for (var param in params) {
      if (!_visitType(dependencies, param.type, disallowTypeParamReferences)) {
        return false;
      }
      if (isSimplyBounded && param.isFunctionTyped) {
        if (!_visitParams(
            dependencies, param.parameters, disallowTypeParamReferences)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Visits the type specified by [type], storing the [SimplyBoundedNode] for
  /// any types it references in [dependencies].
  ///
  /// If a type is found that is already known to be not simply bounded (because
  /// it is in another build unit), or [disallowTypeParamReferences] is `true`
  /// and a reference to a type parameter is found, `false` is returned and
  //  /// further visiting is short-circuited.  Otherwise `true` is returned.
  bool _visitType(List<SimplyBoundedNode> dependencies, EntityRef type,
      bool disallowTypeParamReferences) {
    if (type != null) {
      if (type.paramReference != 0) {
        if (disallowTypeParamReferences) {
          return false;
        }
      } else if (type.entityKind == EntityRefKind.genericFunctionType) {
        if (!_visitParams(
            dependencies, type.syntheticParams, disallowTypeParamReferences)) {
          return false;
        }
        if (!_visitType(dependencies, type.syntheticReturnType,
            disallowTypeParamReferences)) {
          return false;
        }
      } else {
        if (type.typeArguments.isEmpty) {
          var ref = _unit.resolveRef(type.reference);
          var dep = ref._simplyBoundedNode;
          if (dep == null) {
            if (!ref.isSimplyBounded) {
              return false;
            }
          } else {
            dependencies.add(dep);
          }
        } else {
          for (var typeArgument in type.typeArguments) {
            if (!_visitType(
                dependencies, typeArgument, disallowTypeParamReferences)) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }
}

/// Element used for references to special types such as `void`.
class SpecialTypeElementForLink with ReferenceableElementForLink {
  final Linker linker;
  final DartType type;

  SpecialTypeElementForLink(this.linker, this.type);

  @override
  DartType get asStaticType => linker.typeProvider.typeType;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    return type;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => type.toString();
}

/// Element representing a synthetic variable resynthesized from a summary
/// during linking.
class SyntheticVariableElementForLink implements PropertyInducingElementImpl {
  PropertyAccessorElementForLink_Executable _getter;
  PropertyAccessorElementForLink_Executable _setter;

  @override
  PropertyAccessorElementForLink_Executable get getter => _getter;

  @override
  bool get isFinal => _setter == null;

  @override
  bool get isSynthetic => true;

  @override
  PropertyAccessorElementForLink_Executable get setter => _setter;

  @override
  void set type(DartType inferredType) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing a top-level function.
class TopLevelFunctionElementForLink extends ExecutableElementForLink_NonLocal
    with ReferenceableElementForLink
    implements FunctionElementImpl {
  DartType _returnType;

  TopLevelFunctionElementForLink(
      CompilationUnitElementForLink enclosingUnit, UnlinkedExecutable _buf)
      : super(enclosingUnit, null, _buf);

  @override
  DartType get asStaticType => type;

  @override
  String get identifier => serializedExecutable.name;

  @override
  bool get isStatic => true;

  @override
  ElementKind get kind => ElementKind.FUNCTION;

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    // TODO(paulberry): implement.
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Element representing a top level variable resynthesized from a
/// summary during linking.
class TopLevelVariableElementForLink extends VariableElementForLink
    implements TopLevelVariableElement {
  TopLevelVariableElementForLink(CompilationUnitElementForLink enclosingElement,
      UnlinkedVariable unlinkedVariable, Expression initializerForInference)
      : super(unlinkedVariable, enclosingElement, initializerForInference);

  @override
  CompilationUnitElementForLink get enclosingElement => compilationUnit;

  @override
  bool get isStatic => true;

  @override
  LibraryElementForLink get library => compilationUnit.library;

  @override
  TypeParameterizedElementMixin get _typeParameterContext => null;

  /// Store the results of type inference for this variable in
  /// [compilationUnit].
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (hasImplicitType) {
      TypeInferenceNode typeInferenceNode = this._typeInferenceNode;
      if (typeInferenceNode != null) {
        compilationUnit._storeLinkedType(
            unlinkedVariable.inferredTypeSlot, inferredType, null);
        compilationUnit._storeLinkedTypeError(
            unlinkedVariable.inferredTypeSlot, initializer._inferenceError);
      }
      initializer?.link(compilationUnit);
    }
  }
}

/// Specialization of [DependencyWalker] for performing type inference on static
/// and top level variables.
class TypeInferenceDependencyWalker
    extends DependencyWalker<TypeInferenceNode> {
  @override
  void evaluate(TypeInferenceNode v) {
    v.evaluate(null);
  }

  @override
  void evaluateScc(List<TypeInferenceNode> scc) {
    for (TypeInferenceNode v in scc) {
      v.evaluate(scc);
    }
  }
}

/// Specialization of [Node] used to construct the type inference dependency
/// graph.
class TypeInferenceNode extends Node<TypeInferenceNode> {
  /// The [FunctionElementForLink_Local] to which this node refers.
  final FunctionElementForLink_Local functionElement;

  TypeInferenceNode(this.functionElement);

  @override
  bool get isEvaluated => functionElement._hasTypeBeenInferred;

  /// Collect the type inference dependencies in [unlinkedExecutable] (which
  /// should be interpreted relative to [compilationUnit]) and store them in
  /// [dependencies].
  void collectDependencies(
      List<TypeInferenceNode> dependencies,
      UnlinkedExecutable unlinkedExecutable,
      CompilationUnitElementForLink compilationUnit) {
    UnlinkedExpr unlinkedConst = unlinkedExecutable?.bodyExpr;
    if (unlinkedConst == null) {
      return;
    }
    int refPtr = 0;
    int intPtr = 0;

    for (UnlinkedExprOperation operation in unlinkedConst.operations) {
      switch (operation) {
        case UnlinkedExprOperation.pushInt:
          intPtr++;
          break;
        case UnlinkedExprOperation.pushLongInt:
          int numInts = unlinkedConst.ints[intPtr++];
          intPtr += numInts;
          break;
        case UnlinkedExprOperation.concatenate:
          intPtr++;
          break;
        case UnlinkedExprOperation.pushReference:
          EntityRef ref = unlinkedConst.references[refPtr++];
          // TODO(paulberry): cache these resolved references for
          // later use by evaluate().
          TypeInferenceNode dependency =
              compilationUnit.resolveRef(ref.reference).asTypeInferenceNode;
          if (dependency != null) {
            dependencies.add(dependency);
          }
          break;
        case UnlinkedExprOperation.invokeConstructor:
          refPtr++;
          intPtr += 2;
          break;
        case UnlinkedExprOperation.makeUntypedList:
        case UnlinkedExprOperation.makeUntypedMap:
        case UnlinkedExprOperation.makeUntypedSet:
        case UnlinkedExprOperation.makeUntypedSetOrMap:
        case UnlinkedExprOperation.forParts:
        case UnlinkedExprOperation.variableDeclaration:
        case UnlinkedExprOperation.forInitializerDeclarationsUntyped:
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedList:
        case UnlinkedExprOperation.makeTypedSet:
        case UnlinkedExprOperation.forInitializerDeclarationsTyped:
          refPtr++;
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedMap:
        case UnlinkedExprOperation.makeTypedMap2:
          refPtr += 2;
          intPtr++;
          break;
        case UnlinkedExprOperation.assignToRef:
          EntityRef ref = unlinkedConst.references[refPtr++];
          // TODO(paulberry): cache these resolved references for
          // later use by evaluate().
          TypeInferenceNode dependency =
              compilationUnit.resolveRef(ref.reference).asTypeInferenceNode;
          if (dependency != null) {
            dependencies.add(dependency);
          }
          break;
        case UnlinkedExprOperation.invokeMethodRef:
          EntityRef ref = unlinkedConst.references[refPtr++];
          TypeInferenceNode dependency =
              compilationUnit.resolveRef(ref.reference).asTypeInferenceNode;
          if (dependency != null) {
            dependencies.add(dependency);
          }
          intPtr += 2;
          int numTypeArguments = unlinkedConst.ints[intPtr++];
          refPtr += numTypeArguments;
          break;
        case UnlinkedExprOperation.invokeMethod:
          intPtr += 2;
          int numTypeArguments = unlinkedConst.ints[intPtr++];
          refPtr += numTypeArguments;
          break;
        case UnlinkedExprOperation.typeCast:
        case UnlinkedExprOperation.typeCheck:
        case UnlinkedExprOperation.forEachPartsWithTypedDeclaration:
          refPtr++;
          break;
        case UnlinkedExprOperation.pushLocalFunctionReference:
          int popCount = unlinkedConst.ints[intPtr++];
          assert(popCount == 0); // TODO(paulberry): handle the nonzero case.
          dependencies.add(functionElement
              .getLocalFunction(unlinkedConst.ints[intPtr++])
              .asTypeInferenceNode);
          break;
        default:
          break;
      }
    }
    assert(refPtr == unlinkedConst.references.length);
    assert(intPtr == unlinkedConst.ints.length);
  }

  @override
  List<TypeInferenceNode> computeDependencies() {
    List<TypeInferenceNode> dependencies = <TypeInferenceNode>[];
    collectDependencies(dependencies, functionElement.serializedExecutable,
        functionElement.compilationUnit);
    return dependencies;
  }

  void evaluate(List<TypeInferenceNode> cycle) {
    if (cycle != null) {
      List<String> cycleNames = cycle
          .map((node) {
            Element e = node.functionElement;
            while (e != null) {
              if (e is VariableElement) {
                return e.name;
              }
              e = e.enclosingElement;
            }
            return '<unknown>';
          })
          .toSet()
          .toList();
      functionElement._setInferenceError(new TopLevelInferenceErrorBuilder(
          kind: TopLevelInferenceErrorKind.dependencyCycle,
          arguments: cycleNames));
      functionElement._setInferredType(DynamicTypeImpl.instance);
    } else {
      var computer = new ExprTypeComputer(functionElement);
      DartType bodyType = computer.compute();
      if (computer.errorKind != null) {
        functionElement._setInferenceError(
            new TopLevelInferenceErrorBuilder(kind: computer.errorKind));
        functionElement._setInferredType(DynamicTypeImpl.instance);
      } else {
        if (functionElement.isAsynchronous) {
          var linker = functionElement.compilationUnit.library._linker;
          var typeProvider = linker.typeProvider;
          var typeSystem = linker.typeSystem;
          if (bodyType.isDartAsyncFutureOr) {
            bodyType = (bodyType as InterfaceType).typeArguments[0];
          }
          bodyType = typeProvider.futureType
              .instantiate([typeSystem.flatten(bodyType)]);
        }
        functionElement._setInferredType(bodyType);
      }
    }
  }

  @override
  String toString() => 'TypeInferenceNode($functionElement)';
}

class TypeProviderForLink extends TypeProviderBase {
  final Linker _linker;

  InterfaceType _boolType;
  InterfaceType _deprecatedType;
  InterfaceType _doubleType;
  InterfaceType _functionType;
  InterfaceType _futureDynamicType;
  InterfaceType _futureNullType;
  InterfaceType _futureOrNullType;
  InterfaceType _futureOrType;
  InterfaceType _futureType;
  InterfaceType _intType;
  InterfaceType _iterableDynamicType;
  InterfaceType _iterableObjectType;
  InterfaceType _iterableType;
  InterfaceType _listType;
  InterfaceType _mapType;
  InterfaceType _mapObjectObjectType;
  InterfaceType _nullType;
  InterfaceType _numType;
  InterfaceType _objectType;
  InterfaceType _setType;
  InterfaceType _stackTraceType;
  InterfaceType _streamDynamicType;
  InterfaceType _streamType;
  InterfaceType _stringType;
  InterfaceType _symbolType;
  InterfaceType _typeType;

  TypeProviderForLink(this._linker);

  @override
  InterfaceType get boolType =>
      _boolType ??= _buildInterfaceType(_linker.coreLibrary, 'bool');

  @override
  DartType get bottomType => BottomTypeImpl.instance;

  @override
  InterfaceType get deprecatedType => _deprecatedType ??=
      _buildInterfaceType(_linker.coreLibrary, 'Deprecated');

  @override
  InterfaceType get doubleType =>
      _doubleType ??= _buildInterfaceType(_linker.coreLibrary, 'double');

  @override
  DartType get dynamicType => DynamicTypeImpl.instance;

  @override
  InterfaceType get functionType =>
      _functionType ??= _buildInterfaceType(_linker.coreLibrary, 'Function');

  @override
  InterfaceType get futureDynamicType =>
      _futureDynamicType ??= futureType.instantiate(<DartType>[dynamicType]);

  @override
  InterfaceType get futureNullType =>
      _futureNullType ??= futureType.instantiate(<DartType>[nullType]);

  @override
  InterfaceType get futureOrNullType =>
      _futureOrNullType ??= futureOrType.instantiate(<DartType>[nullType]);

  @override
  InterfaceType get futureOrType =>
      _futureOrType ??= _buildInterfaceType(_linker.asyncLibrary, 'FutureOr');

  @override
  InterfaceType get futureType =>
      _futureType ??= _buildInterfaceType(_linker.asyncLibrary, 'Future');

  @override
  InterfaceType get intType =>
      _intType ??= _buildInterfaceType(_linker.coreLibrary, 'int');

  @override
  InterfaceType get iterableDynamicType => _iterableDynamicType ??=
      iterableType.instantiate(<DartType>[dynamicType]);

  @override
  InterfaceType get iterableObjectType =>
      _iterableObjectType ??= iterableType.instantiate(<DartType>[objectType]);

  @override
  InterfaceType get iterableType =>
      _iterableType ??= _buildInterfaceType(_linker.coreLibrary, 'Iterable');

  @override
  InterfaceType get listType =>
      _listType ??= _buildInterfaceType(_linker.coreLibrary, 'List');

  @override
  InterfaceType get mapObjectObjectType => _mapObjectObjectType ??=
      mapType.instantiate(<DartType>[objectType, objectType]);

  @override
  InterfaceType get mapType =>
      _mapType ??= _buildInterfaceType(_linker.coreLibrary, 'Map');

  @override
  DartType get neverType => BottomTypeImpl.instance;

  @override
  DartObjectImpl get nullObject {
    // TODO(paulberry): implement if needed
    throw new UnimplementedError();
  }

  @override
  InterfaceType get nullType =>
      _nullType ??= _buildInterfaceType(_linker.coreLibrary, 'Null');

  @override
  InterfaceType get numType =>
      _numType ??= _buildInterfaceType(_linker.coreLibrary, 'num');

  @override
  InterfaceType get objectType =>
      _objectType ??= _buildInterfaceType(_linker.coreLibrary, 'Object');

  @override
  InterfaceType get setType =>
      _setType ??= _buildInterfaceType(_linker.coreLibrary, 'Set');

  @override
  InterfaceType get stackTraceType => _stackTraceType ??=
      _buildInterfaceType(_linker.coreLibrary, 'StackTrace');

  @override
  InterfaceType get streamDynamicType =>
      _streamDynamicType ??= streamType.instantiate(<DartType>[dynamicType]);

  @override
  InterfaceType get streamType =>
      _streamType ??= _buildInterfaceType(_linker.asyncLibrary, 'Stream');

  @override
  InterfaceType get stringType =>
      _stringType ??= _buildInterfaceType(_linker.coreLibrary, 'String');

  @override
  InterfaceType get symbolType =>
      _symbolType ??= _buildInterfaceType(_linker.coreLibrary, 'Symbol');

  @override
  InterfaceType get typeType =>
      _typeType ??= _buildInterfaceType(_linker.coreLibrary, 'Type');

  InterfaceType _buildInterfaceType(
      LibraryElementForLink library, String name) {
    return library.getContainedName(name).buildType((int i) {
      // TODO(scheglov) accept type parameter names
      var element = new TypeParameterElementImpl('T$i', -1);
      return new TypeParameterTypeImpl(element);
    }, const []);
  }
}

/// Singleton element used for unresolved references.
class UndefinedElementForLink with ReferenceableElementForLink {
  static final UndefinedElementForLink instance =
      new UndefinedElementForLink._();

  UndefinedElementForLink._();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Element representing a top level variable resynthesized from a
/// summary during linking.
abstract class VariableElementForLink
    implements NonParameterVariableElementImpl, PropertyInducingElement {
  /// The unlinked representation of the variable in the summary.
  final UnlinkedVariable unlinkedVariable;

  /// If non-null, the AST for the initializer expression; this is used for
  /// inferring the expression type.
  final Expression _initializerForInference;

  /// If this variable is declared `const` and the enclosing library is
  /// part of the build unit being linked, the variable's node in the
  /// constant evaluation dependency graph.  Otherwise `null`.
  ConstNode _constNode;

  /// If this variable has an initializer and an implicit type, and the
  /// enclosing library is part of the build unit being linked, the variable's
  /// node in the type inference dependency graph.  Otherwise `null`.
  TypeInferenceNode _typeInferenceNode;

  FunctionElementForLink_Initializer _initializer;
  DartType _inferredType;
  DartType _declaredType;
  PropertyAccessorElementForLink_Variable _getter;
  PropertyAccessorElementForLink_Variable _setter;

  /// The compilation unit in which this variable appears.
  final CompilationUnitElementForLink compilationUnit;

  VariableElementForLink(this.unlinkedVariable, this.compilationUnit,
      this._initializerForInference) {
    if (!compilationUnit.isInBuildUnit) return;
    if (unlinkedVariable.initializer?.bodyExpr == null) {
      if (_initializerForInference == null) return;
    } else {
      _constNode = new ConstVariableNode(this);
    }
    if (unlinkedVariable.type == null) {
      _typeInferenceNode = initializer.asTypeInferenceNode;
    }
  }

  /// If the variable has an explicitly declared return type, return it.
  /// Otherwise return `null`.
  DartType get declaredType {
    if (unlinkedVariable.type == null) {
      return null;
    } else {
      return _declaredType ??=
          compilationUnit.resolveTypeRef(this, unlinkedVariable.type);
    }
  }

  @override
  String get displayName => unlinkedVariable.name;

  @override
  PropertyAccessorElementForLink_Variable get getter =>
      _getter ??= new PropertyAccessorElementForLink_Variable(this, false);

  @override
  bool get hasImplicitType => unlinkedVariable.type == null;

  @override
  String get identifier => unlinkedVariable.name;

  /// Return the inferred type of the variable element.  Should only be called
  /// if no type was explicitly declared.
  DartType get inferredType {
    // We should only try to infer a type when none is explicitly declared.
    assert(unlinkedVariable.type == null);
    if (_inferredType == null) {
      if (_typeInferenceNode != null) {
        assert(Linker._initializerTypeInferenceCycle == null);
        Linker._initializerTypeInferenceCycle =
            compilationUnit.library.libraryCycleForLink;
        Linker._isPerformingVariableTypeInference = true;
        try {
          new TypeInferenceDependencyWalker().walk(_typeInferenceNode);
          assert(_inferredType != null);
        } finally {
          Linker._initializerTypeInferenceCycle = null;
          Linker._isPerformingVariableTypeInference = false;
        }
      } else if (compilationUnit.isInBuildUnit) {
        _inferredType = DynamicTypeImpl.instance;
      } else {
        _inferredType = compilationUnit.getLinkedType(
            this, unlinkedVariable.inferredTypeSlot);
      }
    }
    return _inferredType;
  }

  @override
  FunctionElementForLink_Initializer get initializer {
    if (unlinkedVariable.initializer == null) {
      return null;
    } else {
      return _initializer ??= new FunctionElementForLink_Initializer(
          this, _initializerForInference);
    }
  }

  @override
  bool get isConst => unlinkedVariable.isConst;

  /// Return `true` if this variable is a field that was explicitly marked as
  /// being covariant (in the setter's parameter).
  bool get isCovariant => unlinkedVariable.isCovariant;

  @override
  bool get isFinal => unlinkedVariable.isFinal;

  @override
  bool get isStatic;

  @override
  bool get isSynthetic => false;

  @override
  String get name => unlinkedVariable.name;

  @override
  DartType get propagatedType {
    return DynamicTypeImpl.instance;
  }

  @override
  PropertyAccessorElementForLink_Variable get setter {
    if (!isConst && !isFinal) {
      return _setter ??=
          new PropertyAccessorElementForLink_Variable(this, true);
    } else {
      return null;
    }
  }

  @override
  DartType get type => declaredType ?? inferredType;

  @override
  void set type(DartType newType) {
    // TODO(paulberry): store inferred type.
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext {
    return _typeParameterContext;
  }

  /// The context in which type parameters should be interpreted, or `null` if
  /// there are no type parameters in scope.
  TypeParameterizedElementMixin get _typeParameterContext;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/// Specialization of [LibraryResynthesizer] for resynthesis during linking.
class _LibraryResynthesizer extends LibraryResynthesizerMixin {
  LibraryElementForLink _library;

  @override
  LibraryElement get library => _library;

  @override
  List<LinkedExportName> get linkedExportNames => _library._linkedExportNames;

  @override
  Element buildExportName(LinkedExportName exportName) {
    LibraryElementForLink dependency =
        _library.buildImportedLibrary(exportName.dependency);
    return dependency.getContainedName(exportName.name);
  }
}

/// Specialization of [ReferenceInfo] for resynthesis during linking.
class _ReferenceInfo extends ReferenceInfo {
  @override
  final ReferenceableElementForLink element;

  @override
  final ReferenceInfo enclosing;

  @override
  final String name;

  @override
  final bool hasTypeParameters;

  _ReferenceInfo(
      this.enclosing, this.element, this.name, this.hasTypeParameters);

  /// TODO(paulberry): this method doesn't seem to be used.  Investigate whether
  /// it is needed.
  @override
  DartType get type => throw new UnimplementedError();
}

/// Specialization of [UnitResynthesizer] for resynthesis during linking.
class _UnitResynthesizer extends UnitResynthesizer with UnitResynthesizerMixin {
  CompilationUnitElementForLink _unit;

  @override
  LibraryElement get library => _unit.library;

  @override
  TypeProvider get typeProvider => _unit.library._linker.typeProvider;

  @override
  TypeSystem get typeSystem => _unit.library._linker._typeSystem;

  @override
  DartType buildType(ElementImpl context, EntityRef type) =>
      _unit.resolveTypeRef(context, type);

  @override
  DartType buildTypeForClassInfo(
      info, int numTypeArguments, DartType Function(int i) getTypeArgument) {
    ClassElementForLink class_ = info.element;
    if (numTypeArguments == 0) {
      DartType type = class_.typeWithDefaultBounds;
      _typesWithImplicitArguments[type] = true;
      return type;
    }
    return class_.buildType(getTypeArgument, const []);
  }

  @override
  bool doesTypeHaveImplicitArguments(ParameterizedType type) =>
      _typesWithImplicitArguments[type] != null;

  @override
  _ReferenceInfo getReferenceInfo(int index) {
    return _unit.resolveRefToInfo(index);
  }
}
