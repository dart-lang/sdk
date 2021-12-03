// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
    final node = this.node;
    if (_importKind == _ImportKind.dartAsync) {
      yield* _importLibrary(DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async'));
    } else if (_importKind == _ImportKind.forExtension) {
      if (node is SimpleIdentifier) {
        var extensionName = node.name;
        yield* _importLibraryForElement(
            extensionName,
            const [ElementKind.EXTENSION],
            const [TopLevelDeclarationKind.extension]);
      }
    } else if (_importKind == _ImportKind.forExtensionMember) {
      /// Return producers that will import extensions that apply to the
      /// [targetType] and that define a member with the given [memberName].
      Iterable<CorrectionProducer> importMatchingExtensions(
          String memberName, DartType? targetType) sync* {
        if (targetType == null) {
          return;
        }
        var definingLibraries =
            extensionCache.membersByName[memberName]?.toList();
        if (definingLibraries != null) {
          for (var definingLibrary in definingLibraries) {
            var libraryPath = definingLibrary.libraryPath;
            var uri = sessionHelper.session.uriConverter.pathToUri(libraryPath);
            if (uri != null) {
              yield* _importExtensionInLibrary(uri, targetType, memberName);
            }
          }
        }
      }

      if (node is SimpleIdentifier) {
        var memberName = node.name;
        if (memberName.startsWith('_')) {
          return;
        }
        yield* importMatchingExtensions(memberName, _targetType(node));
      } else if (node is BinaryExpression) {
        var memberName = node.operator.lexeme;
        yield* importMatchingExtensions(
            memberName, node.leftOperand.staticType);
      }
    } else if (_importKind == _ImportKind.forFunction) {
      if (node is SimpleIdentifier) {
        var parent = node.parent;
        if (parent is MethodInvocation) {
          if (parent.realTarget != null || parent.methodName != node) {
            return;
          }
        }

        var name = node.name;
        yield* _importLibraryForElement(name, const [
          ElementKind.FUNCTION,
          ElementKind.TOP_LEVEL_VARIABLE
        ], const [
          TopLevelDeclarationKind.function,
          TopLevelDeclarationKind.variable
        ]);
      }
    } else if (_importKind == _ImportKind.forTopLevelVariable) {
      var targetNode = node;
      if (targetNode is Annotation) {
        var name = targetNode.name;
        if (name.staticElement == null) {
          if (targetNode.arguments != null) {
            return;
          }
          targetNode = name;
        }
      }
      if (targetNode is SimpleIdentifier) {
        var name = targetNode.name;
        yield* _importLibraryForElement(
            name,
            const [ElementKind.TOP_LEVEL_VARIABLE],
            const [TopLevelDeclarationKind.variable]);
      }
    } else if (_importKind == _ImportKind.forType) {
      var targetNode = node;
      if (targetNode is Annotation) {
        var name = targetNode.name;
        if (name.staticElement == null) {
          if (targetNode.arguments == null) {
            return;
          }
          targetNode = name;
        }
      }
      if (mightBeTypeIdentifier(targetNode)) {
        var typeName = (targetNode is SimpleIdentifier)
            ? targetNode.name
            : (targetNode as PrefixedIdentifier).prefix.name;
        yield* _importLibraryForElement(typeName, const [
          ElementKind.CLASS,
          ElementKind.FUNCTION_TYPE_ALIAS,
          ElementKind.TYPE_ALIAS
        ], const [
          TopLevelDeclarationKind.type
        ]);
      } else if (mightBeImplicitConstructor(targetNode)) {
        var typeName = (targetNode as SimpleIdentifier).name;
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
      if (parent is NamedType) {
        return true;
      }
    }
    return false;
  }

  /// Returns the relative URI from the passed [library] to the given [path].
  ///
  /// If the [path] is not in the [library]'s directory, `null` is returned.
  String? _getRelativeUriFromLibrary(LibraryElement library, String path) {
    var librarySource = library.librarySource;
    var pathContext = resourceProvider.pathContext;
    var libraryDirectory = pathContext.dirname(librarySource.fullName);
    var sourceDirectory = pathContext.dirname(path);
    if (pathContext.isWithin(libraryDirectory, path) ||
        pathContext.isWithin(sourceDirectory, libraryDirectory)) {
      var relativeFile = pathContext.relative(path, from: libraryDirectory);
      return pathContext.split(relativeFile).join('/');
    }
    return null;
  }

  Iterable<CorrectionProducer> _importExtensionInLibrary(
      Uri uri, DartType targetType, String memberName) sync* {
    // Look to see whether the library at the [uri] is already imported. If it
    // is, then we can check the extension elements without needing to perform
    // additional analysis.
    var foundImport = false;
    for (var imp in libraryElement.imports) {
      // prepare element
      var importedLibrary = imp.importedLibrary;
      if (importedLibrary == null || importedLibrary.source.uri != uri) {
        continue;
      }
      foundImport = true;
      for (var extension in importedLibrary.matchingExtensionsWithMember(
          libraryElement, targetType, memberName)) {
        // If the import has a combinator that needs to be updated, then offer
        // to update it.
        var combinators = imp.combinators;
        if (combinators.length == 1) {
          var combinator = combinators[0];
          if (combinator is HideElementCombinator) {
            // TODO(brianwilkerson) Support removing the extension name from a
            //  hide combinator.
          } else if (combinator is ShowElementCombinator) {
            yield _ImportLibraryShow(
                uri.toString(), combinator, extension.name!);
          }
        }
      }
    }

    // If the library at the [uri] is not already imported, we return a
    // correction producer that will either add an import or not based on the
    // result of analyzing the library.
    if (!foundImport) {
      yield _ImportLibraryContainingExtension(uri, targetType, memberName);
    }
  }

  /// Returns a list of one or two import corrections.
  ///
  /// If [relativeUri] is `null`, only one correction, with an absolute import
  /// path, is returned. Otherwise, a correction with an absolute import path
  /// and a correction with a relative path are returned. If the
  /// `prefer_relative_imports` lint rule is enabled, the relative path is
  /// returned first.
  Iterable<CorrectionProducer> _importLibrary(FixKind fixKind, Uri library,
      [String? relativeUri]) {
    if (relativeUri == null || relativeUri.isEmpty) {
      return [_ImportAbsoluteLibrary(fixKind, library)];
    }
    if (isLintEnabled(LintNames.prefer_relative_imports)) {
      return [
        _ImportRelativeLibrary(fixKind, relativeUri),
        _ImportAbsoluteLibrary(fixKind, library),
      ];
    } else {
      return [
        _ImportAbsoluteLibrary(fixKind, library),
        _ImportRelativeLibrary(fixKind, relativeUri),
      ];
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
      if (libraryElement == null) {
        continue;
      }
      var element = getExportedElement(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement) {
        element = element.variable;
      }
      if (!elementKinds.contains(element.kind)) {
        continue;
      }
      // may be apply prefix
      var prefix = imp.prefix;
      if (prefix != null) {
        yield _ImportLibraryPrefix(libraryElement, prefix);
        continue;
      }
      // may be update "show" directive
      var combinators = imp.combinators;
      if (combinators.length == 1) {
        var combinator = combinators[0];
        if (combinator is HideElementCombinator) {
          // TODO(brianwilkerson) Support removing the element name from a
          //  hide combinator.
        } else if (combinator is ShowElementCombinator) {
          // prepare library name - unit name or 'dart:name' for SDK library
          var libraryName =
              libraryElement.definingCompilationUnit.source.uri.toString();
          if (libraryElement.isInSdk) {
            libraryName = libraryElement.source.shortName;
          }
          // don't add this library again
          alreadyImportedWithPrefix.add(libraryElement.source.fullName);
          yield _ImportLibraryShow(libraryName, combinator, name);
        }
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
      var relativeUri =
          _getRelativeUriFromLibrary(libraryElement, declaration.path);
      yield* _importLibrary(fixKind, declaration.uri, relativeUri);
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

  /// If the [node] might represent an access to a member of a type, return the
  /// type of the object being accessed, otherwise return `null`.
  DartType? _targetType(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is MethodInvocation && parent.methodName == node) {
      var target = parent.realTarget;
      if (target != null) {
        return target.staticType;
      }
    } else if (parent is PropertyAccess && parent.propertyName == node) {
      return parent.realTarget.staticType;
    } else if (parent is PrefixedIdentifier && parent.identifier == node) {
      return parent.prefix.staticType;
    }
    // If there is no explicit target, then return the type of an implicit
    // `this`.
    DartType? enclosingThisType(AstNode node) {
      var parent = node.parent;
      if (parent is ClassOrMixinDeclaration) {
        return parent.declaredElement?.thisType;
      } else if (parent is ExtensionDeclaration) {
        return parent.extendedType.type;
      }
    }

    while (parent != null) {
      if (parent is MethodDeclaration) {
        if (!parent.isStatic) {
          return enclosingThisType(parent);
        }
        return null;
      } else if (parent is FieldDeclaration) {
        if (!parent.isStatic) {
          return enclosingThisType(parent);
        }
        return null;
      }
      parent = parent.parent;
    }
  }

  /// Return an instance of this class that will add an import of `dart:async`.
  /// Used as a tear-off in `FixProcessor`.
  static ImportLibrary dartAsync() => ImportLibrary(_ImportKind.dartAsync);

  /// Return an instance of this class that will add an import for an extension.
  /// Used as a tear-off in `FixProcessor`.
  static ImportLibrary forExtension() =>
      ImportLibrary(_ImportKind.forExtension);

  static ImportLibrary forExtensionMember() =>
      ImportLibrary(_ImportKind.forExtensionMember);

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

/// A correction processor that can add an import using an absolute URI.
class _ImportAbsoluteLibrary extends CorrectionProducer {
  final FixKind _fixKind;

  final Uri _library;

  String _uriText = '';

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
  forExtensionMember,
  forFunction,
  forTopLevelVariable,
  forType
}

/// A correction processor that can add an import of a library containing an
/// extension, but which does so only if the extension applies to a given type.
class _ImportLibraryContainingExtension extends CorrectionProducer {
  /// The URI of the library defining the extension.
  Uri uri;

  /// The type of the target that the extension must apply to.
  DartType targetType;

  /// The name of the member that the extension must declare.
  String memberName;

  /// The URI that is being proposed for the import directive.
  String _uriText = '';

  _ImportLibraryContainingExtension(this.uri, this.targetType, this.memberName);

  @override
  List<Object> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var result = await sessionHelper.session.getLibraryByUri(uri.toString());
    if (result is LibraryElementResult) {
      var library = result.element;
      if (library
          .matchingExtensionsWithMember(libraryElement, targetType, memberName)
          .isNotEmpty) {
        await builder.addDartFileEdit(file, (builder) {
          _uriText = builder.importLibrary(uri);
        });
      }
    }
  }
}

/// A correction processor that can add a prefix to an identifier defined in a
/// library that is already imported but that is imported with a prefix.
class _ImportLibraryPrefix extends CorrectionProducer {
  final LibraryElement _importedLibrary;
  final PrefixElement _importPrefix;

  String _libraryName = '';

  String _prefixName = '';

  _ImportLibraryPrefix(this._importedLibrary, this._importPrefix);

  @override
  List<Object> get fixArguments => [_libraryName, _prefixName];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    _libraryName = _importedLibrary.displayName;
    _prefixName = _importPrefix.displayName;
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.startLength(node, 0), '$_prefixName.');
    });
  }
}

/// A correction processor that can add a name to the show combinator of an
/// existing import.
class _ImportLibraryShow extends CorrectionProducer {
  final String _libraryName;

  final ShowElementCombinator _showCombinator;

  final String _addedName;

  _ImportLibraryShow(this._libraryName, this._showCombinator, this._addedName);

  @override
  List<Object> get fixArguments => [_libraryName];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_SHOW;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Set<String> showNames = SplayTreeSet<String>();
    showNames.addAll(_showCombinator.shownNames);
    showNames.add(_addedName);
    var newShowCode = 'show ${showNames.join(', ')}';
    var offset = _showCombinator.offset;
    var length = _showCombinator.end - offset;
    var libraryFile = resolvedResult.libraryElement.source.fullName;
    await builder.addDartFileEdit(libraryFile, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newShowCode);
    });
  }
}

/// A correction processor that can add an import using a relative URI.
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
