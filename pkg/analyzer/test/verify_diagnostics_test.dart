// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:path/path.dart';
import 'package:pub_semver/src/version_constraint.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/diagnostics/generate.dart';
import 'src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VerifyDiagnosticsTest);
  });
}

/// A class used to validate diagnostic documentation.
class DocumentationValidator {
  /// The sequence used to mark the start of an error range.
  static const String errorRangeStart = '[!';

  /// The sequence used to mark the end of an error range.
  static const String errorRangeEnd = '!]';

  /// A list of the diagnostic codes that are not being verified. These should
  /// ony include docs that cannot be verified because of missing support in the
  /// verifier.
  static const List<String> unverifiedDocs = [
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.INVALID_URI',
    // Need a way to make auxiliary files that (a) are not included in the
    // generated docs or (b) can be made persistent for fixes.
    'CompileTimeErrorCode.PART_OF_NON_PART',
    // The code has been replaced but is not yet removed.
    'HintCode.DEPRECATED_MEMBER_USE',
    // Needs to be able to specify two expected diagnostics.
    'StaticWarningCode.AMBIGUOUS_IMPORT',
    // Produces two diagnostics when it should only produce one.
    'StaticWarningCode.INVALID_USE_OF_NULL_VALUE',
  ];

  /// The prefix used on directive lines to specify the experiments that should
  /// be enabled for a snippet.
  static const String experimentsPrefix = '%experiments=';

  /// The prefix used on directive lines to indicate the uri of an auxiliary
  /// file that is needed for testing purposes.
  static const String uriDirectivePrefix = '%uri="';

  /// The absolute paths of the files containing the declarations of the error
  /// codes.
  final List<CodePath> codePaths;

  /// The buffer to which validation errors are written.
  final StringBuffer buffer = StringBuffer();

  /// The path to the file currently being verified.
  String filePath;

  /// A flag indicating whether the [filePath] has already been written to the
  /// buffer.
  bool hasWrittenFilePath = false;

  /// The name of the variable currently being verified.
  String variableName;

  /// The name of the error code currently being verified.
  String codeName;

  /// A flag indicating whether the [variableName] has already been written to
  /// the buffer.
  bool hasWrittenVariableName = false;

  /// Initialize a newly created documentation validator.
  DocumentationValidator(this.codePaths);

  /// Validate the documentation.
  Future<void> validate() async {
    AnalysisContextCollection collection = AnalysisContextCollection(
        includedPaths:
            codePaths.map((codePath) => codePath.documentationPath).toList(),
        resourceProvider: PhysicalResourceProvider.INSTANCE);
    for (CodePath codePath in codePaths) {
      await _validateFile(_parse(collection, codePath.documentationPath));
    }
    if (buffer.isNotEmpty) {
      fail(buffer.toString());
    }
  }

  /// Return the name of the code as defined in the [initializer].
  String _extractCodeName(VariableDeclaration variable) {
    Expression initializer = variable.initializer;
    if (initializer is MethodInvocation) {
      var firstArgument = initializer.argumentList.arguments[0];
      return (firstArgument as StringLiteral).stringValue;
    }
    return variable.name.name;
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

  _SnippetData _extractSnippetData(String snippet, bool errorRequired,
      Map<String, String> auxiliaryFiles, List<String> experiments) {
    int rangeStart = snippet.indexOf(errorRangeStart);
    if (rangeStart < 0) {
      if (errorRequired) {
        _reportProblem('No error range in example');
      }
      return _SnippetData(snippet, -1, 0, auxiliaryFiles, experiments);
    }
    int rangeEnd = snippet.indexOf(errorRangeEnd, rangeStart + 1);
    if (rangeEnd < 0) {
      _reportProblem('No end of error range in example');
      return _SnippetData(snippet, -1, 0, auxiliaryFiles, experiments);
    } else if (snippet.indexOf(errorRangeStart, rangeEnd) > 0) {
      _reportProblem('More than one error range in example');
    }
    return _SnippetData(
        snippet.substring(0, rangeStart) +
            snippet.substring(rangeStart + errorRangeStart.length, rangeEnd) +
            snippet.substring(rangeEnd + errorRangeEnd.length),
        rangeStart,
        rangeEnd - rangeStart - 2,
        auxiliaryFiles,
        experiments);
  }

  /// Extract the snippets of Dart code between the start (inclusive) and end
  /// (exclusive) indexes.
  List<_SnippetData> _extractSnippets(
      List<String> lines, int start, int end, bool errorRequired) {
    var snippets = <_SnippetData>[];
    var auxiliaryFiles = <String, String>{};
    List<String> experiments;
    var currentStart = -1;
    for (var i = start; i < end; i++) {
      var line = lines[i];
      if (line == '```') {
        if (currentStart < 0) {
          _reportProblem('Snippet without file type on line $i.');
          return snippets;
        }
        var secondLine = lines[currentStart + 1];
        if (secondLine.startsWith(uriDirectivePrefix)) {
          var name = secondLine.substring(
              uriDirectivePrefix.length, secondLine.length - 1);
          var content = lines.sublist(currentStart + 2, i).join('\n');
          auxiliaryFiles[name] = content;
        } else if (lines[currentStart] == '```dart') {
          if (secondLine.startsWith(experimentsPrefix)) {
            experiments = secondLine
                .substring(experimentsPrefix.length)
                .split(',')
                .map((e) => e.trim())
                .toList();
            currentStart++;
          }
          var content = lines.sublist(currentStart + 1, i).join('\n');
          snippets.add(_extractSnippetData(
              content, errorRequired, auxiliaryFiles, experiments));
          auxiliaryFiles = <String, String>{};
        }
        currentStart = -1;
      } else if (line.startsWith('```')) {
        if (currentStart >= 0) {
          _reportProblem('Snippet before line $i was not closed.');
          return snippets;
        }
        currentStart = i;
      }
    }
    return snippets;
  }

  /// Use the analysis context [collection] to parse the file at the given
  /// [path] and return the result.
  ParsedUnitResult _parse(AnalysisContextCollection collection, String path) {
    AnalysisSession session = collection.contextFor(path).currentSession;
    if (session == null) {
      throw StateError('No session for "$path"');
    }
    ParsedUnitResult result = session.getParsedUnit(path);
    if (result.state != ResultState.VALID) {
      throw StateError('Unable to parse "$path"');
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
    if (!hasWrittenVariableName) {
      buffer.writeln('  $variableName');
      hasWrittenVariableName = true;
    }
    buffer.writeln('    $problem');
    for (AnalysisError error in errors) {
      buffer.write('      ');
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
  Future<void> _validateFile(ParsedUnitResult result) async {
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
              codeName = _extractCodeName(variable);
              if (codeName == 'NULLABLE_TYPE_IN_CATCH_CLAUSE') {
                DateTime.now();
              }
              variableName = '$className.${variable.name.name}';
              if (unverifiedDocs.contains(variableName)) {
                continue;
              }
              hasWrittenVariableName = false;

              int exampleStart = docs.indexOf('#### Examples');
              int fixesStart = docs.indexOf('#### Common fixes');

              List<_SnippetData> exampleSnippets =
                  _extractSnippets(docs, exampleStart + 1, fixesStart, true);
              _SnippetData firstExample;
              if (exampleSnippets.isEmpty) {
                _reportProblem('No example.');
              } else {
                firstExample = exampleSnippets[0];
              }
              for (int i = 0; i < exampleSnippets.length; i++) {
                await _validateSnippet('example', i, exampleSnippets[i]);
              }

              List<_SnippetData> fixesSnippets =
                  _extractSnippets(docs, fixesStart + 1, docs.length, false);
              for (int i = 0; i < fixesSnippets.length; i++) {
                _SnippetData snippet = fixesSnippets[i];
                if (firstExample != null) {
                  snippet.auxiliaryFiles.addAll(firstExample.auxiliaryFiles);
                }
                await _validateSnippet('fixes', i, snippet);
              }
            }
          }
        }
      }
    }
  }

  /// Resolve the [snippet]. If the snippet's offset is less than zero, then
  /// verify that no diagnostics are reported. If the offset is greater than or
  /// equal to zero, verify that one error whose name matches the current code
  /// is reported at that offset with the expected length.
  Future<void> _validateSnippet(
      String section, int index, _SnippetData snippet) async {
    _SnippetTest test = _SnippetTest(snippet);
    test.setUp();
    await test.resolveTestFile();
    List<AnalysisError> errors = test.result.errors;
    int errorCount = errors.length;
    if (snippet.offset < 0) {
      if (errorCount > 0) {
        _reportProblem(
            'Expected no errors but found $errorCount ($section $index):',
            errors: errors);
      }
    } else {
      if (errorCount == 0) {
        _reportProblem('Expected one error but found none ($section $index).');
      } else if (errorCount == 1) {
        AnalysisError error = errors[0];
        if (error.errorCode.name != codeName) {
          _reportProblem('Expected an error with code $codeName, '
              'found ${error.errorCode} ($section $index).');
        }
        if (error.offset != snippet.offset) {
          _reportProblem('Expected an error at ${snippet.offset}, '
              'found ${error.offset} ($section $index).');
        }
        if (error.length != snippet.length) {
          _reportProblem('Expected an error of length ${snippet.length}, '
              'found ${error.length} ($section $index).');
        }
      } else {
        _reportProblem(
            'Expected one error but found $errorCount ($section $index):',
            errors: errors);
      }
    }
  }
}

/// Validate the documentation associated with the declarations of the error
/// codes.
@reflectiveTest
class VerifyDiagnosticsTest {
  test_diagnostics() async {
    Context pathContext = PhysicalResourceProvider.INSTANCE.pathContext;
    List<CodePath> codePaths = computeCodePaths();
    //
    // Validate that the input to the generator is correct.
    //
    DocumentationValidator validator = DocumentationValidator(codePaths);
    await validator.validate();
    //
    // Validate that the generator has been run.
    //
    if (pathContext.style != Style.windows) {
      String actualContent = PhysicalResourceProvider.INSTANCE
          .getFile(computeOutputPath())
          .readAsStringSync();

      StringBuffer sink = StringBuffer();
      DocumentationGenerator generator = DocumentationGenerator(codePaths);
      generator.writeDocumentation(sink);
      String expectedContent = sink.toString();

      if (actualContent != expectedContent) {
        fail('The diagnostic documentation needs to be regenerated.\n'
            'Please run tool/diagnostics/generate.dart.');
      }
    }
  }
}

/// A data holder used to return multiple values when extracting an error range
/// from a snippet.
class _SnippetData {
  final String content;
  final int offset;
  final int length;
  final Map<String, String> auxiliaryFiles;
  final List<String> experiments;

  _SnippetData(this.content, this.offset, this.length, this.auxiliaryFiles,
      this.experiments);
}

/// A test class that creates an environment suitable for analyzing the
/// snippets.
class _SnippetTest extends DriverResolutionTest with PackageMixin {
  /// The snippet being tested.
  final _SnippetData snippet;

  @override
  AnalysisOptionsImpl analysisOptions = AnalysisOptionsImpl();

  /// Initialize a newly created test to test the given [snippet].
  _SnippetTest(this.snippet) {
    analysisOptions.contextFeatures =
        FeatureSet.fromEnableFlags(snippet.experiments ?? []);
    String pubspecContent = snippet.auxiliaryFiles['pubspec.yaml'];
    if (pubspecContent != null) {
      for (String line in pubspecContent.split('\n')) {
        if (line.indexOf('sdk:') > 0) {
          int start = line.indexOf("'") + 1;
          String constraint = line.substring(start, line.indexOf("'", start));
          analysisOptions.sdkVersionConstraint =
              VersionConstraint.parse(constraint);
        }
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    addMetaPackage();
    _createAuxiliaryFiles(snippet.auxiliaryFiles);
    addTestFile(snippet.content);
  }

  void _createAuxiliaryFiles(Map<String, String> auxiliaryFiles) {
    Map<String, String> packageMap = {};
    for (String uri in auxiliaryFiles.keys) {
      if (uri.startsWith('package:')) {
        int slash = uri.indexOf('/');
        String packageName = uri.substring(8, slash);
        String libPath = packageMap.putIfAbsent(
            packageName, () => addPubPackage(packageName).path);
        String relativePath = uri.substring(slash + 1);
        newFile('$libPath/$relativePath', content: auxiliaryFiles[uri]);
      } else {
        newFile('/test/$uri', content: auxiliaryFiles[uri]);
      }
    }
  }
}
