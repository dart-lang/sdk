// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tools for generating code in analyzer and analysis server.
 */
import 'dart:async';
import 'dart:io';

import 'package:analyzer_utilities/html.dart';
import 'package:analyzer_utilities/text_formatter.dart';
import 'package:html/dom.dart' as dom;
import 'package:path/path.dart';

final RegExp trailingSpacesInLineRegExp = new RegExp(r' +$', multiLine: true);
final RegExp trailingWhitespaceRegExp = new RegExp(r'[\n ]+$');

/**
 * Join the given strings using camelCase.  If [doCapitalize] is true, the first
 * part will be capitalized as well.
 */
String camelJoin(List<String> parts, {bool doCapitalize: false}) {
  List<String> upcasedParts = <String>[];
  for (int i = 0; i < parts.length; i++) {
    if (i == 0 && !doCapitalize) {
      upcasedParts.add(parts[i]);
    } else {
      upcasedParts.add(capitalize(parts[i]));
    }
  }
  return upcasedParts.join();
}

/**
 * Capitalize and return the passed String.
 */
String capitalize(String string) {
  return string[0].toUpperCase() + string.substring(1);
}

/**
 * Type of functions used to compute the contents of a set of generated files.
 * [pkgPath] is the path to the current package.
 */
typedef Map<String, FileContentsComputer> DirectoryContentsComputer(
    String pkgPath);

/**
 * Type of functions used to compute the contents of a generated file.
 * [pkgPath] is the path to the current package.
 */
typedef Future<String> FileContentsComputer(String pkgPath);

/**
 * Mixin class for generating code.
 */
class CodeGenerator {
  _CodeGeneratorState _state;

  /**
   * Settings that specialize code generation behavior for a given
   * programming language.
   */
  CodeGeneratorSettings codeGeneratorSettings = new CodeGeneratorSettings();

  /**
   * Measure the width of the current indentation level.
   */
  int get indentWidth => _state.nextIndent.length;

  /**
   * Execute [callback], collecting any code that is output using [write]
   * or [writeln], and return the result as a string.
   */
  String collectCode(void callback(), {bool removeTrailingNewLine: false}) {
    _CodeGeneratorState oldState = _state;
    try {
      _state = new _CodeGeneratorState();
      callback();
      var text =
          _state.buffer.toString().replaceAll(trailingSpacesInLineRegExp, '');
      if (!removeTrailingNewLine) {
        return text;
      } else {
        return text.replaceAll(trailingWhitespaceRegExp, '');
      }
    } finally {
      _state = oldState;
    }
  }

  /**
   * Generate a doc comment based on the HTML in [docs].
   *
   * When generating java code, the output is compatible with Javadoc, which
   * understands certain HTML constructs.
   */
  void docComment(List<dom.Node> docs, {bool removeTrailingNewLine: false}) {
    if (containsOnlyWhitespace(docs)) return;
    if (codeGeneratorSettings.docCommentStartMarker != null)
      writeln(codeGeneratorSettings.docCommentStartMarker);
    int width = codeGeneratorSettings.commentLineLength;
    bool javadocStyle = codeGeneratorSettings.languageName == 'java';
    indentBy(codeGeneratorSettings.docCommentLineLeader, () {
      write(nodesToText(docs, width - _state.indent.length, javadocStyle,
          removeTrailingNewLine: removeTrailingNewLine));
    });
    if (codeGeneratorSettings.docCommentEndMarker != null)
      writeln(codeGeneratorSettings.docCommentEndMarker);
  }

  /**
   * Execute [callback], indenting any code it outputs.
   */
  void indent(void callback()) {
    indentSpecial(
        codeGeneratorSettings.indent, codeGeneratorSettings.indent, callback);
  }

  /**
   * Execute [callback], using [additionalIndent] to indent any code it outputs.
   */
  void indentBy(String additionalIndent, void callback()) =>
      indentSpecial(additionalIndent, additionalIndent, callback);

  /**
   * Execute [callback], using [additionalIndent] to indent any code it outputs.
   * The first line of output is indented by [firstAdditionalIndent] instead of
   * [additionalIndent].
   */
  void indentSpecial(
      String firstAdditionalIndent, String additionalIndent, void callback()) {
    String oldNextIndent = _state.nextIndent;
    String oldIndent = _state.indent;
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
    int width = codeGeneratorSettings.commentLineLength;
    indentBy(codeGeneratorSettings.lineCommentLineLeader, () {
      write(nodesToText(docs, width - _state.indent.length, false));
    });
  }

  void outputHeader({bool javaStyle: false, String year = null}) {
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

  /**
   * Output text without ending the current line.
   */
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /**
   * Output text, ending the current line.
   */
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }
}

/**
 * Controls several settings of [CodeGenerator].
 *
 * The default settings are valid for generating Java and Dart code.
 */
class CodeGeneratorSettings {
  /**
   * Name of the language being generated. Lowercase.
   */
  String languageName;

  /**
   * Marker used in line comments.
   */
  String lineCommentLineLeader;

  /**
   * Start marker for doc comments.
   */
  String docCommentStartMarker;

  /**
   * Line leader for body lines in doc comments.
   */
  String docCommentLineLeader;

  /**
   * End marker for doc comments.
   */
  String docCommentEndMarker;

  /**
   * Line length for doc comment lines.
   */
  int commentLineLength;

  /**
   * String used for indenting code.
   */
  String indent;

  CodeGeneratorSettings(
      {this.languageName: 'java',
      this.lineCommentLineLeader: '// ',
      this.docCommentStartMarker: '/**',
      this.docCommentLineLeader: ' * ',
      this.docCommentEndMarker: ' */',
      this.commentLineLength: 99,
      this.indent: '  '});
}

/**
 * A utility class for invoking dartfmt.
 */
class DartFormat {
  static String get _dartfmtPath {
    String binName = Platform.isWindows ? 'dartfmt.bat' : 'dartfmt';
    for (var loc in [binName, join('dart-sdk', 'bin', binName)]) {
      var candidatePath = join(dirname(Platform.resolvedExecutable), loc);
      if (new File(candidatePath).existsSync()) {
        return candidatePath;
      }
    }
    throw new StateError('Could not find dartfmt executable');
  }

  static void formatFile(File file) {
    ProcessResult result = Process.runSync(_dartfmtPath, ['-w', file.path]);
    if (result.exitCode != 0) throw result.stderr;
  }

  static String formatText(String text) {
    File file = new File(join(Directory.systemTemp.path, 'gen.dart'));
    file.writeAsStringSync(text);
    ProcessResult result = Process.runSync(_dartfmtPath, ['-w', file.path]);
    if (result.exitCode != 0) throw result.stderr;
    return file.readAsStringSync();
  }
}

/**
 * Abstract base class representing behaviors common to generated files and
 * generated directories.
 */
abstract class GeneratedContent {
  /**
   * Check whether the [output] has the correct contents, and return true if it
   * does.  [pkgPath] is the path to the current package.
   */
  Future<bool> check(String pkgPath);

  /**
   * Replace the [output] with the correct contents.  [pkgPath] is the path to
   * the current package.
   */
  Future<void> generate(String pkgPath);

  /**
   * Get a [FileSystemEntity] representing the output file or directory.
   * [pkgPath] is the path to the current package.
   */
  FileSystemEntity output(String pkgPath);

  /**
   * Check that all of the [targets] are up to date.  If they are not, print
   * out a message instructing the user to regenerate them, and exit with a
   * nonzero error code.
   *
   * [pkgPath] is the path to the current package.  [generatorPath] is the path
   * to a .dart script the user may use to regenerate the targets.
   *
   * To avoid mistakes when run on Windows, [generatorPath] always uses
   * POSIX directory separators.
   */
  static Future<void> checkAll(
      String pkgPath, String generatorPath, Iterable<GeneratedContent> targets,
      {List<String> args = const []}) async {
    bool generateNeeded = false;
    for (GeneratedContent target in targets) {
      bool ok = await target.check(pkgPath);
      if (!ok) {
        print("${target.output(pkgPath).absolute}"
            " doesn't have expected contents.");
        generateNeeded = true;
      }
    }
    if (generateNeeded) {
      print('Please regenerate using:');
      String executable = Platform.executable;
      String packageRoot = '';
      // ignore: deprecated_member_use
      if (Platform.packageRoot != null) {
        // ignore: deprecated_member_use
        packageRoot = ' --package-root=${Platform.packageRoot}';
      }
      String generateScript = normalize(joinAll(posix.split(generatorPath)));
      print('  $executable$packageRoot $generateScript ${args.join(" ")}');
      exit(1);
    } else {
      print('All generated files up to date.');
    }
  }

  /**
   * Regenerate all of the [targets].  [pkgPath] is the path to the current
   * package.
   */
  static Future<void> generateAll(
      String pkgPath, Iterable<GeneratedContent> targets) async {
    print("Generating...");
    for (GeneratedContent target in targets) {
      await target.generate(pkgPath);
    }
  }
}

/**
 * Class representing a single output directory (either generated code or
 * generated HTML). No other content should exist in the directory.
 */
class GeneratedDirectory extends GeneratedContent {
  /**
   * The path to the directory that will have the generated content.
   */
  final String outputDirPath;

  /**
   * Callback function that computes the directory contents.
   */
  final DirectoryContentsComputer directoryContentsComputer;

  GeneratedDirectory(this.outputDirPath, this.directoryContentsComputer);

  @override
  Future<bool> check(String pkgPath) async {
    Directory outputDirectory = output(pkgPath);
    Map<String, FileContentsComputer> map = directoryContentsComputer(pkgPath);
    try {
      for (String file in map.keys) {
        FileContentsComputer fileContentsComputer = map[file];
        String expectedContents = await fileContentsComputer(pkgPath);
        File outputFile = new File(posix.join(outputDirectory.path, file));
        String actualContents = outputFile.readAsStringSync();
        // Normalize Windows line endings to Unix line endings so that the
        // comparison doesn't fail on Windows.
        actualContents = actualContents.replaceAll('\r\n', '\n');
        if (expectedContents != actualContents) {
          return false;
        }
      }
      int nonHiddenFileCount = 0;
      outputDirectory
          .listSync(recursive: false, followLinks: false)
          .forEach((FileSystemEntity fileSystemEntity) {
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
  Future<void> generate(String pkgPath) async {
    Directory outputDirectory = output(pkgPath);
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
    Map<String, FileContentsComputer> map = directoryContentsComputer(pkgPath);
    for (String file in map.keys) {
      FileContentsComputer fileContentsComputer = map[file];
      File outputFile = new File(posix.join(outputDirectory.path, file));
      print('  ${outputFile.path}');
      String contents = await fileContentsComputer(pkgPath);
      outputFile.writeAsStringSync(contents);
    }
  }

  @override
  Directory output(String pkgPath) =>
      new Directory(join(pkgPath, joinAll(posix.split(outputDirPath))));
}

/**
 * Class representing a single output file (either generated code or generated
 * HTML).
 */
class GeneratedFile extends GeneratedContent {
  /**
   * The output file to which generated output should be written, relative to
   * the "tool/spec" directory.  This filename uses the posix path separator
   * ('/') regardless of the OS.
   */
  final String outputPath;

  /**
   * Callback function which computes the file.
   */
  final FileContentsComputer computeContents;

  GeneratedFile(this.outputPath, this.computeContents);

  bool get isDartFile => outputPath.endsWith('.dart');

  @override
  Future<bool> check(String pkgPath) async {
    File outputFile = output(pkgPath);
    String expectedContents = await computeContents(pkgPath);
    if (isDartFile) {
      expectedContents = DartFormat.formatText(expectedContents);
    }
    try {
      String actualContents = outputFile.readAsStringSync();
      // Normalize Windows line endings to Unix line endings so that the
      // comparison doesn't fail on Windows.
      actualContents = actualContents.replaceAll('\r\n', '\n');
      return expectedContents == actualContents;
    } catch (e) {
      // There was a problem reading the file (most likely because it didn't
      // exist).  Treat that the same as if the file doesn't have the expected
      // contents.
      return false;
    }
  }

  @override
  Future<void> generate(String pkgPath) async {
    File outputFile = output(pkgPath);
    print('  ${outputFile.path}');
    String contents = await computeContents(pkgPath);
    outputFile.writeAsStringSync(contents);
    if (isDartFile) {
      DartFormat.formatFile(outputFile);
    }
  }

  @override
  File output(String pkgPath) =>
      new File(join(pkgPath, joinAll(posix.split(outputPath))));
}

/**
 * Mixin class for generating HTML representations of code that are suitable
 * for enclosing inside a <pre> element.
 */
abstract class HtmlCodeGenerator {
  _HtmlCodeGeneratorState _state;

  /**
   * Add the given [node] to the HTML output.
   */
  void add(dom.Node node) {
    _state.add(node);
  }

  /**
   * Add the given [nodes] to the HTML output.
   */
  void addAll(Iterable<dom.Node> nodes) {
    for (dom.Node node in nodes) {
      _state.add(node);
    }
  }

  /**
   * Execute [callback], collecting any code that is output using [write],
   * [writeln], [add], or [addAll], and return the result as a list of DOM
   * nodes.
   */
  List<dom.Node> collectHtml(void callback()) {
    _HtmlCodeGeneratorState oldState = _state;
    try {
      _state = new _HtmlCodeGeneratorState();
      if (callback != null) {
        callback();
      }
      return _state.buffer;
    } finally {
      _state = oldState;
    }
  }

  /**
   * Execute [callback], wrapping its output in an element with the given
   * [name] and [attributes].
   */
  void element(String name, Map<dynamic, String> attributes,
      [void callback()]) {
    add(makeElement(name, attributes, collectHtml(callback)));
  }

  /**
   * Execute [callback], indenting any code it outputs by two spaces.
   */
  void indent(void callback()) {
    String oldIndent = _state.indent;
    try {
      _state.indent += '  ';
      callback();
    } finally {
      _state.indent = oldIndent;
    }
  }

  /**
   * Output text without ending the current line.
   */
  void write(Object obj) {
    _state.write(obj.toString());
  }

  /**
   * Output text, ending the current line.
   */
  void writeln([Object obj = '']) {
    _state.write('$obj\n');
  }
}

/**
 * State used by [CodeGenerator].
 */
class _CodeGeneratorState {
  StringBuffer buffer = new StringBuffer();
  String nextIndent = '';
  String indent = '';
  bool indentNeeded = true;

  void write(String text) {
    List<String> lines = text.split('\n');
    for (int i = 0; i < lines.length; i++) {
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

/**
 * State used by [HtmlCodeGenerator].
 */
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
      buffer.add(new dom.Text(indent));
    }
    List<String> lines = text.split('\n');
    if (lines.last.isEmpty) {
      lines.removeLast();
      buffer.add(new dom.Text(lines.join('\n$indent') + '\n'));
      indentNeeded = true;
    } else {
      buffer.add(new dom.Text(lines.join('\n$indent')));
      indentNeeded = false;
    }
  }
}
