// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/fix/fix_context.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/src/services/top_level_declarations.dart';
import 'package:analyzer/utilities/extensions/element.dart';

/// An object used to provide context information for Dart fix contributors.
///
/// Clients may not extend, implement or mix-in this class.
class DartFixContext implements FixContext {
  /// Whether fixes were triggered automatically (for example by a save
  /// operation).
  ///
  /// Some fixes may be excluded when running automatically. For example
  /// removing unused imports or parameters is less acceptable while the code is
  /// incomplete and being worked on than when manually executing fixes ready
  /// for committing.
  final bool autoTriggered;

  /// The instrumentation service used to report errors that prevent a fix from
  /// being composed.
  final InstrumentationService instrumentationService;

  /// The library result in which the fix operates.
  final ResolvedLibraryResult libraryResult;

  /// The unit result in which the fix operates.
  final ResolvedUnitResult unitResult;

  // The [CorrectionUtils] for the unit result.
  final CorrectionUtils correctionUtils;

  /// The workspace in which the fix contributor operates.
  final ChangeWorkspace workspace;

  /// Cache of previously computed [getTopLevelDeclarations] responses.
  ///
  /// It's been observed that the same request is fired multiple times for at
  /// least some getFixes requsts. Caching the response can speed up such
  /// requests.
  final Map<String, Future<Map<LibraryElement, Element>>>
      _cachedTopLevelDeclarations = {};

  @override
  final Diagnostic diagnostic;

  DartFixContext({
    required this.instrumentationService,
    required this.workspace,
    required this.libraryResult,
    required this.unitResult,
    // TODO(srawlins): Rename to `diagnostic`.
    required Diagnostic error,
    this.autoTriggered = false,
    CorrectionUtils? correctionUtils,
  })  : diagnostic = error,
        correctionUtils = correctionUtils ?? CorrectionUtils(unitResult);

  @override
  Diagnostic get error => diagnostic;

  /// Returns the mapping from each library (that is available to this context)
  /// to a top-level declaration that is exported (not necessary declared) by
  /// this library, and has the requested base name.
  ///
  /// For getters and setters the corresponding top-level variable is returned.
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(String name) {
    var cachedResult = _cachedTopLevelDeclarations[name];
    if (cachedResult != null) return cachedResult;
    var result = TopLevelDeclarations(unitResult).withName(name);
    _cachedTopLevelDeclarations[name] = result;
    return result;
  }

  /// Returns libraries with extensions that declare non-static public
  /// extension members with the [memberName].
  Stream<LibraryElement> librariesWithExtensions(Name memberName) async* {
    var analysisContext = unitResult.session.analysisContext;
    if (analysisContext is! DriverBasedAnalysisContext) {
      return;
    }

    var analysisDriver = analysisContext.driver;
    await analysisDriver.discoverAvailableFiles();

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(unitResult.path),
    );

    for (var file in fsState.knownFiles.toList()) {
      if (!filter.shouldInclude(file)) {
        continue;
      }

      var elementResult = await analysisDriver.getLibraryByUri(file.uriStr);
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      if (elementResult.element2.exportedExtensions
          .havingMemberWithBaseName(memberName)
          .isNotEmpty) {
        yield elementResult.element2;
      }
    }
  }
}
