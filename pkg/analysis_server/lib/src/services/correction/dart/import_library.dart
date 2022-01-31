// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/library.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ImportLibrary extends MultiCorrectionProducer {
  final _ImportKind _importKind;

  ImportLibrary(this._importKind);

  @override
  Stream<CorrectionProducer> get producers async* {
    final node = this.node;
    if (_importKind == _ImportKind.dartAsync) {
      yield* _importLibrary(DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async'));
    } else if (_importKind == _ImportKind.forExtension) {
      if (node is SimpleIdentifier) {
        var extensionName = node.name;
        yield* _importLibraryForElement(extensionName, const [
          ElementKind.EXTENSION,
        ]);
      }
    } else if (_importKind == _ImportKind.forExtensionMember) {
      /// Return producers that will import extensions that apply to the
      /// [targetType] and that define a member with the given [memberName].
      Stream<CorrectionProducer> importMatchingExtensions(
          String memberName, DartType? targetType) async* {
        if (targetType == null) {
          return;
        }
        await for (var libraryToImport in librariesWithExtensions(memberName)) {
          yield* _importExtensionInLibrary(
              libraryToImport, targetType, memberName);
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
          ElementKind.TOP_LEVEL_VARIABLE,
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
        yield* _importLibraryForElement(name, const [
          ElementKind.TOP_LEVEL_VARIABLE,
        ]);
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
          ElementKind.ENUM,
          ElementKind.FUNCTION_TYPE_ALIAS,
          ElementKind.TYPE_ALIAS,
        ]);
      } else if (mightBeImplicitConstructor(targetNode)) {
        var typeName = (targetNode as SimpleIdentifier).name;
        yield* _importLibraryForElement(typeName, const [
          ElementKind.CLASS,
        ]);
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

  Stream<CorrectionProducer> _importExtensionInLibrary(
    LibraryElement libraryToImport,
    DartType targetType,
    String memberName,
  ) async* {
    // Look to see whether the library at the [uri] is already imported. If it
    // is, then we can check the extension elements without needing to perform
    // additional analysis.
    var foundImport = false;
    for (var imp in libraryElement.imports) {
      // prepare element
      var importedLibrary = imp.importedLibrary;
      if (importedLibrary == null || importedLibrary != libraryToImport) {
        continue;
      }
      foundImport = true;
      var instantiatedExtensions = importedLibrary.exportedExtensions
          .hasMemberWithBaseName(memberName)
          .applicableTo(
            targetLibrary: libraryElement,
            targetType: targetType,
          );
      for (var instantiatedExtension in instantiatedExtensions) {
        // If the import has a combinator that needs to be updated, then offer
        // to update it.
        var combinators = imp.combinators;
        if (combinators.length == 1) {
          var combinator = combinators[0];
          if (combinator is HideElementCombinator) {
            // TODO(brianwilkerson) Support removing the extension name from a
            //  hide combinator.
          } else if (combinator is ShowElementCombinator) {
            yield _ImportLibraryShow(libraryToImport.source.uri.toString(),
                combinator, instantiatedExtension.extension.name!);
          }
        }
      }
    }

    // If the library at the [uri] is not already imported, we return a
    // correction producer that will either add an import or not based on the
    // result of analyzing the library.
    if (!foundImport) {
      yield _ImportLibraryContainingExtension(
          libraryToImport, targetType, memberName);
    }
  }

  /// Returns a list of one or two import corrections.
  ///
  /// If [includeRelativeFix] is `false`, only one correction, with an absolute
  /// import path, is returned. Otherwise, a correction with an absolute import
  /// path and a correction with a relative path are returned. If the
  /// `prefer_relative_imports` lint rule is enabled, the relative path is
  /// returned first.
  Stream<CorrectionProducer> _importLibrary(
    FixKind fixKind,
    Uri library, {
    bool includeRelativeFix = false,
  }) {
    if (!includeRelativeFix) {
      return Stream.fromIterable([
        _ImportAbsoluteLibrary(fixKind, library),
      ]);
    }
    if (isLintEnabled(LintNames.prefer_relative_imports)) {
      return Stream.fromIterable([
        _ImportRelativeLibrary(fixKind, library),
        _ImportAbsoluteLibrary(fixKind, library),
      ]);
    } else {
      return Stream.fromIterable([
        _ImportAbsoluteLibrary(fixKind, library),
        _ImportRelativeLibrary(fixKind, library),
      ]);
    }
  }

  Stream<CorrectionProducer> _importLibraryForElement(
    String name,
    List<ElementKind> kinds,
  ) async* {
    // ignore if private
    if (name.startsWith('_')) {
      return;
    }
    // may be there is an existing import,
    // but it is with prefix and we don't use this prefix
    var alreadyImportedWithPrefix = <LibraryElement>{};
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
      if (!kinds.contains(element.kind)) {
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
          alreadyImportedWithPrefix.add(libraryElement);
          yield _ImportLibraryShow(libraryName, combinator, name);
        }
      }
    }
    // Find new top-level declarations.
    var librariesWithElements = await getTopLevelDeclarations(name);
    for (var libraryEntry in librariesWithElements.entries) {
      var libraryElement = libraryEntry.key;
      var declaration = libraryEntry.value;
      var librarySource = libraryElement.source;
      // Check the kind.
      if (!kinds.contains(declaration.kind)) {
        continue;
      }
      // Check the source.
      if (alreadyImportedWithPrefix.contains(libraryElement)) {
        continue;
      }
      // Check that the import doesn't end with '.template.dart'
      if (librarySource.uri.path.endsWith('.template.dart')) {
        continue;
      }
      // Compute the fix kind.
      FixKind fixKind;
      if (librarySource.uri.isScheme('dart')) {
        fixKind = DartFixKind.IMPORT_LIBRARY_SDK;
      } else if (_isLibSrcPath(librarySource.fullName)) {
        // Bad: non-API.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT3;
      } else if (declaration.library != libraryElement) {
        // Ugly: exports.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT2;
      } else {
        // Good: direct declaration.
        fixKind = DartFixKind.IMPORT_LIBRARY_PROJECT1;
      }
      // If both files are in the same package's lib folder, also include a
      // relative import.
      var includeRelativeUri = canBeRelativeImport(
          librarySource.uri, this.libraryElement.librarySource.uri);
      // Add the fix(es).
      yield* _importLibrary(fixKind, librarySource.uri,
          includeRelativeFix: includeRelativeUri);
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
      } else {
        return null;
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

    return null;
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
      if (builder is DartFileEditBuilderImpl) {
        _uriText = builder.importLibraryWithAbsoluteUri(_library);
      }
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
  /// The library defining the extension.
  LibraryElement library;

  /// The type of the target that the extension must apply to.
  DartType targetType;

  /// The name of the member that the extension must declare.
  String memberName;

  /// The URI that is being proposed for the import directive.
  String _uriText = '';

  _ImportLibraryContainingExtension(
    this.library,
    this.targetType,
    this.memberName,
  );

  @override
  List<Object> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var instantiatedExtensions = library.exportedExtensions
        .hasMemberWithBaseName(memberName)
        .applicableTo(
          targetLibrary: libraryElement,
          targetType: targetType,
        );
    if (instantiatedExtensions.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        _uriText = builder.importLibrary(library.source.uri);
      });
    }
  }
}

/// A correction processor that can add a prefix to an identifier defined in a
/// library that is already imported but that is imported with a prefix.
class _ImportLibraryPrefix extends CorrectionProducer {
  final LibraryElement _importedLibrary;
  final PrefixElement _importPrefix;

  _ImportLibraryPrefix(this._importedLibrary, this._importPrefix);

  @override
  List<Object> get fixArguments {
    var uriStr = _importedLibrary.source.uri.toString();
    return [uriStr, _prefixName];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  String get _prefixName => _importPrefix.name;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(node.offset, '$_prefixName.');
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

  final Uri _library;

  String _uriText = '';

  _ImportRelativeLibrary(this._fixKind, this._library);

  @override
  List<Object> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl) {
        _uriText = builder.importLibraryWithRelativeUri(_library);
      }
    });
  }
}
