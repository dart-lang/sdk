// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.env;

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/static_type_cache.dart';
import '../ir/util.dart';
import '../js_model/class_type_variable_access.dart';
import '../ordered_typeset.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
import 'closure.dart'
    show
        ClosureClassData,
        ContextClassData,
        ClosureFunctionData,
        ClosureFieldData;
import 'element_map.dart'
    show
        JsToElementMap,
        ClassDefinition,
        MemberDefinition,
        forEachOrderedParameterByFunctionNode;
import 'element_map_impl.dart';
import 'elements.dart';
import 'records.dart' show RecordClassData, RecordGetterData;

/// Environment for fast lookup of component libraries.
class JProgramEnv {
  final Iterable<ir.Component> _components;
  final Map<Uri, JLibraryEnv> _libraryMap = {};

  JProgramEnv(this._components);

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member? get mainMethod => _components.first.mainMethod;

  ir.Component get mainComponent => _components.first;

  void registerLibrary(JLibraryEnv env) {
    _libraryMap[env.library.importUri] = env;
  }

  /// Return the [JLibraryEnv] for the library with the canonical [uri].
  JLibraryEnv? lookupLibrary(Uri uri) {
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
  factory JLibraryEnv.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Library library = source.readLibraryNode();
    Map<String, ir.Member> memberMap =
        source.readStringMap(source.readMemberNode)!;
    Map<String, ir.Member> setterMap =
        source.readStringMap(source.readMemberNode)!;
    source.end(tag);
    return JLibraryEnv(library, memberMap, setterMap);
  }

  /// Serializes this [JLibraryEnv] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
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
  JClassEnv? lookupClass(String name) {
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(JClassEnv cls)) {
    _classMap.values.forEach(f);
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member? lookupMember(String name, {bool setter = false}) {
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

  factory JLibraryData.readFromDataSource(DataSourceReader source) {
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
    } else {
      imports = const {};
    }
    source.end(tag);
    return JLibraryData(library, imports);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeLibraryNode(library);
    sink.writeInt(imports.length);
    int index = 0;
    for (ir.LibraryDependency node in library.dependencies) {
      ImportEntity? import = imports[node];
      if (import != null) {
        sink.writeInt(index);
        sink.writeImport(import);
      }
      index++;
    }
    sink.end(tag);
  }
}

/// Enum used for identifying [JClassEnv] subclasses in serialization.
enum JClassEnvKind { node, closure, context, record }

/// Member data for a class.
abstract class JClassEnv {
  /// Deserializes a [JClassEnv] object from [source].
  factory JClassEnv.readFromDataSource(DataSourceReader source) {
    JClassEnvKind kind = source.readEnum(JClassEnvKind.values);
    switch (kind) {
      case JClassEnvKind.node:
        return JClassEnvImpl.readFromDataSource(source);
      case JClassEnvKind.closure:
        return ClosureClassEnv.readFromDataSource(source);
      case JClassEnvKind.context:
        return ContextEnv.readFromDataSource(source);
      case JClassEnvKind.record:
        return RecordClassEnv.readFromDataSource(source);
    }
  }

  /// Serializes this [JClassEnv] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  /// The [ir.Class] that defined the class, if any.
  ir.Class? get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Whether the class is a mixin application with its own members.
  ///
  /// This occurs when a mixin contains methods with super calls or when
  /// the mixin application contains concrete forwarding stubs.
  bool get isMixinApplicationWithMembers;

  /// Return the [MemberEntity] for the member [name] in the class. If [setter]
  /// is `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity? lookupMember(IrToElementMap elementMap, Name name);

  /// Calls [f] for each member of [cls].
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity? lookupConstructor(IrToElementMap elementMap, String name);

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
  final Map<Name, ir.Member> _memberMap;
  final List<ir.Member> _members; // in declaration order.
  @override
  final bool isMixinApplicationWithMembers;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity>? _constructorBodyList;

  JClassEnvImpl(this.cls, this._constructorMap, this._memberMap, this._members,
      this.isMixinApplicationWithMembers);

  factory JClassEnvImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Class cls = source.readClassNode();
    Map<String, ir.Member> constructorMap =
        source.readStringMap(source.readMemberNode)!;
    Map<Name, ir.Member> memberMap = source.readNameMap(source.readMemberNode)!;
    List<ir.Member> members = source.readMemberNodes();
    bool isSuperMixinApplication = source.readBool();
    source.end(tag);
    return JClassEnvImpl(
        cls, constructorMap, memberMap, members, isSuperMixinApplication);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassEnvKind.node);
    sink.begin(tag);
    sink.writeClassNode(cls);
    sink.writeStringMap(_constructorMap, sink.writeMemberNode);
    sink.writeNameMap(_memberMap, sink.writeMemberNode);
    sink.writeMemberNodes(_members);
    sink.writeBool(isMixinApplicationWithMembers);
    sink.end(tag);
  }

  @override
  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  @override
  MemberEntity? lookupMember(IrToElementMap elementMap, Name name) {
    ir.Member? member = _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  @override
  ConstructorEntity? lookupConstructor(IrToElementMap elementMap, String name) {
    ir.Member? constructor = _constructorMap[name];
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
    (_constructorBodyList ??= <ConstructorBodyEntity>[]).add(constructorBody);
  }

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    _constructorBodyList?.forEach(f);
  }
}

class ContextEnv implements JClassEnv {
  /// Tag used for identifying serialized [ContextEnv] objects in a debugging
  /// data stream.
  static const String tag = 'context-env';

  final Map<Name, IndexedMember> _memberMap;

  ContextEnv(this._memberMap);

  factory ContextEnv.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Map<Name, IndexedMember> _memberMap =
        source.readNameMap(() => source.readMember() as IndexedMember)!;
    source.end(tag);
    return ContextEnv(_memberMap);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassEnvKind.context);
    sink.begin(tag);
    sink.writeNameMap(
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
  ConstructorEntity? lookupConstructor(IrToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity? lookupMember(IrToElementMap elementMap, Name name) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  bool get isMixinApplicationWithMembers => false;

  @override
  ir.Class? get cls => null;
}

class ClosureClassEnv extends ContextEnv {
  /// Tag used for identifying serialized [ClosureClassEnv] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-env';

  ClosureClassEnv(super.memberMap);

  factory ClosureClassEnv.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Map<Name, IndexedMember> _memberMap =
        source.readNameMap(() => source.readMember() as IndexedMember)!;
    source.end(tag);
    return ClosureClassEnv(_memberMap);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassEnvKind.closure);
    sink.begin(tag);
    sink.writeNameMap(
        _memberMap, (IndexedMember member) => sink.writeMember(member));
    sink.end(tag);
  }
}

class RecordClassEnv implements JClassEnv {
  /// Tag used for identifying serialized [ContextEnv] objects in a debugging
  /// data stream.
  static const String tag = 'record-env';

  final Map<Name, IndexedMember> _memberMap;

  RecordClassEnv(this._memberMap);

  factory RecordClassEnv.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Map<Name, IndexedMember> _memberMap =
        source.readNameMap(() => source.readMember() as IndexedMember)!;
    source.end(tag);
    return RecordClassEnv(_memberMap);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassEnvKind.record);
    sink.begin(tag);
    sink.writeNameMap(
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
  ConstructorEntity? lookupConstructor(IrToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity? lookupMember(IrToElementMap elementMap, Name name) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  bool get isMixinApplicationWithMembers => false;

  @override
  ir.Class? get cls => null;
}

/// Enum used for identifying [JClassData] subclasses in serialization.
enum JClassDataKind { node, closure, context, record }

abstract class JClassData {
  /// Deserializes a [JClassData] object from [source].
  factory JClassData.readFromDataSource(DataSourceReader source) {
    JClassDataKind kind = source.readEnum(JClassDataKind.values);
    switch (kind) {
      case JClassDataKind.node:
        return JClassDataImpl.readFromDataSource(source);
      case JClassDataKind.closure:
        return ClosureClassData.readFromDataSource(source);
      case JClassDataKind.context:
        return ContextClassData.readFromDataSource(source);
      case JClassDataKind.record:
        return RecordClassData.readFromDataSource(source);
    }
  }

  /// Serializes this [JClassData] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  ClassDefinition get definition;

  InterfaceType? get thisType;
  InterfaceType? get jsInteropType;
  InterfaceType? get rawType;
  InterfaceType? get instantiationToBounds;
  InterfaceType? get supertype;
  InterfaceType? get mixedInType;
  List<InterfaceType> get interfaces;
  OrderedTypeSet? get orderedTypeSet;
  FunctionType? get callType;

  bool get isEnumClass;
  bool? get isMixinApplication;

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
  bool? isMixinApplication;

  @override
  InterfaceType? thisType;
  @override
  InterfaceType? jsInteropType;
  @override
  InterfaceType? rawType;
  @override
  InterfaceType? instantiationToBounds;
  @override
  InterfaceType? supertype;
  @override
  InterfaceType? mixedInType;
  @override
  late List<InterfaceType> interfaces;
  @override
  OrderedTypeSet? orderedTypeSet;

  List<Variance>? _variances;

  JClassDataImpl(this.cls, this.definition);

  factory JClassDataImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Class cls = source.readClassNode();
    ClassDefinition definition = ClassDefinition.readFromDataSource(source);
    source.end(tag);
    return JClassDataImpl(cls, definition);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassDataKind.node);
    sink.begin(tag);
    sink.writeClassNode(cls);
    definition.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  bool get isEnumClass => cls.isEnum;

  @override
  FunctionType? callType;
  bool isCallTypeComputed = false;

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
  recordGetter,
}

abstract class JMemberData {
  MemberDefinition get definition;

  InterfaceType? getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;

  StaticTypeCache get staticTypes;

  JMemberData();

  /// Deserializes a [JMemberData] object from [source].
  factory JMemberData.readFromDataSource(DataSourceReader source) {
    JMemberDataKind kind = source.readEnum(JMemberDataKind.values);
    switch (kind) {
      case JMemberDataKind.function:
        return FunctionDataImpl.readFromDataSource(source);
      case JMemberDataKind.field:
        return JFieldDataImpl.readFromDataSource(source);
      case JMemberDataKind.constructor:
        return JConstructorData.readFromDataSource(source);
      case JMemberDataKind.constructorBody:
        return ConstructorBodyDataImpl.readFromDataSource(source);
      case JMemberDataKind.signature:
        return SignatureFunctionData.readFromDataSource(source);
      case JMemberDataKind.generatorBody:
        return GeneratorBodyFunctionData.readFromDataSource(source);
      case JMemberDataKind.closureFunction:
        return ClosureFunctionData.readFromDataSource(source);
      case JMemberDataKind.closureField:
        return ClosureFieldData.readFromDataSource(source);
      case JMemberDataKind.recordGetter:
        return RecordGetterData.readFromDataSource(source);
    }
  }

  /// Serializes this [JMemberData] to [sink].
  void writeToDataSink(DataSinkWriter sink);
}

abstract class JMemberDataImpl implements JMemberData {
  final ir.Member node;

  @override
  final MemberDefinition definition;

  @override
  StaticTypeCache get staticTypes => _staticTypes.loaded();
  final Deferrable<StaticTypeCache> _staticTypes;

  JMemberDataImpl(this.node, this.definition, StaticTypeCache staticTypes)
      : _staticTypes = Deferrable.eager(staticTypes);

  JMemberDataImpl._deserialized(this.node, this.definition, this._staticTypes);

  static StaticTypeCache _readStaticTypeCache(
      DataSourceReader source, ir.Member node) {
    return StaticTypeCache.readFromDataSource(source, node);
  }

  @override
  InterfaceType? getMemberThisType(JsToElementMap elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity? cls = member.enclosingClass;
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
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false});
}

abstract class FunctionDataTypeVariablesMixin implements FunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType>? _typeVariables;

  @override
  List<TypeVariableType> getFunctionTypeVariables(
      covariant JsKernelToElementMap elementMap) {
    if (_typeVariables == null) {
      if (functionNode.typeParameters.isEmpty) {
        _typeVariables = const <TypeVariableType>[];
      } else {
        ir.TreeNode parent = functionNode.parent!;
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
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false}) {
    void handleParameter(ir.VariableDeclaration parameter,
        {bool isOptional = true}) {
      DartType type = elementMap.getDartType(parameter.type);
      String? name = parameter.name;
      ConstantValue? defaultValue;
      if (parameter.isRequired) {
        if (elementMap.types.useLegacySubtyping) {
          defaultValue = NullConstantValue();
        } else {
          defaultValue = elementMap.getRequiredSentinelConstantValue();
        }
      } else if (isOptional) {
        if (parameter.initializer != null) {
          defaultValue = elementMap.getConstantValue(
              memberContext, parameter.initializer!);
        } else {
          defaultValue = NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    forEachOrderedParameterByFunctionNode(functionNode, parameterStructure,
        (ir.VariableDeclaration parameter,
            {required bool isOptional, required bool isElided}) {
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
  FunctionType? _type;

  FunctionDataImpl(ir.Member node, this.functionNode,
      MemberDefinition definition, StaticTypeCache staticTypes)
      : super(node, definition, staticTypes);

  FunctionDataImpl._deserialized(ir.Member node, this.functionNode,
      MemberDefinition definition, Deferrable<StaticTypeCache> staticTypes)
      : super._deserialized(node, definition, staticTypes);

  factory FunctionDataImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    Deferrable<StaticTypeCache> staticTypes = source.readDeferrableWithArg(
        JMemberDataImpl._readStaticTypeCache, node);
    source.end(tag);
    return FunctionDataImpl._deserialized(
        node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.function);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    sink.writeDeferrable(() => staticTypes.writeToDataSink(sink, node));
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
  final InterfaceType? memberThisType;
  @override
  final ClassTypeVariableAccess classTypeVariableAccess;
  List<ir.TypeParameter> get typeParameters => _typeParameters.loaded();
  final Deferrable<List<ir.TypeParameter>> _typeParameters;

  SignatureFunctionData(this.definition, this.memberThisType,
      List<ir.TypeParameter> typeParameters, this.classTypeVariableAccess)
      : _typeParameters = Deferrable.eager(typeParameters);

  SignatureFunctionData._deserialized(this.definition, this.memberThisType,
      this._typeParameters, this.classTypeVariableAccess);

  static List<ir.TypeParameter> _readTypeParameterNodes(
      DataSourceReader source) {
    return source.readTypeParameterNodes();
  }

  factory SignatureFunctionData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    InterfaceType? memberThisType =
        source.readDartTypeOrNull() as InterfaceType?;
    Deferrable<List<ir.TypeParameter>> typeParameters =
        source.readDeferrable(_readTypeParameterNodes);
    ClassTypeVariableAccess classTypeVariableAccess =
        source.readEnum(ClassTypeVariableAccess.values);
    source.end(tag);
    return SignatureFunctionData._deserialized(
        definition, memberThisType, typeParameters, classTypeVariableAccess);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.signature);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartTypeOrNull(memberThisType);
    sink.writeDeferrable(() => sink.writeTypeParameterNodes(typeParameters));
    sink.writeEnum(classTypeVariableAccess);
    sink.end(tag);
  }

  @override
  StaticTypeCache get staticTypes => const StaticTypeCache();

  @override
  FunctionType getFunctionType(covariant JsKernelToElementMap elementMap) {
    throw UnsupportedError("SignatureFunctionData.getFunctionType");
  }

  @override
  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return typeParameters
        .map<TypeVariableType>((ir.TypeParameter typeParameter) {
      return elementMap
          .getDartType(
              ir.TypeParameterType(typeParameter, ir.Nullability.nonNullable))
          .withoutNullability as TypeVariableType;
    }).toList();
  }

  @override
  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false}) {
    throw UnimplementedError('SignatureData.forEachParameter');
  }

  @override
  InterfaceType? getMemberThisType(JsToElementMap elementMap) => memberThisType;
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
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false}) {
    return baseData.forEachParameter(elementMap, parameterStructure, f,
        isNative: isNative);
  }

  @override
  InterfaceType? getMemberThisType(JsToElementMap elementMap) {
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

  GeneratorBodyFunctionData(super.baseData, this.definition);

  factory GeneratorBodyFunctionData.readFromDataSource(
      DataSourceReader source) {
    source.begin(tag);
    // TODO(johnniwinther): Share the original base data on deserialization.
    FunctionData baseData =
        JMemberData.readFromDataSource(source) as FunctionData;
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    source.end(tag);
    return GeneratorBodyFunctionData(baseData, definition);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.generatorBody);
    sink.begin(tag);
    baseData.writeToDataSink(sink);
    definition.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  StaticTypeCache get staticTypes => const StaticTypeCache();
}

class JConstructorData extends FunctionDataImpl {
  /// Tag used for identifying serialized [JConstructorDataImpl] objects in a
  /// debugging data stream.
  static const String tag = 'constructor-data';

  JConstructorBody? constructorBody;

  JConstructorData(
      super.node, super.functionNode, super.definition, super.staticTypes);

  JConstructorData._deserialized(
      super.node, super.functionNode, super.definition, super.staticTypes)
      : super._deserialized();

  factory JConstructorData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    Deferrable<StaticTypeCache> staticTypes = source.readDeferrableWithArg(
        JMemberDataImpl._readStaticTypeCache, node);
    source.end(tag);
    return JConstructorData._deserialized(
        node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.constructor);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    assert(constructorBody == null);
    sink.writeDeferrable(() => staticTypes.writeToDataSink(sink, node));
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

  ConstructorBodyDataImpl(
      super.node, super.functionNode, super.definition, super.staticTypes);

  ConstructorBodyDataImpl._deserialized(
      super.node, super.functionNode, super.definition, super.staticTypes)
      : super._deserialized();

  factory ConstructorBodyDataImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    ir.FunctionNode functionNode;
    if (node is ir.Procedure) {
      functionNode = node.function;
    } else if (node is ir.Constructor) {
      functionNode = node.function;
    } else {
      throw UnsupportedError(
          "Unexpected member node $node (${node.runtimeType}).");
    }
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    Deferrable<StaticTypeCache> staticTypes = source.readDeferrableWithArg(
        JMemberDataImpl._readStaticTypeCache, node);
    source.end(tag);
    return ConstructorBodyDataImpl._deserialized(
        node, functionNode, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.constructorBody);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    sink.writeDeferrable(() => staticTypes.writeToDataSink(sink, node));
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

  DartType? _type;

  JFieldDataImpl(super.node, super.definition, super.staticTypes);

  JFieldDataImpl._deserialized(super.node, super.definition, super.staticTypes)
      : super._deserialized();

  factory JFieldDataImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.Member node = source.readMemberNode();
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    Deferrable<StaticTypeCache> staticTypes = source.readDeferrableWithArg(
        JMemberDataImpl._readStaticTypeCache, node);
    source.end(tag);
    return JFieldDataImpl._deserialized(
        node as ir.Field, definition, staticTypes);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.field);
    sink.begin(tag);
    sink.writeMemberNode(node);
    definition.writeToDataSink(sink);
    sink.writeDeferrable(() => staticTypes.writeToDataSink(sink, node));
    sink.end(tag);
  }

  @override
  ir.Field get node => super.node as ir.Field;

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
  DartType? _bound;
  DartType? _defaultType;

  JTypeVariableData(this.node);

  factory JTypeVariableData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ir.TypeParameter node = source.readTypeParameterNode();
    source.end(tag);
    return JTypeVariableData(node);
  }

  void writeToDataSink(DataSinkWriter sink) {
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
