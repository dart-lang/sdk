// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'dynamic_module_kernel_metadata.dart';
import 'namer.dart';

/// Manages exporting entities for dynamic modules.
///
/// The [DynamicModuleExporter] records mappings between entities exported from a
/// dynamic main module and their export names so that dynamic submodule
/// compilation can discover the right names to import those entities.
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
class DynamicModuleExporter {
  final Namer _exportNamer;
  final MainModuleMetadata _mainModuleMetadata;
  final DynamicModuleConstants? _dynamicModuleConstants;

  final CoreTypes coreTypes;

  DynamicModuleExporter(
    this.coreTypes,
    this._mainModuleMetadata,
    this._dynamicModuleConstants,
    this._exportNamer,
  );

  int get _nextDynamicCallableId =>
      _mainModuleMetadata.callableReferenceNames.length;
  int get _nextDynamicConstantId =>
      _dynamicModuleConstants!.constantNames.length;

  static String _dynamicCallableName(int id) => '#dynamicCallable$id';
  static String _dynamicConstantName(int id) => '#constant$id';
  static String _dynamicConstantInitializerName(int id) =>
      '#constantInitializer$id';

  void exportDynamicModuleCallable(
    w.ModuleBuilder module,
    w.BaseFunction function,
    Reference callableReference,
  ) {
    _mainModuleMetadata.callableReferenceNames[callableReference] = _export(
      module,
      _dynamicCallableName(_nextDynamicCallableId),
      function,
    );
  }

  void exportDynamicModuleConstant(
    w.ModuleBuilder module,
    Constant constant,
    w.Global global, {
    w.BaseFunction? initializer,
  }) {
    final id = _nextDynamicConstantId;
    _exportConstant(module, constant, global, id);
    if (initializer != null) {
      _exportConstantInitializer(module, constant, initializer, id);
    }
  }

  void _exportConstant(
    w.ModuleBuilder module,
    Constant constant,
    w.Global global,
    int id,
  ) {
    _dynamicModuleConstants!.constantNames[constant] = _export(
      module,
      _dynamicConstantName(id),
      global,
    );
  }

  void _exportConstantInitializer(
    w.ModuleBuilder module,
    Constant constant,
    w.BaseFunction initializer,
    int id,
  ) {
    _dynamicModuleConstants!.constantInitializerNames[constant] = _export(
      module,
      _dynamicConstantInitializerName(id),
      initializer,
    );
  }

  String _export(w.ModuleBuilder module, String name, w.Exportable exportable) {
    final exportName = _exportNamer.getName(name);
    module.exports.export(exportName, exportable);
    return exportName;
  }
}
