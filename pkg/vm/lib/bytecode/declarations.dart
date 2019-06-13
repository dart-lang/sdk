// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.declarations;

import 'package:kernel/ast.dart';
import 'bytecode_serialization.dart'
    show BufferedWriter, BufferedReader, BytecodeSizeStatistics, StringTable;
import 'constant_pool.dart' show ConstantPool;
import 'dbc.dart'
    show currentBytecodeFormatVersion, futureBytecodeFormatVersion;
import 'disassembler.dart' show BytecodeDisassembler;
import 'exceptions.dart' show ExceptionsTable;
import 'local_variable_table.dart' show LocalVariableTable;
import 'object_table.dart' show ObjectTable, ObjectHandle, NameAndType;
import 'source_positions.dart' show SourcePositions;

class Members {
  final List<FieldDeclaration> fields;
  final List<FunctionDeclaration> functions;

  Members(this.fields, this.functions);

  int countFunctions() {
    int count = functions.length;
    for (var field in fields) {
      if ((field.flags & FieldDeclaration.hasGetterFlag) != 0) {
        ++count;
      }
      if ((field.flags & FieldDeclaration.hasSetterFlag) != 0) {
        ++count;
      }
    }
    return count;
  }

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(countFunctions());
    writer.writePackedUInt30(fields.length);
    for (var field in fields) {
      field.write(writer);
    }
    writer.writePackedUInt30(functions.length);
    for (var func in functions) {
      func.write(writer);
    }
  }

  factory Members.read(BufferedReader reader) {
    reader.readPackedUInt30(); // numFunctions
    final fields = new List<FieldDeclaration>.generate(
        reader.readPackedUInt30(), (_) => new FieldDeclaration.read(reader));
    final functions = new List<FunctionDeclaration>.generate(
        reader.readPackedUInt30(), (_) => new FunctionDeclaration.read(reader));
    return new Members(fields, functions);
  }

  @override
  String toString() => "\n"
      "Members {\n"
      "${fields.join('\n')}\n"
      "${functions.join('\n')}"
      "}\n";
}

class FieldDeclaration {
  static const hasInitializerFlag = 1 << 0;
  static const hasGetterFlag = 1 << 1;
  static const hasSetterFlag = 1 << 2;
  static const isReflectableFlag = 1 << 3;
  static const isStaticFlag = 1 << 4;
  static const isConstFlag = 1 << 5;
  static const isFinalFlag = 1 << 6;
  static const isCovariantFlag = 1 << 7;
  static const isGenericCovariantImplFlag = 1 << 8;
  static const hasSourcePositionsFlag = 1 << 9;
  static const hasAnnotationsFlag = 1 << 10;
  static const hasPragmaFlag = 1 << 11;
  static const hasCustomScriptFlag = 1 << 12;

  final int flags;
  final ObjectHandle name;
  final ObjectHandle type;
  final ObjectHandle value;
  final ObjectHandle script;
  final int position;
  final int endPosition;
  final ObjectHandle getterName;
  final ObjectHandle setterName;
  final Code initializerCode;
  final ObjectHandle annotations;

  FieldDeclaration(
      this.flags,
      this.name,
      this.type,
      this.value,
      this.script,
      this.position,
      this.endPosition,
      this.getterName,
      this.setterName,
      this.initializerCode,
      this.annotations);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(flags);
    writer.writePackedObject(name);
    writer.writePackedObject(type);

    if ((flags & hasCustomScriptFlag) != 0) {
      writer.writePackedObject(script);
    }
    if ((flags & hasSourcePositionsFlag) != 0) {
      writer.writePackedUInt30(position + 1);
      writer.writePackedUInt30(endPosition + 1);
    }
    if ((flags & hasInitializerFlag) != 0 && (flags & isStaticFlag) != 0) {
      writer.writeLinkOffset(initializerCode);
    }
    if ((flags & hasInitializerFlag) == 0) {
      writer.writePackedObject(value);
    }
    if ((flags & hasGetterFlag) != 0) {
      writer.writePackedObject(getterName);
    }
    if ((flags & hasSetterFlag) != 0) {
      writer.writePackedObject(setterName);
    }
    if ((flags & hasAnnotationsFlag) != 0) {
      writer.writeLinkOffset(annotations);
    }
  }

  factory FieldDeclaration.read(BufferedReader reader) {
    final flags = reader.readPackedUInt30();
    final name = reader.readPackedObject();
    final type = reader.readPackedObject();
    final script =
        ((flags & hasCustomScriptFlag) != 0) ? reader.readPackedObject() : null;
    final position = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    final endPosition = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    final initializerCode =
        ((flags & hasInitializerFlag) != 0 && (flags & isStaticFlag) != 0)
            ? reader.readLinkOffset<Code>()
            : null;
    final value =
        ((flags & hasInitializerFlag) == 0) ? reader.readPackedObject() : null;
    final getterName =
        ((flags & hasGetterFlag) != 0) ? reader.readPackedObject() : null;
    final setterName =
        ((flags & hasSetterFlag) != 0) ? reader.readPackedObject() : null;
    final annotations = ((flags & hasAnnotationsFlag) != 0)
        ? reader.readLinkOffset<ObjectHandle>()
        : null;
    return new FieldDeclaration(flags, name, type, value, script, position,
        endPosition, getterName, setterName, initializerCode, annotations);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Field $name, type = $type');
    if ((flags & hasGetterFlag) != 0) {
      sb.write(', getter = $getterName');
    }
    if ((flags & hasSetterFlag) != 0) {
      sb.write(', setter = $setterName');
    }
    if ((flags & isReflectableFlag) != 0) {
      sb.write(', reflectable');
    }
    if ((flags & isStaticFlag) != 0) {
      sb.write(', static');
    }
    if ((flags & isConstFlag) != 0) {
      sb.write(', const');
    }
    if ((flags & isFinalFlag) != 0) {
      sb.write(', final');
    }
    if ((flags & hasPragmaFlag) != 0) {
      sb.write(', has-pragma');
    }
    if ((flags & hasCustomScriptFlag) != 0) {
      sb.write(', custom-script = $script');
    }
    if ((flags & hasSourcePositionsFlag) != 0) {
      sb.write(', pos = $position, end-pos = $endPosition');
    }
    sb.writeln();
    if ((flags & hasInitializerFlag) != 0) {
      sb.write('    initializer $initializerCode\n');
    } else {
      sb.write('    value = $value\n');
    }
    if ((flags & hasAnnotationsFlag) != 0) {
      sb.write('    annotations $annotations\n');
    }
    return sb.toString();
  }
}

class FunctionDeclaration {
  static const isConstructorFlag = 1 << 0;
  static const isGetterFlag = 1 << 1;
  static const isSetterFlag = 1 << 2;
  static const isFactoryFlag = 1 << 3;
  static const isStaticFlag = 1 << 4;
  static const isAbstractFlag = 1 << 5;
  static const isConstFlag = 1 << 6;
  static const hasOptionalPositionalParamsFlag = 1 << 7;
  static const hasOptionalNamedParamsFlag = 1 << 8;
  static const hasTypeParamsFlag = 1 << 9;
  static const isReflectableFlag = 1 << 10;
  static const isDebuggableFlag = 1 << 11;
  static const isAsyncFlag = 1 << 12;
  static const isAsyncStarFlag = 1 << 13;
  static const isSyncStarFlag = 1 << 14;
  static const isForwardingStubFlag = 1 << 15;
  static const isNoSuchMethodForwarderFlag = 1 << 16;
  static const isNativeFlag = 1 << 17;
  static const isExternalFlag = 1 << 18;
  static const hasSourcePositionsFlag = 1 << 19;
  static const hasAnnotationsFlag = 1 << 20;
  static const hasPragmaFlag = 1 << 21;
  static const hasCustomScriptFlag = 1 << 22;

  final int flags;
  final ObjectHandle name;
  final ObjectHandle script;
  final int position;
  final int endPosition;
  final TypeParametersDeclaration typeParameters;
  final int numRequiredParameters;
  final List<ParameterDeclaration> parameters;
  final ObjectHandle returnType;
  final ObjectHandle nativeName;
  final Code code;
  final ObjectHandle annotations;

  FunctionDeclaration(
      this.flags,
      this.name,
      this.script,
      this.position,
      this.endPosition,
      this.typeParameters,
      this.numRequiredParameters,
      this.parameters,
      this.returnType,
      this.nativeName,
      this.code,
      this.annotations);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(flags);
    writer.writePackedObject(name);
    if ((flags & hasCustomScriptFlag) != 0) {
      writer.writePackedObject(script);
    }
    if ((flags & hasSourcePositionsFlag) != 0) {
      writer.writePackedUInt30(position + 1);
      writer.writePackedUInt30(endPosition + 1);
    }
    if ((flags & hasTypeParamsFlag) != 0) {
      typeParameters.write(writer);
    }
    writer.writePackedUInt30(parameters.length);
    if ((flags & hasOptionalPositionalParamsFlag) != 0 ||
        (flags & hasOptionalNamedParamsFlag) != 0) {
      writer.writePackedUInt30(numRequiredParameters);
    }
    for (var param in parameters) {
      param.write(writer);
    }
    writer.writePackedObject(returnType);
    if ((flags & isNativeFlag) != 0) {
      writer.writePackedObject(nativeName);
    }
    if ((flags & isAbstractFlag) == 0) {
      writer.writeLinkOffset(code);
    }
    if ((flags & hasAnnotationsFlag) != 0) {
      writer.writeLinkOffset(annotations);
    }
  }

  factory FunctionDeclaration.read(BufferedReader reader) {
    final flags = reader.readPackedUInt30();
    final name = reader.readPackedObject();

    final script =
        ((flags & hasCustomScriptFlag) != 0) ? reader.readPackedObject() : null;
    final position = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    final endPosition = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    final typeParameters = ((flags & hasTypeParamsFlag) != 0)
        ? new TypeParametersDeclaration.read(reader)
        : null;

    final numParameters = reader.readPackedUInt30();
    final numRequiredParameters =
        ((flags & hasOptionalPositionalParamsFlag) != 0 ||
                (flags & hasOptionalNamedParamsFlag) != 0)
            ? reader.readPackedUInt30()
            : numParameters;

    final parameters = new List<ParameterDeclaration>.generate(
        numParameters, (_) => new ParameterDeclaration.read(reader));
    final returnType = reader.readPackedObject();
    final nativeName =
        ((flags & isNativeFlag) != 0) ? reader.readPackedObject() : null;
    final code =
        ((flags & isAbstractFlag) == 0) ? reader.readLinkOffset<Code>() : null;
    final annotations = ((flags & hasAnnotationsFlag) != 0)
        ? reader.readLinkOffset<ObjectHandle>()
        : null;
    return new FunctionDeclaration(
        flags,
        name,
        script,
        position,
        endPosition,
        typeParameters,
        numRequiredParameters,
        parameters,
        returnType,
        nativeName,
        code,
        annotations);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Function $name');
    if ((flags & isConstructorFlag) != 0) {
      sb.write(', constructor');
    }
    if ((flags & isGetterFlag) != 0) {
      sb.write(', getter');
    }
    if ((flags & isSetterFlag) != 0) {
      sb.write(', setter');
    }
    if ((flags & isFactoryFlag) != 0) {
      sb.write(', factory');
    }
    if ((flags & isStaticFlag) != 0) {
      sb.write(', static');
    }
    if ((flags & isAbstractFlag) != 0) {
      sb.write(', abstract');
    }
    if ((flags & isConstFlag) != 0) {
      sb.write(', const');
    }
    if ((flags & hasOptionalPositionalParamsFlag) != 0) {
      sb.write(', has-optional-positional-params');
    }
    if ((flags & hasOptionalNamedParamsFlag) != 0) {
      sb.write(', has-optional-named-params');
    }
    if ((flags & isReflectableFlag) != 0) {
      sb.write(', reflectable');
    }
    if ((flags & isDebuggableFlag) != 0) {
      sb.write(', debuggable');
    }
    if ((flags & isAsyncFlag) != 0) {
      sb.write(', async');
    }
    if ((flags & isAsyncStarFlag) != 0) {
      sb.write(', async*');
    }
    if ((flags & isSyncStarFlag) != 0) {
      sb.write(', sync*');
    }
    if ((flags & isForwardingStubFlag) != 0) {
      sb.write(', forwarding-stub');
    }
    if ((flags & isNoSuchMethodForwarderFlag) != 0) {
      sb.write(', no-such-method-forwarder');
    }
    if ((flags & isNativeFlag) != 0) {
      sb.write(', native $nativeName');
    }
    if ((flags & isExternalFlag) != 0) {
      sb.write(', external');
    }
    if ((flags & hasPragmaFlag) != 0) {
      sb.write(', has-pragma');
    }
    if ((flags & hasCustomScriptFlag) != 0) {
      sb.write(', custom-script = $script');
    }
    if ((flags & hasSourcePositionsFlag) != 0) {
      sb.write(', pos = $position, end-pos = $endPosition');
    }
    sb.writeln();
    if ((flags & hasTypeParamsFlag) != 0) {
      sb.write('    type-params $typeParameters\n');
    }
    sb.write('    parameters $parameters (required: $numRequiredParameters)\n');
    sb.write('    return-type $returnType\n');
    if ((flags & hasAnnotationsFlag) != 0) {
      sb.write('    annotations $annotations\n');
    }
    if ((flags & isAbstractFlag) == 0 && (flags & isExternalFlag) == 0) {
      sb.write('\n$code\n');
    }
    return sb.toString();
  }
}

class TypeParametersDeclaration {
  final List<NameAndType> typeParams;

  TypeParametersDeclaration(this.typeParams);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(typeParams.length);
    for (var tp in typeParams) {
      writer.writePackedObject(tp.name);
    }
    for (var tp in typeParams) {
      writer.writePackedObject(tp.type);
    }
  }

  factory TypeParametersDeclaration.read(BufferedReader reader) {
    final int numTypeParams = reader.readPackedUInt30();
    List<ObjectHandle> names = new List<ObjectHandle>.generate(
        numTypeParams, (_) => reader.readPackedObject());
    List<ObjectHandle> bounds = new List<ObjectHandle>.generate(
        numTypeParams, (_) => reader.readPackedObject());
    return new TypeParametersDeclaration(new List<NameAndType>.generate(
        numTypeParams, (int i) => new NameAndType(names[i], bounds[i])));
  }

  @override
  int get hashCode => listHashCode(typeParams);

  @override
  bool operator ==(other) =>
      other is TypeParametersDeclaration &&
      listEquals(this.typeParams, other.typeParams);

  @override
  String toString() => '<${typeParams.join(', ')}>';
}

class ParameterDeclaration {
  // Parameter flags are written separately (in Code).
  static const isCovariantFlag = 1 << 0;
  static const isGenericCovariantImplFlag = 1 << 1;

  final ObjectHandle name;
  final ObjectHandle type;

  ParameterDeclaration(this.name, this.type);

  void write(BufferedWriter writer) {
    writer.writePackedObject(name);
    writer.writePackedObject(type);
  }

  factory ParameterDeclaration.read(BufferedReader reader) {
    final name = reader.readPackedObject();
    final type = reader.readPackedObject();
    return new ParameterDeclaration(name, type);
  }

  @override
  String toString() => '$type $name';
}

class Code {
  static const hasExceptionsTableFlag = 1 << 0;
  static const hasSourcePositionsFlag = 1 << 1;
  static const hasNullableFieldsFlag = 1 << 2;
  static const hasClosuresFlag = 1 << 3;
  static const hasParameterFlagsFlag = 1 << 4;
  static const hasForwardingStubTargetFlag = 1 << 5;
  static const hasDefaultFunctionTypeArgsFlag = 1 << 6;
  static const hasLocalVariablesFlag = 1 << 7;

  final ConstantPool constantPool;
  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final SourcePositions sourcePositions;
  final LocalVariableTable localVariables;
  final List<ObjectHandle> nullableFields;
  final List<ClosureDeclaration> closures;
  final List<int> parameterFlags;
  final int forwardingStubTargetCpIndex;
  final int defaultFunctionTypeArgsCpIndex;

  bool get hasExceptionsTable => exceptionsTable.blocks.isNotEmpty;
  bool get hasSourcePositions =>
      sourcePositions != null && sourcePositions.mapping.isNotEmpty;
  bool get hasLocalVariables =>
      localVariables != null && localVariables.isNotEmpty;
  bool get hasNullableFields => nullableFields.isNotEmpty;
  bool get hasClosures => closures.isNotEmpty;

  int get flags =>
      (hasExceptionsTable ? hasExceptionsTableFlag : 0) |
      (hasSourcePositions ? hasSourcePositionsFlag : 0) |
      (hasNullableFields ? hasNullableFieldsFlag : 0) |
      (hasClosures ? hasClosuresFlag : 0) |
      (parameterFlags != null ? hasParameterFlagsFlag : 0) |
      (forwardingStubTargetCpIndex != null ? hasForwardingStubTargetFlag : 0) |
      (defaultFunctionTypeArgsCpIndex != null
          ? hasDefaultFunctionTypeArgsFlag
          : 0) |
      (hasLocalVariables ? hasLocalVariablesFlag : 0);

  Code(
      this.constantPool,
      this.bytecodes,
      this.exceptionsTable,
      this.sourcePositions,
      this.localVariables,
      this.nullableFields,
      this.closures,
      this.parameterFlags,
      this.forwardingStubTargetCpIndex,
      this.defaultFunctionTypeArgsCpIndex);

  void write(BufferedWriter writer) {
    final start = writer.offset;
    writer.writePackedUInt30(flags);
    if (parameterFlags != null) {
      writer.writePackedUInt30(parameterFlags.length);
      parameterFlags.forEach((flags) => writer.writePackedUInt30(flags));
    }
    if (forwardingStubTargetCpIndex != null) {
      writer.writePackedUInt30(forwardingStubTargetCpIndex);
    }
    if (defaultFunctionTypeArgsCpIndex != null) {
      writer.writePackedUInt30(defaultFunctionTypeArgsCpIndex);
    }
    if (hasClosures) {
      writer.writePackedUInt30(closures.length);
      closures.forEach((c) => c.write(writer));
    }
    constantPool.write(writer);
    _writeBytecodeInstructions(writer, bytecodes);
    if (hasExceptionsTable) {
      exceptionsTable.write(writer);
    }
    if (hasSourcePositions) {
      writer.writeLinkOffset(sourcePositions);
    }
    if (hasLocalVariables) {
      writer.writeLinkOffset(localVariables);
    }
    if (hasNullableFields) {
      writer.writePackedList(nullableFields);
    }
    if (hasClosures) {
      closures.forEach((c) => c.code.write(writer));
    }
    BytecodeSizeStatistics.membersSize += (writer.offset - start);
  }

  factory Code.read(BufferedReader reader) {
    int flags = reader.readPackedUInt30();
    final parameterFlags = ((flags & hasParameterFlagsFlag) != 0)
        ? new List<int>.generate(
            reader.readPackedUInt30(), (_) => reader.readPackedUInt30())
        : null;
    final forwardingStubTargetCpIndex =
        ((flags & hasForwardingStubTargetFlag) != 0)
            ? reader.readPackedUInt30()
            : null;
    final defaultFunctionTypeArgsCpIndex =
        ((flags & hasDefaultFunctionTypeArgsFlag) != 0)
            ? reader.readPackedUInt30()
            : null;
    final List<ClosureDeclaration> closures = ((flags & hasClosuresFlag) != 0)
        ? new List<ClosureDeclaration>.generate(reader.readPackedUInt30(),
            (_) => new ClosureDeclaration.read(reader))
        : const <ClosureDeclaration>[];
    final ConstantPool constantPool = new ConstantPool.read(reader);
    final List<int> bytecodes = _readBytecodeInstructions(reader);
    final exceptionsTable = ((flags & hasExceptionsTableFlag) != 0)
        ? new ExceptionsTable.read(reader)
        : new ExceptionsTable();
    final sourcePositions = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readLinkOffset<SourcePositions>()
        : null;
    final localVariables = ((flags & hasLocalVariablesFlag) != 0)
        ? reader.readLinkOffset<LocalVariableTable>()
        : null;
    final List<ObjectHandle> nullableFields =
        ((flags & hasNullableFieldsFlag) != 0)
            ? reader.readPackedList<ObjectHandle>()
            : const <ObjectHandle>[];
    for (var c in closures) {
      c.code = new ClosureCode.read(reader);
    }
    return new Code(
        constantPool,
        bytecodes,
        exceptionsTable,
        sourcePositions,
        localVariables,
        nullableFields,
        closures,
        parameterFlags,
        forwardingStubTargetCpIndex,
        defaultFunctionTypeArgsCpIndex);
  }

  // TODO(alexmarkov): Consider printing constant pool before bytecode.
  @override
  String toString() => "\n"
      "Bytecode {\n"
      "${new BytecodeDisassembler().disassemble(bytecodes, exceptionsTable, annotations: [
        hasSourcePositions
            ? sourcePositions.getBytecodeAnnotations()
            : const <int, String>{},
        hasLocalVariables
            ? localVariables.getBytecodeAnnotations()
            : const <int, String>{}
      ])}}\n"
      "$exceptionsTable"
      "${nullableFields.isEmpty ? '' : 'Nullable fields: $nullableFields\n'}"
      "${parameterFlags == null ? '' : 'Parameter flags: $parameterFlags\n'}"
      "${forwardingStubTargetCpIndex == null ? '' : 'Forwarding stub target: CP#$forwardingStubTargetCpIndex\n'}"
      "${defaultFunctionTypeArgsCpIndex == null ? '' : 'Default function type arguments: CP#$defaultFunctionTypeArgsCpIndex\n'}"
      "$constantPool"
      "${closures.join('\n')}";
}

class ClosureDeclaration {
  static const int hasOptionalPositionalParamsFlag = 1 << 0;
  static const int hasOptionalNamedParamsFlag = 1 << 1;
  static const int hasTypeParamsFlag = 1 << 2;
  static const int hasSourcePositionsFlag = 1 << 3;

  final ObjectHandle parent;
  final ObjectHandle name;
  final int position;
  final int endPosition;
  final List<NameAndType> typeParams;
  final int numRequiredParams;
  final int numNamedParams;
  final List<NameAndType> parameters;
  final ObjectHandle returnType;
  ClosureCode code;

  ClosureDeclaration(
      this.parent,
      this.name,
      this.position,
      this.endPosition,
      this.typeParams,
      this.numRequiredParams,
      this.numNamedParams,
      this.parameters,
      this.returnType);

  void write(BufferedWriter writer) {
    int flags = 0;
    if (numRequiredParams != parameters.length) {
      if (numNamedParams > 0) {
        flags |= hasOptionalNamedParamsFlag;
      } else {
        flags |= hasOptionalPositionalParamsFlag;
      }
    }
    if (typeParams.isNotEmpty) {
      flags |= hasTypeParamsFlag;
    }
    if (position != TreeNode.noOffset) {
      flags |= hasSourcePositionsFlag;
    }
    writer.writePackedUInt30(flags);
    writer.writePackedObject(parent);
    writer.writePackedObject(name);

    if (flags & hasSourcePositionsFlag != 0) {
      writer.writePackedUInt30(position + 1);
      writer.writePackedUInt30(endPosition + 1);
    }

    if (flags & hasTypeParamsFlag != 0) {
      writer.writePackedUInt30(typeParams.length);
      for (var tp in typeParams) {
        writer.writePackedObject(tp.name);
      }
      for (var tp in typeParams) {
        writer.writePackedObject(tp.type);
      }
    }
    writer.writePackedUInt30(parameters.length);
    if (flags &
            (hasOptionalPositionalParamsFlag | hasOptionalNamedParamsFlag) !=
        0) {
      writer.writePackedUInt30(numRequiredParams);
    }
    for (var param in parameters) {
      writer.writePackedObject(param.name);
      writer.writePackedObject(param.type);
    }
    writer.writePackedObject(returnType);
  }

  factory ClosureDeclaration.read(BufferedReader reader) {
    final int flags = reader.readPackedUInt30();
    final parent = reader.readPackedObject();
    final name = reader.readPackedObject();
    final position = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    final endPosition = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readPackedUInt30() - 1
        : TreeNode.noOffset;
    List<NameAndType> typeParams;
    if ((flags & hasTypeParamsFlag) != 0) {
      final int numTypeParams = reader.readPackedUInt30();
      List<ObjectHandle> names = new List<ObjectHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      List<ObjectHandle> bounds = new List<ObjectHandle>.generate(
          numTypeParams, (_) => reader.readPackedObject());
      typeParams = new List<NameAndType>.generate(
          numTypeParams, (int i) => new NameAndType(names[i], bounds[i]));
    } else {
      typeParams = const <NameAndType>[];
    }
    final numParams = reader.readPackedUInt30();
    final numRequiredParams = (flags &
                (hasOptionalPositionalParamsFlag |
                    hasOptionalNamedParamsFlag) !=
            0)
        ? reader.readPackedUInt30()
        : numParams;
    final numNamedParams = (flags & hasOptionalNamedParamsFlag != 0)
        ? (numParams - numRequiredParams)
        : 0;
    final List<NameAndType> parameters = new List<NameAndType>.generate(
        numParams,
        (_) => new NameAndType(
            reader.readPackedObject(), reader.readPackedObject()));
    final returnType = reader.readPackedObject();
    return new ClosureDeclaration(parent, name, position, endPosition,
        typeParams, numRequiredParams, numNamedParams, parameters, returnType);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Closure $parent::$name');
    if (position != TreeNode.noOffset) {
      sb.write(' pos = $position, end-pos = $endPosition');
    }
    if (typeParams.isNotEmpty) {
      sb.write(' <${typeParams.join(', ')}>');
    }
    sb.write(' (');
    sb.write(parameters.sublist(0, numRequiredParams).join(', '));
    if (numRequiredParams != parameters.length) {
      if (numRequiredParams > 0) {
        sb.write(', ');
      }
      if (numNamedParams > 0) {
        sb.write('{ ${parameters.sublist(numRequiredParams).join(', ')} }');
      } else {
        sb.write('[ ${parameters.sublist(numRequiredParams).join(', ')} ]');
      }
    }
    sb.write(') -> ');
    sb.writeln(returnType);
    if (code != null) {
      sb.write(code.toString());
    }
    return sb.toString();
  }
}

/// Bytecode of a nested function (closure).
/// Closures share the constant pool of a top-level member.
class ClosureCode {
  static const hasExceptionsTableFlag = 1 << 0;
  static const hasSourcePositionsFlag = 1 << 1;
  static const hasLocalVariablesFlag = 1 << 2;

  final List<int> bytecodes;
  final ExceptionsTable exceptionsTable;
  final SourcePositions sourcePositions;
  final LocalVariableTable localVariables;

  bool get hasExceptionsTable => exceptionsTable.blocks.isNotEmpty;
  bool get hasSourcePositions =>
      sourcePositions != null && sourcePositions.mapping.isNotEmpty;
  bool get hasLocalVariables =>
      localVariables != null && localVariables.isNotEmpty;

  int get flags =>
      (hasExceptionsTable ? hasExceptionsTableFlag : 0) |
      (hasSourcePositions ? hasSourcePositionsFlag : 0) |
      (hasLocalVariables ? hasLocalVariablesFlag : 0);

  ClosureCode(this.bytecodes, this.exceptionsTable, this.sourcePositions,
      this.localVariables);

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(flags);
    _writeBytecodeInstructions(writer, bytecodes);
    if (hasExceptionsTable) {
      exceptionsTable.write(writer);
    }
    if (hasSourcePositions) {
      writer.writeLinkOffset(sourcePositions);
    }
    if (hasLocalVariables) {
      writer.writeLinkOffset(localVariables);
    }
  }

  factory ClosureCode.read(BufferedReader reader) {
    final int flags = reader.readPackedUInt30();
    final List<int> bytecodes = _readBytecodeInstructions(reader);
    final exceptionsTable = ((flags & hasExceptionsTableFlag) != 0)
        ? new ExceptionsTable.read(reader)
        : new ExceptionsTable();
    final sourcePositions = ((flags & hasSourcePositionsFlag) != 0)
        ? reader.readLinkOffset<SourcePositions>()
        : null;
    final localVariables = ((flags & hasLocalVariablesFlag) != 0)
        ? reader.readLinkOffset<LocalVariableTable>()
        : null;
    return new ClosureCode(
        bytecodes, exceptionsTable, sourcePositions, localVariables);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln('ClosureCode {');
    sb.writeln(new BytecodeDisassembler()
        .disassemble(bytecodes, exceptionsTable, annotations: [
      hasSourcePositions
          ? sourcePositions.getBytecodeAnnotations()
          : const <int, String>{},
      hasLocalVariables
          ? localVariables.getBytecodeAnnotations()
          : const <int, String>{}
    ]));
    sb.writeln('}');
    return sb.toString();
  }
}

class _Section {
  int numItems;
  int offset;
  BufferedWriter writer;

  _Section(this.numItems, this.writer);

  int get size => writer.offset;
}

class Component {
  static const int magicValue = 0x44424332; // 'DBC2'
  static const int numSections = 8;
  static const int sectionAlignment = 4;

  //  UInt32 magic, version, numSections x (numItems, offset)
  static const int headerSize = (2 + numSections * 2) * 4;

  int version;
  StringTable stringTable;
  ObjectTable objectTable;
  List<Members> members = <Members>[];
  List<Code> codes = <Code>[];
  List<SourcePositions> sourcePositions = <SourcePositions>[];
  List<LocalVariableTable> localVariables = <LocalVariableTable>[];
  List<ObjectHandle> annotations = <ObjectHandle>[];
  ObjectHandle mainLibrary;

  Component(this.version)
      : stringTable = new StringTable(),
        objectTable = new ObjectTable();

  void write(BufferedWriter writer) {
    objectTable.allocateIndexTable();

    // Write sections to their own buffers in reverse order as section may
    // reference data structures from successor sections by offsets.

    final BufferedWriter annotationsWriter =
        new BufferedWriter.fromWriter(writer);
    for (var annot in annotations) {
      writer.linkWriter.put(annot, annotationsWriter.offset);
      annotationsWriter.writePackedObject(annot);
    }

    final BufferedWriter localVariablesWriter =
        new BufferedWriter.fromWriter(writer);
    for (var lv in localVariables) {
      writer.linkWriter.put(lv, localVariablesWriter.offset);
      lv.write(localVariablesWriter);
    }

    final BufferedWriter sourcePositionsWriter =
        new BufferedWriter.fromWriter(writer);
    for (var sp in sourcePositions) {
      writer.linkWriter.put(sp, sourcePositionsWriter.offset);
      sp.write(sourcePositionsWriter);
    }

    final BufferedWriter codesWriter = new BufferedWriter.fromWriter(writer);
    for (var code in codes) {
      writer.linkWriter.put(code, codesWriter.offset);
      code.write(codesWriter);
    }

    final BufferedWriter membersWriter = new BufferedWriter.fromWriter(writer);
    for (var m in members) {
      writer.linkWriter.put(m, membersWriter.offset);
      m.write(membersWriter);
    }

    BufferedWriter mainWriter;
    if (mainLibrary != null) {
      mainWriter = new BufferedWriter.fromWriter(writer);
      mainWriter.writePackedObject(mainLibrary);
    }

    final BufferedWriter objectsWriter = new BufferedWriter.fromWriter(writer);
    objectTable.write(objectsWriter);

    final BufferedWriter stringsWriter = new BufferedWriter.fromWriter(writer);
    stringTable.write(stringsWriter);

    List<_Section> sections = [
      new _Section(0, stringsWriter),
      new _Section(0, objectsWriter),
      new _Section(0, mainWriter),
      new _Section(members.length, membersWriter),
      new _Section(codes.length, codesWriter),
      new _Section(sourcePositions.length, sourcePositionsWriter),
      new _Section(localVariables.length, localVariablesWriter),
      new _Section(annotations.length, annotationsWriter),
    ];
    assert(sections.length == numSections);

    int offset = headerSize;
    for (var section in sections) {
      if (section.writer != null) {
        offset = (offset + sectionAlignment - 1) & ~(sectionAlignment - 1);
        section.offset = offset;
        offset += section.size;
      } else {
        section.offset = 0;
      }
    }

    final start = writer.offset;

    writer.writeUInt32(magicValue);
    writer.writeUInt32(version);
    for (var section in sections) {
      writer.writeUInt32(section.numItems);
      writer.writeUInt32(section.offset);
    }
    assert(writer.offset - start == headerSize);
    for (var section in sections) {
      if (section.writer != null) {
        writer.align(sectionAlignment);
        assert(writer.offset - start == section.offset);
        writer.writeBytes(section.writer.takeBytes());
      }
    }

    BytecodeSizeStatistics.componentSize += (writer.offset - start);
  }

  Component.read(BufferedReader reader) {
    final int start = reader.offset;

    final int magic = reader.readUInt32();
    if (magic != magicValue) {
      throw 'Error: unexpected bytecode magic $magic';
    }

    version = reader.readUInt32();
    if (version != currentBytecodeFormatVersion) {
      throw 'Error: unexpected bytecode format version $version';
    }

    reader.formatVersion = version;

    reader.readUInt32();
    final stringTableOffset = reader.readUInt32();

    reader.readUInt32();
    final objectTableOffset = reader.readUInt32();

    reader.readUInt32();
    final mainOffset = reader.readUInt32();

    final membersNum = reader.readUInt32();
    final membersOffset = reader.readUInt32();

    final codesNum = reader.readUInt32();
    final codesOffset = reader.readUInt32();

    final sourcePositionsNum = reader.readUInt32();
    final sourcePositionsOffset = reader.readUInt32();

    final localVariablesNum = reader.readUInt32();
    final localVariablesOffset = reader.readUInt32();

    final annotationsNum = reader.readUInt32();
    final annotationsOffset = reader.readUInt32();

    reader.offset = start + stringTableOffset;
    stringTable = new StringTable.read(reader);
    reader.stringReader = stringTable;

    reader.offset = start + objectTableOffset;
    objectTable = new ObjectTable.read(reader);
    reader.objectReader = objectTable;

    // Read sections in the reverse order as section may reference
    // successor sections by offsets.

    final annotationsStart = start + annotationsOffset;
    reader.offset = annotationsStart;
    for (int i = 0; i < annotationsNum; ++i) {
      int offset = reader.offset - annotationsStart;
      ObjectHandle annot = reader.readPackedObject();
      reader.linkReader.setOffset(annot, offset);
      annotations.add(annot);
    }

    final sourcePositionsStart = start + sourcePositionsOffset;
    reader.offset = sourcePositionsStart;
    for (int i = 0; i < sourcePositionsNum; ++i) {
      int offset = reader.offset - sourcePositionsStart;
      SourcePositions sp = new SourcePositions.read(reader);
      reader.linkReader.setOffset(sp, offset);
      sourcePositions.add(sp);
    }

    final localVariablesStart = start + localVariablesOffset;
    reader.offset = localVariablesStart;
    for (int i = 0; i < localVariablesNum; ++i) {
      int offset = reader.offset - localVariablesStart;
      LocalVariableTable lv = new LocalVariableTable.read(reader);
      reader.linkReader.setOffset(lv, offset);
      localVariables.add(lv);
    }

    final codesStart = start + codesOffset;
    reader.offset = codesStart;
    for (int i = 0; i < codesNum; ++i) {
      int offset = reader.offset - codesStart;
      Code code = new Code.read(reader);
      reader.linkReader.setOffset(code, offset);
      codes.add(code);
    }

    final membersStart = start + membersOffset;
    reader.offset = membersStart;
    for (int i = 0; i < membersNum; ++i) {
      int offset = reader.offset - membersStart;
      Members m = new Members.read(reader);
      reader.linkReader.setOffset(m, offset);
      members.add(m);
    }

    if (mainOffset != 0) {
      reader.offset = start + mainOffset;
      mainLibrary = reader.readPackedObject();
    }
  }

  String toString() => "\n"
      "Bytecode"
      " (version: "
      "${version == currentBytecodeFormatVersion ? 'stable' : version == futureBytecodeFormatVersion ? 'future' : "v$version"}"
      ")\n"
//      "$objectTable\n"
//      "$stringTable\n"
      "${mainLibrary != null ? 'Main library: $mainLibrary\n' : ''}"
//      "${members.join('\n')}\n"
      ;
}

void _writeBytecodeInstructions(BufferedWriter writer, List<int> bytecodes) {
  writer.writePackedUInt30(bytecodes.length);
  writer.writeBytes(bytecodes);
  BytecodeSizeStatistics.instructionsSize += bytecodes.length;
}

List<int> _readBytecodeInstructions(BufferedReader reader) {
  int len = reader.readPackedUInt30();
  return reader.readBytesAsUint8List(len);
}
