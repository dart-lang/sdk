// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tools for generating code in analyzer and analysis server.
library;

import 'dart:async';
import 'dart:io';

import 'package:analyzer_utilities/html_dom.dart' as dom;
import 'package:analyzer_utilities/html_generator.dart';
import 'package:analyzer_utilities/text_formatter.dart';
import 'package:dart_style/dart_style.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

final RegExp trailingSpacesInLineRegExp = RegExp(r' +$', multiLine: true);
final RegExp trailingWhitespaceRegExp = RegExp(r'[\n ]+$');

/// Join the given strings using camelCase.  If [doCapitalize] is true, the first
/// part will be capitalized as well.
String camelJoin(List<String> parts, {bool doCapitalize = false}) {
  var upcasedParts = <String>[];
  for (var i = 0; i < parts.length; i++) {
    if (i == 0 && !doCapitalize) {
      upcasedParts.add(parts[i]);
    } else {
      upcasedParts.add(capitalize(parts[i]));
    }
  }
  return upcasedParts.join();
}

/// Capitalize and return the passed String.
String capitalize(String string) {
  return string[0].toUpperCase() + string.substring(1);
}

/// Type of functions used to compute the contents of a set of generated files.
/// [pkgRoot] is the path to the SDK's `pkg` directory.
typedef DirectoryContentsComputer =
    Map<String, FileContentsComputer> Function(String pkgRoot);

/// Type of functions used to compute the contents of a generated file.
/// [pkgRoot] is the path to the SDK's `pkg` directory.
typedef FileContentsComputer = Future<String> Function(String pkgRoot);

/// Mixin class for generating code.
mixin CodeGenerator {
  _CodeGeneratorState _state = _CodeGeneratorState();

  /// Settings that specialize code generation behavior for a given
  /// programming language.
  CodeGeneratorSettings codeGeneratorSettings = CodeGeneratorSettings();

  /// Measure the width of the current indentation level.
  int get indentWidth => _state.nextIndent.length;

  /// Execute [callback], collecting any code that is output using [write]
  /// or [writeln], and return the result as a string.
  String collectCode(
    void Function() callback, {
    bool removeTrailingNewLine = false,
  }) {
    var oldState = _state;
    try {
      _state = _CodeGeneratorState();
      callback();
      var text = _state.buffer.toString().replaceAll(
        trailingSpacesInLineRegExp,
        '',
      );
      if (!removeTrailingNewLine) {
        return text;
      } else {
        return text.replaceAll(trailingWhitespaceRegExp, '');
      }
    } finally {
      _state = oldState;
    }
  }

  /// Generate a doc comment based on the HTML in [docs].
  ///
  /// When generating java code, the output is compatible with Javadoc, which
  /// understands certain HTML constructs.
  void docComment(List<dom.Node> docs, {bool removeTrailingNewLine = false}) {
    if (containsOnlyWhitespace(docs)) return;

    var startMarker = codeGeneratorSettings.docCommentStartMarker;
    if (startMarker != null) {
      writeln(startMarker);
    }

    var width = codeGeneratorSettings.commentLineLength;
    var javadocStyle = codeGeneratorSettings.languageName == 'java';
    indentBy(codeGeneratorSettings.docCommentLineLeader, () {
      write(
        nodesToText(
          docs,
          width - _state.indent.length,
          javadocStyle,
          removeTrailingNewLine: removeTrailingNewLine,
        ),
      );
    });

    var endMarker = codeGeneratorSettings.docCommentEndMarker;
    if (endMarker != null) {
      writeln(endMarker);
    }
  }

  /// Execute [callback], indenting any code it outputs.
  void indent(void Function() callback) {
    indentSpecial(
      codeGeneratorSettings.indent,
      codeGeneratorSettings.indent,
      callback,
    );
  }

  /// Execute [callback], using [additionalIndent] to indent any code it outputs.
  void indentBy(String additionalIndent, void Function() callback) =>
      indentSpecial(additionalIndent, additionalIndent, callback);

  /// Execute [callback], using [additionalIndent] to indent any code it outputs.
  /// The first line of output is indented by [firstAdditionalIndent] instead of
  /// [additionalIndent].
  void indentSpecial(
    String firstAdditionalIndent,
    String additionalIndent,
    void Function() callback,
  ) {
    var oldNextIndent = _state.nextIndent;
    var oldIndent = _state.indent;
    try {
      _state.nextIndent += firstAdditionalIndent;
      _state.indent += additionalIndent;
      callback();
    } finally {
      _state.nextIndent = oldNextIndent;
      _state.indent = oldIndent;
    }
  }

  void lineComment(List<dom.Node> docs) {
    if (containsOnlyWhitespace(docs)) {
      return;
    }
    write(codeGeneratorSettings.lineCommentLineLeader);
    var width = codeGeneratorSettings.commentLineLength;
    indentBy(codeGeneratorSettings.lineCommentLineLeader, () {
      write(nodesToText(docs, width - _state.indent.length, false));
    });
  }

  void outputHeader({bool javaStyle = false, String? year}) {
    String header;
    if (codeGeneratorSettings.languageName == 'java') {
      header = '''
/*
 * Copyright (c) ${year ?? '2019'}, the Dart project authors. Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * This file has been automatically generated. Please do not edit it manually.
 * To regenerate the file, use the script "pkg/analysis_server/tool/spec/generate_files".
 */''';
    } else if (codeGeneratorSettings.languageName == 'python') {
      header = '''
# Copyright (c) ${year ?? '2014'}, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This file has been automatically generated. Please do not edit it manually.
# To regenerate the file, use the script
# "pkg/analysis_server/tool/spec/generate_files".
''';
    } else {
      header = '''
// Copyright (c) ${year ?? '2014'}, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".
''';
    }
    writeln(header.trim());
  }

  /// Output text without ending the current line.
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /// Output text, ending the current line.
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }
}

/// Controls several settings of [CodeGenerator].
///
/// The default settings are valid for generating Java and Dart code.
class CodeGeneratorSettings {
  /// Name of the language being generated. Lowercase.
  String languageName;

  /// Marker used in line comments.
  String lineCommentLineLeader;

  /// Start marker for doc comments.
  String? docCommentStartMarker;

  /// Line leader for body lines in doc comments.
  String docCommentLineLeader;

  /// End marker for doc comments.
  String? docCommentEndMarker;

  /// Line length for doc comment lines.
  int commentLineLength;

  /// String used for indenting code.
  String indent;

  CodeGeneratorSettings({
    this.languageName = 'java',
    this.lineCommentLineLeader = '// ',
    this.docCommentStartMarker = '/**',
    this.docCommentLineLeader = ' * ',
    this.docCommentEndMarker = ' */',
    this.commentLineLength = 99,
    this.indent = '  ',
  });
}

/// A utility class for invoking 'dart format'.
class DartFormat {
  static String get _dartPath => Platform.resolvedExecutable;

  static void formatFile(File file) {
    var result = Process.runSync(_dartPath, ['format', file.path]);
    _throwIfExitCode(result);
  }

  static Future<String> _formatText(
    String text, {
    required String pkgPath,
  }) async {
    var packageConfig = await findPackageConfig(Directory(pkgPath));
    if (packageConfig == null) {
      throw StateError(
        'Could not find the shared Dart SDK package_config.json file, for '
        '"$pkgPath"',
      );
    }
    var package = packageConfig.packageOf(
      Uri.file(join(pkgPath, 'pubspec.yaml')),
    );
    if (package == null) {
      throw StateError('Could not find the package for "$pkgPath"');
    }
    var languageVersion = package.languageVersion;
    if (languageVersion == null) {
      throw StateError('Could not find a Dart language version for "$pkgPath"');
    }
    var version = Version(languageVersion.major, languageVersion.minor, 0);
    return DartFormatter(languageVersion: version).format(text);
  }

  static void _throwIfExitCode(ProcessResult result) {
    if (result.exitCode != 0) throw result.stderr as Object;
  }
}

/// Abstract base class representing behaviors common to generated files and
/// generated directories.
abstract class GeneratedContent {
  /// Check whether the [output] has the correct contents, and return true if it
  /// does.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.
  Future<bool> check(String pkgRoot);

  /// Replace the [output] with the correct contents.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.
  Future<void> generate(String pkgRoot);

  /// Get a [FileSystemEntity] representing the output file or directory.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.
  FileSystemEntity output(String pkgRoot);

  /// Check that all of the [targets] are up to date.  If they are not, print
  /// out a message instructing the user to regenerate them, and exit with a
  /// nonzero error code.
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.  [generatorPath] is
  /// the path to a .dart script the user may use to regenerate the targets.
  ///
  /// To avoid mistakes when run on Windows, [generatorPath] always uses
  /// POSIX directory separators.
  static Future<void> checkAll(
    String pkgRoot,
    String generatorPath,
    Iterable<GeneratedContent> targets,
  ) async {
    var generateNeeded = false;
    for (var target in targets) {
      var ok = await target.check(pkgRoot);
      if (!ok) {
        print(
          '${normalize(target.output(pkgRoot).absolute.path)}'
          " doesn't have expected contents.",
        );
        generateNeeded = true;
      }
    }
    if (generateNeeded) {
      print('Please regenerate using:');
      var executable = Platform.executable;
      var generateScript = normalize(joinAll(posix.split(generatorPath)));
      print('  $executable $generateScript');
      fail('Generated content needs to be regenerated');
    }
  }

  /// Regenerate all of the [targets].
  ///
  /// [pkgRoot] is the path to the SDK's `pkg` directory.
  static Future<void> generateAll(
    String pkgRoot,
    Iterable<GeneratedContent> targets,
  ) async {
    print('Generating...');
    for (var target in targets) {
      await target.generate(pkgRoot);
    }
  }
}

/// Class representing a single output directory (either generated code or
/// generated HTML). No other content should exist in the directory.
class GeneratedDirectory extends GeneratedContent {
  /// The path to the directory that will have the generated content, relative
  /// to the `pkg` directory.
  ///
  /// This pathname uses the posix path separator ('/') regardless of the OS.
  final String outputDirPath;

  /// Callback function that computes the directory contents.
  final DirectoryContentsComputer directoryContentsComputer;

  GeneratedDirectory(this.outputDirPath, this.directoryContentsComputer);

  @override
  Future<bool> check(String pkgRoot) async {
    var outputDirectory = output(pkgRoot);
    var map = directoryContentsComputer(pkgRoot);
    try {
      for (var entry in map.entries) {
        var file = entry.key;
        var fileContentsComputer = entry.value;
        var expectedContents = await fileContentsComputer(pkgRoot);
        var outputFile = File(posix.join(outputDirectory.path, file));
        var actualContents = outputFile.readAsStringSync();
        // Normalize Windows line endings to Unix line endings so that the
        // comparison doesn't fail on Windows.
        actualContents = actualContents.replaceAll('\r\n', '\n');
        if (expectedContents != actualContents) {
          return false;
        }
      }
      var nonHiddenFileCount = 0;
      outputDirectory.listSync(recursive: false, followLinks: false).forEach((
        FileSystemEntity fileSystemEntity,
      ) {
        if (fileSystemEntity is File &&
            !basename(fileSystemEntity.path).startsWith('.')) {
          nonHiddenFileCount++;
        }
      });
      if (nonHiddenFileCount != map.length) {
        // The number of files generated doesn't match the number we expected to
        // generate.
        return false;
      }
    } catch (e) {
      // There was a problem reading the file (most likely because it didn't
      // exist).  Treat that the same as if the file doesn't have the expected
      // contents.
      return false;
    }
    return true;
  }

  @override
  Future<void> generate(String pkgRoot) async {
    var outputDirectory = output(pkgRoot);
    try {
      // delete the contents of the directory (and the directory itself)
      outputDirectory.deleteSync(recursive: true);
    } catch (e) {
      // Error caught while trying to delete the directory, this can happen if
      // it didn't yet exist.
    }
    // re-create the empty directory
    outputDirectory.createSync(recursive: true);

    // generate all of the files in the directory
    var map = directoryContentsComputer(pkgRoot);
    for (var entry in map.entries) {
      var file = entry.key;
      var fileContentsComputer = entry.value;
      var outputFile = File(posix.join(outputDirectory.path, file));
      print('  ${normalize(outputFile.path)}');
      var contents = await fileContentsComputer(pkgRoot);
      outputFile.writeAsStringSync(contents);
    }
  }

  @override
  Directory output(String pkgRoot) =>
      Directory(join(pkgRoot, joinAll(posix.split(outputDirPath))));
}

/// Class representing a single output file (either generated code or generated
/// HTML).
class GeneratedFile extends GeneratedContent {
  /// The output file to which generated output should be written, relative to
  /// the `pkg` directory.
  ///
  /// This filename uses the posix path separator ('/') regardless of the OS.
  final String outputPath;

  /// Callback function which computes the file.
  final FileContentsComputer computeContents;

  GeneratedFile(this.outputPath, this.computeContents);

  bool get isDartFile => outputPath.endsWith('.dart');

  @override
  Future<bool> check(String pkgRoot) async {
    var outputFile = output(pkgRoot);
    var expectedContents = await computeContents(pkgRoot);
    if (isDartFile) {
      expectedContents = await DartFormat._formatText(
        expectedContents,
        pkgPath: dirname(outputFile.path),
      );
    }
    try {
      var actualContents = outputFile.readAsStringSync();
      // Normalize Windows line endings to Unix line endings so that the
      // comparison doesn't fail on Windows.
      actualContents = actualContents.replaceAll('\r\n', '\n');
      expectedContents = expectedContents.replaceAll('\r\n', '\n');
      return expectedContents == actualContents;
    } catch (e) {
      // There was a problem reading the file (most likely because it didn't
      // exist).  Treat that the same as if the file doesn't have the expected
      // contents.
      return false;
    }
  }

  @override
  Future<void> generate(String pkgRoot) async {
    var outputFile = output(pkgRoot);
    print('  ${normalize(outputFile.path)}');
    var contents = await computeContents(pkgRoot);
    outputFile.writeAsStringSync(contents);
    if (isDartFile) {
      DartFormat.formatFile(outputFile);
    }
  }

  @override
  File output(String pkgRoot) =>
      File(normalize(join(pkgRoot, joinAll(posix.split(outputPath)))));
}

/// Mixin class for generating HTML representations of code that are suitable
/// for enclosing inside a <pre> element.
mixin HtmlCodeGenerator {
  _HtmlCodeGeneratorState _state = _HtmlCodeGeneratorState();

  /// Add the given [node] to the HTML output.
  void add(dom.Node node) {
    _state.add(node);
  }

  /// Add the given [nodes] to the HTML output.
  void addAll(Iterable<dom.Node> nodes) {
    for (var node in nodes) {
      _state.add(node);
    }
  }

  /// Execute [callback], collecting any code that is output using [write],
  /// [writeln], [add], or [addAll], and return the result as a list of DOM
  /// nodes.
  List<dom.Node> collectHtml(void Function()? callback) {
    var oldState = _state;
    try {
      _state = _HtmlCodeGeneratorState();
      if (callback != null) {
        callback();
      }
      return _state.buffer;
    } finally {
      _state = oldState;
    }
  }

  /// Execute [callback], wrapping its output in an element with the given
  /// [name] and [attributes].
  void element(
    String name,
    Map<String, String> attributes, [
    void Function()? callback,
  ]) {
    add(makeElement(name, attributes, collectHtml(callback)));
  }

  /// Execute [callback], indenting any code it outputs by two spaces.
  void indent(void Function() callback) {
    var oldIndent = _state.indent;
    try {
      _state.indent += '  ';
      callback();
    } finally {
      _state.indent = oldIndent;
    }
  }

  /// Output text without ending the current line.
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /// Output text, ending the current line.
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }
}

/// State used by [CodeGenerator].
class _CodeGeneratorState {
  StringBuffer buffer = StringBuffer();
  String nextIndent = '';
  String indent = '';
  bool indentNeeded = true;

  void write(String text) {
    var lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (i == lines.length - 1 && lines[i].isEmpty) {
        break;
      }
      if (indentNeeded) {
        buffer.write(nextIndent);
        nextIndent = indent;
      }
      indentNeeded = false;
      buffer.write(lines[i]);
      if (i != lines.length - 1) {
        buffer.writeln();
        indentNeeded = true;
      }
    }
  }
}

/// State used by [HtmlCodeGenerator].
class _HtmlCodeGeneratorState {
  List<dom.Node> buffer = <dom.Node>[];
  String indent = '';
  bool indentNeeded = true;

  void add(dom.Node node) {
    if (node is dom.Text) {
      write(node.text);
    } else {
      buffer.add(node);
    }
  }

  void write(String text) {
    if (text.isEmpty) {
      return;
    }
    if (indentNeeded) {
      buffer.add(dom.Text(indent));
    }
    var lines = text.split('\n');
    if (lines.last.isEmpty) {
      lines.removeLast();
      buffer.add(dom.Text('${lines.join('\n$indent')}\n'));
      indentNeeded = true;
    } else {
      buffer.add(dom.Text(lines.join('\n$indent')));
      indentNeeded = false;
    }
  }
}
