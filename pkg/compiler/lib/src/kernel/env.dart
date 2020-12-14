// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show isRedirectingFactory, isRedirectingFactoryField;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart' as ir;
import 'package:collection/collection.dart' show mergeSort; // a stable sort.

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/static_type_cache.dart';
import '../ir/util.dart';
import '../js_model/element_map.dart';
import '../js_model/env.dart';
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import '../universe/member_usage.dart';
import 'element_map.dart';
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
        if (isRedirectingFactoryField(member)) {
          continue;
        }
        if (member is ir.Procedure) {
          if (member.kind == ir.ProcedureKind.Setter) {
            _setterMap[member.name.text] = member;
          } else {
            _memberMap[member.name.text] = member;
          }
        } else if (member is ir.Field) {
          _memberMap[member.name.text] = member;
          if (member.isMutable) {
            _setterMap[member.name.text] = member;
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
  JLibraryEnv convert(IrToElementMap elementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage) {
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
    if (_memberMap == null) {
      memberMap = const <String, ir.Member>{};
    } else {
      memberMap = <String, ir.Member>{};
      _memberMap.forEach((String name, ir.Member node) {
        MemberEntity member = elementMap.getMember(node);
        if (liveMemberUsage.containsKey(member)) {
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
        if (liveMemberUsage.containsKey(member)) {
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
    return _metadata ??= elementMap.getMetadata(
        new ir.StaticTypeContext.forAnnotations(
            library, elementMap.typeEnvironment),
        library.annotations);
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

  /// Calls [f] for each member of [cls].
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name);

  /// Calls [f] for each constructor of [cls].
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor));

  /// Calls [f] for each constructor body for the live constructors in the
  /// class.
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor));

  /// Convert this [KClassEnv] to the corresponding [JClassEnv] containing only
  /// the members in [liveMembers].
  JClassEnv convert(IrToElementMap elementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage);
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
  @override
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

  @override
  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  @override
  bool get isSuperMixinApplication {
    assert(_isSuperMixinApplication != null);
    return _isSuperMixinApplication;
  }

  @override
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
      if (isRedirectingFactoryField(member)) return;
      var name = member.name.text;
      _memberMap[name] = member;
      if (member.isMutable) {
        _setterMap[name] = member;
      }
      members.add(member);
    }

    void addProcedure(ir.Procedure member,
        {bool includeStatic, bool includeNoSuchMethodForwarders}) {
      if (memberIsIgnorable(member, cls: cls)) return;
      if (!includeStatic && member.isStatic) return;
      if (member.isNoSuchMethodForwarder) {
        // TODO(sigmund): remove once #33732 is fixed.
        if (!includeNoSuchMethodForwarders ||
            member.name.isPrivate &&
                member.name.libraryName != member.enclosingLibrary.reference) {
          return;
        }
      }
      var name = member.name.text;
      if (member.kind == ir.ProcedureKind.Factory) {
        if (isRedirectingFactory(member)) {
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
        var name = member.name.text;
        _constructorMap[name] = member;
      }
    }

    int mixinMemberCount = 0;

    if (cls.mixedInClass != null) {
      CloneVisitorWithMembers cloneVisitor;
      for (ir.Field field in cls.mixedInClass.mixin.fields) {
        if (field.containsSuperCalls) {
          _isSuperMixinApplication = true;
          cloneVisitor ??= new CloneVisitorWithMembers(
              typeSubstitution: getSubstitutionMap(cls.mixedInType));
          // TODO(jensj): Provide a "referenceFrom" if we need to support
          // the incremental compiler.
          cls.addField(cloneVisitor.cloneField(field, null));
          continue;
        }
        addField(field, includeStatic: false);
      }
      for (ir.Procedure procedure in cls.mixedInClass.mixin.procedures) {
        if (procedure.containsSuperCalls) {
          _isSuperMixinApplication = true;
          cloneVisitor ??= new CloneVisitorWithMembers(
              typeSubstitution: getSubstitutionMap(cls.mixedInType));
          // TODO(jensj): Provide a "referenceFrom" if we need to support
          // the incremental compiler.
          cls.addProcedure(cloneVisitor.cloneProcedure(procedure, null));
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

    mergeSort(members, start: mixinMemberCount, compare: orderByFileOffset);
    _members = members;
  }

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    _ensureMaps(elementMap);
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _ensureMaps(elementMap);
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  @override
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    _ensureMaps(elementMap);
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  @override
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

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    _constructorBodyList?.forEach(f);
  }

  @override
  JClassEnv convert(IrToElementMap elementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage) {
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
        if (liveMemberUsage.containsKey(member)) {
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
        if (liveMemberUsage.containsKey(member)) {
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
        if (liveMemberUsage.containsKey(member)) {
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
        if (liveMemberUsage.containsKey(member)) {
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
  InterfaceType get jsInteropType;
  InterfaceType get rawType;
  InterfaceType get instantiationToBounds;
  InterfaceType get supertype;
  InterfaceType get mixedInType;
  List<InterfaceType> get interfaces;
  OrderedTypeSet get orderedTypeSet;
  DartType get callType;

  bool get isEnumClass;
  bool get isMixinApplication;

  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap);
  List<Variance> getVariances();

  /// Convert this [KClassData] to the corresponding [JClassData].
  JClassData convert();
}

class KClassDataImpl implements KClassData {
  @override
  final ir.Class node;
  @override
  bool isMixinApplication;
  bool isCallTypeComputed = false;

  @override
  InterfaceType thisType;
  @override
  InterfaceType jsInteropType;
  @override
  InterfaceType rawType;
  @override
  InterfaceType instantiationToBounds;
  @override
  InterfaceType supertype;
  @override
  InterfaceType mixedInType;
  @override
  List<InterfaceType> interfaces;
  @override
  OrderedTypeSet orderedTypeSet;

  Iterable<ConstantValue> _metadata;
  List<Variance> _variances;

  KClassDataImpl(this.node);

  @override
  bool get isEnumClass => node.isEnum;

  @override
  DartType get callType => null;

  @override
  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapImpl elementMap) {
    return _metadata ??= elementMap.getMetadata(
        new ir.StaticTypeContext.forAnnotations(
            node.enclosingLibrary, elementMap.typeEnvironment),
        node.annotations);
  }

  @override
  List<Variance> getVariances() =>
      _variances ??= node.typeParameters.map(convertVariance).toList();

  @override
  JClassData convert() {
    return new JClassDataImpl(node, new RegularClassDefinition(node));
  }
}

abstract class KMemberData {
  ir.Member get node;

  StaticTypeCache staticTypes;

  Iterable<ConstantValue> getMetadata(IrToElementMap elementMap);

  InterfaceType getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;

  /// Convert this [KMemberData] to the corresponding [JMemberData].
  JMemberData convert();
}

abstract class KMemberDataImpl implements KMemberData {
  @override
  final ir.Member node;

  Iterable<ConstantValue> _metadata;

  @override
  StaticTypeCache staticTypes;

  KMemberDataImpl(this.node);

  @override
  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapImpl elementMap) {
    return _metadata ??= elementMap.getMetadata(
        new ir.StaticTypeContext(node, elementMap.typeEnvironment),
        node.annotations);
  }

  @override
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

  @override
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
                .getDartType(new ir.TypeParameterType(
                    typeParameter, ir.Nullability.nonNullable))
                .withoutNullability;
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
  @override
  final ir.FunctionNode functionNode;
  FunctionType _type;

  KFunctionDataImpl(ir.Member node, this.functionNode) : super(node);

  @override
  FunctionType getFunctionType(covariant KernelToElementMapImpl elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  @override
  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    void handleParameter(ir.VariableDeclaration parameter,
        {bool isOptional: true}) {
      DartType type = elementMap.getDartType(parameter.type);
      String name = parameter.name;
      ConstantValue defaultValue;
      if (isOptional) {
        if (parameter.initializer != null) {
          defaultValue =
              elementMap.getConstantValue(node, parameter.initializer);
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

abstract class KConstructorData extends KFunctionData {}

class KConstructorDataImpl extends KFunctionDataImpl
    implements KConstructorData {
  ConstructorBodyEntity constructorBody;

  KConstructorDataImpl(ir.Member node, ir.FunctionNode functionNode)
      : super(node, functionNode);

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
}

class KFieldDataImpl extends KMemberDataImpl implements KFieldData {
  DartType _type;

  KFieldDataImpl(ir.Field node) : super(node);

  @override
  ir.Field get node => super.node;

  @override
  DartType getFieldType(covariant KernelToElementMapImpl elementMap) {
    return _type ??= elementMap.getDartType(node.type);
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
