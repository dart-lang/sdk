// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ImportLibrary extends MultiCorrectionProducer {
  final _ImportKind _importKind;

  ImportLibrary(this._importKind);

  @override
  Iterable<CorrectionProducer> get producers sync* {
    if (_importKind == _ImportKind.dartAsync) {
      yield* _importLibrary(DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async'));
    } else if (_importKind == _ImportKind.forExtension) {
      if (node is SimpleIdentifier) {
        var extensionName = (node as SimpleIdentifier).name;
        yield* _importLibraryForElement(
            extensionName,
            const [ElementKind.EXTENSION],
            const [TopLevelDeclarationKind.extension]);
      }
    } else if (_importKind == _ImportKind.forFunction) {
      if (node is SimpleIdentifier) {
        if (node.parent is MethodInvocation) {
          var invocation = node.parent as MethodInvocation;
          if (invocation.realTarget != null || invocation.methodName != node) {
            return;
          }
        }

        var name = (node as SimpleIdentifier).name;
        yield* _importLibraryForElement(name, const [
          ElementKind.FUNCTION,
          ElementKind.TOP_LEVEL_VARIABLE
        ], const [
          TopLevelDeclarationKind.function,
          TopLevelDeclarationKind.variable
        ]);
      }
    } else if (_importKind == _ImportKind.forTopLevelVariable) {
      var node = this.node;
      if (node is Annotation) {
        Annotation annotation = node;
        var name = annotation.name;
        if (name != null && name.staticElement == null) {
          if (annotation.arguments != null) {
            return;
          }
          node = name;
        }
      }
      if (node is SimpleIdentifier) {
        var name = node.name;
        yield* _importLibraryForElement(
            name,
            const [ElementKind.TOP_LEVEL_VARIABLE],
            const [TopLevelDeclarationKind.variable]);
      }
    } else if (_importKind == _ImportKind.forType) {
      var node = this.node;
      if (node is Annotation) {
        Annotation annotation = node;
        var name = annotation.name;
        if (name != null && name.staticElement == null) {
          if (annotation.arguments == null) {
            return;
          }
          node = name;
        }
      }
      if (mightBeTypeIdentifier(node)) {
        var typeName = (node is SimpleIdentifier)
            ? node.name
            : (node as PrefixedIdentifier).prefix.name;
        yield* _importLibraryForElement(
            typeName,
            const [ElementKind.CLASS, ElementKind.FUNCTION_TYPE_ALIAS],
            const [TopLevelDeclarationKind.type]);
      } else if (mightBeImplicitConstructor(node)) {
        var typeName = (node as SimpleIdentifier).name;
        yield* _importLibraryForElement(typeName, const [ElementKind.CLASS],
            const [TopLevelDeclarationKind.type]);
      }
    }
  }

  @override
  bool mightBeTypeIdentifier(AstNode node) {
    if (super.mightBeTypeIdentifier(node)) {
      return true;
    }
    if (node is PrefixedIdentifier) {
      var parent = node.parent;
      if (parent is TypeName) {
        return true;
      }
    }
    return false;
  }

  /// Return the relative uri from the passed [library] to the given [path].
  /// If the [path] is not in the LibraryElement, `null` is returned.
  String _getRelativeURIFromLibrary(LibraryElement library, String path) {
    var librarySource = library?.librarySource;
    if (librarySource == null) {
      return null;
    }
    var pathCtx = resourceProvider.pathContext;
    var libraryDirectory = pathCtx.dirname(librarySource.fullName);
    var sourceDirectory = pathCtx.dirname(path);
    if (pathCtx.isWithin(libraryDirectory, path) ||
        pathCtx.isWithin(sourceDirectory, libraryDirectory)) {
      var relativeFile = pathCtx.relative(path, from: libraryDirectory);
      return pathCtx.split(relativeFile).join('/');
    }
    return null;
  }

  Iterable<CorrectionProducer> _importLibrary(FixKind fixKind, Uri library,
      [String relativeURI]) sync* {
    yield _ImportAbsoluteLibrary(fixKind, library);
    if (relativeURI != null && relativeURI.isNotEmpty) {
      yield _ImportRelativeLibrary(fixKind, relativeURI);
    }
  }

  Iterable<CorrectionProducer> _importLibraryForElement(
      String name,
      List<ElementKind> elementKinds,
      List<TopLevelDeclarationKind> kinds2) sync* {
    // ignore if private
    if (name.startsWith('_')) {
      return;
    }
    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
    var alreadyImportedWithPrefix = <String>{};
    for (var imp in libraryElement.imports) {
      // prepare element
      var libraryElement = imp.importedLibrary;
      var element = getExportedElement(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement) {
        element = (element as PropertyAccessorElement).variable;
      }
      if (!elementKinds.contains(element.kind)) {
        continue;
      }
      // may be apply prefix
      var prefix = imp.prefix;
      if (prefix != null) {
        yield _ImportLibraryPrefix(imp);
        continue;
      }
      // may be update "show" directive
      var combinators = imp.combinators;
      if (combinators.length == 1 && combinators[0] is ShowElementCombinator) {
        var showCombinator = combinators[0] as ShowElementCombinator;
        // prepare new set of names to show
        Set<String> showNames = SplayTreeSet<String>();
        showNames.addAll(showCombinator.shownNames);
        showNames.add(name);
        // prepare library name - unit name or 'dart:name' for SDK library
        var libraryName =
            libraryElement.definingCompilationUnit.source.uri.toString();
        if (libraryElement.isInSdk) {
          libraryName = libraryElement.source.shortName;
        }
        // don't add this library again
        alreadyImportedWithPrefix.add(libraryElement.source.fullName);
        yield _ImportLibraryShow(libraryName, showCombinator, showNames);
      }
    }
    // Find new top-level declarations.
    var declarations = getTopLevelDeclarations(name);
    for (var declaration in declarations) {
      // Check the kind.
      if (!kinds2.contains(declaration.kind)) {
        continue;
      }
      // Check the source.
      if (alreadyImportedWithPrefix.contains(declaration.path)) {
        continue;
      }
      // Check that the import doesn't end with '.template.dart'
      if (declaration.uri.path.endsWith('.template.dart')) {
        continue;
      }
      // Compute the fix kind.
      FixKind fixKind;
      if (declaration.uri.isScheme('dart')) {
        fixKind = DartFixKind.IMPORT_LIBRARY_SDK;
      } else if (_isLibSrcPath(declaration.path)) {
        // Bad: non-API.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT3;
      } else if (declaration.isExported) {
        // Ugly: exports.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT2;
      } else {
        // Good: direct declaration.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT1;
      }
      // Add the fix.
      var relativeURI =
          _getRelativeURIFromLibrary(libraryElement, declaration.path);
      yield* _importLibrary(fixKind, declaration.uri, relativeURI);
    }
  }

  bool _isLibSrcPath(String path) {
    var parts = resourceProvider.pathContext.split(path);
    for (var i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') {
        return true;
      }
    }
    return false;
  }

  /// Return an instance of this class that will add an import of `dart:async`.
  /// Used as a tear-off in `FixProcessor`.
  static ImportLibrary dartAsync() => ImportLibrary(_ImportKind.dartAsync);

  /// Return an instance of this class that will add an import for an extension.
  /// Used as a tear-off in `FixProcessor`.
  static ImportLibrary forExtension() =>
      ImportLibrary(_ImportKind.forExtension);

  /// Return an instance of this class that will add an import for a top-level
  /// function. Used as a tear-off in `FixProcessor`.
  static ImportLibrary forFunction() => ImportLibrary(_ImportKind.forFunction);

  /// Return an instance of this class that will add an import for a top-level
  /// variable. Used as a tear-off in `FixProcessor`.
  static ImportLibrary forTopLevelVariable() =>
      ImportLibrary(_ImportKind.forTopLevelVariable);

  /// Return an instance of this class that will add an import for a type (class
  /// or mixin). Used as a tear-off in `FixProcessor`.
  static ImportLibrary forType() => ImportLibrary(_ImportKind.forType);
}

/// A correction processor that can make one of the possible change computed by
/// the [ImportLibrary] producer.
class _ImportAbsoluteLibrary extends CorrectionProducer {
  final FixKind _fixKind;

  final Uri _library;

  String _uriText;

  _ImportAbsoluteLibrary(this._fixKind, this._library);

  @override
  List<Object> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      _uriText = builder.importLibrary(_library);
    });
  }
}

enum _ImportKind {
  dartAsync,
  forExtension,
  forFunction,
  forTopLevelVariable,
  forType
}

/// A correction processor that can make one of the possible change computed by
/// the [ImportLibrary] producer.
class _ImportLibraryPrefix extends CorrectionProducer {
  final ImportElement _importElement;

  String _libraryName;

  String _prefixName;

  _ImportLibraryPrefix(this._importElement);

  @override
  List<Object> get fixArguments => [_libraryName, _prefixName];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var libraryElement = _importElement.importedLibrary;
    var prefix = _importElement.prefix;
    _libraryName = libraryElement.displayName;
    _prefixName = prefix.displayName;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.startLength(node, 0), '$_prefixName.');
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [ImportLibrary] producer.
class _ImportLibraryShow extends CorrectionProducer {
  final String _libraryName;

  final ShowElementCombinator _showCombinator;

  final Set<String> _showNames;

  _ImportLibraryShow(this._libraryName, this._showCombinator, this._showNames);

  @override
  List<Object> get fixArguments => [_libraryName];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_SHOW;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var newShowCode = 'show ${_showNames.join(', ')}';
    var offset = _showCombinator.offset;
    var length = _showCombinator.end - offset;
    var libraryFile = resolvedResult.libraryElement.source.fullName;
    await builder.addDartFileEdit(libraryFile, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newShowCode);
    });
  }
}

/// A correction processor that can make one of the possible change computed by
/// the [ImportLibrary] producer.
class _ImportRelativeLibrary extends CorrectionProducer {
  final FixKind _fixKind;

  final String _relativeURI;

  _ImportRelativeLibrary(this._fixKind, this._relativeURI);

  @override
  List<Object> get fixArguments => [_relativeURI];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl) {
        builder.importLibraryWithRelativeUri(_relativeURI);
      }
    });
  }
}
