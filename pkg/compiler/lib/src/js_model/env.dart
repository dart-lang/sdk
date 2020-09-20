// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.env;

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/static_type_cache.dart';
import '../ir/util.dart';
import '../js_model/element_map.dart';
import '../ordered_typeset.dart';
import '../serialization/serialization.dart';
import '../ssa/type_builder.dart';
import 'closure.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'elements.dart';

/// Environment for fast lookup of component libraries.
class JProgramEnv {
  final Iterable<ir.Component> _components;
  final Map<Uri, JLibraryEnv> _libraryMap = {};

  JProgramEnv(this._components);

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member get mainMethod => _components.first?.mainMethod;

  ir.Component get mainComponent => _components.first;

  void registerLibrary(JLibraryEnv env) {
    _libraryMap[env.library.importUri] = env;
  }

  /// Return the [JLibraryEnv] for the library with the canonical [uri].
  JLibraryEnv lookupLibrary(Uri uri) {
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(JLibraryEnv library)) {
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length {
    return _libraryMap.length;
  }
}

/// Environment for fast lookup of library classes and members.
class JLibraryEnv {
  /// Tag used for identifying serialized [JLibraryEnv] objects in a
  /// debugging data stream.
  static const String tag = 'library-env';

  final ir.Library library;
  final Map<String, JClassEnv> _classMap = {};
  final Map<String, ir.Member> _memberMap;
  final Map<String, ir.Member> _setterMap;

  JLibraryEnv(this.library, this._memberMap, this._setterMap);

  /// Deserializes a [JLibraryEnv] object from [source].
  factory JLibraryEnv.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Library library = source.readLibraryNode();
    Map<String, ir.Member> memberMap =
        source.readStringMap(source.readMemberNode);
    Map<String, ir.Member> setterMap =
        source.readStringMap(source.readMemberNode);
    source.end(tag);
    return new JLibraryEnv(library, memberMap, setterMap);
  }

  /// Serializes this [JLibraryEnv] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeLibraryNode(library);
    sink.writeStringMap(_memberMap, sink.writeMemberNode);
    sink.writeStringMap(_setterMap, sink.writeMemberNode);
    sink.end(tag);
  }

  void registerClass(String name, JClassEnv classEnv) {
    _classMap[name] = classEnv;
  }

  /// Return the [JClassEnv] for the class [name] in [library].
  JClassEnv lookupClass(String name) {
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(JClassEnv cls)) {
    _classMap.values.forEach(f);
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    return setter ? _setterMap[name] : _memberMap[name];
  }

  void forEachMember(void f(ir.Member member)) {
    _memberMap.values.forEach(f);
    for (ir.Member member in _setterMap.values) {
      if (member is ir.Procedure) {
        f(member);
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }
}

class JLibraryData {
  /// Tag used for identifying serialized [JLibraryData] objects in a
  /// debugging data stream.
  static const String tag = 'library-data';

  final ir.Library library;
  // TODO(johnniwinther): Avoid direct access to [imports]. It might be null if
  // it hasn't been computed for the corresponding [KLibraryData].
  final Map<ir.LibraryDependency, ImportEntity> imports;

  JLibraryData(this.library, this.imports);

  factory JLibraryData.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Library library = source.readLibraryNode();
    int importCount = source.readInt();
    Map<ir.LibraryDependency, ImportEntity> imports;
    if (importCount > 0) {
      imports = {};
      for (int i = 0; i < importCount; i++) {
        int index = source.readInt();
        ImportEntity import = source.readImport();
        imports[library.dependencies[index]] = import;
      }
    }
    source.end(tag);
    return new JLibraryData(library, imports);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeLibraryNode(library);
    if (imports == null) {
      sink.writeInt(0);
    } else {
      sink.writeInt(imports.length);
      int index = 0;
      for (ir.LibraryDependency node in library.dependencies) {
        ImportEntity import = imports[node];
        if (import != null) {
          sink.writeInt(index);
          sink.writeImport(import);
        }
        index++;
      }
    }
    sink.end(tag);
  }
}

/// Enum used for identifying [JClassEnv] subclasses in serialization.
enum JClassEnvKind { node, closure, record }

/// Member data for a class.
abstract class JClassEnv {
  /// Deserializes a [JClassEnv] object from [source].
  factory JClassEnv.readFromDataSource(DataSource source) {
    JClassEnvKind kind = source.readEnum(JClassEnvKind.values);
    switch (kind) {
      case JClassEnvKind.node:
        return new JClassEnvImpl.readFromDataSource(source);
      case JClassEnvKind.closure:
        return new ClosureClassEnv.readFromDataSource(source);
      case JClassEnvKind.record:
        return new RecordEnv.readFromDataSource(source);
    }
    throw new UnsupportedError("Unsupported JClassEnvKind $kind");
  }

  /// Serializes this [JClassEnv] to [sink].
  void writeToDataSink(DataSink sink);

  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Whether the class is a mixin application that mixes in methods with super
  /// calls.
  bool get isSuperMixinApplication;

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
}

/// Environment for fast lookup of class members.
class JClassEnvImpl implements JClassEnv {
  /// Tag used for identifying serialized [JClassEnv] objects in a
  /// debugging data stream.
  static const String tag = 'class-env';

  @override
  final ir.Class cls;
  final Map<String, ir.Member> _constructorMap;
  final Map<String, ir.Member> _memberMap;
  final Map<String, ir.Member> _setterMap;
  final List<ir.Member> _members; // in declaration order.
  @override
  final bool isSuperMixinApplication;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  JClassEnvImpl(this.cls, this._constructorMap, this._memberMap,
      this._setterMap, this._members, this.isSuperMixinApplication);

  factory JClassEnvImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Class cls = source.readClassNode();
    Map<String, ir.Member> constructorMap =
        source.readStringMap(source.readMemberNode);
    Map<String, ir.Member> memberMap =
        source.readStringMap(source.readMemberNode);
    Map<String, ir.Member> setterMap =
        source.readStringMap(source.readMemberNode);
    List<ir.Member> members = source.readMemberNodes();
    bool isSuperMixinApplication = source.readBool();
    source.end(tag);
    return new JClassEnvImpl(cls, constructorMap, memberMap, setterMap, members,
        isSuperMixinApplication);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassEnvKind.node);
    sink.begin(tag);
    sink.writeClassNode(cls);
    sink.writeStringMap(_constructorMap, sink.writeMemberNode);
    sink.writeStringMap(_memberMap, sink.writeMemberNode);
    sink.writeStringMap(_setterMap, sink.writeMemberNode);
    sink.writeMemberNodes(_members);
    sink.writeBool(isSuperMixinApplication);
    sink.end(tag);
  }

  @override
  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  @override
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  @override
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
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
}

class RecordEnv implements JClassEnv {
  /// Tag used for identifying serialized [RecordEnv] objects in a
  /// debugging data stream.
  static const String tag = 'record-env';

  final Map<String, IndexedMember> _memberMap;

  RecordEnv(this._memberMap);

  factory RecordEnv.readFromDataSource(DataSource source) {
    source.begin(tag);
    Map<String, IndexedMember> _memberMap =
        source.readStringMap(() => source.readMember());
    source.end(tag);
    return new RecordEnv(_memberMap);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassEnvKind.record);
    sink.begin(tag);
    sink.writeStringMap(
        _memberMap, (IndexedMember member) => sink.writeMember(member));
    sink.end(tag);
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
}

class ClosureClassEnv extends RecordEnv {
  /// Tag used for identifying serialized [ClosureClassEnv] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-env';

  ClosureClassEnv(Map<String, MemberEntity> memberMap) : super(memberMap);

  factory ClosureClassEnv.readFromDataSource(DataSource source) {
    source.begin(tag);
    Map<String, IndexedMember> _memberMap =
        source.readStringMap(() => source.readMember());
    source.end(tag);
    return new ClosureClassEnv(_memberMap);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassEnvKind.closure);
    sink.begin(tag);
    sink.writeStringMap(
        _memberMap, (IndexedMember member) => sink.writeMember(member));
    sink.end(tag);
  }

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    if (setter) {
      // All closure fields are final.
      return null;
    }
    return super.lookupMember(elementMap, name, setter: setter);
  }
}

/// Enum used for identifying [JClassData] subclasses in serialization.
enum JClassDataKind { node, closure, record }

abstract class JClassData {
  /// Deserializes a [JClassData] object from [source].
  factory JClassData.readFromDataSource(DataSource source) {
    JClassDataKind kind = source.readEnum(JClassDataKind.values);
    switch (kind) {
      case JClassDataKind.node:
        return new JClassDataImpl.readFromDataSource(source);
      case JClassDataKind.closure:
        return new ClosureClassData.readFromDataSource(source);
      case JClassDataKind.record:
        return new RecordClassData.readFromDataSource(source);
    }
    throw new UnsupportedError("Unexpected JClassDataKind $kind");
  }

  /// Serializes this [JClassData] to [sink].
  void writeToDataSink(DataSink sink);

  ClassDefinition get definition;

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

  List<Variance> getVariances();
}

class JClassDataImpl implements JClassData {
  /// Tag used for identifying serialized [JClassDataImpl] objects in a
  /// debugging data stream.
  static const String tag = 'class-data';

  final ir.Class cls;
  @override
  final ClassDefinition definition;
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

  List<Variance> _variances;

  JClassDataImpl(this.cls, this.definition);

  factory JClassDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Class cls = source.readClassNode();
    ClassDefinition definition = new ClassDefinition.readFromDataSource(source);
    source.end(tag);
    return new JClassDataImpl(cls, definition);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassDataKind.node);
    sink.begin(tag);
    sink.writeClassNode(cls);
    definition.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  bool get isEnumClass => cls != null && cls.isEnum;

  @override
  DartType get callType => null;

  @override
  List<Variance> getVariances() =>
      _variances ??= cls.typeParameters.map(convertVariance).toList();
}

/// Enum used for identifying [JMemberData] subclasses in serialization.
enum JMemberDataKind {
  function,
  field,
  constructor,
  constructorBody,
  signature,
  generatorBody,
  closureFunction,
  closureField,
}

abstract class JMemberData {
  MemberDefinition get definition;

  InterfaceType getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;

  StaticTypeCache get staticTypes;

  JMemberData();

  /// Deserializes a [JMemberData] object from [source].
  factory JMemberData.readFromDataSource(DataSource source) {
    JMemberDataKind kind = source.readEnum(JMemberDataKind.values);
    switch (kind) {
      case JMemberDataKind.function:
        return new FunctionDataImpl.readFromDataSource(source);
      case JMemberDataKind.field:
        return new JFieldDataImpl.readFromDataSource(source);
      case JMemberDataKind.constructor:
        return new JConstructorDataImpl.readFromDataSource(source);
      case JMemberDataKind.constructorBody:
        return new ConstructorBodyDataImpl.readFromDataSource(source);
      case JMemberDataKind.signature:
        return new SignatureFunctionData.readFromDataSource(source);
      case JMemberDataKind.generatorBody:
        return new GeneratorBodyFunctionData.readFromDataSource(source);
      case JMemberDataKind.closureFunction:
        return new ClosureFunctionData.readFromDataSource(source);
      case JMemberDataKind.closureField:
        return new ClosureFieldData.readFromDataSource(source);
    }
    throw new UnsupportedError("Unexpected JMemberDataKind $kind");
  }

  /// Serializes this [JMemberData] to [sink].
  void writeToDataSink(DataSink sink);
}

abstract class JMemberDataImpl implements JMemberData {
  final ir.Member node;

  @override
  final MemberDefinition definition;

  @override
  final StaticTypeCache staticTypes;

  JMemberDataImpl(this.node, this.definition, this.staticTypes);

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

abstract class FunctionData implements JMemberData {
  FunctionType getFunctionType(IrToElementMap elementMap);

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap);

  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false});
}

abstract class FunctionDataTypeVariablesMixin implements FunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType> _typeVariables;

  @override
  List<TypeVariableType> getFunctionTypeVariables(
      covariant JsKernelToElementMap elementMap) {
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

abstract class FunctionDataForEachParameterMixin implements FunctionData {
  ir.FunctionNode get functionNode;

  // TODO(johnniwinther,sigmund): Remove this when it's no longer needed for
  //  `getConstantValue` in [forEachParameter].
  ir.Member get memberContext;

  @override
  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false}) {
    void handleParameter(ir.VariableDeclaration parameter,
        {bool isOptional: true}) {
      DartType type = elementMap.getDartType(parameter.type);
      String name = parameter.name;
      ConstantValue defaultValue;
      if (parameter.isRequired) {
        if (elementMap.types.useLegacySubtyping) {
          defaultValue = NullConstantValue();
        } else {
          defaultValue = elementMap.getRequiredSentinelConstantValue();
        }
      } else if (isOptional) {
        if (parameter.initializer != null) {
          defaultValue =
              elementMap.getConstantValue(memberContext, parameter.initializer);
        } else {
          defaultValue = NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    forEachOrderedParameterByFunctionNode(functionNode, parameterStructure,
        (ir.VariableDeclaration parameter, {bool isOptional, bool isElided}) {
      if (!isElided) {
        handleParameter(parameter, isOptional: isOptional);
      }
    }, useNativeOrdering: isNative);
  }
}

class FunctionDataImpl extends JMemberDataImpl
    with FunctionDataTypeVariablesMixin, FunctionDataForEachParameterMixin
    implements FunctionData {
  /// Tag used for identifying serialized [FunctionDataImpl] objects in a
  /// debugging data stream.
  static const String tag = 'function-data';

  @override
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionDataImpl(ir.Member node, this.functionNode,
      MemberDefinition definition, StaticTypeCache staticTypes)
      : super(node, definition, staticTypes);

  factory FunctionDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw new UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    StaticTypeCache staticTypes =
        new StaticTypeCache.readFromDataSource(source, node);
    source.end(tag);
    return new FunctionDataImpl(node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.function);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    staticTypes.writeToDataSink(sink, node);
    sink.end(tag);
  }

  @override
  ir.Member get memberContext => node;

  @override
  FunctionType getFunctionType(covariant JsKernelToElementMap elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

class SignatureFunctionData implements FunctionData {
  /// Tag used for identifying serialized [SignatureFunctionData] objects in a
  /// debugging data stream.
  static const String tag = 'signature-function-data';

  @override
  final MemberDefinition definition;
  final InterfaceType memberThisType;
  @override
  final ClassTypeVariableAccess classTypeVariableAccess;
  final List<ir.TypeParameter> typeParameters;

  SignatureFunctionData(this.definition, this.memberThisType,
      this.typeParameters, this.classTypeVariableAccess);

  factory SignatureFunctionData.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    InterfaceType memberThisType = source.readDartType(allowNull: true);
    List<ir.TypeParameter> typeParameters = source.readTypeParameterNodes();
    ClassTypeVariableAccess classTypeVariableAccess =
        source.readEnum(ClassTypeVariableAccess.values);
    source.end(tag);
    return new SignatureFunctionData(
        definition, memberThisType, typeParameters, classTypeVariableAccess);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.signature);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(memberThisType, allowNull: true);
    sink.writeTypeParameterNodes(typeParameters);
    sink.writeEnum(classTypeVariableAccess);
    sink.end(tag);
  }

  @override
  StaticTypeCache get staticTypes => const StaticTypeCache();

  @override
  FunctionType getFunctionType(covariant JsKernelToElementMap elementMap) {
    throw new UnsupportedError("SignatureFunctionData.getFunctionType");
  }

  @override
  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return typeParameters
        .map<TypeVariableType>((ir.TypeParameter typeParameter) {
      return elementMap
          .getDartType(new ir.TypeParameterType(
              typeParameter, ir.Nullability.nonNullable))
          .withoutNullability;
    }).toList();
  }

  @override
  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false}) {
    throw new UnimplementedError('SignatureData.forEachParameter');
  }

  @override
  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return memberThisType;
  }
}

abstract class DelegatedFunctionData implements FunctionData {
  final FunctionData baseData;

  DelegatedFunctionData(this.baseData);

  @override
  FunctionType getFunctionType(covariant JsKernelToElementMap elementMap) {
    return baseData.getFunctionType(elementMap);
  }

  @override
  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return baseData.getFunctionTypeVariables(elementMap);
  }

  @override
  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false}) {
    return baseData.forEachParameter(elementMap, parameterStructure, f,
        isNative: isNative);
  }

  @override
  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return baseData.getMemberThisType(elementMap);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      baseData.classTypeVariableAccess;
}

class GeneratorBodyFunctionData extends DelegatedFunctionData {
  /// Tag used for identifying serialized [GeneratorBodyFunctionData] objects in
  /// a debugging data stream.
  static const String tag = 'generator-body-data';

  @override
  final MemberDefinition definition;

  GeneratorBodyFunctionData(FunctionData baseData, this.definition)
      : super(baseData);

  factory GeneratorBodyFunctionData.readFromDataSource(DataSource source) {
    source.begin(tag);
    // TODO(johnniwinther): Share the original base data on deserialization.
    FunctionData baseData = new JMemberData.readFromDataSource(source);
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    source.end(tag);
    return new GeneratorBodyFunctionData(baseData, definition);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.generatorBody);
    sink.begin(tag);
    baseData.writeToDataSink(sink);
    definition.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  StaticTypeCache get staticTypes => const StaticTypeCache();
}

abstract class JConstructorData extends FunctionData {}

class JConstructorDataImpl extends FunctionDataImpl
    implements JConstructorData {
  /// Tag used for identifying serialized [JConstructorDataImpl] objects in a
  /// debugging data stream.
  static const String tag = 'constructor-data';

  JConstructorBody constructorBody;

  JConstructorDataImpl(ir.Member node, ir.FunctionNode functionNode,
      MemberDefinition definition, StaticTypeCache staticTypes)
      : super(node, functionNode, definition, staticTypes);

  factory JConstructorDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw new UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    StaticTypeCache staticTypes =
        new StaticTypeCache.readFromDataSource(source, node);
    source.end(tag);
    return new JConstructorDataImpl(
        node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.constructor);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    assert(constructorBody == null);
    staticTypes.writeToDataSink(sink, node);
    sink.end(tag);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

class ConstructorBodyDataImpl extends FunctionDataImpl {
  /// Tag used for identifying serialized [ConstructorBodyDataImpl] objects in
  /// a debugging data stream.
  static const String tag = 'constructor-body-data';

  ConstructorBodyDataImpl(ir.Member node, ir.FunctionNode functionNode,
      MemberDefinition definition, StaticTypeCache staticTypes)
      : super(node, functionNode, definition, staticTypes);

  factory ConstructorBodyDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw new UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    StaticTypeCache staticTypes =
        new StaticTypeCache.readFromDataSource(source, node);
    source.end(tag);
    return new ConstructorBodyDataImpl(
        node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.constructorBody);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    staticTypes.writeToDataSink(sink, node);
    sink.end(tag);
  }

  // TODO(johnniwinther,sra): Constructor bodies should access type variables
  // through `this`.
  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

abstract class JFieldData extends JMemberData {
  DartType getFieldType(IrToElementMap elementMap);
}

class JFieldDataImpl extends JMemberDataImpl implements JFieldData {
  /// Tag used for identifying serialized [JFieldDataImpl] objects in
  /// a debugging data stream.
  static const String tag = 'field-data';

  DartType _type;

  JFieldDataImpl(
      ir.Field node, MemberDefinition definition, StaticTypeCache staticTypes)
      : super(node, definition, staticTypes);

  factory JFieldDataImpl.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    StaticTypeCache staticTypes =
        new StaticTypeCache.readFromDataSource(source, node);
    source.end(tag);
    return new JFieldDataImpl(node, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.field);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    staticTypes.writeToDataSink(sink, node);
    sink.end(tag);
  }

  @override
  ir.Field get node => super.node;

  @override
  DartType getFieldType(covariant JsKernelToElementMap elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.instanceField;
    return ClassTypeVariableAccess.none;
  }
}

class JTypeVariableData {
  /// Tag used for identifying serialized [JTypeVariableData] objects in
  /// a debugging data stream.
  static const String tag = 'type-variable-data';

  final ir.TypeParameter node;
  DartType _bound;
  DartType _defaultType;

  JTypeVariableData(this.node);

  factory JTypeVariableData.readFromDataSource(DataSource source) {
    source.begin(tag);
    ir.TypeParameter node = source.readTypeParameterNode();
    source.end(tag);
    return new JTypeVariableData(node);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeTypeParameterNode(node);
    sink.end(tag);
  }

  DartType getBound(IrToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  DartType getDefaultType(IrToElementMap elementMap) {
    return _defaultType ??= elementMap.getDartType(node.defaultType);
  }
}
