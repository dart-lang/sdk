// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Info serialization to a binary form.
///
/// Unlike the JSON codec, this serialization is designed to be streamed.

import 'dart:convert';

import 'src/binary/sink.dart';
import 'src/binary/source.dart';
import 'info.dart';

void encode(AllInfo info, Sink<List<int>> sink) {
  new BinaryPrinter(new BinarySink(sink)).visitAll(info);
}

AllInfo decode(List<int> data) {
  return new BinaryReader(new BinarySource(data)).readAll();
}

class BinaryPrinter implements InfoVisitor<void> {
  final BinarySink sink;

  BinaryPrinter(this.sink);

  void writeDate(DateTime date) {
    sink.writeString(date.toIso8601String());
  }

  void writeDuration(Duration duration) {
    sink.writeInt(duration.inMicroseconds);
  }

  void writeInfoWithKind(Info info) {
    sink.writeEnum(info.kind);
    info.accept(this);
  }

  void visitAll(AllInfo info) {
    sink.writeInt(info.version);
    sink.writeInt(info.minorVersion);
    sink.writeList(info.libraries, visitLibrary);
    // TODO(sigmund): synthesize the following lists instead of serializing the
    // values again.
    sink.writeList(info.classes, visitClass);
    sink.writeList(info.functions, visitFunction);
    sink.writeList(info.typedefs, visitTypedef);
    sink.writeList(info.fields, visitField);
    sink.writeList(info.constants, visitConstant);
    sink.writeList(info.closures, visitClosure);

    void writeDependencies(CodeInfo info) {
      sink.writeList(info.uses, _writeDependencyInfo);
    }

    info.fields.forEach(writeDependencies);
    info.functions.forEach(writeDependencies);

    sink.writeInt(info.dependencies.length);
    info.dependencies.forEach((Info key, List<Info> values) {
      writeInfoWithKind(key);
      sink.writeList(values, writeInfoWithKind);
    });
    sink.writeList(info.outputUnits, visitOutput);
    sink.writeString(jsonEncode(info.deferredFiles));
    visitProgram(info.program);
    sink.close();
  }

  void visitProgram(ProgramInfo info) {
    visitFunction(info.entrypoint);
    sink.writeInt(info.size);
    sink.writeStringOrNull(info.dart2jsVersion);
    writeDate(info.compilationMoment);
    writeDuration(info.compilationDuration);
    // Note: we don't record the 'toJsonDuration' field. Consider deleting it?
    writeDuration(info.dumpInfoDuration);
    sink.writeBool(info.noSuchMethodEnabled);
    sink.writeBool(info.isRuntimeTypeUsed);
    sink.writeBool(info.isIsolateInUse);
    sink.writeBool(info.isFunctionApplyUsed);
    sink.writeBool(info.isMirrorsUsed);
    sink.writeBool(info.minified);
  }

  void _visitBasicInfo(BasicInfo info) {
    sink.writeStringOrNull(info.name);
    sink.writeInt(info.size);
    sink.writeStringOrNull(info.coverageId);
    _writeOutputOrNull(info.outputUnit);
    // Note: parent-pointers are not serialized, they get deduced during deserialization.
  }

  void visitLibrary(LibraryInfo library) {
    sink.writeCached(library, (LibraryInfo info) {
      sink.writeUri(info.uri);
      _visitBasicInfo(info);
      sink.writeList(info.topLevelFunctions, visitFunction);
      sink.writeList(info.topLevelVariables, visitField);
      sink.writeList(info.classes, visitClass);
      sink.writeList(info.typedefs, visitTypedef);
    });
  }

  void visitClass(ClassInfo cls) {
    sink.writeCached(cls, (ClassInfo info) {
      _visitBasicInfo(info);
      sink.writeBool(info.isAbstract);
      sink.writeList(info.fields, visitField);
      sink.writeList(info.functions, visitFunction);
    });
  }

  void visitField(FieldInfo field) {
    sink.writeCached(field, (FieldInfo info) {
      _visitBasicInfo(info);
      sink.writeList(info.closures, visitClosure);
      sink.writeString(info.inferredType);
      sink.writeList(info.code, _visitCodeSpan);
      sink.writeString(info.type);
      sink.writeBool(info.isConst);
      if (info.isConst) {
        _writeConstantOrNull(info.initializer);
      }
    });
  }

  _visitCodeSpan(CodeSpan code) {
    sink.writeIntOrNull(code.start);
    sink.writeIntOrNull(code.end);
    sink.writeStringOrNull(code.text);
  }

  void _writeConstantOrNull(ConstantInfo info) {
    sink.writeBool(info != null);
    if (info != null) {
      visitConstant(info);
    }
  }

  void visitConstant(ConstantInfo constant) {
    sink.writeCached(constant, (ConstantInfo info) {
      _visitBasicInfo(info);
      sink.writeList(info.code, _visitCodeSpan);
    });
  }

  void _visitFunctionModifiers(FunctionModifiers mods) {
    int value = 0;
    if (mods.isStatic) value |= _staticMask;
    if (mods.isConst) value |= _constMask;
    if (mods.isFactory) value |= _factoryMask;
    if (mods.isExternal) value |= _externalMask;
    sink.writeInt(value);
  }

  void _visitParameterInfo(ParameterInfo info) {
    sink.writeString(info.name);
    sink.writeString(info.type);
    sink.writeString(info.declaredType);
  }

  void visitFunction(FunctionInfo function) {
    sink.writeCached(function, (FunctionInfo info) {
      _visitBasicInfo(info);
      sink.writeList(info.closures, visitClosure);
      _visitFunctionModifiers(info.modifiers);
      sink.writeString(info.returnType);
      sink.writeString(info.inferredReturnType);
      sink.writeList(info.parameters, _visitParameterInfo);
      sink.writeString(info.sideEffects);
      sink.writeIntOrNull(info.inlinedCount);
      sink.writeList(info.code, _visitCodeSpan);
      sink.writeString(info.type);
    });
  }

  void _writeDependencyInfo(DependencyInfo info) {
    writeInfoWithKind(info.target);
    sink.writeStringOrNull(info.mask);
  }

  void visitClosure(ClosureInfo closure) {
    sink.writeCached(closure, (ClosureInfo info) {
      _visitBasicInfo(info);
      visitFunction(info.function);
    });
  }

  void visitTypedef(TypedefInfo typedef) {
    sink.writeCached(typedef, (TypedefInfo info) {
      _visitBasicInfo(info);
      sink.writeString(info.type);
    });
  }

  void _writeOutputOrNull(OutputUnitInfo info) {
    sink.writeBool(info != null);
    if (info != null) {
      visitOutput(info);
    }
  }

  void visitOutput(OutputUnitInfo output) {
    sink.writeCached(output, (OutputUnitInfo info) {
      _visitBasicInfo(info);
      sink.writeStringOrNull(info.filename);
      sink.writeList(info.imports, sink.writeString);
    });
  }
}

class BinaryReader {
  final BinarySource source;
  BinaryReader(this.source);

  DateTime readDate() {
    return DateTime.parse(source.readString());
  }

  Duration readDuration() {
    return new Duration(microseconds: source.readInt());
  }

  Info readInfoWithKind() {
    InfoKind kind = source.readEnum(InfoKind.values);
    switch (kind) {
      case InfoKind.library:
        return readLibrary();
      case InfoKind.clazz:
        return readClass();
      case InfoKind.function:
        return readFunction();
      case InfoKind.field:
        return readField();
      case InfoKind.constant:
        return readConstant();
      case InfoKind.outputUnit:
        return readOutput();
      case InfoKind.typedef:
        return readTypedef();
      case InfoKind.closure:
        return readClosure();
    }
    return null;
  }

  AllInfo readAll() {
    var info = new AllInfo();
    int version = source.readInt();
    int minorVersion = source.readInt();
    if (info.version != version || info.minorVersion != minorVersion) {
      print("warning: data was encoded with format version "
          "$version.$minorVersion, but decoded with "
          "${info.version}.${info.minorVersion}");
    }
    info.libraries = source.readList(readLibrary);
    info.classes = source.readList(readClass);
    info.functions = source.readList(readFunction);
    info.typedefs = source.readList(readTypedef);
    info.fields = source.readList(readField);
    info.constants = source.readList(readConstant);
    info.closures = source.readList(readClosure);

    void readDependencies(CodeInfo info) {
      info.uses = source.readList(_readDependencyInfo);
    }

    info.fields.forEach(readDependencies);
    info.functions.forEach(readDependencies);

    int dependenciesTotal = source.readInt();
    while (dependenciesTotal > 0) {
      Info key = readInfoWithKind();
      List<Info> values = source.readList(readInfoWithKind);
      info.dependencies[key] = values;
      dependenciesTotal--;
    }

    info.outputUnits = source.readList(readOutput);

    Map<String, Map<String, dynamic>> map =
        jsonDecode(source.readString()).cast<String, Map<String, dynamic>>();
    for (final library in map.values) {
      if (library['imports'] != null) {
        // The importMap needs to be typed as <String, List<String>>, but the
        // json parser produces <String, dynamic>.
        final importMap = library['imports'] as Map<String, dynamic>;
        importMap.forEach((prefix, files) {
          importMap[prefix] = (files as List<dynamic>).cast<String>();
        });
        library['imports'] = importMap.cast<String, List<String>>();
      }
    }
    info.deferredFiles = map;
    info.program = readProgram();
    return info;
  }

  ProgramInfo readProgram() {
    var info = new ProgramInfo();
    info.entrypoint = readFunction();
    info.size = source.readInt();
    info.dart2jsVersion = source.readStringOrNull();
    info.compilationMoment = readDate();
    info.compilationDuration = readDuration();
    info.toJsonDuration = new Duration(microseconds: 0);
    info.dumpInfoDuration = readDuration();
    info.noSuchMethodEnabled = source.readBool();
    info.isRuntimeTypeUsed = source.readBool();
    info.isIsolateInUse = source.readBool();
    info.isFunctionApplyUsed = source.readBool();
    info.isMirrorsUsed = source.readBool();
    info.minified = source.readBool();
    return info;
  }

  void _readBasicInfo(BasicInfo info) {
    info.name = source.readStringOrNull();
    info.size = source.readInt();
    info.coverageId = source.readStringOrNull();
    info.outputUnit = _readOutputOrNull();
    // Note: parent pointers are added when deserializing parent nodes.
  }

  LibraryInfo readLibrary() => source.readCached<LibraryInfo>(() {
        LibraryInfo info = new LibraryInfo.internal();
        info.uri = source.readUri();
        _readBasicInfo(info);
        info.topLevelFunctions = source.readList(readFunction);
        info.topLevelVariables = source.readList(readField);
        info.classes = source.readList(readClass);
        info.typedefs = source.readList(readTypedef);

        setParent(BasicInfo child) => child.parent = info;
        info.topLevelFunctions.forEach(setParent);
        info.topLevelVariables.forEach(setParent);
        info.classes.forEach(setParent);
        info.typedefs.forEach(setParent);
        return info;
      });

  ClassInfo readClass() => source.readCached<ClassInfo>(() {
        ClassInfo info = new ClassInfo.internal();
        _readBasicInfo(info);
        info.isAbstract = source.readBool();
        info.fields = source.readList(readField);
        info.functions = source.readList(readFunction);

        setParent(BasicInfo child) => child.parent = info;
        info.fields.forEach(setParent);
        info.functions.forEach(setParent);
        return info;
      });

  FieldInfo readField() => source.readCached<FieldInfo>(() {
        FieldInfo info = new FieldInfo.internal();
        _readBasicInfo(info);
        info.closures = source.readList(readClosure);
        info.inferredType = source.readString();
        info.code = source.readList(_readCodeSpan);
        info.type = source.readString();
        info.isConst = source.readBool();
        if (info.isConst) {
          info.initializer = _readConstantOrNull();
        }
        info.closures.forEach((c) => c.parent = info);
        return info;
      });

  CodeSpan _readCodeSpan() {
    return new CodeSpan()
      ..start = source.readIntOrNull()
      ..end = source.readIntOrNull()
      ..text = source.readStringOrNull();
  }

  ConstantInfo _readConstantOrNull() {
    bool hasOutput = source.readBool();
    if (hasOutput) return readConstant();
    return null;
  }

  ConstantInfo readConstant() => source.readCached<ConstantInfo>(() {
        ConstantInfo info = new ConstantInfo.internal();
        _readBasicInfo(info);
        info.code = source.readList(_readCodeSpan);
        return info;
      });

  FunctionModifiers _readFunctionModifiers() {
    int value = source.readInt();
    return new FunctionModifiers(
        isStatic: value & _staticMask != 0,
        isConst: value & _constMask != 0,
        isFactory: value & _factoryMask != 0,
        isExternal: value & _externalMask != 0);
  }

  ParameterInfo _readParameterInfo() {
    return new ParameterInfo(
        source.readString(), source.readString(), source.readString());
  }

  FunctionInfo readFunction() => source.readCached<FunctionInfo>(() {
        FunctionInfo info = new FunctionInfo.internal();
        _readBasicInfo(info);
        info.closures = source.readList(readClosure);
        info.modifiers = _readFunctionModifiers();
        info.returnType = source.readString();
        info.inferredReturnType = source.readString();
        info.parameters = source.readList(_readParameterInfo);
        info.sideEffects = source.readString();
        info.inlinedCount = source.readIntOrNull();
        info.code = source.readList(_readCodeSpan);
        info.type = source.readString();
        info.closures.forEach((c) => c.parent = info);
        return info;
      });

  DependencyInfo _readDependencyInfo() =>
      new DependencyInfo(readInfoWithKind(), source.readStringOrNull());

  ClosureInfo readClosure() => source.readCached<ClosureInfo>(() {
        ClosureInfo info = new ClosureInfo.internal();
        _readBasicInfo(info);
        info.function = readFunction();
        info.function.parent = info;
        return info;
      });

  TypedefInfo readTypedef() => source.readCached<TypedefInfo>(() {
        TypedefInfo info = new TypedefInfo.internal();
        _readBasicInfo(info);
        info.type = source.readString();
        return info;
      });

  OutputUnitInfo _readOutputOrNull() {
    bool hasOutput = source.readBool();
    if (hasOutput) return readOutput();
    return null;
  }

  OutputUnitInfo readOutput() => source.readCached<OutputUnitInfo>(() {
        OutputUnitInfo info = new OutputUnitInfo.internal();
        _readBasicInfo(info);
        info.filename = source.readStringOrNull();
        info.imports = source.readList(source.readString);
        return info;
      });
}

const int _staticMask = 1 << 3;
const int _constMask = 1 << 2;
const int _factoryMask = 1 << 1;
const int _externalMask = 1 << 0;
