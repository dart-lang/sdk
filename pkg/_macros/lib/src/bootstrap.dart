// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'executor/serialization.dart'
    show SerializationMode, SerializationModeHelpers;

/// Generates a Dart program for a given set of macros, which can be compiled
/// and then passed as a precompiled kernel file to `MacroExecutor.loadMacro`.
///
/// The [macroDeclarations] is a map from library URIs to macro classes for the
/// macros supported. The macro classes are provided as a map from macro class
/// names to the names of the macro class constructors.
///
/// The [serializationMode] must be a client variant.
String bootstrapMacroIsolate(
    Map<String, Map<String, List<String>>> macroDeclarations,
    SerializationMode serializationMode) {
  final StringBuffer imports = StringBuffer();
  final StringBuffer constructorEntries = StringBuffer();

  // Prepend template content
  return template.replaceFirst(_importMarker, _generateImports(macroDeclarations))
      .replaceFirst(_macroConstructorEntriesMarker, _generateConstructorEntries(macroDeclarations))
      .replaceFirst(_modeMarker, serializationMode.asCode);
}

const String _importMarker = '{{IMPORT}}';
const String _macroConstructorEntriesMarker = '{{MACRO_CONSTRUCTOR_ENTRIES}}';
const String _modeMarker = '{{SERIALIZATION_MODE}}';

const String template = '''
import 'dart:io';
import 'dart:isolate';

import 'package:_macros/src/executor/client.dart';
import 'package:_macros/src/executor/serialization.dart';

$_importMarker

/// Entrypoint to be spawned with [Isolate.spawnUri] or [Process.start].
///
/// Supports the client side of the macro expansion protocol.
void main(List<String> arguments, [SendPort? sendPort]) async {
  await MacroExpansionClient.start(
      $_modeMarker, _macroConstructors, arguments, sendPort);
}

/// Maps libraries by uri to macros by name, and then constructors by name.
final _macroConstructors = <Uri, Map<String, Map<String, Function>>>{
  $_macroConstructorEntriesMarker
};
''';

String _generateImports(Map<String, Map<String, List<String>>> macroDeclarations) {
  return macroDeclarations.entries.map((entry) {
    return 'import \'${entry.key}\';\n';
  }).join('');
}

String _generateConstructorEntries(Map<String, Map<String, List<String>>> macroDeclarations) {
  return '{\n${macroDeclarations.entries.map((entry) {
    return '${entry.key}: {\n${entry.value.entries.map((innerEntry) {
      return '${innerEntry.key}: ${innerEntry.value.first.isEmpty ? 'new' : innerEntry.value.first},\n';
    }).toList().join('')}\n},\n';
  }).toList().join('')}';
}
