// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library is capable of producing linked summaries from unlinked
 * ones (or prelinked ones).  It functions by building a miniature
 * element model to represent the contents of the summaries, and then
 * scanning the element model to gather linked information and adding
 * it to the summary data structures.
 *
 * The reason we use a miniature element model to do the linking
 * (rather than resynthesizing the full element model from the
 * summaries) is that it is expected that we will only need to
 * traverse a small subset of the element properties in order to link.
 * Resynthesizing only those properties that we need should save
 * substantial CPU time.
 *
 * The element model implements the same interfaces as the full
 * element model, so we can re-use code elsewhere in the analysis
 * engine to do the linking.  However, only a small subset of the
 * methods and getters defined in the full element model are
 * implemented here.  To avoid static warnings, each element model
 * class contains an implementation of `noSuchMethod`.
 *
 * The miniature element model follows the following design
 * principles:
 *
 * - With few exceptions, resynthesis is done incrementally on demand,
 *   so that we don't pay the cost of resynthesizing elements (or
 *   properties of elements) that aren't referenced from a part of the
 *   element model that is relevant to linking.
 *
 * - Computation of values in the miniature element model is similar
 *   to the task model, but much lighter weight.  Instead of declaring
 *   tasks and their relationships using classes, each task is simply
 *   a method (frequently a getter) that computes a value.  Instead of
 *   using a general purpose cache, values are cached by the methods
 *   themselves in private fields (with `null` typically representing
 *   "not yet cached").
 *
 * - No attempt is made to detect cyclic dependencies due to bugs in
 *   the analyzer.  This saves time because dependency evaluation
 *   doesn't have to be a separate step from evaluating a value; we
 *   can simply call the getter.
 *
 * - However, for cases where cyclic dependencies may occur in the
 *   absence of analyzer bugs (e.g. because of errors in the code
 *   being analyzed, or cycles between top level and static variables
 *   undergoing type inference), we do precompute dependencies, and we
 *   use Tarjan's strongly connected components algorithm to detect
 *   cycles.
 *
 * - As much as possible, bookkeeping data is pointed to directly by
 *   the element objects, rather than being stored in maps.
 *
 * - Where possible, we favor method dispatch instead of "is" and "as"
 *   checks.  E.g. see [ReferenceableElementForLink.asConstructor].
 */
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/inheritance_manager.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/task/strong_mode.dart';
import 'package:front_end/src/dependency_walker.dart';

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

/**
 * Link together the build unit consisting of [libraryUris], using
 * [getDependency] to fetch the [LinkedLibrary] objects from other
 * build units, and [getUnit] to fetch the [UnlinkedUnit] objects from
 * both this build unit and other build units.
 *
 * The [strong] flag controls whether type inference is performed in strong
 * mode or spec mode.  Note that in spec mode, the only types that are inferred
 * are the types of initializing formals, which are inferred from the types of
 * the corresponding fields.
 *
 * A map is returned whose keys are the URIs of the libraries in this
 * build unit, and whose values are the corresponding
 * [LinkedLibraryBuilder]s.
 */
Map<String, LinkedLibraryBuilder> link(
    Set<String> libraryUris,
    GetDependencyCallback getDependency,
    GetUnitCallback getUnit,
    GetDeclaredVariable getDeclaredVariable,
    bool strong) {
  Map<String, LinkedLibraryBuilder> linkedLibraries =
      setupForLink(libraryUris, getUnit, getDeclaredVariable);
  relink(linkedLibraries, getDependency, getUnit, strong);
  return linkedLibraries;
}

/**
 * Given [libraries] (a map from URI to [LinkedLibraryBuilder]
 * containing correct prelinked information), rebuild linked
 * information, using [getDependency] to fetch the [LinkedLibrary]
 * objects from other build units, and [getUnit] to fetch the
 * [UnlinkedUnit] objects from both this build unit and other build
 * units.
 *
 * The [strong] flag controls whether type inference is performed in strong
 * mode or spec mode.  Note that in spec mode, the only types that are inferred
 * are the types of initializing formals, which are inferred from the types of
 * the corresponding fields.
 */
void relink(Map<String, LinkedLibraryBuilder> libraries,
    GetDependencyCallback getDependency, GetUnitCallback getUnit, bool strong) {
  new Linker(libraries, getDependency, getUnit, strong).link();
}

/**
 * Prepare to link together the build unit consisting of [libraryUris], using
 * [getUnit] to fetch the [UnlinkedUnit] objects from both this build unit and
 * other build units.
 *
 * The libraries are prelinked, and a map is returned whose keys are the URIs of
 * the libraries in this build unit, and whose values are the corresponding
 * [LinkedLibraryBuilder]s.
 */
Map<String, LinkedLibraryBuilder> setupForLink(Set<String> libraryUris,
    GetUnitCallback getUnit, GetDeclaredVariable getDeclaredVariable) {
  Map<String, LinkedLibraryBuilder> linkedLibraries =
      <String, LinkedLibraryBuilder>{};
  for (String absoluteUri in libraryUris) {
    linkedLibraries[absoluteUri] = prelink(
        absoluteUri,
        getUnit(absoluteUri),
        getUnit,
        (String absoluteUri) => getUnit(absoluteUri)?.publicNamespace,
        getDeclaredVariable);
  }
  return linkedLibraries;
}

/**
 * Create an [EntityRefBuilder] representing the given [type], in a form
 * suitable for inclusion in [LinkedUnit.types].  [compilationUnit] is the
 * compilation unit in which the type will be used.  If [slot] is provided, it
 * is stored in [EntityRefBuilder.slot].
 */
EntityRefBuilder _createLinkedType(
    DartType type,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterizedElementMixin typeParameterContext,
    {int slot}) {
  EntityRefBuilder result = new EntityRefBuilder(slot: slot);
  if (type is InterfaceType) {
    ClassElementForLink element = type.element;
    result.reference = compilationUnit.addReference(element);
    _storeTypeArguments(
        type.typeArguments, result, compilationUnit, typeParameterContext);
    return result;
  } else if (type is DynamicTypeImpl) {
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
    if (typeParameterContext.isTypeParameterInScope(element)) {
      result.paramReference =
          typeParameterContext.typeParameterNestingLevel - element.nestingLevel;
    } else {
      throw new StateError('The type parameter $type (in ${element?.location}) '
          'is out of scope on ${typeParameterContext?.location}.');
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
    if (element is FunctionElement && element.enclosingElement == null) {
      // Element is a synthetic function element that was generated on the fly
      // to represent a type that has no associated source code location.
      _storeFunctionElementByValue(result, element, compilationUnit);
      return result;
    }
    if (element is FunctionElement) {
      // Element is a local function inside another executable.
      result.reference = compilationUnit.addReference(element);
      _storeFunctionElementByValue(result, element, compilationUnit);
      // TODO(paulberry): do I need to store type arguments?
      return result;
    }
    if (element is GenericFunctionTypeElement) {
      result.entityKind = EntityRefKind.genericFunctionType;
      result.syntheticReturnType = _createLinkedType(
          type.returnType, compilationUnit, typeParameterContext);
      result.syntheticParams = type.parameters
          .map((ParameterElement param) => _serializeSyntheticParam(
              param, compilationUnit, typeParameterContext))
          .toList();
      return result;
    }
    // TODO(paulberry): implement other cases.
    throw new UnimplementedError('${element.runtimeType}');
  }
  // TODO(paulberry): implement other cases.
  throw new UnimplementedError('${type.runtimeType}');
}

DartType _dynamicIfNull(DartType type) {
  if (type == null || type.isBottom || type.isDartCoreNull) {
    return DynamicTypeImpl.instance;
  }
  return type;
}

/**
 * Create an [UnlinkedParam] representing the given [parameter], which should be
 * a parameter of a synthetic function type (e.g. one produced during type
 * inference as a result of computing the least upper bound of two function
 * types).
 */
UnlinkedParamBuilder _serializeSyntheticParam(
    ParameterElement parameter,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterizedElementMixin typeParameterContext) {
  UnlinkedParamBuilder b = new UnlinkedParamBuilder();
  b.name = parameter.name;
  switch (parameter.parameterKind) {
    case ParameterKind.REQUIRED:
      b.kind = UnlinkedParamKind.required;
      break;
    case ParameterKind.POSITIONAL:
      b.kind = UnlinkedParamKind.positional;
      break;
    case ParameterKind.NAMED:
      b.kind = UnlinkedParamKind.named;
      break;
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

/**
 * Create an [UnlinkedTypeParamBuilder] representing the given [typeParameter],
 * which should be a type parameter of a synthetic function type (e.g. one
 * produced during type inference as a result of computing the least upper
 * bound of two function types).
 */
UnlinkedTypeParamBuilder _serializeSyntheticTypeParameter(
    TypeParameterElement typeParameter,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterizedElementMixin typeParameterContext) {
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

/**
 * Store the given function [element] into the [entity] by value.
 */
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

/**
 * Store the given [typeArguments] in [encodedType], using [compilationUnit] and
 * [typeParameterContext] to serialize them.
 */
void _storeTypeArguments(
    List<DartType> typeArguments,
    EntityRefBuilder encodedType,
    CompilationUnitElementInBuildUnit compilationUnit,
    TypeParameterizedElementMixin typeParameterContext) {
  int count = typeArguments.length;
  List<EntityRefBuilder> encodedTypeArguments =
      new List<EntityRefBuilder>(count);
  for (int i = 0; i < count; i++) {
    encodedTypeArguments[i] = _createLinkedType(
        typeArguments[i], compilationUnit, typeParameterContext);
  }
  encodedType.typeArguments = encodedTypeArguments;
}

/**
 * Type of the callback used by [link] and [relink] to request
 * [LinkedLibrary] objects from other build units.
 */
typedef LinkedLibrary GetDependencyCallback(String absoluteUri);

/**
 * Type of the callback used by [link] and [relink] to request
 * [UnlinkedUnit] objects.
 */
typedef UnlinkedUnit GetUnitCallback(String absoluteUri);

/**
 * Stub implementation of [AnalysisOptions] used during linking.
 */
class AnalysisOptionsForLink implements AnalysisOptions {
  final Linker _linker;

  AnalysisOptionsForLink(this._linker);

  @override
  bool get strongMode => _linker.strongMode;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a class or enum resynthesized from a summary
 * during linking.
 */
abstract class ClassElementForLink extends Object
    with ReferenceableElementForLink
    implements AbstractClassElementImpl {
  Map<String, ReferenceableElementForLink> _containedNames;

  @override
  final CompilationUnitElementForLink enclosingElement;

  /// TODO(brianwilkerson) This appears to be unused and might be removable.
  bool hasBeenInferred;

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
  CompilationUnitElementImpl get enclosingUnit => enclosingElement;

  @override
  List<FieldElementForLink> get fields;

  /**
   * Indicates whether this is the core class `Object`.
   */
  bool get isObject;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  List<MethodElementForLink> get methods;

  @override
  String get name;

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

  /**
   * Perform type inference and cycle detection on this class and
   * store the resulting information in [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a class resynthesized from a summary during
 * linking.
 */
class ClassElementForLink_Class extends ClassElementForLink
    with TypeParameterizedElementMixin
    implements ClassElementImpl {
  /**
   * The unlinked representation of the class in the summary.
   */
  final UnlinkedClass _unlinkedClass;

  List<ConstructorElementForLink> _constructors;
  ConstructorElementForLink _unnamedConstructor;
  bool _unnamedConstructorComputed = false;
  List<FieldElementForLink_ClassField> _fields;
  InterfaceType _supertype;
  InterfaceType _type;
  List<MethodElementForLink> _methods;
  List<InterfaceType> _mixins;
  List<InterfaceType> _interfaces;
  List<PropertyAccessorElementForLink> _accessors;

  ClassElementForLink_Class(
      CompilationUnitElementForLink enclosingElement, this._unlinkedClass)
      : super(enclosingElement);

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
      for (UnlinkedVariable field in _unlinkedClass.fields) {
        _fields.add(new FieldElementForLink_ClassField(this, field));
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
  List<InterfaceType> get mixins =>
      _mixins ??= _unlinkedClass.mixins.map(_computeInterfaceType).toList();

  @override
  String get name => _unlinkedClass.name;

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
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    for (ConstructorElementForLink constructorElement in constructors) {
      constructorElement.link(compilationUnit);
    }
    if (library._linker.strongMode) {
      for (MethodElementForLink methodElement in methods) {
        methodElement.link(compilationUnit);
      }
      for (PropertyAccessorElementForLink propertyAccessorElement
          in accessors) {
        propertyAccessorElement.link(compilationUnit);
      }
      for (FieldElementForLink_ClassField fieldElement in fields) {
        fieldElement.link(compilationUnit);
      }
    }
  }

  @override
  String toString() => '$enclosingElement.$name';

  /**
   * Convert [typeRef] into an [InterfaceType].
   */
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
}

/**
 * Element representing an enum resynthesized from a summary during
 * linking.
 */
class ClassElementForLink_Enum extends ClassElementForLink
    implements EnumElementImpl {
  /**
   * The unlinked representation of the enum in the summary.
   */
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
  bool get isEnum => true;

  @override
  bool get isObject => false;

  @override
  List<MethodElementForLink> get methods => const [];

  @override
  List<InterfaceType> get mixins => const [];

  @override
  String get name => _unlinkedEnum.name;

  @override
  InterfaceType get supertype => library._linker.typeProvider.objectType;

  @override
  InterfaceType get type => _type ??= new InterfaceTypeImpl(this);

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  ConstructorElementForLink get unnamedConstructor => null;

  /**
   * Get the type of the enum's static member `values`.
   */
  DartType get valuesType =>
      _valuesType ??= library._linker.typeProvider.listType.instantiate([type]);

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      type;

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {}

  @override
  String toString() => '$enclosingElement.$name';
}

/**
 * Element representing a compilation unit resynthesized from a
 * summary during linking.
 */
abstract class CompilationUnitElementForLink
    implements CompilationUnitElementImpl, ResynthesizerContext {
  /**
   * The unlinked representation of the compilation unit in the
   * summary.
   */
  final UnlinkedUnit _unlinkedUnit;

  /**
   * For each entry in [UnlinkedUnit.references], the element referred
   * to by the reference, or `null` if it hasn't been located yet.
   */
  final List<ReferenceableElementForLink> _references;

  /**
   * The absolute URI of this compilation unit.
   */
  final String _absoluteUri;

  List<ClassElementForLink_Class> _types;
  Map<String, ReferenceableElementForLink> _containedNames;
  List<TopLevelVariableElementForLink> _topLevelVariables;
  List<ClassElementForLink_Enum> _enums;
  List<TopLevelFunctionElementForLink> _functions;
  List<PropertyAccessorElementForLink> _accessors;
  List<FunctionTypeAliasElementForLink> _functionTypeAliases;

  /**
   * Index of this unit in the list of units in the enclosing library.
   */
  final int unitNum;

  CompilationUnitElementForLink(UnlinkedUnit unlinkedUnit, this.unitNum,
      int numReferences, this._absoluteUri)
      : _references = new List<ReferenceableElementForLink>(numReferences),
        _unlinkedUnit = unlinkedUnit;

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
        }
      }).toList();

  @override
  String get identifier => _absoluteUri;

  /**
   * Indicates whether this compilation element is part of the build unit
   * currently being linked.
   */
  bool get isInBuildUnit;

  /**
   * Determine whether type inference is complete in this compilation unit.
   */
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
  ResynthesizerContext get resynthesizerContext => this;

  @override
  List<TopLevelVariableElementForLink> get topLevelVariables {
    if (_topLevelVariables == null) {
      _topLevelVariables = <TopLevelVariableElementForLink>[];
      for (UnlinkedVariable unlinkedVariable in _unlinkedUnit.variables) {
        _topLevelVariables
            .add(new TopLevelVariableElementForLink(this, unlinkedVariable));
      }
    }
    return _topLevelVariables;
  }

  @override
  List<ClassElementForLink_Class> get types {
    if (_types == null) {
      _types = <ClassElementForLink_Class>[];
      for (UnlinkedClass unlinkedClass in _unlinkedUnit.classes) {
        _types.add(new ClassElementForLink_Class(this, unlinkedClass));
      }
    }
    return _types;
  }

  /**
   * The linked representation of the compilation unit in the summary.
   */
  LinkedUnit get _linkedUnit;

  /**
   * Search the unit for a top level element with the given [name].
   * If no name is found, return the singleton instance of
   * [UndefinedElementForLink].
   */
  ReferenceableElementForLink getContainedName(name) {
    if (_containedNames == null) {
      _containedNames = <String, ReferenceableElementForLink>{};
      // TODO(paulberry): what's the correct way to handle name conflicts?
      for (ClassElementForLink_Class type in types) {
        _containedNames[type.name] = type;
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

  /**
   * Compute the type referred to by the given linked type [slot] (interpreted
   * in [context]).  If there is no inferred type in the
   * given slot, `dynamic` is returned.
   */
  DartType getLinkedType(ElementImpl context, int slot);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /**
   * Return the class element for the constructor referred to by the given
   * [index] in [UnlinkedUnit.references].  If the reference is unresolved,
   * return [UndefinedElementForLink.instance].
   */
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

  /**
   * Return the element referred to by the given [index] in
   * [UnlinkedUnit.references].  If the reference is unresolved,
   * return [UndefinedElementForLink.instance].
   */
  ReferenceableElementForLink resolveRef(int index) {
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
      if (containingReference != 0 &&
          _linkedUnit.references[containingReference].kind !=
              ReferenceKind.prefix) {
        if (linkedReference.kind == ReferenceKind.function) {
          // Local function
          _references[index] = resolveRef(containingReference)
                  .getLocalFunction(linkedReference.localIndex) ??
              UndefinedElementForLink.instance;
        } else {
          _references[index] =
              resolveRef(containingReference).getContainedName(name);
        }
      } else if (linkedReference.dependency == 0) {
        if (linkedReference.kind == ReferenceKind.unresolved) {
          _references[index] = UndefinedElementForLink.instance;
        } else if (name == 'void') {
          _references[index] = enclosingElement._linker.voidElement;
        } else if (name == '*bottom*') {
          _references[index] = enclosingElement._linker.bottomElement;
        } else if (name == 'dynamic') {
          _references[index] = enclosingElement._linker.dynamicElement;
        } else {
          _references[index] = enclosingElement.getContainedName(name);
        }
      } else {
        LibraryElementForLink dependency =
            enclosingElement._getDependency(linkedReference.dependency);
        _references[index] = dependency.getContainedName(name);
      }
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
      return new GenericFunctionTypeElementForLink(this, context, entity).type;
    } else if (entity.syntheticReturnType != null && entity.reference == 0) {
      // TODO(scheglov): Remove "&& entity.reference == 0" condition after
      // rolling SDK with this change internally, so that we always store
      // synthetic and local function types by value.

      // TODO(paulberry): implement.
      throw new UnimplementedError();
    } else if (entity.implicitFunctionTypeIndices.isNotEmpty) {
      DartType type = resolveRef(entity.reference).asStaticType;
      for (int index in entity.implicitFunctionTypeIndices) {
        type = (type as FunctionType).parameters[index].type;
      }
      return type;
    } else {
      ReferenceableElementForLink element = resolveRef(entity.reference);

      DartType getTypeArgument(int i) {
        if (i < entity.typeArguments.length) {
          return resolveTypeRef(context, entity.typeArguments[i]);
        } else if (!instantiateToBoundsAllowed) {
          // Do not allow buildType to instantiate the bounds; force dynamic.
          return DynamicTypeImpl.instance;
        } else {
          return null;
        }
      }

      return element.buildType(
          getTypeArgument, entity.implicitFunctionTypeIndices);
    }
  }

  @override
  String toString() => enclosingElement.toString();
}

/**
 * Element representing a compilation unit which is part of the build
 * unit being linked.
 */
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
      String absoluteUri)
      : super(
            unlinkedUnit, unitNum, unlinkedUnit.references.length, absoluteUri);

  @override
  bool get isInBuildUnit => true;

  @override
  LibraryElementInBuildUnit get library => enclosingElement;

  /**
   * If this compilation unit already has a reference in its references table
   * matching [dependency], [name], [numTypeParameters], [unitNum],
   * [containingReference], and [kind], return its index.  Otherwise add a new reference to
   * the table and return its index.
   */
  int addRawReference(String name,
      {int dependency: 0,
      int numTypeParameters: 0,
      int unitNum: 0,
      int containingReference: 0,
      int localIndex: 0,
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
          linkedReference.kind == kind &&
          linkedReference.localIndex == localIndex) {
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
        kind: kind,
        localIndex: localIndex));
    return result;
  }

  /**
   * If this compilation unit already has a reference in its references table
   * to [element], return its index.  Otherwise add a new reference to the table
   * and return its index.
   */
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
    } else if (element is FunctionElementForLink_Initializer) {
      return addRawReference('',
          containingReference: addReference(element.enclosingElement),
          kind: ReferenceKind.function,
          localIndex: 0);
    } else if (element is FunctionElementForLink_Local_NonSynthetic) {
      ExecutableElementForLink parent = element.enclosingElement;
      int localIndex = parent.functions.indexOf(element);
      assert(localIndex != -1);
      return addRawReference(element.name,
          containingReference: addReference(parent),
          kind: ReferenceKind.function,
          localIndex: localIndex);
    } else if (element is ExecutableElementForLink_NonLocal) {
      ClassElementForLink_Class enclosingClass = element.enclosingClass;
      ReferenceKind kind;
      switch (element._unlinkedExecutable.kind) {
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
          throw new UnimplementedError('${element._unlinkedExecutable.kind}');
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

  /**
   * Perform type inference and const cycle detection on this
   * compilation unit.
   */
  void link() {
    if (library._linker.strongMode) {
      new InstanceMemberInferrer(
          enclosingElement._linker.typeProvider,
          (clazz) => (clazz.library as LibraryElementInBuildUnit)
              .inheritanceManager).inferCompilationUnit(this);
      for (TopLevelVariableElementForLink variable in topLevelVariables) {
        variable.link(this);
      }
    }
    for (ClassElementForLink classElement in types) {
      classElement.link(this);
    }
  }

  /**
   * Throw away any information stored in the summary by a previous call to
   * [link].
   */
  void unlink() {
    _linkedUnit.constCycles.clear();
    _linkedUnit.parametersInheritingCovariant.clear();
    _linkedUnit.references.length = _unlinkedUnit.references.length;
    _linkedUnit.types.clear();
  }

  /**
   * Store the fact that the given [slot] represents a constant constructor
   * that is part of a cycle.
   */
  void _storeConstCycle(int slot) {
    _linkedUnit.constCycles.add(slot);
  }

  /**
   * Store the fact that the given [slot] represents a parameter that inherits
   * `@covariant` behavior.
   */
  void _storeInheritsCovariant(int slot) {
    _linkedUnit.parametersInheritingCovariant.add(slot);
  }

  /**
   * Store the given [linkedType] in the given [slot] of the this compilation
   * unit's linked type list.
   */
  void _storeLinkedType(int slot, DartType linkedType,
      TypeParameterizedElementMixin typeParameterContext) {
    if (slot != 0) {
      if (linkedType != null && !linkedType.isDynamic) {
        _linkedUnit.types.add(_createLinkedType(
            linkedType, this, typeParameterContext,
            slot: slot));
      }
    }
  }

  /**
   * Store the given error [error] in the given [slot].
   */
  void _storeLinkedTypeError(int slot, TopLevelInferenceErrorBuilder error) {
    if (slot != 0) {
      if (error != null) {
        error.slot = slot;
        _linkedUnit.topLevelInferenceErrors.add(error);
      }
    }
  }
}

/**
 * Element representing a compilation unit which is depended upon
 * (either directly or indirectly) by the build unit being linked.
 *
 * TODO(paulberry): ensure that inferred types in dependencies are properly
 * resynthesized.
 */
class CompilationUnitElementInDependency extends CompilationUnitElementForLink {
  @override
  final LinkedUnit _linkedUnit;

  /**
   * Set of slot ids corresponding to parameters that inherit `covariant`.
   */
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
        super(
            unlinkedUnit, unitNum, linkedUnit.references.length, absoluteUri) {
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

/**
 * Instance of [ConstNode] representing a constant constructor.
 */
class ConstConstructorNode extends ConstNode {
  /**
   * The [ConstructorElement] to which this node refers.
   */
  final ConstructorElementForLink constructorElement;

  /**
   * Once this node has been evaluated, indicates whether the
   * constructor is free of constant evaluation cycles.
   */
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
        constructorElement._unlinkedExecutable;
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
          in constructorElement._unlinkedExecutable.constantInitializers) {
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

  /**
   * If [constructorElement] redirects to another constructor via a factory
   * redirect, return the constructor it redirects to.
   */
  ConstructorElementForLink _getFactoryRedirectedConstructor() {
    EntityRef redirectedConstructor =
        constructorElement._unlinkedExecutable.redirectedConstructor;
    if (redirectedConstructor != null) {
      return constructorElement.compilationUnit
          .resolveRef(redirectedConstructor.reference)
          .asConstructor;
    } else {
      return null;
    }
  }
}

/**
 * Specialization of [DependencyWalker] for detecting constant
 * evaluation cycles.
 */
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

/**
 * Specialization of [Node] used to construct the constant evaluation
 * dependency graph.
 */
abstract class ConstNode extends Node<ConstNode> {
  @override
  bool isEvaluated = false;

  /**
   * Collect the dependencies in [unlinkedConst] (which should be
   * interpreted relative to [compilationUnit]) and store them in
   * [dependencies].
   */
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
          intPtr++;
          break;
        case UnlinkedExprOperation.assignToRef:
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
          refPtr++;
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedMap:
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

/**
 * Instance of [ConstNode] representing a parameter with a default
 * value.
 */
class ConstParameterNode extends ConstNode {
  /**
   * The [ParameterElement] to which this node refers.
   */
  final ParameterElementForLink parameterElement;

  ConstParameterNode(this.parameterElement);

  @override
  List<ConstNode> computeDependencies() {
    List<ConstNode> dependencies = <ConstNode>[];
    collectDependencies(
        dependencies,
        parameterElement._unlinkedParam.initializer?.bodyExpr,
        parameterElement.compilationUnit);
    return dependencies;
  }
}

/**
 * Element representing a constructor resynthesized from a summary
 * during linking.
 */
class ConstructorElementForLink extends ExecutableElementForLink_NonLocal
    with ReferenceableElementForLink
    implements ConstructorElementImpl {
  /**
   * If this is a `const` constructor and the enclosing library is
   * part of the build unit being linked, the constructor's node in
   * the constant evaluation dependency graph.  Otherwise `null`.
   */
  ConstConstructorNode _constNode;

  ConstructorElementForLink(ClassElementForLink_Class enclosingClass,
      UnlinkedExecutable unlinkedExecutable)
      : super(enclosingClass.enclosingElement, enclosingClass,
            unlinkedExecutable) {
    if (enclosingClass.enclosingElement.isInBuildUnit &&
        _unlinkedExecutable != null &&
        _unlinkedExecutable.constCycleSlot != 0) {
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

  /**
   * Perform const cycle detection on this constructor.
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (_constNode != null && !isCycleFree) {
      compilationUnit._storeConstCycle(_unlinkedExecutable.constCycleSlot);
    }
    // TODO(paulberry): call super.
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * A synthetic constructor.
 */
class ConstructorElementForLink_Synthetic extends ConstructorElementForLink {
  ConstructorElementForLink_Synthetic(
      ClassElementForLink_Class enclosingElement)
      : super(enclosingElement, null);

  @override
  String get name => '';

  @override
  List<ParameterElement> get parameters => const <ParameterElement>[];
}

/**
 * Instance of [ConstNode] representing a constant field or constant
 * top level variable.
 */
class ConstVariableNode extends ConstNode {
  /**
   * The [FieldElement] or [TopLevelVariableElement] to which this
   * node refers.
   */
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

/**
 * Stub implementation of [AnalysisContext] which provides just those methods
 * needed during linking.
 */
class ContextForLink implements AnalysisContext {
  final Linker _linker;

  ContextForLink(this._linker);

  @override
  AnalysisOptionsForLink get analysisOptions => _linker.analysisOptions;

  @override
  TypeSystem get typeSystem => _linker.typeSystem;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Base class for executable elements resynthesized from a summary during
 * linking.
 */
abstract class ExecutableElementForLink extends Object
    with TypeParameterizedElementMixin, ParameterParentElementForLink
    implements ExecutableElementImpl {
  /**
   * The unlinked representation of the method in the summary.
   */
  final UnlinkedExecutable _unlinkedExecutable;

  DartType _declaredReturnType;
  DartType _inferredReturnType;
  FunctionTypeImpl _type;
  String _name;
  String _displayName;

  final CompilationUnitElementForLink compilationUnit;

  ExecutableElementForLink(this.compilationUnit, this._unlinkedExecutable);

  @override
  ContextForLink get context => compilationUnit.context;

  /**
   * If the executable element had an explicitly declared return type, return
   * it.  Otherwise return `null`.
   */
  DartType get declaredReturnType {
    if (_unlinkedExecutable.returnType == null) {
      return null;
    } else {
      return _declaredReturnType ??=
          compilationUnit.resolveTypeRef(this, _unlinkedExecutable.returnType);
    }
  }

  @override
  String get displayName {
    if (_displayName == null) {
      _displayName = _unlinkedExecutable.name;
      if (_unlinkedExecutable.kind == UnlinkedExecutableKind.setter) {
        _displayName = _displayName.substring(0, _displayName.length - 1);
      }
    }
    return _displayName;
  }

  @override
  CompilationUnitElementImpl get enclosingUnit => compilationUnit;

  @override
  bool get hasImplicitReturnType => _unlinkedExecutable.returnType == null;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  /**
   * Return the inferred return type of the executable element.  Should only be
   * called if no return type was explicitly declared.
   */
  DartType get inferredReturnType {
    // We should only try to infer a return type when none is explicitly
    // declared.
    assert(_unlinkedExecutable.returnType == null);
    if (Linker._initializerTypeInferenceCycle != null &&
        Linker._initializerTypeInferenceCycle ==
            compilationUnit.library.libraryCycleForLink) {
      // We are currently computing the type of an initializer expression in the
      // current library cycle, so type inference results should be ignored.
      return _computeDefaultReturnType();
    }
    if (_inferredReturnType == null) {
      if (_unlinkedExecutable.kind == UnlinkedExecutableKind.constructor) {
        // TODO(paulberry): implement.
        throw new UnimplementedError();
      } else if (compilationUnit.isInBuildUnit) {
        _inferredReturnType = _computeDefaultReturnType();
      } else {
        _inferredReturnType = compilationUnit.getLinkedType(
            this, _unlinkedExecutable.inferredReturnTypeSlot);
      }
    }
    return _inferredReturnType;
  }

  @override
  bool get isStatic => _unlinkedExecutable.isStatic;

  @override
  bool get isSynthetic => false;

  @override
  LibraryElement get library => enclosingElement.library;

  @override
  String get name {
    if (_name == null) {
      _name = _unlinkedExecutable.name;
      if (_name == '-' && _unlinkedExecutable.parameters.isEmpty) {
        _name = 'unary-';
      }
    }
    return _name;
  }

  @override
  DartType get returnType => declaredReturnType ?? inferredReturnType;

  @override
  void set returnType(DartType inferredType) {
    assert(_inferredReturnType == null);
    _inferredReturnType = inferredType;
  }

  @override
  FunctionTypeImpl get type => _type ??= new FunctionTypeImpl(this);

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters => _unlinkedExecutable.parameters;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
      _unlinkedExecutable.typeParameters;

  @override
  bool isAccessibleIn(LibraryElement library) =>
      !Identifier.isPrivateName(name) || identical(this.library, library);

  /**
   * Compute the default return type for this type of executable element (if no
   * return type is declared and strong mode type inference cannot infer a
   * better return type).
   */
  DartType _computeDefaultReturnType() {
    if (_unlinkedExecutable.kind == UnlinkedExecutableKind.setter &&
        (library as LibraryElementForLink)._linker.strongMode) {
      // In strong mode, setters without an explicit return type are
      // considered to return `void`.
      return VoidTypeImpl.instance;
    } else {
      return DynamicTypeImpl.instance;
    }
  }
}

/**
 * Base class for executable elements that are resynthesized from a summary
 * during linking and are not local functions.
 */
abstract class ExecutableElementForLink_NonLocal
    extends ExecutableElementForLink {
  /**
   * Return the class in which this executable appears, maybe `null` for a
   * top-level function.
   */
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

  /**
   * Store the results of type inference for this method in [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (_unlinkedExecutable.returnType == null) {
      compilationUnit._storeLinkedType(
          _unlinkedExecutable.inferredReturnTypeSlot, inferredReturnType, this);
    }
    for (ParameterElementForLink parameterElement in parameters) {
      parameterElement.link(compilationUnit);
    }
  }
}

class ExprTypeComputer {
  final FunctionElementForLink_Local function;
  final CompilationUnitElementForLink unit;
  final LibraryElementForLink library;
  final Linker linker;
  final TypeProvider typeProvider;
  final UnlinkedExpr unlinkedConst;

  final List<DartType> stack = <DartType>[];
  int intPtr = 0;
  int refPtr = 0;
  int strPtr = 0;
  int assignmentOperatorPtr = 0;

  TopLevelInferenceErrorKind errorKind;

  factory ExprTypeComputer(FunctionElementForLink_Local functionElement) {
    CompilationUnitElementForLink unit = functionElement.compilationUnit;
    LibraryElementForLink library = unit.enclosingElement;
    Linker linker = library._linker;
    TypeProvider typeProvider = linker.typeProvider;
    UnlinkedExpr unlinkedConst = functionElement._unlinkedExecutable.bodyExpr;
    return new ExprTypeComputer._(
        functionElement, unit, library, linker, typeProvider, unlinkedConst);
  }

  ExprTypeComputer._(this.function, this.unit, this.library, this.linker,
      this.typeProvider, this.unlinkedConst);

  DartType compute() {
    if (unlinkedConst == null) {
      // No function body was stored for this function, so we can't infer its
      // return type.  Assume `dynamic`.
      return DynamicTypeImpl.instance;
    }
    // If no operations, we cannot compute the type.  Assume `dynamic`.
    if (unlinkedConst.operations.isEmpty) {
      return DynamicTypeImpl.instance;
    }
    // Perform RPN evaluation of the constant, using a stack of inferred types.
    for (UnlinkedExprOperation operation in unlinkedConst.operations) {
      switch (operation) {
        case UnlinkedExprOperation.pushInt:
          intPtr++;
          stack.add(typeProvider.intType);
          break;
        case UnlinkedExprOperation.pushLongInt:
          int numInts = _getNextInt();
          intPtr += numInts;
          stack.add(typeProvider.intType);
          break;
        case UnlinkedExprOperation.pushDouble:
          stack.add(typeProvider.doubleType);
          break;
        case UnlinkedExprOperation.pushTrue:
        case UnlinkedExprOperation.pushFalse:
          stack.add(typeProvider.boolType);
          break;
        case UnlinkedExprOperation.pushString:
          strPtr++;
          stack.add(typeProvider.stringType);
          break;
        case UnlinkedExprOperation.concatenate:
          stack.length -= _getNextInt();
          stack.add(typeProvider.stringType);
          break;
        case UnlinkedExprOperation.makeSymbol:
          strPtr++;
          stack.add(typeProvider.symbolType);
          break;
        case UnlinkedExprOperation.pushNull:
          stack.add(typeProvider.nullType);
          break;
        case UnlinkedExprOperation.pushSuper:
          stack.add(DynamicTypeImpl.instance);
          break;
        case UnlinkedExprOperation.pushThis:
          stack.add(DynamicTypeImpl.instance);
          break;
        case UnlinkedExprOperation.pushReference:
          _doPushReference();
          break;
        case UnlinkedExprOperation.extractProperty:
          _doExtractProperty();
          break;
        case UnlinkedExprOperation.invokeConstructor:
          _doInvokeConstructor();
          break;
        case UnlinkedExprOperation.makeUntypedList:
          _doMakeUntypedList();
          break;
        case UnlinkedExprOperation.makeUntypedMap:
          _doMakeUntypedMap();
          break;
        case UnlinkedExprOperation.makeTypedList:
          _doMakeTypedList();
          break;
        case UnlinkedExprOperation.makeTypedMap:
          _doMakeTypeMap();
          break;
        case UnlinkedExprOperation.not:
          stack.length -= 1;
          stack.add(typeProvider.boolType);
          break;
        case UnlinkedExprOperation.complement:
          _computePrefixExpressionType('~');
          break;
        case UnlinkedExprOperation.negate:
          _computePrefixExpressionType('unary-');
          break;
        case UnlinkedExprOperation.and:
        case UnlinkedExprOperation.or:
        case UnlinkedExprOperation.equal:
        case UnlinkedExprOperation.notEqual:
          stack.length -= 2;
          stack.add(typeProvider.boolType);
          break;
        case UnlinkedExprOperation.bitXor:
          _computeBinaryExpressionType(TokenType.CARET);
          break;
        case UnlinkedExprOperation.bitAnd:
          _computeBinaryExpressionType(TokenType.AMPERSAND);
          break;
        case UnlinkedExprOperation.bitOr:
          _computeBinaryExpressionType(TokenType.BAR);
          break;
        case UnlinkedExprOperation.bitShiftRight:
          _computeBinaryExpressionType(TokenType.GT_GT);
          break;
        case UnlinkedExprOperation.bitShiftLeft:
          _computeBinaryExpressionType(TokenType.LT_LT);
          break;
        case UnlinkedExprOperation.add:
          _computeBinaryExpressionType(TokenType.PLUS);
          break;
        case UnlinkedExprOperation.subtract:
          _computeBinaryExpressionType(TokenType.MINUS);
          break;
        case UnlinkedExprOperation.multiply:
          _computeBinaryExpressionType(TokenType.STAR);
          break;
        case UnlinkedExprOperation.divide:
          _computeBinaryExpressionType(TokenType.SLASH);
          break;
        case UnlinkedExprOperation.floorDivide:
          _computeBinaryExpressionType(TokenType.TILDE_SLASH);
          break;
        case UnlinkedExprOperation.greater:
          _computeBinaryExpressionType(TokenType.GT);
          break;
        case UnlinkedExprOperation.less:
          _computeBinaryExpressionType(TokenType.LT);
          break;
        case UnlinkedExprOperation.greaterEqual:
          _computeBinaryExpressionType(TokenType.GT_EQ);
          break;
        case UnlinkedExprOperation.lessEqual:
          _computeBinaryExpressionType(TokenType.LT_EQ);
          break;
        case UnlinkedExprOperation.modulo:
          _computeBinaryExpressionType(TokenType.PERCENT);
          break;
        case UnlinkedExprOperation.conditional:
          _doConditional();
          break;
        case UnlinkedExprOperation.assignToIndex:
          _doAssignToIndex();
          break;
        case UnlinkedExprOperation.assignToProperty:
          _doAssignToProperty();
          break;
        case UnlinkedExprOperation.assignToRef:
          _doAssignToRef();
          break;
        case UnlinkedExprOperation.await:
          _doAwait();
          break;
        case UnlinkedExprOperation.extractIndex:
          _doExtractIndex();
          break;
        case UnlinkedExprOperation.invokeMethodRef:
          _doInvokeMethodRef();
          break;
        case UnlinkedExprOperation.invokeMethod:
          _doInvokeMethod();
          break;
        case UnlinkedExprOperation.cascadeSectionBegin:
          stack.add(stack.last);
          break;
        case UnlinkedExprOperation.cascadeSectionEnd:
          stack.removeLast();
          break;
        case UnlinkedExprOperation.typeCast:
          stack.removeLast();
          DartType type = _getNextTypeRef();
          stack.add(type);
          break;
        case UnlinkedExprOperation.typeCheck:
          stack.removeLast();
          refPtr++;
          stack.add(typeProvider.boolType);
          break;
        case UnlinkedExprOperation.throwException:
          stack.removeLast();
          stack.add(BottomTypeImpl.instance);
          break;
        case UnlinkedExprOperation.pushLocalFunctionReference:
          int popCount = _getNextInt();
          assert(popCount == 0); // TODO(paulberry): handle the nonzero case.
          stack.add(function.functions[_getNextInt()].type);
          break;
        case UnlinkedExprOperation.pushParameter:
          stack.add(_findParameterType(_getNextString()));
          break;
        case UnlinkedExprOperation.ifNull:
          _doIfNull();
          break;
        default:
          // TODO(paulberry): implement.
          throw new UnimplementedError('$operation');
      }
    }
    assert(intPtr == unlinkedConst.ints.length);
    assert(refPtr == unlinkedConst.references.length);
    assert(strPtr == unlinkedConst.strings.length);
    assert(assignmentOperatorPtr == unlinkedConst.assignmentOperators.length);
    assert(stack.length == 1);
    return stack[0];
  }

  void _computeBinaryExpressionType(TokenType operator) {
    DartType right = stack.removeLast();
    DartType left = stack.removeLast();
    _pushBinaryOperatorType(left, operator, right);
  }

  void _computePrefixExpressionType(String operatorName) {
    DartType operand = stack.removeLast();
    if (operand is InterfaceType) {
      MethodElement method =
          operand.lookUpInheritedMethod(operatorName, library: library);
      if (method != null) {
        DartType type = method.returnType;
        stack.add(type);
        return;
      }
    }
    stack.add(DynamicTypeImpl.instance);
  }

  void _doAssignment() {
    UnlinkedExprAssignOperator operator =
        unlinkedConst.assignmentOperators[assignmentOperatorPtr++];
    if (isIncrementOrDecrement(operator)) {
      _doIncrementOrDecrement(operator);
      return;
    }
    if (operator == UnlinkedExprAssignOperator.assign) {
      stack.removeLast();
      return; // type is on the stack
    }
    TokenType binaryOperator = _convertAssignOperatorToTokenType(operator);
    _computeBinaryExpressionType(binaryOperator);
  }

  void _doAssignToIndex() {
    _doExtractIndex();
    _doAssignment();
  }

  void _doAssignToProperty() {
    _doExtractProperty();
    _doAssignment();
  }

  void _doAssignToRef() {
    EntityRef ref = _getNextRef();
    ReferenceableElementForLink element = unit.resolveRef(ref.reference);
    stack.add(element.asStaticType);
    _doAssignment();
  }

  void _doAwait() {
    DartType type = stack.removeLast();
    DartType typeArgument = type?.flattenFutures(linker.typeSystem);
    typeArgument = _dynamicIfNull(typeArgument);
    stack.add(typeArgument);
  }

  void _doConditional() {
    DartType elseType = stack.removeLast();
    DartType thenType = stack.removeLast();
    stack.removeLast();
    DartType type = _leastUpperBound(thenType, elseType);
    type = _dynamicIfNull(type);
    stack.add(type);
  }

  void _doExtractIndex() {
    stack.removeLast(); // index
    DartType target = stack.removeLast();
    stack.add(() {
      if (target is InterfaceType) {
        MethodElement method =
            target.lookUpInheritedMethod('[]', library: library);
        if (method != null) {
          return method.returnType;
        }
      }
      return DynamicTypeImpl.instance;
    }());
  }

  void _doExtractProperty() {
    DartType target = stack.removeLast();
    if (target.isDynamic) {
      target = typeProvider.objectType;
    }
    String propertyName = _getNextString();
    stack.add(() {
      if (target is InterfaceType) {
        ExecutableElement element = target
            .lookUpInheritedGetterOrMethod(propertyName, library: library);
        if (element != null) {
          if (element is PropertyAccessorElement) {
            return element.returnType;
          } else {
            // Method tear-off
            return element.type;
          }
        }
      }
      return DynamicTypeImpl.instance;
    }());
  }

  void _doIfNull() {
    DartType secondType = stack.removeLast();
    DartType firstType = stack.removeLast();
    DartType type = _leastUpperBound(firstType, secondType);
    type = _dynamicIfNull(type);
    stack.add(type);
  }

  void _doIncrementOrDecrement(UnlinkedExprAssignOperator operator) {
    switch (operator) {
      case UnlinkedExprAssignOperator.prefixDecrement:
        stack.add(typeProvider.intType);
        _computeBinaryExpressionType(TokenType.MINUS);
        return;
      case UnlinkedExprAssignOperator.prefixIncrement:
        stack.add(typeProvider.intType);
        _computeBinaryExpressionType(TokenType.PLUS);
        return;
      case UnlinkedExprAssignOperator.postfixDecrement:
      case UnlinkedExprAssignOperator.postfixIncrement:
        return; // Return the operand type
      default:
        stack.removeLast();
        stack.add(DynamicTypeImpl.instance);
        return;
    }
  }

  void _doInvokeConstructor() {
    int numNamed = unlinkedConst.ints[intPtr++];
    int numPositional = unlinkedConst.ints[intPtr++];
    List<String> namedArgNames = _getNextStrings(numNamed);
    List<DartType> namedArgTypeList = _popList(numNamed);
    List<DartType> positionalArgTypes = _popList(numPositional);

    EntityRef ref = _getNextRef();
    ReferenceableElementForLink refElement = unit.resolveRef(ref.reference);
    ConstructorElementForLink constructorElement = refElement.asConstructor;

    if (constructorElement != null) {
      stack.add(() {
        if (ref.typeArguments.isNotEmpty) {
          return constructorElement.enclosingClass.buildType((int i) {
            if (i < ref.typeArguments.length) {
              return unit.resolveTypeRef(function, ref.typeArguments[i]);
            } else {
              return null;
            }
          }, const <int>[]);
        } else {
          FunctionType rawType = StaticTypeAnalyzer
              .constructorToGenericFunctionType(constructorElement);
          FunctionType inferredType = _inferExecutableType(
              rawType,
              numNamed,
              numPositional,
              namedArgNames,
              namedArgTypeList,
              positionalArgTypes, const <DartType>[]);
          if (inferredType == null || identical(inferredType, rawType)) {
            inferredType = linker.typeSystem.instantiateToBounds(rawType);
          }
          return inferredType.returnType;
        }
      }());
    } else {
      ClassElementForLink classElement =
          unit.resolveConstructorClassRef(ref.reference).asClass;
      DartType inferredType;
      if (classElement != null) {
        InterfaceType rawType = classElement.type;
        inferredType = linker.typeSystem.instantiateToBounds(rawType);
      } else {
        inferredType = DynamicTypeImpl.instance;
      }
      stack.add(inferredType);
    }
  }

  void _doInvokeMethod() {
    int numNamed = unlinkedConst.ints[intPtr++];
    int numPositional = unlinkedConst.ints[intPtr++];
    List<String> namedArgNames = _getNextStrings(numNamed);
    List<DartType> namedArgTypeList = _popList(numNamed);
    List<DartType> positionalArgTypes = _popList(numPositional);
    // TODO(scheglov) if we pushed target and method name first, we might be
    // able to move work with arguments in _inferExecutableType()
    String methodName = _getNextString();
    List<DartType> typeArguments = _getTypeArguments();
    DartType target = stack.removeLast();
    if (target.isDynamic) {
      target = typeProvider.objectType;
    }
    stack.add(() {
      if (target is InterfaceType) {
        MethodElement method =
            target.lookUpInheritedMethod(methodName, library: library);
        FunctionType rawType = method?.type;
        FunctionType inferredType = _inferExecutableType(
            rawType,
            numNamed,
            numPositional,
            namedArgNames,
            namedArgTypeList,
            positionalArgTypes,
            typeArguments);
        if (inferredType != null) {
          return inferredType.returnType;
        }
      }
      return DynamicTypeImpl.instance;
    }());
  }

  void _doInvokeMethodRef() {
    int numNamed = _getNextInt();
    int numPositional = _getNextInt();
    List<String> namedArgNames = _getNextStrings(numNamed);
    List<DartType> namedArgTypeList = _popList(numNamed);
    List<DartType> positionalArgTypes = _popList(numPositional);
    EntityRef ref = _getNextRef();
    ReferenceableElementForLink element = unit.resolveRef(ref.reference);
    List<DartType> typeArguments = _getTypeArguments();
    stack.add(() {
      DartType rawType = element.asStaticType;
      if (rawType is FunctionType) {
        FunctionType inferredType = _inferExecutableType(
            rawType,
            numNamed,
            numPositional,
            namedArgNames,
            namedArgTypeList,
            positionalArgTypes,
            typeArguments);
        if (inferredType != null) {
          return inferredType.returnType;
        }
      }
      return DynamicTypeImpl.instance;
    }());
  }

  void _doMakeTypedList() {
    DartType itemType = _getNextTypeRef();
    stack.length -= _getNextInt();
    stack.add(typeProvider.listType.instantiate(<DartType>[itemType]));
  }

  void _doMakeTypeMap() {
    DartType keyType = _getNextTypeRef();
    DartType valueType = _getNextTypeRef();
    stack.length -= 2 * _getNextInt();
    stack.add(typeProvider.mapType.instantiate(<DartType>[keyType, valueType]));
  }

  void _doMakeUntypedList() {
    int numItems = _getNextInt();
    DartType itemType = numItems == 0
        ? DynamicTypeImpl.instance
        : _popList(numItems).reduce(_leastUpperBound);
    itemType = _dynamicIfNull(itemType);
    stack.add(typeProvider.listType.instantiate(<DartType>[itemType]));
  }

  void _doMakeUntypedMap() {
    int numEntries = _getNextInt();
    List<DartType> keysValues = _popList(2 * numEntries);
    DartType keyType = null;
    DartType valueType = null;
    for (int i = 0; i < 2 * numEntries; i++) {
      DartType type = keysValues[i];
      if (i.isEven) {
        keyType = keyType == null ? type : _leastUpperBound(keyType, type);
      } else {
        valueType =
            valueType == null ? type : _leastUpperBound(valueType, type);
      }
    }
    keyType = _dynamicIfNull(keyType);
    valueType = _dynamicIfNull(valueType);
    stack.add(typeProvider.mapType.instantiate(<DartType>[keyType, valueType]));
  }

  void _doPushReference() {
    EntityRef ref = _getNextRef();
    if (ref.paramReference != 0) {
      stack.add(typeProvider.typeType);
    } else {
      // Synthetic function types can't be directly referred
      // to by expressions.
      assert(ref.syntheticReturnType == null);
      // Nor can implicit function types derived from
      // function-typed parameters.
      assert(ref.implicitFunctionTypeIndices.isEmpty);
      ReferenceableElementForLink element = unit.resolveRef(ref.reference);
      stack.add(element.asStaticType);
    }
  }

  /**
   * Find the parameter in scope called [parameterName] and return its type.
   */
  DartType _findParameterType(String parameterName) {
    FunctionElementForLink_Local f = this.function;
    while (true) {
      for (ParameterElement parameter in f.parameters) {
        if (parameter.name == parameterName) {
          return parameter.type;
        }
      }
      Element parent = f.enclosingElement;
      if (parent is FunctionElementForLink_Local) {
        f = parent;
      } else {
        // Parameter not found.  This should never happen in a well-formed
        // summary.
        assert(false);
        return DynamicTypeImpl.instance;
      }
    }
  }

  int _getNextInt() {
    return unlinkedConst.ints[intPtr++];
  }

  EntityRef _getNextRef() => unlinkedConst.references[refPtr++];

  String _getNextString() {
    return unlinkedConst.strings[strPtr++];
  }

  List<String> _getNextStrings(int n) {
    List<String> result = new List<String>(n);
    for (int i = 0; i < n; i++) {
      result[i] = _getNextString();
    }
    return result;
  }

  DartType _getNextTypeRef() {
    EntityRef ref = _getNextRef();
    return unit.resolveTypeRef(function, ref);
  }

  List<DartType> _getTypeArguments() {
    int numTypeArguments = _getNextInt();
    List<DartType> typeArguments = new List<DartType>(numTypeArguments);
    for (int i = 0; i < numTypeArguments; i++) {
      typeArguments[i] = _getNextTypeRef();
    }
    return typeArguments;
  }

  FunctionType _inferExecutableType(
      FunctionType rawMethodType,
      int numNamedArguments,
      int numPositionalArguments,
      List<String> namedArgNames,
      List<DartType> namedArgTypeList,
      List<DartType> positionalArgTypes,
      List<DartType> typeArguments) {
    TypeSystem ts = linker.typeSystem;
    if (rawMethodType != null) {
      if (rawMethodType.typeFormals.isNotEmpty && typeArguments.isNotEmpty) {
        Element methodElement = rawMethodType.element;
        if (methodElement is TypeParameterizedElement &&
            methodElement.typeParameters.length == typeArguments.length) {
          return rawMethodType.instantiate(typeArguments);
        }
      } else if (rawMethodType.typeFormals.isNotEmpty &&
          ts is StrongTypeSystemImpl) {
        // Prepare the named argument types map.
        Map<String, DartType> namedArgTypes = <String, DartType>{};
        for (int i = 0; i < numNamedArguments; i++) {
          String name = namedArgNames[i];
          DartType type = namedArgTypeList[i];
          namedArgTypes[name] = type;
        }

        // Fill parameters and the corresponding arguments.
        List<ParameterElement> parameters = <ParameterElement>[];
        List<DartType> argumentTypes = <DartType>[];
        int positionalIndex = 0;
        int numRequiredParameters = 0;
        for (ParameterElement parameter in rawMethodType.parameters) {
          if (parameter.parameterKind == ParameterKind.REQUIRED) {
            numRequiredParameters++;
            if (numRequiredParameters > numPositionalArguments) {
              return null;
            }
            parameters.add(parameter);
            argumentTypes.add(positionalArgTypes[positionalIndex]);
            positionalIndex++;
          } else if (parameter.parameterKind == ParameterKind.POSITIONAL) {
            if (positionalIndex < numPositionalArguments) {
              parameters.add(parameter);
              argumentTypes.add(positionalArgTypes[positionalIndex]);
              positionalIndex++;
            }
          } else if (parameter.parameterKind == ParameterKind.NAMED) {
            DartType namedArgumentType = namedArgTypes[parameter.name];
            if (namedArgumentType != null) {
              parameters.add(parameter);
              argumentTypes.add(namedArgumentType);
            }
          }
        }

        // Perform inference.
        FunctionType inferred = ts.inferGenericFunctionOrType(
            rawMethodType, parameters, argumentTypes, null);
        return inferred;
      }
    }
    // Not a generic function type, use the raw type.
    return rawMethodType;
  }

  DartType _leastUpperBound(DartType s, DartType t) {
    return linker.typeSystem.getLeastUpperBound(s, t);
  }

  List<DartType> _popList(int n) {
    List<DartType> result = stack.sublist(stack.length - n, stack.length);
    stack.length -= n;
    return result;
  }

  void _pushBinaryOperatorType(
      DartType left, TokenType operator, DartType right) {
    if (left is InterfaceType) {
      MethodElement method =
          left.lookUpInheritedMethod(operator.lexeme, library: library);
      if (method != null) {
        DartType type = method.returnType;
        type = linker.typeSystem
            .refineBinaryExpressionType(left, operator, right, type);
        stack.add(type);
        return;
      }
    }
    stack.add(DynamicTypeImpl.instance);
  }

  static TokenType _convertAssignOperatorToTokenType(
      UnlinkedExprAssignOperator o) {
    switch (o) {
      case UnlinkedExprAssignOperator.assign:
        return null;
      case UnlinkedExprAssignOperator.ifNull:
        return TokenType.QUESTION_QUESTION;
      case UnlinkedExprAssignOperator.multiply:
        return TokenType.STAR;
      case UnlinkedExprAssignOperator.divide:
        return TokenType.SLASH;
      case UnlinkedExprAssignOperator.floorDivide:
        return TokenType.TILDE_SLASH;
      case UnlinkedExprAssignOperator.modulo:
        return TokenType.PERCENT;
      case UnlinkedExprAssignOperator.plus:
        return TokenType.PLUS;
      case UnlinkedExprAssignOperator.minus:
        return TokenType.MINUS;
      case UnlinkedExprAssignOperator.shiftLeft:
        return TokenType.LT_LT;
      case UnlinkedExprAssignOperator.shiftRight:
        return TokenType.GT_GT;
      case UnlinkedExprAssignOperator.bitAnd:
        return TokenType.AMPERSAND;
      case UnlinkedExprAssignOperator.bitXor:
        return TokenType.CARET;
      case UnlinkedExprAssignOperator.bitOr:
        return TokenType.BAR;
      case UnlinkedExprAssignOperator.prefixIncrement:
        return TokenType.PLUS_PLUS;
      case UnlinkedExprAssignOperator.prefixDecrement:
        return TokenType.MINUS_MINUS;
      case UnlinkedExprAssignOperator.postfixIncrement:
        return TokenType.PLUS_PLUS;
      case UnlinkedExprAssignOperator.postfixDecrement:
        return TokenType.MINUS_MINUS;
    }
    return null;
  }
}

/**
 * Element representing a field resynthesized from a summary during
 * linking.
 */
abstract class FieldElementForLink implements FieldElement {
  @override
  PropertyAccessorElementForLink get getter;

  @override
  PropertyAccessorElementForLink get setter;
}

/**
 * Specialization of [FieldElementForLink] for class fields.
 */
class FieldElementForLink_ClassField extends VariableElementForLink
    implements FieldElementForLink {
  @override
  final ClassElementForLink_Class enclosingElement;

  /**
   * If this is an instance field, the type that was computed by
   * [InstanceMemberInferrer] (if any).  Otherwise `null`.
   */
  DartType _inferredInstanceType;

  TopLevelInferenceErrorBuilder _inferenceError;

  FieldElementForLink_ClassField(ClassElementForLink_Class enclosingElement,
      UnlinkedVariable unlinkedVariable)
      : enclosingElement = enclosingElement,
        super(unlinkedVariable, enclosingElement.enclosingElement);

  @override
  bool get isStatic => unlinkedVariable.isStatic;

  @override
  void set type(DartType inferredType) {
    assert(!isStatic);
    assert(_inferredInstanceType == null);
    _inferredInstanceType = inferredType;
  }

  @override
  TypeParameterizedElementMixin get _typeParameterContext => enclosingElement;

  /**
   * Store the results of type inference for this field in
   * [compilationUnit].
   */
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

/**
 * Specialization of [FieldElementForLink] for enum fields.
 */
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

/**
 * Specialization of [FieldElementForLink] for the 'index' enum field.
 */
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

/**
 * Specialization of [FieldElementForLink] for enum fields.
 */
class FieldElementForLink_EnumField_value
    extends FieldElementForLink_EnumField {
  /**
   * The unlinked representation of the field in the summary.
   */
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

/**
 * Specialization of [FieldElementForLink] for the 'values' enum field.
 */
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
          FieldElement field = enclosingClass.getField(_unlinkedParam.name);
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

/**
 * Element representing a function-typed parameter resynthesied from a summary
 * during linking.
 */
class FunctionElementForLink_FunctionTypedParam extends Object
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
      if (enclosingElement._unlinkedParam.type == null) {
        _returnType = DynamicTypeImpl.instance;
      } else {
        _returnType = enclosingElement.compilationUnit.resolveTypeRef(
            enclosingElement, enclosingElement._unlinkedParam.type);
      }
    }
    return _returnType;
  }

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing the initializer expression of a variable.
 */
class FunctionElementForLink_Initializer extends Object
    with ReferenceableElementForLink, TypeParameterizedElementMixin
    implements FunctionElementForLink_Local {
  /**
   * The variable for which this element is the initializer.
   */
  final VariableElementForLink _variable;

  /**
   * The type inference node for this function, or `null` if it hasn't been
   * computed yet.
   */
  TypeInferenceNode _typeInferenceNode;

  List<FunctionElementForLink_Local_NonSynthetic> _functions;
  DartType _inferredReturnType;
  TopLevelInferenceErrorBuilder _inferenceError;

  FunctionElementForLink_Initializer(this._variable);

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
      _functions ??= _variable.unlinkedVariable.initializer.localFunctions
          .map((UnlinkedExecutable ex) =>
              new FunctionElementForLink_Local_NonSynthetic(
                  _variable.compilationUnit, this, ex))
          .toList();

  @override
  String get identifier => '';

  @override
  bool get isAsynchronous => _unlinkedExecutable.isAsynchronous;

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
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams => const [];

  @override
  bool get _hasTypeBeenInferred => _inferredReturnType != null;

  @override
  UnlinkedExecutable get _unlinkedExecutable =>
      _variable.unlinkedVariable.initializer;

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    List<FunctionElementForLink_Local_NonSynthetic> functions = this.functions;
    return index < functions.length ? functions[index] : null;
  }

  /**
   * Store the results of type inference for this initializer in
   * [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(_unlinkedExecutable.inferredReturnTypeSlot,
        _inferredReturnType, typeParameterContext);
    for (FunctionElementForLink_Local_NonSynthetic function in functions) {
      function.link(compilationUnit);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

/**
 * Element representing a local function (possibly a closure).
 */
abstract class FunctionElementForLink_Local
    implements
        ExecutableElementForLink,
        FunctionElementImpl,
        ReferenceableElementForLink {
  /**
   * Indicates whether type inference has completed for this function.
   */
  bool get _hasTypeBeenInferred;

  /**
   * Stores the given [error] as the type inference error for this function.
   * Should only be called if [_hasTypeBeenInferred] is `false`.
   */
  void _setInferenceError(TopLevelInferenceErrorBuilder error);

  /**
   * Stores the given [type] as the inferred return type for this function.
   * Should only be called if [_hasTypeBeenInferred] is `false`.
   */
  void _setInferredType(DartType type);
}

/**
 * Element representing a local function (possibly a closure) inside another
 * executable.
 */
class FunctionElementForLink_Local_NonSynthetic extends ExecutableElementForLink
    with ReferenceableElementForLink
    implements FunctionElementForLink_Local {
  @override
  final ExecutableElementForLink enclosingElement;

  List<FunctionElementForLink_Local_NonSynthetic> _functions;

  /**
   * The type inference node for this function, or `null` if it hasn't been
   * computed yet.
   */
  TypeInferenceNode _typeInferenceNode;

  FunctionElementForLink_Local_NonSynthetic(
      CompilationUnitElementForLink compilationUnit,
      this.enclosingElement,
      UnlinkedExecutable unlinkedExecutable)
      : super(compilationUnit, unlinkedExecutable);

  @override
  TypeInferenceNode get asTypeInferenceNode =>
      _typeInferenceNode ??= new TypeInferenceNode(this);

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext =>
      enclosingElement;

  @override
  List<FunctionElementForLink_Local_NonSynthetic> get functions =>
      _functions ??= _unlinkedExecutable.localFunctions
          .map((UnlinkedExecutable ex) =>
              new FunctionElementForLink_Local_NonSynthetic(
                  compilationUnit, this, ex))
          .toList();

  @override
  String get identifier {
    String identifier = _unlinkedExecutable.name;
    Element enclosing = this.enclosingElement;
    if (enclosing is ExecutableElement) {
      int id =
          ElementImpl.findElementIndexUsingIdentical(enclosing.functions, this);
      identifier += "@$id";
    }
    return identifier;
  }

  @override
  bool get isAsynchronous => _unlinkedExecutable.isAsynchronous;

  @override
  bool get _hasTypeBeenInferred => _inferredReturnType != null;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    assert(implicitFunctionTypeIndices.isEmpty);
    return type;
  }

  @override
  FunctionElementForLink_Local getLocalFunction(int index) {
    List<FunctionElementForLink_Local_NonSynthetic> functions = this.functions;
    return index < functions.length ? functions[index] : null;
  }

  /**
   * Store the results of type inference for this function in [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (_unlinkedExecutable.returnType == null) {
      compilationUnit._storeLinkedType(
          _unlinkedExecutable.inferredReturnTypeSlot, inferredReturnType, this);
    }
    for (FunctionElementForLink_Local_NonSynthetic function in functions) {
      function.link(compilationUnit);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void _setInferenceError(TopLevelInferenceErrorBuilder error) {}

  @override
  void _setInferredType(DartType type) {
    // TODO(paulberry): store the inferred return type in the summary.
    assert(!_hasTypeBeenInferred);
    _inferredReturnType = _dynamicIfNull(type);
  }
}

/**
 * Element representing a typedef resynthesized from a summary during linking.
 */
class FunctionTypeAliasElementForLink extends Object
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink
    implements FunctionTypeAliasElement, ElementImpl {
  @override
  final CompilationUnitElementForLink enclosingElement;

  /**
   * The unlinked representation of the typedef in the summary.
   */
  final UnlinkedTypedef _unlinkedTypedef;

  FunctionTypeImpl _type;
  DartType _returnType;

  FunctionTypeAliasElementForLink(this.enclosingElement, this._unlinkedTypedef);

  @override
  DartType get asStaticType {
    return enclosingElement.enclosingElement._linker.typeProvider.typeType;
  }

  @override
  ContextForLink get context => enclosingElement.context;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementImpl get enclosingUnit => enclosingElement;

  @override
  String get identifier => _unlinkedTypedef.name;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  String get name => _unlinkedTypedef.name;

  @override
  DartType get returnType => _returnType ??=
      enclosingElement.resolveTypeRef(this, _unlinkedTypedef.returnType);

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters => _unlinkedTypedef.parameters;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
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
        return new FunctionTypeImpl.elementWithNameAndArgs(
            this, name, typeArguments, true);
      }
    } else {
      return _type ??= new FunctionTypeImpl.forTypedef(this);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/**
 * Element representing a generic function resynthesized from a summary during
 * linking.
 */
class GenericFunctionTypeElementForLink extends Object
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink
    implements GenericFunctionTypeElement, ElementImpl {
  @override
  final CompilationUnitElementForLink enclosingUnit;

  @override
  final ElementImpl enclosingElement;

  /**
   * The linked representation of the generic function in the summary.
   */
  final EntityRef _entity;

  DartType _returnType;
  FunctionTypeImpl _type;

  GenericFunctionTypeElementForLink(
      this.enclosingUnit, this.enclosingElement, this._entity);

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
  String get name => '-';

  @override
  DartType get returnType => _returnType ??=
      enclosingUnit.resolveTypeRef(this, _entity.syntheticReturnType);

  @override
  FunctionType get type {
    return _type ??= new FunctionTypeImpl.elementWithNameAndArgs(
        this, null, allEnclosingTypeParameterTypes, false);
  }

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedParam> get unlinkedParameters => _entity.syntheticParams;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams => _entity.typeParameters;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/**
 * Element representing a generic typedef resynthesized from a summary during
 * linking.
 */
class GenericTypeAliasElementForLink extends Object
    with
        TypeParameterizedElementMixin,
        ParameterParentElementForLink,
        ReferenceableElementForLink
    implements FunctionTypeAliasElementForLink, ElementImpl {
  @override
  final CompilationUnitElementForLink enclosingElement;

  /**
   * The unlinked representation of the typedef in the summary.
   */
  final UnlinkedTypedef _unlinkedTypedef;

  GenericTypeAliasElementForLink(this.enclosingElement, this._unlinkedTypedef);

  @override
  DartType get asStaticType {
    return enclosingElement.enclosingElement._linker.typeProvider.typeType;
  }

  @override
  ContextForLink get context => enclosingElement.context;

  @override
  TypeParameterizedElementMixin get enclosingTypeParameterContext => null;

  @override
  CompilationUnitElementImpl get enclosingUnit => enclosingElement;

  @override
  String get identifier => _unlinkedTypedef.name;

  @override
  List<int> get implicitFunctionTypeIndices => const <int>[];

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  String get name => _unlinkedTypedef.name;

  @override
  TypeParameterizedElementMixin get typeParameterContext => this;

  @override
  List<UnlinkedTypeParam> get unlinkedTypeParams =>
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
        return new FunctionTypeImpl.elementWithNameAndArgs(
            this, name, typeArguments, true);
      }
    } else {
      return new FunctionTypeImpl.forTypedef(this);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}

/**
 * Specialization of [DependencyWalker] for linking library cycles.
 */
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

/**
 * An instance of [LibraryCycleForLink] represents a single library cycle
 * discovered during linking; it consists of one or more libraries in the build
 * unit being linked.
 */
class LibraryCycleForLink {
  /**
   * The libraries in the cycle.
   */
  final List<LibraryElementInBuildUnit> libraries;

  /**
   * The library cycles which this library depends on.
   */
  final List<LibraryCycleForLink> dependencies;

  /**
   * The [LibraryCycleNode] for this library cycle.
   */
  LibraryCycleNode _node;

  LibraryCycleForLink(this.libraries, this.dependencies) {
    _node = new LibraryCycleNode(this);
  }

  LibraryCycleNode get node => _node;

  /**
   * Link this library cycle and any library cycles it depends on.  Does
   * nothing if this library cycle has already been linked.
   */
  void ensureLinked() {
    if (!node.isEvaluated) {
      new LibraryCycleDependencyWalker().walk(node);
    }
  }
}

/**
 * Specialization of [Node] used to link library cycles in proper dependency
 * order.
 */
class LibraryCycleNode extends Node<LibraryCycleNode> {
  /**
   * The library cycle this [Node] represents.
   */
  final LibraryCycleForLink libraryCycle;

  /**
   * Indicates whether this library cycle has been linked yet.
   */
  bool _isLinked = false;

  LibraryCycleNode(this.libraryCycle);

  @override
  bool get isEvaluated => _isLinked;

  @override
  List<LibraryCycleNode> computeDependencies() => libraryCycle.dependencies
      .map((LibraryCycleForLink cycle) => cycle.node)
      .toList();

  /**
   * Link this library cycle.
   */
  void link() {
    for (LibraryElementInBuildUnit library in libraryCycle.libraries) {
      library.link();
    }
    _isLinked = true;
  }
}

/**
 * Specialization of [DependencyWalker] for computing library cycles.
 */
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

/**
 * Element representing a library resynthesied from a summary during
 * linking.  The type parameter, [UnitElement], represents the type
 * that will be used for the compilation unit elements.
 */
abstract class LibraryElementForLink<
        UnitElement extends CompilationUnitElementForLink>
    implements LibraryElementImpl {
  /**
   * Pointer back to the linker.
   */
  final Linker _linker;

  /**
   * The absolute URI of this library.
   */
  final Uri _absoluteUri;

  List<UnitElement> _units;
  final Map<String, ReferenceableElementForLink> _containedNames =
      <String, ReferenceableElementForLink>{};
  final List<LibraryElementForLink> _dependencies = <LibraryElementForLink>[];
  UnlinkedUnit _definingUnlinkedUnit;
  List<LibraryElementForLink> _importedLibraries;
  List<LibraryElementForLink> _exportedLibraries;

  LibraryElementForLink(this._linker, this._absoluteUri) {
    if (_linkedLibrary != null) {
      _dependencies.length = _linkedLibrary.dependencies.length;
    }
  }

  @override
  ContextForLink get context => _linker.context;

  /**
   * Get the [UnlinkedUnit] for the defining compilation unit of this library.
   */
  UnlinkedUnit get definingUnlinkedUnit =>
      _definingUnlinkedUnit ??= _linker.getUnit(_absoluteUri.toString());

  @override
  Element get enclosingElement => null;

  @override
  List<LibraryElementForLink> get exportedLibraries =>
      _exportedLibraries ??= _linkedLibrary.exportDependencies
          .map(_getDependency)
          .where((library) => library != null)
          .toList();

  @override
  String get identifier => _absoluteUri.toString();

  @override
  List<LibraryElementForLink> get importedLibraries => _importedLibraries ??=
      _linkedLibrary.importDependencies.map(_getDependency).toList();

  @override
  bool get isDartAsync => _absoluteUri.toString() == 'dart:async';

  @override
  bool get isDartCore => _absoluteUri.toString() == 'dart:core';

  /**
   * If this library is part of the build unit being linked, return the library
   * cycle it is part of.  Otherwise return `null`.
   */
  LibraryCycleForLink get libraryCycleForLink;

  @override
  String get name {
    return _definingUnlinkedUnit.libraryName;
  }

  @override
  List<UnitElement> get units {
    if (_units == null) {
      UnlinkedUnit definingUnit = definingUnlinkedUnit;
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

  /**
   * The linked representation of the library in the summary.
   */
  LinkedLibrary get _linkedLibrary;

  /**
   * Search all the units for a top level element with the given
   * [name].  If no name is found, return the singleton instance of
   * [UndefinedElementForLink].
   */
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => _absoluteUri.toString();

  /**
   * Return the [LibraryElement] corresponding to the given dependency [index].
   */
  LibraryElementForLink _getDependency(int index) {
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

  /**
   * Create a [UnitElement] for one of the library's compilation
   * units.
   */
  UnitElement _makeUnitElement(
      UnlinkedUnit unlinkedUnit, int i, String absoluteUri);
}

/**
 * Element representing a library which is part of the build unit
 * being linked.
 */
class LibraryElementInBuildUnit
    extends LibraryElementForLink<CompilationUnitElementInBuildUnit> {
  @override
  final LinkedLibraryBuilder _linkedLibrary;

  /**
   * The [LibraryNode] representing this library in the library dependency
   * graph.
   */
  LibraryNode _libraryNode;

  InheritanceManager _inheritanceManager;

  LibraryElementInBuildUnit(Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri) {
    _libraryNode = new LibraryNode(this);
  }

  /**
   * Get the inheritance manager for this library (creating it if necessary).
   */
  InheritanceManager get inheritanceManager =>
      _inheritanceManager ??= new InheritanceManager(this, ignoreErrors: true);

  @override
  LibraryCycleForLink get libraryCycleForLink {
    if (!_libraryNode.isEvaluated) {
      new LibraryDependencyWalker().walk(_libraryNode);
    }
    return _libraryNode._libraryCycle;
  }

  /**
   * If this library already has a dependency in its dependencies table matching
   * [library], return its index.  Otherwise add a new dependency to table and
   * return its index.
   */
  int addDependency(LibraryElementForLink library) {
    for (int i = 0; i < _linkedLibrary.dependencies.length; i++) {
      if (identical(_getDependency(i), library)) {
        return i;
      }
    }
    int result = _linkedLibrary.dependencies.length;
    Uri libraryUri = library._absoluteUri;
    List<String> partsRelativeToDependency =
        library.definingUnlinkedUnit.publicNamespace.parts;
    List<String> partsAbsolute = partsRelativeToDependency
        .map((partUri) =>
            resolveRelativeUri(libraryUri, Uri.parse(partUri)).toString())
        .toList();
    _linkedLibrary.dependencies.add(new LinkedDependencyBuilder(
        parts: partsAbsolute, uri: libraryUri.toString()));
    _dependencies.add(library);
    return result;
  }

  /**
   * Perform type inference and const cycle detection on this library.
   */
  void link() {
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.link();
    }
  }

  /**
   * Throw away any information stored in the summary by a previous call to
   * [link].
   */
  void unlink() {
    _linkedLibrary.dependencies.length =
        _linkedLibrary.numPrelinkedDependencies;
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.unlink();
    }
  }

  @override
  CompilationUnitElementInBuildUnit _makeUnitElement(
          UnlinkedUnit unlinkedUnit, int i, String absoluteUri) =>
      new CompilationUnitElementInBuildUnit(
          this, unlinkedUnit, _linkedLibrary.units[i], i, absoluteUri);
}

/**
 * Element representing a library which is depended upon (either
 * directly or indirectly) by the build unit being linked.
 */
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
          this, unlinkedUnit, _linkedLibrary.units[i], i, absoluteUri);
}

/**
 * Specialization of [Node] used to construct the library dependency graph.
 */
class LibraryNode extends Node<LibraryNode> {
  /**
   * The library this [Node] represents.
   */
  final LibraryElementInBuildUnit library;

  /**
   * The library cycle to which [library] belongs, if it has been computed.
   * Otherwise `null`.
   */
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

/**
 * Instances of [Linker] contain the necessary information to link
 * together a single build unit.
 */
class Linker {
  /**
   * During linking, if type inference is currently being performed on the
   * initializer of a static or instance variable, the library cycle in
   * which inference is being performed.  Otherwise, `null`.
   *
   * This allows us to suppress instance member type inference results from a
   * library cycle while doing inference on the right hand sides of static and
   * instance variables in that same cycle.
   */
  static LibraryCycleForLink _initializerTypeInferenceCycle;

  /**
   * Callback to ask the client for a [LinkedLibrary] for a
   * dependency.
   */
  final GetDependencyCallback getDependency;

  /**
   * Callback to ask the client for an [UnlinkedUnit].
   */
  final GetUnitCallback getUnit;

  /**
   * Map containing all library elements accessed during linking,
   * whether they are part of the build unit being linked or whether
   * they are dependencies.
   */
  final Map<Uri, LibraryElementForLink> _libraries =
      <Uri, LibraryElementForLink>{};

  /**
   * List of library elements for the libraries in the build unit
   * being linked.
   */
  final List<LibraryElementInBuildUnit> _librariesInBuildUnit =
      <LibraryElementInBuildUnit>[];

  /**
   * Indicates whether type inference should use strong mode rules.
   */
  final bool strongMode;

  LibraryElementForLink _coreLibrary;
  LibraryElementForLink _asyncLibrary;
  TypeProviderForLink _typeProvider;
  TypeSystem _typeSystem;
  SpecialTypeElementForLink _voidElement;
  SpecialTypeElementForLink _dynamicElement;
  SpecialTypeElementForLink _bottomElement;
  ContextForLink _context;
  AnalysisOptionsForLink _analysisOptions;

  Linker(Map<String, LinkedLibraryBuilder> linkedLibraries, this.getDependency,
      this.getUnit, this.strongMode) {
    // Create elements for the libraries to be linked.  The rest of
    // the element model will be created on demand.
    linkedLibraries
        .forEach((String absoluteUri, LinkedLibraryBuilder linkedLibrary) {
      Uri uri = Uri.parse(absoluteUri);
      _librariesInBuildUnit.add(_libraries[uri] =
          new LibraryElementInBuildUnit(this, uri, linkedLibrary));
    });
  }

  /**
   * Get an instance of [AnalysisOptions] for use during linking.
   */
  AnalysisOptionsForLink get analysisOptions =>
      _analysisOptions ??= new AnalysisOptionsForLink(this);

  /**
   * Get the library element for `dart:async`.
   */
  LibraryElementForLink get asyncLibrary =>
      _asyncLibrary ??= getLibrary(Uri.parse('dart:async'));

  /**
   * Get the element representing the "bottom" type.
   */
  SpecialTypeElementForLink get bottomElement => _bottomElement ??=
      new SpecialTypeElementForLink(this, BottomTypeImpl.instance);

  /**
   * Get a stub implementation of [AnalysisContext] which can be used during
   * linking.
   */
  get context => _context ??= new ContextForLink(this);

  /**
   * Get the library element for `dart:core`.
   */
  LibraryElementForLink get coreLibrary =>
      _coreLibrary ??= getLibrary(Uri.parse('dart:core'));

  /**
   * Get the element representing `dynamic`.
   */
  SpecialTypeElementForLink get dynamicElement => _dynamicElement ??=
      new SpecialTypeElementForLink(this, DynamicTypeImpl.instance);

  /**
   * Get an instance of [TypeProvider] for use during linking.
   */
  TypeProviderForLink get typeProvider =>
      _typeProvider ??= new TypeProviderForLink(this);

  /**
   * Get an instance of [TypeSystem] for use during linking.
   */
  TypeSystem get typeSystem => _typeSystem ??= strongMode
      ? new StrongTypeSystemImpl(typeProvider)
      : new TypeSystemImpl(typeProvider);

  /**
   * Get the element representing `void`.
   */
  SpecialTypeElementForLink get voidElement => _voidElement ??=
      new SpecialTypeElementForLink(this, VoidTypeImpl.instance);

  /**
   * Get the library element for the library having the given [uri].
   */
  LibraryElementForLink getLibrary(Uri uri) => _libraries.putIfAbsent(
      uri,
      () => new LibraryElementInDependency(
          this, uri, getDependency(uri.toString())));

  /**
   * Perform type inference and const cycle detection on all libraries
   * in the build unit being linked.
   */
  void link() {
    // Link library cycles in appropriate dependency order.
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.libraryCycleForLink.ensureLinked();
    }
    // TODO(paulberry): set dependencies.
  }

  /**
   * Throw away any information stored in the summary by a previous call to
   * [link].
   */
  void unlink() {
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.unlink();
    }
  }
}

/**
 * Element representing a method resynthesized from a summary during linking.
 */
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
 * Element used for references that result from trying to access a non-static
 * member of an element that is not a container (e.g. accessing the "length"
 * property of a constant).
 *
 * Accesses to a chain of non-static members separated by '.' are handled by
 * creating a [NonstaticMemberElementForLink] that points to another
 * [NonstaticMemberElementForLink], to whatever nesting level is necessary.
 */
class NonstaticMemberElementForLink extends Object
    with ReferenceableElementForLink {
  /**
   * The [ReferenceableElementForLink] which is the target of the non-static
   * reference.
   */
  final ReferenceableElementForLink _target;

  /**
   * The name of the non-static members that is being accessed.
   */
  final String _name;

  /**
   * The library in which the access occurs.  This determines whether private
   * names are accessible.
   */
  final LibraryElementForLink _library;

  /**
   * Whether the [_element] was computed (even if to `null`).
   */
  bool _elementReady = false;

  /**
   * The cached [ExecutableElement] represented by this element.
   */
  ExecutableElement _element;

  NonstaticMemberElementForLink(this._library, this._target, this._name);

  @override
  ConstVariableNode get asConstVariable => _target.asConstVariable;

  /**
   * Return the [ExecutableElement] represented by this element.
   */
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
    if (_library._linker.strongMode) {
      ExecutableElement element = asExecutableElement;
      if (element != null) {
        if (element is PropertyAccessorElement) {
          return element.returnType;
        } else {
          // Method tear-off
          return element.type;
        }
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

/**
 * Element representing a function or method parameter resynthesized
 * from a summary during linking.
 */
class ParameterElementForLink implements ParameterElementImpl {
  /**
   * The unlinked representation of the parameter in the summary.
   */
  final UnlinkedParam _unlinkedParam;

  /**
   * The innermost enclosing element that can declare type parameters.
   */
  final TypeParameterizedElementMixin _typeParameterContext;

  /**
   * If this parameter has a default value and the enclosing library
   * is part of the build unit being linked, the parameter's node in
   * the constant evaluation dependency graph.  Otherwise `null`.
   */
  ConstNode _constNode;

  /**
   * The compilation unit in which this parameter appears.
   */
  final CompilationUnitElementForLink compilationUnit;

  /**
   * The index of this parameter within [enclosingElement]'s parameter list.
   */
  final int _parameterIndex;

  @override
  final ParameterParentElementForLink enclosingElement;

  DartType _inferredType;
  TopLevelInferenceErrorBuilder _inferenceError;
  DartType _declaredType;
  bool _inheritsCovariant = false;

  ParameterElementForLink(this.enclosingElement, this._unlinkedParam,
      this._typeParameterContext, this.compilationUnit, this._parameterIndex) {
    if (_unlinkedParam.initializer?.bodyExpr != null) {
      _constNode = new ConstParameterNode(this);
    }
    if (compilationUnit is CompilationUnitElementInDependency) {
      _inheritsCovariant =
          (compilationUnit as CompilationUnitElementInDependency)
              .parametersInheritingCovariant
              .contains(_unlinkedParam.inheritsCovariantSlot);
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
  String get displayName => _unlinkedParam.name;

  @override
  bool get hasImplicitType =>
      !_unlinkedParam.isFunctionTyped && _unlinkedParam.type == null;

  @override
  bool get inheritsCovariant => _inheritsCovariant;

  @override
  void set inheritsCovariant(bool value) {
    _inheritsCovariant = value;
  }

  @override
  bool get isCovariant {
    if (isExplicitlyCovariant || inheritsCovariant) {
      return true;
    }
    for (UnlinkedExpr annotation in _unlinkedParam.annotations) {
      if (annotation.operations.length == 1 &&
          annotation.operations[0] == UnlinkedExprOperation.pushReference) {
        ReferenceableElementForLink element =
            this.compilationUnit.resolveRef(annotation.references[0].reference);
        if (element is PropertyAccessorElementForLink &&
            element.name == 'checked' &&
            element.library.name == 'meta') {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool get isExplicitlyCovariant => _unlinkedParam.isExplicitlyCovariant;

  @override
  String get name => _unlinkedParam.name;

  @override
  ParameterKind get parameterKind {
    switch (_unlinkedParam.kind) {
      case UnlinkedParamKind.required:
        return ParameterKind.REQUIRED;
      case UnlinkedParamKind.positional:
        return ParameterKind.POSITIONAL;
      case UnlinkedParamKind.named:
        return ParameterKind.NAMED;
    }
    return null;
  }

  @override
  DartType get type {
    if (_inferredType != null) {
      return _inferredType;
    } else if (_declaredType == null) {
      if (_unlinkedParam.isFunctionTyped) {
        _declaredType = new FunctionTypeImpl(
            new FunctionElementForLink_FunctionTypedParam(
                this, _typeParameterContext, _unlinkedParam.parameters));
      } else if (_unlinkedParam.type == null) {
        if (!compilationUnit.isInBuildUnit) {
          _inferredType = compilationUnit.getLinkedType(
              this, _unlinkedParam.inferredTypeSlot);
          return _inferredType;
        } else {
          _declaredType = DynamicTypeImpl.instance;
        }
      } else {
        _declaredType =
            compilationUnit.resolveTypeRef(this, _unlinkedParam.type);
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

  /**
   * Store the results of type inference for this parameter in
   * [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(
        _unlinkedParam.inferredTypeSlot, _inferredType, _typeParameterContext);
    compilationUnit._storeLinkedTypeError(
        _unlinkedParam.inferredTypeSlot, _inferenceError);
    if (inheritsCovariant) {
      compilationUnit
          ._storeInheritsCovariant(_unlinkedParam.inheritsCovariantSlot);
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void setInferenceError(TopLevelInferenceErrorBuilder error) {
    assert(_inferenceError == null);
    _inferenceError = error;
  }
}

/**
 * Element representing the parameter of a synthetic setter for a variable
 * resynthesized during linking.
 */
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

/**
 * Mixin used by elements that can have parameters.
 */
abstract class ParameterParentElementForLink implements Element {
  List<ParameterElement> _parameters;

  /**
   * Get the appropriate integer list to store in
   * [EntityRef.implicitFunctionTypeIndices] to refer to this element.  For an
   * element representing a function-typed parameter, this should return a
   * non-empty list.  For an element representing an executable, this should
   * return the empty list.
   */
  List<int> get implicitFunctionTypeIndices;

  /**
   * Get all the parameters of this element.
   */
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

  /**
   * Get the innermost enclosing element that can declare type parameters (which
   * may be [this], or may be a parent when there are function-typed
   * parameters).
   */
  TypeParameterizedElementMixin get typeParameterContext;

  /**
   * Get the list of unlinked parameters of this element.
   */
  List<UnlinkedParam> get unlinkedParameters;
}

/**
 * Element representing a getter or setter resynthesized from a summary during
 * linking.
 */
abstract class PropertyAccessorElementForLink
    implements PropertyAccessorElementImpl, ReferenceableElementForLink {
  void link(CompilationUnitElementInBuildUnit compilationUnit);
}

/**
 * Specialization of [PropertyAccessorElementForLink] for synthetic accessors
 * implied by the synthetic fields of an enum declaration.
 */
class PropertyAccessorElementForLink_EnumField extends Object
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

/**
 * Specialization of [PropertyAccessorElementForLink] for non-synthetic
 * accessors explicitly declared in the source code.
 */
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
      _unlinkedExecutable.kind == UnlinkedExecutableKind.getter;

  @override
  bool get isSetter =>
      _unlinkedExecutable.kind == UnlinkedExecutableKind.setter;

  @override
  bool get isStatic => enclosingClass == null || super.isStatic;

  @override
  ElementKind get kind =>
      _unlinkedExecutable.kind == UnlinkedExecutableKind.getter
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

/**
 * Specialization of [PropertyAccessorElementForLink] for synthetic accessors
 * implied by a field or variable declaration.
 */
class PropertyAccessorElementForLink_Variable extends Object
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

/**
 * Base class representing an element which can be the target of a reference.
 * When used as a mixin, implements the default behavior shared by most
 * elements.
 */
abstract class ReferenceableElementForLink implements Element {
  /**
   * If this element is a class reference, return it. Otherwise return `null`.
   */
  ClassElementForLink get asClass => null;

  /**
   * If this element can be used in a constructor invocation context,
   * return the associated constructor (which may be `this` or some
   * other element).  Otherwise return `null`.
   */
  ConstructorElementForLink get asConstructor => null;

  /**
   * If this element can be used in a getter context to refer to a
   * constant variable, return the [ConstVariableNode] for the
   * constant value.  Otherwise return `null`.
   */
  ConstVariableNode get asConstVariable => null;

  /**
   * Return the static type (possibly inferred) of the entity referred to by
   * this element.
   */
  DartType get asStaticType => DynamicTypeImpl.instance;

  /**
   * If this element can be used in a getter context as a type inference
   * dependency, return the [TypeInferenceNode] for the inferred type.
   * Otherwise return `null`.
   */
  TypeInferenceNode get asTypeInferenceNode => null;

  @override
  ElementLocation get location => new ElementLocationImpl.con1(this);

  /**
   * Return the type indicated by this element when it is used in a
   * type instantiation context.  If this element can't legally be
   * instantiated as a type, return the dynamic type.
   *
   * If the type is parameterized, [getTypeArgument] will be called to retrieve
   * the type parameters.  It should return `null` for unspecified type
   * parameters.
   */
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  /**
   * If this element contains other named elements, return the
   * contained element having the given [name].  If this element can't
   * contain other named elements, or it doesn't contain an element
   * with the given name, return the singleton of
   * [UndefinedElementForLink].
   */
  ReferenceableElementForLink getContainedName(String name) {
    // TODO(paulberry): handle references to `call` for function types.
    return UndefinedElementForLink.instance;
  }

  /**
   * If this element contains local functions, return the contained local
   * function having the given [index].  If this element doesn't contain local
   * functions, or the index is out of range, return `null`.
   */
  FunctionElementForLink_Local getLocalFunction(int index) => null;
}

/**
 * Element used for references to special types such as `void`.
 */
class SpecialTypeElementForLink extends Object
    with ReferenceableElementForLink {
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

/**
 * Element representing a synthetic variable resynthesized from a summary during
 * linking.
 */
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

/**
 * Element representing a top-level function.
 */
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
  String get identifier => _unlinkedExecutable.name;

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

/**
 * Element representing a top level variable resynthesized from a
 * summary during linking.
 */
class TopLevelVariableElementForLink extends VariableElementForLink
    implements TopLevelVariableElement {
  TopLevelVariableElementForLink(CompilationUnitElementForLink enclosingElement,
      UnlinkedVariable unlinkedVariable)
      : super(unlinkedVariable, enclosingElement);

  @override
  CompilationUnitElementForLink get enclosingElement => compilationUnit;

  @override
  bool get isStatic => true;

  @override
  LibraryElementForLink get library => compilationUnit.library;

  @override
  TypeParameterizedElementMixin get _typeParameterContext => null;

  /**
   * Store the results of type inference for this variable in
   * [compilationUnit].
   */
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

/**
 * Specialization of [DependencyWalker] for performing type inference on static
 * and top level variables.
 */
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

/**
 * Specialization of [Node] used to construct the type inference dependency
 * graph.
 */
class TypeInferenceNode extends Node<TypeInferenceNode> {
  /**
   * The [FunctionElementForLink_Local] to which this node refers.
   */
  final FunctionElementForLink_Local functionElement;

  TypeInferenceNode(this.functionElement);

  @override
  bool get isEvaluated => functionElement._hasTypeBeenInferred;

  /**
   * Collect the type inference dependencies in [unlinkedExecutable] (which
   * should be interpreted relative to [compilationUnit]) and store them in
   * [dependencies].
   */
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
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedList:
          refPtr++;
          intPtr++;
          break;
        case UnlinkedExprOperation.makeTypedMap:
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
    collectDependencies(dependencies, functionElement._unlinkedExecutable,
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
              .instantiate([bodyType.flattenFutures(typeSystem)]);
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
  InterfaceType _iterableType;
  InterfaceType _listType;
  InterfaceType _mapType;
  InterfaceType _nullType;
  InterfaceType _numType;
  InterfaceType _objectType;
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
  InterfaceType get iterableType =>
      _iterableType ??= _buildInterfaceType(_linker.coreLibrary, 'Iterable');

  @override
  InterfaceType get listType =>
      _listType ??= _buildInterfaceType(_linker.coreLibrary, 'List');

  @override
  InterfaceType get mapType =>
      _mapType ??= _buildInterfaceType(_linker.coreLibrary, 'Map');

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

  @override
  DartType get undefinedType => UndefinedTypeImpl.instance;

  InterfaceType _buildInterfaceType(
      LibraryElementForLink library, String name) {
    return library.getContainedName(name).buildType((int i) {
      // TODO(scheglov) accept type parameter names
      var element = new TypeParameterElementImpl('T$i', -1);
      return new TypeParameterTypeImpl(element);
    }, const []);
  }
}

/**
 * Singleton element used for unresolved references.
 */
class UndefinedElementForLink extends Object with ReferenceableElementForLink {
  static final UndefinedElementForLink instance =
      new UndefinedElementForLink._();

  UndefinedElementForLink._();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a top level variable resynthesized from a
 * summary during linking.
 */
abstract class VariableElementForLink
    implements NonParameterVariableElementImpl, PropertyInducingElement {
  /**
   * The unlinked representation of the variable in the summary.
   */
  final UnlinkedVariable unlinkedVariable;

  /**
   * If this variable is declared `const` and the enclosing library is
   * part of the build unit being linked, the variable's node in the
   * constant evaluation dependency graph.  Otherwise `null`.
   */
  ConstNode _constNode;

  /**
   * If this variable has an initializer and an implicit type, and the enclosing
   * library is part of the build unit being linked, the variable's node in the
   * type inference dependency graph.  Otherwise `null`.
   */
  TypeInferenceNode _typeInferenceNode;

  FunctionElementForLink_Initializer _initializer;
  DartType _inferredType;
  DartType _declaredType;
  PropertyAccessorElementForLink_Variable _getter;
  PropertyAccessorElementForLink_Variable _setter;

  /**
   * The compilation unit in which this variable appears.
   */
  final CompilationUnitElementForLink compilationUnit;

  VariableElementForLink(this.unlinkedVariable, this.compilationUnit) {
    if (compilationUnit.isInBuildUnit &&
        unlinkedVariable.initializer?.bodyExpr != null) {
      _constNode = new ConstVariableNode(this);
      if (unlinkedVariable.type == null) {
        _typeInferenceNode = initializer.asTypeInferenceNode;
      }
    }
  }

  /**
   * If the variable has an explicitly declared return type, return it.
   * Otherwise return `null`.
   */
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

  /**
   * Return the inferred type of the variable element.  Should only be called if
   * no type was explicitly declared.
   */
  DartType get inferredType {
    // We should only try to infer a type when none is explicitly declared.
    assert(unlinkedVariable.type == null);
    if (_inferredType == null) {
      if (_typeInferenceNode != null) {
        assert(Linker._initializerTypeInferenceCycle == null);
        Linker._initializerTypeInferenceCycle =
            compilationUnit.library.libraryCycleForLink;
        try {
          new TypeInferenceDependencyWalker().walk(_typeInferenceNode);
          assert(_inferredType != null);
        } finally {
          Linker._initializerTypeInferenceCycle = null;
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
      return _initializer ??= new FunctionElementForLink_Initializer(this);
    }
  }

  @override
  bool get isConst => unlinkedVariable.isConst;

  /**
   * Return `true` if this variable is a field that was explicitly marked as
   * being covariant (in the setter's parameter).
   */
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

  /**
   * The context in which type parameters should be interpreted, or `null` if
   * there are no type parameters in scope.
   */
  TypeParameterizedElementMixin get _typeParameterContext;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => '$enclosingElement.$name';
}
