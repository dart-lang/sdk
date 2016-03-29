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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';

/**
 * Link together the build unit consisting of [libraryUris], using
 * [getDependency] to fetch the [LinkedLibrary] objects from other
 * build units, and [getUnit] to fetch the [UnlinkedUnit] objects from
 * both this build unit and other build units.
 *
 * A map is returned whose keys are the URIs of the libraries in this
 * build unit, and whose values are the corresponding
 * [LinkedLibraryBuilder]s.
 */
Map<String, LinkedLibraryBuilder> link(Set<String> libraryUris,
    GetDependencyCallback getDependency, GetUnitCallback getUnit) {
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
  relink(linkedLibraries, getDependency, getUnit);
  return linkedLibraries;
}

/**
 * Given [libraries] (a map from URI to [LinkedLibraryBuilder]
 * containing correct prelinked information), rebuild linked
 * information, using [getDependency] to fetch the [LinkedLibrary]
 * objects from other build units, and [getUnit] to fetch the
 * [UnlinkedUnit] objects from both this build unit and other build
 * units.
 */
void relink(Map<String, LinkedLibraryBuilder> libraries,
    GetDependencyCallback getDependency, GetUnitCallback getUnit) {
  new _Linker(libraries, getDependency, getUnit).link();
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
    implements ClassElement, ReferenceableElementForLink {
  Map<String, ReferenceableElementForLink> _containedNames;

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
  List<ConstructorElementForLink> get constructors;

  @override
  List<FieldElementForLink> get fields;

  /**
   * Indicates whether this is the core class `Object`.
   */
  bool get isObject;

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
   * store the resulting information in the enclosing elements.
   */
  void link(LinkedUnitBuilder linkedUnit);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Element representing a class resynthesized from a summary during
 * linking.
 */
class ClassElementForLink_Class extends ClassElementForLink
    implements TypeParameterContext {
  /**
   * The unlinked representation of the class in the summary.
   */
  final UnlinkedClass _unlinkedClass;

  @override
  final CompilationUnitElementForLink enclosingElement;

  List<ConstructorElementForLink> _constructors;
  ConstructorElementForLink _unnamedConstructor;
  bool _unnamedConstructorComputed = false;
  List<FieldElementForLink_ClassField> _fields;
  InterfaceTypeForLink _supertype;
  InterfaceTypeForLink _type;
  List<TypeParameterTypeForLink> _typeParameterTypes;

  ClassElementForLink_Class(this.enclosingElement, this._unlinkedClass);

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
  bool get isObject => _unlinkedClass.hasNoSupertype;

  @override
  String get name => _unlinkedClass.name;

  @override
  InterfaceTypeForLink get supertype {
    if (isObject) {
      return null;
    }
    return _supertype ??= _computeSupertype();
  }

  /**
   * Get a list of [TypeParameterTypeForLink] objects corresponding to the
   * class's type parameters.
   */
  List<TypeParameterTypeForLink> get typeParameterTypes {
    if (_typeParameterTypes == null) {
      _typeParameterTypes = _unlinkedClass.typeParameters
          .map((UnlinkedTypeParam _) => new TypeParameterTypeForLink())
          .toList();
    }
    return _typeParameterTypes;
  }

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
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
      List<int> implicitFunctionTypeIndices) {
    if (_unlinkedClass.typeParameters.length != 0) {
      return new InterfaceTypeForLink(this);
    } else {
      return _type ??= new InterfaceTypeForLink(this);
    }
  }

  @override
  TypeParameterTypeForLink getTypeParameterType(int index) {
    List<TypeParameterTypeForLink> types = typeParameterTypes;
    return types[types.length - index];
  }

  @override
  void link(LinkedUnitBuilder linkedUnit) {
    for (ConstructorElementForLink constructorElement in constructors) {
      constructorElement.link(linkedUnit);
    }
  }

  InterfaceTypeForLink _computeSupertype() {
    if (_unlinkedClass.supertype != null) {
      DartTypeForLink supertype =
          enclosingElement._resolveTypeRef(_unlinkedClass.supertype, this);
      if (supertype is InterfaceTypeForLink) {
        return supertype;
      }
      // In the event that the supertype isn't an interface type (which may
      // happen in the event of erroneous code) just fall through and pretend
      // the supertype is `Object`.
    }
    return enclosingElement.enclosingElement._linker.objectType;
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

  InterfaceTypeForLink _type;
  List<FieldElementForLink_EnumField> _fields;

  ClassElementForLink_Enum(this._unlinkedEnum);

  @override
  List<ConstructorElementForLink> get constructors => const [];

  @override
  List<FieldElementForLink_EnumField> get fields {
    if (_fields == null) {
      _fields = <FieldElementForLink_EnumField>[];
      _fields.add(new FieldElementForLink_EnumField(null));
      for (UnlinkedEnumValue value in _unlinkedEnum.values) {
        _fields.add(new FieldElementForLink_EnumField(value));
      }
    }
    return _fields;
  }

  @override
  bool get isObject => false;

  @override
  String get name => _unlinkedEnum.name;

  @override
  ConstructorElementForLink get unnamedConstructor => null;

  @override
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      _type ??= new InterfaceTypeForLink(this);

  @override
  void link(LinkedUnitBuilder linkedUnit) {}
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

  @override
  final LibraryElementForLink enclosingElement;

  CompilationUnitElementForLink(
      this.enclosingElement, UnlinkedUnit unlinkedUnit)
      : _references = new List<ReferenceableElementForLink>(
            unlinkedUnit.references.length),
        _unlinkedUnit = unlinkedUnit;

  @override
  List<ClassElementForLink_Enum> get enums {
    if (_enums == null) {
      _enums = <ClassElementForLink_Enum>[];
      for (UnlinkedEnum unlinkedEnum in _unlinkedUnit.enums) {
        _enums.add(new ClassElementForLink_Enum(unlinkedEnum));
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
  DartTypeForLink _resolveTypeRef(
      EntityRef type, TypeParameterContext typeParameterContext,
      {bool defaultVoid: false}) {
    if (type == null) {
      if (defaultVoid) {
        return VoidTypeForLink.instance;
      } else {
        return DynamicTypeForLink.instance;
      }
    }
    if (type.paramReference != 0) {
      return typeParameterContext.getTypeParameterType(type.paramReference);
    } else if (type.syntheticReturnType != null) {
      // TODO(paulberry): implement.
      throw new UnimplementedError();
    } else {
      DartTypeForLink getTypeArgument(int i) {
        if (i < type.typeArguments.length) {
          return _resolveTypeRef(type.typeArguments[i], typeParameterContext);
        } else {
          return DynamicTypeForLink.instance;
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

  CompilationUnitElementInBuildUnit(LibraryElementInBuildUnit libraryElement,
      UnlinkedUnit unlinkedUnit, this._linkedUnit)
      : super(libraryElement, unlinkedUnit);

  @override
  bool get isInBuildUnit => true;

  /**
   * Perform type inference and const cycle detection on this
   * compilation unit.
   */
  void link() {
    for (ClassElementForLink classElement in types) {
      classElement.link(_linkedUnit);
    }
  }

  /**
   * Throw away any information produced by a previous call to [link].
   */
  void unlink() {
    _linkedUnit.constCycles.clear();
    _linkedUnit.references.length = _unlinkedUnit.references.length;
    _linkedUnit.types.clear();
  }
}

/**
 * Element representing a compilation unit which is depended upon
 * (either directly or indirectly) by the build unit being linked.
 */
class CompilationUnitElementInDependency extends CompilationUnitElementForLink {
  @override
  final LinkedUnit _linkedUnit;

  CompilationUnitElementInDependency(LibraryElementInDependency libraryElement,
      UnlinkedUnit unlinkedUnit, this._linkedUnit)
      : super(libraryElement, unlinkedUnit);

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
class ConstructorElementForLink
    implements ConstructorElement, ReferenceableElementForLink {
  /**
   * The unlinked representation of the constructor in the summary.
   */
  final UnlinkedExecutable _unlinkedExecutable;

  /**
   * If this is a `const` constructor and the enclosing library is
   * part of the build unit being linked, the constructor's node in
   * the constant evaluation dependency graph.  Otherwise `null`.
   */
  ConstConstructorNode _constNode;

  @override
  final ClassElementForLink_Class enclosingElement;

  List<ParameterElementForLink> _parameters;

  ConstructorElementForLink(this.enclosingElement, this._unlinkedExecutable) {
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
  bool get isCycleFree {
    if (!_constNode.isEvaluated) {
      new ConstDependencyWalker().walk(_constNode);
    }
    return _constNode.isCycleFree;
  }

  @override
  String get name => _unlinkedExecutable.name;

  @override
  List<ParameterElementForLink> get parameters {
    if (_parameters == null) {
      _parameters = <ParameterElementForLink>[];
      for (UnlinkedParam unlinkedParam in _unlinkedExecutable.parameters) {
        _parameters.add(new ParameterElementForLink(
            unlinkedParam, enclosingElement.enclosingElement));
      }
    }
    return _parameters;
  }

  @override
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeForLink.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) =>
      UndefinedElementForLink.instance;

  /**
   * Perform const cycle detection on this constructor.
   */
  void link(LinkedUnitBuilder linkedUnit) {
    if (_constNode != null && !isCycleFree) {
      linkedUnit.constCycles.add(_unlinkedExecutable.constCycleSlot);
    }
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
 * Representation of a type resynthesized from a summary during linking.
 */
class DartTypeForLink implements DartType {
  const DartTypeForLink();

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
        if (dependency.index == 0) {
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
        // In the case where the strongly connected component has only
        // one node, determine whether there is a trivial cycle or
        // not.
        //
        // TODO(paulberry): could we figure this out in the for-loop
        // above and save some effort?
        if (identical(stack.last, node)) {
          stack.removeLast();
          if (_hasTrivialScc(node)) {
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

  /**
   * The given [node] is in a strongly connected component of size 1.
   * Determine if it contains a trivial cycle (i.e. depends on
   * itself).
   */
  bool _hasTrivialScc(NodeType node) {
    for (NodeType dependency in node.dependencies) {
      if (identical(dependency, node)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Representation of the dynamic type during linking.
 */
class DynamicTypeForLink extends DartTypeForLink {
  /**
   * Singleton instance of the dynamic type.
   */
  static const DynamicTypeForLink instance = const DynamicTypeForLink._();

  const DynamicTypeForLink._();
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

  FieldElementForLink_ClassField(ClassElementForLink_Class enclosingElement,
      UnlinkedVariable unlinkedVariable)
      : enclosingElement = enclosingElement,
        super(unlinkedVariable, enclosingElement.enclosingElement);

  @override
  bool get isStatic => unlinkedVariable.isStatic;
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

  FieldElementForLink_EnumField(this.unlinkedEnumValue);

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
  bool get isStatic => true;

  @override
  String get name =>
      unlinkedEnumValue == null ? 'values' : unlinkedEnumValue.name;

  @override
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeForLink.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) =>
      UndefinedElementForLink.instance;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Representation of an interface type during linking.
 *
 * TODO(paulberry): add the ability to represent type arguments.
 */
class InterfaceTypeForLink extends DartTypeForLink implements InterfaceType {
  @override
  final ClassElementForLink element;

  InterfaceTypeForLink(this.element);
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

  LibraryElementForLink(this._linker, this._absoluteUri) {
    _dependencies.length = _linkedLibrary.dependencies.length;
  }

  @override
  List<UnitElement> get units {
    if (_units == null) {
      UnlinkedUnit definingUnit = _linker.getUnit(_absoluteUri.toString());
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
  ReferenceableElementForLink getContainedName(name) =>
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

  LibraryElementInBuildUnit(
      _Linker linker, Uri absoluteUri, this._linkedLibrary)
      : super(linker, absoluteUri);

  /**
   * Perform type inference and const cycle detection on this library.
   */
  void link() {
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.link();
    }
  }

  /**
   * Throw away any information produced by a previous call to [link].
   */
  void unlink() {
    _linkedLibrary.dependencies.length =
        _linkedLibrary.numPrelinkedDependencies;
    for (CompilationUnitElementInBuildUnit unit in units) {
      unit.link();
    }
  }

  @override
  CompilationUnitElementInBuildUnit _makeUnitElement(
          UnlinkedUnit unlinkedUnit, int i) =>
      new CompilationUnitElementInBuildUnit(
          this, unlinkedUnit, _linkedLibrary.units[i]);
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
  CompilationUnitElementInDependency _makeUnitElement(
          UnlinkedUnit unlinkedUnit, int i) =>
      new CompilationUnitElementInDependency(
          this, unlinkedUnit, _linkedLibrary.units[i]);
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
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeForLink.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) => this;
}

/**
 * Element representing a function or method parameter resynthesized
 * from a summary during linking.
 */
class ParameterElementForLink implements ParameterElement {
  /**
   * The unlinked representation of the parameter in the summary.
   */
  final UnlinkedParam _unlinkedParam;

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

  ParameterElementForLink(this._unlinkedParam, this.compilationUnit) {
    if (_unlinkedParam.defaultValue != null) {
      _constNode = new ConstParameterNode(this);
    }
  }

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
   * Return the type indicated by this element when it is used in a
   * type instantiation context.  If this element can't legally be
   * instantiated as a type, return the dynamic type.
   */
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
      List<int> implicitFunctionTypeIndices);

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
}

/**
 * Interface representing elements which can serve as the context within which
 * type parameter indices are interpreted.
 */
abstract class TypeParameterContext {
  /**
   * Convert the given [index] into a type parameter type.
   */
  TypeParameterTypeForLink getTypeParameterType(int index);
}

/**
 * Representation of a type based on a type parameter during linking.
 *
 * TODO(paulberry): add more functionality as needed.
 */
class TypeParameterTypeForLink extends DartTypeForLink
    implements TypeParameterType {}

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
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeForLink.instance;

  @override
  ReferenceableElementForLink getContainedName(String name) => this;
}

/**
 * Element representing a top level variable resynthesized from a
 * summary during linking.
 */
class VariableElementForLink
    implements VariableElement, ReferenceableElementForLink {
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
   * The compilation unit in which this variable appears.
   */
  final CompilationUnitElementForLink compilationUnit;

  VariableElementForLink(this.unlinkedVariable, this.compilationUnit) {
    if (compilationUnit.isInBuildUnit && unlinkedVariable.constExpr != null) {
      _constNode = new ConstVariableNode(this);
    }
  }

  @override
  ConstructorElementForLink get asConstructor => null;

  @override
  ConstVariableNode get asConstVariable => _constNode;

  @override
  bool get isConst => unlinkedVariable.isConst;

  @override
  bool get isFinal => unlinkedVariable.isFinal;

  @override
  bool get isStatic;

  @override
  String get name => unlinkedVariable.name;

  @override
  DartTypeForLink buildType(DartTypeForLink getTypeArgument(int i),
          List<int> implicitFunctionTypeIndices) =>
      DynamicTypeForLink.instance;

  ReferenceableElementForLink getContainedName(String name) {
    return new NonstaticMemberElementForLink(_constNode);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/**
 * Representation of the void type during linking.
 */
class VoidTypeForLink extends DartTypeForLink {
  static const VoidTypeForLink instance = const VoidTypeForLink._();
  const VoidTypeForLink._();
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

  InterfaceTypeForLink _objectType;
  LibraryElementForLink _coreLibrary;

  _Linker(Map<String, LinkedLibraryBuilder> linkedLibraries, this.getDependency,
      this.getUnit) {
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
   * Get the library element for `dart:core`.
   */
  LibraryElementForLink get coreLibrary =>
      _coreLibrary ??= getLibrary(Uri.parse('dart:core'));

  /**
   * Get the `InterfaceType` for the type `Object`.
   */
  InterfaceTypeForLink get objectType => _objectType ??= coreLibrary
      .getContainedName('Object')
      .buildType((int i) => DynamicTypeForLink.instance, const []);

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
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.link();
    }
    // TODO(paulberry): set dependencies.
  }

  /**
   * Throw away any information produced by a previous call to [link].
   */
  void unlink() {
    for (LibraryElementInBuildUnit library in _librariesInBuildUnit) {
      library.unlink();
    }
  }
}
