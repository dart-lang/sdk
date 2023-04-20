// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/diagnostics/generate.dart';
import '../tool/messages/error_code_documentation_info.dart';
import '../tool/messages/error_code_info.dart';
import 'src/dart/resolution/context_collection_resolution.dart';

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
    // Needs to be able to specify two expected diagnostics.
    'CompileTimeErrorCode.AMBIGUOUS_IMPORT',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.CONST_DEFERRED_CLASS',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT',
    // These docs need to be published until there are few enough users that
    // are on a pre-3.0 SDK that we're OK with the possibility of them
    // encountering a broken link.
    // todo(pq): remove (some time) post 3.0
    'CompileTimeErrorCode.DEFAULT_LIST_CONSTRUCTOR',
    // The mock SDK doesn't define any internal libraries.
    'CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY',
    // Also reports CompileTimeErrorCode.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
    'CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS',
    // Has code in the example section that needs to be skipped (because it's
    // part of the explanatory text not part of the example), but there's
    // currently no way to do that.
    'CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE',
    // Produces two diagnostics when it should only produce one. We could get
    // rid of the invalid error by adding a declaration of a top-level variable
    // (such as `JSBool b;`), but that would complicate the example.
    'CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.INVALID_URI',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE',
    // No example, by design.
    'CompileTimeErrorCode.MISSING_DART_LIBRARY',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS',
    // Produces two diagnostics when it should only produce one.
    'CompileTimeErrorCode.NON_SYNC_FACTORY',
    // Need a way to make auxiliary files that (a) are not included in the
    // generated docs or (b) can be made persistent for fixes.
    'CompileTimeErrorCode.PART_OF_NON_PART',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE',
    // https://github.com/dart-lang/sdk/issues/45960
    'CompileTimeErrorCode.RETURN_IN_GENERATOR',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.TOP_LEVEL_CYCLE',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    // Produces two diagnostic out of necessity.
    'CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    // Produces the diagnostic HintCode.UNUSED_LOCAL_VARIABLE when it shouldn't.
    'CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT',
    // Produces multiple diagnostic because of poor recovery.
    'CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR',

    // This is not reported after 2.12, and the examples don't compile after 3.0.
    'FfiCode.FIELD_INITIALIZER_IN_STRUCT',
    // This is not reported after 2.12, and the examples don't compile after 3.0.
    'FfiCode.FIELD_IN_STRUCT_WITH_INITIALIZER',

    // This no longer works in 3.0.
    'HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    // The code has been replaced but is not yet removed.
    'HintCode.DEPRECATED_MEMBER_USE',
    // Produces two diagnostics when it should only produce one (see
    // https://github.com/dart-lang/sdk/issues/43051)
    'HintCode.UNNECESSARY_NULL_COMPARISON_FALSE',
    // Also produces FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY.
    'FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS',

    // Produces two diagnostics when it should only produce one (see
    // https://github.com/dart-lang/sdk/issues/43263)
    'StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION',
    //
    // The following can't currently be verified because the examples aren't
    // Dart code.
    //
    'PubspecWarningCode.ASSET_DOES_NOT_EXIST',
    'PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST',
    'PubspecWarningCode.ASSET_FIELD_NOT_LIST',
    'PubspecWarningCode.ASSET_NOT_STRING',
    'PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP',
    'PubspecWarningCode.DEPRECATED_FIELD',
    'PubspecWarningCode.FLUTTER_FIELD_NOT_MAP',
    'PubspecWarningCode.INVALID_DEPENDENCY',
    'PubspecWarningCode.MISSING_NAME',
    'PubspecWarningCode.NAME_NOT_STRING',
    'PubspecWarningCode.PATH_DOES_NOT_EXIST',
    'PubspecWarningCode.PATH_NOT_POSIX',
    'PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST',
    'PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY',

    // Reports CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY
    'WarningCode.DEPRECATED_EXTENDS_FUNCTION',
    // Produces more than one error range by design.
    // TODO: update verification to allow for multiple highlight ranges.
    'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    // Produces more than one error range by design.
    'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
  ];

  /// The buffer to which validation errors are written.
  final StringBuffer buffer = StringBuffer();

  /// The name of the variable currently being verified.
  late String variableName;

  /// The name of the error code currently being verified.
  late String codeName;

  /// A flag indicating whether the [variableName] has already been written to
  /// the buffer.
  bool hasWrittenVariableName = false;

  /// Initialize a newly created documentation validator.
  DocumentationValidator();

  /// Validate the documentation.
  Future<void> validate() async {
    for (var classEntry in analyzerMessages.entries) {
      var errorClass = classEntry.key;
      await _validateMessages(errorClass, classEntry.value);
    }
    ErrorClassInfo? errorClassIncludingCfeMessages;
    for (var errorClass in errorClasses) {
      if (errorClass.includeCfeMessages) {
        if (errorClassIncludingCfeMessages != null) {
          fail('Multiple error classes include CFE messages: '
              '${errorClassIncludingCfeMessages.name} and ${errorClass.name}');
        }
        errorClassIncludingCfeMessages = errorClass;
        await _validateMessages(
            errorClass.name, cfeToAnalyzerErrorCodeTables.analyzerCodeToInfo);
      }
    }
    if (buffer.isNotEmpty) {
      fail(buffer.toString());
    }
  }

  _SnippetData _extractSnippetData(
    String snippet,
    bool errorRequired,
    Map<String, String> auxiliaryFiles,
    List<String> experiments,
    String? languageVersion,
  ) {
    int rangeStart = snippet.indexOf(errorRangeStart);
    if (rangeStart < 0) {
      if (errorRequired) {
        _reportProblem('No error range in example');
      }
      return _SnippetData(
          snippet, -1, 0, auxiliaryFiles, experiments, languageVersion);
    }
    int rangeEnd = snippet.indexOf(errorRangeEnd, rangeStart + 1);
    if (rangeEnd < 0) {
      _reportProblem('No end of error range in example');
      return _SnippetData(
          snippet, -1, 0, auxiliaryFiles, experiments, languageVersion);
    } else if (snippet.indexOf(errorRangeStart, rangeEnd) > 0) {
      _reportProblem('More than one error range in example');
    }
    String content;
    try {
      content = snippet.substring(0, rangeStart) +
          snippet.substring(rangeStart + errorRangeStart.length, rangeEnd) +
          snippet.substring(rangeEnd + errorRangeEnd.length);
    } on RangeError catch (exception) {
      _reportProblem(exception.message.toString());
      content = '';
    }
    return _SnippetData(
      content,
      rangeStart,
      rangeEnd - rangeStart - 2,
      auxiliaryFiles,
      experiments,
      languageVersion,
    );
  }

  /// Extract the snippets of Dart code from [documentationParts] that are
  /// tagged as belonging to the given [blockSection].
  List<_SnippetData> _extractSnippets(
      List<ErrorCodeDocumentationPart> documentationParts,
      BlockSection blockSection) {
    var snippets = <_SnippetData>[];
    var auxiliaryFiles = <String, String>{};
    for (var documentationPart in documentationParts) {
      if (documentationPart is ErrorCodeDocumentationBlock) {
        if (documentationPart.containingSection != blockSection) {
          continue;
        }
        var uri = documentationPart.uri;
        if (uri != null) {
          auxiliaryFiles[uri] = documentationPart.text;
        } else {
          if (documentationPart.fileType == 'dart') {
            snippets.add(_extractSnippetData(
                documentationPart.text,
                blockSection == BlockSection.examples,
                auxiliaryFiles,
                documentationPart.experiments,
                documentationPart.languageVersion));
          }
          auxiliaryFiles = <String, String>{};
        }
      }
    }
    return snippets;
  }

  /// Report a problem with the current error code.
  void _reportProblem(String problem, {List<AnalysisError> errors = const []}) {
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

  /// Extract documentation from the given [messages], which are error messages
  /// destined for the class [className].
  Future<void> _validateMessages(
      String className, Map<String, ErrorCodeInfo> messages) async {
    for (var errorEntry in messages.entries) {
      var errorName = errorEntry.key;
      var errorCodeInfo = errorEntry.value;
      var docs = parseErrorCodeDocumentation(
          '$className.$errorName', errorCodeInfo.documentation);
      if (docs != null) {
        codeName = errorCodeInfo.sharedName ?? errorName;
        variableName = '$className.$errorName';
        if (unverifiedDocs.contains(variableName)) {
          continue;
        }
        hasWrittenVariableName = false;

        List<_SnippetData> exampleSnippets =
            _extractSnippets(docs, BlockSection.examples);
        _SnippetData? firstExample;
        if (exampleSnippets.isEmpty) {
          _reportProblem('No example.');
        } else {
          firstExample = exampleSnippets[0];
        }
        for (int i = 0; i < exampleSnippets.length; i++) {
          await _validateSnippet('example', i, exampleSnippets[i]);
        }

        List<_SnippetData> fixesSnippets =
            _extractSnippets(docs, BlockSection.commonFixes);
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
  @TestTimeout(Timeout.factor(4))
  test_diagnostics() async {
    //
    // Validate that the input to the generator is correct.
    //
    DocumentationValidator validator = DocumentationValidator();
    await validator.validate();
    //
    // Validate that the generator has been run.
    //
    String actualContent = PhysicalResourceProvider.INSTANCE
        .getFile(computeOutputPath())
        .readAsStringSync();
    // Normalize Windows line endings to Unix line endings so that the
    // comparison doesn't fail on Windows.
    actualContent = actualContent.replaceAll('\r\n', '\n');

    StringBuffer sink = StringBuffer();
    DocumentationGenerator generator = DocumentationGenerator();
    generator.writeDocumentation(sink);
    String expectedContent = sink.toString();

    if (actualContent != expectedContent) {
      fail('The diagnostic documentation needs to be regenerated.\n'
          'Please run tool/diagnostics/generate.dart.');
    }
  }

  test_published() {
    // Verify that if _any_ error code is marked as having published docs then
    // _all_ codes with the same name are also marked that way.
    var nameToCodeMap = <String, List<ErrorCode>>{};
    var nameToPublishedMap = <String, bool>{};
    for (var code in errorCodeValues) {
      var name = code.name;
      nameToCodeMap.putIfAbsent(name, () => []).add(code);
      nameToPublishedMap[name] =
          (nameToPublishedMap[name] ?? false) || code.hasPublishedDocs;
    }
    var unpublished = <ErrorCode>[];
    for (var entry in nameToCodeMap.entries) {
      var name = entry.key;
      if (nameToPublishedMap[name]!) {
        for (var code in entry.value) {
          if (!code.hasPublishedDocs) {
            unpublished.add(code);
          }
        }
      }
    }
    if (unpublished.isNotEmpty) {
      var buffer = StringBuffer();
      buffer.write("The following error codes have published docs but aren't "
          "marked as such:");
      for (var code in unpublished) {
        buffer.writeln();
        buffer.write('- ${code.runtimeType}.${code.uniqueName}');
      }
      fail(buffer.toString());
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
  final String? languageVersion;

  _SnippetData(this.content, this.offset, this.length, this.auxiliaryFiles,
      this.experiments, this.languageVersion);
}

/// A test class that creates an environment suitable for analyzing the
/// snippets.
class _SnippetTest extends PubPackageResolutionTest {
  /// The snippet being tested.
  final _SnippetData snippet;

  /// Initialize a newly created test to test the given [snippet].
  _SnippetTest(this.snippet) {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: snippet.experiments,
      ),
    );
  }

  @override
  String? get testPackageLanguageVersion {
    return snippet.languageVersion;
  }

  @override
  String get testPackageRootPath => '$workspaceRootPath/docTest';

  @override
  void setUp() {
    super.setUp();
    _createAuxiliaryFiles(snippet.auxiliaryFiles);
    addTestFile(snippet.content);
  }

  void _createAuxiliaryFiles(Map<String, String> auxiliaryFiles) {
    var packageConfigBuilder = PackageConfigFileBuilder();
    for (String uriStr in auxiliaryFiles.keys) {
      if (uriStr.startsWith('package:')) {
        Uri uri = Uri.parse(uriStr);

        String packageName = uri.pathSegments[0];
        String packageRootPath = '/packages/$packageName';
        packageConfigBuilder.add(name: packageName, rootPath: packageRootPath);

        String pathInLib = uri.pathSegments.skip(1).join('/');
        newFile(
          '$packageRootPath/lib/$pathInLib',
          auxiliaryFiles[uriStr]!,
        );
      } else {
        newFile(
          '$testPackageRootPath/$uriStr',
          auxiliaryFiles[uriStr]!,
        );
      }
    }
    writeTestPackageConfig(packageConfigBuilder, ffi: true, meta: true);
  }
}
