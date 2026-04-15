// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/lint_messages.dart';
import 'package:analyzer_utilities/messages.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/messages/error_code_documentation_info.dart';
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
    // The following diagnostics can't be verified because the examples aren't
    // Dart code. The verifier needs to add the ability to verify YAML snippets
    // and to use a YAML snippet as the example. If we can do this based on the
    // class of the diagnostic, then there will be less chance of a false
    // positive.
    'analysis_option_deprecated',
    'asset_does_not_exist',
    'asset_directory_does_not_exist',
    'asset_field_not_list',
    'asset_missing_path',
    'asset_not_string',
    'asset_not_string_or_map',
    'asset_path_not_string',
    'dependencies_field_not_map',
    'deprecated_field',
    'deprecated_lint',
    'duplicate_rule',
    'flutter_field_not_map',
    'included_file_parse_error',
    'included_file_warning',
    'include_file_not_found',
    'incompatible_lint',
    'invalid_dependency',
    'invalid_option',
    'invalid_platforms_field',
    'invalid_section_format',
    'missing_name',
    'missing_dependency',
    'name_not_string',
    'package_names',
    'path_does_not_exist',
    'path_not_posix',
    'path_pubspec_does_not_exist',
    'parse_error',
    'platform_value_disallowed',
    'plugins_in_inner_options',
    'recursive_include_file',
    'removed_lint',
    'removed_lint_use',
    'secure_pubspec_urls',
    'sort_pub_dependencies',
    'unknown_platform',
    'undefined_lint',
    'unnecessary_dev_dependency',
    'unrecognized_error_code',
    'unsupported_option_with_legal_value',
    'unsupported_value',
    'workspace_field_not_list',
    'workspace_value_not_string',
    'workspace_value_not_subdirectory',

    // The following diagnostics can't be verified because they necessarily
    // produce more than one diagnostic. This is typically because of a conflict
    // between two or more declarations, neither of which is obviously the
    // better declaration to flag, and we have chosen to create a diagnostic for
    // all of them.
    'ambiguous_import',
    'extension_type_implements_itself',
    'extension_type_representation_depends_on_itself',
    'recursive_compile_time_constant',
    'recursive_constructor_redirect',
    'recursive_interface_inheritance',
    'text_direction_code_point_in_comment',
    'text_direction_code_point_in_literal',
    'top_level_cycle',
    'type_alias_cannot_reference_itself',
    'type_parameter_supertype_of_its_bound',

    // const_constructor_param_type_mismatch (analyzer)
    // - Expected an error with code const_constructor_param_type_mismatch,
    //   found const_eval_throws_exception (example 0).
    //
    // Based on the TODO comment below, it appears that this diagnostic is never
    // reported, and it should be marked as removed.
    //
    // TODO(kallentu): This is always reported with
    // `argument_type_not_assignable` or is reported as
    // `const_eval_throws_exception` in const constructor evaluation.
    'const_constructor_param_type_mismatch',

    // invalid_implementation_override (analyzer)
    // - No error range in example
    // - Expected no errors but found 1 (example 1):
    //   undefined_class (7, 1) Undefined class 'B'.
    //
    // Has code in the example section that needs to be skipped (because it's
    // part of the explanatory text not part of the example), but there's
    // currently no way to do that. We could try to rewrite the text so that all
    // of the code is in a single snippet, or we could introduce a way to skip
    // some code blocks.
    'invalid_implementation_override',

    // invalid_uri (analyzer)
    // - Expected an error with code invalid_uri, found uri_does_not_exist
    //   (example 0).
    //
    // It's possible that this diagnostic is no longer reported.
    'invalid_uri',

    // yield_each_in_non_generator (analyzer)
    // - No error range in example
    // - Expected no errors but found 2 (example 0):
    //   - undefined_identifier (29, 5) Undefined name 'yield'.
    //   - body_might_complete_normally (18, 6) The body might complete
    //     normally, causing 'null' to be returned, but the return type,
    //     'Iterable<int>', is a potentially non-nullable type.
    'yield_each_in_non_generator',

    // deprecated_colon_for_default_value (analyzer)
    // - Expected an error with code deprecated_colon_for_default_value, found
    //   obsolete_colon_for_default_value (example 0).
    //
    // This no longer works in 3.0 and should be marked as removed.
    'deprecated_colon_for_default_value',

    // deprecated_member_use (analyzer)
    // - Expected an error with code deprecated_member_use, found
    //   undefined_class (example 0).
    //
    // The example needs to have a definition of `C` that is marked as
    // deprecated.
    'deprecated_member_use',

    // avoid_relative_lib_imports (linter)
    // - Expected one error but found 2 (example 0):
    //   - uri_does_not_exist (7, 15) Target of URI doesn't exist: '../lib/a.dart'.
    //   - avoid_relative_lib_imports (7, 15) Can't use a relative path to import a library in 'lib'.
    // - Expected no errors but found 1 (fixes 0):
    //   - unused_import (7, 8) Unused import: 'a.dart'.
    //
    // Missing support for example files outside of `lib`.
    'avoid_relative_lib_imports',

    // avoid_web_libraries_in_flutter (linter)
    // - Expected one error but found none (example 0).
    //
    // The example isn't being recognized as a flutter app. We might need to
    // build a pubspec.yaml when analyzing flutter code.
    'avoid_web_libraries_in_flutter',

    // depend_on_referenced_packages (linter)
    // - Expected one error but found none (example 0).
    //
    // The example doesn't generate the documented diagnostic.
    'depend_on_referenced_packages',

    // file_names (linter)
    // - No example.
    //
    // There's no interesting file content to use as an example. We could have
    // some placeholder content to get rid of the failure, but the documentation
    // wouldn't be improved.
    'file_names',

    // prefer_inlined_adds_single (linter)
    // - Expected one error but found none (example 1).
    //
    // Doesn't produce a lint for the second example, even though the analyzer
    // does when the example is pasted into a file.
    'prefer_inlined_adds_single',

    // library_annotations (linter)
    // - Expected an error with code library_annotations, found
    // undefined_annotation (example 0).
    // - Expected no errors but found 1 (fixes 0):
    //   - undefined_annotation (0, 18) Undefined name 'TestOn' used as an
    //     annotation.
    //
    // No mock 'test' package, no good library annotations in 'meta'.
    'library_annotations',

    // package_prefixed_library_names (linter)
    // - Expected one error but found none (example 0).
    //
    // The lint does nothing, so no diagnostic is produced. I needs to be marked
    // as 'removed'.
    'package_prefixed_library_names',

    // prefer_relative_imports (linter)
    // No error range in example
    // - Expected no errors but found 1 (example 0):
    //   - uri_does_not_exist (7, 29) Target of URI doesn't exist:
    //     'package:my_package/bar.dart'.
    // - Expected no errors but found 1 (fixes 0):
    //   - uri_does_not_exist (7, 10) Target of URI doesn't exist: 'bar.dart'.
    //
    // Need a way to specify the existance of files whose content is irrelevant.
    // Either that or the example needs to include a minial file to refer to.
    'prefer_relative_imports',

    // public_member_api_docs (linter)
    // - Expected one error but found none (example 0).
    //
    // The test file is in a basic workspace, so it can't have public API. I
    // think we'd need to add a `pubspec.yaml` file to the example.
    'public_member_api_docs',

    // recursive_getters (linter)
    // - Expected an error at 39, found 48 (example 0).
    //
    // The lint fires when the example is pasted into an empty file.
    'recursive_getters',

    // Missing a mock of `Expando` in `dart:core`.
    'extension_declares_instance_field',

    // deprecated_extends_function (analyzer)
    // - Expected an error with code deprecated_subtype_of_function, found
    //  final_class_extended_outside_of_library (example 0).
    //
    // Probably needs a language override comment, but I don't know which
    // version.
    'deprecated_extends_function',
  ];

  /// The buffer to which validation errors are written.
  final StringBuffer buffer = StringBuffer();

  /// The name of the package containing the variables currently being verified.
  late String packageName;

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
    packageName = '_fe_analyzer_shared';
    await _validateMessages(feAnalyzerSharedMessages);
    packageName = 'analyzer';
    await _validateMessages(analyzerMessages);
    packageName = 'analysis_server';
    await _validateMessages(analysisServerMessages);
    packageName = 'linter';
    await _validateMessages(lintMessages);
    if (buffer.isNotEmpty) {
      fail(buffer.toString());
    }
  }

  _SnippetData _extractSnippetData(
    String snippet,
    bool errorRequired,
    Map<String, String> auxiliaryFiles,
    List<String> experiments,
    List<String> ignores,
    String? languageVersion,
  ) {
    int rangeStart = snippet.indexOf(errorRangeStart);
    if (rangeStart < 0) {
      if (errorRequired) {
        _reportProblem('No error range in example');
      }
      return _SnippetData(
        snippet,
        -1,
        0,
        auxiliaryFiles,
        experiments,
        ignores,
        languageVersion,
      );
    }
    int rangeEnd = snippet.indexOf(errorRangeEnd, rangeStart + 1);
    if (rangeEnd < 0) {
      _reportProblem('No end of error range in example');
      return _SnippetData(
        snippet,
        -1,
        0,
        auxiliaryFiles,
        experiments,
        ignores,
        languageVersion,
      );
    } else if (snippet.indexOf(errorRangeStart, rangeEnd) > 0) {
      _reportProblem('More than one error range in example');
    }
    String content;
    try {
      content =
          snippet.substring(0, rangeStart) +
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
      ignores,
      languageVersion,
    );
  }

  /// Extract the snippets of Dart code from [documentationParts] that are
  /// tagged as belonging to the given [blockSection].
  List<_SnippetData> _extractSnippets(
    List<ErrorCodeDocumentationPart> documentationParts,
    BlockSection blockSection,
  ) {
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
            snippets.add(
              _extractSnippetData(
                documentationPart.text,
                blockSection == BlockSection.examples,
                auxiliaryFiles,
                documentationPart.experiments,
                documentationPart.ignores,
                documentationPart.languageVersion,
              ),
            );
          }
          auxiliaryFiles = <String, String>{};
        }
      }
    }
    return snippets;
  }

  /// Report a problem with the current error code.
  void _reportProblem(
    String problem, {
    List<Diagnostic> diagnostics = const [],
  }) {
    if (!hasWrittenVariableName) {
      buffer.writeln('  $variableName ($packageName)');
      hasWrittenVariableName = true;
    }
    buffer.writeln('    $problem');
    for (Diagnostic diagnostic in diagnostics) {
      buffer.write('      ');
      buffer.write(diagnostic.diagnosticCode);
      buffer.write(' (');
      buffer.write(diagnostic.offset);
      buffer.write(', ');
      buffer.write(diagnostic.length);
      buffer.write(') ');
      buffer.writeln(diagnostic.message);
    }
  }

  /// Extract documentation from the given [messages].
  Future<void> _validateMessages(List<MessageWithAnalyzerCode> messages) async {
    for (var message in messages) {
      // If the diagnostic is no longer generated,
      // the corresponding code snippets won't report it.
      if (message.isRemoved) {
        continue;
      }
      var docs = parseErrorCodeDocumentation(
        message.analyzerCode.toString(),
        message.documentation,
      );
      if (docs != null) {
        codeName = (message.sharedName ?? message.analyzerCode).snakeCaseName;
        variableName = message.analyzerCode.snakeCaseName;
        if (unverifiedDocs.contains(variableName)) {
          continue;
        }
        hasWrittenVariableName = false;

        List<_SnippetData> exampleSnippets = _extractSnippets(
          docs,
          BlockSection.examples,
        );
        _SnippetData? firstExample;
        if (exampleSnippets.isEmpty) {
          _reportProblem('No example.');
        } else {
          firstExample = exampleSnippets[0];
        }
        for (int i = 0; i < exampleSnippets.length; i++) {
          _SnippetData snippet = exampleSnippets[i];
          if (message.type == AnalyzerDiagnosticType.lint) {
            snippet.lintCode = codeName;
          }
          await _validateSnippet('example', i, snippet);
        }

        List<_SnippetData> fixesSnippets = _extractSnippets(
          docs,
          BlockSection.commonFixes,
        );
        for (int i = 0; i < fixesSnippets.length; i++) {
          _SnippetData snippet = fixesSnippets[i];
          if (firstExample != null) {
            snippet.auxiliaryFiles.addAll(firstExample.auxiliaryFiles);
          }
          if (message.type == AnalyzerDiagnosticType.lint) {
            snippet.lintCode = codeName;
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
    String section,
    int index,
    _SnippetData snippet,
  ) async {
    var test = _SnippetTest(snippet);
    test.setUp();
    await test.resolveTestFile();
    var diagnostics = test.result.diagnostics;
    var filteredDiagnostics = <Diagnostic>[];
    var errorCount = 0;
    var unneededIgnores = snippet.ignores.toList();
    for (var diagnostic in diagnostics) {
      var diagnosticName = diagnostic.diagnosticCode.lowerCaseName;
      if (snippet.ignores.contains(diagnosticName)) {
        unneededIgnores.remove(diagnosticName);
      } else {
        errorCount++;
        filteredDiagnostics.add(diagnostic);
      }
    }

    if (snippet.offset < 0) {
      if (errorCount > 0) {
        _reportProblem(
          'Expected no errors but found $errorCount ($section $index):',
          diagnostics: diagnostics,
        );
      }
    } else {
      if (errorCount == 0) {
        _reportProblem('Expected one error but found none ($section $index).');
      } else if (errorCount == 1) {
        var diagnostic = filteredDiagnostics[0];
        if (diagnostic.diagnosticCode.lowerCaseName != codeName) {
          _reportProblem(
            'Expected an error with code $codeName, '
            'found ${diagnostic.diagnosticCode} ($section $index).',
          );
        }
        if (diagnostic.offset != snippet.offset) {
          _reportProblem(
            'Expected an error at ${snippet.offset}, '
            'found ${diagnostic.offset} ($section $index).',
          );
        }
        if (diagnostic.length != snippet.length) {
          _reportProblem(
            'Expected an error of length ${snippet.length}, '
            'found ${diagnostic.length} ($section $index).',
          );
        }
      } else {
        _reportProblem(
          'Expected one error but found $errorCount ($section $index):',
          diagnostics: diagnostics,
        );
      }
    }
    if (unneededIgnores.isNotEmpty) {
      var list = unneededIgnores.join(', ');
      _reportProblem('Unneeded ignores: $list ($section $index).');
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
  }

  test_published() {
    // Verify that if _any_ error code is marked as having published docs then
    // _all_ codes with the same name are also marked that way.
    var nameToCodeMap = <String, List<DiagnosticCode>>{};
    var nameToPublishedMap = <String, bool>{};
    for (var code in diagnosticCodeValues) {
      var name = code.lowerCaseName;
      nameToCodeMap.putIfAbsent(name, () => []).add(code);
      nameToPublishedMap[name] =
          (nameToPublishedMap[name] ?? false) || code.hasPublishedDocs;
    }
    var unpublished = <DiagnosticCode>[];
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
      buffer.write(
        "The following error codes have published docs but aren't "
        "marked as such:",
      );
      for (var code in unpublished) {
        buffer.writeln();
        buffer.write('- ${code.runtimeType}.${code.lowerCaseUniqueName}');
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
  final List<String> ignores;
  final String? languageVersion;
  String? lintCode;

  _SnippetData(
    this.content,
    this.offset,
    this.length,
    this.auxiliaryFiles,
    this.experiments,
    this.ignores,
    this.languageVersion,
  );
}

/// A test class that creates an environment suitable for analyzing the
/// snippets.
class _SnippetTest extends PubPackageResolutionTest {
  /// The snippet being tested.
  final _SnippetData snippet;

  /// Initialize a newly created test to test the given [snippet].
  _SnippetTest(this.snippet) {
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: snippet.experiments),
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
    _createAnalysisOptionsFile();
    _createAuxiliaryFiles(snippet.auxiliaryFiles);
    addTestFile(snippet.content);
  }

  void _createAnalysisOptionsFile() {
    var lintCode = snippet.lintCode;
    if (lintCode != null) {
      writeTestPackageAnalysisOptionsFile(
        analysisOptionsContent(
          rules: [lintCode],
          experiments: snippet.experiments,
        ),
      );
    }
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
        newFile('$packageRootPath/lib/$pathInLib', auxiliaryFiles[uriStr]!);
      } else {
        newFile('$testPackageRootPath/$uriStr', auxiliaryFiles[uriStr]!);
      }
    }
    writeTestPackageConfig(
      packageConfigBuilder,
      angularMeta: true,
      ffi: true,
      flutter: true,
      meta: true,
    );
  }
}
