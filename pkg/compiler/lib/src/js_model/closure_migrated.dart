// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/serialization/serialization.dart';

import 'package:kernel/ast.dart' as ir;

import '../closure_migrated.dart';
import '../elements/entities.dart';
import '../elements/names.dart' show Name;
import 'elements.dart';
import 'jrecord_field_interface.dart';

/// A container for variables declared in a particular scope that are accessed
/// elsewhere.
// TODO(johnniwinther): Don't implement JClass. This isn't actually a
// class.
class JRecord extends JClass {
  /// Tag used for identifying serialized [JRecord] objects in a
  /// debugging data stream.
  static const String tag = 'record';

  JRecord(LibraryEntity library, String name)
      : super(library as JLibrary, name, isAbstract: false);

  factory JRecord.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    JLibrary library = source.readLibrary() as JLibrary;
    String name = source.readString();
    source.end(tag);
    return JRecord(library, name);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassKind.record);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  @override
  bool get isClosure => false;

  @override
  String toString() => '${jsElementPrefix}record_container($name)';
}

/// A variable that has been "boxed" to prevent name shadowing with the
/// original variable and ensure that this variable is updated/read with the
/// most recent value.
class JRecordField extends JField implements JRecordFieldInterface {
  /// Tag used for identifying serialized [JRecordField] objects in a
  /// debugging data stream.
  static const String tag = 'record-field';

  final BoxLocal box;

  JRecordField(String name, this.box, {required bool isConst})
      : super(box.container.library as JLibrary, box.container as JClass,
            Name(name, box.container.library),
            isStatic: false, isAssignable: true, isConst: isConst);

  factory JRecordField.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    String name = source.readString();
    final enclosingClass = source.readClass() as JClass;
    bool isConst = source.readBool();
    source.end(tag);
    return JRecordField(name, BoxLocal(enclosingClass), isConst: isConst);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberKind.recordField);
    sink.begin(tag);
    sink.writeString(name);
    sink.writeClass(enclosingClass!);
    sink.writeBool(isConst);
    sink.end(tag);
  }

  // TODO(johnniwinther): Remove these anomalies. Maybe by separating the
  // J-entities from the K-entities.
  @override
  bool get isInstanceMember => false;

  @override
  bool get isTopLevel => false;

  @override
  bool get isStatic => false;
}

class JClosureClass extends JClass {
  /// Tag used for identifying serialized [JClosureClass] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class';

  JClosureClass(JLibrary library, String name)
      : super(library, name, isAbstract: false);

  factory JClosureClass.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    JLibrary library = source.readLibrary() as JLibrary;
    String name = source.readString();
    source.end(tag);
    return JClosureClass(library, name);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassKind.closure);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  @override
  bool get isClosure => true;

  @override
  String toString() => '${jsElementPrefix}closure_class($name)';
}

class AnonymousClosureLocal implements Local {
  final JClosureClass closureClass;

  AnonymousClosureLocal(this.closureClass);

  @override
  String get name => '';

  @override
  int get hashCode => closureClass.hashCode * 13;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! AnonymousClosureLocal) return false;
    return closureClass == other.closureClass;
  }

  @override
  String toString() =>
      '${jsElementPrefix}anonymous_closure_local(${closureClass.name})';
}

class JClosureField extends JField implements PrivatelyNamedJSEntity {
  /// Tag used for identifying serialized [JClosureClass] objects in a
  /// debugging data stream.
  static const String tag = 'closure-field';

  @override
  final String declaredName;

  JClosureField(
      String name, JsClosureClassInfo containingClass, String declaredName,
      {required bool isConst, required bool isAssignable})
      : this.internal(
            containingClass.closureClassEntity.library,
            containingClass.closureClassEntity as JClosureClass,
            Name(name, containingClass.closureClassEntity.library),
            declaredName,
            isAssignable: isAssignable,
            isConst: isConst);

  JClosureField.internal(JLibrary library, JClosureClass enclosingClass,
      Name memberName, this.declaredName,
      {required bool isConst, required bool isAssignable})
      : super(library, enclosingClass, memberName,
            isAssignable: isAssignable, isConst: isConst, isStatic: false);

  factory JClosureField.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final cls = source.readClass() as JClosureClass;
    String name = source.readString();
    String declaredName = source.readString();
    bool isConst = source.readBool();
    bool isAssignable = source.readBool();
    source.end(tag);
    return JClosureField.internal(
        cls.library, cls, Name(name, cls.library), declaredName,
        isAssignable: isAssignable, isConst: isConst);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberKind.closureField);
    sink.begin(tag);
    sink.writeClass(enclosingClass!);
    sink.writeString(name);
    sink.writeString(declaredName);
    sink.writeBool(isConst);
    sink.writeBool(isAssignable);
    sink.end(tag);
  }

  @override
  Entity get rootOfScope => enclosingClass!;
}

abstract class JsClosureClassInfo {
  JClass get closureClassEntity;
  Local get thisLocal;
  JFunction get callMethod;
  void set callMethod(JFunction value);
  JSignatureMethod get signatureMethod;
  void set signatureMethod(JSignatureMethod value);

  bool hasFieldForLocal(Local local);

  bool hasFieldForTypeVariable(JTypeVariable typeVariable);
  void registerFieldForTypeVariable(JTypeVariable typeVariable, JField field);
  void registerFieldForLocal(Local local, JField field);
  void registerFieldForVariable(ir.VariableDeclaration node, JField field);
  void registerFieldForBoxedVariable(ir.VariableDeclaration node, JField field);
}
