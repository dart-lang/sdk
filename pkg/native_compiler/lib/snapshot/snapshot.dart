// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/configuration.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/utils/misc.dart';
import 'package:native_compiler/runtime/type_utils.dart';

/// Kinds of Dart snapshots.
/// Should match Snapshot::Kind enum in runtime/vm/snapshot.h.
enum SnapshotKind { full, fullCore, fullJIT, fullAOT, module, none, invalid }

/// Dart snapshot constants.
class Snapshot {
  // Dart snapshot magic and header format.
  // Values of these constants should match corresponding constants
  // declared in Snapshot class in runtime/vm/snapshot.h.
  static const int magicValue = 0xdcdcf5f5;
  static const int magicOffset = 0;
  static const int lengthOffset = magicOffset + 4;
  static const int kindOffset = lengthOffset + 8;
  static const int headerSize = kindOffset + 8;

  /// Endianness for writing snapshots.
  /// All our targets are little-endian.
  static const Endian endianness = Endian.little;

  /// Version of module snapshot format.
  /// Should match ModuleSnapshot::kFormatVersion
  /// constant declared in runtime/vm/module_snapshot.cc.
  static const int moduleSnapshotFormatVersion = 1;
}

/// Predefined clusters in the module snapshots.
///
/// This enum should match ModuleSnapshot::PredefinedClusters
/// enum declared in runtime/vm/module_snapshot.cc.
enum PredefinedClusters {
  oneByteStrings,
  twoByteStrings,
  libraryRefs,
  privateNames,
  classRefs,
  fieldRefs,
  functionRefs,
  closureFunctionRefs,
  closureRefs,
  ints,
  doubles,
  arrays,
  interfaceTypes,
  functionTypes,
  recordTypes,
  typeParameterTypes,
  typeArguments,
  codes,
  objectPools,
}

/// Function kinds in the module snapshots.
///
/// This enum should match ModuleSnapshot::FunctionKind
/// enum declared in runtime/vm/module_snapshot.cc.
enum FunctionKind {
  regular,
  getter,
  setter,
  generativeConstructor,
  factoryConstructor,
  implicitGetter,
  implicitSetter,
  fieldInitializer,
}

/// Object pool entry kinds in the module snapshots.
///
/// This enum should match ModuleSnapshot::ObjectPoolEntryKind
/// enum declared in runtime/vm/module_snapshot.cc.
enum ObjectPoolEntryKind { objectRef, newObjectTags }

abstract base class SerializationCluster {
  /// Add [object] to the cluster and push its outgoing references.
  void trace(SnapshotSerializer serializer, Object object);

  /// Write the cluster type and information needed to
  /// reference imported objects.
  void writePreLoad(SnapshotSerializer serializer);

  /// Write information needed to allocate the cluster's objects.
  void writeAlloc(SnapshotSerializer serializer) {}

  /// Write contents of the cluster's objects.
  void writeFill(SnapshotSerializer serializer) {}

  /// Write information needed to post-process
  /// allocated objects (e.g. perform canonicalization).
  void writePostLoad(SnapshotSerializer serializer) {}
}

class SnapshotSerializer {
  // Discovered but not allocated yet.
  static const int unallocatedReference = -1;
  // The first allocated reference.
  static const int firstReference = 1;

  final TargetCPU targetCPU;
  final FunctionRegistry functionRegistry;
  int numBaseObjects = 0;
  int numObjects = 0;
  final List<Object?> _objects = [];
  final Map<Object?, int> _objectIds = {};
  final List<Object?> _stack = [];
  final List<SerializationCluster?> _clusters = List.filled(
    PredefinedClusters.values.length,
    null,
  );
  final SnapshotStreamWriter out = SnapshotStreamWriter();

  SnapshotSerializer(this.targetCPU, this.functionRegistry) {
    addBaseObject(null);
    addBaseObject(true);
    addBaseObject(false);
    addBaseObject(const ast.DynamicType());
    addBaseObject(const ast.VoidType());
    addBaseObject(const ast.NullType());
    addBaseObject(const ast.NeverType.nonNullable());
    numObjects = numBaseObjects;
  }

  void writeModuleSnapshot() {
    out.reserve(Snapshot.headerSize);
    writeVersionAndFeatures();

    out.writeUint(numBaseObjects);
    out.writeUint(numObjects);

    final codeCluster =
        getPredefinedCluster(PredefinedClusters.codes)
            as CodeSerializationCluster;
    final lastCode = codeCluster._objects.last;
    out.writeUint(
      lastCode.instructionsImageOffset! + lastCode.instructions.lengthInBytes,
    );

    final clusters = [for (final c in _clusters) ?c];
    out.writeUint(clusters.length);

    for (final cluster in clusters) {
      cluster.writePreLoad(this);
    }
    for (final cluster in clusters) {
      cluster.writeAlloc(this);
    }
    assert(_objects.length == numObjects);

    for (final cluster in clusters) {
      cluster.writeFill(this);
    }
    for (final cluster in clusters) {
      cluster.writePostLoad(this);
    }

    fillHeader(SnapshotKind.module);
  }

  void writeVersionAndFeatures() {
    out.writeUint(Snapshot.moduleSnapshotFormatVersion);
    out.writeUint8List(utf8.encode(targetCPU.name));
    out.writeByte(0);
  }

  void fillHeader(SnapshotKind kind) {
    out.writeInt32At(Snapshot.magicOffset, Snapshot.magicValue);
    out.writeInt64At(Snapshot.lengthOffset, out.position);
    out.writeInt64At(Snapshot.kindOffset, kind.index);
  }

  void addBaseObject(Object? obj) {
    assignRef(obj);
    ++numBaseObjects;
  }

  void addRoot(Object obj) {
    push(obj);
    while (_stack.isNotEmpty) {
      trace(_stack.removeLast()!);
    }
  }

  Object? preprocess(Object? obj) => switch (obj) {
    ast.PrimitiveConstant() => obj.value,
    ast.Name() when !obj.isPrivate => obj.text,
    ast.FutureOrType() => ast.InterfaceType(
      GlobalContext.instance.coreTypes.deprecatedFutureOrClass,
      obj.declaredNullability,
      [obj.typeArgument],
    ),
    TypeArgumentsConstant() when isAllDynamic(obj.types) => null,
    _ => obj,
  };

  void trace(Object obj) {
    ++numObjects;
    final cluster = getCluster(obj);
    cluster.trace(this, obj);
  }

  void push(Object? obj) {
    obj = preprocess(obj);
    _objectIds.putIfAbsent(obj, () {
      _stack.add(obj);
      return unallocatedReference;
    });
  }

  int assignRef(Object? obj) {
    assert(identical(preprocess(obj), obj));
    final id = firstReference + _objects.length;
    _objects.add(obj);
    _objectIds[obj] = id;
    return id;
  }

  void writeUint(int value) {
    out.writeUint(value);
  }

  void writeRefId(Object? obj) {
    obj = preprocess(obj);
    final refId = _objectIds[obj]!;
    assert(refId >= firstReference);
    out.writeRefId(refId);
  }

  SerializationCluster getCluster(Object obj) => switch (obj) {
    // Program structure.
    ast.Library() => getPredefinedCluster(PredefinedClusters.libraryRefs),
    ast.Class() => getPredefinedCluster(PredefinedClusters.classRefs),
    ast.Field() => getPredefinedCluster(PredefinedClusters.fieldRefs),
    ClosureFunction() => getPredefinedCluster(
      PredefinedClusters.closureFunctionRefs,
    ),
    CFunction() => getPredefinedCluster(PredefinedClusters.functionRefs),
    ast.Name() => getPredefinedCluster(PredefinedClusters.privateNames),
    // Constants.
    String() => getPredefinedCluster(
      OneByteStringSerializationCluster.isOneByteString(obj)
          ? PredefinedClusters.oneByteStrings
          : PredefinedClusters.twoByteStrings,
    ),
    int() => getPredefinedCluster(PredefinedClusters.ints),
    double() => getPredefinedCluster(PredefinedClusters.doubles),
    ast.ListConstant() => throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.MapConstant() => throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.SetConstant() => throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.RecordConstant() =>
      throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.InstanceConstant() =>
      throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.SymbolConstant() =>
      throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.InstantiationConstant() =>
      throw 'Unimplemented cluster for ${obj.runtimeType}',
    ast.TearOffConstant() => getPredefinedCluster(
      PredefinedClusters.closureRefs,
    ),
    ast.TypeLiteralConstant() =>
      throw 'Unimplemented cluster for ${obj.runtimeType}',
    // Types.
    ast.InterfaceType() => getPredefinedCluster(
      PredefinedClusters.interfaceTypes,
    ),
    ast.FutureOrType() => getPredefinedCluster(
      PredefinedClusters.interfaceTypes,
    ),
    ast.FunctionType() => getPredefinedCluster(
      PredefinedClusters.functionTypes,
    ),
    ast.RecordType() => getPredefinedCluster(PredefinedClusters.recordTypes),
    ast.TypeParameterType() => getPredefinedCluster(
      PredefinedClusters.typeParameterTypes,
    ),
    ast.StructuralParameterType() => getPredefinedCluster(
      PredefinedClusters.typeParameterTypes,
    ),
    TypeArgumentsConstant() => getPredefinedCluster(
      PredefinedClusters.typeArguments,
    ),
    // Generated code and object pool
    Code() => getPredefinedCluster(PredefinedClusters.codes),
    ObjectPool() => getPredefinedCluster(PredefinedClusters.objectPools),
    _ => throw 'Unxpected ${obj.runtimeType} $obj',
  };

  SerializationCluster getPredefinedCluster(PredefinedClusters clusterId) =>
      (_clusters[clusterId.index] ??= _createPredefinedCluster(clusterId));

  SerializationCluster _createPredefinedCluster(
    PredefinedClusters clusterId,
  ) => switch (clusterId) {
    PredefinedClusters.libraryRefs => LibraryRefSerializationCluster(),
    PredefinedClusters.classRefs => ClassRefSerializationCluster(),
    PredefinedClusters.fieldRefs => FieldRefSerializationCluster(),
    PredefinedClusters.functionRefs => FunctionRefSerializationCluster(),
    PredefinedClusters.closureFunctionRefs =>
      ClosureFunctionRefSerializationCluster(),
    PredefinedClusters.closureRefs => ClosureRefSerializationCluster(),
    PredefinedClusters.oneByteStrings => OneByteStringSerializationCluster(),
    PredefinedClusters.twoByteStrings => TwoByteStringSerializationCluster(),
    PredefinedClusters.privateNames => PrivateNameSerializationCluster(),
    PredefinedClusters.codes => CodeSerializationCluster(),
    PredefinedClusters.objectPools => ObjectPoolSerializationCluster(),
    PredefinedClusters.typeArguments => TypeArgumentsSerializationCluster(),
    PredefinedClusters.interfaceTypes => InterfaceTypeSerializationCluster(),
    _ => throw 'Unimplemented $clusterId',
  };
}

final class LibraryRefSerializationCluster extends SerializationCluster {
  final List<ast.Library> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final library = object as ast.Library;
    _objects.add(library);
    serializer.push(library.importUri.toString());
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.libraryRefs.index);
    serializer.writeUint(_objects.length);
    for (final library in _objects) {
      serializer.assignRef(library);
      serializer.writeRefId(library.importUri.toString());
    }
  }
}

extension on ast.Class {
  Object get mangledName =>
      name.startsWith('_') ? ast.Name(name, enclosingLibrary) : name;
}

final class ClassRefSerializationCluster extends SerializationCluster {
  final List<ast.Class> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final classNode = object as ast.Class;
    _objects.add(classNode);
    serializer.push(classNode.enclosingLibrary);
    serializer.push(classNode.mangledName);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.classRefs.index);
    serializer.writeUint(_objects.length);
    for (final classNode in _objects) {
      serializer.assignRef(classNode);
      serializer.writeRefId(classNode.enclosingLibrary);
      serializer.writeRefId(classNode.mangledName);
    }
  }
}

final class FieldRefSerializationCluster extends SerializationCluster {
  final List<ast.Field> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final field = object as ast.Field;
    _objects.add(field);
    serializer.push(field.enclosingClass ?? field.enclosingLibrary);
    serializer.push(field.name);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.fieldRefs.index);
    serializer.writeUint(_objects.length);
    for (final field in _objects) {
      serializer.assignRef(field);
      serializer.writeRefId(field.enclosingClass ?? field.enclosingLibrary);
      serializer.writeRefId(field.name);
    }
  }
}

final class FunctionRefSerializationCluster extends SerializationCluster {
  final List<CFunction> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final function = object as CFunction;
    _objects.add(function);
    switch (function) {
      case RegularFunction() ||
          GenerativeConstructor() ||
          GetterFunction() ||
          SetterFunction() ||
          FieldInitializerFunction():
        serializer.push(
          function.member.enclosingClass ?? function.member.enclosingLibrary,
        );
        serializer.push(function.member.name);
        break;
      case ClosureFunction():
        throw 'Unexpected ${function.runtimeType} in FunctionRefSerializationCluster';
    }
    ;
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.functionRefs.index);
    serializer.writeUint(_objects.length);
    for (final function in _objects) {
      serializer.assignRef(function);
      final kind = switch (function) {
        RegularFunction() =>
          (function.member as ast.Procedure).isFactory
              ? FunctionKind.factoryConstructor
              : FunctionKind.regular,
        GenerativeConstructor() => FunctionKind.generativeConstructor,
        ImplicitFieldGetter() => FunctionKind.implicitGetter,
        ImplicitFieldSetter() => FunctionKind.implicitSetter,
        FieldInitializerFunction() => FunctionKind.fieldInitializer,
        GetterFunction() => FunctionKind.getter,
        SetterFunction() => FunctionKind.setter,
        ClosureFunction() =>
          throw 'Unexpected ${function.runtimeType} in FunctionRefSerializationCluster',
      };
      serializer.writeUint(kind.index);
      switch (function) {
        case RegularFunction() ||
            GenerativeConstructor() ||
            GetterFunction() ||
            SetterFunction() ||
            FieldInitializerFunction():
          serializer.writeRefId(
            function.member.enclosingClass ?? function.member.enclosingLibrary,
          );
          serializer.writeRefId(function.member.name);
          break;
        case ClosureFunction():
          throw 'Unexpected ${function.runtimeType} in FunctionRefSerializationCluster';
      }
    }
  }
}

final class ClosureFunctionRefSerializationCluster
    extends SerializationCluster {
  final List<ClosureFunction> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final function = object as ClosureFunction;
    _objects.add(function);
    switch (function) {
      case TearOffFunction():
        serializer.push(
          serializer.functionRegistry.getFunction(function.member),
        );
      case LocalFunction():
        break;
    }
    ;
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.closureFunctionRefs.index);
    serializer.writeUint(_objects.length);
    for (final function in _objects) {
      serializer.assignRef(function);
      serializer.writeUint(function is TearOffFunction ? 1 : 0);
      switch (function) {
        case TearOffFunction():
          serializer.writeRefId(
            serializer.functionRegistry.getFunction(function.member),
          );
        case LocalFunction():
          // TODO: write closure info
          throw 'Unimplemented: ClosureFunctionRefSerializationCluster for LocalFunction';
      }
    }
  }
}

final class ClosureRefSerializationCluster extends SerializationCluster {
  final List<ast.TearOffConstant> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final closure = object as ast.TearOffConstant;
    _objects.add(closure);
    serializer.push(
      serializer.functionRegistry.getFunction(closure.target, isTearOff: true),
    );
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.closureRefs.index);
    serializer.writeUint(_objects.length);
    for (final closure in _objects) {
      serializer.assignRef(closure);
      serializer.writeRefId(
        serializer.functionRegistry.getFunction(
          closure.target,
          isTearOff: true,
        ),
      );
    }
  }
}

final class OneByteStringSerializationCluster extends SerializationCluster {
  final List<String> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final string = object as String;
    _objects.add(string);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.oneByteStrings.index);
    serializer.writeUint(_objects.length);
    for (final string in _objects) {
      serializer.assignRef(string);
      serializer.writeUint(string.length);
      serializer.out.writeUint8List(string.codeUnits);
    }
  }

  static bool isOneByteString(String value) {
    const maxLatin1 = 0xff;
    for (var i = 0; i < value.length; ++i) {
      if (value.codeUnitAt(i) > maxLatin1) {
        return false;
      }
    }
    return true;
  }
}

final class TwoByteStringSerializationCluster extends SerializationCluster {
  final List<String> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final string = object as String;
    _objects.add(string);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.twoByteStrings.index);
    serializer.writeUint(_objects.length);
    for (final string in _objects) {
      serializer.assignRef(string);
      serializer.writeUint(string.length);
      serializer.out.writeUint16List(string.codeUnits);
    }
  }
}

final class PrivateNameSerializationCluster extends SerializationCluster {
  final List<ast.Name> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final name = object as ast.Name;
    _objects.add(name);
    serializer.push(name.library!);
    serializer.push(name.text);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.privateNames.index);
    serializer.writeUint(_objects.length);
    for (final name in _objects) {
      serializer.assignRef(name);
      serializer.writeRefId(name.library!);
      serializer.writeRefId(name.text);
    }
  }
}

final class TypeArgumentsSerializationCluster extends SerializationCluster {
  final List<TypeArgumentsConstant> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final typeArgs = object as TypeArgumentsConstant;
    _objects.add(typeArgs);
    for (final type in typeArgs.types) {
      serializer.push(type);
    }
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.typeArguments.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final typeArgs in _objects) {
      serializer.assignRef(typeArgs);
      serializer.writeUint(typeArgs.types.length);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final typeArgs in _objects) {
      serializer.writeUint(typeArgs.types.length);
      for (final type in typeArgs.types) {
        serializer.writeRefId(type);
      }
    }
  }
}

final class InterfaceTypeSerializationCluster extends SerializationCluster {
  final List<ast.InterfaceType> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final type = object as ast.InterfaceType;
    _objects.add(type);
    serializer.push(type.classNode);
    serializer.push(TypeArgumentsConstant(type.typeArguments));
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.interfaceTypes.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final type in _objects) {
      serializer.assignRef(type);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final type in _objects) {
      serializer.writeRefId(type.classNode);
      serializer.writeUint(
        type.declaredNullability == ast.Nullability.nullable ? 1 : 0,
      );
      serializer.writeRefId(TypeArgumentsConstant(type.typeArguments));
    }
  }
}

final class CodeSerializationCluster extends SerializationCluster {
  final List<Code> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final code = object as Code;
    assert(
      (_objects.isEmpty && code.instructionsImageOffset == 0) ||
          _objects.last.instructionsImageOffset! +
                  _objects.last.instructions.lengthInBytes ==
              code.instructionsImageOffset,
    );
    _objects.add(code);
    serializer.push(code.function);
    serializer.push(code.objectPool);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.codes.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final obj in _objects) {
      serializer.assignRef(obj);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final code in _objects) {
      serializer.writeRefId(code.objectPool);
      serializer.writeRefId(code.function);
      serializer.writeUint(code.instructions.lengthInBytes);
    }
  }
}

final class ObjectPoolSerializationCluster extends SerializationCluster {
  final List<ObjectPool> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final pool = object as ObjectPool;
    _objects.add(pool);
    for (final entry in pool.entries) {
      if (entry is SpecializedEntry) {
        switch (entry) {
          case NewObjectTags():
            serializer.push(entry.cls);
        }
      } else {
        serializer.push(entry);
      }
    }
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.objectPools.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final pool in _objects) {
      serializer.assignRef(pool);
      serializer.writeUint(pool.entries.length);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final pool in _objects) {
      serializer.writeUint(pool.entries.length);
      for (final entry in pool.entries) {
        if (entry is SpecializedEntry) {
          switch (entry) {
            case NewObjectTags():
              serializer.writeUint(ObjectPoolEntryKind.newObjectTags.index);
              serializer.writeRefId(entry.cls);
          }
        } else {
          serializer.writeUint(ObjectPoolEntryKind.objectRef.index);
          serializer.writeRefId(entry);
        }
      }
    }
  }
}

/// Buffers snapshot writing.
class SnapshotStreamWriter {
  /// Initial size of the buffer.
  static const int initialSize = 1024;

  // Constants for variable-length encoding used by snapshots.
  static const int dataBitsPerByte = 7;
  static const int byteMask = (1 << dataBitsPerByte) - 1;
  static const int maxUnsignedDataPerByte = byteMask;
  static const int minDataPerByte = -(1 << (dataBitsPerByte - 1));
  static const int maxDataPerByte = (~minDataPerByte) & byteMask;
  static const int endByteMarker = 255 - maxDataPerByte;
  static const int endUnsignedByteMarker = 255 - maxUnsignedDataPerByte;

  // Prefix of the data stored in this writer.
  List<(Uint8List, int length)> _buffers = [];

  // Total length of data in [_buffers].
  int _buffersLength = 0;

  Uint8List _currentBuffer = Uint8List(initialSize);
  int _currentLength = 0;

  SnapshotStreamWriter();

  List<Uint8List> getContents() {
    final list = <Uint8List>[];
    for (var (buf, len) in _buffers) {
      if (len != buf.length) {
        buf = Uint8List.view(buf.buffer, buf.offsetInBytes, len);
      }
      list.add(buf);
    }
    Uint8List buf = _currentBuffer;
    if (_currentLength != buf.length) {
      buf = Uint8List.view(buf.buffer, buf.offsetInBytes, _currentLength);
    }
    list.add(buf);
    return list;
  }

  int get position => _buffersLength + _currentLength;

  @pragma('vm:never-inline')
  void _grow(int minLength) {
    int nextBufferSize = _currentBuffer.length << 1;
    while (nextBufferSize < minLength) {
      nextBufferSize = nextBufferSize << 1;
    }
    _buffers.add((_currentBuffer, _currentLength));
    _buffersLength += _currentLength;
    _currentBuffer = Uint8List(nextBufferSize);
    _currentLength = 0;
  }

  @pragma('vm:prefer-inline')
  void _ensureCapacity(int length) {
    assert(length >= 0);
    if (length > _currentBuffer.length - _currentLength) {
      _grow(length);
    }
  }

  @pragma('vm:prefer-inline')
  void reserve(int length) {
    if (length != 0) {
      _ensureCapacity(length);
      _currentLength += length;
    }
  }

  @pragma('vm:prefer-inline')
  void align(int alignment) {
    final pos = this.position;
    int padding = roundUp(pos, alignment) - pos;
    reserve(padding);
  }

  @pragma('vm:prefer-inline')
  void writeByte(int value) {
    _ensureCapacity(1);
    _currentBuffer[_currentLength++] = value;
  }

  @pragma('vm:prefer-inline')
  void writeUint8List(List<int> src) {
    _ensureCapacity(src.length);
    _currentBuffer.setRange(_currentLength, _currentLength + src.length, src);
    _currentLength += src.length;
  }

  @pragma('vm:prefer-inline')
  void writeUint16List(List<int> src) {
    _ensureCapacity(src.length << 1);
    _currentBuffer.buffer
        .asUint16List(_currentLength)
        .setRange(0, src.length, src);
    _currentLength += src.length << 1;
  }

  @pragma('vm:prefer-inline')
  void writeInt(int value) {
    while (value < minDataPerByte || value > maxDataPerByte) {
      writeByte(value & byteMask);
      value = value >> dataBitsPerByte;
    }
    writeByte(value + endByteMarker);
  }

  @pragma('vm:prefer-inline')
  void writeUint(int value) {
    assert(value >= 0);
    while (value > maxUnsignedDataPerByte) {
      writeByte(value & byteMask);
      value = value >>> dataBitsPerByte;
    }
    writeByte(value + endUnsignedByteMarker);
  }

  void writeRefId(int value) {
    assert((value >>> 28) == 0);
    _ensureCapacity(4);
    if ((value >> 21) != 0) {
      _currentBuffer[_currentLength++] = (value >> 21) & 127;
    }
    if ((value >> 14) != 0) {
      _currentBuffer[_currentLength++] = (value >> 14) & 127;
    }
    if ((value >> 7) != 0) {
      _currentBuffer[_currentLength++] = (value >> 7) & 127;
    }
    _currentBuffer[_currentLength++] = ((value >> 0) & 127) | 128;
  }

  ByteData _bufferAt(int offset) {
    if (offset >= _buffersLength) {
      return _currentBuffer.buffer.asByteData(offset - _buffersLength);
    } else {
      for (var (buf, len) in _buffers) {
        if (offset < len) {
          return buf.buffer.asByteData(offset);
        }
        offset -= len;
      }
      throw 'Mismatch between _buffers and _buffersLength';
    }
  }

  /// Write 32-bit value at given offset.
  /// The space for the value should be reserved by a single [reserve].
  void writeInt32At(int offset, int value) {
    _bufferAt(offset).setInt32(0, value, Snapshot.endianness);
  }

  /// Write 64-bit value at given offset.
  /// The space for the value should be reserved by a single [reserve].
  void writeInt64At(int offset, int value) {
    _bufferAt(offset).setInt64(0, value, Snapshot.endianness);
  }
}
