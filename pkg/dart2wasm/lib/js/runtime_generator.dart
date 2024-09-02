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
  final Map<Procedure, ({String importName, String jsCode})> allJSMethods;

  RuntimeFinalizer(this.allJSMethods);

  String generate(Iterable<Procedure> translatedProcedures,
      List<String> constantStrings, wasm_target.Mode mode) {
    String escape(String s) => json.encode(s);

    Set<Procedure> usedProcedures = {};
    final usedJSMethods = <({String importName, String jsCode})>[];
    for (Procedure p in translatedProcedures) {
      if (usedProcedures.add(p) && allJSMethods.containsKey(p)) {
        usedJSMethods.add(allJSMethods[p]!);
      }
    }
    // Sort so _9 comes before _11 (for example)
    usedJSMethods.sort((a, b) => compareNatural(a.importName, b.importName));

    final jsMethods = StringBuffer();
    for (final jsMethod in usedJSMethods) {
      jsMethods.write('      ');
      jsMethods.write(jsMethod.importName);
      jsMethods.write(': ');
      final lines = _unindentJsCode(jsMethod.jsCode);
      for (int i = 0; i < lines.length; ++i) {
        if (i != 0) {
          jsMethods.write('      ');
        }
        jsMethods.write(lines[i]);
        if (i < (lines.length - 1)) {
          jsMethods.writeln();
        } else {
          jsMethods.writeln(',');
        }
      }
    }

    String internalizedStrings = '';
    if (constantStrings.isNotEmpty) {
      internalizedStrings = '''
      s: [
        ${constantStrings.map(escape).join(',\n')}
      ],
''';
    }
    return '''
$jsRuntimeBlobPart1
$jsRuntimeBlobPart3
$jsMethods
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
  final jsInteropMethods = _performJSInteropTransformations(
      component, coreTypes, classHierarchy, transitiveImportingJSInterop);
  return RuntimeFinalizer(jsInteropMethods);
}

// Removes indentation common among all lines of [block] (except for first one)
List<String> _unindentJsCode(String block) {
  block = block.trim();
  final lines = block.split('\n');
  if (lines.length == 1) return lines;

  int minSpaces = -1;
  for (int i = 1; i < lines.length; ++i) {
    final line = lines[i];
    final currentSpaces = _countLeadingSpaces(line);
    if (currentSpaces == line.length) continue; // empty line
    if (minSpaces == -1 || currentSpaces < minSpaces) {
      minSpaces = currentSpaces;
    }
  }

  if (minSpaces > 0) {
    for (int i = 1; i < lines.length; ++i) {
      final line = lines[i];
      if (line.length <= minSpaces) {
        lines[i] = '';
      } else {
        lines[i] = lines[i].substring(minSpaces);
      }
    }
  }
  return lines;
}

int _countLeadingSpaces(String line) {
  int spaces = 0;
  for (int i = 0; i < line.length; ++i) {
    if (line.codeUnitAt(i) != ' '.codeUnitAt(0)) break;
    spaces++;
  }
  return spaces;
}
