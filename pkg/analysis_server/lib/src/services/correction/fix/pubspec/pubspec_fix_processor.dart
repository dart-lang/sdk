// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:yaml/yaml.dart';

typedef PubspecFixRequestResult = ({
  List<SourceFileEdit> edits,
  List<BulkFix> details,
});

/// A fix processor that produces changes to `pubspec.yaml` files to fix
/// issues like missing dependencies.
class PubspecFixProcessor {
  /// The set of diagnostic codes that will cause pubspec fixes to be applied
  /// when filtering by specific codes.
  static final _pubspecFixDiagnosticCodes = {
    diag.missingDependency.lowerCaseName,
    diag.dependOnReferencedPackages.lowerCaseName,
    diag.migrateDesignWidgets.lowerCaseName,
  };

  final ResourceProvider _resourceProvider;
  final Set<String>? _codesToFix;
  final String _defaultEol;
  final CancellationToken? _cancellationToken;
  final String? _onlyForFile;

  /// Constructs a new [PubspecFixProcessor].
  ///
  /// If [_onlyForFile] is provided, only package dependencies referenced from
  /// that file are considered.
  new({
    required this._resourceProvider,
    this._codesToFix,
    required this._defaultEol,
    this._cancellationToken,
    this._onlyForFile,
  });

  bool get _isCancellationRequested =>
      _cancellationToken?.isCancellationRequested ?? false;

  /// Computes changes to the pubspec files in the given [contexts].
  ///
  Future<PubspecFixRequestResult> fix(List<AnalysisContext> contexts) async {
    assert(
      _onlyForFile == null || contexts.length == 1,
      'When fixing pubspec issues only for one file, only one context should '
      'be provided',
    );

    // If we were filtered to a set of codes that doesn't include codes that
    // should make pubspec fixes, don't compute any fixes.
    if (_codesToFix != null &&
        !_codesToFix.any(_pubspecFixDiagnosticCodes.contains)) {
      return (edits: const <SourceFileEdit>[], details: const <BulkFix>[]);
    }

    var fixes = <SourceFileEdit>[];
    var details = <BulkFix>[];
    for (var context in contexts) {
      if (_isCancellationRequested) break;

      var workspace = context.contextRoot.workspace;
      if (workspace is! PackageConfigWorkspace) continue;

      var packageToDeps = <PubPackage, _PubspecDeps>{};

      var filePaths = _onlyForFile != null
          ? [_onlyForFile]
          : context.contextRoot.analyzedFiles();
      for (var filePath in filePaths) {
        if (_isCancellationRequested) break;

        _fixFile(
          filePath,
          context: context,
          workspace: workspace,
          packageToDeps: packageToDeps,
        );
      }

      // Iterate over packages in the workspace, compute changes to pubspec.
      for (var package in packageToDeps.keys) {
        if (_isCancellationRequested) break;

        var pubspecDeps = packageToDeps[package]!;
        var pubspecFile = package.pubspecFile;
        var result = await _runPubspecValidatorAndFixGenerator(
          FileSource(pubspecFile),
          pubspecDeps.packages,
          pubspecDeps.devPackages.difference(pubspecDeps.packages),
          _resourceProvider,
        );
        if (result.isNotEmpty) {
          for (var fix in result) {
            fixes.addAll(fix.change.edits);
          }
          details.add(
            BulkFix(pubspecFile.path, [
              // TODO(dantup): We always show 1 here and this diagnostic code
              //  even if there are multiple packages added and if the
              //  diagnostic is something like depend_on_referenced_packages.
              BulkFixDetail(diag.missingDependency.lowerCaseName, 1),
            ]),
          );
        }
      }
    }
    return (edits: fixes, details: details);
  }

  void _fixFile(
    String filePath, {
    required AnalysisContext context,
    required Workspace workspace,
    required Map<PubPackage, _PubspecDeps> packageToDeps,
  }) {
    if (!file_paths.isDart(_resourceProvider.pathContext, filePath) ||
        file_paths.isGenerated(filePath)) {
      return;
    }
    var package = workspace.findPackageFor(filePath);
    if (package is! PubPackage) return;

    var libPath = package.root.getFolder('lib');
    var binPath = package.root.getFolder('bin');

    var pubspecDeps = packageToDeps.putIfAbsent(package, () => _PubspecDeps());

    // Get the list of imports/exports used in the files.
    var parsedUnits = <ParsedUnitResult>[];
    var libraryResult = context.currentSession.getParsedLibrary(filePath);
    if (libraryResult is ParsedLibraryResult) {
      parsedUnits.addAll(libraryResult.units);
    } else if (_onlyForFile != null) {
      var unitResult = context.currentSession.getParsedUnit(filePath);
      if (unitResult is ParsedUnitResult) {
        parsedUnits.add(unitResult);
      }
    }

    void addPackage(String? uriString, String path) {
      if (uriString == null || !uriString.startsWith('package:')) return;

      var uri = Uri.tryParse(uriString);
      if (uri == null || uri.pathSegments.isEmpty) return;

      var name = uri.pathSegments.first;
      if (libPath.contains(path) || binPath.contains(path)) {
        pubspecDeps.packages.add(name);
      } else {
        pubspecDeps.devPackages.add(name);
      }
    }

    for (var unitResult in parsedUnits) {
      var directives = unitResult.unit.directives;
      for (var directive in directives) {
        if (directive is NamespaceDirective) {
          addPackage(directive.uri.stringValue, unitResult.path);
          for (var configuration in directive.configurations) {
            addPackage(configuration.uri.stringValue, unitResult.path);
          }
        }
      }
    }
  }

  Future<List<Fix>> _runPubspecValidatorAndFixGenerator(
    Source pubspec,
    Set<String> usedDeps,
    Set<String> usedDevDeps,
    ResourceProvider resourceProvider,
  ) async {
    String contents = pubspec.contents.data;
    YamlNode? node;
    try {
      node = loadYamlNode(contents);
    } catch (_) {
      // Could not parse the pubspec file.
      return const [];
    }

    if (node is! YamlMap) {
      // The file is empty.
      return const [];
    }

    var errors = MissingDependencyValidator(
      node,
      pubspec,
      resourceProvider,
    ).validate(usedDeps, usedDevDeps);
    if (errors.isEmpty) return const [];

    var generator = PubspecFixGenerator(
      resourceProvider,
      errors[0],
      contents,
      node,
      defaultEol: _defaultEol,
    );
    return await generator.computeFixes();
  }
}

class _PubspecDeps {
  final Set<String> packages = <String>{};
  final Set<String> devPackages = <String>{};
}
