// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure_migrated.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/names.dart' show Name;
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/static_type_cache.dart';
import '../js_model/class_type_variable_access.dart';
import '../ordered_typeset.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
import 'element_map_interfaces.dart';
import 'element_map_migrated.dart';
import 'elements.dart';
import 'env.dart';

/// A container for variables declared in a particular scope that are accessed
/// elsewhere.
// TODO(johnniwinther): Don't implement JClass. This isn't actually a class.
class JContext extends JClass {
  /// Tag used for identifying serialized [JContext] objects in a debugging data
  /// stream.
  static const String tag = 'context';

  JContext(LibraryEntity library, String name)
      : super(library as JLibrary, name, isAbstract: false);

  factory JContext.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    JLibrary library = source.readLibrary() as JLibrary;
    String name = source.readString();
    source.end(tag);
    return JContext(library, name);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassKind.context);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  @override
  bool get isClosure => false;

  @override
  String toString() => '${jsElementPrefix}context($name)';
}

/// A variable that has been "boxed" to prevent name shadowing with the original
/// variable and ensure that this variable is updated/read with the most recent
/// value.
class JContextField extends JField {
  /// Tag used for identifying serialized [JContextField] objects in a debugging
  /// data stream.
  static const String tag = 'context-field';

  final BoxLocal box;

  JContextField(String name, this.box, {required bool isConst})
      : super(box.container.library as JLibrary, box.container as JClass,
            Name(name, box.container.library.canonicalUri),
            isStatic: false, isAssignable: true, isConst: isConst);

  factory JContextField.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    String name = source.readString();
    final enclosingClass = source.readClass() as JClass;
    bool isConst = source.readBool();
    source.end(tag);
    return JContextField(name, BoxLocal(enclosingClass), isConst: isConst);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberKind.contextField);
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

  JClosureClass(super.library, super.name) : super(isAbstract: false);

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
            Name(name, containingClass.closureClassEntity.library.canonicalUri),
            declaredName,
            isAssignable: isAssignable,
            isConst: isConst);

  JClosureField.internal(super.library, JClosureClass super.enclosingClass,
      super.memberName, this.declaredName,
      {required super.isConst, required super.isAssignable})
      : super(isStatic: false);

  factory JClosureField.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final cls = source.readClass() as JClosureClass;
    String name = source.readString();
    String declaredName = source.readString();
    bool isConst = source.readBool();
    bool isAssignable = source.readBool();
    source.end(tag);
    return JClosureField.internal(
        cls.library, cls, Name(name, cls.library.canonicalUri), declaredName,
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
  Local? get thisLocal;
  JFunction? get callMethod;
  void set callMethod(JFunction? value);
  JSignatureMethod? get signatureMethod;
  void set signatureMethod(JSignatureMethod? value);

  bool hasFieldForLocal(Local local);

  bool hasFieldForTypeVariable(JTypeVariable typeVariable);
  void registerFieldForTypeVariable(JTypeVariable typeVariable, JField field);
  void registerFieldForLocal(Local local, JField field);
  void registerFieldForVariable(ir.VariableDeclaration node, JField field);
  void registerFieldForBoxedVariable(ir.VariableDeclaration node, JField field);
}

class ContextClassData implements JClassData {
  /// Tag used for identifying serialized [ContextClassData] objects in a
  /// debugging data stream.
  static const String tag = 'context-class-data';

  @override
  final ClassDefinition definition;

  @override
  final InterfaceType? thisType;

  @override
  final OrderedTypeSet orderedTypeSet;

  @override
  final InterfaceType? supertype;

  ContextClassData(
      this.definition, this.thisType, this.supertype, this.orderedTypeSet);

  factory ContextClassData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ClassDefinition definition = ClassDefinition.readFromDataSource(source);
    InterfaceType thisType = source.readDartType() as InterfaceType;
    InterfaceType supertype = source.readDartType() as InterfaceType;
    OrderedTypeSet orderedTypeSet = OrderedTypeSet.readFromDataSource(source);
    source.end(tag);
    return ContextClassData(definition, thisType, supertype, orderedTypeSet);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassDataKind.context);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(thisType!);
    sink.writeDartType(supertype!);
    orderedTypeSet.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  bool get isMixinApplication => false;

  @override
  bool get isEnumClass => false;

  @override
  FunctionType? get callType => null;

  @override
  List<InterfaceType> get interfaces => const <InterfaceType>[];

  @override
  InterfaceType? get mixedInType => null;

  @override
  InterfaceType? get jsInteropType => thisType;

  @override
  InterfaceType? get rawType => thisType;

  @override
  InterfaceType? get instantiationToBounds => thisType;

  @override
  List<Variance> getVariances() => [];
}

class ClosureClassData extends ContextClassData {
  /// Tag used for identifying serialized [ClosureClassData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-data';

  @override
  FunctionType? callType;

  ClosureClassData(
      super.definition, super.thisType, super.supertype, super.orderedTypeSet);

  factory ClosureClassData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ClassDefinition definition = ClassDefinition.readFromDataSource(source);
    InterfaceType thisType = source.readDartType() as InterfaceType;
    InterfaceType supertype = source.readDartType() as InterfaceType;
    OrderedTypeSet orderedTypeSet = OrderedTypeSet.readFromDataSource(source);
    FunctionType callType = source.readDartType() as FunctionType;
    source.end(tag);
    return ClosureClassData(definition, thisType, supertype, orderedTypeSet)
      ..callType = callType;
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassDataKind.closure);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(thisType!);
    sink.writeDartType(supertype!);
    orderedTypeSet.writeToDataSink(sink);
    sink.writeDartType(callType!);
    sink.end(tag);
  }
}

abstract class ClosureMemberData implements JMemberData {
  @override
  final MemberDefinition definition;
  final InterfaceType? memberThisType;

  ClosureMemberData(this.definition, this.memberThisType);

  @override
  StaticTypeCache get staticTypes {
    // The cached types are stored in the data for enclosing member.
    throw UnsupportedError("ClosureMemberData.staticTypes");
  }

  @override
  InterfaceType? getMemberThisType(covariant JsToElementMap elementMap) {
    return memberThisType;
  }
}

class ClosureFunctionData extends ClosureMemberData
    with FunctionDataTypeVariablesMixin, FunctionDataForEachParameterMixin
    implements FunctionData {
  /// Tag used for identifying serialized [ClosureFunctionData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-function-data';

  final FunctionType functionType;
  @override
  ir.FunctionNode get functionNode => _functionNode.loaded();
  final Deferrable<ir.FunctionNode> _functionNode;
  @override
  final ClassTypeVariableAccess classTypeVariableAccess;

  ClosureFunctionData(super.definition, super.memberThisType, this.functionType,
      ir.FunctionNode functionNode, this.classTypeVariableAccess)
      : _functionNode = Deferrable.eager(functionNode);

  ClosureFunctionData._deserialized(super.definition, super.memberThisType,
      this.functionType, this._functionNode, this.classTypeVariableAccess);

  factory ClosureFunctionData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ClosureMemberDefinition definition =
        MemberDefinition.readFromDataSource(source) as ClosureMemberDefinition;
    InterfaceType? memberThisType =
        source.readDartTypeOrNull() as InterfaceType?;
    FunctionType functionType = source.readDartType() as FunctionType;
    Deferrable<ir.FunctionNode> functionNode =
        source.readDeferrable(() => source.readTreeNode() as ir.FunctionNode);
    ClassTypeVariableAccess classTypeVariableAccess =
        source.readEnum(ClassTypeVariableAccess.values);
    source.end(tag);
    return ClosureFunctionData._deserialized(definition, memberThisType,
        functionType, functionNode, classTypeVariableAccess);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.closureFunction);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartTypeOrNull(memberThisType);
    sink.writeDartType(functionType);
    sink.writeDeferrable(() => sink.writeTreeNode(functionNode));
    sink.writeEnum(classTypeVariableAccess);
    sink.end(tag);
  }

  @override
  late final ir.Member memberContext = (() {
    ir.TreeNode parent = functionNode;
    while (parent is! ir.Member) {
      parent = parent.parent!;
    }
    return parent;
  })();

  @override
  FunctionType getFunctionType(IrToElementMap elementMap) {
    return functionType;
  }
}

class ClosureFieldData extends ClosureMemberData implements JFieldData {
  /// Tag used for identifying serialized [ClosureFieldData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-field-data';

  DartType? _type;

  ClosureFieldData(super.definition, super.memberThisType);

  factory ClosureFieldData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    InterfaceType /*?*/ memberThisType =
        source.readDartTypeOrNull() as InterfaceType /*?*/;
    source.end(tag);
    return ClosureFieldData(definition, memberThisType);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.closureField);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartTypeOrNull(memberThisType);
    sink.end(tag);
  }

  @override
  DartType getFieldType(IrToElementMap elementMap) {
    if (_type != null) return _type!;
    ir.Node sourceNode = definition.node;
    ir.DartType type;
    if (sourceNode is ir.Class) {
      type = sourceNode.getThisType(
          elementMap.coreTypes, sourceNode.enclosingLibrary.nonNullable);
    } else if (sourceNode is ir.VariableDeclaration) {
      type = sourceNode.type;
    } else if (sourceNode is ir.Field) {
      type = sourceNode.type;
    } else if (sourceNode is ir.TypeLiteral) {
      type = sourceNode.type;
    } else if (sourceNode is ir.Typedef) {
      type = sourceNode.type!;
    } else if (sourceNode is ir.TypeParameter) {
      type = sourceNode.bound;
    } else {
      failedAt(
          definition.location,
          'Unexpected node type ${sourceNode} in '
          'ClosureFieldData.getFieldType');
    }
    return _type = elementMap.getDartType(type);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.none;
}
