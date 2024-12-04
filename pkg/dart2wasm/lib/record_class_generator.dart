// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'records.dart';

/// Generates a class extending `Record` for each record shape in the
/// [Component].
///
/// Shape of a record is described by the [RecordShape] type.
///
/// Example: for the record `(1, a: 'hi', false)`, this generates:
///
/// ```
/// @pragma('wasm:entry-point')
/// class Record_2_a {
///   @pragma('wasm:entry-point')
///   final Object? $1;
///
///   @pragma('wasm:entry-point')
///   final Object? $2;
///
///   @pragma('wasm:entry-point')
///   final Object? a;
///
///   @pragma('wasm:entry-point')
///   Record_2_a(this.$1, this.$2, this.a);
///
///   @pragma('wasm:entry-point')
///   bool _checkRecordType(WasmArray<_Type> types, ImmutableWasmArray<String> names) {
///     if (types.length != 3) return false;
///     if (!identical(names, const ImmutableWasmArray(["a"]))) return false;
///
///     if (!_isSubtype($1, types[0])) return false;
///     if (!_isSubtype($2, types[1])) return false;
///     if (!_isSubtype($a, types[2])) return false;
///
///     return true;
///   }
///
///   @pragma('wasm:entry-point')
///   _Type get _masqueradedRecordRuntimeType =>
///     _RecordType(
///       const ImmutableWasmArray(["a"]),
///       WasmArray.literal([
///         _getMasqueradedRuntimeTypeNullable($1),
///         _getMasqueradedRuntimeTypeNullable($2),
///         _getMasqueradedRuntimeTypeNullable(a)
///       ]));
///
///   @pragma('wasm:entry-point')
///   _Type get _recordRuntimeType =>
///     _RecordType(
///       const ImmutableWasmArray(["a"]),
///       WasmArray.literal([
///         _getActualRuntimeTypeNullable($1),
///         _getActualRuntimeTypeNullable($2),
///         _getActualRuntimeTypeNullable(a)
///       ]));
///
///   @pragma('wasm:entry-point')
///   String toString() =>
///     "(" + $1 + ", " + $2 + ", " + "a: " + a + ")";
///
///   @pragma('wasm:entry-point')
///   bool operator ==(Object other) {
///     if (other is! Record_2_a) return false;
///     if ($1 != other.$1) return false;
///     if ($2 != other.$2) return false;
///     if (a != other.a) return false;
///     return true;
///   }
///
///   @pragma('wasm:entry-point')
///   int hashCode =>
///     Object.hash(shapeID, $1, $2, a);
/// }
/// ```
Map<RecordShape, Class> generateRecordClasses(
    Component component, CoreTypes coreTypes) {
  final Map<RecordShape, Class> recordClasses = {};
  final recordClassGenerator = _RecordClassGenerator(recordClasses, coreTypes);
  final visitor = _RecordVisitor(recordClassGenerator);
  component.libraries.forEach(visitor.visitLibrary);
  return recordClasses;
}

class _RecordClassGenerator {
  final CoreTypes coreTypes;
  final Map<RecordShape, Class> classes;

  late final Class typeRuntimetypeTypeClass =
      coreTypes.index.getClass("dart:core", "_Type");
  late final Class recordRuntimeTypeClass =
      coreTypes.index.getClass('dart:core', '_RecordType');

  late final Constructor recordRuntimeTypeConstructor =
      recordRuntimeTypeClass.constructors.single;

  late final Procedure objectHashProcedure =
      coreTypes.index.getProcedure('dart:core', 'Object', 'hash');

  late final Procedure objectHashAllProcedure =
      coreTypes.index.getProcedure('dart:core', 'Object', 'hashAll');

  late final Procedure objectToStringProcedure =
      coreTypes.index.getProcedure('dart:core', 'Object', 'toString');

  late final Procedure identical =
      coreTypes.index.getTopLevelProcedure('dart:core', 'identical');

  late final Procedure objectEqualsProcedure = coreTypes.objectEquals;

  late final FunctionType integerEqualsFunctionType =
      FunctionType([intType, intType], boolType, Nullability.nonNullable);

  late final Procedure stringPlusProcedure =
      coreTypes.index.getProcedure('dart:core', 'String', '+');

  late final Procedure isSubtype =
      coreTypes.index.getTopLevelProcedure('dart:core', '_isSubtype');

  late final Class wasmArrayClass =
      coreTypes.index.getClass('dart:_wasm', 'WasmArray');

  late final Class immutableWasmArrayClass =
      coreTypes.index.getClass('dart:_wasm', 'ImmutableWasmArray');

  late final Procedure wasmArrayRefLength =
      coreTypes.index.getProcedure('dart:_wasm', 'WasmArrayRef', 'get:length');

  late final Procedure wasmArrayIndex = coreTypes.index
      .getLibrary('dart:_wasm')
      .extensions
      .singleWhere((e) => e.name == 'WasmArrayExt')
      .memberDescriptors
      .singleWhere((member) => member.name.text == '[]')
      .memberReference
      .node as Procedure;

  late final Constructor wasmArrayLiteralConstructor =
      coreTypes.index.getConstructor('dart:_wasm', 'WasmArray', 'literal');

  late final Field wasmArrayValueField =
      coreTypes.index.getField("dart:_wasm", "WasmArray", "_value");

  late final Field immutableWasmArrayValueField =
      coreTypes.index.getField("dart:_wasm", "ImmutableWasmArray", "_value");

  late final InterfaceType wasmArrayOfType = InterfaceType(
      wasmArrayClass, Nullability.nonNullable, [nonNullableTypeType]);

  late final InterfaceType immutableWasmArrayOfString = InterfaceType(
      immutableWasmArrayClass,
      Nullability.nonNullable,
      [nonNullableStringType]);

  late final InterfaceType runtimeTypeType =
      InterfaceType(typeRuntimetypeTypeClass, Nullability.nonNullable);

  late final InterfaceType nonNullableTypeType =
      InterfaceType(typeRuntimetypeTypeClass, Nullability.nonNullable);

  late final Procedure getActualRuntimeTypeNullable = coreTypes.index
      .getTopLevelProcedure('dart:core', '_getActualRuntimeTypeNullable');

  late final Procedure getMasqueradedRuntimeTypeNullableProcedure = coreTypes
      .index
      .getTopLevelProcedure('dart:core', '_getMasqueradedRuntimeTypeNullable');

  DartType get nullableObjectType => coreTypes.objectNullableRawType;

  DartType get nonNullableStringType => coreTypes.stringNonNullableRawType;

  DartType get boolType => coreTypes.boolNonNullableRawType;

  DartType get intType => coreTypes.intNonNullableRawType;

  Library get library => coreTypes.coreLibrary;

  _RecordClassGenerator(this.classes, this.coreTypes);

  void generateClassForRecordType(RecordType recordType) {
    final shape = RecordShape.fromType(recordType);
    final id = classes.length;
    classes.putIfAbsent(shape, () => _generateClass(shape, id));
  }

  /// Add a `@pragma('wasm:entry-point')` annotation to an annotatable.
  T _addWasmEntryPointPragma<T extends Annotatable>(T node) => node
    ..addAnnotation(ConstantExpression(
        InstanceConstant(coreTypes.pragmaClass.reference, [], {
      coreTypes.pragmaName.fieldReference: StringConstant("wasm:entry-point"),
      coreTypes.pragmaOptions.fieldReference: NullConstant(),
    })));

  Class _generateClass(RecordShape shape, int id) {
    final fields = _generateFields(shape);

    String className = 'Record_${shape.positionals}';
    if (shape.names.isNotEmpty) {
      className = '${className}_${shape.names.join('_')}';
    }

    final cls = _addWasmEntryPointPragma(Class(
      name: className,
      isAbstract: false,
      isAnonymousMixin: false,
      supertype: Supertype(coreTypes.recordClass, []),
      constructors: [_generateConstructor(shape, fields)],
      procedures: [
        _generateHashCode(fields, id),
        _generateToString(shape, fields),
      ],
      fields: fields,
      fileUri: library.fileUri,
    ));
    library.addClass(cls);
    cls.addProcedure(_generateEquals(shape, fields, cls));
    cls.addProcedure(_generateCheckRecordType(shape, fields));
    cls.addProcedure(_generateRecordRuntimeType(shape, fields));
    cls.addProcedure(_generateMasqueradedRecordRuntimeType(shape, fields));
    return cls;
  }

  List<Field> _generateFields(RecordShape shape) {
    final List<Field> fields = [];

    for (int i = 0; i < shape.positionals; i += 1) {
      fields.add(_addWasmEntryPointPragma(Field.immutable(
        Name('\$${i + 1}', library),
        isFinal: true,
        fileUri: library.fileUri,
      )));
    }

    for (String name in shape.names) {
      fields.add(_addWasmEntryPointPragma(Field.immutable(
        Name(name, library),
        isFinal: true,
        fileUri: library.fileUri,
      )));
    }

    return fields;
  }

  /// Generate a constructor with name `_`. Named fields are passed in sorted
  /// order.
  Constructor _generateConstructor(RecordShape shape, List<Field> fields) {
    final List<VariableDeclaration> positionalParameters = List.generate(
        fields.length,
        (i) => VariableDeclaration('field$i', isSynthesized: true));

    final List<Initializer> initializers = List.generate(
        fields.length,
        (i) =>
            FieldInitializer(fields[i], VariableGet(positionalParameters[i])));

    final function =
        FunctionNode(null, positionalParameters: positionalParameters);

    return _addWasmEntryPointPragma(Constructor(function,
        name: Name('_', library),
        isConst: true,
        initializers: initializers,
        fileUri: library.fileUri));
  }

  /// Generate `int get hashCode` member.
  Procedure _generateHashCode(List<Field> fields, int shapeId) {
    final Expression returnValue;

    if (fields.isEmpty) {
      returnValue = IntLiteral(shapeId);
    } else {
      final List<Expression> arguments = [];
      arguments.add(IntLiteral(shapeId));
      for (Field field in fields) {
        arguments.add(InstanceGet(
            InstanceAccessKind.Instance, ThisExpression(), field.name,
            interfaceTarget: field, resultType: nullableObjectType));
      }
      if (fields.length <= 20) {
        // Object.hash(field1, field2, ...)
        returnValue =
            StaticInvocation(objectHashProcedure, Arguments(arguments));
      } else {
        // Object.hashAll([field1, field2, ...])
        returnValue = StaticInvocation(
            objectHashAllProcedure, Arguments([ListLiteral(arguments)]));
      }
    }

    return _addWasmEntryPointPragma(Procedure(
      Name('hashCode', library),
      ProcedureKind.Getter,
      FunctionNode(ReturnStatement(returnValue), returnType: intType),
      fileUri: library.fileUri,
    ));
  }

  /// Generate `String toString()` member.
  Procedure _generateToString(RecordShape shape, List<Field> fields) {
    final List<Expression> stringExprs = [];

    Expression fieldToStringExpression(Field field) => InstanceInvocation(
        InstanceAccessKind.Object,
        InstanceGet(InstanceAccessKind.Instance, ThisExpression(), field.name,
            interfaceTarget: field, resultType: nullableObjectType),
        Name('toString'),
        Arguments([]),
        interfaceTarget: objectToStringProcedure,
        functionType: FunctionType(
          [],
          nonNullableStringType,
          Nullability.nonNullable,
        ));

    int fieldIdx = 0;

    for (; fieldIdx < shape.positionals; fieldIdx += 1) {
      final Field field = fields[fieldIdx];
      stringExprs.add(fieldToStringExpression(field));
      if (fieldIdx != shape.numFields - 1) {
        stringExprs.add(StringLiteral(', '));
      }
    }

    for (String name in shape.names) {
      final Field field = fields[fieldIdx];
      stringExprs.add(StringLiteral('$name: '));
      stringExprs.add(fieldToStringExpression(field));
      if (fieldIdx != shape.numFields - 1) {
        stringExprs.add(StringLiteral(', '));
      }
      fieldIdx += 1;
    }

    stringExprs.add(StringLiteral(')'));

    final Expression stringExpression = stringExprs.fold(
        StringLiteral('('),
        (string, next) => InstanceInvocation(
              InstanceAccessKind.Instance,
              string,
              Name('+'),
              Arguments([next]),
              interfaceTarget: stringPlusProcedure,
              functionType: FunctionType(
                [nonNullableStringType],
                nonNullableStringType,
                Nullability.nonNullable,
              ),
            ));

    return _addWasmEntryPointPragma(Procedure(
      Name('toString', library),
      ProcedureKind.Method,
      FunctionNode(ReturnStatement(stringExpression)),
      fileUri: library.fileUri,
    ));
  }

  /// Generate `bool operator ==` member.
  Procedure _generateEquals(RecordShape shape, List<Field> fields, Class cls) {
    final equalsFunctionType = FunctionType(
      [nullableObjectType],
      boolType,
      Nullability.nonNullable,
    );

    final VariableDeclaration parameter = VariableDeclaration('other',
        type: nullableObjectType, isSynthesized: true);

    final List<Statement> statements = [];

    statements.add(IfStatement(
      Not(IsExpression(
          VariableGet(parameter), InterfaceType(cls, Nullability.nonNullable))),
      ReturnStatement(BoolLiteral(false)),
      null,
    ));

    // Compare fields.
    for (Field field in fields) {
      statements.add(IfStatement(
        Not(EqualsCall(
          InstanceGet(InstanceAccessKind.Instance, ThisExpression(), field.name,
              interfaceTarget: field, resultType: nullableObjectType),
          InstanceGet(
              InstanceAccessKind.Instance, VariableGet(parameter), field.name,
              interfaceTarget: field, resultType: nullableObjectType),
          interfaceTarget: objectEqualsProcedure,
          functionType: equalsFunctionType,
        )),
        ReturnStatement(BoolLiteral(false)),
        null,
      ));
    }

    statements.add(ReturnStatement(BoolLiteral(true)));

    final FunctionNode function = FunctionNode(
      Block(statements),
      positionalParameters: [parameter],
      returnType: boolType,
    );

    return _addWasmEntryPointPragma(Procedure(
      Name('==', library),
      ProcedureKind.Operator,
      function,
      fileUri: library.fileUri,
    ));
  }

  /// Generate `_checkRecordType` member.
  Procedure _generateCheckRecordType(RecordShape shape, List<Field> fields) {
    final typesParameter = VariableDeclaration('types', type: wasmArrayOfType);
    final namesParameter =
        VariableDeclaration('names', type: immutableWasmArrayOfString);

    final List<Statement> statements = [];

    // if (types.length != shape.numFields) return false;
    statements.add(IfStatement(
        Not(EqualsCall(
            InstanceGet(
              InstanceAccessKind.Instance,
              VariableGet(typesParameter),
              wasmArrayRefLength.name,
              interfaceTarget: wasmArrayRefLength,
              resultType: intType,
            ),
            IntLiteral(shape.numFields),
            functionType: integerEqualsFunctionType,
            interfaceTarget: objectEqualsProcedure)),
        ReturnStatement(BoolLiteral(false)),
        null));

    // if (!identical(names, _fieldNamesConstant(shape))) return false;
    statements.add(IfStatement(
        Not(StaticInvocation(
            identical,
            Arguments([
              VariableGet(namesParameter),
              ConstantExpression(_fieldNamesConstant(shape)),
            ]))),
        ReturnStatement(BoolLiteral(false)),
        null));

    // if (!_isSubtype($..., types[...])) return false;
    for (int i = 0; i < shape.numFields; ++i) {
      final field = fields[i];
      statements.add(IfStatement(
          Not(StaticInvocation(
              isSubtype,
              Arguments([
                InstanceGet(
                    InstanceAccessKind.Instance, ThisExpression(), field.name,
                    interfaceTarget: field, resultType: nullableObjectType),
                StaticInvocation(
                    wasmArrayIndex,
                    Arguments([
                      VariableGet(typesParameter),
                      IntLiteral(i),
                    ], types: [
                      nonNullableTypeType
                    ])),
              ]))),
          ReturnStatement(BoolLiteral(false)),
          null));
    }

    // return true
    statements.add(ReturnStatement(BoolLiteral(true)));

    final FunctionNode function = FunctionNode(
      Block(statements),
      positionalParameters: [typesParameter, namesParameter],
      returnType: boolType,
    );

    return _addWasmEntryPointPragma(Procedure(
      Name('_checkRecordType', library),
      ProcedureKind.Method,
      function,
      fileUri: library.fileUri,
    ));
  }

  /// Generate `_Type get _recordRuntimeType` member.
  Procedure _generateRecordRuntimeType(RecordShape shape, List<Field> fields) {
    return _generateRecordRuntimeTypeHelper(
        '_recordRuntimeType', getActualRuntimeTypeNullable, shape, fields);
  }

  /// Generate `_Type get _masqueradedRecordRuntimeType ` member.
  Procedure _generateMasqueradedRecordRuntimeType(
      RecordShape shape, List<Field> fields) {
    return _generateRecordRuntimeTypeHelper('_masqueradedRecordRuntimeType',
        getMasqueradedRuntimeTypeNullableProcedure, shape, fields);
  }

  Procedure _generateRecordRuntimeTypeHelper(
      String name, Procedure target, RecordShape shape, List<Field> fields) {
    final List<Statement> statements = [];

    // const ImmutableWasmArray(["name1", "name2", ...])
    final fieldNamesList = ConstantExpression(_fieldNamesConstant(shape));

    Expression fieldRuntimeTypeExpr(Field field) => StaticInvocation(
        target,
        Arguments([
          InstanceGet(InstanceAccessKind.Instance, ThisExpression(), field.name,
              interfaceTarget: field, resultType: nullableObjectType)
        ]));

    // WasmArray.literal([_get*RuntimeTypeNullable(this.$1), ...])
    final fieldTypesList = ConstructorInvocation(
        wasmArrayLiteralConstructor,
        Arguments([
          ListLiteral(
            fields.map(fieldRuntimeTypeExpr).toList(),
            typeArgument: runtimeTypeType,
          )
        ], types: [
          runtimeTypeType
        ]));

    statements.add(ReturnStatement(ConstructorInvocation(
        recordRuntimeTypeConstructor,
        Arguments([
          fieldNamesList,
          fieldTypesList,
          BoolLiteral(false), // declared nullable
        ]))));

    final FunctionNode function = FunctionNode(
      Block(statements),
      positionalParameters: [],
      returnType:
          InterfaceType(recordRuntimeTypeClass, Nullability.nonNullable),
    );

    return _addWasmEntryPointPragma(Procedure(
      Name(name, library),
      ProcedureKind.Getter,
      function,
      fileUri: library.fileUri,
    ));
  }

  Constant _fieldNamesConstant(RecordShape shape) {
    return InstanceConstant(immutableWasmArrayClass.reference, [
      nonNullableStringType
    ], {
      immutableWasmArrayValueField.fieldReference: ListConstant(
          nonNullableStringType,
          shape.names.map((name) => StringConstant(name)).toList())
    });
  }
}

class _RecordVisitor extends RecursiveVisitor {
  final _RecordClassGenerator classGenerator;
  final Set<Constant> constantCache = Set.identity();

  _RecordVisitor(this.classGenerator);

  @override
  void visitRecordType(RecordType node) {
    classGenerator.generateClassForRecordType(node);
    super.visitRecordType(node);
  }

  @override
  void defaultConstantReference(Constant node) {
    if (constantCache.add(node)) {
      node.visitChildren(this);
    }
  }
}
