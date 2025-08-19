// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:_js_interop_checks/js_interop_checks.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:collection/collection.dart';
import 'package:front_end/src/api_prototype/codes.dart'
    show Message, LocatedMessage;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:linter/src/lint_codes.dart';
import 'package:linter/src/rules/avoid_double_and_int_checks.dart';
import 'package:linter/src/rules/invalid_runtime_check_with_js_interop_types.dart';
import 'package:path/path.dart' as p;

/// Used to record the type of error in Flutter telemetry.
///
/// DO NOT alter the numeric values or change the meaning of these entries.
///
/// It is MUCH better to add new values and deprecate old values.
/// Consider commenting out the old value line as a tombstone.
///
/// Please notify folks in charge of Flutter Web analytics before making any
/// changes.
enum _DryRunErrorCode {
  noDartHtml(0),
  noDartJs(1),
  interopChecksError(2),
  // Deprecated.
  // ignore: unused_field
  isTestValueError(3),
  // Deprecated.
  // ignore: unused_field
  isTestTypeError(4),
  // Deprecated.
  // ignore: unused_field
  isTestGenericTypeError(5),
  invalidRuntimeCheckWithJsInteropTypesDartAsJs(6),
  invalidRuntimeCheckWithJsInteropTypesDartIsJs(7),
  invalidRuntimeCheckWithJsInteropTypesJsAsDart(8),
  invalidRuntimeCheckWithJsInteropTypesJsIsDart(9),
  invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs(10),
  invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs(11),
  invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs(12),
  avoidDoubleAndIntChecks(13);

  const _DryRunErrorCode(this.code);

  final int code;
}

class _DryRunError {
  final _DryRunErrorCode code;
  final String problemMessage;
  final Uri? errorSourceUri;
  final Location? errorLocation;

  _DryRunError(this.code, this.problemMessage,
      {this.errorSourceUri, this.errorLocation});

  static String _locationToString(Uri? sourceUri, Location? location) {
    if (sourceUri == null && location == null) return 'unknown location';
    final uri = sourceUri ?? location?.file;
    final lineCol =
        location != null ? ' ${location.line}:${location.column}' : '';
    return '$uri$lineCol';
  }

  @override
  String toString() => '${_locationToString(errorSourceUri, errorLocation)} '
      '- $problemMessage (${code.code})';
}

/// Runs several passes over the provided kernel to find any code in the
/// sources that could block a migration to WASM from JS.
///
/// At the end of execution, it emits a summary to stdout that looks like:
/// ```
/// Found incompatibilities with WebAssembly.
///
/// package:dryrun/test.dart 6:7 - JS interop class 'B' cannot extend Dart class 'A'. (2)
/// ````
class DryRunSummarizer {
  final _avoidDoubleAndIntChecks = AvoidDoubleAndIntChecks();
  final _invalidRuntimeCheckWithJSInteropTypes =
      InvalidRuntimeCheckWithJSInteropTypes();
  final Component component;
  late final CoreTypes coreTypes;
  late final ClassHierarchy classHierarchy;

  DryRunSummarizer(this.component) {
    coreTypes = CoreTypes(component);
    classHierarchy = ClassHierarchy(component, coreTypes);
  }

  static const Map<String, _DryRunErrorCode> _disallowedDartUris = {
    'dart:html': _DryRunErrorCode.noDartHtml,
    'dart:js': _DryRunErrorCode.noDartJs,
    // 'dart:ffi' is handled by interop checks.
  };

  List<_DryRunError> _analyzeImports() {
    final errors = <_DryRunError>[];

    for (final library in component.libraries) {
      if (library.importUri.scheme == 'dart') continue;

      for (final dep in library.dependencies) {
        final depLib = dep.importedLibraryReference.asLibrary;
        final code = _disallowedDartUris[depLib.importUri.toString()];
        if (code != null) {
          errors.add(_DryRunError(code, '${depLib.importUri} unsupported',
              errorSourceUri: library.importUri, errorLocation: dep.location));
        }
      }
    }

    return errors;
  }

  List<_DryRunError> _interopChecks() {
    final collector = _CollectingDiagnosticReporter(component);
    final reporter = JsInteropDiagnosticReporter(collector);
    // These checks will already have been done by the CFE but the message
    // format the CFE provides for those errors makes it hard to identify them
    // as interop-specific errors. Instead we rerun and collect any errors here.
    component.accept(JsInteropChecks(coreTypes, classHierarchy, reporter,
        JsInteropChecks.getNativeClasses(component),
        isDart2Wasm: true));
    return collector.errors;
  }

  Future<List<_DryRunError>> _lintChecks() async {
    final errors = <_DryRunError>[];

    final pathUriMap = <String, Uri>{};
    for (final library in component.libraries) {
      if (library.importUri.scheme == 'dart') continue;
      final uri = library.fileUri;
      pathUriMap[p.normalize(
          p.absolute(uri.toFilePath(windows: Platform.isWindows)))] = uri;
    }
    if (pathUriMap.isEmpty) return [];

    final collection =
        AnalysisContextCollection(includedPaths: pathUriMap.keys.toList());
    for (var context in collection.contexts) {
      var allOptions =
          (context as DriverBasedAnalysisContext).allAnalysisOptions;
      for (var options in allOptions) {
        options as AnalysisOptionsImpl;
        options.lintRules = [
          _avoidDoubleAndIntChecks,
          _invalidRuntimeCheckWithJSInteropTypes
        ];
        options.lint = true;
      }

      for (var filePath in context.contextRoot.analyzedFiles()) {
        final uri = pathUriMap[filePath]!;
        var result = await context.currentSession.getErrors(filePath);
        if (result is ErrorsResult) {
          for (final diagnostic in result.diagnostics) {
            final errorCode = _getDryRunErrorCodeFromDiagnostic(diagnostic);
            if (errorCode != null) {
              errors.add(_DryRunError(
                  errorCode,
                  '${diagnostic.diagnosticCode.name} lint violation: '
                  '${diagnostic.message}',
                  errorSourceUri: uri,
                  errorLocation: component.getLocation(
                      uri, diagnostic.problemMessage.offset)));
            }
          }
        }
      }
    }

    await collection.dispose();
    return errors;
  }

  _DryRunErrorCode? _getDryRunErrorCodeFromDiagnostic(Diagnostic diagnostic) =>
      switch (diagnostic.diagnosticCode) {
        LinterLintCode.invalidRuntimeCheckWithJsInteropTypesDartAsJs =>
          _DryRunErrorCode.invalidRuntimeCheckWithJsInteropTypesDartAsJs,
        LinterLintCode.invalidRuntimeCheckWithJsInteropTypesDartIsJs =>
          _DryRunErrorCode.invalidRuntimeCheckWithJsInteropTypesDartIsJs,
        LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsAsDart =>
          _DryRunErrorCode.invalidRuntimeCheckWithJsInteropTypesJsAsDart,
        LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsIsDart =>
          _DryRunErrorCode.invalidRuntimeCheckWithJsInteropTypesJsIsDart,
        LinterLintCode
              .invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs =>
          _DryRunErrorCode
              .invalidRuntimeCheckWithJsInteropTypesJsAsIncompatibleJs,
        LinterLintCode
              .invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs =>
          _DryRunErrorCode
              .invalidRuntimeCheckWithJsInteropTypesJsIsInconsistentJs,
        LinterLintCode.invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs =>
          _DryRunErrorCode.invalidRuntimeCheckWithJsInteropTypesJsIsUnrelatedJs,
        LinterLintCode.avoidDoubleAndIntChecks =>
          _DryRunErrorCode.avoidDoubleAndIntChecks,
        _ => null,
      };

  Future<bool> summarize() async {
    final errors = [
      ..._analyzeImports(),
      ..._interopChecks(),
      ...(await _lintChecks()),
      // TODO(srujzs): Add additional number semantics incompatibility checks
      // here.
    ];

    if (errors.isNotEmpty) {
      print('Found incompatibilities with WebAssembly.\n');
      print(errors.join('\n'));
      return true;
    }
    return false;
  }
}

class _CollectingDiagnosticReporter
    extends DiagnosticReporter<Message, LocatedMessage> {
  final Component component;
  final List<_DryRunError> errors = <_DryRunError>[];

  _CollectingDiagnosticReporter(this.component);

  @override
  void report(Message message, int charOffset, int length, Uri? fileUri,
      {List<LocatedMessage>? context}) {
    final libraryUri = fileUri != null
        ? component.libraries
            .firstWhereOrNull((e) => e.fileUri == fileUri)
            ?.importUri
        : null;
    final location =
        fileUri != null ? component.getLocation(fileUri, charOffset) : null;
    errors.add(_DryRunError(
        _DryRunErrorCode.interopChecksError, message.problemMessage,
        errorSourceUri: libraryUri ?? fileUri, errorLocation: location));
  }
}
