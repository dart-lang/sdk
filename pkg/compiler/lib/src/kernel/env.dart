// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart' as ir;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';
import 'package:collection/algorithms.dart' show mergeSort; // a stable sort.

import '../common.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'element_map_mixins.dart';
import 'kelements.dart' show KImport;

/// Environment for fast lookup of component libraries.
class ProgramEnv {
  final Set<ir.Component> _components = new Set<ir.Component>();

  Map<Uri, LibraryEnv> _libraryMap;

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member get mainMethod => _components.first?.mainMethod;

  ir.Component get mainComponent => _components.first;

  void addComponent(ir.Component component) {
    if (_components.add(component)) {
      if (_libraryMap != null) {
        _addLibraries(component);
      }
    }
  }

  void _addLibraries(ir.Component component) {
    for (ir.Library library in component.libraries) {
      _libraryMap[library.importUri] = new LibraryEnv(library);
    }
  }

  void _ensureLibraryMap() {
    if (_libraryMap == null) {
      _libraryMap = <Uri, LibraryEnv>{};
      for (ir.Component component in _components) {
        _addLibraries(component);
      }
    }
  }

  /// Return the [LibraryEnv] for the library with the canonical [uri].
  LibraryEnv lookupLibrary(Uri uri) {
    _ensureLibraryMap();
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(LibraryEnv library)) {
    _ensureLibraryMap();
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length {
    _ensureLibraryMap();
    return _libraryMap.length;
  }
}

/// Environment for fast lookup of library classes and members.
class LibraryEnv {
  final ir.Library library;

  Map<String, ClassEnv> _classMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  LibraryEnv(this.library);

  LibraryEnv.internal(
      this.library, this._classMap, this._memberMap, this._setterMap);

  void _ensureClassMap() {
    if (_classMap == null) {
      _classMap = <String, ClassEnv>{};
      for (ir.Class cls in library.classes) {
        _classMap[cls.name] = new ClassEnvImpl(cls);
      }
    }
  }

  /// Return the [ClassEnv] for the class [name] in [library].
  ClassEnv lookupClass(String name) {
    _ensureClassMap();
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(ClassEnv cls)) {
    _ensureClassMap();
    _classMap.values.forEach(f);
  }

  void _ensureMemberMaps() {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      _setterMap = <String, ir.Member>{};
      for (ir.Member member in library.members) {
        if (member.name.name.contains('#')) {
          // Skip synthetic .dill members.
          continue;
        }
        if (member is ir.Procedure) {
          if (member.kind == ir.ProcedureKind.Setter) {
            _setterMap[member.name.name] = member;
          } else {
            _memberMap[member.name.name] = member;
          }
        } else if (member is ir.Field) {
          _memberMap[member.name.name] = member;
          if (member.isMutable) {
            _setterMap[member.name.name] = member;
          }
        } else {
          failedAt(
              NO_LOCATION_SPANNABLE, "Unexpected library member node: $member");
        }
      }
    }
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    _ensureMemberMaps();
    return setter ? _setterMap[name] : _memberMap[name];
  }

  void forEachMember(void f(ir.Member member)) {
    _ensureMemberMaps();
    _memberMap.values.forEach(f);
    for (ir.Member member in _setterMap.values) {
      if (member is ir.Procedure) {
        f(member);
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }

  /// Creates a new [LibraryEnv] containing only the members in [liveMembers].
  ///
  /// Currently all classes are copied.
  // TODO(johnniwinther): Filter unused classes.
  LibraryEnv copyLive(
      KernelToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    Map<String, ClassEnv> classMap;
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
    if (_classMap == null) {
      classMap = const <String, ClassEnv>{};
    } else {
      classMap = _classMap;
    }
    if (_memberMap == null) {
      memberMap = const <String, ir.Member>{};
    } else {
      memberMap = <String, ir.Member>{};
      _memberMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          memberMap[name] = node;
        }
      });
    }
    if (_setterMap == null) {
      setterMap = const <String, ir.Member>{};
    } else {
      setterMap = <String, ir.Member>{};
      _setterMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          setterMap[name] = node;
        }
      });
    }
    return new LibraryEnv.internal(library, classMap, memberMap, setterMap);
  }
}

class LibraryData {
  final ir.Library library;
  Iterable<ConstantValue> _metadata;
  Map<ir.LibraryDependency, ImportEntity> imports;

  LibraryData(this.library, [this.imports]);

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(library.annotations);
  }

  Iterable<ImportEntity> getImports(KernelToElementMapBase elementMap) {
    if (imports == null) {
      List<ir.LibraryDependency> dependencies = library.dependencies;
      if (dependencies.isEmpty) {
        imports = const <ir.LibraryDependency, ImportEntity>{};
      } else {
        imports = <ir.LibraryDependency, ImportEntity>{};
        dependencies.forEach((ir.LibraryDependency node) {
          if (node.isExport) return;
          imports[node] = new KImport(
              node.isDeferred,
              node.name,
              node.targetLibrary.importUri,
              elementMap.getLibrary(node.enclosingLibrary));
        });
      }
    }
    return imports.values;
  }

  LibraryData copy() {
    return new LibraryData(library, imports);
  }
}

/// Member data for a class.
abstract class ClassEnv {
  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Ensures that all members have been computed for [cls].
  void ensureMembers(KernelToElementMapBase elementMap);

  /// Return the [MemberEntity] for the member [name] in the class. If [setter]
  /// is `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false});

  /// Calls [f] for each member of the class.
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in the class.
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name);

  /// Calls [f] for each constructor of the class.
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor));

  /// Calls [f] for each constructor body for the live constructors in the
  /// class.
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor));

  /// Creates a new [ClassEnv] containing only the members in [liveMembers].
  ClassEnv copyLive(
      KernelToElementMap elementMap, Iterable<MemberEntity> liveMembers);
}

int orderByFileOffset(ir.TreeNode a, ir.TreeNode b) {
  var aLoc = a.location;
  var bLoc = b.location;
  var aUri = '${aLoc.file}';
  var bUri = '${bLoc.file}';
  var uriCompare = aUri.compareTo(bUri);
  if (uriCompare != 0) return uriCompare;
  return a.fileOffset.compareTo(b.fileOffset);
}

/// Environment for fast lookup of class members.
class ClassEnvImpl implements ClassEnv {
  final ir.Class cls;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;
  List<ir.Member> _members; // in declaration order.

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  ClassEnvImpl(this.cls);

  ClassEnvImpl.internal(this.cls, this._constructorMap, this._memberMap,
      this._setterMap, this._members);

  bool get isUnnamedMixinApplication => cls.isSyntheticMixinImplementation;

  /// Copied from 'package:kernel/transformations/mixin_full_resolution.dart'.
  ir.Constructor _buildForwardingConstructor(
      CloneVisitor cloner, ir.Constructor superclassConstructor) {
    var superFunction = superclassConstructor.function;

    // We keep types and default values for the parameters but always mark the
    // parameters as final (since we just forward them to the super
    // constructor).
    ir.VariableDeclaration cloneVariable(ir.VariableDeclaration variable) {
      ir.VariableDeclaration clone = cloner.clone(variable);
      clone.isFinal = true;
      return clone;
    }

    // Build a [FunctionNode] which has the same parameters as the one in the
    // superclass constructor.
    var positionalParameters =
        superFunction.positionalParameters.map(cloneVariable).toList();
    var namedParameters =
        superFunction.namedParameters.map(cloneVariable).toList();
    var function = new ir.FunctionNode(new ir.EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: superFunction.requiredParameterCount,
        returnType: const ir.VoidType());

    // Build a [SuperInitializer] which takes all positional/named parameters
    // and forward them to the super class constructor.
    var positionalArguments = <ir.Expression>[];
    for (var variable in positionalParameters) {
      positionalArguments.add(new ir.VariableGet(variable));
    }
    var namedArguments = <ir.NamedExpression>[];
    for (var variable in namedParameters) {
      namedArguments.add(
          new ir.NamedExpression(variable.name, new ir.VariableGet(variable)));
    }
    var superInitializer = new ir.SuperInitializer(superclassConstructor,
        new ir.Arguments(positionalArguments, named: namedArguments));

    // Assemble the constructor.
    return new ir.Constructor(function,
        name: superclassConstructor.name,
        initializers: <ir.Initializer>[superInitializer]);
  }

  void ensureMembers(KernelToElementMapBase elementMap) {
    _ensureMaps(elementMap);
  }

  void _ensureMaps(KernelToElementMapBase elementMap) {
    if (_memberMap != null) return;

    _memberMap = <String, ir.Member>{};
    _setterMap = <String, ir.Member>{};
    _constructorMap = <String, ir.Member>{};
    var members = <ir.Member>[];

    void addFields(ir.Class c, {bool includeStatic}) {
      for (ir.Field member in c.fields) {
        if (!includeStatic && member.isStatic) continue;
        var name = member.name.name;
        if (name.contains('#')) {
          // Skip synthetic .dill members.
          continue;
        }
        _memberMap[name] = member;
        if (member.isMutable) {
          _setterMap[name] = member;
        }
        members.add(member);
      }
    }

    void addProcedures(ir.Class c, {bool includeStatic}) {
      for (ir.Procedure member in c.procedures) {
        if (member.isForwardingStub && member.isAbstract) {
          // Skip abstract forwarding stubs. These are never emitted but they
          // might shadow the inclusion of a mixed in method in code like:
          //
          //     class Super {}
          //     class Mixin<T> {
          //       void method(T t) {}
          //     }
          //     class Class extends Super with Mixin<int> {}
          //     main() => new Class().method();
          //
          // Here a stub is created for `Super&Mixin.method` hiding that
          // `Mixin.method` is inherited by `Class`.
          continue;
        }
        if (!includeStatic && member.isStatic) continue;
        var name = member.name.name;
        assert(!name.contains('#'));
        if (member.kind == ir.ProcedureKind.Factory) {
          if (member.function.body is ir.RedirectingFactoryBody) {
            // Don't include redirecting factories.
            continue;
          }
          _constructorMap[name] = member;
        } else if (member.kind == ir.ProcedureKind.Setter) {
          _setterMap[name] = member;
          members.add(member);
        } else {
          assert(member.kind == ir.ProcedureKind.Method ||
              member.kind == ir.ProcedureKind.Getter ||
              member.kind == ir.ProcedureKind.Operator);
          _memberMap[name] = member;
          members.add(member);
        }
      }
    }

    void addConstructors(ir.Class c) {
      for (ir.Constructor member in c.constructors) {
        var name = member.name.name;
        assert(!name.contains('#'));
        _constructorMap[name] = member;
      }
    }

    int mixinMemberCount = 0;
    if (cls.mixedInClass != null) {
      elementMap.ensureClassMembers(cls.mixedInClass);
      addFields(cls.mixedInClass.mixin, includeStatic: false);
      addProcedures(cls.mixedInClass.mixin, includeStatic: false);
      mergeSort(members, compare: orderByFileOffset);
      mixinMemberCount = members.length;
    }
    addFields(cls, includeStatic: true);
    addConstructors(cls);
    addProcedures(cls, includeStatic: true);

    if (isUnnamedMixinApplication && _constructorMap.isEmpty) {
      // Ensure that constructors are created for the superclass in case it
      // is also an unnamed mixin application.
      ClassEntity superclass = elementMap.getClass(cls.superclass);
      elementMap.elementEnvironment.lookupConstructor(superclass, '');

      // Unnamed mixin applications have no constructors when read from .dill.
      // For each generative constructor in the superclass we make a
      // corresponding forwarding constructor in the subclass.
      //
      // This code is copied from
      // 'package:kernel/transformations/mixin_full_resolution.dart'
      var superclassSubstitution = getSubstitutionMap(cls.supertype);
      var superclassCloner =
          new CloneVisitor(typeSubstitution: superclassSubstitution);

      for (var superclassConstructor in cls.superclass.constructors) {
        var forwardingConstructor = _buildForwardingConstructor(
            superclassCloner, superclassConstructor);
        cls.addMember(forwardingConstructor);
        _constructorMap[forwardingConstructor.name.name] =
            forwardingConstructor;
      }
    }

    mergeSort(members, start: mixinMemberCount, compare: orderByFileOffset);
    _members = members;
  }

  /// Return the [MemberEntity] for the member [name] in [cls]. If [setter] is
  /// `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    _ensureMaps(elementMap);
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  /// Calls [f] for each member of [cls].
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member)) {
    _ensureMaps(elementMap);
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name) {
    _ensureMaps(elementMap);
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  /// Calls [f] for each constructor of [cls].
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor)) {
    _ensureMaps(elementMap);
    _constructorMap.values.forEach((ir.Member constructor) {
      f(elementMap.getConstructor(constructor));
    });
  }

  void addConstructorBody(ConstructorBodyEntity constructorBody) {
    _constructorBodyList ??= <ConstructorBodyEntity>[];
    _constructorBodyList.add(constructorBody);
  }

  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    _constructorBodyList?.forEach(f);
  }

  ClassEnv copyLive(
      KernelToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    Map<String, ir.Member> constructorMap;
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
    List<ir.Member> members;
    if (_constructorMap == null) {
      constructorMap = const <String, ir.Member>{};
    } else {
      constructorMap = <String, ir.Member>{};
      _constructorMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          constructorMap[name] = node;
        }
      });
    }
    if (_memberMap == null) {
      memberMap = const <String, ir.Member>{};
    } else {
      memberMap = <String, ir.Member>{};
      _memberMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          memberMap[name] = node;
        }
      });
    }
    if (_setterMap == null) {
      setterMap = const <String, ir.Member>{};
    } else {
      setterMap = <String, ir.Member>{};
      _setterMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          setterMap[name] = node;
        }
      });
    }
    if (_members == null) {
      members = const <ir.Member>[];
    } else {
      members = <ir.Member>[];
      _members.forEach((ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMembers.contains(member)) {
          members.add(node);
        }
      });
    }
    return new ClassEnvImpl.internal(
        cls, constructorMap, memberMap, setterMap, members);
  }
}

class ClosureClassEnv extends RecordEnv {
  ClosureClassEnv(Map<String, MemberEntity> memberMap) : super(memberMap);

  @override
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    if (setter) {
      // All closure fields are final.
      return null;
    }
    return super.lookupMember(elementMap, name, setter: setter);
  }

  @override
  ClassEnv copyLive(
          KernelToElementMap elementMap, Iterable<MemberEntity> liveMembers) =>
      this;
}

class RecordEnv implements ClassEnv {
  final Map<String, MemberEntity> _memberMap;

  RecordEnv(this._memberMap);

  @override
  void ensureMembers(KernelToElementMapBase elementMap) {
    // All members have been computed at creation.
  }

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    // We do not create constructor bodies for containers.
  }

  @override
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor)) {
    // We do not create constructors for containers.
  }

  @override
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  ir.Class get cls => null;

  @override
  ClassEnv copyLive(
      KernelToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    return this;
  }
}

class ClassData {
  /// TODO(johnniwinther): Remove this from the [ClassData] interface. Use
  /// `definition.node` instead.
  final ir.Class cls;
  final ClassDefinition definition;
  bool isMixinApplication;
  bool isCallTypeComputed = false;

  InterfaceType thisType;
  InterfaceType rawType;
  InterfaceType supertype;
  InterfaceType mixedInType;
  List<InterfaceType> interfaces;
  OrderedTypeSet orderedTypeSet;
  DartType callType;

  Iterable<ConstantValue> _metadata;

  ClassData(this.cls, this.definition);

  bool get isEnumClass => cls != null && cls.isEnum;

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(cls.annotations);
  }

  ClassData copy() {
    return new ClassData(cls, definition);
  }
}

abstract class MemberData {
  MemberDefinition get definition;

  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap);

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;
}

abstract class MemberDataImpl implements MemberData {
  /// TODO(johnniwinther): Remove this from the [MemberData] interface. Use
  /// `definition.node` instead.
  final ir.Member node;

  final MemberDefinition definition;

  Iterable<ConstantValue> _metadata;

  MemberDataImpl(this.node, this.definition);

  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(node.annotations);
  }

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity cls = member.enclosingClass;
    if (cls != null) {
      return elementMap.elementEnvironment.getThisType(cls);
    }
    return null;
  }

  MemberData copy();
}

abstract class FunctionData implements MemberData {
  FunctionType getFunctionType(KernelToElementMap elementMap);

  List<TypeVariableType> getFunctionTypeVariables(
      KernelToElementMap elementMap);

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue));
}

abstract class FunctionDataMixin implements FunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType> _typeVariables;

  List<TypeVariableType> getFunctionTypeVariables(
      covariant KernelToElementMapBase elementMap) {
    if (_typeVariables == null) {
      if (functionNode.typeParameters.isEmpty ||
          !elementMap.options.strongMode) {
        _typeVariables = const <TypeVariableType>[];
      } else {
        ir.TreeNode parent = functionNode.parent;
        if (parent is ir.Constructor ||
            (parent is ir.Procedure &&
                parent.kind == ir.ProcedureKind.Factory)) {
          _typeVariables = const <TypeVariableType>[];
        } else {
          _typeVariables = functionNode.typeParameters
              .map<TypeVariableType>((ir.TypeParameter typeParameter) {
            return elementMap
                .getDartType(new ir.TypeParameterType(typeParameter));
          }).toList();
        }
      }
    }
    return _typeVariables;
  }
}

class FunctionDataImpl extends MemberDataImpl
    with FunctionDataMixin
    implements FunctionData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionDataImpl(
      ir.Member node, this.functionNode, MemberDefinition definition)
      : super(node, definition);

  FunctionType getFunctionType(covariant KernelToElementMapBase elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    void handleParameter(ir.VariableDeclaration node, {bool isOptional: true}) {
      DartType type = elementMap.getDartType(node.type);
      String name = node.name;
      ConstantValue defaultValue;
      if (isOptional) {
        if (node.initializer != null) {
          defaultValue = elementMap.getConstantValue(node.initializer);
        } else {
          defaultValue = new NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    for (int i = 0; i < functionNode.positionalParameters.length; i++) {
      handleParameter(functionNode.positionalParameters[i],
          isOptional: i >= functionNode.requiredParameterCount);
    }
    functionNode.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);
  }

  @override
  FunctionData copy() {
    return new FunctionDataImpl(node, functionNode, definition);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

class SignatureFunctionData implements FunctionData {
  final FunctionType functionType;
  final MemberDefinition definition;
  final InterfaceType memberThisType;
  final ClassTypeVariableAccess classTypeVariableAccess;
  final List<ir.TypeParameter> typeParameters;

  SignatureFunctionData(this.definition, this.memberThisType, this.functionType,
      this.typeParameters, this.classTypeVariableAccess);

  FunctionType getFunctionType(covariant KernelToElementMapBase elementMap) {
    return functionType;
  }

  List<TypeVariableType> getFunctionTypeVariables(
      KernelToElementMap elementMap) {
    return typeParameters
        .map<TypeVariableType>((ir.TypeParameter typeParameter) {
      return elementMap.getDartType(new ir.TypeParameterType(typeParameter));
    }).toList();
  }

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    throw new UnimplementedError('SignatureData.forEachParameter');
  }

  @override
  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap) {
    return const <ConstantValue>[];
  }

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap) {
    return memberThisType;
  }
}

abstract class DelegatedFunctionData implements FunctionData {
  final FunctionData baseData;

  DelegatedFunctionData(this.baseData);

  FunctionType getFunctionType(covariant KernelToElementMapBase elementMap) {
    return baseData.getFunctionType(elementMap);
  }

  List<TypeVariableType> getFunctionTypeVariables(
      KernelToElementMap elementMap) {
    return baseData.getFunctionTypeVariables(elementMap);
  }

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    return baseData.forEachParameter(elementMap, f);
  }

  @override
  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap) {
    return const <ConstantValue>[];
  }

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap) {
    return baseData.getMemberThisType(elementMap);
  }

  ClassTypeVariableAccess get classTypeVariableAccess =>
      baseData.classTypeVariableAccess;
}

class GeneratorBodyFunctionData extends DelegatedFunctionData {
  final MemberDefinition definition;
  GeneratorBodyFunctionData(FunctionData baseData, this.definition)
      : super(baseData);
}

abstract class ConstructorData extends FunctionData {
  ConstantConstructor getConstructorConstant(
      KernelToElementMapBase elementMap, ConstructorEntity constructor);
}

class ConstructorDataImpl extends FunctionDataImpl implements ConstructorData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  ConstructorDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  ConstantConstructor getConstructorConstant(
      KernelToElementMapBase elementMap, ConstructorEntity constructor) {
    if (_constantConstructor == null) {
      if (node is ir.Constructor && constructor.isConst) {
        _constantConstructor =
            new Constantifier(elementMap).computeConstantConstructor(node);
      } else {
        failedAt(
            constructor,
            "Unexpected constructor $constructor in "
            "ConstructorDataImpl._getConstructorConstant");
      }
    }
    return _constantConstructor;
  }

  @override
  ConstructorData copy() {
    return new ConstructorDataImpl(node, functionNode, definition);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

class ConstructorBodyDataImpl extends FunctionDataImpl {
  ConstructorBodyDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  // TODO(johnniwinther,sra): Constructor bodies should access type variables
  // through `this`.
  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

abstract class FieldData extends MemberData {
  DartType getFieldType(KernelToElementMap elementMap);

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapBase elementMap);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(KernelToElementMapBase elementMap);

  bool hasConstantFieldInitializer(KernelToElementMapBase elementMap);

  ConstantValue getConstantFieldInitializer(KernelToElementMapBase elementMap);
}

class FieldDataImpl extends MemberDataImpl implements FieldData {
  DartType _type;
  bool _isConstantComputed = false;
  ConstantValue _constantValue;
  ConstantExpression _constantExpression;

  FieldDataImpl(ir.Field node, MemberDefinition definition)
      : super(node, definition);

  ir.Field get node => super.node;

  DartType getFieldType(covariant KernelToElementMapBase elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapBase elementMap) {
    if (_constantExpression == null) {
      if (node.isConst) {
        _constantExpression =
            new Constantifier(elementMap).visit(node.initializer);
      } else {
        failedAt(
            definition.member,
            "Unexpected field ${definition.member} in "
            "FieldDataImpl.getFieldConstant");
      }
    }
    return _constantExpression;
  }

  @override
  ConstantValue getFieldConstantValue(KernelToElementMapBase elementMap) {
    if (!_isConstantComputed) {
      _constantValue = elementMap.getConstantValue(node.initializer,
          requireConstant: node.isConst, implicitNull: !node.isConst);
      _isConstantComputed = true;
    }
    return _constantValue;
  }

  @override
  bool hasConstantFieldInitializer(KernelToElementMapBase elementMap) {
    return getFieldConstantValue(elementMap) != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(KernelToElementMapBase elementMap) {
    ConstantValue value = getFieldConstantValue(elementMap);
    assert(
        value != null,
        failedAt(
            definition.member,
            "Field ${definition.member} doesn't have a "
            "constant initial value."));
    return value;
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.instanceField;
    return ClassTypeVariableAccess.none;
  }

  @override
  FieldData copy() {
    return new FieldDataImpl(node, definition);
  }
}

class TypedefData {
  final ir.Typedef node;
  final TypedefEntity element;
  final TypedefType rawType;

  TypedefData(this.node, this.element, this.rawType);
}

class TypeVariableData {
  final ir.TypeParameter node;
  DartType _bound;

  TypeVariableData(this.node);

  DartType getBound(KernelToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  TypeVariableData copy() {
    return new TypeVariableData(node);
  }
}
