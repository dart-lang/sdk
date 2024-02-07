// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Records are implemented as classes introduced in the K- to J- lowering.
///
/// The record classes are arranged in a hierarchy, with single base class.  The
/// base class has subclasses for each 'basic' shape, the number of fields. This
/// is called the 'arity' class.  The arity class has subclasses for each actual
/// record shape. There can be further subclasses of the shape class to allow
/// specialization on the basis of the value stored in the field.
///
/// Example
///
///     _Record - base class
///
///       _Record2 - class for Record arity (number of fields)
///
///         _Record_2_end_start - class for shape `(start:, end:)`
///
///           _Record_2_end_start__int_int - class for specialization within
///              shape when the field are known to in `int`s. This allows more
///              efficient `==` and `.hashCode` operations.
///
/// RecordDataBuilder creates the new classes. The arity classes exist as Dart
/// code in `js_runtime/lib/records.dart`. RecordDataBuilder creates shape
/// classes and specialization classes.
///
/// (Specialization classes have not yet been implemented).
library dart2js.js_model.records;

import 'package:js_shared/variance.dart';

import '../common.dart';
import '../constants/values.dart' show ConstantValue;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/element_map.dart' show IrToElementMap;
import '../js_backend/annotations.dart';
import '../ordered_typeset.dart';
import '../serialization/serialization.dart';
import '../universe/record_shape.dart';
import 'class_type_variable_access.dart';
import 'element_map.dart';
import 'element_map_impl.dart' show JsKernelToElementMap;
import 'elements.dart';
import 'env.dart';
import 'js_world_builder.dart' show JClosedWorldBuilder;

class RecordData {
  /// Tag used for identifying serialized [RecordData] objects in a
  /// debugging data stream.
  static const String tag = 'record-data';

  final JsToElementMap _elementMap;
  final List<RecordRepresentation> _representations;

  final Map<RecordShape, List<MemberEntity>> _gettersByShape;
  final Map<ClassEntity, RecordRepresentation> _classToRepresentation = {};
  final Map<RecordShape, RecordRepresentation> _shapeToRepresentation = {};

  RecordData._(this._elementMap, this._representations, this._gettersByShape) {
    // Unpack representations into lookup maps.
    for (final info in _representations) {
      _classToRepresentation[info.cls] = info;
      if (info.definesShape) _shapeToRepresentation[info.shape] = info;
    }
  }

  Iterable<MemberEntity> get allGetters =>
      _gettersByShape.values.expand((e) => e);

  List<MemberEntity> gettersForShape(RecordShape shape) =>
      _gettersByShape[shape]!;

  Iterable<ClassEntity> get allClasses => _classToRepresentation.keys;

  factory RecordData.readFromDataSource(
      JsToElementMap elementMap, DataSourceReader source) {
    source.begin(tag);
    List<RecordRepresentation> representations =
        source.readList(() => RecordRepresentation.readFromDataSource(source));
    final shapes =
        source.readList(() => RecordShape.readFromDataSource(source));
    final getters = source.readList(source.readMembers);
    source.end(tag);
    return RecordData._(
        elementMap, representations, Map.fromIterables(shapes, getters));
  }

  /// Serializes this [RecordData] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeList<RecordRepresentation>(
        _representations, (info) => info.writeToDataSink(sink));
    sink.writeList(
        _gettersByShape.keys, (RecordShape v) => v.writeToDataSink(sink));
    sink.writeList(_gettersByShape.values, sink.writeMembers);
    sink.end(tag);
  }

  /// Returns a fresh List of representations that define shapes.
  List<RecordRepresentation> representationsForShapes() =>
      [..._shapeToRepresentation.values];

  /// Returns the representation for a shape.  Returns `null` if the record
  /// shape is not instantiated.
  RecordRepresentation? representationForShape(RecordShape shape) {
    return _shapeToRepresentation[shape];
  }

  /// This should only be called at record creation sites, ensuring that there
  /// is a representation.
  RecordRepresentation representationForStaticType(RecordType type) {
    // TODO(49718): Implement specialization when fields have types that allow
    // better code for `==` and `.hashCode`.

    // TODO(50081): Ensure the specialization is correctly identified the
    // 'static' type of a constant record where the type is generated from the
    // field values.

    return representationForShape(type.shape) ??
        (throw StateError('representationForStaticType $type '
            'for uninstantiated shape ${type.shape}'));
  }

  /// Returns `null` if [cls] is not a record representation.
  RecordRepresentation? representationForClass(ClassEntity cls) {
    return _classToRepresentation[cls];
  }

  /// Returns field and possibly index for accessing into a shape. The shape
  /// needs to have a representation, so calls may need to be guarded by
  /// checking that there is a representation for the shape
  /// ([representationForShape]).
  RecordAccessPath pathForAccess(RecordShape shape, int indexInShape) {
    // TODO(sra): Cache lookup.
    final representation = representationForShape(shape)!;
    final cls = representation.cls;
    if (representation.usesList) {
      final field = _elementMap.elementEnvironment
          .lookupClassMember(cls, Name('_values', cls.library.canonicalUri));
      return RecordAccessPath(field as FieldEntity, indexInShape);
    } else {
      final field = _elementMap.elementEnvironment.lookupClassMember(
          cls, Name('_$indexInShape', cls.library.canonicalUri));
      return RecordAccessPath(field as FieldEntity, null);
    }
  }
}

/// How to access a field of a record. Currently there are two forms, a single
/// field access (e.g. `r._2`), used for small records, or a field access
/// followed by an indexing, used for records that hold the values in a JSArray
/// (e.g. `r._values[2]`).
class RecordAccessPath {
  final FieldEntity field;
  final int? index; // `null` for single field access.
  RecordAccessPath(this.field, this.index);
}

class RecordRepresentation {
  static const String tag = 'record-class-info';

  /// There is one [RecordRepresentation] per class.
  final ClassEntity cls;

  /// The record shape of [cls]. There can be many classes defining records of
  /// the same shape, for example, when there are specializations of a record
  /// shape.
  final RecordShape shape;

  /// [definesShape] is `true` if this record class is a shape class. There may
  /// be subclasses of this class which share the same shape. In this case
  /// [definesShape] is `false`, as the subclasses can inherit shape metadata.
  ///
  /// A shape class defines some metadata properties on the prototype:
  ///
  /// (1) The shapeTag, a small integer (see below).
  /// (2) The top-type recipe for the shape. The recipe is a function of the
  ///     [shape]. e.g. `"+end,start(@,@)"`.
  final bool definesShape;

  /// `true` if this class is based on the general record class that uses a
  /// `List` to store the fields.
  final bool usesList;

  /// [shapeTag] is a small integer that is a function of the shape.  The
  /// shapeTag can be used as an index into runtime computed derived data.
  final int shapeTag;

  /// This is non-null for a specialization subclass of a shape class.
  // TODO(50081): This is a placeholder for the specialization key. We might do
  // something like interceptors, where 'i' means 'int', 's' means 'string', so
  // they key 's_i_is' would be a specialization for a record where the fields
  // are {int}, {string} and {int,string}. Operator `==` could be specialized to
  // use `===` for each field, but `.hashCode` would need a dispatch for the
  // last field. Or we could do something completely different like have a
  // `List` of inferred types.
  final String? _specializationKey;

  RecordRepresentation._(this.cls, this.shape, this.definesShape, this.usesList,
      this.shapeTag, this._specializationKey);

  factory RecordRepresentation.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final cls = source.readClass();
    final shape = RecordShape.readFromDataSource(source);
    final definesShape = source.readBool();
    final usesList = source.readBool();
    final shapeTag = source.readInt();
    final specializationKey = source.readStringOrNull();
    source.end(tag);
    return RecordRepresentation._(
        cls, shape, definesShape, usesList, shapeTag, specializationKey);
  }

  /// Serializes this [RecordData] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeClass(cls);
    shape.writeToDataSink(sink);
    sink.writeBool(definesShape);
    sink.writeBool(usesList);
    sink.writeInt(shapeTag);
    sink.writeStringOrNull(_specializationKey);
    sink.end(tag);
  }

  @override
  String toString() {
    final sb = StringBuffer('RecordRepresentation(');
    sb.writeAll([
      'cls=$cls',
      'shape=$shape',
      'shapeTag=$shapeTag',
      if (_specializationKey != null) 'specializationKey=$_specializationKey'
    ], ',');
    sb.write(')');
    return sb.toString();
  }
}

/// Conversion of records to classes.
class RecordDataBuilder {
  final DiagnosticReporter _reporter;
  final JsToElementMap _elementMap;
  final AnnotationsData _annotationsData;
  final Map<RecordShape, List<MemberEntity>> _gettersByShape = {};

  RecordDataBuilder(this._reporter, this._elementMap, this._annotationsData);

  RecordData createRecordData(JClosedWorldBuilder closedWorldBuilder,
      Iterable<RecordType> recordTypes) {
    _reporter;
    _annotationsData;

    // Sorted shapes lead to a more consistent class ordering in the generated
    // code.
    final shapes = recordTypes.map((type) => type.shape).toSet().toList()
      ..sort(RecordShape.compare);

    List<RecordRepresentation> representations = [];
    for (int i = 0; i < shapes.length; i++) {
      final shape = shapes[i];
      final getters = <MemberEntity>[];
      final cls = shape.fieldCount == 0
          ? _elementMap.commonElements.emptyRecordClass
          : closedWorldBuilder.buildRecordShapeClass(shape, getters);
      _gettersByShape[shape] = getters;
      int shapeTag = i;
      bool usesList = _computeUsesGeneralClass(cls);
      final info =
          RecordRepresentation._(cls, shape, true, usesList, shapeTag, null);
      representations.add(info);
    }

    return RecordData._(_elementMap, representations, _gettersByShape);
  }

  bool _computeUsesGeneralClass(ClassEntity? cls) {
    while (cls != null) {
      if (cls == _elementMap.commonElements.recordGeneralBaseClass) return true;
      cls = _elementMap.elementEnvironment.getSuperClass(cls);
    }
    return false;
  }
}

// TODO(sra): Use a regular JClass with a different Definition?
class JRecordClass extends JClass {
  /// Tag used for identifying serialized [JRecordClass] objects in a
  /// debugging data stream.
  static const String tag = 'record-class';

  JRecordClass(super.library, super.name, {required super.isAbstract});

  factory JRecordClass.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    JLibrary library = source.readLibrary() as JLibrary;
    String name = source.readString();
    bool isAbstract = source.readBool();
    source.end(tag);
    return JRecordClass(library, name, isAbstract: isAbstract);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassKind.record);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.writeBool(isAbstract);
    sink.end(tag);
  }

  @override
  String toString() => '${jsElementPrefix}record_class($name)';
}

class RecordClassData implements JClassData {
  /// Tag used for identifying serialized [RecordClassData] objects in a
  /// debugging data stream.
  static const String tag = 'record-class-data';

  @override
  final ClassDefinition definition;

  @override
  final InterfaceType? thisType;

  @override
  final OrderedTypeSet orderedTypeSet;

  @override
  final InterfaceType? supertype;

  RecordClassData(
      this.definition, this.thisType, this.supertype, this.orderedTypeSet);

  factory RecordClassData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    ClassDefinition definition = ClassDefinition.readFromDataSource(source);
    InterfaceType thisType = source.readDartType() as InterfaceType;
    InterfaceType supertype = source.readDartType() as InterfaceType;
    OrderedTypeSet orderedTypeSet = OrderedTypeSet.readFromDataSource(source);
    source.end(tag);
    return RecordClassData(definition, thisType, supertype, orderedTypeSet);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JClassDataKind.record);
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

class JRecordGetter extends JFunction {
  /// Tag used for identifying serialized [JRecordGetter] objects in a
  /// debugging data stream.
  static const String tag = 'record-getter';

  JRecordGetter(JClass enclosingClass, Name name)
      : super(enclosingClass.library, enclosingClass, name,
            ParameterStructure.getter, AsyncMarker.SYNC,
            isStatic: false, isExternal: false);

  factory JRecordGetter.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    JClass enclosingClass = source.readClass() as JClass;
    Name memberName = source.readMemberName();
    source.end(tag);
    return JRecordGetter(enclosingClass, memberName);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberKind.recordGetter);
    sink.begin(tag);
    sink.writeClass(enclosingClass!);
    sink.writeMemberName(memberName);
    sink.end(tag);
  }

  @override
  bool get isAbstract => false;

  @override
  bool get isGetter => true;

  @override
  String toString() => '${jsElementPrefix}record_getter'
      '(${enclosingClass!.name}.$name)';
}

abstract class RecordMemberData implements JMemberData {
  @override
  final MemberDefinition definition;
  final InterfaceType? memberThisType;

  RecordMemberData(this.definition, this.memberThisType);

  @override
  InterfaceType? getMemberThisType(covariant JsToElementMap elementMap) {
    return memberThisType;
  }
}

class RecordGetterData extends RecordMemberData implements FunctionData {
  /// Tag used for identifying serialized [RecordGetterData] objects in a
  /// debugging data stream.
  static const String tag = 'record-getter-data';

  final FunctionType functionType;

  RecordGetterData(super.definition, super.memberThisType, this.functionType);

  RecordGetterData._deserialized(
      super.definition, super.memberThisType, this.functionType);

  factory RecordGetterData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    MemberDefinition definition = MemberDefinition.readFromDataSource(source);
    InterfaceType? memberThisType =
        source.readDartTypeOrNull() as InterfaceType?;
    FunctionType functionType = source.readDartType() as FunctionType;
    source.end(tag);
    return RecordGetterData._deserialized(
        definition, memberThisType, functionType);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(JMemberDataKind.recordGetter);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartTypeOrNull(memberThisType);
    sink.writeDartType(functionType);
    sink.end(tag);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.none;

  @override
  List<TypeVariableType> getFunctionTypeVariables(
      covariant JsKernelToElementMap unusedElementMap) {
    return const <TypeVariableType>[];
  }

  @override
  void forEachParameter(
      JsToElementMap elementMap,
      ParameterStructure parameterStructure,
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false}) {}

  @override
  // It is a bit of a code-smell here that an synthetic element introduced
  // during creation of the K-world depends on Kernel. Perhaps it would be
  // better to compute this type and serialize it for all functions, although
  // that is redundant with the Kernel IR for most functions.
  FunctionType getFunctionType(IrToElementMap unusedElementMap) {
    return functionType;
  }
}
