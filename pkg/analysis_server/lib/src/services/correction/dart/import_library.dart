// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/library.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ImportLibrary extends MultiCorrectionProducer {
  final _ImportKind _importKind;

  /// Initialize a newly created instance that will add an import of
  /// `dart:async`.
  ImportLibrary.dartAsync({required super.context})
      : _importKind = _ImportKind.dartAsync;

  /// Initialize a newly created instance that will add an import for an
  /// extension.
  ImportLibrary.forExtension({required super.context})
      : _importKind = _ImportKind.forExtension;

  /// Initialize a newly created instance that will add an import for a member
  /// of an extension.
  ImportLibrary.forExtensionMember({required super.context})
      : _importKind = _ImportKind.forExtensionMember;

  /// Initialize a newly created instance that will add an import for an
  /// extension type.
  ImportLibrary.forExtensionType({required super.context})
      : _importKind = _ImportKind.forExtensionType;

  /// Initialize a newly created instance that will add an import for a
  /// top-level function.
  ImportLibrary.forFunction({required super.context})
      : _importKind = _ImportKind.forFunction;

  /// Initialize a newly created instance that will add an import for a
  /// top-level variable.
  ImportLibrary.forTopLevelVariable({required super.context})
      : _importKind = _ImportKind.forTopLevelVariable;

  /// Initialize a newly created instance that will add an import for a
  /// type-like declaration (class, enum, mixin, typedef), a constructor, a
  /// static member of a declaration, or an enum value.
  ImportLibrary.forType({required super.context})
      : _importKind = _ImportKind.forType;

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    return switch (_importKind) {
      _ImportKind.dartAsync =>
        _importLibrary(DartFixKind.IMPORT_ASYNC, Uri.parse('dart:async')),
      _ImportKind.forExtension => await _producersForExtension(),
      _ImportKind.forExtensionMember => await _producersForExtensionMember(),
      _ImportKind.forExtensionType => await _producersForExtensionType(),
      _ImportKind.forFunction => await _producersForFunction(),
      _ImportKind.forTopLevelVariable => await _producersForTopLevelVariable(),
      _ImportKind.forType => await _producersForType(),
    };
  }

  List<ResolvedCorrectionProducer> _importExtensionInLibrary(
    LibraryElement libraryToImport,
    DartType targetType,
    Name memberName,
  ) {
    // Look to see whether the library at the [uri] is already imported. If it
    // is, then we can check the extension elements without needing to perform
    // additional analysis.
    var foundImport = false;
    var producers = <ResolvedCorrectionProducer>[];
    for (var import in libraryElement.libraryImports) {
      // prepare element
      var importedLibrary = import.importedLibrary;
      if (importedLibrary == null || importedLibrary != libraryToImport) {
        continue;
      }
      foundImport = true;
      var instantiatedExtensions = importedLibrary.exportedExtensions
          .havingMemberWithBaseName(memberName)
          .applicableTo(targetLibrary: libraryElement, targetType: targetType);
      for (var instantiatedExtension in instantiatedExtensions) {
        // If the import has a combinator that needs to be updated, then offer
        // to update it.
        var combinators = import.combinators;
        if (combinators.length == 1) {
          var combinator = combinators[0];
          if (combinator is HideElementCombinator) {
            // TODO(brianwilkerson): Support removing the extension name from a
            //  hide combinator.
          } else if (combinator is ShowElementCombinator) {
            producers.add(_ImportLibraryShow(
              libraryToImport.source.uri.toString(),
              combinator,
              instantiatedExtension.extension.name!,
              context: context,
            ));
          }
        }
      }
    }

    // If the library at the URI is not already imported, we return a correction
    // producer that will either add an import or not based on the result of
    // analyzing the library.
    if (!foundImport) {
      producers.add(_ImportLibraryContainingExtension(
        libraryToImport,
        targetType,
        memberName,
        context: context,
      ));
    }
    return producers;
  }

  /// Returns a list of one or two import corrections.
  ///
  /// If [includeRelativeFix] is `false`, only one correction, with an absolute
  /// import path, is returned. Otherwise, a correction with an absolute import
  /// path and a correction with a relative path are returned. If the
  /// `prefer_relative_imports` lint rule is enabled, the relative path is
  /// returned first.
  List<ResolvedCorrectionProducer> _importLibrary(
    FixKind fixKind,
    Uri library, {
    bool includeRelativeFix = false,
  }) {
    if (!includeRelativeFix) {
      return [_ImportAbsoluteLibrary(fixKind, library, context: context)];
    } else if (getCodeStyleOptions(unitResult.file).useRelativeUris) {
      return [
        _ImportRelativeLibrary(fixKind, library, context: context),
        _ImportAbsoluteLibrary(fixKind, library, context: context),
      ];
    } else {
      return [
        _ImportAbsoluteLibrary(fixKind, library, context: context),
        _ImportRelativeLibrary(fixKind, library, context: context),
      ];
    }
  }

  Future<List<ResolvedCorrectionProducer>> _importLibraryForElement(
    String name,
    List<ElementKind> kinds,
  ) async {
    // Ignore the element if the name is private.
    if (name.startsWith('_')) {
      return const [];
    }
    var producers = <ResolvedCorrectionProducer>[];
    // Maybe there is an existing import, but it is with prefix and we don't use
    // this prefix.
    var alreadyImportedWithPrefix = <LibraryElement>{};
    for (var import in libraryElement.libraryImports) {
      // Prepare the element.
      var libraryElement = import.importedLibrary;
      if (libraryElement == null) {
        continue;
      }
      var element = getExportedElement(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement) {
        element = element.variable2;
        if (element == null) {
          continue;
        }
      }
      if (!kinds.contains(element.kind)) {
        continue;
      }
      // Maybe apply a prefix.
      var prefix = import.prefix?.element;
      if (prefix != null) {
        producers.add(
            _ImportLibraryPrefix(libraryElement, prefix, context: context));
        continue;
      }
      // Maybe update a "show" directive.
      var combinators = import.combinators;
      if (combinators.length == 1) {
        var combinator = combinators[0];
        if (combinator is HideElementCombinator) {
          // TODO(brianwilkerson): Support removing the element name from a
          //  hide combinator.
        } else if (combinator is ShowElementCombinator) {
          // Prepare library name - unit name or 'dart:name' for SDK library.
          var libraryName =
              libraryElement.definingCompilationUnit.source.uri.toString();
          if (libraryElement.isInSdk) {
            libraryName = libraryElement.source.shortName;
          }
          // Don't add this library again.
          alreadyImportedWithPrefix.add(libraryElement);
          producers.add(_ImportLibraryShow(libraryName, combinator, name,
              context: context));
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
      // Check that the import doesn't end with '.template.dart'.
      if (librarySource.uri.path.endsWith('.template.dart')) {
        continue;
      }
      // Compute the fix kind.
      FixKind fixKind;
      if (libraryElement.isInSdk) {
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
      // If both files are in the same package's 'lib' folder, also include a
      // relative import.
      var includeRelativeUri = canBeRelativeImport(
          librarySource.uri, this.libraryElement.librarySource.uri);
      // Add the fix(es).
      producers.addAll(_importLibrary(fixKind, librarySource.uri,
          includeRelativeFix: includeRelativeUri));
    }
    return producers;
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

  Future<List<ResolvedCorrectionProducer>> _producersForExtension() async {
    if (node case SimpleIdentifier(:var name)) {
      return await _importLibraryForElement(
        name,
        const [ElementKind.EXTENSION],
      );
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>>
      _producersForExtensionMember() async {
    String memberName;
    DartType? targetType;
    var node = this.node;
    if (node is SimpleIdentifier) {
      memberName = node.name;
      if (memberName.startsWith('_')) {
        return const [];
      }
      targetType = node.targetType;
    } else if (node is BinaryExpression) {
      memberName = node.operator.lexeme;
      targetType = node.leftOperand.staticType;
    } else {
      return const [];
    }

    if (targetType == null) {
      return const [];
    }

    var dartFixContext = context.dartFixContext;
    if (dartFixContext == null) {
      return const [];
    }

    var name = Name(
        dartFixContext.resolvedResult.libraryElement.source.uri, memberName);
    var producers = <ResolvedCorrectionProducer>[];
    await for (var libraryToImport in librariesWithExtensions(memberName)) {
      producers
          .addAll(_importExtensionInLibrary(libraryToImport, targetType, name));
    }
    return producers;
  }

  Future<List<ResolvedCorrectionProducer>> _producersForExtensionType() async {
    if (node case SimpleIdentifier(:var name)) {
      return await _importLibraryForElement(
        name,
        const [ElementKind.EXTENSION_TYPE],
      );
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>> _producersForFunction() async {
    if (node case SimpleIdentifier(:var name, :var parent)) {
      if (parent is MethodInvocation) {
        if (parent.realTarget != null || parent.methodName != node) {
          return const [];
        }
      }

      return await _importLibraryForElement(name, const [
        ElementKind.FUNCTION,
        ElementKind.TOP_LEVEL_VARIABLE,
      ]);
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>>
      _producersForTopLevelVariable() async {
    var targetNode = node;
    if (targetNode case Annotation(:var name)) {
      if (name.staticElement == null) {
        if (targetNode.arguments != null) {
          return const [];
        }
        targetNode = name;
      }
    }
    if (targetNode case SimpleIdentifier(:var name)) {
      return await _importLibraryForElement(name, const [
        ElementKind.TOP_LEVEL_VARIABLE,
      ]);
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>> _producersForType() async {
    var targetNode = node;
    if (targetNode case Annotation(:var name)) {
      if (name.staticElement == null) {
        if (targetNode.period != null && targetNode.arguments == null) {
          return const [];
        }
        targetNode = name;
      }
    }
    var typeName = targetNode.nameOfType;
    if (typeName != null) {
      return await _importLibraryForElement(typeName, const [
        ElementKind.CLASS,
        ElementKind.ENUM,
        ElementKind.FUNCTION_TYPE_ALIAS,
        ElementKind.MIXIN,
        ElementKind.TYPE_ALIAS,
      ]);
    }
    if (targetNode.mightBeImplicitConstructor) {
      var typeName = (targetNode as SimpleIdentifier).name;
      return await _importLibraryForElement(typeName, const [
        ElementKind.CLASS,
      ]);
    }

    return const [];
  }
}

/// A correction processor that can add an import using an absolute URI.
class _ImportAbsoluteLibrary extends ResolvedCorrectionProducer {
  final FixKind _fixKind;

  final Uri _library;

  String _uriText = '';

  _ImportAbsoluteLibrary(this._fixKind, this._library,
      {required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_uriText];

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
  forExtensionType,
  forFunction,
  forTopLevelVariable,
  forType
}

/// A correction processor that can add an import of a library containing an
/// extension, but which does so only if the extension applies to a given type.
class _ImportLibraryContainingExtension extends ResolvedCorrectionProducer {
  /// The library defining the extension.
  LibraryElement library;

  /// The type of the target that the extension must apply to.
  DartType targetType;

  /// The name of the member that the extension must declare.
  Name memberName;

  /// The URI that is being proposed for the import directive.
  String _uriText = '';

  _ImportLibraryContainingExtension(
    this.library,
    this.targetType,
    this.memberName, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var instantiatedExtensions = library.exportedExtensions
        .havingMemberWithBaseName(memberName)
        .applicableTo(targetLibrary: libraryElement, targetType: targetType);
    if (instantiatedExtensions.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        _uriText = builder.importLibrary(library.source.uri);
      });
    }
  }
}

/// A correction processor that can add a prefix to an identifier defined in a
/// library that is already imported but that is imported with a prefix.
class _ImportLibraryPrefix extends ResolvedCorrectionProducer {
  final LibraryElement _importedLibrary;
  final PrefixElement _importPrefix;

  _ImportLibraryPrefix(
    this._importedLibrary,
    this._importPrefix, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var uriStr = _importedLibrary.source.uri.toString();
    return [uriStr, _prefixName];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  String get _prefixName => _importPrefix.name;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;

    if (targetNode is Annotation) {
      targetNode = targetNode.name;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(targetNode.offset, '$_prefixName.');
    });
  }
}

/// A correction processor that can add a name to the show combinator of an
/// existing import.
class _ImportLibraryShow extends ResolvedCorrectionProducer {
  final String _libraryName;

  final ShowElementCombinator _showCombinator;

  final String _addedName;

  _ImportLibraryShow(
    this._libraryName,
    this._showCombinator,
    this._addedName, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_libraryName];

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
    var libraryFile = unitResult.libraryElement.source.fullName;
    await builder.addDartFileEdit(libraryFile, (builder) {
      builder.addSimpleReplacement(SourceRange(offset, length), newShowCode);
    });
  }
}

/// A correction processor that can add an import using a relative URI.
class _ImportRelativeLibrary extends ResolvedCorrectionProducer {
  final FixKind _fixKind;

  final Uri _library;

  String _uriText = '';

  _ImportRelativeLibrary(
    this._fixKind,
    this._library, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_uriText];

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

extension on AstNode {
  /// Whether this [AstNode] is in a location where an implicit constructor
  /// invocation would be allowed.
  bool get mightBeImplicitConstructor {
    if (this is SimpleIdentifier) {
      var parent = this.parent;
      if (parent is MethodInvocation) {
        return parent.realTarget == null;
      }
    }
    return false;
  }

  /// The "type name" of this node if it might represent a type, and `null`
  /// otherwise.
  String? get nameOfType {
    switch (this) {
      case NamedType(:var importPrefix, :var name2):
        if (parent is ConstructorName && importPrefix != null) {
          return importPrefix.name.lexeme;
        }
        return name2.lexeme;
      case PrefixedIdentifier(:var prefix):
        return prefix.name;
      case SimpleIdentifier(:var name):
        return name;
    }
    return null;
  }
}

extension on SimpleIdentifier {
  /// The type of the object being accessed, if this node might represent an
  /// access to a member of a type, otherwise `null`.
  DartType? get targetType {
    var parent = this.parent;
    if (parent is MethodInvocation && parent.methodName == this) {
      var target = parent.realTarget;
      if (target != null) {
        return target.staticType;
      }
    } else if (parent is PropertyAccess && parent.propertyName == this) {
      return parent.realTarget.staticType;
    } else if (parent is PrefixedIdentifier && parent.identifier == this) {
      return parent.prefix.staticType;
    }
    // If there is no explicit target, then return the type of an implicit
    // `this`.
    DartType? enclosingThisType(AstNode node) {
      var parent = node.parent;
      if (parent is ClassDeclaration) {
        return parent.declaredElement?.thisType;
      } else if (parent is ExtensionDeclaration) {
        return parent.onClause?.extendedType.type;
      } else if (parent is MixinDeclaration) {
        return parent.declaredElement?.thisType;
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
}
