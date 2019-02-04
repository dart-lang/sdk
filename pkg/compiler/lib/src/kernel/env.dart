// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:front_end/src/api_unstable/dart2js.dart' as ir
    show RedirectingFactoryBody;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';
import 'package:collection/collection.dart' show mergeSort; // a stable sort.

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
import '../js_model/env.dart';
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import 'element_map_impl.dart';

/// Environment for fast lookup of component libraries.
class KProgramEnv {
  final Set<ir.Component> _components = new Set<ir.Component>();

  Map<Uri, KLibraryEnv> _libraryMap;

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
      _libraryMap[library.importUri] = new KLibraryEnv(library);
    }
  }

  void _ensureLibraryMap() {
    if (_libraryMap == null) {
      _libraryMap = <Uri, KLibraryEnv>{};
      for (ir.Component component in _components) {
        _addLibraries(component);
      }
    }
  }

  /// Return the [KLibraryEnv] for the library with the canonical [uri].
  KLibraryEnv lookupLibrary(Uri uri) {
    _ensureLibraryMap();
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(KLibraryEnv library)) {
    _ensureLibraryMap();
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length {
    _ensureLibraryMap();
    return _libraryMap.length;
  }

  /// Convert this [KProgramEnv] to the corresponding [JProgramEnv].
  JProgramEnv convert() => new JProgramEnv(_components);
}

/// Environment for fast lookup of library classes and members.
class KLibraryEnv {
  final ir.Library library;

  Map<String, KClassEnv> _classMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  KLibraryEnv(this.library);

  void _ensureClassMap() {
    if (_classMap == null) {
      _classMap = <String, KClassEnv>{};
      for (ir.Class cls in library.classes) {
        _classMap[cls.name] = new KClassEnvImpl(cls);
      }
    }
  }

  /// Return the [KClassEnv] for the class [name] in [library].
  KClassEnv lookupClass(String name) {
    _ensureClassMap();
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(KClassEnv cls)) {
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

  /// Convert this [KLibraryEnv] to a corresponding [JLibraryEnv] containing
  /// only the members in [liveMembers].
  JLibraryEnv convert(
      IrToElementMap elementMap, Iterable<MemberEntity> liveMembers) {
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
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
    return new JLibraryEnv(library, memberMap, setterMap);
  }
}

class KLibraryData {
  final ir.Library library;
  Iterable<ConstantValue> _metadata;
  // TODO(johnniwinther): Avoid direct access to [imports].
  Map<ir.LibraryDependency, ImportEntity> imports;

  KLibraryData(this.library);

  Iterable<ConstantValue> getMetadata(KernelToElementMapImpl elementMap) {
    return _metadata ??= elementMap.getMetadata(library.annotations);
  }

  Iterable<ImportEntity> getImports(KernelToElementMapImpl elementMap) {
    if (imports == null) {
      List<ir.LibraryDependency> dependencies = library.dependencies;
      if (dependencies.isEmpty) {
        imports = const <ir.LibraryDependency, ImportEntity>{};
      } else {
        imports = <ir.LibraryDependency, ImportEntity>{};
        dependencies.forEach((ir.LibraryDependency node) {
          if (node.isExport) return;
          imports[node] = new ImportEntity(
              node.isDeferred,
              node.name,
              node.targetLibrary.importUri,
              elementMap.getLibrary(node.enclosingLibrary).canonicalUri);
        });
      }
    }
    return imports.values;
  }

  /// Convert this [KLibraryData] to the corresponding [JLibraryData].
  // TODO(johnniwinther): Why isn't [imports] ensured to be non-null here?
  JLibraryData convert() {
    return new JLibraryData(library, imports);
  }
}

/// Member data for a class.
abstract class KClassEnv {
  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Whether the class is a mixin application that mixes in methods with super
  /// calls.
  bool get isSuperMixinApplication;

  /// Ensures that all members have been computed for [cls].
  void ensureMembers(KernelToElementMapImpl elementMap);

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

  /// Convert this [KClassEnv] to the corresponding [JClassEnv] containing only
  /// the members in [liveMembers].
  JClassEnv convert(
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
class KClassEnvImpl implements KClassEnv {
  final ir.Class cls;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;
  List<ir.Member> _members; // in declaration order.
  bool _isSuperMixinApplication;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  KClassEnvImpl(this.cls);

  KClassEnvImpl.internal(this.cls, this._constructorMap, this._memberMap,
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

  void ensureMembers(KernelToElementMapImpl elementMap) {
    _ensureMaps(elementMap);
  }

  void _ensureMaps(KernelToElementMapImpl elementMap) {
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
        // TODO(sigmund): remove once #33732 is fixed.
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
          cloneVisitor ??= new CloneVisitor(
              typeSubstitution: getSubstitutionMap(cls.mixedInType));
          cls.addMember(cloneVisitor.clone(field));
          continue;
        }
        addField(field, includeStatic: false);
      }
      for (ir.Procedure procedure in cls.mixedInClass.mixin.procedures) {
        if (procedure.containsSuperCalls) {
          _isSuperMixinApplication = true;
          cloneVisitor ??= new CloneVisitor(
              typeSubstitution: getSubstitutionMap(cls.mixedInType));
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

  JClassEnv convert(
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
    return new JClassEnvImpl(cls, constructorMap, memberMap, setterMap, members,
        _isSuperMixinApplication ?? false);
  }
}

abstract class KClassData {
  ir.Class get node;

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

  /// Convert this [KClassData] to the corresponding [JClassData].
  JClassData convert();
}

class KClassDataImpl implements KClassData {
  final ir.Class node;
  bool isMixinApplication;
  bool isCallTypeComputed = false;

  InterfaceType thisType;
  InterfaceType rawType;
  InterfaceType supertype;
  InterfaceType mixedInType;
  List<InterfaceType> interfaces;
  OrderedTypeSet orderedTypeSet;

  Iterable<ConstantValue> _metadata;

  KClassDataImpl(this.node);

  bool get isEnumClass => node.isEnum;

  DartType get callType => null;

  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapImpl elementMap) {
    return _metadata ??= elementMap.getMetadata(node.annotations);
  }

  JClassData convert() {
    return new JClassDataImpl(node, new RegularClassDefinition(node));
  }
}

abstract class KMemberData {
  ir.Member get node;

  Map<ir.Expression, ir.DartType> staticTypes;

  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap);

  InterfaceType getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;

  /// Convert this [KMemberData] to the corresponding [JMemberData].
  JMemberData convert();
}

abstract class KMemberDataImpl implements KMemberData {
  final ir.Member node;

  Iterable<ConstantValue> _metadata;

  Map<ir.Expression, ir.DartType> staticTypes;

  KMemberDataImpl(this.node);

  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapImpl elementMap) {
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
}

abstract class KFunctionData implements KMemberData {
  FunctionType getFunctionType(IrToElementMap elementMap);

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap);

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue));
}

abstract class KFunctionDataMixin implements KFunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType> _typeVariables;

  List<TypeVariableType> getFunctionTypeVariables(
      covariant KernelToElementMapImpl elementMap) {
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

class KFunctionDataImpl extends KMemberDataImpl
    with KFunctionDataMixin
    implements KFunctionData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  KFunctionDataImpl(ir.Member node, this.functionNode) : super(node);

  FunctionType getFunctionType(covariant KernelToElementMapImpl elementMap) {
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
  FunctionData convert() {
    return new FunctionDataImpl(
        node, functionNode, new RegularMemberDefinition(node), staticTypes);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

abstract class KConstructorData extends KFunctionData {
  ConstantConstructor getConstructorConstant(
      KernelToElementMapImpl elementMap, ConstructorEntity constructor);
}

class KConstructorDataImpl extends KFunctionDataImpl
    implements KConstructorData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  KConstructorDataImpl(ir.Member node, ir.FunctionNode functionNode)
      : super(node, functionNode);

  ConstantConstructor getConstructorConstant(
      KernelToElementMapImpl elementMap, ConstructorEntity constructor) {
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
  JConstructorData convert() {
    MemberDefinition definition;
    if (node is ir.Constructor) {
      definition = new SpecialMemberDefinition(node, MemberKind.constructor);
    } else {
      definition = new RegularMemberDefinition(node);
    }
    return new JConstructorDataImpl(
        node, functionNode, definition, staticTypes);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

abstract class KFieldData extends KMemberData {
  DartType getFieldType(IrToElementMap elementMap);

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapImpl elementMap);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(KernelToElementMapImpl elementMap);

  bool hasConstantFieldInitializer(KernelToElementMapImpl elementMap);

  ConstantValue getConstantFieldInitializer(KernelToElementMapImpl elementMap);
}

class KFieldDataImpl extends KMemberDataImpl implements KFieldData {
  DartType _type;
  bool _isConstantComputed = false;
  ConstantValue _constantValue;
  ConstantExpression _constantExpression;

  KFieldDataImpl(ir.Field node) : super(node);

  ir.Field get node => super.node;

  DartType getFieldType(covariant KernelToElementMapImpl elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapImpl elementMap) {
    if (_constantExpression == null) {
      if (node.isConst) {
        _constantExpression =
            new Constantifier(elementMap).visit(node.initializer);
      } else {
        failedAt(
            computeSourceSpanFromTreeNode(node),
            "Unexpected field ${node} in "
            "FieldDataImpl.getFieldConstant");
      }
    }
    return _constantExpression;
  }

  @override
  ConstantValue getFieldConstantValue(KernelToElementMapImpl elementMap) {
    if (!_isConstantComputed) {
      _constantValue = elementMap.getConstantValue(node.initializer,
          requireConstant: node.isConst, implicitNull: !node.isConst);
      _isConstantComputed = true;
    }
    return _constantValue;
  }

  @override
  bool hasConstantFieldInitializer(KernelToElementMapImpl elementMap) {
    return getFieldConstantValue(elementMap) != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(KernelToElementMapImpl elementMap) {
    ConstantValue value = getFieldConstantValue(elementMap);
    assert(
        value != null,
        failedAt(
            computeSourceSpanFromTreeNode(node),
            "Field ${node} doesn't have a "
            "constant initial value."));
    return value;
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.instanceField;
    return ClassTypeVariableAccess.none;
  }

  @override
  JFieldData convert() {
    return new JFieldDataImpl(
        node, new RegularMemberDefinition(node), staticTypes);
  }
}

class KTypedefData {
  final ir.Typedef node;
  final TypedefEntity element;
  final TypedefType rawType;

  KTypedefData(this.node, this.element, this.rawType);
}

class KTypeVariableData {
  final ir.TypeParameter node;
  DartType _bound;
  DartType _defaultType;

  KTypeVariableData(this.node);

  DartType getBound(IrToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  DartType getDefaultType(IrToElementMap elementMap) {
    // TODO(34522): Remove `?? const ir.DynamicType()` when issue 34522 is
    // fixed.
    return _defaultType ??=
        elementMap.getDartType(node.defaultType ?? const ir.DynamicType());
  }

  JTypeVariableData copy() {
    return new JTypeVariableData(node);
  }
}
