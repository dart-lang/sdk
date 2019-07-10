// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:front_end/src/testing/package_root.dart' as package_root;
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../tool/diagnostics/generate.dart';
import 'src/dart/resolution/driver_resolution.dart';

/// Validate the documentation associated with the declarations of the error
/// codes.
void main() async {
  Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
  //
  // Validate that the input to the generator is correct.
  //
  String packageRoot = pathContext.normalize(package_root.packageRoot);
  String analyzerPath = pathContext.join(packageRoot, 'analyzer');
  List<String> docPaths = [
    pathContext.join(
        analyzerPath, 'lib', 'src', 'dart', 'error', 'hint_codes.dart'),
    pathContext.join(analyzerPath, 'lib', 'src', 'error', 'codes.dart'),
  ];

  DocumentationValidator validator = DocumentationValidator(docPaths);
  validator.validate();
  //
  // Validate that the generator has been run.
  //
  if (pathContext.style != Style.windows) {
    String outputPath =
        pathContext.join(analyzerPath, 'tool', 'diagnostics', 'diagnostics.md');
    String actualContent = PhysicalResourceProvider.INSTANCE
        .getFile(outputPath)
        .readAsStringSync();

    StringBuffer sink = StringBuffer();
    DocumentationGenerator generator = DocumentationGenerator(docPaths);
    generator.writeDocumentation(sink);
    String expectedContent = sink.toString();

    if (actualContent != expectedContent) {
      fail('The diagnostic documentation needs to be regenerated.\n'
          'Please run tool/diagnostics/generate.dart.');
    }
  }
}

/// A class used to validate diagnostic documentation.
class DocumentationValidator {
  /// The sequence used to mark the start of an error range.
  static const String errorRangeStart = '[!';

  /// The sequence used to mark the end of an error range.
  static const String errorRangeEnd = '!]';

  /// The absolute paths of the files containing the declarations of the error
  /// codes.
  final List<String> docPaths;

  /// The buffer to which validation errors are written.
  final StringBuffer buffer = StringBuffer();

  /// The path to the file currently being verified.
  String filePath;

  /// A flag indicating whether the [filePath] has already been written to the
  /// buffer.
  bool hasWrittenFilePath = false;

  /// The name of the error code currently being verified.
  String codeName;

  /// A flag indicating whether the [codeName] has already been written to the
  /// buffer.
  bool hasWrittenCodeName = false;

  /// Initialize a newly created documentation validator.
  DocumentationValidator(this.docPaths);

  /// Validate the documentation.
  void validate() async {
    AnalysisContextCollection collection = new AnalysisContextCollection(
        includedPaths: docPaths,
        resourceProvider: PhysicalResourceProvider.INSTANCE);
    for (String docPath in docPaths) {
      _validateFile(_parse(collection, docPath));
    }
    if (buffer.isNotEmpty) {
      fail(buffer.toString());
    }
  }

  /// Extract documentation from the given [field] declaration.
  List<String> _extractDoc(FieldDeclaration field) {
    Token comments = field.firstTokenAfterCommentAndMetadata.precedingComments;
    if (comments == null) {
      return null;
    }
    List<String> docs = [];
    while (comments != null) {
      String lexeme = comments.lexeme;
      if (lexeme.startsWith('// TODO')) {
        break;
      } else if (lexeme.startsWith('// ')) {
        docs.add(lexeme.substring(3));
      } else if (lexeme == '//') {
        docs.add('');
      }
      comments = comments.next;
    }
    if (docs.isEmpty) {
      return null;
    }
    return docs;
  }

  _SnippetData _extractSnippetData(String snippet) {
    int rangeStart = snippet.indexOf(errorRangeStart);
    if (rangeStart < 0) {
      _reportProblem('No error range in example');
      return _SnippetData(snippet, -1, 0);
    }
    int rangeEnd = snippet.indexOf(errorRangeEnd, rangeStart + 1);
    if (rangeEnd < 0) {
      _reportProblem('No end of error range in example');
      return _SnippetData(snippet, -1, 0);
    } else if (snippet.indexOf(errorRangeStart, rangeEnd) > 0) {
      _reportProblem('More than one error range in example');
    }
    return _SnippetData(
        snippet.substring(0, rangeStart) +
            snippet.substring(rangeStart + 1, rangeEnd) +
            snippet.substring(rangeEnd + 1),
        rangeStart,
        rangeEnd - rangeStart - 1);
  }

  /// Extract the snippets of Dart code between the start (inclusive) and end
  /// (exclusive) indexes.
  List<String> _extractSnippets(List<String> lines, int start, int end) {
    List<String> snippets = [];
    int snippetStart = lines.indexOf('```dart', start);
    while (snippetStart >= 0 && snippetStart < end) {
      int snippetEnd = lines.indexOf('```', snippetStart + 1);
      snippets.add(lines.sublist(snippetStart + 1, snippetEnd).join('\n'));
      snippetStart = lines.indexOf('```dart', snippetEnd + 1);
    }
    return snippets;
  }

  /// Use the analysis context [collection] to parse the file at the given
  /// [path] and return the result.
  ParsedUnitResult _parse(AnalysisContextCollection collection, String path) {
    AnalysisSession session = collection.contextFor(path).currentSession;
    if (session == null) {
      throw new StateError('No session for "$path"');
    }
    ParsedUnitResult result = session.getParsedUnit(path);
    if (result.state != ResultState.VALID) {
      throw new StateError('Unable to parse "$path"');
    }
    return result;
  }

  /// Report a problem with the current error code.
  void _reportProblem(String problem, {List<AnalysisError> errors = const []}) {
    if (!hasWrittenFilePath) {
      buffer.writeln();
      buffer.writeln('In $filePath');
      hasWrittenFilePath = true;
    }
    if (!hasWrittenCodeName) {
      buffer.writeln('  $codeName');
      hasWrittenCodeName = true;
    }
    buffer.writeln('    $problem');
    for (AnalysisError error in errors) {
      buffer.write(error.errorCode);
      buffer.write(' (');
      buffer.write(error.offset);
      buffer.write(', ');
      buffer.write(error.length);
      buffer.write(') ');
      buffer.writeln(error.message);
    }
  }

  /// Extract documentation from the file that was parsed to produce the given
  /// [result].
  void _validateFile(ParsedUnitResult result) {
    filePath = result.path;
    hasWrittenFilePath = false;
    CompilationUnit unit = result.unit;
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        String className = declaration.name.name;
        for (ClassMember member in declaration.members) {
          if (member is FieldDeclaration) {
            List<String> docs = _extractDoc(member);
            if (docs != null) {
              VariableDeclaration variable = member.fields.variables[0];
              String variableName = variable.name.name;
              codeName = '$className.$variableName';
              hasWrittenCodeName = false;

              int exampleStart = docs.indexOf('#### Example');
              int fixesStart = docs.indexOf('#### Common fixes');

              List<String> exampleSnippets =
                  _extractSnippets(docs, exampleStart + 1, fixesStart);
              for (String snippet in exampleSnippets) {
                _SnippetData data = _extractSnippetData(snippet);
                _validateSnippet(data.snippet, data.offset, data.length);
              }

              List<String> fixesSnippets =
                  _extractSnippets(docs, fixesStart + 1, docs.length);
              for (String snippet in fixesSnippets) {
                _validateSnippet(snippet, -1, 0);
              }
            }
          }
        }
      }
    }
  }

  /// Resolve the [snippet]. If the [offset] is less than zero, then verify that
  /// no diagnostics are reported. If the [offset] is greater than or equal to
  /// zero, verify that one error whose name matches the current code is
  /// reported at that offset with the given [length].
  void _validateSnippet(String snippet, int offset, int length) async {
    // TODO(brianwilkerson) Implement this.
    DriverResolutionTest test = DriverResolutionTest();
    test.setUp();
    test.addTestFile(snippet);
    await test.resolveTestFile();
    List<AnalysisError> errors = test.result.errors;
    int errorCount = errors.length;
    if (offset < 0) {
      if (errorCount > 0) {
        _reportProblem('Expected no errors but found $errorCount.',
            errors: errors);
      }
    } else {
      if (errorCount == 0) {
        _reportProblem('Expected one error but found none.');
      } else if (errorCount == 1) {
        AnalysisError error = errors[0];
        if (error.errorCode != codeName) {
          _reportProblem(
              'Expected an error with code $codeName, found ${error.errorCode}.');
        }
        if (error.offset != offset) {
          _reportProblem(
              'Expected an error at $offset, found ${error.offset}.');
        }
        if (error.length != length) {
          _reportProblem(
              'Expected an error of length $length, found ${error.length}.');
        }
      } else {
        _reportProblem('Expected one error but found $errorCount.',
            errors: errors);
      }
    }
  }
}

/// A data holder used to return multiple values when extracting an error range
/// from a snippet.
class _SnippetData {
  final String snippet;
  final int offset;
  final int length;

  _SnippetData(this.snippet, this.offset, this.length);
}
