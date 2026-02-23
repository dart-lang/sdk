// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cfg/ir/constant_value.dart';
import 'package:cfg/ir/field.dart';
import 'package:cfg/ir/functions.dart';
import 'package:cfg/ir/global_context.dart';
import 'package:cfg/utils/misc.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:kernel/src/printer.dart' as ast_printer show AstPrinter;
import 'package:kernel/type_environment.dart'
    as ast_type_environment
    show StaticTypeContext;
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/object_pool.dart';
import 'package:native_compiler/configuration.dart';
import 'package:native_compiler/runtime/object_layout.dart';
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
  argumentsDescriptorRefs,
  ints,
  doubles,
  lists,
  maps,
  sets,
  records,
  instantiatedClosures,
  typeParameters,
  interfaceTypes,
  functionTypes,
  recordTypes,
  typeParameterTypes,
  typeArguments,
  codes,
  icDatas,
  objectPools,
  instances, // Separate cluster for every class.
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
enum ObjectPoolEntryKind { objectRef, newObjectTags, interfaceCall }

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
  final ObjectLayout objectLayout;
  int numBaseObjects = 0;
  int numObjects = 0;
  final List<Object?> _objects = [];
  final Map<Object?, int> _objectIds = {};
  final List<Object?> _stack = [];
  final List<SerializationCluster?> _clusters = List.filled(
    PredefinedClusters.values.length,
    null,
  );
  final Map<ast.Class, SerializationCluster> _instanceClusters = {};
  final SnapshotStreamWriter out = SnapshotStreamWriter();

  SnapshotSerializer(this.targetCPU, this.functionRegistry, this.objectLayout) {
    addBaseObject(null);
    addBaseObject(true);
    addBaseObject(false);
    addBaseObject(const ast.DynamicType());
    addBaseObject(const ast.VoidType());
    addBaseObject(const ast.NullType());
    addBaseObject(const ast.NeverType.nonNullable());
    addBaseObject(ast.ListConstant(const ast.DynamicType(), const []));
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

    final clusters = [
      for (final c in _clusters) ?c,
      ..._instanceClusters.values,
    ];
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
    ast.Name() when !obj.isPrivate => obj.text,
    ast.PrimitiveConstant() when obj is! ast.DoubleConstant => obj.value,
    ast.TypeLiteralConstant() => preprocess(obj.type),
    ast.SymbolConstant() => ast.InstanceConstant(
      GlobalContext.instance.coreTypes.internalSymbolClass.reference,
      const [],
      {
        GlobalContext.instance.coreTypes.index
            .getField('dart:_internal', 'Symbol', '_name')
            .fieldReference: getNameConstant(
          obj.name,
          obj.libraryReference?.asLibrary,
        ),
      },
    ),
    ast.FutureOrType() => ast.InterfaceType(
      GlobalContext.instance.coreTypes.deprecatedFutureOrClass,
      obj.declaredNullability,
      [obj.typeArgument],
    ),
    ast.ExtensionType() => preprocess(obj.extensionTypeErasure),
    ast.NeverType() when obj.nullability == .nullable => const ast.NullType(),
    TypeArgumentsConstant() when isAllDynamic(obj.types) => null,
    WrapperConstant() => preprocess(obj.unwrap),
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
    ArgumentsShape() => getPredefinedCluster(
      PredefinedClusters.argumentsDescriptorRefs,
    ),
    // Constants.
    String() => getPredefinedCluster(
      OneByteStringSerializationCluster.isOneByteString(obj)
          ? PredefinedClusters.oneByteStrings
          : PredefinedClusters.twoByteStrings,
    ),
    int() => getPredefinedCluster(PredefinedClusters.ints),
    ast.DoubleConstant() => getPredefinedCluster(PredefinedClusters.doubles),
    ast.ListConstant() => getPredefinedCluster(PredefinedClusters.lists),
    ast.MapConstant() => getPredefinedCluster(PredefinedClusters.maps),
    ast.SetConstant() => getPredefinedCluster(PredefinedClusters.sets),
    ast.RecordConstant() => getPredefinedCluster(PredefinedClusters.records),
    ast.InstanceConstant() => getInstanceCluster(obj.classNode),
    ast.InstantiationConstant() => getPredefinedCluster(
      PredefinedClusters.instantiatedClosures,
    ),
    ast.TearOffConstant() => getPredefinedCluster(
      PredefinedClusters.closureRefs,
    ),
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
    ICData() => getPredefinedCluster(PredefinedClusters.icDatas),
    ObjectPool() => getPredefinedCluster(PredefinedClusters.objectPools),
    _ => throw 'Unxpected ${obj.runtimeType} $obj',
  };

  SerializationCluster getPredefinedCluster(PredefinedClusters clusterId) =>
      (_clusters[clusterId.index] ??= _createPredefinedCluster(clusterId));

  SerializationCluster getInstanceCluster(ast.Class cls) =>
      (_instanceClusters[cls] ??= InstanceSerializationCluster(cls));

  SerializationCluster _createPredefinedCluster(
    PredefinedClusters clusterId,
  ) => switch (clusterId) {
    .libraryRefs => LibraryRefSerializationCluster(),
    .classRefs => ClassRefSerializationCluster(),
    .fieldRefs => FieldRefSerializationCluster(),
    .functionRefs => FunctionRefSerializationCluster(),
    .closureFunctionRefs => ClosureFunctionRefSerializationCluster(),
    .closureRefs => ClosureRefSerializationCluster(),
    .argumentsDescriptorRefs => ArgumentsDescriptorRefSerializationCluster(),
    .oneByteStrings => OneByteStringSerializationCluster(),
    .twoByteStrings => TwoByteStringSerializationCluster(),
    .privateNames => PrivateNameSerializationCluster(),
    .ints => IntSerializationCluster(),
    .doubles => DoubleSerializationCluster(),
    .lists => ListSerializationCluster(),
    .maps => MapSerializationCluster(),
    .sets => SetSerializationCluster(),
    .records => throw 'Unimplemented cluster $clusterId',
    .instantiatedClosures => throw 'Unimplemented cluster $clusterId',
    .typeParameters =>
      throw 'Unimplemented cluster $clusterId', // TypeParametersSerializationCluster(),
    .typeArguments => TypeArgumentsSerializationCluster(),
    .interfaceTypes => InterfaceTypeSerializationCluster(),
    .functionTypes => FunctionTypeSerializationCluster(),
    .recordTypes => throw 'Unimplemented cluster $clusterId',
    .typeParameterTypes => throw 'Unimplemented cluster $clusterId',
    .codes => CodeSerializationCluster(),
    .icDatas => ICDataSerializationCluster(),
    .objectPools => ObjectPoolSerializationCluster(),
    .instances => throw 'Each class has a separate instance cluster',
  };
}

/// AST Constant which wraps an arbitrary object.
/// Used during snapshot serialization in order to embed arbitrary objects
/// (such as Name) into other constants (such as ListConstant).
class WrapperConstant extends ast.AuxiliaryConstant {
  final Object? unwrap;

  WrapperConstant(this.unwrap);

  @override
  void visitChildren(ast.Visitor v) => throw 'Should not be called.';

  @override
  void toTextInternal(ast_printer.AstPrinter printer) =>
      throw 'Should not be called.';

  @override
  ast.DartType getType(ast_type_environment.StaticTypeContext context) =>
      throw 'Should not be called.';

  @override
  int get hashCode => unwrap.hashCode;

  @override
  bool operator ==(Object other) {
    return other is WrapperConstant && this.unwrap == other.unwrap;
  }
}

/// Wrap given [name] into a Constant.
/// Private names should have a non-null [library].
ast.Constant getNameConstant(String name, ast.Library? library) =>
    (library != null)
    ? WrapperConstant(ast.Name(name, library))
    : ast.StringConstant(name);

/// Create a ListConstant from given [elements], wrapping them if needed.
ast.ListConstant getListConstant(List<Object?> elements) => ast.ListConstant(
  const ast.DynamicType(),
  [for (final e in elements) e is ast.Constant ? e : WrapperConstant(e)],
);

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

final class ArgumentsDescriptorRefSerializationCluster
    extends SerializationCluster {
  final List<ArgumentsShape> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final args = object as ArgumentsShape;
    _objects.add(args);
    for (final name in args.named) {
      serializer.push(name);
    }
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.argumentsDescriptorRefs.index);
    serializer.writeUint(_objects.length);
    for (final args in _objects) {
      serializer.assignRef(args);
      serializer.writeUint(args.types);
      serializer.writeUint(args.positional);
      serializer.writeUint(args.named.length);
      for (final name in args.named) {
        serializer.writeRefId(name);
      }
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

final class IntSerializationCluster extends SerializationCluster {
  final List<int> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final integer = object as int;
    _objects.add(integer);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.ints.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    // Move Smi values to the beginning.
    final objectLayout = serializer.objectLayout;
    var i = 0;
    for (var j = 0; j < _objects.length; ++j) {
      final v = _objects[j];
      if (objectLayout.isSmi(v)) {
        final tmp = _objects[i];
        _objects[i] = v;
        _objects[j] = tmp;
        ++i;
      }
    }
    serializer.writeUint(_objects.length);
    serializer.writeUint(i);
    for (final integer in _objects) {
      serializer.assignRef(integer);
      serializer.out.writeInt(integer);
    }
  }
}

final class DoubleSerializationCluster extends SerializationCluster {
  final List<ast.DoubleConstant> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final dbl = object as ast.DoubleConstant;
    _objects.add(dbl);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.doubles.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final dbl in _objects) {
      serializer.assignRef(dbl);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final dbl in _objects) {
      serializer.out.writeDouble(dbl.value);
    }
  }
}

/// Serialization cluster for constant lists.
///
/// On the VM, constant lists are represented with dart:core._ImmutableList
/// objects / Array handles with kImmutableArrayCid class id.
final class ListSerializationCluster extends SerializationCluster {
  final List<ast.ListConstant> _objects = [];

  Object? _typeArguments(ast.ListConstant list) {
    final typeArg = list.typeArgument;
    if (typeArg is ast.DynamicType) return null;
    return TypeArgumentsConstant([typeArg]);
  }

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final list = object as ast.ListConstant;
    _objects.add(list);
    serializer.push(_typeArguments(list));
    for (final entry in list.entries) {
      serializer.push(entry);
    }
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.lists.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final list in _objects) {
      serializer.assignRef(list);
      serializer.writeUint(list.entries.length);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (final list in _objects) {
      serializer.writeUint(list.entries.length);
      serializer.writeRefId(_typeArguments(list));
      for (final entry in list.entries) {
        serializer.writeRefId(entry);
      }
    }
  }
}

final class MapSerializationCluster extends SerializationCluster {
  final List<ast.MapConstant> _objects = [];
  final List<ast.ListConstant> _dataLists = [];

  Object? _typeArguments(ast.MapConstant map) {
    final keyType = map.keyType;
    final valueType = map.valueType;
    if (keyType is ast.DynamicType && valueType is ast.DynamicType) return null;
    return TypeArgumentsConstant([keyType, valueType]);
  }

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final map = object as ast.MapConstant;
    final data = ast.ListConstant(const ast.DynamicType(), [
      for (final entry in map.entries) ...[entry.key, entry.value],
    ]);
    _objects.add(map);
    _dataLists.add(data);
    serializer.push(_typeArguments(map));
    serializer.push(data);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.maps.index);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    for (final map in _objects) {
      serializer.assignRef(map);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    for (var i = 0; i < _objects.length; ++i) {
      final map = _objects[i];
      final data = _dataLists[i];
      serializer.writeRefId(_typeArguments(map));
      serializer.writeRefId(data);
      serializer.writeUint(map.entries.length << 1);
    }
  }
}

final class SetSerializationCluster extends SerializationCluster {
  final List<ast.SetConstant> _objects = [];
  final List<ast.ListConstant> _dataLists = [];

  Object? _typeArguments(ast.SetConstant obj) {
    final typeArg = obj.typeArgument;
    if (typeArg is ast.DynamicType) return null;
    return TypeArgumentsConstant([typeArg]);
  }

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final obj = object as ast.SetConstant;
    final data = ast.ListConstant(const ast.DynamicType(), obj.entries);
    _objects.add(obj);
    _dataLists.add(data);
    serializer.push(_typeArguments(obj));
    serializer.push(data);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.sets.index);
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
    for (var i = 0; i < _objects.length; ++i) {
      final obj = _objects[i];
      final data = _dataLists[i];
      serializer.writeRefId(_typeArguments(obj));
      serializer.writeRefId(data);
      serializer.writeUint(obj.entries.length);
    }
  }
}

final class InstanceSerializationCluster extends SerializationCluster {
  final ast.Class _cls;
  final List<ast.InstanceConstant> _objects = [];

  InstanceSerializationCluster(this._cls);

  Object? _typeArguments(ast.InstanceConstant obj) {
    final typeArgs = getInstantiatorTypeArguments(_cls, obj.typeArguments);
    if (typeArgs == null) return null;
    return TypeArgumentsConstant(typeArgs);
  }

  List<ast.Reference?> _computeFieldOrder(
    SnapshotSerializer serializer,
    CField? typeArgumentsField,
  ) {
    final objectLayout = serializer.objectLayout;
    final offsetToField = <int, ast.Field>{};
    for (ast.Class? cls = _cls; cls != null; cls = cls.superclass) {
      for (final field in cls.fields) {
        if (field.isInstanceMember) {
          offsetToField[objectLayout.getFieldOffset(CField(field))] = field;
        }
      }
    }
    final typeArgsOffset = (typeArgumentsField != null)
        ? objectLayout.getFieldOffset(typeArgumentsField)
        : -1;
    final compressedWordSize = objectLayout.compressedWordSize;
    final firstOffset = objectLayout.vmOffsets.Instance_first_field_offset;
    final size = objectLayout.getUnalignedInstanceSize(_cls);
    // TODO: support unboxed fields
    return [
      for (
        int offset = firstOffset;
        offset < size;
        offset += compressedWordSize
      )
        (offset == typeArgsOffset)
            ? null
            : offsetToField[offset]!.fieldReference,
    ];
  }

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final obj = object as ast.InstanceConstant;
    assert(obj.classNode == _cls);
    _objects.add(obj);
    serializer.push(_cls);
    serializer.push(_typeArguments(obj));
    for (final fieldValue in obj.fieldValues.values) {
      serializer.push(fieldValue);
    }
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.instances.index);
    serializer.writeRefId(_cls);
  }

  @override
  void writeAlloc(SnapshotSerializer serializer) {
    serializer.writeUint(_objects.length);
    serializer.writeUint(
      serializer.objectLayout.getUnalignedInstanceSize(_cls),
    );
    serializer.writeUint(serializer.objectLayout.getInstanceSize(_cls));
    for (final obj in _objects) {
      serializer.assignRef(obj);
    }
  }

  @override
  void writeFill(SnapshotSerializer serializer) {
    final typeArgumentsField = serializer.objectLayout.getTypeArgumentsField(
      _cls,
    );
    final fields = _computeFieldOrder(serializer, typeArgumentsField);
    for (final obj in _objects) {
      for (final field in fields) {
        if (field == null) {
          serializer.writeRefId(_typeArguments(obj));
        } else {
          serializer.writeRefId(obj.fieldValues[field]!);
        }
      }
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

/// Declaration of type parameters, corresponds to the VM TypeParameters object.
class TypeParameters {
  final List<ast.StructuralParameter> params;
  TypeParameters(this.params);
}

final class FunctionTypeSerializationCluster extends SerializationCluster {
  final List<ast.FunctionType> _objects = [];
  final List<
    ({
      TypeParameters? typeParameters,
      ast.ListConstant parameterTypes,
      ast.ListConstant parameterNames,
    })
  >
  _fields = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final type = object as ast.FunctionType;
    _objects.add(type);
    final typeParameters = type.typeParameters.isNotEmpty
        ? TypeParameters(type.typeParameters)
        : null;
    final parameterTypes = getListConstant([
      const ast.DynamicType(), // implicit closure parameter
      ...type.positionalParameters,
      for (final np in type.namedParameters) np.type,
    ]);
    // TODO: encode parameter flags in the names array
    final parameterNames = getListConstant([
      for (final np in type.namedParameters) np.name,
    ]);
    serializer.push(typeParameters);
    serializer.push(type.returnType);
    serializer.push(parameterTypes);
    serializer.push(parameterNames);
    _fields.add((
      typeParameters: typeParameters,
      parameterTypes: parameterTypes,
      parameterNames: parameterNames,
    ));
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.functionTypes.index);
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
    for (var i = 0; i < _objects.length; i++) {
      final type = _objects[i];
      final fields = _fields[i];
      serializer.writeUint(
        type.declaredNullability == ast.Nullability.nullable ? 1 : 0,
      );
      serializer.writeRefId(fields.typeParameters);
      serializer.writeRefId(type.returnType);
      serializer.writeRefId(fields.parameterTypes);
      serializer.writeRefId(fields.parameterNames);
      serializer.writeUint(
        1 /* implicit closure parameter */ + type.requiredParameterCount,
      );
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

class ICData {
  final CFunction owner;
  final ArgumentsShape argumentsShape;
  final ast.Name targetName;
  ICData(this.owner, this.argumentsShape, this.targetName);
}

final class ICDataSerializationCluster extends SerializationCluster {
  final List<ICData> _objects = [];

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final obj = object as ICData;
    _objects.add(obj);
    serializer.push(obj.targetName);
    serializer.push(obj.argumentsShape);
    serializer.push(obj.owner);
  }

  @override
  void writePreLoad(SnapshotSerializer serializer) {
    serializer.writeUint(PredefinedClusters.icDatas.index);
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
    for (final obj in _objects) {
      serializer.writeRefId(obj.targetName);
      serializer.writeRefId(obj.argumentsShape);
      serializer.writeRefId(obj.owner);
    }
  }
}

final class ObjectPoolSerializationCluster extends SerializationCluster {
  final List<ObjectPool> _objects = [];
  final Map<InterfaceCallEntry, ICData> icDatas = {};

  @override
  void trace(SnapshotSerializer serializer, Object object) {
    final pool = object as ObjectPool;
    _objects.add(pool);
    for (final entry in pool.entries) {
      if (entry is SpecializedEntry) {
        switch (entry) {
          case NewObjectTags():
            serializer.push(entry.cls);
          case InterfaceCallEntry():
            // TODO: call through monomorphic/table dispatcher.
            final icData = icDatas[entry] = ICData(
              entry.owner,
              entry.argumentsShape,
              entry.interfaceTarget.member.name,
            );
            serializer.push(icData);
          case ReservedEntry():
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
            case InterfaceCallEntry():
              serializer.writeUint(ObjectPoolEntryKind.interfaceCall.index);
              serializer.writeRefId(icDatas[entry]);
            case ReservedEntry():
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

  void writeDouble(double value) {
    final buf = ByteData(8);
    buf.setFloat64(0, value, Endian.little);
    final intValue = buf.getInt64(0, Endian.little);
    writeInt(intValue);
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
