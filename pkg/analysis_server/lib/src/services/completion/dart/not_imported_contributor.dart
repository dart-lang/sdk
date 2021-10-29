// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show SuggestionBuilder;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A contributor of suggestions from not yet imported libraries.
class NotImportedContributor extends DartCompletionContributor {
  /// Tests set this function to abort the current request.
  @visibleForTesting
  static void Function(FileState)? onFile;

  final CompletionBudget budget;
  final List<Uri> librariesToImport;

  NotImportedContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
    this.budget,
    this.librariesToImport,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    if (!request.includeIdentifiers) {
      return;
    }

    var session = request.result.session as AnalysisSessionImpl;
    var analysisDriver = session.getDriver(); // ignore: deprecated_member_use

    var fsState = analysisDriver.fsState;
    var filter = _buildFilter(fsState);

    try {
      await analysisDriver.discoverAvailableFiles().timeout(budget.left);
    } on TimeoutException {
      return;
    }

    var knownFiles = fsState.knownFiles.toList();
    for (var file in knownFiles) {
      onFile?.call(file);
      request.checkAborted();

      if (budget.isEmpty) {
        return;
      }

      if (!filter.shouldInclude(file)) {
        continue;
      }

      var elementResult = await session.getLibraryByUri(file.uriStr);
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      var newSuggestions = builder.markSuggestions();

      _buildSuggestions(
        elementResult.element.exportNamespace,
      );

      newSuggestions.setLibraryUriToImportIndex(() {
        librariesToImport.add(file.uri);
        return librariesToImport.length - 1;
      });
    }
  }

  _Filter _buildFilter(FileSystemState fsState) {
    var file = fsState.getFileForPath(request.result.path);
    var workspacePackage = file.workspacePackage;
    if (workspacePackage is PubWorkspacePackage) {
      return _PubFilter(workspacePackage, file.path);
    } else {
      return _AnyFilter();
    }
  }

  void _buildSuggestions(Namespace namespace) {
    var visitor = LibraryElementSuggestionBuilder(request, builder);
    for (var element in namespace.definedNames.values) {
      element.accept(visitor);
    }
  }
}

class _AnyFilter implements _Filter {
  @override
  bool shouldInclude(FileState file) => true;
}

abstract class _Filter {
  bool shouldInclude(FileState file);
}

class _PubFilter implements _Filter {
  final PubWorkspacePackage targetPackage;
  final String? targetPackageName;
  final bool targetInLib;
  final Set<String> dependencies;

  factory _PubFilter(PubWorkspacePackage package, String path) {
    var inLib = package.workspace.provider
        .getFolder(package.root)
        .getChildAssumingFolder('lib')
        .contains(path);

    var dependencies = <String>{};
    var pubspec = package.pubspec;
    if (pubspec != null) {
      dependencies.addAll(pubspec.dependencies.names);
      if (!inLib) {
        dependencies.addAll(pubspec.devDependencies.names);
      }
    }

    return _PubFilter._(
      targetPackage: package,
      targetPackageName: pubspec?.name?.value.text,
      targetInLib: inLib,
      dependencies: dependencies,
    );
  }

  _PubFilter._({
    required this.targetPackage,
    required this.targetPackageName,
    required this.targetInLib,
    required this.dependencies,
  });

  @override
  bool shouldInclude(FileState file) {
    var uri = file.uri;
    if (uri.isScheme('dart')) {
      return true;
    }

    // Normally only package URIs are available.
    // But outside of lib/ we allow any files of this package.
    if (!uri.isScheme('package')) {
      if (targetInLib) {
        return false;
      } else {
        var filePackage = file.workspacePackage;
        return filePackage is PubWorkspacePackage &&
            filePackage.root == targetPackage.root;
      }
    }

    // Sanity check.
    var uriPathSegments = uri.pathSegments;
    if (uriPathSegments.length < 2) {
      return false;
    }

    // Any `package:` library from the same package.
    var packageName = uriPathSegments[0];
    if (packageName == targetPackageName) {
      return true;
    }

    // If not the same package, must be public.
    if (uriPathSegments[1] == 'src') {
      return false;
    }

    return dependencies.contains(packageName);
  }
}

extension on PSDependencyList? {
  List<String> get names {
    final self = this;
    if (self == null) {
      return const [];
    } else {
      return self
          .map((dependency) => dependency.name?.text)
          .whereNotNull()
          .toList();
    }
  }
}
