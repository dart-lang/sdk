// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/reference_from_index.dart' show ReferenceFromIndex;
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:vm/modular/transformations/ffi/common.dart' show FfiTransformer;

// Currently transforms `Native.addressOf` into a `throw`.
// TODO(https://github.com/dart-lang/sdk/issues/46690): Implement this for
// dart2wasm.
void transformLibraries(
  Component component,
  CoreTypes coreTypes,
  ClassHierarchy hierarchy,
  List<Library> libraries,
  DiagnosticReporter diagnosticReporter,
  ReferenceFromIndex? referenceFromIndex,
) {
  final index = LibraryIndex(component, [
    'dart:core',
    'dart:ffi',
    'dart:_internal',
    'dart:typed_data',
    'dart:nativewrappers',
    'dart:_wasm',
    'dart:isolate',
  ]);
  final transformer = WasmFfiNativeAddressTransformer(
    index,
    coreTypes,
    hierarchy,
    diagnosticReporter,
    referenceFromIndex,
  );
  libraries.forEach(transformer.visitLibrary);
}

class WasmFfiNativeAddressTransformer extends FfiTransformer {
  WasmFfiNativeAddressTransformer(
    super.index,
    super.coreTypes,
    super.hierarchy,
    super.diagnosticReporter,
    super.referenceFromIndex,
  );

  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.target == nativeAddressOf) {
      return Throw(
          StringLiteral('Native.addressOf is supported (yet) in dart2wasm.'));
    }
    return super.visitStaticInvocation(node);
  }
}
