// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Converters and codecs for converting between Protobuf and [Info] classes.

import 'dart:convert';
import 'package:fixnum/fixnum.dart';

import 'info.dart';
import 'src/proto/info.pb.dart';

export 'src/proto/info.pb.dart';

class ProtoToAllInfoConverter extends Converter<AllInfoPB, AllInfo> {
  AllInfo convert(AllInfoPB info) {
    // TODO(lorenvs): Implement this conversion. It is unlikely to to be used
    // by production code since the goal of the proto codec is to consume this
    // information from other languages. However, it is useful for roundtrip
    // testing, so we should support it.
    throw new UnimplementedError('ProtoToAllInfoConverter is not implemented');
  }
}

class AllInfoToProtoConverter extends Converter<AllInfo, AllInfoPB> {
  AllInfoPB convert(AllInfo info) => _convertToAllInfoPB(info);

  static DependencyInfoPB _convertToDependencyInfoPB(DependencyInfo info) {
    return new DependencyInfoPB()
      ..targetId = info.target?.serializedId
      ..mask = info.mask;
  }

  static ParameterInfoPB _convertToParameterInfoPB(ParameterInfo info) {
    return new ParameterInfoPB()
      ..name = info.name
      ..type = info.type
      ..declaredType = info.declaredType;
  }

  static MeasurementsPB _convertToMeasurementsPB(Measurements measurements) {
    final proto = new MeasurementsPB();

    if (measurements.uri != null) {
      proto.sourceFile = measurements.uri.toString();
    }

    measurements.entries.forEach((metric, values) {
      final entryProto = new MeasurementEntryPB()..name = metric.name;

      for (final entry in values) {
        entryProto.values.add(entry.begin);
        entryProto.values.add(entry.end);
      }

      proto.entries.add(entryProto);
    });

    measurements.counters.forEach((metric, value) {
      proto.counters.add(new MeasurementCounterPB()
        ..name = metric.name
        ..value = value);
    });

    return proto;
  }

  static LibraryInfoPB _convertToLibraryInfoPB(LibraryInfo info) {
    final proto = new LibraryInfoPB()..uri = info.uri.toString();

    proto.childrenIds
        .addAll(info.topLevelFunctions.map((func) => func.serializedId));
    proto.childrenIds
        .addAll(info.topLevelVariables.map((field) => field.serializedId));
    proto.childrenIds.addAll(info.classes.map((clazz) => clazz.serializedId));
    proto.childrenIds.addAll(info.typedefs.map((def) => def.serializedId));

    return proto;
  }

  static ClassInfoPB _convertToClassInfoPB(ClassInfo info) {
    final proto = new ClassInfoPB()..isAbstract = info.isAbstract;

    proto.childrenIds.addAll(info.functions.map((func) => func.serializedId));
    proto.childrenIds.addAll(info.fields.map((field) => field.serializedId));

    return proto;
  }

  static FunctionModifiersPB _convertToFunctionModifiers(
      FunctionModifiers modifiers) {
    return new FunctionModifiersPB()
      ..isStatic = modifiers.isStatic
      ..isConst = modifiers.isConst
      ..isFactory = modifiers.isFactory
      ..isExternal = modifiers.isExternal;
  }

  static FunctionInfoPB _convertToFunctionInfoPB(FunctionInfo info) {
    final proto = new FunctionInfoPB()
      ..functionModifiers = _convertToFunctionModifiers(info.modifiers)
      ..inlinedCount = info.inlinedCount ?? 0;

    if (info.returnType != null) {
      proto.returnType = info.returnType;
    }

    if (info.inferredReturnType != null) {
      proto.inferredReturnType = info.inferredReturnType;
    }

    if (info.code != null) {
      proto.code = info.code;
    }

    if (info.sideEffects != null) {
      proto.sideEffects = info.sideEffects;
    }

    if (info.measurements != null) {
      proto.measurements = _convertToMeasurementsPB(info.measurements);
    }

    proto.childrenIds
        .addAll(info.closures.map(((closure) => closure.serializedId)));
    proto.parameters.addAll(info.parameters.map(_convertToParameterInfoPB));

    return proto;
  }

  static FieldInfoPB _convertToFieldInfoPB(FieldInfo info) {
    final proto = new FieldInfoPB()
      ..type = info.type
      ..inferredType = info.inferredType
      ..isConst = info.isConst;

    if (info.code != null) {
      proto.code = info.code;
    }

    if (info.initializer != null) {
      proto.initializerId = info.initializer.serializedId;
    }

    proto.childrenIds
        .addAll(info.closures.map((closure) => closure.serializedId));

    return proto;
  }

  static ConstantInfoPB _convertToConstantInfoPB(ConstantInfo info) {
    return new ConstantInfoPB()..code = info.code;
  }

  static OutputUnitInfoPB _convertToOutputUnitInfoPB(OutputUnitInfo info) {
    final proto = new OutputUnitInfoPB();
    proto.imports.addAll(info.imports.where((import) => import != null));
    return proto;
  }

  static TypedefInfoPB _convertToTypedefInfoPB(TypedefInfo info) {
    return new TypedefInfoPB()..type = info.type;
  }

  static ClosureInfoPB _convertToClosureInfoPB(ClosureInfo info) {
    return new ClosureInfoPB()..functionId = info.function.serializedId;
  }

  static InfoPB _convertToInfoPB(Info info) {
    final proto = new InfoPB()
      ..id = info.id
      ..serializedId = info.serializedId
      ..size = info.size;

    if (info.name != null) {
      proto.name = info.name;
    }

    if (info.parent != null) {
      proto.parentId = info.parent.serializedId;
    }

    if (info.coverageId != null) {
      proto.coverageId = info.coverageId;
    }

    if (info is CodeInfo) {
      proto.uses.addAll(info.uses.map(_convertToDependencyInfoPB));
    }

    if (info is LibraryInfo) {
      proto.libraryInfo = _convertToLibraryInfoPB(info);
    } else if (info is ClassInfo) {
      proto.classInfo = _convertToClassInfoPB(info);
    } else if (info is FunctionInfo) {
      proto.functionInfo = _convertToFunctionInfoPB(info);
    } else if (info is FieldInfo) {
      proto.fieldInfo = _convertToFieldInfoPB(info);
    } else if (info is ConstantInfo) {
      proto.constantInfo = _convertToConstantInfoPB(info);
    } else if (info is OutputUnitInfo) {
      proto.outputUnitInfo = _convertToOutputUnitInfoPB(info);
    } else if (info is TypedefInfo) {
      proto.typedefInfo = _convertToTypedefInfoPB(info);
    } else if (info is ClosureInfo) {
      proto.closureInfo = _convertToClosureInfoPB(info);
    }

    return proto;
  }

  static ProgramInfoPB _convertToProgramInfoPB(ProgramInfo info) {
    return new ProgramInfoPB()
      ..entrypointId = info.entrypoint.serializedId
      ..size = info.size
      ..dart2jsVersion = info.dart2jsVersion
      ..compilationMoment =
          new Int64(info.compilationMoment.microsecondsSinceEpoch)
      ..compilationDuration = new Int64(info.compilationDuration.inMicroseconds)
      ..toProtoDuration = new Int64(info.toJsonDuration.inMicroseconds)
      ..dumpInfoDuration = new Int64(info.dumpInfoDuration.inMicroseconds)
      ..noSuchMethodEnabled = info.noSuchMethodEnabled ?? false
      ..isRuntimeTypeUsed = info.isRuntimeTypeUsed ?? false
      ..isIsolateUsed = info.isIsolateInUse ?? false
      ..isFunctionApplyUsed = info.isFunctionApplyUsed ?? false
      ..isMirrorsUsed = info.isMirrorsUsed ?? false
      ..minified = info.minified ?? false;
  }

  static Iterable<AllInfoPB_AllInfosEntry>
      _convertToAllInfosEntries<T extends Info>(Iterable<T> infos) sync* {
    for (final info in infos) {
      final infoProto = _convertToInfoPB(info);
      final entry = new AllInfoPB_AllInfosEntry()
        ..key = infoProto.serializedId
        ..value = infoProto;
      yield entry;
    }
  }

  static AllInfoPB _convertToAllInfoPB(AllInfo info) {
    final proto = new AllInfoPB()
      ..program = _convertToProgramInfoPB(info.program);

    proto.allInfos.addAll(_convertToAllInfosEntries(info.libraries));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.classes));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.functions));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.fields));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.constants));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.outputUnits));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.typedefs));
    proto.allInfos.addAll(_convertToAllInfosEntries(info.closures));

    return proto;
  }
}

/// A codec for converting [AllInfo] to a protobuf format.
///
/// This codec is still experimental, and will likely crash on certain output
/// from dart2js.
class AllInfoProtoCodec extends Codec<AllInfo, AllInfoPB> {
  final Converter<AllInfo, AllInfoPB> encoder = new AllInfoToProtoConverter();
  final Converter<AllInfoPB, AllInfo> decoder = new ProtoToAllInfoConverter();
}
