// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data' show Uint8List;

import 'package:dart2bytecode/bytecode_generator.dart' show generateBytecode;
import 'package:dart2bytecode/options.dart' show BytecodeOptions;
import 'package:kernel/ast.dart' show Component, Library;
import 'package:kernel/binary/ast_to_binary.dart' show BytesSink;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/target/targets.dart' show Target;

import '../../vm/bin/kernel_service.dart' as kernel_service;

Uint8List _generateBytecode(
    Component component,
    List<Library> libraries,
    CoreTypes coreTypes,
    ClassHierarchy hierarchy,
    Target target,
    bool enableAsserts,
    {Set<Library> extraLoadedLibraries = const {}}) {
  final byteSink = new BytesSink();
  generateBytecode(component, byteSink,
      libraries: libraries,
      extraLoadedLibraries: extraLoadedLibraries,
      coreTypes: coreTypes,
      hierarchy: hierarchy,
      target: target,
      options: BytecodeOptions(
        enableAsserts: enableAsserts,
        emitSourcePositions: true,
        emitLocalVarInfo: true,
        emitInstanceFieldInitializers: true,
        embedSourceText: true,
      ));
  return byteSink.builder.takeBytes();
}

// Wire up bytecode generator to the kernel service to avoid
// circular dependency between package:vm and package:dart2bytecode.
main([args]) {
  kernel_service.bytecodeGenerator = _generateBytecode;
  return kernel_service.main(args);
}
