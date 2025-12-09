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
    //
    // The following can't currently be verified because the examples aren't
    // Dart code.
    //
    'included_file_parse_error',
    'parse_error',
    'analysis_option_deprecated',
    'deprecated_lint',
    'duplicate_rule',
    'included_file_warning',
    'include_file_not_found',
    'incompatible_lint',
    'invalid_option',
    'invalid_section_format',
    'plugins_in_inner_options',
    'recursive_include_file',
    'removed_lint',
    'undefined_lint',
    'unrecognized_error_code',
    'unsupported_option_with_legal_value',
    'unsupported_value',

    // Needs to be able to specify two expected diagnostics.
    'ambiguous_import',
    // Produces two diagnostics when it should only produce one.
    'built_in_identifier_as_type',
    // TODO(kallentu): This is always reported with
    // `argument_type_not_assignable` or is reported as
    // `const_eval_throws_exception` in const constructor evaluation.
    'const_constructor_param_type_mismatch',
    // Produces two diagnostics when it should only produce one.
    'const_deferred_class',
    // The mock SDK doesn't define any internal libraries.
    'export_internal_library',
    // Also reports subtype_of_base_or_final_is_not_base_final_or_sealed
    'extends_disallowed_class',
    // The following codes produce two diagnostics because they illustrate a
    // cycle.
    'extension_type_implements_itself',
    'extension_type_representation_depends_on_itself',
    // Not reported with `getter-setter-error` feature enabled.
    'getter_not_subtype_setter_types',
    // Has code in the example section that needs to be skipped (because it's
    // part of the explanatory text not part of the example), but there's
    // currently no way to do that.
    'invalid_implementation_override',
    // Produces two diagnostics when it should only produce one. We could get
    // rid of the invalid error by adding a declaration of a top-level variable
    // (such as `JSBool b;`), but that would complicate the example.
    'import_internal_library',
    // Produces two diagnostics when it should only produce one.
    'invalid_uri',
    // No example, by design.
    'missing_dart_library',
    // Produces two diagnostics when it should only produce one.
    'non_sync_factory',
    // Need a way to make auxiliary files that (a) are not included in the
    // generated docs or (b) can be made persistent for fixes.
    'part_of_non_part',
    // Produces multiple diagnostics when it should only produce one.
    'prefix_collides_with_top_level_member',
    // Produces two diagnostic out of necessity.
    'recursive_compile_time_constant',
    // Produces two diagnostic out of necessity.
    'recursive_constructor_redirect',
    // Produces two diagnostic out of necessity.
    'recursive_interface_inheritance',
    // Produces two diagnostics out of necessity.
    'referenced_before_declaration',
    // Produces two diagnostic out of necessity.
    'top_level_cycle',
    // Produces two diagnostic out of necessity.
    'type_alias_cannot_reference_itself',
    // Produces two diagnostic out of necessity.
    'type_parameter_supertype_of_its_bound',
    // Produces the diagnostic unused_local_variable when it shouldn't.
    'undefined_identifier_await',
    // Produces multiple diagnostic because of poor recovery.
    'yield_each_in_non_generator',

    // This is not reported after 2.12, and the examples don't compile after 3.0.
    'field_initializer_in_struct',
    // This is not reported after 2.12, and the examples don't compile after 3.0.
    'field_in_struct_with_initializer',

    // This no longer works in 3.0.
    'deprecated_colon_for_default_value',
    // The code has been replaced but is not yet removed.
    'deprecated_member_use',

    // Need a way to specify the existance of files whose content is irrelevant.
    'always_use_package_imports',
    // Missing support for example files outside of `lib`.
    'avoid_relative_lib_imports',
    // The example isn't being recognized as a flutter app. We might need to
    // build a pubspec.yaml when analyzing flutter code.
    'avoid_web_libraries_in_flutter',
    // Produces a body_might_complete_normally.
    'control_flow_in_finally',
    // Missing support for creating an indirect dependency on a package.
    'depend_on_referenced_packages',
    // Missing support for specifying the name of the test file.
    'file_names',
    // Produces an unused import diagnostic.
    'implementation_imports',
    // Doesn't produce a lint for the second example, even though the analyzer
    // does when the example is pasted into a file.
    'prefer_inlined_adds_single',
    // No mock 'test' package, no good library annotations in 'meta'.
    'library_annotations',
    // Produces an unused import diagnostic.
    'library_prefixes',
    // Produces an unused element diagnostic.
    'library_private_types_in_public_api',
    // Missing support for YAML files.
    'package_names',
    // The lint does nothing.
    'package_prefixed_library_names',
    // Need a way to specify the existance of files whose content is irrelevant.
    'prefer_relative_imports',
    // The test file is in a basic workspace, so it can't have public API. I
    // think we'd need to add a `pubspec.yaml` file to the example.
    'public_member_api_docs',
    // Missing support for YAML files.
    'secure_pubspec_urls',
    // The test framework doesn't yet support lints in non-dart files.
    'sort_pub_dependencies',
    // Doesn't produce a lint for the first example, even though the analyzer
    // does when the example is pasted into a file.
    'unnecessary_lambdas',
    // Produces an unused_field warning.
    'use_setters_to_change_properties',
    // Extra warning.
    'recursive_getters',

    // Has `language=2.9`
    'extension_declares_instance_field',

    // Produces the newer private_named_non_field_parameter diagnostic instead
    // as part of the "private named parameters" feature.
    'private_optional_parameter',

    //
    // The following can't currently be verified because the examples aren't
    // Dart code.
    //
    'asset_does_not_exist',
    'asset_directory_does_not_exist',
    'asset_field_not_list',
    'asset_missing_path',
    'asset_not_string',
    'asset_not_string_or_map',
    'asset_path_not_string',
    'dependencies_field_not_map',
    'deprecated_field',
    'flutter_field_not_map',
    'invalid_dependency',
    'invalid_platforms_field',
    'missing_name',
    'missing_dependency',
    'name_not_string',
    'path_does_not_exist',
    'path_not_posix',
    'path_pubspec_does_not_exist',
    'platform_value_disallowed',
    'unknown_platform',
    'unnecessary_dev_dependency',
    'workspace_field_not_list',
    'workspace_value_not_string',
    'workspace_value_not_subdirectory',

    // Produces two diagnostics out of necessity.
    'dead_null_aware_expression',

    // Reports final_class_extended_outside_of_library
    'deprecated_extends_function',
    // Doesn't apply to Dart files.
    // TODO(brianwilkerson): Provide better support for non-Dart files.
    'removed_lint_use',
    // Produces more than one error range by design.
    // TODO(srawlins): update verification to allow for multiple highlight ranges.
    'text_direction_code_point_in_comment',
    // Produces more than one error range by design.
    'text_direction_code_point_in_literal',
    // Produces two diagnostics out of necessity.
    'unnecessary_null_comparison_never_null_false',
    // Produced two diagnostics because `mustBeConst` is experimental.
    'non_const_argument_for_const_parameter',
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
    await _validateMessages(feAnalyzerSharedMessages);
    await _validateMessages(analyzerMessages);
    await _validateMessages(analysisServerMessages);
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
      buffer.writeln('  $variableName');
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
        codeName =
            (message.sharedName ?? message.analyzerCode).lowerSnakeCaseName;
        variableName = message.analyzerCode.lowerSnakeCaseName;
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
    _SnippetTest test = _SnippetTest(snippet);
    test.setUp();
    await test.resolveTestFile();
    List<Diagnostic> diagnostics = test.result.diagnostics;
    int errorCount = diagnostics.length;
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
        Diagnostic diagnostic = diagnostics[0];
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
  final String? languageVersion;
  String? lintCode;

  _SnippetData(
    this.content,
    this.offset,
    this.length,
    this.auxiliaryFiles,
    this.experiments,
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
