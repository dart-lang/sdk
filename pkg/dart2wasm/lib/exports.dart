// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart';

import 'util.dart';

class DynamicModuleExportRepository
    extends MetadataRepository<DynamicModuleExports> {
  static const repositoryTag = 'wasm.dynamic-modules.exports';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, DynamicModuleExports> mapping = {};

  @override
  DynamicModuleExports readFromBinary(_, BinarySource source) {
    return DynamicModuleExports._readFromBinary(source);
  }

  @override
  void writeToBinary(DynamicModuleExports exports, Node node, BinarySink sink) {
    exports._writeToBinary(sink);
  }
}

class DynamicModuleExports {
  final Map<int, String> _callableNames = {};
  final Map<int, String> _constantNames = {};
  final Map<int, String> _constantInitializerNames = {};

  DynamicModuleExports();

  factory DynamicModuleExports._readFromBinary(BinarySource source) {
    void readMap(Map<int, String> map) {
      final length = source.readUInt30();
      for (int i = 0; i < length; i++) {
        final id = source.readUInt30();
        final name = source.readStringReference();
        map[id] = name;
      }
    }

    final exports = DynamicModuleExports();
    readMap(exports._callableNames);
    readMap(exports._constantNames);
    readMap(exports._constantInitializerNames);
    return exports;
  }

  void _writeToBinary(BinarySink sink) {
    void writeMap(Map<int, String> map) {
      sink.writeUInt30(map.length);
      map.forEach((id, name) {
        sink.writeUInt30(id);
        sink.writeStringReference(name);
      });
    }

    writeMap(_callableNames);
    writeMap(_constantNames);
    writeMap(_constantInitializerNames);
  }

  String? getCallableName(int callableReferenceId) =>
      _callableNames[callableReferenceId];

  String? getConstantName(int constantId) => _constantNames[constantId];

  String? getConstantInitializerName(int constantId) =>
      _constantInitializerNames[constantId];
}

/// A generator for export names (when minification is enabled).
///
/// For simplicity and readability of generated names, we just use the base64
/// encoding of an integer counter.
class ExportNamer {
  final bool minify;

  ExportNamer(this.minify);

  final Set<String> _reservedNames = {};

  /// Mark a name as reserved by the `wasm:export` or `wasm:weak-export`
  /// annotations so that it will not be generated as a minified export name.
  void reserveName(String name) {
    if (!minify) return;
    final added = _reservedNames.add(name);
    assert(added, "Name '$name' is already reserved");
  }

  int _nameCounter = 0;

  String _getExportName(String name) {
    if (!minify) return name;
    do {
      name = intToBase64(_nameCounter++);
    } while (_reservedNames.contains(name));
    return name;
  }
}

/// Manages exporting entities in a minification-aware way.
///
/// The [Exporter] stores associations between entities exported from a dynamic
/// main module and their export names in [dynamicModuleExports] so that dynamic
/// submodules can import these entities with those names.
///
/// The `export___` methods add relevant associations to [dynamicModuleExports]
/// and add the given exportable to the Wasm exports of the specified module
/// under the computed export name.
class Exporter {
  final ExportNamer _namer;

  Exporter(this._namer);

  final DynamicModuleExports dynamicModuleExports = DynamicModuleExports();

  void exportCallable(ModuleBuilder module, String name,
      FunctionBuilder function, int callableReferenceId) {
    dynamicModuleExports._callableNames[callableReferenceId] =
        _export(module, name, function);
  }

  void exportConstant(ModuleBuilder module, String name, GlobalBuilder constant,
      int constantId) {
    dynamicModuleExports._constantNames[constantId] =
        _export(module, name, constant);
  }

  void exportConstantInitializer(ModuleBuilder module, String name,
      FunctionBuilder initializer, int constantId) {
    dynamicModuleExports._constantInitializerNames[constantId] =
        _export(module, name, initializer);
  }

  String _export(ModuleBuilder module, String name, Exportable exportable) {
    final exportName = _namer._getExportName(name);
    module.exports.export(exportName, exportable);
    return exportName;
  }
}
