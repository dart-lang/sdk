// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns the content of a file containing [classCount] classes.
///
/// If [exports] are provided, the file will contain one export directive for
/// each element. The elements should be the text of the URI without enclosing
/// quotes.
///
/// If [imports] are provided, the file will contain one import directive for
/// each element. The elements should be the text of the URI without enclosing
/// quotes.
///
/// If a [libraryName] is provided, the file will contain a library directive
/// with that name. There's no way to generate a library directive without a
/// name.
///
/// If a [partOf] is provided, the file will contain a part-of directive. If the
/// [partOf] ends with `.dart` then it is assumed to be a URI and will be
/// enclosed in quotes. If not, it's assumed to be a library name and is written
/// as-is.
///
/// If [parts] are provided, the file will contain one part directive for each
/// element. The elements should be the text of the URI without enclosing
/// quotes.
String createFileContent({
  int classCount = CodeGenerator.classCount,
  List<String> exports = const [],
  List<String> imports = const [],
  String? libraryName,
  String? partOf,
  List<String> parts = const [],
}) {
  var generator = CodeGenerator();
  generator.writeClasses(
    classCount: classCount,
    exports: exports,
    imports: imports,
    libraryName: libraryName,
    partOf: partOf,
    parts: parts,
  );
  return generator.code;
}

/// A class used to generate code for a test.
class CodeGenerator {
  /// The number of classes in each test file.
  static const int classCount = 40;

  /// The buffer used to collect the code being generated.
  final StringBuffer buffer = StringBuffer();

  /// Whether a blank line should be added before the next top-level declaration
  /// is written.
  bool needsSeparator = false;

  /// The code that was generated.
  String get code => buffer.toString();

  /// Generate a class with the given [name].
  ///
  /// The [methodCount] specifies the number of methods that should be defined
  /// by the class.
  void writeClass({required String name, int methodCount = 100}) {
    if (needsSeparator) {
      buffer.writeln();
    }
    buffer.writeln('class $name {');
    var needsLineBeforeMember = false;
    for (var i = 0; i < methodCount; i++) {
      if (needsLineBeforeMember) {
        buffer.writeln();
      }
      writeMethod(name: 'm$i');
      needsLineBeforeMember = true;
    }
    buffer.writeln('}');
    needsSeparator = true;
  }

  /// Generate [classCount] classes with synthetic names.
  ///
  /// The file will have one export for each of the unquoted URI's in [exports].
  ///
  /// The file will have one part directive for each of the unquoted URI's in [parts].
  ///
  /// The file will have one import for each of the unquoted URI's in [imports].
  /// For example, to import `dart:async`, include `'dart:async'` in the list.
  void writeClasses({
    required int classCount,
    List<String> exports = const [],
    List<String> imports = const [],
    String? libraryName,
    String? partOf,
    List<String> parts = const [],
  }) {
    assert(
      libraryName == null || partOf == null,
      'Cannot specify both a library name and a part of name',
    );
    if (libraryName != null) {
      buffer.writeln('library $libraryName;');
      buffer.writeln();
    }
    if (partOf != null) {
      if (partOf.endsWith('.dart')) {
        buffer.writeln("part of '$partOf';");
      } else {
        buffer.writeln('part of $partOf;');
      }
      buffer.writeln();
    }
    for (var import in imports) {
      buffer.writeln("import '$import';");
    }
    if (imports.isNotEmpty) {
      buffer.writeln();
    }
    for (var export in exports) {
      buffer.writeln("export '$export';");
    }
    if (exports.isNotEmpty) {
      buffer.writeln();
    }
    for (var part in parts) {
      buffer.writeln("part '$part';");
    }
    if (parts.isNotEmpty) {
      buffer.writeln();
    }
    for (int i = 0; i < classCount; i++) {
      writeClass(name: 'C$i');
    }
  }

  /// Generate a method with the given [name].
  void writeMethod({required String name}) {
    buffer.write('''
  void $name(StringBuffer buffer, Map<String, Object> map) {
    buffer.write('{');
    for (var entry in map.entries) {
      buffer.write(entry.key);
      buffer.write(': ');
      var value = entry.value;
      if (value is Map<String, Object>) {
        $name(buffer, value);
        buffer.writeln();
      } else {
        buffer.write(value);
      }
      buffer.writeln(entry.value);
    }
    buffer.write('}');
  }
''');
  }
}
