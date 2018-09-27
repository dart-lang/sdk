// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.env;

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
import '../ir/element_map.dart';
import '../ir/visitors.dart';
import '../ir/util.dart';
import '../js_model/element_map.dart';
import '../kernel/kelements.dart' show KImport;
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import 'element_map.dart';
import 'element_map_impl.dart';

/// Environment for fast lookup of component libraries.
class JProgramEnv {
  final Set<ir.Component> _components;

  JProgramEnv(this._components);

  Map<Uri, JLibraryEnv> _libraryMap;

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
      _libraryMap[library.importUri] = new JLibraryEnv(library);
    }
  }

  void _ensureLibraryMap() {
    if (_libraryMap == null) {
      _libraryMap = <Uri, JLibraryEnv>{};
      for (ir.Component component in _components) {
        _addLibraries(component);
      }
    }
  }

  /// Return the [JLibraryEnv] for the library with the canonical [uri].
  JLibraryEnv lookupLibrary(Uri uri) {
    _ensureLibraryMap();
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(JLibraryEnv library)) {
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
class JLibraryEnv {
  final ir.Library library;

  Map<String, JClassEnv> _classMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  JLibraryEnv(this.library);

  JLibraryEnv.internal(
      this.library, this._classMap, this._memberMap, this._setterMap);

  void registerClass(String name, JClassEnv classEnv) {
    assert(_classMap.containsKey(name) && _classMap[name] == null);
    _classMap[name] = classEnv;
  }

  void _ensureClassMap() {
    if (_classMap == null) {
      _classMap = <String, JClassEnv>{};
      for (ir.Class cls in library.classes) {
        _classMap[cls.name] = new JClassEnvImpl(cls);
      }
    }
  }

  /// Return the [JClassEnv] for the class [name] in [library].
  JClassEnv lookupClass(String name) {
    _ensureClassMap();
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(JClassEnv cls)) {
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

  /// Creates a new [JLibraryEnv] containing only the members in [liveMembers].
  ///
  /// Currently all classes are copied.
  // TODO(johnniwinther): Filter unused classes.
  JLibraryEnv copyLive(
      IrToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    Map<String, JClassEnv> classMap;
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
    if (_classMap == null) {
      classMap = const <String, JClassEnv>{};
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
    return new JLibraryEnv.internal(library, classMap, memberMap, setterMap);
  }
}

class JLibraryData {
  final ir.Library library;
  Iterable<ConstantValue> _metadata;
  Map<ir.LibraryDependency, ImportEntity> imports;

  JLibraryData(this.library, [this.imports]);

  Iterable<ConstantValue> getMetadata(JsToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(library.annotations);
  }

  Iterable<ImportEntity> getImports(JsToElementMapBase elementMap) {
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

  JLibraryData copy() {
    return new JLibraryData(library, imports);
  }
}

/// Member data for a class.
abstract class JClassEnv {
  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Whether the class is a mixin application that mixes in methods with super
  /// calls.
  bool get isSuperMixinApplication;

  /// Ensures that all members have been computed for [cls].
  void ensureMembers(JsToElementMapBase elementMap);

  /// Return the [MemberEntity] for the member [name] in the class. If [setter]
  /// is `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false});

  /// Calls [f] for each member of the class.
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in the class.
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name);

  /// Calls [f] for each constructor of the class.
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor));

  /// Calls [f] for each constructor body for the live constructors in the
  /// class.
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor));

  /// Creates a new [JClassEnv] containing only the members in [liveMembers].
  JClassEnv copyLive(
      IrToElementMap elementMap, Iterable<MemberEntity> liveMembers);
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
class JClassEnvImpl implements JClassEnv {
  final ir.Class cls;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;
  List<ir.Member> _members; // in declaration order.
  bool _isSuperMixinApplication;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  JClassEnvImpl(this.cls);

  JClassEnvImpl.internal(this.cls, this._constructorMap, this._memberMap,
      this._setterMap, this._members, this._isSuperMixinApplication);

  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  bool get isSuperMixinApplication {
    assert(_isSuperMixinApplication != null);
    return _isSuperMixinApplication;
  }

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

  void ensureMembers(JsToElementMapBase elementMap) {
    _ensureMaps(elementMap);
  }

  void _ensureMaps(JsToElementMapBase elementMap) {
    if (_memberMap != null) return;

    _memberMap = <String, ir.Member>{};
    _setterMap = <String, ir.Member>{};
    _constructorMap = <String, ir.Member>{};
    var members = <ir.Member>[];
    _isSuperMixinApplication = false;

    void addField(ir.Field member, {bool includeStatic}) {
      if (!includeStatic && member.isStatic) return;
      var name = member.name.name;
      if (name.contains('#')) {
        // Skip synthetic .dill members.
        return;
      }
      _memberMap[name] = member;
      if (member.isMutable) {
        _setterMap[name] = member;
      }
      members.add(member);
    }

    void addProcedure(ir.Procedure member,
        {bool includeStatic, bool includeNoSuchMethodForwarders}) {
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
        return;
      }
      if (!includeStatic && member.isStatic) return;
      if (member.isNoSuchMethodForwarder) {
        // TODO(sigmund): remove once #33665 is fixed.
        if (!includeNoSuchMethodForwarders ||
            member.name.isPrivate &&
                member.name.libraryName != member.enclosingLibrary.reference) {
          return;
        }
      }
      var name = member.name.name;
      assert(!name.contains('#'));
      if (member.kind == ir.ProcedureKind.Factory) {
        if (member.function.body is ir.RedirectingFactoryBody) {
          // Don't include redirecting factories.
          return;
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

    void addConstructors(ir.Class c) {
      for (ir.Constructor member in c.constructors) {
        var name = member.name.name;
        assert(!name.contains('#'));
        _constructorMap[name] = member;
      }
    }

    int mixinMemberCount = 0;

    if (cls.mixedInClass != null) {
      CloneVisitor cloneVisitor;
      for (ir.Field field in cls.mixedInClass.mixin.fields) {
        if (field.containsSuperCalls) {
          _isSuperMixinApplication = true;
          cloneVisitor ??= new SuperCloner(getSubstitutionMap(cls.mixedInType));
          cls.addMember(cloneVisitor.clone(field));
          continue;
        }
        addField(field, includeStatic: false);
      }
      for (ir.Procedure procedure in cls.mixedInClass.mixin.procedures) {
        if (procedure.containsSuperCalls) {
          _isSuperMixinApplication = true;
          cloneVisitor ??= new SuperCloner(getSubstitutionMap(cls.mixedInType));
          cls.addMember(cloneVisitor.clone(procedure));
          continue;
        }
        addProcedure(procedure,
            includeStatic: false, includeNoSuchMethodForwarders: false);
      }
      mergeSort(members, compare: orderByFileOffset);
      mixinMemberCount = members.length;
    }

    for (ir.Field member in cls.fields) {
      addField(member, includeStatic: true);
    }
    addConstructors(cls);
    for (ir.Procedure member in cls.procedures) {
      addProcedure(member,
          includeStatic: true, includeNoSuchMethodForwarders: true);
    }

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
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    _ensureMaps(elementMap);
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  /// Calls [f] for each member of [cls].
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _ensureMaps(elementMap);
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    _ensureMaps(elementMap);
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  /// Calls [f] for each constructor of [cls].
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
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

  JClassEnv copyLive(
      IrToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
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
    return new JClassEnvImpl.internal(cls, constructorMap, memberMap, setterMap,
        members, _isSuperMixinApplication);
  }
}

class ClosureClassEnv extends RecordEnv {
  ClosureClassEnv(Map<String, MemberEntity> memberMap) : super(memberMap);

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    if (setter) {
      // All closure fields are final.
      return null;
    }
    return super.lookupMember(elementMap, name, setter: setter);
  }

  @override
  JClassEnv copyLive(
          IrToElementMap elementMap, Iterable<MemberEntity> liveMembers) =>
      this;
}

class RecordEnv implements JClassEnv {
  final Map<String, MemberEntity> _memberMap;

  RecordEnv(this._memberMap);

  @override
  List<ir.Member> ensureMembers(JsToElementMapBase elementMap) {
    // All members have been computed at creation.
    return const <ir.Member>[];
  }

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    // We do not create constructor bodies for containers.
  }

  @override
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
    // We do not create constructors for containers.
  }

  @override
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  bool get isSuperMixinApplication => false;

  @override
  ir.Class get cls => null;

  @override
  JClassEnv copyLive(
      IrToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    return this;
  }
}

abstract class JClassData {
  ClassDefinition get definition;

  InterfaceType get thisType;
  InterfaceType get rawType;
  InterfaceType get supertype;
  InterfaceType get mixedInType;
  List<InterfaceType> get interfaces;
  OrderedTypeSet get orderedTypeSet;
  DartType get callType;

  bool get isEnumClass;
  bool get isMixinApplication;

  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap);

  JClassData copy();
}

class JClassDataImpl implements JClassData {
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

  Iterable<ConstantValue> _metadata;

  JClassDataImpl(this.cls, this.definition);

  bool get isEnumClass => cls != null && cls.isEnum;

  DartType get callType => null;

  Iterable<ConstantValue> getMetadata(covariant JsToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(cls.annotations);
  }

  JClassData copy() {
    return new JClassDataImpl(cls, definition);
  }
}

abstract class JMemberData {
  MemberDefinition get definition;

  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap);

  InterfaceType getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;
}

abstract class JMemberDataImpl implements JMemberData {
  /// TODO(johnniwinther): Remove this from the [JMemberData] interface. Use
  /// `definition.node` instead.
  final ir.Member node;

  final MemberDefinition definition;

  Iterable<ConstantValue> _metadata;

  JMemberDataImpl(this.node, this.definition);

  Iterable<ConstantValue> getMetadata(covariant JsToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(node.annotations);
  }

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity cls = member.enclosingClass;
    if (cls != null) {
      return elementMap.elementEnvironment.getThisType(cls);
    }
    return null;
  }

  JMemberData copy();
}

abstract class FunctionData implements JMemberData {
  FunctionType getFunctionType(IrToElementMap elementMap);

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap);

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue));
}

abstract class FunctionDataMixin implements FunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType> _typeVariables;

  List<TypeVariableType> getFunctionTypeVariables(
      covariant JsToElementMapBase elementMap) {
    if (_typeVariables == null) {
      if (functionNode.typeParameters.isEmpty) {
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

class FunctionDataImpl extends JMemberDataImpl
    with FunctionDataMixin
    implements FunctionData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionDataImpl(
      ir.Member node, this.functionNode, MemberDefinition definition)
      : super(node, definition);

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  void forEachParameter(JsToElementMap elementMap,
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

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return functionType;
  }

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return typeParameters
        .map<TypeVariableType>((ir.TypeParameter typeParameter) {
      return elementMap.getDartType(new ir.TypeParameterType(typeParameter));
    }).toList();
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    throw new UnimplementedError('SignatureData.forEachParameter');
  }

  @override
  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap) {
    return const <ConstantValue>[];
  }

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return memberThisType;
  }
}

abstract class DelegatedFunctionData implements FunctionData {
  final FunctionData baseData;

  DelegatedFunctionData(this.baseData);

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return baseData.getFunctionType(elementMap);
  }

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return baseData.getFunctionTypeVariables(elementMap);
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    return baseData.forEachParameter(elementMap, f);
  }

  @override
  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap) {
    return const <ConstantValue>[];
  }

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
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

abstract class JConstructorData extends FunctionData {
  ConstantConstructor getConstructorConstant(
      JsToElementMapBase elementMap, ConstructorEntity constructor);
}

class JConstructorDataImpl extends FunctionDataImpl
    implements JConstructorData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  JConstructorDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  ConstantConstructor getConstructorConstant(
      JsToElementMapBase elementMap, ConstructorEntity constructor) {
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
  JConstructorData copy() {
    return new JConstructorDataImpl(node, functionNode, definition);
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

abstract class JFieldData extends JMemberData {
  DartType getFieldType(IrToElementMap elementMap);

  ConstantExpression getFieldConstantExpression(JsToElementMapBase elementMap);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(JsToElementMapBase elementMap);

  bool hasConstantFieldInitializer(JsToElementMapBase elementMap);

  ConstantValue getConstantFieldInitializer(JsToElementMapBase elementMap);
}

class JFieldDataImpl extends JMemberDataImpl implements JFieldData {
  DartType _type;
  bool _isConstantComputed = false;
  ConstantValue _constantValue;
  ConstantExpression _constantExpression;

  JFieldDataImpl(ir.Field node, MemberDefinition definition)
      : super(node, definition);

  ir.Field get node => super.node;

  DartType getFieldType(covariant JsToElementMapBase elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ConstantExpression getFieldConstantExpression(JsToElementMapBase elementMap) {
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
  ConstantValue getFieldConstantValue(JsToElementMapBase elementMap) {
    if (!_isConstantComputed) {
      _constantValue = elementMap.getConstantValue(node.initializer,
          requireConstant: node.isConst, implicitNull: !node.isConst);
      _isConstantComputed = true;
    }
    return _constantValue;
  }

  @override
  bool hasConstantFieldInitializer(JsToElementMapBase elementMap) {
    return getFieldConstantValue(elementMap) != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(JsToElementMapBase elementMap) {
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
  JFieldData copy() {
    return new JFieldDataImpl(node, definition);
  }
}

class JTypedefData {
  final ir.Typedef node;
  final TypedefEntity element;
  final TypedefType rawType;

  JTypedefData(this.node, this.element, this.rawType);
}

class JTypeVariableData {
  final ir.TypeParameter node;
  DartType _bound;
  DartType _defaultType;

  JTypeVariableData(this.node);

  DartType getBound(IrToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  DartType getDefaultType(IrToElementMap elementMap) {
    return _defaultType ??= elementMap.getDartType(node.defaultType);
  }

  JTypeVariableData copy() {
    return new JTypeVariableData(node);
  }
}

class SuperCloner extends CloneVisitor {
  SuperCloner(Map<ir.TypeParameter, ir.DartType> typeSubstitution)
      : super(typeSubstitution: typeSubstitution, cloneAnnotations: true);

  @override
  visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    // We ensure that we re-resolve the target by setting the interface target
    // to `null`.
    return new ir.SuperMethodInvocation(node.name, clone(node.arguments));
  }

  @override
  visitSuperPropertyGet(ir.SuperPropertyGet node) {
    // We ensure that we re-resolve the target by setting the interface target
    // to `null`.
    return new ir.SuperPropertyGet(node.name);
  }

  @override
  visitSuperPropertySet(ir.SuperPropertySet node) {
    // We ensure that we re-resolve the target by setting the interface target
    // to `null`.
    return new ir.SuperPropertySet(node.name, clone(node.value), null);
  }
}
