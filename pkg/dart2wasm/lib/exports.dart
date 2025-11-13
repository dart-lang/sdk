// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart';

import 'dynamic_module_kernel_metadata.dart'
    show DynamicModuleConstants, MainModuleMetadata;
import 'util.dart';

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
      name = intToMinString(_nameCounter++);
    } while (_reservedNames.contains(name));
    return name;
  }
}

/// Manages exporting entities in a minification-aware way.
///
/// The [Exporter] records mappings between entities exported from a dynamic
/// main module and their export names so that dynamic submodule compilation can
/// discover the right names to import those entities.
/// - The callable reference mapping is stored in [_mainModuleMetadata], since
///   the [DataSerializer] is capable of correctly serializing [Reference]s (but
///   not [Constant]s).
/// - The constant (and constant initializer) mapping is stored in
///   [_dynamicModuleConstants], which is serialized via a
///   [DynamicModuleConstantRepository], since the kernel [BinarySink] can
///   handle [Constant]s (but not [Reference]s that come from the TFA'd
///   [Component] but must be written to metadata on the un-TFA'd [Component]).
///
/// The `exportDynamic___` methods add relevant associations to the above
/// mappings and add the given exportable to the Wasm exports of the specified
/// module under the computed export name.
///
/// For deferred imports, the [export] method is sufficient.
class Exporter {
  final ExportNamer _namer;
  final MainModuleMetadata _mainModuleMetadata;
  final DynamicModuleConstants? _dynamicModuleConstants;

  Exporter(this._namer, this._mainModuleMetadata, this._dynamicModuleConstants);

  int get _nextDynamicCallableId =>
      _mainModuleMetadata.callableReferenceNames.length;
  int get _nextDynamicConstantId =>
      _dynamicModuleConstants!.constantNames.length;

  static String _dynamicCallableName(int id) => '#dynamicCallable$id';
  static String _dynamicConstantName(int id) => '#constant$id';
  static String _dynamicConstantInitializerName(int id) =>
      '#constantInitializer$id';

  void exportDynamicCallable(ModuleBuilder module, BaseFunction function,
      Reference callableReference) {
    _mainModuleMetadata.callableReferenceNames[callableReference] =
        export(module, _dynamicCallableName(_nextDynamicCallableId), function);
  }

  void exportDynamicConstant(
      ModuleBuilder module, Constant constant, Global global,
      {BaseFunction? initializer}) {
    final id = _nextDynamicConstantId;
    _exportConstant(module, constant, global, id);
    if (initializer != null) {
      _exportConstantInitializer(module, constant, initializer, id);
    }
  }

  void _exportConstant(
      ModuleBuilder module, Constant constant, Global global, int id) {
    _dynamicModuleConstants!.constantNames[constant] =
        export(module, _dynamicConstantName(id), global);
  }

  void _exportConstantInitializer(ModuleBuilder module, Constant constant,
      BaseFunction initializer, int id) {
    _dynamicModuleConstants!.constantInitializerNames[constant] =
        export(module, _dynamicConstantInitializerName(id), initializer);
  }

  String export(ModuleBuilder module, String name, Exportable exportable) {
    final exportName = _namer._getExportName(name);
    module.exports.export(exportName, exportable);
    return exportName;
  }
}
