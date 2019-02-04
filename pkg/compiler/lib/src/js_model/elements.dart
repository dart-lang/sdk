// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.elements;

import '../common/names.dart' show Names;
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../serialization/serialization.dart';
import '../universe/class_set.dart' show ClassHierarchyNodesMapKey;
import 'closure.dart';

/// Map from 'frontend' to 'backend' elements.
///
/// Frontend elements are what we read in, these typically represents concepts
/// in Dart. Backend elements are what we generate, these may include elements
/// that do not correspond to a Dart concept, such as closure classes.
///
/// Querying for the frontend element for a backend-only element throws an
/// exception.
abstract class JsToFrontendMap {
  LibraryEntity toBackendLibrary(LibraryEntity library);

  ClassEntity toBackendClass(ClassEntity cls);

  /// Returns the backend member corresponding to [member]. If a member isn't
  /// live, it doesn't have a corresponding backend member and `null` is
  /// returned instead.
  MemberEntity toBackendMember(MemberEntity member);

  DartType toBackendType(DartType type);

  Set<LibraryEntity> toBackendLibrarySet(Iterable<LibraryEntity> set) {
    return set.map(toBackendLibrary).toSet();
  }

  Set<ClassEntity> toBackendClassSet(Iterable<ClassEntity> set) {
    // TODO(johnniwinther): Filter unused classes.
    return set.map(toBackendClass).toSet();
  }

  Set<MemberEntity> toBackendMemberSet(Iterable<MemberEntity> set) {
    return set.map(toBackendMember).where((MemberEntity member) {
      // Members that are not live don't have a corresponding backend member.
      return member != null;
    }).toSet();
  }

  Set<FunctionEntity> toBackendFunctionSet(Iterable<FunctionEntity> set) {
    Set<FunctionEntity> newSet = new Set<FunctionEntity>();
    for (FunctionEntity element in set) {
      FunctionEntity backendFunction = toBackendMember(element);
      if (backendFunction != null) {
        // Members that are not live don't have a corresponding backend member.
        newSet.add(backendFunction);
      }
    }
    return newSet;
  }

  Map<LibraryEntity, V> toBackendLibraryMap<V>(
      Map<LibraryEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendLibrary, convert);
  }

  Map<ClassEntity, V> toBackendClassMap<V>(
      Map<ClassEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendClass, convert);
  }

  Map<MemberEntity, V> toBackendMemberMap<V>(
      Map<MemberEntity, V> map, V convert(V value)) {
    return convertMap(map, toBackendMember, convert);
  }
}

E identity<E>(E element) => element;

Map<K, V> convertMap<K, V>(
    Map<K, V> map, K convertKey(K key), V convertValue(V value)) {
  Map<K, V> newMap = <K, V>{};
  map.forEach((K key, V value) {
    K newKey = convertKey(key);
    V newValue = convertValue(value);
    if (newKey != null && newValue != null) {
      // Entities that are not used don't have a corresponding backend entity.
      newMap[newKey] = newValue;
    }
  });
  return newMap;
}

abstract class JsToFrontendMapBase extends JsToFrontendMap {
  DartType toBackendType(DartType type) =>
      type == null ? null : const TypeConverter().visit(type, _toBackendEntity);

  Entity _toBackendEntity(Entity entity) {
    if (entity is ClassEntity) return toBackendClass(entity);
    assert(entity is TypeVariableEntity);
    return toBackendTypeVariable(entity);
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable);
}

typedef Entity EntityConverter(Entity cls);

class TypeConverter implements DartTypeVisitor<DartType, EntityConverter> {
  const TypeConverter();

  @override
  DartType visit(DartType type, EntityConverter converter) {
    return type.accept(this, converter);
  }

  List<DartType> visitList(List<DartType> types, EntityConverter converter) {
    List<DartType> list = <DartType>[];
    for (DartType type in types) {
      list.add(visit(type, converter));
    }
    return list;
  }

  @override
  DartType visitDynamicType(DynamicType type, EntityConverter converter) {
    return const DynamicType();
  }

  @override
  DartType visitInterfaceType(InterfaceType type, EntityConverter converter) {
    return new InterfaceType(
        converter(type.element), visitList(type.typeArguments, converter));
  }

  @override
  DartType visitTypedefType(TypedefType type, EntityConverter converter) {
    return new TypedefType(
        converter(type.element),
        visitList(type.typeArguments, converter),
        visit(type.unaliased, converter));
  }

  @override
  DartType visitFunctionType(FunctionType type, EntityConverter converter) {
    return new FunctionType(
        visit(type.returnType, converter),
        visitList(type.parameterTypes, converter),
        visitList(type.optionalParameterTypes, converter),
        type.namedParameters,
        visitList(type.namedParameterTypes, converter),
        type.typeVariables);
  }

  @override
  DartType visitTypeVariableType(
      TypeVariableType type, EntityConverter converter) {
    return new TypeVariableType(converter(type.element));
  }

  @override
  DartType visitFunctionTypeVariable(
      FunctionTypeVariable type, EntityConverter converter) {
    return type;
  }

  @override
  DartType visitVoidType(VoidType type, EntityConverter converter) {
    return const VoidType();
  }

  @override
  DartType visitFutureOrType(FutureOrType type, EntityConverter converter) {
    return new FutureOrType(visit(type.typeArgument, converter));
  }
}

const String jsElementPrefix = 'j:';

class JLibrary extends IndexedLibrary {
  /// Tag used for identifying serialized [JLibrary] objects in a
  /// debugging data stream.
  static const String tag = 'library';

  final String name;
  final Uri canonicalUri;

  JLibrary(this.name, this.canonicalUri);

  /// Deserializes a [JLibrary] object from [source].
  factory JLibrary.readFromDataSource(DataSource source) {
    source.begin(tag);
    String name = source.readString();
    Uri canonicalUri = source.readUri();
    source.end(tag);
    return new JLibrary(name, canonicalUri);
  }

  /// Serializes this [JLibrary] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeString(name);
    sink.writeUri(canonicalUri);
    sink.end(tag);
  }

  String toString() => '${jsElementPrefix}library($name)';
}

/// Enum used for identifying [JClass] subclasses in serialization.
enum JClassKind { node, closure, record }

class JClass extends IndexedClass with ClassHierarchyNodesMapKey {
  /// Tag used for identifying serialized [JClass] objects in a
  /// debugging data stream.
  static const String tag = 'class';

  final JLibrary library;

  final String name;
  final bool isAbstract;

  JClass(this.library, this.name, {this.isAbstract});

  /// Deserializes a [JClass] object from [source].
  factory JClass.readFromDataSource(DataSource source) {
    JClassKind kind = source.readEnum(JClassKind.values);
    switch (kind) {
      case JClassKind.node:
        source.begin(tag);
        JLibrary library = source.readLibrary();
        String name = source.readString();
        bool isAbstract = source.readBool();
        source.end(tag);
        return new JClass(library, name, isAbstract: isAbstract);
      case JClassKind.closure:
        return new JClosureClass.readFromDataSource(source);
      case JClassKind.record:
        return new JRecord.readFromDataSource(source);
    }
    throw new UnsupportedError("Unexpected ClassKind $kind");
  }

  /// Serializes this [JClass] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassKind.node);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.writeBool(isAbstract);
    sink.end(tag);
  }

  @override
  bool get isClosure => false;

  String toString() => '${jsElementPrefix}class($name)';
}

class JTypedef extends IndexedTypedef {
  /// Tag used for identifying serialized [JTypedef] objects in a
  /// debugging data stream.
  static const String tag = 'typedef';

  final JLibrary library;

  final String name;

  JTypedef(this.library, this.name);

  /// Deserializes a [JTypedef] object from [source].
  factory JTypedef.readFromDataSource(DataSource source) {
    source.begin(tag);
    JLibrary library = source.readLibrary();
    String name = source.readString();
    source.end(tag);
    return new JTypedef(library, name);
  }

  /// Serializes this [JTypedef] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  String toString() => '${jsElementPrefix}typedef($name)';
}

/// Enum used for identifying [JMember] subclasses in serialization.
enum JMemberKind {
  generativeConstructor,
  factoryConstructor,
  constructorBody,
  field,
  getter,
  setter,
  method,
  closureField,
  closureCallMethod,
  generatorBody,
  signatureMethod,
  recordField,
}

abstract class JMember extends IndexedMember {
  final JLibrary library;
  final JClass enclosingClass;
  final Name _name;
  final bool _isStatic;

  JMember(this.library, this.enclosingClass, this._name, {bool isStatic: false})
      : _isStatic = isStatic;

  /// Deserializes a [JMember] object from [source].
  factory JMember.readFromDataSource(DataSource source) {
    JMemberKind kind = source.readEnum(JMemberKind.values);
    switch (kind) {
      case JMemberKind.generativeConstructor:
        return new JGenerativeConstructor.readFromDataSource(source);
      case JMemberKind.factoryConstructor:
        return new JFactoryConstructor.readFromDataSource(source);
      case JMemberKind.constructorBody:
        return new JConstructorBody.readFromDataSource(source);
      case JMemberKind.field:
        return new JField.readFromDataSource(source);
      case JMemberKind.getter:
        return new JGetter.readFromDataSource(source);
      case JMemberKind.setter:
        return new JSetter.readFromDataSource(source);
      case JMemberKind.method:
        return new JMethod.readFromDataSource(source);
      case JMemberKind.closureField:
        return new JClosureField.readFromDataSource(source);
      case JMemberKind.closureCallMethod:
        return new JClosureCallMethod.readFromDataSource(source);
      case JMemberKind.generatorBody:
        return new JGeneratorBody.readFromDataSource(source);
      case JMemberKind.signatureMethod:
        return new JSignatureMethod.readFromDataSource(source);
      case JMemberKind.recordField:
        return new JRecordField.readFromDataSource(source);
    }
    throw new UnsupportedError("Unexpected JMemberKind $kind");
  }

  /// Serializes this [JMember] to [sink].
  void writeToDataSink(DataSink sink);

  String get name => _name.text;

  Name get memberName => _name;

  @override
  bool get isAssignable => false;

  @override
  bool get isConst => false;

  @override
  bool get isAbstract => false;

  @override
  bool get isSetter => false;

  @override
  bool get isGetter => false;

  @override
  bool get isFunction => false;

  @override
  bool get isField => false;

  @override
  bool get isConstructor => false;

  @override
  bool get isInstanceMember => enclosingClass != null && !_isStatic;

  @override
  bool get isStatic => enclosingClass != null && _isStatic;

  @override
  bool get isTopLevel => enclosingClass == null;

  String get _kind;

  String toString() => '${jsElementPrefix}$_kind'
      '(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class JFunction extends JMember
    implements FunctionEntity, IndexedFunction {
  final ParameterStructure parameterStructure;
  final bool isExternal;
  final AsyncMarker asyncMarker;

  JFunction(JLibrary library, JClass enclosingClass, Name name,
      this.parameterStructure, this.asyncMarker,
      {bool isStatic: false, this.isExternal: false})
      : super(library, enclosingClass, name, isStatic: isStatic);
}

abstract class JConstructor extends JFunction
    implements ConstructorEntity, IndexedConstructor {
  final bool isConst;

  JConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, this.isConst})
      : super(enclosingClass.library, enclosingClass, name, parameterStructure,
            AsyncMarker.SYNC,
            isExternal: isExternal);

  @override
  bool get isConstructor => true;

  @override
  bool get isInstanceMember => false;

  @override
  bool get isStatic => false;

  @override
  bool get isTopLevel => false;

  @override
  bool get isFromEnvironmentConstructor => false;

  String get _kind => 'constructor';
}

class JGenerativeConstructor extends JConstructor {
  /// Tag used for identifying serialized [JGenerativeConstructor] objects in a
  /// debugging data stream.
  static const String tag = 'generative-constructor';

  JGenerativeConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  factory JGenerativeConstructor.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass enclosingClass = source.readClass();
    String name = source.readString();
    ParameterStructure parameterStructure =
        new ParameterStructure.readFromDataSource(source);
    bool isExternal = source.readBool();
    bool isConst = source.readBool();
    source.end(tag);
    return new JGenerativeConstructor(enclosingClass,
        new Name(name, enclosingClass.library), parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.generativeConstructor);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    sink.writeString(name);
    parameterStructure.writeToDataSink(sink);
    sink.writeBool(isExternal);
    sink.writeBool(isConst);
    sink.end(tag);
  }

  @override
  bool get isFactoryConstructor => false;

  @override
  bool get isGenerativeConstructor => true;
}

class JFactoryConstructor extends JConstructor {
  /// Tag used for identifying serialized [JFactoryConstructor] objects in a
  /// debugging data stream.
  static const String tag = 'factory-constructor';

  @override
  final bool isFromEnvironmentConstructor;

  JFactoryConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, this.isFromEnvironmentConstructor})
      : super(enclosingClass, name, parameterStructure,
            isExternal: isExternal, isConst: isConst);

  factory JFactoryConstructor.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass enclosingClass = source.readClass();
    String name = source.readString();
    ParameterStructure parameterStructure =
        new ParameterStructure.readFromDataSource(source);
    bool isExternal = source.readBool();
    bool isConst = source.readBool();
    bool isFromEnvironmentConstructor = source.readBool();
    source.end(tag);
    return new JFactoryConstructor(enclosingClass,
        new Name(name, enclosingClass.library), parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.factoryConstructor);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    sink.writeString(name);
    parameterStructure.writeToDataSink(sink);
    sink.writeBool(isExternal);
    sink.writeBool(isConst);
    sink.writeBool(isFromEnvironmentConstructor);
    sink.end(tag);
  }

  @override
  bool get isFactoryConstructor => true;

  @override
  bool get isGenerativeConstructor => false;
}

class JConstructorBody extends JFunction implements ConstructorBodyEntity {
  /// Tag used for identifying serialized [JConstructorBody] objects in a
  /// debugging data stream.
  static const String tag = 'constructor-body';

  final JConstructor constructor;

  JConstructorBody(this.constructor)
      : super(
            constructor.library,
            constructor.enclosingClass,
            constructor.memberName,
            constructor.parameterStructure,
            AsyncMarker.SYNC,
            isStatic: false,
            isExternal: false);

  factory JConstructorBody.readFromDataSource(DataSource source) {
    source.begin(tag);
    JConstructor constructor = source.readMember();
    source.end(tag);
    return new JConstructorBody(constructor);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.constructorBody);
    sink.begin(tag);
    sink.writeMember(constructor);
    sink.end(tag);
  }

  String get _kind => 'constructor_body';
}

class JMethod extends JFunction {
  /// Tag used for identifying serialized [JMethod] objects in a
  /// debugging data stream.
  static const String tag = 'method';

  final bool isAbstract;

  JMethod(JLibrary library, JClass enclosingClass, Name name,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, parameterStructure, asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  factory JMethod.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberContextKind kind = source.readEnum(MemberContextKind.values);
    JLibrary library;
    JClass enclosingClass;
    switch (kind) {
      case MemberContextKind.library:
        library = source.readLibrary();
        break;
      case MemberContextKind.cls:
        enclosingClass = source.readClass();
        library = enclosingClass.library;
        break;
    }
    String name = source.readString();
    ParameterStructure parameterStructure =
        new ParameterStructure.readFromDataSource(source);
    AsyncMarker asyncMarker = source.readEnum(AsyncMarker.values);
    bool isStatic = source.readBool();
    bool isExternal = source.readBool();
    bool isAbstract = source.readBool();
    source.end(tag);
    return new JMethod(library, enclosingClass, new Name(name, library),
        parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.method);
    sink.begin(tag);
    if (enclosingClass != null) {
      sink.writeEnum(MemberContextKind.cls);
      sink.writeClass(enclosingClass);
    } else {
      sink.writeEnum(MemberContextKind.library);
      sink.writeLibrary(library);
    }
    sink.writeString(name);
    parameterStructure.writeToDataSink(sink);
    sink.writeEnum(asyncMarker);
    sink.writeBool(isStatic);
    sink.writeBool(isExternal);
    sink.writeBool(isAbstract);
    sink.end(tag);
  }

  @override
  bool get isFunction => true;

  String get _kind => 'method';
}

class JGeneratorBody extends JFunction {
  /// Tag used for identifying serialized [JGeneratorBody] objects in a
  /// debugging data stream.
  static const String tag = 'generator-body';

  final JFunction function;
  final DartType elementType;
  final int hashCode;

  JGeneratorBody(this.function, this.elementType)
      : hashCode = function.hashCode + 1, // Hack stabilize sort order.
        super(function.library, function.enclosingClass, function.memberName,
            function.parameterStructure, function.asyncMarker,
            isStatic: function.isStatic, isExternal: false);

  factory JGeneratorBody.readFromDataSource(DataSource source) {
    source.begin(tag);
    JFunction function = source.readMember();
    DartType elementType = source.readDartType();
    source.end(tag);
    return new JGeneratorBody(function, elementType);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.generatorBody);
    sink.begin(tag);
    sink.writeMember(function);
    sink.writeDartType(elementType);
    sink.end(tag);
  }

  String get _kind => 'generator_body';
}

class JGetter extends JFunction {
  /// Tag used for identifying serialized [JGetter] objects in a
  /// debugging data stream.
  static const String tag = 'getter';

  final bool isAbstract;

  JGetter(JLibrary library, JClass enclosingClass, Name name,
      AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, const ParameterStructure.getter(),
            asyncMarker,
            isStatic: isStatic, isExternal: isExternal);

  factory JGetter.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberContextKind kind = source.readEnum(MemberContextKind.values);
    JLibrary library;
    JClass enclosingClass;
    switch (kind) {
      case MemberContextKind.library:
        library = source.readLibrary();
        break;
      case MemberContextKind.cls:
        enclosingClass = source.readClass();
        library = enclosingClass.library;
        break;
    }
    String name = source.readString();
    AsyncMarker asyncMarker = source.readEnum(AsyncMarker.values);
    bool isStatic = source.readBool();
    bool isExternal = source.readBool();
    bool isAbstract = source.readBool();
    source.end(tag);
    return new JGetter(
        library, enclosingClass, new Name(name, library), asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.getter);
    sink.begin(tag);
    if (enclosingClass != null) {
      sink.writeEnum(MemberContextKind.cls);
      sink.writeClass(enclosingClass);
    } else {
      sink.writeEnum(MemberContextKind.library);
      sink.writeLibrary(library);
    }
    sink.writeString(name);
    sink.writeEnum(asyncMarker);
    sink.writeBool(isStatic);
    sink.writeBool(isExternal);
    sink.writeBool(isAbstract);
    sink.end(tag);
  }

  @override
  bool get isGetter => true;

  String get _kind => 'getter';
}

class JSetter extends JFunction {
  /// Tag used for identifying serialized [JSetter] objects in a
  /// debugging data stream.
  static const String tag = 'setter';

  final bool isAbstract;

  JSetter(JLibrary library, JClass enclosingClass, Name name,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, const ParameterStructure.setter(),
            AsyncMarker.SYNC,
            isStatic: isStatic, isExternal: isExternal);

  factory JSetter.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberContextKind kind = source.readEnum(MemberContextKind.values);
    JLibrary library;
    JClass enclosingClass;
    switch (kind) {
      case MemberContextKind.library:
        library = source.readLibrary();
        break;
      case MemberContextKind.cls:
        enclosingClass = source.readClass();
        library = enclosingClass.library;
        break;
    }
    String name = source.readString();
    bool isStatic = source.readBool();
    bool isExternal = source.readBool();
    bool isAbstract = source.readBool();
    source.end(tag);
    return new JSetter(
        library, enclosingClass, new Name(name, library, isSetter: true),
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.setter);
    sink.begin(tag);
    if (enclosingClass != null) {
      sink.writeEnum(MemberContextKind.cls);
      sink.writeClass(enclosingClass);
    } else {
      sink.writeEnum(MemberContextKind.library);
      sink.writeLibrary(library);
    }
    sink.writeString(name);
    sink.writeBool(isStatic);
    sink.writeBool(isExternal);
    sink.writeBool(isAbstract);
    sink.end(tag);
  }

  @override
  bool get isAssignable => true;

  @override
  bool get isSetter => true;

  String get _kind => 'setter';
}

class JField extends JMember implements FieldEntity, IndexedField {
  /// Tag used for identifying serialized [JField] objects in a
  /// debugging data stream.
  static const String tag = 'field';

  final bool isAssignable;
  final bool isConst;

  JField(JLibrary library, JClass enclosingClass, Name name,
      {bool isStatic, this.isAssignable, this.isConst})
      : super(library, enclosingClass, name, isStatic: isStatic);

  factory JField.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberContextKind kind = source.readEnum(MemberContextKind.values);
    JLibrary library;
    JClass enclosingClass;
    switch (kind) {
      case MemberContextKind.library:
        library = source.readLibrary();
        break;
      case MemberContextKind.cls:
        enclosingClass = source.readClass();
        library = enclosingClass.library;
        break;
    }
    String name = source.readString();
    bool isStatic = source.readBool();
    bool isAssignable = source.readBool();
    bool isConst = source.readBool();
    source.end(tag);
    return new JField(library, enclosingClass, new Name(name, library),
        isStatic: isStatic, isAssignable: isAssignable, isConst: isConst);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.field);
    sink.begin(tag);
    if (enclosingClass != null) {
      sink.writeEnum(MemberContextKind.cls);
      sink.writeClass(enclosingClass);
    } else {
      sink.writeEnum(MemberContextKind.library);
      sink.writeLibrary(library);
    }
    sink.writeString(name);
    sink.writeBool(isStatic);
    sink.writeBool(isAssignable);
    sink.writeBool(isConst);
    sink.end(tag);
  }

  @override
  bool get isField => true;

  String get _kind => 'field';
}

class JClosureCallMethod extends JMethod {
  /// Tag used for identifying serialized [JClosureCallMethod] objects in a
  /// debugging data stream.
  static const String tag = 'closure-call-method';

  JClosureCallMethod(ClassEntity enclosingClass,
      ParameterStructure parameterStructure, AsyncMarker asyncMarker)
      : super(enclosingClass.library, enclosingClass, Names.call,
            parameterStructure, asyncMarker,
            isStatic: false, isExternal: false, isAbstract: false);

  factory JClosureCallMethod.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass enclosingClass = source.readClass();
    ParameterStructure parameterStructure =
        new ParameterStructure.readFromDataSource(source);
    AsyncMarker asyncMarker = source.readEnum(AsyncMarker.values);
    source.end(tag);
    return new JClosureCallMethod(
        enclosingClass, parameterStructure, asyncMarker);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.closureCallMethod);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    parameterStructure.writeToDataSink(sink);
    sink.writeEnum(asyncMarker);
    sink.end(tag);
  }

  String get _kind => 'closure_call';
}

/// A method that returns the signature of the Dart closure/tearoff that this
/// method's parent class is representing.
class JSignatureMethod extends JMethod {
  /// Tag used for identifying serialized [JSignatureMethod] objects in a
  /// debugging data stream.
  static const String tag = 'signature-method';

  JSignatureMethod(ClassEntity enclosingClass)
      : super(enclosingClass.library, enclosingClass, Names.signature,
            const ParameterStructure(0, 0, const [], 0), AsyncMarker.SYNC,
            isStatic: false, isExternal: false, isAbstract: false);

  factory JSignatureMethod.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass cls = source.readClass();
    source.end(tag);
    return new JSignatureMethod(cls);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.signatureMethod);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    sink.end(tag);
  }

  String get _kind => 'signature';
}

/// Enum used for identifying [JTypeVariable] variants in serialization.
enum JTypeVariableKind { cls, member, typedef, local }

class JTypeVariable extends IndexedTypeVariable {
  /// Tag used for identifying serialized [JTypeVariable] objects in a
  /// debugging data stream.
  static const String tag = 'type-variable';

  final Entity typeDeclaration;
  final String name;
  final int index;

  JTypeVariable(this.typeDeclaration, this.name, this.index);

  /// Deserializes a [JTypeVariable] object from [source].
  factory JTypeVariable.readFromDataSource(DataSource source) {
    source.begin(tag);
    JTypeVariableKind kind = source.readEnum(JTypeVariableKind.values);
    Entity typeDeclaration;
    switch (kind) {
      case JTypeVariableKind.cls:
        typeDeclaration = source.readClass();
        break;
      case JTypeVariableKind.member:
        typeDeclaration = source.readMember();
        break;
      case JTypeVariableKind.typedef:
        typeDeclaration = source.readTypedef();
        break;
      case JTypeVariableKind.local:
        // Type variables declared by local functions don't point to their
        // declaration, since the corresponding closure call methods is created
        // after the type variable.
        // TODO(johnniwinther): Fix this.
        break;
    }
    String name = source.readString();
    int index = source.readInt();
    source.end(tag);
    return new JTypeVariable(typeDeclaration, name, index);
  }

  /// Serializes this [JTypeVariable] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    if (typeDeclaration is IndexedClass) {
      IndexedClass cls = typeDeclaration;
      sink.writeEnum(JTypeVariableKind.cls);
      sink.writeClass(cls);
    } else if (typeDeclaration is IndexedMember) {
      IndexedMember member = typeDeclaration;
      sink.writeEnum(JTypeVariableKind.member);
      sink.writeMember(member);
    } else if (typeDeclaration is IndexedTypedef) {
      IndexedTypedef typedef = typeDeclaration;
      sink.writeEnum(JTypeVariableKind.typedef);
      sink.writeTypedef(typedef);
    } else if (typeDeclaration == null) {
      sink.writeEnum(JTypeVariableKind.local);
    } else {
      throw new UnsupportedError(
          "Unexpected type variable declarer $typeDeclaration.");
    }
    sink.writeString(name);
    sink.writeInt(index);
    sink.end(tag);
  }

  String toString() =>
      '${jsElementPrefix}type_variable(${typeDeclaration.name}.$name)';
}
