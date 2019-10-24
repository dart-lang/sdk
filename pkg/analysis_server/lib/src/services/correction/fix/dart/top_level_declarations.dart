// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/src/services/available_declarations.dart';

/// Information about a single top-level declaration.
class TopLevelDeclaration {
  /// The path of the library that exports this declaration.
  final String path;

  /// The URI of the library that exports this declaration.
  final Uri uri;

  final TopLevelDeclarationKind kind;

  final String name;

  /// Is `true` if the declaration is exported, not declared in the [path].
  final bool isExported;

  TopLevelDeclaration(
    this.path,
    this.uri,
    this.kind,
    this.name,
    this.isExported,
  );

  @override
  String toString() => '($path, $uri, $kind, $name, $isExported)';
}

/// Kind of a top-level declaration.
///
/// We don't need it to be precise, just enough to support quick fixes.
enum TopLevelDeclarationKind { type, extension, function, variable }

class TopLevelDeclarationsProvider {
  final DeclarationsTracker tracker;

  TopLevelDeclarationsProvider(this.tracker);

  void doTrackerWork() {
    while (tracker.hasWork) {
      tracker.doWork();
    }
  }

  List<TopLevelDeclaration> get(
    AnalysisContext analysisContext,
    String path,
    String name,
  ) {
    var declarations = <TopLevelDeclaration>[];

    void addDeclarations(Library library) {
      for (var declaration in library.declarations) {
        if (declaration.name != name) continue;

        var kind = _getTopKind(declaration.kind);
        if (kind == null) continue;

        declarations.add(
          TopLevelDeclaration(
            library.path,
            library.uri,
            kind,
            name,
            declaration.locationLibraryUri != library.uri,
          ),
        );
      }
    }

    var declarationsContext = tracker.getContext(analysisContext);
    if (declarationsContext == null) return const [];

    var libraries = declarationsContext.getLibraries(path);
    libraries.context.forEach(addDeclarations);
    libraries.dependencies.forEach(addDeclarations);
    libraries.sdk.forEach(addDeclarations);

    return declarations;
  }

  TopLevelDeclarationKind _getTopKind(DeclarationKind kind) {
    switch (kind) {
      case DeclarationKind.CLASS:
      case DeclarationKind.CLASS_TYPE_ALIAS:
      case DeclarationKind.ENUM:
      case DeclarationKind.FUNCTION_TYPE_ALIAS:
      case DeclarationKind.MIXIN:
        return TopLevelDeclarationKind.type;
        break;
      case DeclarationKind.EXTENSION:
        return TopLevelDeclarationKind.extension;
        break;
      case DeclarationKind.FUNCTION:
        return TopLevelDeclarationKind.function;
        break;
      case DeclarationKind.GETTER:
      case DeclarationKind.SETTER:
      case DeclarationKind.VARIABLE:
        return TopLevelDeclarationKind.variable;
        break;
      default:
        return null;
    }
  }
}
