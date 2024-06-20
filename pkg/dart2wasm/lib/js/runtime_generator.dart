// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show json;

import 'package:_js_interop_checks/src/js_interop.dart'
    show calculateTransitiveImportsOfJsInteropIfUsed;
import 'package:_js_interop_checks/src/transformations/static_interop_class_eraser.dart';
import 'package:collection/collection.dart' show compareNatural;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

import '../target.dart' as wasm_target;
import 'interop_transformer.dart';
import 'method_collector.dart';
import 'runtime_blob.dart';

JSMethods _performJSInteropTransformations(
    Component component,
    CoreTypes coreTypes,
    ClassHierarchy classHierarchy,
    Set<Library> interopDependentLibraries) {
  // Transform kernel and generate JS methods.
  final transformer = InteropTransformer(coreTypes, classHierarchy);
  for (final library in interopDependentLibraries) {
    transformer.visitLibrary(library);
  }

  // We want static types to help us specialize methods based on receivers.
  // Therefore, erasure must come after the lowering.
  final jsValueClass = coreTypes.index.getClass('dart:_js_helper', 'JSValue');
  final staticInteropClassEraser = StaticInteropClassEraser(coreTypes,
      eraseStaticInteropType: (staticInteropType) =>
          InterfaceType(jsValueClass, staticInteropType.declaredNullability),
      additionalCoreLibraries: {
        '_js_helper',
        '_js_string_convert',
        '_js_types',
        '_string',
        'convert',
        'js_interop',
        'js_interop_unsafe',
      });
  for (Library library in interopDependentLibraries) {
    staticInteropClassEraser.visitLibrary(library);
  }
  return transformer.jsMethods;
}

class RuntimeFinalizer {
  final Map<Procedure, String> allJSMethods;

  RuntimeFinalizer(this.allJSMethods);

  String generate(Iterable<Procedure> translatedProcedures,
      List<String> constantStrings, wasm_target.Mode mode) {
    String escape(String s) => json.encode(s);

    Set<Procedure> usedProcedures = {};
    List<String> usedJSMethods = [];
    for (Procedure p in translatedProcedures) {
      if (usedProcedures.add(p) && allJSMethods.containsKey(p)) {
        usedJSMethods.add(allJSMethods[p]!);
      }
    }
    // Sort so _9 comes before _11 (for example)
    usedJSMethods.sort(compareNatural);

    String internalizedStrings = '';
    if (constantStrings.isNotEmpty) {
      internalizedStrings = '''
s: [
  ${constantStrings.map(escape).join(',\n')}
],''';
    }
    return '''
$jsRuntimeBlobPart1
${mode == wasm_target.Mode.jsCompatibility ? jsRuntimeBlobPart2JSCM : jsRuntimeBlobPart2Regular}
$jsRuntimeBlobPart3
${usedJSMethods.join(',\n')}
$jsRuntimeBlobPart4
$internalizedStrings
$jsRuntimeBlobPart5
''';
  }
}

RuntimeFinalizer createRuntimeFinalizer(
    Component component, CoreTypes coreTypes, ClassHierarchy classHierarchy) {
  Set<Library> transitiveImportingJSInterop = {
    ...calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("package:js/js.dart")),
    ...calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:_js_annotations")),
    ...calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:_js_helper")),
    ...calculateTransitiveImportsOfJsInteropIfUsed(
        component, Uri.parse("dart:js_interop")),
  };
  Map<Procedure, String> jsInteropMethods = {};
  jsInteropMethods = _performJSInteropTransformations(
      component, coreTypes, classHierarchy, transitiveImportingJSInterop);
  return RuntimeFinalizer(jsInteropMethods);
}
