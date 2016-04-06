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
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/task/strong_mode.dart';

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
Map<String, LinkedLibraryBuilder> link(Set<String> libraryUris,
    GetDependencyCallback getDependency, GetUnitCallback getUnit, bool strong) {
  Map<String, LinkedLibraryBuilder> linkedLibraries =
      <String, LinkedLibraryBuilder>{};
  for (String absoluteUri in libraryUris) {
    Uri uri = Uri.parse(absoluteUri);
    UnlinkedUnit getRelativeUnit(String relativeUri) =>
        getUnit(resolveRelativeUri(uri, Uri.parse(relativeUri)).toString());
    linkedLibraries[absoluteUri] = prelink(
        getUnit(absoluteUri),
        getRelativeUnit,
        (String relativeUri) => getRelativeUnit(relativeUri)?.publicNamespace);
  }
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
  new _Linker(libraries, getDependency, getUnit, strong).link();
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
    TypeParameterizedElementForLink typeParameterContext,
    {int slot}) {
  EntityRefBuilder result = new EntityRefBuilder(slot: slot);
  if (type is InterfaceType) {
    ClassElementForLink element = type.element;
    result.reference = compilationUnit.addReference(element);
    if (type.typeArguments.isNotEmpty) {
      result.typeArguments = type.typeArguments
          .map((DartType t) =>
              _createLinkedType(t, compilationUnit, typeParameterContext))
          .toList();
    }
    return result;
  } else if (type is VoidTypeImpl) {
    result.reference = compilationUnit.addRawReference('void');
    return result;
  } else if (type is BottomTypeImpl) {
    result.reference = compilationUnit.addRawReference('*bottom*');
    return result;
  } else if (type is TypeParameterType) {
    TypeParameterElementForLink element = type.element;
    result.paramReference =
        typeParameterContext.typeParameterNestingLevel - element.nestingLevel;
    return result;
  } else if (type is FunctionType) {
    Element element = type.element;
    if (element is FunctionElementForLink_FunctionTypedParam) {
      result.reference =
          compilationUnit.addReference(element.enclosingExecutable);
      result.implicitFunctionTypeIndices = element.implicitFunctionTypeIndices;
      if (type.typeArguments.isNotEmpty) {
        result.typeArguments = type.typeArguments
            .map((DartType t) =>
                _createLinkedType(t, compilationUnit, typeParameterContext))
            .toList();
      }
      return result;
    }
    // TODO(paulberry): implement other cases.
    throw new UnimplementedError('${element.runtimeType}');
  }
  // TODO(paulberry): implement other cases.
  throw new UnimplementedError('${type.runtimeType}');
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
 * Element representing a class or enum resynthesized from a summary
 * during linking.
 */
abstract class ClassElementForLink
    implements ClassElementImpl, ReferenceableElementForLink {
  Map<String, ReferenceableElementForLink> _containedNames;

  @override
  final CompilationUnitElementForLink enclosingElement;

  @override
  bool hasBeenInferred;

  ClassElementForLink(CompilationUnitElementForLink enclosingElement)
      : enclosingElement = enclosingElement,
        hasBeenInferred = !enclosingElement.isInBuildUnit;

  @override
  ConstructorElementForLink get asConstructor => unnamedConstructor;

  @override
  ConstVariableNode get asConstVariable {
    // When a class name is used as a constant variable, it doesn't depend on
    // anything, so it is not necessary to include it in the constant
    // dependency graph.
    return null;
  }

  @override
  DartType get asStaticType =>
      enclosingElement.enclosingElement._linker.typeProvider.typeType;

  @override
  TypeInferenceNode get asTypeInferenceNode => null;

  @override
  List<ConstructorElementForLink> get constructors;

  @override
  List<FieldElementForLink> get fields;

  /**
   * Indicates whether this is the core class `Object`.
   */
  bool get isObject;

  @override
  LibraryElementForLink get library => enclosingElement.library;

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
      for (FieldElementForLink field in fields) {
        // TODO(paulberry): do we need to handle nonstatic fields for
        // consistent behavior with erroneous code?
        if (field.isStatic) {
          _containedNames[field.name] = field;
        }
      }
      // TODO(paulberry): add methods.
    }
    return _containedNames.putIfAbsent(
        name, () => UndefinedElementForLink.instance);
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
    with TypeParameterizedElementForLink {
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
          PropertyAccessorElementForLink accessor =
              new PropertyAccessorElementForLink(
                  this, unlinkedExecutable, syntheticVariable);
          _accessors.add(accessor);
          if (unlinkedExecutable.kind == UnlinkedExecutableKind.getter) {
            syntheticVariable._getter = accessor;
          } else {
            syntheticVariable._setter = accessor;
          }
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
    }
    return _constructors;
  }

  @override
  String get displayName => _unlinkedClass.name;

  @override
  TypeParameterizedElementForLink get enclosingTypeParameterContext => null;

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
  List<InterfaceType> get interfaces => _interfaces ??=
      _unlinkedClass.interfaces.map(_computeInterfaceType).toList();

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
  DartType get type =>
      _type ??= buildType((int i) => typeParameterTypes[i], null);

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
  List<UnlinkedTypeParam> get _unlinkedTypeParams =>
      _unlinkedClass.typeParameters;

  @override
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices) {
    int numTypeParameters = _unlinkedClass.typeParameters.length;
    if (numTypeParameters != 0) {
      List<DartType> typeArguments = new List<DartType>(numTypeParameters);
      for (int i = 0; i < numTypeParameters; i++) {
        typeArguments[i] = getTypeArgument(i);
      }
      return new InterfaceTypeImpl.elementWithNameAndArgs(
          this, name, typeArguments);
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

  /**
   * Convert [typeRef] into an [InterfaceType].
   */
  InterfaceType _computeInterfaceType(EntityRef typeRef) {
    if (_unlinkedClass.supertype != null) {
      DartType supertype = enclosingElement._resolveTypeRef(typeRef, this);
      if (supertype is InterfaceType) {
        return supertype;
      }
      // In the event that the supertype isn't an interface type (which may
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
class ClassElementForLink_Enum extends ClassElementForLink {
  /**
   * The unlinked representation of the enum in the summary.
   */
  final UnlinkedEnum _unlinkedEnum;

  InterfaceType _type;
  List<FieldElementForLink_EnumField> _fields;

  ClassElementForLink_Enum(
      CompilationUnitElementForLink enclosingElement, this._unlinkedEnum)
      : super(enclosingElement);

  @override
  List<PropertyAccessorElement> get accessors {
    // TODO(paulberry): do we need to include synthetic accessors?
    return const [];
  }

  @override
  List<ConstructorElementForLink> get constructors => const [];

  @override
  String get displayName => _unlinkedEnum.name;

  @override
  List<FieldElementForLink_EnumField> get fields {
    if (_fields == null) {
      _fields = <FieldElementForLink_EnumField>[];
      _fields.add(new FieldElementForLink_EnumField(null, this));
      for (UnlinkedEnumValue value in _unlinkedEnum.values) {
        _fields.add(new FieldElementForLink_EnumField(value, this));
      }
    }
    return _fields;
  }

  @override
  List<InterfaceType> get interfaces => const [];

  @override
  bool get isObject => false;

  @override
  List<MethodElement> get methods => const [];

  @override
  List<InterfaceType> get mixins => const [];

  @override
  String get name => _unlinkedEnum.name;

  @override
  InterfaceType get supertype => library._linker.typeProvider.objectType;

  @override
  DartType get type => _type ??= new InterfaceTypeImpl(this);

  @override
  List<TypeParameterElement> get typeParameters => const [];

  @override
  ConstructorElementForLink get unnamedConstructor => null;

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      type;

  @override
  void link(CompilationUnitElementInBuildUnit compilationUnit) {}
}

/**
 * Element representing a compilation unit resynthesized from a
 * summary during linking.
 */
abstract class CompilationUnitElementForLink implements CompilationUnitElement {
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

  List<ClassElementForLink_Class> _types;

  Map<String, ReferenceableElementForLink> _containedNames;
  List<TopLevelVariableElementForLink> _topLevelVariables;
  List<ClassElementForLink_Enum> _enums;

  /**
   * Index of this unit in the list of units in the enclosing library.
   */
  final int unitNum;

  CompilationUnitElementForLink(UnlinkedUnit unlinkedUnit, this.unitNum)
      : _references = new List<ReferenceableElementForLink>(
            unlinkedUnit.references.length),
        _unlinkedUnit = unlinkedUnit;

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

  /**
   * Indicates whether this compilation element is part of the build unit
   * currently being linked.
   */
  bool get isInBuildUnit;

  @override
  LibraryElementForLink get library => enclosingElement;

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
      for (TopLevelVariableElementForLink variable in topLevelVariables) {
        _containedNames[variable.name] = variable;
      }
      // TODO(paulberry): fill in other top level entities (typedefs
      // and executables).
    }
    return _containedNames.putIfAbsent(
        name, () => UndefinedElementForLink.instance);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /**
   * Return the element referred to by the given [index] in
   * [UnlinkedUnit.references].  If the reference is unresolved,
   * return [UndefinedElementForLink.instance].
   */
  ReferenceableElementForLink _resolveRef(int index) {
    if (_references[index] == null) {
      UnlinkedReference unlinkedReference = _unlinkedUnit.references[index];
      LinkedReference linkedReference = _linkedUnit.references[index];
      String name = unlinkedReference.name;
      int containingReference = unlinkedReference.prefixReference;
      if (containingReference != 0 &&
          _linkedUnit.references[containingReference].kind !=
              ReferenceKind.prefix) {
        _references[index] =
            _resolveRef(containingReference).getContainedName(name);
      } else if (linkedReference.dependency == 0) {
        _references[index] = enclosingElement.getContainedName(name);
      } else {
        LibraryElementForLink dependency =
            enclosingElement._getDependency(linkedReference.dependency);
        _references[index] = dependency.getContainedName(name);
      }
    }
    return _references[index];
  }

  /**
   * Resolve an [EntityRef] into a type.  If the reference is
   * unresolved, return [DynamicTypeImpl.instance].
   *
   * TODO(paulberry): or should we have a class representing an
   * unresolved type, for consistency with the full element model?
   */
  DartType _resolveTypeRef(
      EntityRef type, TypeParameterizedElementForLink typeParameterContext,
      {bool defaultVoid: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeImpl.instance;
      } else {
        return DynamicTypeImpl.instance;
      }
    }
    if (type.paramReference != 0) {
      return typeParameterContext.getTypeParameterType(type.paramReference);
    } else if (type.syntheticReturnType != null) {
      // TODO(paulberry): implement.
      throw new UnimplementedError();
    } else if (type.implicitFunctionTypeIndices.isNotEmpty) {
      // TODO(paulberry): implement.
      throw new UnimplementedError();
    } else {
      DartType getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return _resolveTypeRef(type.typeArguments[i], typeParameterContext);
        } else {
          return DynamicTypeImpl.instance;
        }
      }
      ReferenceableElementForLink element = _resolveRef(type.reference);
      return element.buildType(
          getTypeArgument, type.implicitFunctionTypeIndices);
    }
  }
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

  CompilationUnitElementInBuildUnit(this.enclosingElement,
      UnlinkedUnit unlinkedUnit, this._linkedUnit, int unitNum)
      : super(unlinkedUnit, unitNum);

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
      ReferenceKind kind: ReferenceKind.classOrEnum}) {
    List<LinkedReferenceBuilder> linkedReferences = _linkedUnit.references;
    List<UnlinkedReference> unlinkedReferences = _unlinkedUnit.references;
    for (int i = 0; i < linkedReferences.length; i++) {
      LinkedReferenceBuilder linkedReference = linkedReferences[i];
      if (linkedReference.dependency == dependency &&
          (i < unlinkedReferences.length
                  ? unlinkedReferences[i].name
                  : linkedReference.name) ==
              name &&
          linkedReference.numTypeParameters == numTypeParameters &&
          linkedReference.unit == unitNum &&
          (i < unlinkedReferences.length
                  ? unlinkedReferences[i].prefixReference
                  : linkedReference.containingReference) ==
              containingReference &&
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
    } else if (element is ExecutableElementForLink) {
      // TODO(paulberry): will this code ever be executed for an executable
      // element that's not inside a class?
      assert(element.enclosingElement is ClassElementForLink_Class);
      ReferenceKind kind;
      switch (element._unlinkedExecutable.kind) {
        case UnlinkedExecutableKind.functionOrMethod:
          kind = ReferenceKind.method;
          break;
        case UnlinkedExecutableKind.setter:
          kind = ReferenceKind.propertyAccessor;
          break;
        default:
          // TODO(paulberry): implement other cases as necessary
          throw new UnimplementedError('${element._unlinkedExecutable.kind}');
      }
      return addRawReference(element.name,
          numTypeParameters: element.typeParameters.length,
          containingReference: addReference(element.enclosingElement),
          kind: kind);
    }
    // TODO(paulberry): implement other cases
    throw new UnimplementedError('${element.runtimeType}');
  }

  /**
   * Perform type inference and const cycle detection on this
   * compilation unit.
   */
  void link() {
    if (library._linker.strongMode) {
      new InstanceMemberInferrer(enclosingElement._linker.typeProvider,
              enclosingElement.inheritanceManager)
          .inferCompilationUnit(this);
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
   * Store the given [linkedType] in the given [slot] of the this compilation
   * unit's linked type list.
   */
  void _storeLinkedType(int slot, DartType linkedType,
      TypeParameterizedElementForLink typeParameterContext) {
    if (slot != 0) {
      if (linkedType != null && !linkedType.isDynamic) {
        _linkedUnit.types.add(_createLinkedType(
            linkedType, this, typeParameterContext,
            slot: slot));
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

  @override
  final LibraryElementInDependency enclosingElement;

  CompilationUnitElementInDependency(this.enclosingElement,
      UnlinkedUnit unlinkedUnit, this._linkedUnit, int unitNum)
      : super(unlinkedUnit, unitNum);

  @override
  bool get isInBuildUnit => false;
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
              .enclosingElement
              .getContainedName(constructorInitializer.name)
              .asConstructor;
          safeAddDependency(constructor?._constNode);
        }
        CompilationUnitElementForLink compilationUnit =
            constructorElement.enclosingElement.enclosingElement;
        collectDependencies(
            dependencies, constructorInitializer.expression, compilationUnit);
        for (UnlinkedConst unlinkedConst in constructorInitializer.arguments) {
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
          safeAddDependency(field.asConstVariable);
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
      return constructorElement.enclosingElement.enclosingElement
          ._resolveRef(redirectedConstructor.reference)
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
      UnlinkedConst unlinkedConst,
      CompilationUnitElementForLink compilationUnit) {
    if (unlinkedConst == null) {
      return;
    }
    int refPtr = 0;
    for (UnlinkedConstOperation operation in unlinkedConst.operations) {
      switch (operation) {
        case UnlinkedConstOperation.pushReference:
          EntityRef ref = unlinkedConst.references[refPtr++];
          ConstVariableNode variable =
              compilationUnit._resolveRef(ref.reference).asConstVariable;
          if (variable != null) {
            dependencies.add(variable);
          }
          break;
        case UnlinkedConstOperation.makeTypedList:
          refPtr++;
          break;
        case UnlinkedConstOperation.makeTypedMap:
          refPtr += 2;
          break;
        case UnlinkedConstOperation.invokeConstructor:
          EntityRef ref = unlinkedConst.references[refPtr++];
          ConstructorElementForLink element =
              compilationUnit._resolveRef(ref.reference).asConstructor;
          if (element?._constNode != null) {
            dependencies.add(element._constNode);
          }
          break;
        default:
          break;
      }
    }
    assert(refPtr == unlinkedConst.references.length);
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
        parameterElement._unlinkedParam.defaultValue,
        parameterElement.compilationUnit);
    return dependencies;
  }
}

/**
 * Element representing a constructor resynthesized from a summary
 * during linking.
 */
class ConstructorElementForLink extends ExecutableElementForLink
    implements ConstructorElementImpl, ReferenceableElementForLink {
  /**
   * If this is a `const` constructor and the enclosing library is
   * part of the build unit being linked, the constructor's node in
   * the constant evaluation dependency graph.  Otherwise `null`.
   */
  ConstConstructorNode _constNode;

  ConstructorElementForLink(ClassElementForLink_Class enclosingElement,
      UnlinkedExecutable unlinkedExecutable)
      : super(enclosingElement, unlinkedExecutable) {
    if (enclosingElement.enclosingElement.isInBuildUnit &&
        _unlinkedExecutable.constCycleSlot != 0) {
      _constNode = new ConstConstructorNode(this);
    }
  }

  @override
  ConstructorElementForLink get asConstructor => this;

  @override
  ConstVariableNode get asConstVariable => null;

  @override
  DartType get asStaticType {
    // Referring to a constructor directly is an error, so just use
    // `dynamic`.
    return DynamicTypeImpl.instance;
  }

  @override
  TypeInferenceNode get asTypeInferenceNode => null;

  @override
  bool get isCycleFree {
    if (!_constNode.isEvaluated) {
      new ConstDependencyWalker().walk(_constNode);
    }
    return _constNode.isCycleFree;
  }

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) =>
      UndefinedElementForLink.instance;

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
        variableElement.unlinkedVariable.constExpr,
        variableElement.compilationUnit);
    return dependencies;
  }
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
      node.index = node.lowLink = index++;
      stack.add(node);

      // Consider the node's dependencies one at a time.
      for (NodeType dependency in node.dependencies) {
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
        } else if (dependency.index == 0) {
          // The dependency hasn't been seen yet, so recurse on it.
          strongConnect(dependency);
          // If the dependency's lowLink refers to a node that was
          // visited before the current node, that means that the
          // current node, the dependency, and the node referred to by
          // the dependency's lowLink are all part of the same
          // strongly connected component, so we need to update the
          // current node's lowLink accordingly.
          if (dependency.lowLink < node.lowLink) {
            node.lowLink = dependency.lowLink;
          }
        } else {
          // The dependency has already been seen, so it is part of
          // the current node's strongly connected component.  If it
          // was visited earlier than the current node's lowLink, then
          // it is a new addition to the current node's strongly
          // connected component, so we need to update the current
          // node's lowLink accordingly.
          if (dependency.index < node.lowLink) {
            node.lowLink = dependency.index;
          }
        }
      }

      // If the current node's lowLink is the same as its index, then
      // we have finished visiting a strongly connected component, so
      // pop the stack and evaluate it before moving on.
      if (node.lowLink == node.index) {
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

/**
 * Base class for executable elements resynthesized from a summary during
 * linking.
 */
abstract class ExecutableElementForLink extends Object
    with TypeParameterizedElementForLink
    implements ExecutableElementImpl {
  /**
   * The unlinked representation of the method in the summary.
   */
  final UnlinkedExecutable _unlinkedExecutable;

  DartType _declaredReturnType;
  DartType _inferredReturnType;
  FunctionTypeImpl _type;
  List<TypeParameterElementForLink> _typeParameters;
  List<ParameterElementForLink> _parameters;

  /**
   * TODO(paulberry): this won't always be a class element.
   */
  @override
  final ClassElementForLink_Class enclosingElement;

  ExecutableElementForLink(this.enclosingElement, this._unlinkedExecutable);

  @override
  TypeParameterizedElementForLink get enclosingTypeParameterContext =>
      enclosingElement;

  @override
  bool get hasImplicitReturnType => _unlinkedExecutable.returnType == null;

  @override
  bool get isStatic => _unlinkedExecutable.isStatic;

  @override
  bool get isSynthetic => false;

  @override
  LibraryElementForLink get library => enclosingElement.library;

  @override
  String get name => _unlinkedExecutable.name;

  @override
  List<ParameterElementForLink> get parameters {
    if (_parameters == null) {
      int numParameters = _unlinkedExecutable.parameters.length;
      _parameters = new List<ParameterElementForLink>(numParameters);
      for (int i = 0; i < numParameters; i++) {
        UnlinkedParam unlinkedParam = _unlinkedExecutable.parameters[i];
        _parameters[i] = new ParameterElementForLink(
            this, unlinkedParam, this, enclosingElement.enclosingElement, i);
      }
    }
    return _parameters;
  }

  @override
  DartType get returnType {
    if (_inferredReturnType != null) {
      return _inferredReturnType;
    } else if (_declaredReturnType == null) {
      if (_unlinkedExecutable.returnType == null) {
        if (_unlinkedExecutable.kind == UnlinkedExecutableKind.constructor) {
          // TODO(paulberry): implement.
          throw new UnimplementedError();
        } else if (_unlinkedExecutable.kind == UnlinkedExecutableKind.setter &&
            library._linker.strongMode) {
          // In strong mode, setters without an explicit return type are
          // considered to return `void`.
          _declaredReturnType = VoidTypeImpl.instance;
        } else {
          _declaredReturnType = DynamicTypeImpl.instance;
        }
      } else {
        _declaredReturnType = enclosingElement.enclosingElement
            ._resolveTypeRef(_unlinkedExecutable.returnType, this);
      }
    }
    return _declaredReturnType;
  }

  @override
  void set returnType(DartType inferredType) {
    assert(_inferredReturnType == null);
    _inferredReturnType = inferredType;
  }

  @override
  FunctionTypeImpl get type => _type ??= new FunctionTypeImpl(this);

  @override
  List<UnlinkedTypeParam> get _unlinkedTypeParams =>
      _unlinkedExecutable.typeParameters;

  @override
  bool isAccessibleIn(LibraryElement library) =>
      !Identifier.isPrivateName(name) || identical(this.library, library);

  /**
   * Store the results of type inference for this method in [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(
        _unlinkedExecutable.inferredReturnTypeSlot, returnType, this);
    for (ParameterElementForLink parameterElement in parameters) {
      parameterElement.link(compilationUnit);
    }
  }
}

/**
 * Element representing a field resynthesized from a summary during
 * linking.
 */
abstract class FieldElementForLink
    implements FieldElement, ReferenceableElementForLink {}

/**
 * Specialization of [FieldElementForLink] for class fields.
 */
class FieldElementForLink_ClassField extends VariableElementForLink
    implements FieldElementForLink {
  @override
  final ClassElementForLink_Class enclosingElement;

  /**
   * If this is an instance field, the type that was computed by
   * [InstanceMemberInferrer].
   */
  DartType _inferredInstanceType;

  DartType _declaredType;

  FieldElementForLink_ClassField(ClassElementForLink_Class enclosingElement,
      UnlinkedVariable unlinkedVariable)
      : enclosingElement = enclosingElement,
        super(unlinkedVariable, enclosingElement.enclosingElement);

  @override
  bool get isStatic => unlinkedVariable.isStatic;

  @override
  DartType get type {
    assert(!isStatic);
    if (_inferredInstanceType != null) {
      return _inferredInstanceType;
    } else if (_declaredType == null) {
      if (unlinkedVariable.type == null) {
        _declaredType = DynamicTypeImpl.instance;
      } else {
        _declaredType = compilationUnit._resolveTypeRef(
            unlinkedVariable.type, enclosingElement);
      }
    }
    return _declaredType;
  }

  @override
  void set type(DartType inferredType) {
    assert(!isStatic);
    assert(_inferredInstanceType == null);
    _inferredInstanceType = inferredType;
  }

  @override
  TypeParameterizedElementForLink get _typeParameterContext => enclosingElement;

  /**
   * Store the results of type inference for this field in
   * [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (hasImplicitType) {
      if (isStatic) {
        TypeInferenceNode typeInferenceNode = this.asTypeInferenceNode;
        if (typeInferenceNode != null) {
          compilationUnit._storeLinkedType(unlinkedVariable.inferredTypeSlot,
              typeInferenceNode.inferredType, enclosingElement);
        }
      } else {
        compilationUnit._storeLinkedType(unlinkedVariable.inferredTypeSlot,
            _inferredInstanceType, enclosingElement);
      }
    }
  }
}

/**
 * Specialization of [FieldElementForLink] for enum fields.
 */
class FieldElementForLink_EnumField extends FieldElementForLink
    implements FieldElement {
  /**
   * The unlinked representation of the field in the summary, or `null` if this
   * is an enum's `values` field.
   */
  final UnlinkedEnumValue unlinkedEnumValue;

  @override
  final ClassElementForLink_Enum enclosingElement;

  FieldElementForLink_EnumField(this.unlinkedEnumValue, this.enclosingElement);

  @override
  ConstructorElementForLink get asConstructor => null;

  @override
  ConstVariableNode get asConstVariable {
    // Even though enum fields are constants, there is no need to include them
    // in the const dependency graph because they can't participate in a
    // circularity.
    return null;
  }

  @override
  DartType get asStaticType => enclosingElement.type;

  @override
  TypeInferenceNode get asTypeInferenceNode => null;

  @override
  bool get isStatic => true;

  @override
  bool get isSynthetic => false;

  @override
  String get name =>
      unlinkedEnumValue == null ? 'values' : unlinkedEnumValue.name;

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) =>
      UndefinedElementForLink.instance;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a function-typed parameter resynthesied from a summary
 * during linking.
 */
class FunctionElementForLink_FunctionTypedParam implements FunctionElement {
  @override
  final ParameterElementForLink enclosingElement;

  /**
   * The executable element containing this function-typed parameter.
   */
  final Element enclosingExecutable;

  /**
   * The appropriate integer list to store in
   * [EntityRef.implicitFunctionTypeIndices] to refer to this function-typed
   * parameter.
   */
  final List<int> implicitFunctionTypeIndices;

  DartType _returnType;

  FunctionElementForLink_FunctionTypedParam(this.enclosingElement,
      this.enclosingExecutable, this.implicitFunctionTypeIndices);

  @override
  DartType get returnType {
    if (_returnType == null) {
      if (enclosingElement._unlinkedParam.type == null) {
        _returnType = DynamicTypeImpl.instance;
      } else {
        _returnType = enclosingElement.compilationUnit._resolveTypeRef(
            enclosingElement._unlinkedParam.type,
            enclosingElement._typeParameterContext);
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
class FunctionElementForLink_Initializer implements FunctionElementImpl {
  /**
   * The variable for which this element is the initializer.
   */
  final VariableElementForLink _variable;

  FunctionElementForLink_Initializer(this._variable);

  @override
  DartType get returnType {
    // If this is a variable whose type needs inferring, infer it.
    TypeInferenceNode typeInferenceNode = _variable._typeInferenceNode;
    if (typeInferenceNode != null) {
      return typeInferenceNode.inferredType;
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
    // TODO(paulberry): store inferred type.
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * An instance of [LibraryCycleForLink] represents a single library cycle
 * discovered during linking; it consists of one or more libraries in the build
 * unit being linked.
 *
 * This is a stub implementation; at the moment all libraries in the build unit
 * being linked are considered to be part of the same library cycle.  Hence
 * there is just a singleton instance of this class.
 * TODO(paulberry): replace this with a correct implementation.
 */
class LibraryCycleForLink {
  static final LibraryCycleForLink instance = const LibraryCycleForLink._();

  const LibraryCycleForLink._();
}

/**
 * Element representing a library resynthesied from a summary during
 * linking.  The type parameter, [UnitElement], represents the type
 * that will be used for the compilation unit elements.
 */
abstract class LibraryElementForLink<
        UnitElement extends CompilationUnitElementForLink>
    implements LibraryElement {
  /**
   * Pointer back to the linker.
   */
  final _Linker _linker;

  /**
   * The absolute URI of this library.
   */
  final Uri _absoluteUri;

  List<UnitElement> _units;
  final Map<String, ReferenceableElementForLink> _containedNames =
      <String, ReferenceableElementForLink>{};
  final List<LibraryElementForLink> _dependencies = <LibraryElementForLink>[];
  UnlinkedUnit _definingUnlinkedUnit;

  LibraryElementForLink(this._linker, this._absoluteUri) {
    _dependencies.length = _linkedLibrary.dependencies.length;
  }

  /**
   * Get the [UnlinkedUnit] for the defining compilation unit of this library.
   */
  UnlinkedUnit get definingUnlinkedUnit =>
      _definingUnlinkedUnit ??= _linker.getUnit(_absoluteUri.toString());

  @override
  Element get enclosingElement => null;

  /**
   * If this library is part of the build unit being linked, return the library
   * cycle it is part of.  Otherwise return `null`.
   */
  LibraryCycleForLink get libraryCycleForLink;

  @override
  List<UnitElement> get units {
    if (_units == null) {
      UnlinkedUnit definingUnit = definingUnlinkedUnit;
      _units = <UnitElement>[_makeUnitElement(definingUnit, 0)];
      int numParts = definingUnit.parts.length;
      for (int i = 0; i < numParts; i++) {
        // TODO(paulberry): make sure we handle the case where Uri.parse fails.
        // TODO(paulberry): make sure we handle the case where
        // resolveRelativeUri fails.
        UnlinkedUnit partUnit = _linker.getUnit(resolveRelativeUri(
                _absoluteUri, Uri.parse(definingUnit.publicNamespace.parts[i]))
            .toString());
        _units.add(
            _makeUnitElement(partUnit ?? new UnlinkedUnitBuilder(), i + 1));
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

  /**
   * Return the [LibraryElement] corresponding to the given dependency [index].
   */
  LibraryElementForLink _getDependency(int index) {
    return _dependencies[index] ??= _linker.getLibrary(resolveRelativeUri(
        _absoluteUri, Uri.parse(_linkedLibrary.dependencies[index].uri)));
  }

  /**
   * Create a [UnitElement] for one of the library's compilation
   * units.
   */
  UnitElement _makeUnitElement(UnlinkedUnit unlinkedUnit, int i);
}

/**
 * Element representing a library which is part of the build unit
 * being linked.
 */
class LibraryElementInBuildUnit
    extends LibraryElementForLink<CompilationUnitElementInBuildUnit> {
  @override
  final LinkedLibraryBuilder _linkedLibrary;

  InheritanceManager _inheritanceManager;

  LibraryElementInBuildUnit(
      _Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri);

  /**
   * Get the inheritance manager for this library (creating it if necessary).
   */
  InheritanceManager get inheritanceManager =>
      _inheritanceManager ??= new InheritanceManager(this);

  @override
  LibraryCycleForLink get libraryCycleForLink => LibraryCycleForLink.instance;

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
    _linkedLibrary.dependencies.add(new LinkedDependencyBuilder(
        parts: library.definingUnlinkedUnit.publicNamespace.parts,
        uri: library._absoluteUri.toString()));
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
          UnlinkedUnit unlinkedUnit, int i) =>
      new CompilationUnitElementInBuildUnit(
          this, unlinkedUnit, _linkedLibrary.units[i], i);
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
      _Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri);

  @override
  LibraryCycleForLink get libraryCycleForLink => null;

  @override
  CompilationUnitElementInDependency _makeUnitElement(
          UnlinkedUnit unlinkedUnit, int i) =>
      new CompilationUnitElementInDependency(
          this, unlinkedUnit, _linkedLibrary.units[i], i);
}

/**
 * Element representing a method resynthesized from a summary during linking.
 */
class MethodElementForLink extends ExecutableElementForLink
    implements MethodElementImpl {
  MethodElementForLink(ClassElementForLink_Class enclosingElement,
      UnlinkedExecutable unlinkedExecutable)
      : super(enclosingElement, unlinkedExecutable);

  @override
  ElementKind get kind => ElementKind.METHOD;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  int index = 0;

  /**
   * Low link used by Tarjan's strongly connected components
   * algorithm.  This represents the smallest [index] of all the nodes
   * in the strongly connected component to which this node belongs.
   */
  int lowLink = 0;

  List<NodeType> _dependencies;

  /**
   * Retrieve the dependencies of this node.
   */
  List<NodeType> get dependencies => _dependencies ??= computeDependencies();

  /**
   * Indicates whether this node has been evaluated yet.
   */
  bool get isEvaluated;

  /**
   * Compute the dependencies of this node.
   */
  List<NodeType> computeDependencies();
}

/**
 * Element used for references that result from trying to access a nonstatic
 * member of an element that is not a container (e.g. accessing the "length"
 * property of a constant).
 */
class NonstaticMemberElementForLink implements ReferenceableElementForLink {
  /**
   * If the thing from which a member was accessed is a constant, the
   * associated [ConstNode].  Otherwise `null`.
   */
  final ConstVariableNode _constNode;

  NonstaticMemberElementForLink(this._constNode);

  @override
  ConstructorElementForLink get asConstructor => null;

  @override
  ConstVariableNode get asConstVariable => _constNode;

  @override
  DartType get asStaticType {
    // TODO(paulberry): implement.
    return DynamicTypeImpl.instance;
  }

  @override
  TypeInferenceNode get asTypeInferenceNode {
    // TODO(paulberry): implement.
    return null;
  }

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) => this;
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
   * The context in which type parameters should be interpreted.
   */
  final TypeParameterizedElementForLink _typeParameterContext;

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
  final ExecutableElementForLink enclosingElement;

  DartType _inferredType;
  DartType _declaredType;

  ParameterElementForLink(this.enclosingElement, this._unlinkedParam,
      this._typeParameterContext, this.compilationUnit, this._parameterIndex) {
    if (_unlinkedParam.defaultValue != null) {
      _constNode = new ConstParameterNode(this);
    }
  }

  @override
  bool get hasImplicitType =>
      !_unlinkedParam.isFunctionTyped && _unlinkedParam.type == null;

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
  }

  @override
  DartType get type {
    if (_inferredType != null) {
      return _inferredType;
    } else if (_declaredType == null) {
      if (_unlinkedParam.isFunctionTyped) {
        // TODO(paulberry): implement.
        _declaredType = new FunctionTypeImpl(
            new FunctionElementForLink_FunctionTypedParam(
                this, enclosingElement, <int>[_parameterIndex]));
      } else if (_unlinkedParam.type == null) {
        _declaredType = DynamicTypeImpl.instance;
      } else {
        _declaredType = compilationUnit._resolveTypeRef(
            _unlinkedParam.type, _typeParameterContext);
      }
    }
    return _declaredType;
  }

  @override
  void set type(DartType inferredType) {
    assert(_inferredType == null);
    _inferredType = inferredType;
  }

  /**
   * Store the results of type inference for this parameter in
   * [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    compilationUnit._storeLinkedType(
        _unlinkedParam.inferredTypeSlot, _inferredType, _typeParameterContext);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a getter or setter resynthesized from a summary during
 * linking.
 */
class PropertyAccessorElementForLink extends ExecutableElementForLink
    implements PropertyAccessorElementImpl {
  @override
  SyntheticVariableElementForLink variable;

  PropertyAccessorElementForLink(ClassElementForLink_Class enclosingElement,
      UnlinkedExecutable unlinkedExecutable, this.variable)
      : super(enclosingElement, unlinkedExecutable);

  @override
  PropertyAccessorElementForLink get correspondingGetter => variable.getter;

  @override
  bool get isGetter =>
      _unlinkedExecutable.kind == UnlinkedExecutableKind.getter;

  @override
  bool get isSetter =>
      _unlinkedExecutable.kind == UnlinkedExecutableKind.setter;

  @override
  ElementKind get kind => _unlinkedExecutable.kind ==
      UnlinkedExecutableKind.getter ? ElementKind.GETTER : ElementKind.SETTER;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Abstract base class representing an element which can be the target
 * of a reference.
 */
abstract class ReferenceableElementForLink {
  /**
   * If this element can be used in a constructor invocation context,
   * return the associated constructor (which may be `this` or some
   * other element).  Otherwise return `null`.
   */
  ConstructorElementForLink get asConstructor;

  /**
   * If this element can be used in a getter context to refer to a
   * constant variable, return the [ConstVariableNode] for the
   * constant value.  Otherwise return `null`.
   */
  ConstVariableNode get asConstVariable;

  /**
   * Return the static type of the entity referred to by thi element.
   */
  DartType get asStaticType;

  /**
   * If this element can be used in a getter context as a type inference
   * dependency, return the [TypeInferenceNode] for the inferred type.
   * Otherwise return `null`.
   */
  TypeInferenceNode get asTypeInferenceNode;

  /**
   * Return the type indicated by this element when it is used in a
   * type instantiation context.  If this element can't legally be
   * instantiated as a type, return the dynamic type.
   */
  DartType buildType(
      DartType getTypeArgument(int i), List<int> implicitFunctionTypeIndices);

  /**
   * If this element contains other named elements, return the
   * contained element having the given [name].  If this element can't
   * contain other named elements, or it doesn't contain an element
   * with the given name, return the singleton of
   * [UndefinedElementForLink].
   */
  ReferenceableElementForLink getContainedName(String name);
}

/**
 * Element representing a synthetic variable resynthesized from a summary during
 * linking.
 */
class SyntheticVariableElementForLink implements PropertyInducingElementImpl {
  PropertyAccessorElementForLink _getter;
  PropertyAccessorElementForLink _setter;

  @override
  PropertyAccessorElementForLink get getter => _getter;

  @override
  PropertyAccessorElementForLink get setter => _setter;

  @override
  void set type(DartType inferredType) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a top level variable resynthesized from a
 * summary during linking.
 */
class TopLevelVariableElementForLink extends VariableElementForLink
    implements TopLevelVariableElement {
  TopLevelVariableElementForLink(CompilationUnitElement enclosingElement,
      UnlinkedVariable unlinkedVariable)
      : super(unlinkedVariable, enclosingElement);

  @override
  bool get isStatic => true;

  @override
  TypeParameterizedElementForLink get _typeParameterContext => null;

  /**
   * Store the results of type inference for this variable in
   * [compilationUnit].
   */
  void link(CompilationUnitElementInBuildUnit compilationUnit) {
    if (hasImplicitType) {
      TypeInferenceNode typeInferenceNode = this.asTypeInferenceNode;
      if (typeInferenceNode != null) {
        compilationUnit._storeLinkedType(unlinkedVariable.inferredTypeSlot,
            typeInferenceNode.inferredType, null);
      }
    }
  }
}

/**
 * Specialization of [DependencyWalker] for performing type inferrence
 * on static and top level variables.
 */
class TypeInferenceDependencyWalker
    extends DependencyWalker<TypeInferenceNode> {
  @override
  void evaluate(TypeInferenceNode v) {
    v.evaluate(false);
  }

  @override
  void evaluateScc(List<TypeInferenceNode> scc) {
    for (TypeInferenceNode v in scc) {
      v.evaluate(true);
    }
  }
}

/**
 * Specialization of [Node] used to construct the type inference dependency
 * graph.
 */
class TypeInferenceNode extends Node<TypeInferenceNode> {
  /**
   * The [FieldElement] or [TopLevelVariableElement] to which this
   * node refers.
   */
  final VariableElementForLink variableElement;

  /**
   * If a type has been inferred for this node, the inferred type (may be
   * `dynamic`).  Otherwise `null`.
   */
  DartType _inferredType;

  TypeInferenceNode(this.variableElement);

  /**
   * Infer a type for this node if necessary, and return it.
   */
  DartType get inferredType {
    if (_inferredType == null) {
      new TypeInferenceDependencyWalker().walk(this);
      assert(_inferredType != null);
    }
    return _inferredType;
  }

  @override
  bool get isEvaluated => _inferredType != null;

  /**
   * Collect the type inference dependencies in [unlinkedConst] (which should be
   * interpreted relative to [compilationUnit]) and store them in
   * [dependencies].
   */
  void collectDependencies(
      List<TypeInferenceNode> dependencies,
      UnlinkedConst unlinkedConst,
      CompilationUnitElementForLink compilationUnit) {
    if (unlinkedConst == null) {
      return;
    }
    int refPtr = 0;
    for (UnlinkedConstOperation operation in unlinkedConst.operations) {
      switch (operation) {
        case UnlinkedConstOperation.pushReference:
          EntityRef ref = unlinkedConst.references[refPtr++];
          // TODO(paulberry): cache these resolved references for
          // later use by evaluate().
          TypeInferenceNode dependency =
              compilationUnit._resolveRef(ref.reference).asTypeInferenceNode;
          if (dependency != null) {
            dependencies.add(dependency);
          }
          break;
        case UnlinkedConstOperation.makeTypedList:
        case UnlinkedConstOperation.invokeConstructor:
          refPtr++;
          break;
        case UnlinkedConstOperation.makeTypedMap:
          refPtr += 2;
          break;
        case UnlinkedConstOperation.assignToRef:
          // TODO(paulberry): if this reference refers to a variable, should it
          // be considered a type inference dependency?
          refPtr++;
          break;
        case UnlinkedConstOperation.invokeMethodRef:
          // TODO(paulberry): if this reference refers to a variable, should it
          // be considered a type inference dependency?
          refPtr++;
          break;
        default:
          break;
      }
    }
    assert(refPtr == unlinkedConst.references.length);
  }

  @override
  List<TypeInferenceNode> computeDependencies() {
    List<TypeInferenceNode> dependencies = <TypeInferenceNode>[];
    collectDependencies(
        dependencies,
        variableElement.unlinkedVariable.constExpr,
        variableElement.compilationUnit);
    return dependencies;
  }

  @override
  void evaluate(bool inCycle) {
    if (inCycle) {
      _inferredType = DynamicTypeImpl.instance;
    } else if (!variableElement.unlinkedVariable.constExpr.isValidConst) {
      // TODO(paulberry): delete this case and fix errors.
      _inferredType = DynamicTypeImpl.instance;
    } else {
      // Perform RPN evaluation of the cycle, using a stack of
      // inferred types.
      List<DartType> stack = <DartType>[];
      int refPtr = 0;
      int intPtr = 0;
      int assignmentOperatorPtr = 0;
      UnlinkedConst unlinkedConst = variableElement.unlinkedVariable.constExpr;
      TypeProvider typeProvider =
          variableElement.compilationUnit.enclosingElement._linker.typeProvider;
      for (UnlinkedConstOperation operation in unlinkedConst.operations) {
        switch (operation) {
          case UnlinkedConstOperation.pushInt:
            intPtr++;
            stack.add(typeProvider.intType);
            break;
          case UnlinkedConstOperation.pushLongInt:
            int numInts = unlinkedConst.ints[intPtr++];
            intPtr += numInts;
            stack.add(typeProvider.intType);
            break;
          case UnlinkedConstOperation.pushDouble:
            stack.add(typeProvider.doubleType);
            break;
          case UnlinkedConstOperation.pushTrue:
          case UnlinkedConstOperation.pushFalse:
            stack.add(typeProvider.boolType);
            break;
          case UnlinkedConstOperation.pushString:
            stack.add(typeProvider.stringType);
            break;
          case UnlinkedConstOperation.concatenate:
            stack.length -= unlinkedConst.ints[intPtr++];
            stack.add(typeProvider.stringType);
            break;
          case UnlinkedConstOperation.makeSymbol:
            stack.add(typeProvider.symbolType);
            break;
          case UnlinkedConstOperation.pushNull:
            stack.add(BottomTypeImpl.instance);
            break;
          case UnlinkedConstOperation.pushReference:
            EntityRef ref = unlinkedConst.references[refPtr++];
            if (ref.paramReference != 0) {
              stack.add(typeProvider.typeType);
            } else {
              // Synthetic function types can't be directly referred
              // to by expressions.
              assert(ref.syntheticReturnType == null);
              // Nor can implicit function types derived from
              // function-typed parameters.
              assert(ref.implicitFunctionTypeIndices.isEmpty);
              ReferenceableElementForLink element =
                  variableElement.compilationUnit._resolveRef(ref.reference);
              TypeInferenceNode typeInferenceNode = element.asTypeInferenceNode;
              if (typeInferenceNode != null) {
                assert(typeInferenceNode.isEvaluated);
                stack.add(typeInferenceNode._inferredType);
              } else {
                stack.add(element.asStaticType);
              }
            }
            break;
          case UnlinkedConstOperation.extractProperty:
            stack.removeLast();
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.invokeConstructor:
            // TODO(paulberry): don't just pop the args; use their types
            // to infer the type of type arguments.
            stack.length -=
                unlinkedConst.ints[intPtr++] + unlinkedConst.ints[intPtr++];
            EntityRef ref = unlinkedConst.references[refPtr++];
            ConstructorElementForLink element = variableElement.compilationUnit
                ._resolveRef(ref.reference)
                .asConstructor;
            if (element != null) {
              stack.add(element.enclosingElement.buildType(
                  (int i) => i >= ref.typeArguments.length
                      ? DynamicTypeImpl.instance
                      : variableElement.compilationUnit._resolveTypeRef(
                          ref.typeArguments[i],
                          variableElement._typeParameterContext),
                  const []));
            } else {
              stack.add(DynamicTypeImpl.instance);
            }
            break;
          case UnlinkedConstOperation.makeUntypedList:
            stack.length -= unlinkedConst.ints[intPtr++];
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.makeUntypedMap:
            stack.length -= 2 * unlinkedConst.ints[intPtr++];
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.makeTypedList:
            refPtr++;
            stack.length -= unlinkedConst.ints[intPtr++];
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.makeTypedMap:
            refPtr += 2;
            stack.length -= 2 * unlinkedConst.ints[intPtr++];
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.not:
          case UnlinkedConstOperation.complement:
          case UnlinkedConstOperation.negate:
            stack.removeLast();
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.equal:
          case UnlinkedConstOperation.notEqual:
          case UnlinkedConstOperation.and:
          case UnlinkedConstOperation.or:
          case UnlinkedConstOperation.bitXor:
          case UnlinkedConstOperation.bitAnd:
          case UnlinkedConstOperation.bitOr:
          case UnlinkedConstOperation.bitShiftRight:
          case UnlinkedConstOperation.bitShiftLeft:
          case UnlinkedConstOperation.add:
          case UnlinkedConstOperation.subtract:
          case UnlinkedConstOperation.multiply:
          case UnlinkedConstOperation.divide:
          case UnlinkedConstOperation.floorDivide:
          case UnlinkedConstOperation.greater:
          case UnlinkedConstOperation.less:
          case UnlinkedConstOperation.greaterEqual:
          case UnlinkedConstOperation.lessEqual:
          case UnlinkedConstOperation.modulo:
            stack.length -= 2;
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.conditional:
            stack.length -= 3;
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.assignToRef:
            if (!isIncrementOrDecrement(
                unlinkedConst.assignmentOperators[assignmentOperatorPtr++])) {
              stack.removeLast();
            }
            refPtr++;
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.assignToProperty:
            stack.removeLast();
            if (!isIncrementOrDecrement(
                unlinkedConst.assignmentOperators[assignmentOperatorPtr++])) {
              stack.removeLast();
            }
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.assignToIndex:
            stack.length -= 2;
            if (!isIncrementOrDecrement(
                unlinkedConst.assignmentOperators[assignmentOperatorPtr++])) {
              stack.removeLast();
            }
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.extractIndex:
            stack.length -= 2;
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.invokeMethodRef:
            stack.length -=
                unlinkedConst.ints[intPtr++] + unlinkedConst.ints[intPtr++];
            refPtr++;
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          case UnlinkedConstOperation.invokeMethod:
            stack.length -=
                unlinkedConst.ints[intPtr++] + unlinkedConst.ints[intPtr++];
            stack.removeLast();
            // TODO(paulberry): implement.
            stack.add(DynamicTypeImpl.instance);
            break;
          default:
            // TODO(paulberry): implement.
            throw new UnimplementedError('$operation');
        }
      }
      assert(refPtr == unlinkedConst.references.length);
      assert(intPtr == unlinkedConst.ints.length);
      assert(assignmentOperatorPtr == unlinkedConst.assignmentOperators.length);
      assert(stack.length == 1);
      _inferredType = stack[0];
    }
  }
}

/**
 * Element representing a type parameter resynthesized from a summary during
 * linking.
 */
class TypeParameterElementForLink implements TypeParameterElement {
  /**
   * The unlinked representation of the type parameter in the summary.
   */
  final UnlinkedTypeParam _unlinkedTypeParam;

  /**
   * The number of type parameters whose scope overlaps this one, and which are
   * declared earlier in the file.
   */
  final int nestingLevel;

  TypeParameterTypeImpl _type;

  TypeParameterElementForLink(this._unlinkedTypeParam, this.nestingLevel);

  @override
  String get name => _unlinkedTypeParam.name;

  @override
  TypeParameterTypeImpl get type => _type ??= new TypeParameterTypeImpl(this);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Mixin representing an element which can have type parameters.
 */
abstract class TypeParameterizedElementForLink
    implements TypeParameterizedElement {
  List<TypeParameterType> _typeParameterTypes;
  List<TypeParameterElementForLink> _typeParameters;
  int _nestingLevel;

  /**
   * Get the type parameter context enclosing this one, if any.
   */
  TypeParameterizedElementForLink get enclosingTypeParameterContext;

  /**
   * Find out how many type parameters are in scope in this context.
   */
  int get typeParameterNestingLevel =>
      _nestingLevel ??= _unlinkedTypeParams.length +
          (enclosingTypeParameterContext?.typeParameterNestingLevel ?? 0);

  List<TypeParameterElementForLink> get typeParameters {
    if (_typeParameters == null) {
      int enclosingNestingLevel =
          enclosingTypeParameterContext?.typeParameterNestingLevel ?? 0;
      int numTypeParameters = _unlinkedTypeParams.length;
      _typeParameters =
          new List<TypeParameterElementForLink>(numTypeParameters);
      for (int i = 0; i < numTypeParameters; i++) {
        _typeParameters[i] = new TypeParameterElementForLink(
            _unlinkedTypeParams[i], enclosingNestingLevel + i);
      }
    }
    return _typeParameters;
  }

  /**
   * Get a list of [TypeParameterType] objects corresponding to the
   * element's type parameters.
   */
  List<TypeParameterType> get typeParameterTypes {
    if (_typeParameterTypes == null) {
      _typeParameterTypes = typeParameters
          .map((TypeParameterElementForLink e) => e.type)
          .toList();
    }
    return _typeParameterTypes;
  }

  /**
   * Get the [UnlinkedTypeParam]s representing the type parameters declared by
   * this element.
   */
  List<UnlinkedTypeParam> get _unlinkedTypeParams;

  /**
   * Convert the given [index] into a type parameter type.
   */
  TypeParameterType getTypeParameterType(int index) {
    List<TypeParameterType> types = typeParameterTypes;
    if (index <= types.length) {
      return types[types.length - index];
    } else if (enclosingTypeParameterContext != null) {
      return enclosingTypeParameterContext
          .getTypeParameterType(index - types.length);
    } else {
      // If we get here, it means that a summary contained a type parameter index
      // that was out of range.
      throw new RangeError('Invalid type parameter index');
    }
  }
}

class TypeProviderForLink implements TypeProvider {
  final _Linker _linker;

  InterfaceType _boolType;
  InterfaceType _deprecatedType;
  InterfaceType _doubleType;
  InterfaceType _functionType;
  InterfaceType _futureDynamicType;
  InterfaceType _futureNullType;
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
  List<InterfaceType> get nonSubtypableTypes => <InterfaceType>[
        nullType,
        numType,
        intType,
        doubleType,
        boolType,
        stringType
      ];

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
    return library
        .getContainedName(name)
        .buildType((int i) => DynamicTypeImpl.instance, const []);
  }
}

/**
 * Singleton element used for unresolved references.
 */
class UndefinedElementForLink implements ReferenceableElementForLink {
  static const UndefinedElementForLink instance =
      const UndefinedElementForLink._();

  const UndefinedElementForLink._();

  @override
  ConstructorElementForLink get asConstructor => null;

  @override
  ConstVariableNode get asConstVariable => null;

  @override
  DartType get asStaticType => DynamicTypeImpl.instance;

  @override
  TypeInferenceNode get asTypeInferenceNode => null;

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) => this;
}

/**
 * Element representing a top level variable resynthesized from a
 * summary during linking.
 */
class VariableElementForLink
    implements VariableElementImpl, ReferenceableElementForLink {
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

  /**
   * The compilation unit in which this variable appears.
   */
  final CompilationUnitElementForLink compilationUnit;

  VariableElementForLink(this.unlinkedVariable, this.compilationUnit) {
    if (compilationUnit.isInBuildUnit && unlinkedVariable.constExpr != null) {
      _constNode = new ConstVariableNode(this);
      if (unlinkedVariable.type == null) {
        _typeInferenceNode = new TypeInferenceNode(this);
      }
    }
  }

  @override
  ConstructorElementForLink get asConstructor => null;

  @override
  ConstVariableNode get asConstVariable => _constNode;

  @override
  DartType get asStaticType {
    // TODO(paulberry): implement.
    return DynamicTypeImpl.instance;
  }

  @override
  TypeInferenceNode get asTypeInferenceNode => _typeInferenceNode;

  @override
  bool get hasImplicitType => unlinkedVariable.type == null;

  @override
  FunctionElementForLink_Initializer get initializer {
    if (unlinkedVariable.constExpr == null) {
      return null;
    } else {
      return _initializer ??= new FunctionElementForLink_Initializer(this);
    }
  }

  @override
  bool get isConst => unlinkedVariable.isConst;

  @override
  bool get isFinal => unlinkedVariable.isFinal;

  @override
  bool get isStatic;

  @override
  bool get isSynthetic => false;

  @override
  String get name => unlinkedVariable.name;

  @override
  void set type(DartType newType) {
    // TODO(paulberry): store inferred type.
  }

  /**
   * The context in which type parameters should be interpreted, or `null` if
   * there are no type parameters in scope.
   */
  TypeParameterizedElementForLink get _typeParameterContext;

  @override
  DartType buildType(DartType getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeImpl.instance;

  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(_constNode);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Instances of [_Linker] contain the necessary information to link
 * together a single build unit.
 */
class _Linker {
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

  _Linker(Map<String, LinkedLibraryBuilder> linkedLibraries, this.getDependency,
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
   * Get the library element for `dart:async`.
   */
  LibraryElementForLink get asyncLibrary =>
      _asyncLibrary ??= getLibrary(Uri.parse('dart:async'));

  /**
   * Get the library element for `dart:core`.
   */
  LibraryElementForLink get coreLibrary =>
      _coreLibrary ??= getLibrary(Uri.parse('dart:core'));

  /**
   * Get an instance of [TypeProvider] for use during linking.
   */
  TypeProviderForLink get typeProvider =>
      _typeProvider ??= new TypeProviderForLink(this);

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
    // TODO(paulberry): link library cycles in appropriate dependency order.
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.link();
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
