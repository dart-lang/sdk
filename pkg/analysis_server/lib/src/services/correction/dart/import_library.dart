// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/src/utilities/library.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ImportLibrary extends MultiCorrectionProducer {
  final _ImportKind _importKind;

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
      _ImportKind.forExtension => await _producersForExtension(),
      _ImportKind.forExtensionMember => await _producersForExtensionMember(),
      _ImportKind.forExtensionType => await _producersForExtensionType(),
      _ImportKind.forFunction => await _producersForFunction(),
      _ImportKind.forTopLevelVariable => await _producersForTopLevelVariable(),
      _ImportKind.forType => await _producersForType(),
    };
  }

  List<ResolvedCorrectionProducer> _importExtensionInLibrary(
    LibraryElement2 libraryToImport,
    DartType targetType,
    Name memberName,
  ) {
    // Look to see whether the library at the [uri] is already imported. If it
    // is, then we can check the extension elements without needing to perform
    // additional analysis.
    var foundImport = false;
    var producers = <ResolvedCorrectionProducer>[];
    for (var import in unitResult.libraryFragment.libraryImports2) {
      // prepare element
      var importedLibrary = import.importedLibrary2;
      if (importedLibrary == null || importedLibrary != libraryToImport) {
        continue;
      }
      foundImport = true;
      var instantiatedExtensions = importedLibrary.exportedExtensions
          .havingMemberWithBaseName(memberName)
          .applicableTo(targetLibrary: libraryElement2, targetType: targetType);
      for (var instantiatedExtension in instantiatedExtensions) {
        // If the import has a combinator that needs to be updated, then offer
        // to update it.
        var combinators = import.combinators;
        if (combinators.length == 1) {
          var combinator = combinators[0];
          if (combinator is HideElementCombinator) {
            producers.add(
              _ImportLibraryCombinator(
                libraryToImport.uri.toString(),
                combinator,
                instantiatedExtension.extension.name3!,
                context: context,
              ),
            );
          } else if (combinator is ShowElementCombinator) {
            producers.add(
              _ImportLibraryCombinator(
                libraryToImport.uri.toString(),
                combinator,
                instantiatedExtension.extension.name3!,
                context: context,
              ),
            );
          }
        }
      }
    }

    // If the library at the URI is not already imported, we return a correction
    // producer that will either add an import or not based on the result of
    // analyzing the library.
    if (!foundImport) {
      producers.add(
        _ImportLibraryContainingExtension(
          libraryToImport,
          targetType,
          memberName,
          context: context,
        ),
      );
    }
    return producers;
  }

  /// Returns a list of one or two import corrections.
  ///
  /// If [includeRelativeFix] is `false`, only one correction, with an absolute
  /// import path, is returned. Otherwise, a correction with an absolute import
  /// path and a correction with a relative path are returned.
  /// If the `always_use_package_imports` lint rule is active then only the
  /// package import is returned.
  /// If `prefer_relative_imports` is active then the relative path is returned.
  /// Otherwise, both are returned in the order: absolute, relative.
  List<ResolvedCorrectionProducer> _importLibrary(
    FixKind fixKind,
    FixKind fixKindShow,
    Uri library,
    String name, {
    String? prefix,
    bool includeRelativeFix = false,
  }) {
    if (!includeRelativeFix) {
      return [
        _ImportAbsoluteLibrary(fixKind, library, prefix, context: context),
        _ImportAbsoluteLibrary(
          fixKindShow,
          library,
          prefix,
          show: name,
          context: context,
        ),
      ];
    }
    var codeStyleOptions = getCodeStyleOptions(unitResult.file);
    if (codeStyleOptions.usePackageUris) {
      return [
        _ImportAbsoluteLibrary(fixKind, library, prefix, context: context),
        _ImportAbsoluteLibrary(
          fixKindShow,
          library,
          prefix,
          show: name,
          context: context,
        ),
      ];
    }
    if (codeStyleOptions.useRelativeUris) {
      return [
        _ImportRelativeLibrary(fixKind, library, prefix, context: context),
        _ImportRelativeLibrary(
          fixKindShow,
          library,
          prefix,
          show: name,
          context: context,
        ),
      ];
    }
    return [
      _ImportAbsoluteLibrary(fixKind, library, prefix, context: context),
      _ImportAbsoluteLibrary(
        fixKindShow,
        library,
        prefix,
        show: name,
        context: context,
      ),
      _ImportRelativeLibrary(fixKind, library, prefix, context: context),
      _ImportRelativeLibrary(
        fixKindShow,
        library,
        prefix,
        show: name,
        context: context,
      ),
    ];
  }

  Future<List<ResolvedCorrectionProducer>> _importLibraryForElement(
    String name,
    List<ElementKind> kinds, {
    String? prefix,
  }) async {
    // Ignore the element if the name is private.
    if (name.startsWith('_')) {
      return const [];
    }
    var producers = <ResolvedCorrectionProducer>[];
    // Maybe there is an existing import, but it is with prefix and we don't use
    // this prefix.
    var alreadyImportedWithPrefix = <LibraryElement2>{};
    for (var import in unitResult.libraryFragment.libraryImports2) {
      // Prepare the element.
      var libraryElement = import.importedLibrary2;
      if (libraryElement == null) {
        continue;
      }
      var element = getExportedElement2(libraryElement, name);
      if (element == null) {
        continue;
      }
      if (element is PropertyAccessorElement2) {
        element = element.variable3;
        if (element == null) {
          continue;
        }
      }
      if (!kinds.contains(element.kind)) {
        continue;
      }
      _ImportLibraryCombinator? combinatorProducer;
      var importPrefix = import.prefix2?.element;
      // Maybe update a "show"/"hide" directive.
      var combinators = import.combinators;
      if (combinators.length == 1) {
        // Prepare library name - unit name or 'dart:name' for SDK library.
        var libraryName = libraryElement.uri.toString();
        var combinator = combinators.first;
        if (combinator is HideElementCombinator) {
          // Don't add this library again.
          alreadyImportedWithPrefix.add(libraryElement);
          combinatorProducer = _ImportLibraryCombinator(
            libraryName,
            combinator,
            name,
            removePrefix: importPrefix == null,
            context: context,
          );
        } else if (combinator is ShowElementCombinator) {
          // Don't add this library again.
          alreadyImportedWithPrefix.add(libraryElement);
          combinatorProducer = _ImportLibraryCombinator(
            libraryName,
            combinator,
            name,
            removePrefix: importPrefix == null,
            context: context,
          );
        }
      }
      // Maybe apply a prefix.
      if (importPrefix != null) {
        producers.add(
          _ImportLibraryPrefix(
            libraryElement,
            importPrefix,
            combinatorProducer,
            prefix,
            context: context,
          ),
        );
        continue;
      } else if (combinatorProducer != null) {
        producers.add(combinatorProducer);
      }
    }
    // Find new top-level declarations.
    var librariesWithElements = await getTopLevelDeclarations2(name);
    for (var libraryEntry in librariesWithElements.entries) {
      var libraryElement = libraryEntry.key;
      var declaration = libraryEntry.value;
      var librarySource = libraryElement.firstFragment.source;
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
      FixKind fixKindShow;
      if (libraryElement.isInSdk) {
        fixKind =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_SDK
                : DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED;
        fixKindShow =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_SDK_SHOW
                : DartFixKind.IMPORT_LIBRARY_SDK_PREFIXED_SHOW;
      } else if (_isLibSrcPath(librarySource.fullName)) {
        // Bad: non-API.
        fixKind =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT3
                : DartFixKind.IMPORT_LIBRARY_PROJECT3_PREFIXED;
        fixKindShow =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT3_SHOW
                : DartFixKind.IMPORT_LIBRARY_PROJECT3_PREFIXED_SHOW;
      } else if (declaration.library2 != libraryElement) {
        // Ugly: exports.
        fixKind =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT2
                : DartFixKind.IMPORT_LIBRARY_PROJECT2_PREFIXED;
        fixKindShow =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT2_SHOW
                : DartFixKind.IMPORT_LIBRARY_PROJECT2_PREFIXED_SHOW;
      } else {
        // Good: direct declaration.
        fixKind =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT1
                : DartFixKind.IMPORT_LIBRARY_PROJECT1_PREFIXED;
        fixKindShow =
            prefix.isEmptyOrNull
                ? DartFixKind.IMPORT_LIBRARY_PROJECT1_SHOW
                : DartFixKind.IMPORT_LIBRARY_PROJECT1_PREFIXED_SHOW;
      }
      // If both files are in the same package's 'lib' folder, also include a
      // relative import.
      var includeRelativeUri = canBeRelativeImport(
        librarySource.uri,
        libraryElement2.uri,
      );
      // Add the fix(es).
      producers.addAll(
        _importLibrary(
          fixKind,
          fixKindShow,
          librarySource.uri,
          name,
          prefix: prefix,
          includeRelativeFix: includeRelativeUri,
        ),
      );
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
    if (node case SimpleIdentifier(:var name, :var parent)) {
      return await _producersForMethodInvocation(name, parent, const [
        ElementKind.EXTENSION,
      ]);
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
      targetType = node.targetType(unitResult.typeSystem);
    } else if (node is BinaryExpression) {
      memberName = node.operator.lexeme;
      targetType = node.leftOperand.staticType;
    } else if (node is PrefixExpression) {
      memberName = node.operator.lexeme;
      if (node.operator.type == TokenType.MINUS ||
          node.operator.type == TokenType.TILDE) {
        targetType = node.operand.staticType;
      }
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

    var name = Name.forLibrary(
      dartFixContext.unitResult.libraryElement2,
      memberName,
    );
    var producers = <ResolvedCorrectionProducer>[];
    await for (var libraryToImport in librariesWithExtensions2(memberName)) {
      producers.addAll(
        _importExtensionInLibrary(libraryToImport, targetType, name),
      );
    }
    return producers;
  }

  Future<List<ResolvedCorrectionProducer>> _producersForExtensionType() async {
    if (node case SimpleIdentifier(:var name)) {
      return await _importLibraryForElement(name, const [
        ElementKind.EXTENSION_TYPE,
      ]);
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>> _producersForFunction() async {
    if (node case SimpleIdentifier(:var name, :var parent)) {
      return await _producersForMethodInvocation(name, parent, const [
        ElementKind.FUNCTION,
        ElementKind.TOP_LEVEL_VARIABLE,
      ]);
    }

    return const [];
  }

  /// Returns a list of import corrections considering the [name] and [parent].
  ///
  /// If the [parent] is a [MethodInvocation] it can be a method invocation or
  /// a prefixed identifier. So we calculate both import options for this case.
  ///
  /// If we have unresolved code like `foo.bar()` then we have two options:
  /// - Import of some library, prefixed with `foo`, that contains a top-level
  /// function called bar;
  /// - Import of some library that contains a top-level propriety or class
  /// called `foo` that has a method called `bar` (has to be static for a
  /// _class_ with that name).
  Future<List<ResolvedCorrectionProducer>> _producersForMethodInvocation(
    String name,
    AstNode? parent,
    List<ElementKind> kinds,
  ) async {
    String? prefix;
    var producers = <ResolvedCorrectionProducer>[];
    if (parent case MethodInvocation(:var target?, :var function)) {
      // Getting the import library for elements with [name].
      producers.addAll(await _importLibraryForElement(name, kinds));

      // Set the prefix and (maybe swap) name and get the other import library
      // option - with prefix!.
      if (target == node) {
        prefix = name;
        if (function case SimpleIdentifier(name: var realName)) {
          name = realName;
        }
      } else if (target case SimpleIdentifier(:var name)) {
        prefix = name;
      }
    } else if (parent case PrefixedIdentifier(
      prefix: var parentPrefix,
      :var identifier,
    )) {
      producers.addAll(await _importLibraryForElement(name, kinds));

      // Set the prefix and (maybe swap) name and get the other import library
      // option - with prefix!.
      if (identifier != node) {
        prefix = name;
        name = identifier.name;
      } else {
        prefix = parentPrefix.name;
      }
    }

    producers.addAll(
      await _importLibraryForElement(name, kinds, prefix: prefix),
    );
    return producers;
  }

  Future<List<ResolvedCorrectionProducer>>
  _producersForTopLevelVariable() async {
    String? prefix;
    var targetNode = node;
    if (targetNode.parent case PrefixedIdentifier prefixed
        when prefixed.prefix == node) {
      targetNode = prefixed.identifier;
      prefix = prefixed.prefix.name;
    }
    if (targetNode case Annotation(:var name)) {
      if (name.element == null) {
        if (targetNode.arguments != null) {
          return const [];
        }
        targetNode = name;
      }
    }
    if (targetNode case SimpleIdentifier(:var name)) {
      return await _importLibraryForElement(name, const [
        ElementKind.TOP_LEVEL_VARIABLE,
      ], prefix: prefix);
    }

    return const [];
  }

  Future<List<ResolvedCorrectionProducer>> _producersForType() async {
    const kinds = [
      ElementKind.CLASS,
      ElementKind.ENUM,
      ElementKind.EXTENSION_TYPE,
      ElementKind.FUNCTION_TYPE_ALIAS,
      ElementKind.MIXIN,
      ElementKind.TYPE_ALIAS,
    ];
    if (node case SimpleIdentifier(:var name, :var parent)) {
      return await _producersForMethodInvocation(name, parent, kinds);
    }
    var targetNode = node;
    if (targetNode case Annotation(:var name)) {
      if (name.element == null) {
        if (targetNode.period != null && targetNode.arguments == null) {
          return const [];
        }
        targetNode = name;
      }
    }
    String? prefix;
    if (node case NamedType(:var importPrefix, :var parent)
        // Makes sure that
        // [ImportLibraryProject1Test.test_withClass_instanceCreation_const_namedConstructor]
        // and
        // [ImportLibraryProject1Test.test_withClass_instanceCreation_new_namedConstructor]
        // are not broken.
        when parent is! ConstructorName) {
      prefix = importPrefix?.name.lexeme;
    }
    var typeName = targetNode.nameOfType;
    if (typeName != null) {
      return await _importLibraryForElement(typeName, kinds, prefix: prefix);
    }
    if (targetNode.mightBeImplicitConstructor) {
      var typeName = (targetNode as SimpleIdentifier).name;
      return await _importLibraryForElement(typeName, const [
        ElementKind.CLASS,
      ], prefix: prefix);
    }

    return const [];
  }
}

/// A correction processor that can add an import using an absolute URI.
class _ImportAbsoluteLibrary extends ResolvedCorrectionProducer {
  final FixKind _fixKind;
  final String? _prefix;
  final Uri _library;
  final String? _show;

  String _uriText = '';

  _ImportAbsoluteLibrary(
    this._fixKind,
    this._library,
    this._prefix, {
    String? show,
    required super.context,
  }) : _show = show;

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [
    _uriText,
    if (_prefix != null && _prefix.isNotEmpty) _prefix,
  ];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl) {
        _uriText = builder.importLibraryWithAbsoluteUri(
          _library,
          prefix: _prefix,
          shownName: _show,
          useShow: _show != null,
        );
      }
    });
  }
}

enum _ImportKind {
  forExtension,
  forExtensionMember,
  forExtensionType,
  forFunction,
  forTopLevelVariable,
  forType,
}

/// A correction processor that can add/remove a name to/from the show/hide
/// combinator of an existing import.
class _ImportLibraryCombinator extends ResolvedCorrectionProducer {
  final String _libraryName;

  final NamespaceCombinator _combinator;

  final String _updatedName;

  final bool _removePrefix;

  _ImportLibraryCombinator(
    this._libraryName,
    this._combinator,
    this._updatedName, {
    bool removePrefix = false,
    required super.context,
  }) : _removePrefix = removePrefix;

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [_libraryName];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_COMBINATOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Set<String> finalNames = SplayTreeSet<String>();
    int offset;
    int length;
    Keyword keyword;
    if (_combinator case ShowElementCombinator(shownNames: var names)) {
      finalNames.addAll(names);
      offset = _combinator.offset;
      length = _combinator.end - offset;
      finalNames.add(_updatedName);
      keyword = Keyword.SHOW;
    } else if (_combinator case HideElementCombinator(hiddenNames: var names)) {
      finalNames.addAll(names);
      offset = _combinator.offset;
      length = _combinator.end - offset;
      finalNames.remove(_updatedName);
      keyword = Keyword.HIDE;
    } else {
      return;
    }
    var newCombinatorCode = '';
    if (finalNames.isNotEmpty) {
      newCombinatorCode = ' ${keyword.lexeme} ${finalNames.join(', ')}';
    }
    var libraryPath = unitResult.libraryElement2.firstFragment.source.fullName;
    await builder.addDartFileEdit(libraryPath, (builder) {
      builder.addSimpleReplacement(
        SourceRange(offset - 1, length + 1),
        newCombinatorCode,
      );
      if (_removePrefix) {
        AstNode? prefix;
        if (node case NamedType(:var importPrefix?)) {
          prefix = importPrefix;
        } else if (node case PrefixedIdentifier(:var prefix)) {
          prefix = prefix;
        } else {
          return;
        }
        if (prefix == null) {
          return;
        }
        builder.addDeletion(range.node(prefix));
      }
    });
  }
}

/// A correction processor that can add an import of a library containing an
/// extension, but which does so only if the extension applies to a given type.
class _ImportLibraryContainingExtension extends ResolvedCorrectionProducer {
  /// The library defining the extension.
  LibraryElement2 library;

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
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [_uriText];

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PROJECT1;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var instantiatedExtensions = library.exportedExtensions
        .havingMemberWithBaseName(memberName)
        .applicableTo(targetLibrary: libraryElement2, targetType: targetType);
    if (instantiatedExtensions.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        _uriText = builder.importLibrary(library.uri);
      });
    }
  }
}

/// A correction processor that can add a prefix to an identifier defined in a
/// library that is already imported but that is imported with a prefix.
class _ImportLibraryPrefix extends ResolvedCorrectionProducer {
  final LibraryElement2 _importedLibrary;
  final PrefixElement2 _importPrefix;
  final String? _nodePrefix;
  final _ImportLibraryCombinator? _editCombinator;

  _ImportLibraryPrefix(
    this._importedLibrary,
    this._importPrefix,
    this._editCombinator,
    this._nodePrefix, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments {
    var uriStr = _importedLibrary.uri.toString();
    return [uriStr, _prefixName];
  }

  @override
  FixKind get fixKind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  String get _prefixName => _importPrefix.name3!;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var targetNode = node;

    if (targetNode is Annotation) {
      targetNode = targetNode.name;
    }

    await _editCombinator?.compute(builder);

    if (_nodePrefix == null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(targetNode.offset, '$_prefixName.');
      });
    } else if (_nodePrefix != _prefixName) {
      AstNode prefix;
      if (targetNode case NamedType(:var importPrefix?)) {
        prefix = importPrefix;
      } else if (targetNode case PrefixedIdentifier(prefix: var prefixNode)) {
        prefix = prefixNode;
      } else {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(prefix), '$_prefixName.');
      });
    }
  }
}

/// A correction processor that can add an import using a relative URI.
class _ImportRelativeLibrary extends ResolvedCorrectionProducer {
  final FixKind _fixKind;
  final String? _prefix;
  final Uri _library;
  final String? _show;

  String _uriText = '';

  _ImportRelativeLibrary(
    this._fixKind,
    this._library,
    this._prefix, {
    String? show,
    required super.context,
  }) : _show = show;

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  @override
  List<String> get fixArguments => [
    _uriText,
    if (_prefix != null && _prefix.isNotEmpty) _prefix,
  ];

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl) {
        _uriText = builder.importLibraryWithRelativeUri(
          _library,
          prefix: _prefix,
          shownName: _show,
          useShow: _show != null,
        );
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
  DartType? targetType(TypeSystem typeSystem) {
    var parent = this.parent;

    if (parent is MethodInvocation && parent.methodName == this) {
      var target = parent.realTarget;
      if (target != null) {
        var type = target.staticType;
        if (type == null) return type;
        if (parent.isNullAware) {
          type = typeSystem.promoteToNonNull(type);
        }
        return type;
      }
    } else if (parent is PropertyAccess && parent.propertyName == this) {
      var type = parent.realTarget.staticType;
      if (type == null) return type;
      if (parent.isNullAware) {
        type = typeSystem.promoteToNonNull(type);
      }
      return type;
    } else if (parent is PrefixedIdentifier && parent.identifier == this) {
      return parent.prefix.staticType;
    }

    // If there is no explicit target, then return the type of an implicit
    // `this`.
    DartType? enclosingThisType(AstNode node) {
      var parent = node.parent;
      if (parent is ClassDeclaration) {
        return parent.declaredFragment?.element.thisType;
      } else if (parent is ExtensionDeclaration) {
        return parent.onClause?.extendedType.type;
      } else if (parent is MixinDeclaration) {
        return parent.declaredFragment?.element.thisType;
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
