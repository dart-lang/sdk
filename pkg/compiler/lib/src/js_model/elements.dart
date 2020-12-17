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

const String jsElementPrefix = 'j:';

class JLibrary extends IndexedLibrary {
  /// Tag used for identifying serialized [JLibrary] objects in a
  /// debugging data stream.
  static const String tag = 'library';

  @override
  final String name;
  @override
  final Uri canonicalUri;
  @override
  final bool isNonNullableByDefault;

  JLibrary(this.name, this.canonicalUri, this.isNonNullableByDefault);

  /// Deserializes a [JLibrary] object from [source].
  factory JLibrary.readFromDataSource(DataSource source) {
    source.begin(tag);
    String name = source.readString();
    Uri canonicalUri = source.readUri();
    bool isNonNullableByDefault = source.readBool();
    source.end(tag);
    return new JLibrary(name, canonicalUri, isNonNullableByDefault);
  }

  /// Serializes this [JLibrary] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeString(name);
    sink.writeUri(canonicalUri);
    sink.writeBool(isNonNullableByDefault);
    sink.end(tag);
  }

  @override
  String toString() => '${jsElementPrefix}library($name)';
}

/// Enum used for identifying [JClass] subclasses in serialization.
enum JClassKind { node, closure, record }

class JClass extends IndexedClass with ClassHierarchyNodesMapKey {
  /// Tag used for identifying serialized [JClass] objects in a
  /// debugging data stream.
  static const String tag = 'class';

  @override
  final JLibrary library;

  @override
  final String name;
  @override
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

  @override
  String toString() => '${jsElementPrefix}class($name)';
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
  @override
  final JLibrary library;
  @override
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

  @override
  String get name => _name.text;

  @override
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

  @override
  String toString() => '${jsElementPrefix}$_kind'
      '(${enclosingClass != null ? '${enclosingClass.name}.' : ''}$name)';
}

abstract class JFunction extends JMember
    implements FunctionEntity, IndexedFunction {
  @override
  final ParameterStructure parameterStructure;
  @override
  final bool isExternal;
  @override
  final AsyncMarker asyncMarker;

  JFunction(JLibrary library, JClass enclosingClass, Name name,
      this.parameterStructure, this.asyncMarker,
      {bool isStatic: false, this.isExternal: false})
      : super(library, enclosingClass, name, isStatic: isStatic);
}

abstract class JConstructor extends JFunction
    implements ConstructorEntity, IndexedConstructor {
  @override
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

  @override
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

  @override
  final JConstructor constructor;

  JConstructorBody(this.constructor, ParameterStructure parameterStructure)
      : super(constructor.library, constructor.enclosingClass,
            constructor.memberName, parameterStructure, AsyncMarker.SYNC,
            isStatic: false, isExternal: false);

  factory JConstructorBody.readFromDataSource(DataSource source) {
    source.begin(tag);
    JConstructor constructor = source.readMember();
    ParameterStructure parameterStructure =
        new ParameterStructure.readFromDataSource(source);
    source.end(tag);
    return new JConstructorBody(constructor, parameterStructure);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.constructorBody);
    sink.begin(tag);
    sink.writeMember(constructor);
    parameterStructure.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  String get _kind => 'constructor_body';
}

class JMethod extends JFunction {
  /// Tag used for identifying serialized [JMethod] objects in a
  /// debugging data stream.
  static const String tag = 'method';

  @override
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

  @override
  String get _kind => 'method';
}

class JGeneratorBody extends JFunction {
  /// Tag used for identifying serialized [JGeneratorBody] objects in a
  /// debugging data stream.
  static const String tag = 'generator-body';

  final JFunction function;
  final DartType elementType;
  @override
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

  @override
  String get _kind => 'generator_body';
}

class JGetter extends JFunction {
  /// Tag used for identifying serialized [JGetter] objects in a
  /// debugging data stream.
  static const String tag = 'getter';

  @override
  final bool isAbstract;

  JGetter(JLibrary library, JClass enclosingClass, Name name,
      AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, ParameterStructure.getter,
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

  @override
  String get _kind => 'getter';
}

class JSetter extends JFunction {
  /// Tag used for identifying serialized [JSetter] objects in a
  /// debugging data stream.
  static const String tag = 'setter';

  @override
  final bool isAbstract;

  JSetter(JLibrary library, JClass enclosingClass, Name name,
      {bool isStatic, bool isExternal, this.isAbstract})
      : super(library, enclosingClass, name, ParameterStructure.setter,
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

  @override
  String get _kind => 'setter';
}

class JField extends JMember implements FieldEntity, IndexedField {
  /// Tag used for identifying serialized [JField] objects in a
  /// debugging data stream.
  static const String tag = 'field';

  @override
  final bool isAssignable;
  @override
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

  @override
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

  @override
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
            ParameterStructure.zeroArguments, AsyncMarker.SYNC,
            isStatic: false, isExternal: false, isAbstract: false);

  factory JSignatureMethod.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass cls = source.readClass();
    source.end(tag);
    return new JSignatureMethod(cls);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.signatureMethod);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    sink.end(tag);
  }

  @override
  String get _kind => 'signature';
}

/// Enum used for identifying [JTypeVariable] variants in serialization.
enum JTypeVariableKind { cls, member, local }

class JTypeVariable extends IndexedTypeVariable {
  /// Tag used for identifying serialized [JTypeVariable] objects in a
  /// debugging data stream.
  static const String tag = 'type-variable';

  @override
  final Entity typeDeclaration;
  @override
  final String name;
  @override
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

  @override
  String toString() =>
      '${jsElementPrefix}type_variable(${typeDeclaration.name}.$name)';
}
