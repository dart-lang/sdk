// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/namespace.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server/src/utilities/extensions/iterable.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/resolver/applicable_extensions.dart';
import 'package:analyzer/utilities/extensions/element.dart';
import 'package:analyzer/utilities/extensions/uri.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

typedef _ProducersGenerators =
    Future<List<ResolvedCorrectionProducer>> Function(
      String? prefix,
      String name,
    );

class ImportLibrary extends MultiCorrectionProducer {
  /// The kinds of elements that a type-like reference can resolve to.
  static const _typeKinds = [
    ElementKind.CLASS,
    ElementKind.ENUM,
    ElementKind.EXTENSION_TYPE,
    ElementKind.FUNCTION_TYPE_ALIAS,
    ElementKind.MIXIN,
    ElementKind.TYPE_ALIAS,
  ];

  /// The kinds of elements that a documentation comment reference can resolve
  /// to.
  ///
  /// A documentation comment reference such as `[foo]` names a declaration
  /// without saying what kind of declaration it is, so it can resolve to a
  /// top-level function or variable as well as to anything in [_typeKinds].
  static const _commentReferenceKinds = [
    ..._typeKinds,
    ElementKind.FUNCTION,
    ElementKind.TOP_LEVEL_VARIABLE,
  ];

  final _ImportKind _importKind;

  /// Initialize a newly created instance that will add an import for a
  /// declaration referenced from a documentation comment reference.
  ///
  /// Covers the same declarations as [ImportLibrary.forTypeOrMember], since a
  /// documentation comment reference names a declaration without saying what
  /// kind of declaration it is. Extensions referenced from a documentation
  /// comment are handled separately, by
  /// [ImportLibrary.forExtensionCommentReference].
  new forCommentReference({required super.context})
    : _importKind = .forCommentReference;

  /// Initialize a newly created instance that will add an import for an
  /// extension.
  new forExtension({required super.context}) : _importKind = .forExtension;

  /// Initialize a newly created instance that will add an import for an
  /// extension referenced from a documentation comment reference.
  new forExtensionCommentReference({required super.context})
    : _importKind = .forExtensionCommentReference;

  /// Initialize a newly created instance that will add an import for a member
  /// of an extension.
  new forExtensionMember({required super.context})
    : _importKind = .forExtensionMember;

  /// Initialize a newly created instance that will add an import for an
  /// extension type.
  new forExtensionType({required super.context})
    : _importKind = .forExtensionType;

  /// Initialize a newly created instance that will add an import for a
  /// top-level function.
  new forFunction({required super.context}) : _importKind = .forFunction;

  /// Initialize a newly created instance that will add an import for a
  /// top-level variable.
  new forTopLevelVariable({required super.context})
    : _importKind = .forTopLevelVariable;

  /// Initialize a newly created instance that will add an import for a
  /// type-like declaration, or for a member reached through one.
  ///
  /// The type-like declarations are classes, enums, extension types, mixins,
  /// and typedefs; the members reached through one are constructors, static
  /// members, and enum values. Extensions are not included; they are handled by
  /// [ImportLibrary.forExtension].
  new forTypeOrMember({required super.context})
    : _importKind = .forTypeOrMember;

  @override
  Future<List<ResolvedCorrectionProducer>> get producers async {
    var names = await _allPossibleNames();
    if (names.isEmpty) {
      return const [];
    }
    return [for (var name in names) ...?(await name.producers)];
  }

  bool get shouldSuggestDocImports =>
      _importKind == .forCommentReference ||
      _importKind == .forExtensionCommentReference;

  /// A map of all the diagnostic codes that this fix can be applied to and the
  /// generators that can be used to apply the fix.
  Map<DiagnosticCode, List<MultiProducerGenerator>> get _codesWhereThisIsValid {
    var producerGenerators = _ImportKind.values.map((key) => key.fn).toList();
    var nonLintMultiProducers = registeredFixGenerators.warningMultiProducers;
    return {
      for (var MapEntry(:key, :value) in nonLintMultiProducers.entries)
        if (value.containsAny(producerGenerators)) key: value,
    };
  }

  Future<List<_PrefixedName>> _allPossibleNames() async {
    return switch (_importKind) {
      .forCommentReference => _namesForType(_commentReferenceKinds),
      .forExtension => _namesForExtension(),
      .forExtensionCommentReference => _namesForExtension(),
      .forExtensionMember => await _namesForExtensionMember(),
      .forExtensionType => _namesForExtensionType(),
      .forFunction => _namesForFunction(),
      .forTopLevelVariable => _namesForTopLevelVariable(),
      .forTypeOrMember => _namesForType(),
    };
  }

  DartType? _getTypeForPattern(AstNode node) {
    var parent = node.parent;
    while (parent is DartPattern || parent?.parent is DartPattern) {
      if (parent is ObjectPattern) {
        return parent.type.type;
      }
      parent = parent?.parent;
    }
    // We don't know how to answer this.
    return null;
  }

  Future<(_ImportLibraryCombinator?, _ImportLibraryCombinatorMultiple?)>
  _importEditCombinators(
    LibraryImport import,
    LibraryElement libraryElement,
    String uri,
    String name, {
    String? prefix,
  }) async {
    var combinators = import.combinators;
    if (combinators.isEmpty) {
      return (null, null);
    }
    var otherNames = await _otherUnresolvedNames(prefix, name);
    var namesInThisLibrary = <String>[
      name,
      for (var otherName in otherNames)
        ?getExportedElement(libraryElement, otherName)?.name,
    ];
    var importPrefix = import.prefix?.element;
    var importCombinator = _ImportLibraryCombinator(
      uri,
      combinators,
      name,
      removePrefix: importPrefix == null,
      context: context,
    );
    if (namesInThisLibrary.length == 1) {
      return (importCombinator, null);
    }
    var importCombinatorMultiple = _ImportLibraryCombinatorMultiple(
      uri,
      combinators,
      namesInThisLibrary,
      removePrefix: importPrefix == null,
      context: context,
    );
    return (importCombinator, importCombinatorMultiple);
  }

  /// Returns a list of import correction producers, two or four of them when
  /// [fixKindDoc] is `null`, and three or six when it is not.
  ///
  /// For each import path used in the return values, one returned correction
  /// producer uses a 'show' combinator, and one does not.
  ///
  /// If [includeRelativeFix] is `false`, only correction producers with
  /// absolute import paths are returned. Otherwise, correction producers with
  /// absolute import paths and correction producers with relative paths are
  /// returned. If the `always_use_package_imports` lint rule is enabled then
  /// only correction producers using the package import are returned. If the
  /// `prefer_relative_imports` lint rule is enabled then only correction
  /// producers using the relative path are returned. Otherwise, correction
  /// producers using both types of paths are returned in the order: absolute
  /// imports, relative imports.
  ///
  /// If [fixKindDoc] is non-`null`, one further correction producer is returned
  /// for each import path, adding an `@docImport` directive to the library's
  /// documentation comment rather than a regular import directive. Pass `null`
  /// when a doc import wouldn't resolve the diagnostic, so that no such
  /// correction is offered.
  List<ResolvedCorrectionProducer> _importLibrary(
    FixKind fixKind,
    FixKind fixKindShow,
    Uri library,
    String name, {
    required String? prefix,
    required bool includeRelativeFix,
    FixKind? fixKindDoc,
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
        if (fixKindDoc != null)
          _ImportAbsoluteLibrary(
            fixKindDoc,
            library,
            prefix,
            isDocImport: true,
            context: context,
          ),
      ];
    }
    var codeStyleOptions = getCodeStyleOptions(unitResult.file);
    var usePackageUris = codeStyleOptions.usePackageUris;
    var useRelativeUris = codeStyleOptions.useRelativeUris;
    return [
      if (usePackageUris || !useRelativeUris) ...[
        _ImportAbsoluteLibrary(fixKind, library, prefix, context: context),
        _ImportAbsoluteLibrary(
          fixKindShow,
          library,
          prefix,
          show: name,
          context: context,
        ),
        if (fixKindDoc != null)
          _ImportAbsoluteLibrary(
            fixKindDoc,
            library,
            prefix,
            isDocImport: true,
            context: context,
          ),
      ],
      if (useRelativeUris || !usePackageUris) ...[
        _ImportRelativeLibrary(fixKind, library, prefix, context: context),
        _ImportRelativeLibrary(
          fixKindShow,
          library,
          prefix,
          show: name,
          context: context,
        ),
        if (fixKindDoc != null)
          _ImportRelativeLibrary(
            fixKindDoc,
            library,
            prefix,
            isDocImport: true,
            context: context,
          ),
      ],
    ];
  }

  Future<List<ResolvedCorrectionProducer>> _importLibraryForElement(
    String name,
    List<ElementKind> kinds, {
    String? prefix,
    bool canBePrefixed = true,
  }) async {
    // Ignore the element if the name is private.
    if (name.startsWith('_')) {
      return const [];
    }
    var producers = <ResolvedCorrectionProducer>[];
    // Maybe there is an existing import, but it is with prefix and we don't use
    // this prefix.
    var alreadyImported = <LibraryElement>{};
    for (var importDirective
        in unitResult.unit.directives.whereType<ImportDirective>()) {
      // Prepare the element.
      var import = importDirective.libraryImport;
      if (import == null) {
        continue;
      }
      var libraryElement = import.importedLibrary;
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
      // Maybe update a "show"/"hide" directive.
      var (
        combinatorProducer,
        combinatorProducerMultiple,
      ) = await _importEditCombinators(
        import,
        libraryElement,
        importDirective.uri.stringValue!,
        name,
        prefix: prefix,
      );
      // Maybe apply a prefix.
      var importPrefix = import.prefix?.element;
      if (canBePrefixed && importPrefix != null) {
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
        alreadyImported.add(libraryElement);
        producers.add(combinatorProducer);
        if (combinatorProducerMultiple != null) {
          producers.add(combinatorProducerMultiple);
        }
      }
    }
    // Find new top-level declarations.
    var librariesWithElements = await getTopLevelDeclarations(name);
    for (var libraryEntry in librariesWithElements.entries) {
      var libraryElement = libraryEntry.key;
      var declaration = libraryEntry.value;
      var librarySource = libraryElement.firstFragment.source;
      // Check the kind.
      if (!kinds.contains(declaration.kind)) {
        continue;
      }
      // Check the source.
      if (alreadyImported.contains(libraryElement)) {
        continue;
      }
      // Check that the import doesn't end with '.template.dart'.
      if (librarySource.uri.path.endsWith('.template.dart')) {
        continue;
      }
      // Compute the fix kind.
      FixKind fixKind;
      FixKind fixKindShow;
      FixKind? fixKindDoc;
      var suggestDoc = shouldSuggestDocImports && prefix.isEmptyOrNull;
      if (declaration.hasOrInheritsDeprecated ||
          libraryElement.hasOrInheritsDeprecated) {
        fixKind = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject4
            : DartFixKind.importLibraryProject4Prefixed;
        fixKindShow = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject4Show
            : DartFixKind.importLibraryProject4PrefixedShow;
        if (suggestDoc) {
          fixKindDoc = DartFixKind.importLibraryProject4Doc;
        }
      } else if (libraryElement.isInSdk) {
        fixKind = prefix.isEmptyOrNull
            ? DartFixKind.importLibrarySdk
            : DartFixKind.importLibrarySdkPrefixed;
        fixKindShow = prefix.isEmptyOrNull
            ? DartFixKind.importLibrarySdkShow
            : DartFixKind.importLibrarySdkPrefixedShow;
        if (suggestDoc) {
          fixKindDoc = DartFixKind.importLibrarySdkDoc;
        }
      } else if (_isLibSrcPath(librarySource.fullName)) {
        // Bad: non-API.
        fixKind = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject3
            : DartFixKind.importLibraryProject3Prefixed;
        fixKindShow = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject3Show
            : DartFixKind.importLibraryProject3PrefixedShow;
        if (suggestDoc) {
          fixKindDoc = DartFixKind.importLibraryProject3Doc;
        }
      } else if (declaration.library != libraryElement) {
        // Ugly: exports.
        fixKind = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject2
            : DartFixKind.importLibraryProject2Prefixed;
        fixKindShow = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject2Show
            : DartFixKind.importLibraryProject2PrefixedShow;
        if (suggestDoc) {
          fixKindDoc = DartFixKind.importLibraryProject2Doc;
        }
      } else {
        // Good: direct declaration.
        fixKind = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject1
            : DartFixKind.importLibraryProject1Prefixed;
        fixKindShow = prefix.isEmptyOrNull
            ? DartFixKind.importLibraryProject1Show
            : DartFixKind.importLibraryProject1PrefixedShow;
        if (suggestDoc) {
          fixKindDoc = DartFixKind.importLibraryProject1Doc;
        }
      }
      // If both files are in the same package's 'lib' folder, also include a
      // relative import.
      var includeRelativeUri = librarySource.uri.isSamePackageAs(
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
          fixKindDoc: fixKindDoc,
        ),
      );
    }
    return producers;
  }

  /// Whether [path] appears to be a package-implementation source file.
  ///
  /// Note that this is approximate; without knowing the containing package's
  /// location, this can give false positives.
  bool _isLibSrcPath(String path) {
    var parts = resourceProvider.pathContext.split(path);
    for (var i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'lib' && parts[i + 1] == 'src') {
        return true;
      }
    }
    return false;
  }

  List<_PrefixedName> _namesForExtension() {
    if (node case SimpleIdentifier(:var name, :var parent)) {
      return _namesForMethodInvocation(name, parent, [ElementKind.EXTENSION]);
    }

    return const [];
  }

  List<_PrefixedName> _namesForExtensionInLibrary(
    LibraryElement libraryToImport,
    DartType targetType,
    Name memberName,
  ) {
    // Look to see whether the library at the [uri] is already imported. If it
    // is, then we can check the extension elements without needing to perform
    // additional analysis.
    var foundImport = false;
    var names = <_PrefixedName>[];
    var extensionsInLibrary =
        <LibraryImport?, List<InstantiatedExtensionWithMember>>{};
    for (var import in unitResult.libraryFragment.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary == null || importedLibrary != libraryToImport) {
        continue;
      }
      foundImport = true;
      extensionsInLibrary[import] = importedLibrary.exportedExtensions
          .havingMemberWithBaseName(memberName)
          .applicableTo(targetLibrary: libraryElement2, targetType: targetType);
    }

    // If the library at the URI is not already imported, we return a correction
    // producer that will either add an import or not based on the result of
    // analyzing the library.
    if (!foundImport) {
      extensionsInLibrary[null] = libraryToImport.exportedExtensions
          .havingMemberWithBaseName(memberName)
          .applicableTo(targetLibrary: libraryElement2, targetType: targetType);
    }
    for (var entry in extensionsInLibrary.entries) {
      var extensionsInLibrary = entry.value;
      for (var instantiatedExtension in extensionsInLibrary) {
        names.add(
          _PrefixedName(
            name: instantiatedExtension.extension.name!,
            ignorePrefix: true,
            producerGenerators: (prefix, name) async {
              return await _importLibraryForElement(
                name,
                prefix: prefix,
                canBePrefixed: false,
                [ElementKind.EXTENSION],
              );
            },
          ),
        );
      }
    }
    return names;
  }

  Future<List<_PrefixedName>> _namesForExtensionMember() async {
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
    } else if (node is PatternFieldName) {
      memberName = node.name?.lexeme ?? '';
      if (memberName.isEmpty) {
        return const [];
      }
      targetType = _getTypeForPattern(node);
    } else if (node is DeclaredVariablePattern) {
      memberName = node.name.lexeme;
      targetType = _getTypeForPattern(node);
    } else {
      return const [];
    }

    if (targetType == null) {
      return const [];
    }
    var finalTargetType = targetType;

    var dartFixContext = context.dartFixContext;
    if (dartFixContext == null) {
      return const [];
    }

    var names = <_PrefixedName>[];
    var name = Name.forLibrary(
      dartFixContext.unitResult.libraryElement,
      memberName,
    );
    await for (var libraryToImport in librariesWithExtensions(name)) {
      names.addAll(
        _namesForExtensionInLibrary(libraryToImport, finalTargetType, name),
      );
    }
    return names;
  }

  List<_PrefixedName> _namesForExtensionType() {
    if (node case SimpleIdentifier(:var name)) {
      return [
        _PrefixedName(
          name: name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, const [
              ElementKind.EXTENSION_TYPE,
            ]);
          },
        ),
      ];
    }

    return const [];
  }

  List<_PrefixedName> _namesForFunction() {
    if (node case SimpleIdentifier(:var name, :var parent)) {
      return _namesForMethodInvocation(name, parent, const [
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
  ///   function called `bar`.
  /// - Import of some library that contains a top-level propriety or class-like
  ///   member called `foo` that has a method called `bar` (has to be static for
  ///   a class-like member with that name).
  List<_PrefixedName> _namesForMethodInvocation(
    String name,
    AstNode? parent,
    List<ElementKind> kinds,
  ) {
    String? prefix;
    var names = <_PrefixedName>[];
    if (parent case MethodInvocation(:var target?, :var function)) {
      // Getting the import library for elements with [name].
      names.add(
        _PrefixedName(
          name: name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, kinds, prefix: prefix);
          },
        ),
      );

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
      names.add(
        _PrefixedName(
          name: name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, kinds, prefix: prefix);
          },
        ),
      );

      // Set the prefix and (maybe swap) name and get the other import library
      // option - with prefix!.
      if (identifier != node) {
        prefix = name;
        name = identifier.name;
      } else {
        prefix = parentPrefix.name;
      }
    }

    names.add(
      _PrefixedName(
        prefix: prefix,
        name: name,
        producerGenerators: (prefix, name) async {
          return await _importLibraryForElement(name, kinds, prefix: prefix);
        },
      ),
    );
    return names;
  }

  List<_PrefixedName> _namesForTopLevelVariable() {
    String? prefix;
    var targetNode = node;
    if (targetNode case Annotation(:var name)) {
      if (name.element == null) {
        if (targetNode.arguments != null) {
          return const [];
        }
        targetNode = name;
      }
    }
    if (targetNode case PrefixedIdentifier(:var prefix, :var identifier)) {
      return [
        _PrefixedName(
          prefix: prefix.name,
          name: identifier.name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, const [
              ElementKind.TOP_LEVEL_VARIABLE,
            ], prefix: prefix);
          },
        ),
        _PrefixedName(
          name: prefix.name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, const [
              ElementKind.TOP_LEVEL_VARIABLE,
            ], prefix: prefix);
          },
        ),
      ];
    }
    if (targetNode.parent case PrefixedIdentifier prefixed
        when prefixed.prefix == targetNode) {
      targetNode = prefixed.identifier;
      prefix = prefixed.prefix.name;
    }
    if (targetNode case SimpleIdentifier(:var name)) {
      return [
        _PrefixedName(
          prefix: prefix,
          name: name,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, const [
              ElementKind.TOP_LEVEL_VARIABLE,
            ], prefix: prefix);
          },
        ),
      ];
    }

    return const [];
  }

  List<_PrefixedName> _namesForType([List<ElementKind> kinds = _typeKinds]) {
    var targetNode = node;
    if (targetNode case Annotation(:var name)) {
      if (name.element == null) {
        if (targetNode.period != null && targetNode.arguments == null) {
          return const [];
        }
        targetNode = name;
      }
    }
    if (targetNode case SimpleIdentifier(:var name, :var parent)) {
      return _namesForMethodInvocation(name, parent, kinds);
    }
    String? prefix;
    if (targetNode case NamedType(:var importPrefix, :var parent)
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
      return [
        _PrefixedName(
          name: typeName,
          prefix: prefix,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, kinds, prefix: prefix);
          },
        ),
        if (targetNode case PrefixedIdentifier(:var identifier, :var prefix))
          _PrefixedName(
            name: identifier.name,
            prefix: prefix.name,
            producerGenerators: (prefix, name) async {
              return await _importLibraryForElement(
                name,
                kinds,
                prefix: prefix,
              );
            },
          ),
      ];
    }
    if (targetNode is SimpleIdentifier &&
        targetNode.mightBeImplicitConstructor) {
      var typeName = targetNode.name;
      return [
        _PrefixedName(
          name: typeName,
          prefix: prefix,
          producerGenerators: (prefix, name) async {
            return await _importLibraryForElement(name, const [
              ElementKind.CLASS,
            ], prefix: prefix);
          },
        ),
      ];
    }

    return const [];
  }

  /// Searches all diagnostics reported for this compilation unit for unresolved
  /// names where this fix can be applied besides the current diagnostic.
  Future<Set<String>> _otherUnresolvedNames(String? prefix, String name) async {
    var errorsForThisFix = _codesWhereThisIsValid;
    var diagnostics = <Diagnostic, List<MultiProducerGenerator>>{}
      ..addEntries(
        unitResult.diagnostics.map((d) {
          if (d == diagnostic) return null;
          var generators = errorsForThisFix[d.diagnosticCode];
          if (generators == null) return null;
          return MapEntry(d, generators);
        }).nonNulls,
      );
    var otherNames = <String>{};
    if (diagnostics.isNotEmpty) {
      for (var MapEntry(:key, :value) in diagnostics.entries) {
        for (var generator in value) {
          DartFixContext? dartFixContext;
          if (context.dartFixContext case var context?) {
            dartFixContext = DartFixContext(
              instrumentationService: context.instrumentationService,
              workspace: context.workspace,
              libraryResult: context.libraryResult,
              unitResult: context.unitResult,
              error: key,
            );
          }
          var multiCorrectionProducer = generator(
            context: CorrectionProducerContext.createResolved(
              libraryResult: libraryResult,
              unitResult: unitResult,
              diagnostic: key,
              selectionLength: key.length,
              selectionOffset: key.offset,
              dartFixContext: dartFixContext,
            ),
          );
          if (multiCorrectionProducer is ImportLibrary) {
            var names = await multiCorrectionProducer._allPossibleNames();
            for (var prefixedName in names) {
              if (prefixedName.name != name &&
                  (prefixedName.ignorePrefix ||
                      prefixedName.prefix == prefix)) {
                otherNames.add(prefixedName.name);
              }
            }
          }
        }
      }
    }
    return otherNames;
  }
}

/// A correction processor that can add an import using an absolute URI.
class _ImportAbsoluteLibrary extends ResolvedCorrectionProducer
    with _ImportLibraryMixin {
  @override
  final FixKind _fixKind;
  @override
  final String? _prefix;
  @override
  final Uri _library;
  final String? _show;
  @override
  final bool _isDocImport;

  @override
  String _uriText = '';

  new(
    this._fixKind,
    this._library,
    this._prefix, {
    this._show,
    this._isDocImport = false,
    required super.context,
  });

  @override
  String _docImport(DartFileEditBuilderImpl builder) =>
      builder.docImportLibraryWithAbsoluteUri(_library);

  @override
  String _import(DartFileEditBuilderImpl builder) =>
      builder.importLibraryWithAbsoluteUri(
        _library,
        prefix: _prefix,
        showName: _show,
        useShow: _show != null,
      );
}

enum _ImportKind {
  forCommentReference(ImportLibrary.forCommentReference),
  forExtension(ImportLibrary.forExtension),
  forExtensionCommentReference(ImportLibrary.forExtensionCommentReference),
  forExtensionMember(ImportLibrary.forExtensionMember),
  forExtensionType(ImportLibrary.forExtensionType),
  forFunction(ImportLibrary.forFunction),
  forTopLevelVariable(ImportLibrary.forTopLevelVariable),
  forTypeOrMember(ImportLibrary.forTypeOrMember);

  final ImportLibrary Function({required CorrectionProducerContext context}) fn;

  new(this.fn);
}

/// A correction processor that can add/remove a name to/from the show/hide
/// combinator of an existing import.
class _ImportLibraryCombinator extends _ImportLibraryCombinatorMultiple {
  new(
    String libraryName,
    List<NamespaceCombinator> combinators,
    String updatedName, {
    super.removePrefix,
    required super.context,
  }) : super(libraryName, combinators, [updatedName]);

  @override
  List<String> get fixArguments => [_updatedNames.first, _libraryName];

  @override
  FixKind get fixKind => DartFixKind.importLibraryCombinator;
}

/// A correction processor that can add/remove multiple names to/from the
/// show/hide combinator of an existing import.
class _ImportLibraryCombinatorMultiple extends ResolvedCorrectionProducer {
  final String _libraryName;

  final List<NamespaceCombinator> _combinators;

  final List<String> _updatedNames;

  final bool _removePrefix;

  new(
    this._libraryName,
    this._combinators,
    this._updatedNames, {
    this._removePrefix = false,
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var othersCount = _updatedNames.length - 1;
    return [
      _updatedNames.first,
      '$othersCount',
      othersCount == 1 ? '' : 's', // plural for 'other(s)'
      _libraryName,
    ];
  }

  @override
  FixKind get fixKind => DartFixKind.importLibraryCombinatorMultiple;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var codeStyleOptions = getCodeStyleOptions(unitResult.file);

    for (var combinator in _combinators) {
      var combinatorNames = <String>{};
      var offset = combinator.offset;
      var length = combinator.end - offset;

      Keyword keyword;
      switch (combinator) {
        case ShowElementCombinator(shownNames: var names):
          combinatorNames.addAll(names);
          combinatorNames.addAll(_updatedNames);
          keyword = Keyword.SHOW;
        case HideElementCombinator(hiddenNames: var names):
          combinatorNames.addAll(names);
          combinatorNames.removeAll(_updatedNames);
          keyword = Keyword.HIDE;
      }

      var names = codeStyleOptions.sortCombinators
          ? combinatorNames.sorted()
          : combinatorNames;

      var newCombinatorCode = '';
      if (names.isNotEmpty) {
        newCombinatorCode = ' ${keyword.lexeme} ${names.join(', ')}';
      }
      var libraryPath = unitResult.libraryElement.firstFragment.source.fullName;
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
}

/// Shared behavior for correction producers that add an import for a
/// library, either as a regular import directive or, when [_isDocImport] is
/// `true`, as a `/// @docImport` documentation comment on the library
/// directive.
mixin _ImportLibraryMixin on ResolvedCorrectionProducer {
  @override
  /// There may be many import options that can be the right choice.
  CorrectionApplicability get applicability => .singleLocation;

  @override
  List<String> get fixArguments => [
    _uriText,
    if (_prefix != null && _prefix.isNotEmpty) _prefix,
  ];

  @override
  FixKind get fixKind => _fixKind;

  FixKind get _fixKind;

  bool get _isDocImport;

  // ignore: unused_element referenced in doc comments below.
  Uri get _library;

  String? get _prefix;

  String get _uriText;

  set _uriText(String value);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await builder.addDartFileEdit(file, (builder) {
      if (builder is DartFileEditBuilderImpl) {
        _uriText = _isDocImport ? _docImport(builder) : _import(builder);
      }
    });
  }

  /// Adds a `/// @docImport` for [_library] and returns the URI text that was
  /// written.
  String _docImport(DartFileEditBuilderImpl builder);

  /// Adds an import for [_library] and returns the URI text that was
  /// written.
  String _import(DartFileEditBuilderImpl builder);
}

/// A correction processor that can add a prefix to an identifier defined in a
/// library that is already imported but that is imported with a prefix.
class _ImportLibraryPrefix extends ResolvedCorrectionProducer {
  final LibraryElement _importedLibrary;
  final PrefixElement _importPrefix;
  final String? _nodePrefix;
  final _ImportLibraryCombinator? _editCombinator;

  new(
    this._importedLibrary,
    this._importPrefix,
    this._editCombinator,
    this._nodePrefix, {
    required super.context,
  });

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments {
    var uriStr = _importedLibrary.uri.toString();
    return [uriStr, _prefixName];
  }

  @override
  FixKind get fixKind => DartFixKind.importLibraryPrefix;

  String get _prefixName => _importPrefix.name!;

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
      SourceRange nodeRange;
      if (targetNode case NamedType(:var importPrefix?)) {
        nodeRange = range.node(importPrefix);
      } else if (targetNode case PrefixedIdentifier(
        prefix: var prefixNode,
        :var identifier,
      )) {
        nodeRange = range.startStart(prefixNode, identifier);
      } else if (targetNode.parent
          case MethodInvocation(:SimpleIdentifier target, :var methodName)
          when target.name == _nodePrefix) {
        nodeRange = range.startStart(target, methodName);
      } else {
        return;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(nodeRange, '$_prefixName.');
      });
    }
  }
}

/// A correction processor that can add an import using a relative URI.
class _ImportRelativeLibrary extends ResolvedCorrectionProducer
    with _ImportLibraryMixin {
  @override
  final FixKind _fixKind;
  @override
  final String? _prefix;
  @override
  final Uri _library;
  final String? _show;
  @override
  final bool _isDocImport;

  @override
  String _uriText = '';

  new(
    this._fixKind,
    this._library,
    this._prefix, {
    this._show,
    this._isDocImport = false,
    required super.context,
  });

  @override
  String _docImport(DartFileEditBuilderImpl builder) =>
      builder.docImportLibraryWithRelativeUri(_library);

  @override
  String _import(DartFileEditBuilderImpl builder) =>
      builder.importLibraryWithRelativeUri(
        _library,
        prefix: _prefix,
        showName: _show,
        useShow: _show != null,
      );
}

/// Information needed to generate producers for a given [name] and [prefix].
///
/// This is used in normal cases simply to generate the producers, but for the
/// [_ImportLibraryCombinatorMultiple] correction producer, it is used to save
/// the different names that are being added to the combinator.
class _PrefixedName {
  /// Whether to ignore the prefix.
  ///
  /// This should only be used when the import is an extension and the library
  /// is already imported and prefixed.
  final bool ignorePrefix;
  final String? prefix;
  final String name;
  final _ProducersGenerators _producerGenerators;

  new({
    required this.name,
    this.prefix,
    required this._producerGenerators,
    this.ignorePrefix = false,
  });

  Future<List<ResolvedCorrectionProducer>>? get producers =>
      _producerGenerators(prefix, name);
}

extension on SimpleIdentifier {
  /// Whether this [AstNode] is in a location where an implicit constructor
  /// invocation would be allowed.
  bool get mightBeImplicitConstructor {
    var parent = this.parent;
    if (parent is MethodInvocation) {
      return parent.realTarget == null;
    }

    return false;
  }
}

extension on AstNode {
  /// The "type name" of this node if it might represent a type, and `null`
  /// otherwise.
  String? get nameOfType {
    switch (this) {
      case NamedType(:var importPrefix, :var name):
        if (parent is ConstructorName && importPrefix != null) {
          return importPrefix.name.lexeme;
        }
        return name.lexeme;
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
      var parent = node.parent?.parent;
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
