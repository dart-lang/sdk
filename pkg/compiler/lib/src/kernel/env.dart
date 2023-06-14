// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'package:collection/collection.dart' show mergeSort; // a stable sort.

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/static_type_cache.dart';
import '../ir/util.dart';
import '../js_model/class_type_variable_access.dart';
import '../js_model/element_map.dart';
import '../js_model/env.dart';
import '../ordered_typeset.dart';
import '../universe/member_usage.dart';
import 'element_map.dart' show memberIsIgnorable, KernelToElementMap;

/// Environment for fast lookup of component libraries.
class KProgramEnv {
  final Set<ir.Component> _components = {};

  late final Map<Uri, KLibraryEnv> _libraryMap = {
    for (final component in _components)
      for (final library in component.libraries)
        library.importUri: KLibraryEnv(library),
  };

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member? get mainMethod => mainComponent.mainMethod;

  ir.Component get mainComponent => _components.first;

  void addComponent(ir.Component component) {
    if (_components.add(component)) {
      for (ir.Library library in component.libraries) {
        _libraryMap[library.importUri] ??= KLibraryEnv(library);
      }
    }
  }

  /// Return the [KLibraryEnv] for the library with the canonical [uri].
  KLibraryEnv? lookupLibrary(Uri uri) => _libraryMap[uri];

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(KLibraryEnv library)) {
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length => _libraryMap.length;

  /// Convert this [KProgramEnv] to the corresponding [JProgramEnv].
  JProgramEnv convert() => JProgramEnv(_components);
}

/// Environment for fast lookup of library classes and members.
class KLibraryEnv {
  final ir.Library library;

  late final Map<String, KClassEnv> _classMap = {
    for (ir.Class cls in library.classes) cls.name: KClassEnv(cls),
  };

  Map<String, ir.Member>? _memberMap;
  Map<String, ir.Member>? _setterMap;

  KLibraryEnv(this.library);

  /// Return the [KClassEnv] for the class [name] in [library].
  KClassEnv? lookupClass(String name) => _classMap[name];

  /// Calls [f] for each class in this library.
  void forEachClass(void f(KClassEnv cls)) {
    _classMap.values.forEach(f);
  }

  void _ensureMemberMaps() {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      _setterMap = <String, ir.Member>{};
      for (ir.Member member in library.members) {
        if (member is ir.Procedure) {
          if (member.kind == ir.ProcedureKind.Setter) {
            _setterMap![member.name.text] = member;
          } else {
            _memberMap![member.name.text] = member;
          }
        } else if (member is ir.Field) {
          _memberMap![member.name.text] = member;
          if (member.hasSetter) {
            _setterMap![member.name.text] = member;
          }
        } else {
          failedAt(
              NO_LOCATION_SPANNABLE, "Unexpected library member node: $member");
        }
      }
    }
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member? lookupMember(String name, {bool setter = false}) {
    _ensureMemberMaps();
    return setter ? _setterMap![name] : _memberMap![name];
  }

  void forEachMember(void f(ir.Member member)) {
    _ensureMemberMaps();
    _memberMap!.values.forEach(f);
    for (ir.Member member in _setterMap!.values) {
      if (member is ir.Procedure) {
        f(member);
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }

  /// Convert this [KLibraryEnv] to a corresponding [JLibraryEnv] containing
  /// only the members in [liveMembers].
  JLibraryEnv convert(IrToElementMap kElementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage) {
    Map<String, ir.Member> memberMap;
    Map<String, ir.Member> setterMap;
    if (_memberMap == null) {
      memberMap = const <String, ir.Member>{};
    } else {
      memberMap = <String, ir.Member>{};
      _memberMap!.forEach((String name, ir.Member node) {
        MemberEntity member = kElementMap.getMember(node);
        if (liveMemberUsage.containsKey(member)) {
          memberMap[name] = node;
        }
      });
    }
    if (_setterMap == null) {
      setterMap = const <String, ir.Member>{};
    } else {
      setterMap = <String, ir.Member>{};
      _setterMap!.forEach((String name, ir.Member node) {
        MemberEntity member = kElementMap.getMember(node);
        if (liveMemberUsage.containsKey(member)) {
          setterMap[name] = node;
        }
      });
    }
    return JLibraryEnv(library, memberMap, setterMap);
  }
}

class KLibraryData {
  final ir.Library library;
  Iterable<ConstantValue>? _metadata;
  // TODO(johnniwinther): Avoid direct access to [imports].
  Map<ir.LibraryDependency, ImportEntity>? imports;

  KLibraryData(this.library);

  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap) {
    return _metadata ??= elementMap.getMetadata(
        ir.StaticTypeContext.forAnnotations(
            library, elementMap.typeEnvironment),
        library.annotations);
  }

  Iterable<ImportEntity> getImports(KernelToElementMap elementMap) {
    if (imports == null) {
      List<ir.LibraryDependency> dependencies = library.dependencies;
      if (dependencies.isEmpty) {
        imports = const <ir.LibraryDependency, ImportEntity>{};
      } else {
        imports = <ir.LibraryDependency, ImportEntity>{};
        dependencies.forEach((ir.LibraryDependency node) {
          if (node.isExport) return;
          imports![node] = ImportEntity(
              node.isDeferred,
              node.name,
              node.targetLibrary.importUri,
              elementMap.getLibrary(node.enclosingLibrary).canonicalUri);
        });
      }
    }
    return imports!.values;
  }

  /// Convert this [KLibraryData] to the corresponding [JLibraryData].
  // TODO(johnniwinther): Why isn't [imports] ensured to be non-null here?
  JLibraryData convert() {
    return JLibraryData(library, imports ?? const {});
  }
}

int orderByFileOffset(ir.TreeNode a, ir.TreeNode b) {
  var aLoc = a.location!;
  var bLoc = b.location!;
  var aUri = '${aLoc.file}';
  var bUri = '${bLoc.file}';
  var uriCompare = aUri.compareTo(bUri);
  if (uriCompare != 0) return uriCompare;
  return a.fileOffset.compareTo(b.fileOffset);
}

/// Environment for fast lookup of class members.
class KClassEnv {
  final ir.Class cls;

  Map<String, ir.Member>? _constructorMap;
  Map<Name, ir.Member>? _memberMap;
  List<ir.Member>? _members; // in declaration order.
  bool? _isMixinApplicationWithMembers;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity>? _constructorBodyList;

  KClassEnv(this.cls);

  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  bool get isMixinApplicationWithMembers => _isMixinApplicationWithMembers!;

  bool checkHasMember(ir.Member node) {
    if (_memberMap == null) return false;
    return _memberMap!.values.contains(node) ||
        _constructorMap!.values.contains(node);
  }

  void ensureMembers(KernelToElementMap elementMap) {
    _ensureMaps(elementMap);
  }

  void _ensureMaps(KernelToElementMap elementMap) {
    if (_memberMap != null) return;

    _memberMap = <Name, ir.Member>{};
    _constructorMap = <String, ir.Member>{};
    var members = <ir.Member>[];
    _isMixinApplicationWithMembers = false;

    void addField(ir.Field member, {required bool includeStatic}) {
      if (!includeStatic && member.isStatic) return;
      var name = elementMap.getName(member.name);
      _memberMap![name] = member;
      if (member.hasSetter) {
        _memberMap![name.setter] = member;
      }
      members.add(member);
    }

    void addProcedure(ir.Procedure member,
        {required bool includeStatic,
        required bool includeNoSuchMethodForwarders,
        bool isFromMixinApplication = false}) {
      if (memberIsIgnorable(member, cls: cls)) return;
      if (!includeStatic && member.isStatic) return;
      if (member.isNoSuchMethodForwarder) {
        if (!includeNoSuchMethodForwarders) {
          return;
        }
      }
      if (member.kind == ir.ProcedureKind.Factory) {
        if (member.isRedirectingFactory) {
          // Don't include redirecting factories.
          return;
        }
        _constructorMap![member.name.text] = member;
      } else {
        var name = elementMap.getName(member.name, setter: member.isSetter);
        _memberMap![name] = member;
        members.add(member);
        if (isFromMixinApplication) {
          _isMixinApplicationWithMembers = true;
        }
      }
    }

    void addConstructors(ir.Class c) {
      for (ir.Constructor member in c.constructors) {
        var name = member.name.text;
        _constructorMap![name] = member;
      }
    }

    int mixinMemberCount = 0;

    if (cls.mixedInClass != null) {
      for (ir.Field field in cls.mixedInClass!.mixin.fields) {
        if (field.containsSuperCalls) {
          _isMixinApplicationWithMembers = true;
          continue;
        }
        addField(field, includeStatic: false);
      }
      for (ir.Procedure procedure in cls.mixedInClass!.mixin.procedures) {
        if (procedure.containsSuperCalls) {
          _isMixinApplicationWithMembers = true;
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
          includeStatic: true,
          includeNoSuchMethodForwarders: true,
          isFromMixinApplication: cls.mixedInClass != null);
    }

    mergeSort(members, start: mixinMemberCount, compare: orderByFileOffset);
    _members = members;
  }

  MemberEntity? lookupMember(
      covariant KernelToElementMap elementMap, Name name) {
    _ensureMaps(elementMap);
    ir.Member? member = _memberMap![name];
    return member != null ? elementMap.getMember(member) : null;
  }

  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _ensureMaps(elementMap as KernelToElementMap);
    _members!.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  ConstructorEntity? lookupConstructor(
      IrToElementMap elementMap, String? name) {
    _ensureMaps(elementMap as KernelToElementMap);
    ir.Member? constructor = _constructorMap![name!];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
    _ensureMaps(elementMap as KernelToElementMap);
    _constructorMap!.values.forEach((ir.Member constructor) {
      f(elementMap.getConstructor(constructor));
    });
  }

  void addConstructorBody(ConstructorBodyEntity constructorBody) {
    _constructorBodyList ??= <ConstructorBodyEntity>[];
    _constructorBodyList!.add(constructorBody);
  }

  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    _constructorBodyList?.forEach(f);
  }

  JClassEnv convert(
      IrToElementMap kElementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage,
      Iterable<MemberEntity> liveAbstractMembers,
      LibraryEntity Function(ir.Library library) getJLibrary) {
    Map<String, ir.Member> constructorMap;
    Map<Name, ir.Member> memberMap;
    List<ir.Member> members;
    if (_constructorMap == null) {
      constructorMap = const <String, ir.Member>{};
    } else {
      constructorMap = <String, ir.Member>{};
      _constructorMap!.forEach((String name, ir.Member node) {
        MemberEntity member = kElementMap.getMember(node);
        if (liveMemberUsage.containsKey(member) ||
            liveAbstractMembers.contains(member)) {
          constructorMap[name] = node;
        }
      });
    }
    if (_memberMap == null) {
      memberMap = const <Name, ir.Member>{};
    } else {
      memberMap = <Name, ir.Member>{};
      _memberMap!.forEach((Name name, ir.Member node) {
        MemberEntity member = kElementMap.getMember(node);
        if (liveMemberUsage.containsKey(member) ||
            liveAbstractMembers.contains(member)) {
          memberMap[name] = node;
        }
      });
    }
    if (_members == null) {
      members = const <ir.Member>[];
    } else {
      members = <ir.Member>[];
      _members!.forEach((ir.Member node) {
        MemberEntity member = kElementMap.getMember(node);
        if (liveMemberUsage.containsKey(member) ||
            liveAbstractMembers.contains(member)) {
          members.add(node);
        }
      });
    }
    return JClassEnvImpl(cls, constructorMap, memberMap, members,
        _isMixinApplicationWithMembers ?? false);
  }
}

class KClassData {
  final ir.Class node;
  late bool isMixinApplication;

  InterfaceType? thisType;
  InterfaceType? jsInteropType;
  InterfaceType? rawType;
  InterfaceType? instantiationToBounds;
  InterfaceType? supertype;
  InterfaceType? mixedInType;
  List<InterfaceType>? interfaces;
  OrderedTypeSet? orderedTypeSet;

  Iterable<ConstantValue>? _metadata;
  List<Variance>? _variances;

  KClassData(this.node);

  bool get isEnumClass => node.isEnum;

  FunctionType? callType;
  bool isCallTypeComputed = false;

  Iterable<ConstantValue> getMetadata(covariant KernelToElementMap elementMap) {
    return _metadata ??= elementMap.getMetadata(
        ir.StaticTypeContext.forAnnotations(
            node.enclosingLibrary, elementMap.typeEnvironment),
        node.annotations);
  }

  List<Variance> getVariances() =>
      _variances ??= node.typeParameters.map(convertVariance).toList();

  JClassData convert() {
    return JClassDataImpl(node, RegularClassDefinition(node));
  }
}

abstract class KMemberData {
  final ir.Member node;

  Iterable<ConstantValue>? _metadata;

  StaticTypeCache? staticTypes;

  ClassTypeVariableAccess get classTypeVariableAccess;

  KMemberData(this.node);

  Iterable<ConstantValue> getMetadata(covariant KernelToElementMap elementMap) {
    return _metadata ??= elementMap.getMetadata(
        ir.StaticTypeContext(node, elementMap.typeEnvironment),
        node.annotations);
  }

  InterfaceType? getMemberThisType(JsToElementMap elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity? cls = member.enclosingClass;
    if (cls != null) {
      return elementMap.elementEnvironment.getThisType(cls);
    }
    return null;
  }

  /// Convert this [KMemberData] to the corresponding [JMemberData].
  JMemberData convert();
}

class KFunctionData extends KMemberData {
  final ir.FunctionNode functionNode;
  FunctionType? _type;
  List<TypeVariableType>? _typeVariables;

  KFunctionData(super.node, this.functionNode);

  FunctionType getFunctionType(covariant KernelToElementMap elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String? name, ConstantValue? defaultValue)) {
    void handleParameter(ir.VariableDeclaration parameter,
        {bool isOptional = true}) {
      DartType type = elementMap.getDartType(parameter.type);
      String? name = parameter.name;
      ConstantValue? defaultValue;
      if (isOptional) {
        if (parameter.initializer != null) {
          defaultValue =
              elementMap.getConstantValue(node, parameter.initializer);
        } else {
          defaultValue = NullConstantValue();
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

  List<TypeVariableType> getFunctionTypeVariables(
      covariant KernelToElementMap elementMap) {
    if (_typeVariables == null) {
      if (functionNode.typeParameters.isEmpty) {
        _typeVariables = const <TypeVariableType>[];
      } else {
        ir.TreeNode? parent = functionNode.parent;
        if (parent is ir.Constructor ||
            (parent is ir.Procedure &&
                parent.kind == ir.ProcedureKind.Factory)) {
          _typeVariables = const <TypeVariableType>[];
        } else {
          _typeVariables = functionNode.typeParameters
              .map<TypeVariableType>((ir.TypeParameter typeParameter) {
            return elementMap
                .getDartType(ir.TypeParameterType(
                    typeParameter, ir.Nullability.nonNullable))
                .withoutNullability as TypeVariableType;
          }).toList();
        }
      }
    }
    return _typeVariables!;
  }

  @override
  FunctionData convert() {
    return FunctionDataImpl(
        node,
        functionNode,
        RegularMemberDefinition(node),
        // Abstract members without bodies will not have expressions so we use
        // an empty cache.
        staticTypes ?? const StaticTypeCache());
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

class KConstructorData extends KFunctionData {
  ConstructorBodyEntity? constructorBody;

  KConstructorData(super.node, super.functionNode);

  @override
  JConstructorData convert() {
    MemberDefinition definition;
    if (node is ir.Constructor) {
      definition = SpecialMemberDefinition(node, MemberKind.constructor);
    } else {
      definition = RegularMemberDefinition(node);
    }
    return JConstructorData(node, functionNode, definition, staticTypes!);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

class KFieldData extends KMemberData {
  DartType? _type;

  final bool isLateBackingField;

  final bool isLateFinalBackingField;

  KFieldData(super.node,
      {required this.isLateBackingField,
      required this.isLateFinalBackingField});

  @override
  ir.Field get node => super.node as ir.Field;

  DartType getFieldType(covariant KernelToElementMap elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.instanceField;
    return ClassTypeVariableAccess.none;
  }

  @override
  JFieldData convert() {
    return JFieldDataImpl(
        node,
        RegularMemberDefinition(node),
        // Late fields in abstract classes won't have initializers so we use an
        // empty cache.
        staticTypes ?? const StaticTypeCache());
  }
}

class KTypeVariableData {
  final ir.TypeParameter node;
  DartType? _bound;
  DartType? _defaultType;

  KTypeVariableData(this.node);

  DartType getBound(IrToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  DartType getDefaultType(IrToElementMap elementMap) {
    return _defaultType ??= elementMap.getDartType(node.defaultType);
  }

  JTypeVariableData copy() {
    return JTypeVariableData(node);
  }
}
