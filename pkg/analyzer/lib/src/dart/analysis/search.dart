// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer/src/utilities/fuzzy_matcher.dart';
import 'package:collection/collection.dart';

Element _getEnclosingElement(CompilationUnitElement unitElement, int offset) {
  var finder = _ContainingElementFinder(offset);
  unitElement.accept(finder);
  var element = finder.containingElement;
  if (element == null) {
    throw StateError(
      'No containing element in ${unitElement.source.fullName} at $offset',
    );
  }
  return element;
}

DeclarationKind? _getSearchElementKind(Element element) {
  if (element is EnumElement) {
    return DeclarationKind.ENUM;
  }

  if (element is MixinElement) {
    return DeclarationKind.MIXIN;
  }

  if (element is ClassElement) {
    if (element.isMixinApplication) {
      return DeclarationKind.CLASS_TYPE_ALIAS;
    }
    return DeclarationKind.CLASS;
  }

  if (element is ConstructorElement) {
    return DeclarationKind.CONSTRUCTOR;
  }

  if (element is ExtensionElement) {
    return DeclarationKind.EXTENSION;
  }

  if (element is FieldElement) {
    if (element.isEnumConstant) return DeclarationKind.ENUM_CONSTANT;
    return DeclarationKind.FIELD;
  }

  if (element is FunctionElement) {
    return DeclarationKind.FUNCTION;
  }

  if (element is MethodElement) {
    return DeclarationKind.METHOD;
  }

  if (element is PropertyAccessorElement) {
    return element.isGetter ? DeclarationKind.GETTER : DeclarationKind.SETTER;
  }

  if (element is TypeAliasElement) {
    return DeclarationKind.TYPE_ALIAS;
  }

  if (element is VariableElement) {
    return DeclarationKind.VARIABLE;
  }

  return null;
}

/// An element declaration.
class Declaration {
  final int fileIndex;
  final LineInfo lineInfo;
  final String name;
  final DeclarationKind kind;
  final int offset;
  final int line;
  final int column;
  final int codeOffset;
  final int codeLength;
  final String? className;
  final String? mixinName;
  final String? parameters;

  Declaration(
    this.fileIndex,
    this.lineInfo,
    this.name,
    this.kind,
    this.offset,
    this.line,
    this.column,
    this.codeOffset,
    this.codeLength,
    this.className,
    this.mixinName,
    this.parameters,
  );
}

/// The kind of a [Declaration].
enum DeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  EXTENSION,
  FIELD,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  METHOD,
  MIXIN,
  SETTER,
  TYPE_ALIAS,
  VARIABLE
}

/// Searches through files known to [drivers] for declarations.
///
/// If files are known to multiple drivers, they will be searched only within
/// the context of the first.
class FindDeclarations {
  final List<AnalysisDriver> drivers;
  final WorkspaceSymbols result;
  final int? maxResults;
  final String pattern;
  final FuzzyMatcher matcher;
  final String? onlyForFile;
  final bool onlyAnalyzed;
  final OwnedFiles ownedFiles;
  final OperationPerformanceImpl performance;

  FindDeclarations(
    this.drivers,
    this.result,
    this.pattern,
    this.maxResults, {
    this.onlyForFile,
    this.onlyAnalyzed = false,
    required this.ownedFiles,
    required this.performance,
  }) : matcher = FuzzyMatcher(pattern);

  Future<void> compute([CancellationToken? cancellationToken]) async {
    if (!onlyAnalyzed) {
      await performance.runAsync('discoverAvailableFiles', (performance) async {
        await Future.wait(
          drivers.map((driver) => driver.discoverAvailableFiles()),
        );
      });
    }

    final entries = [
      ...ownedFiles.addedFiles.entries,
      if (!onlyAnalyzed) ...ownedFiles.knownFiles.entries,
    ];

    await performance.runAsync('findDeclarations', (performance) async {
      await _FindDeclarations(
        entries,
        result,
        pattern,
        matcher,
        maxResults,
        onlyForFile: onlyForFile,
        performance: performance,
      ).compute(cancellationToken);
    });
  }
}

/// Visitor that adds [SearchResult]s for references to the [importElement].
class ImportElementReferencesVisitor extends RecursiveAstVisitor<void> {
  final List<SearchResult> results = <SearchResult>[];

  final LibraryImportElement importElement;
  final CompilationUnitElement enclosingUnitElement;

  late final Set<Element> importedElements;

  ImportElementReferencesVisitor(
      LibraryImportElement element, this.enclosingUnitElement)
      : importElement = element {
    importedElements = element.namespace.definedNames.values.toSet();
  }

  @override
  void visitExportDirective(ExportDirective node) {}

  @override
  void visitImportDirective(ImportDirective node) {}

  @override
  void visitNamedType(NamedType node) {
    if (importedElements.contains(node.element)) {
      final importElementPrefix = importElement.prefix;
      final importPrefix = node.importPrefix;
      if (importElementPrefix == null) {
        if (importPrefix == null) {
          _addResult(node.offset, 0);
        }
      } else {
        if (importPrefix != null &&
            importPrefix.element == importElementPrefix.element) {
          final offset = importPrefix.offset;
          final end = importPrefix.period.end;
          _addResult(offset, end - offset);
        }
      }
    }

    node.importPrefix?.accept(this);
    node.typeArguments?.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (importElement.prefix != null) {
      if (node.staticElement == importElement.prefix?.element) {
        var parent = node.parent;
        if (parent is PrefixedIdentifier && parent.prefix == node) {
          var element = parent.writeOrReadElement?.declaration;
          if (importedElements.contains(element)) {
            _addResultForPrefix(node, parent.identifier);
          }
        }
        if (parent is MethodInvocation && parent.target == node) {
          var element = parent.methodName.staticElement?.declaration;
          if (importedElements.contains(element)) {
            _addResultForPrefix(node, parent.methodName);
          }
        }
      }
    } else {
      var element = node.writeOrReadElement?.declaration;
      if (importedElements.contains(element)) {
        _addResult(node.offset, 0);
      }
    }
  }

  void _addResult(int offset, int length) {
    Element enclosingElement =
        _getEnclosingElement(enclosingUnitElement, offset);
    results.add(SearchResult._(enclosingElement, SearchResultKind.REFERENCE,
        offset, length, true, false));
  }

  void _addResultForPrefix(SimpleIdentifier prefixNode, AstNode nextNode) {
    int prefixOffset = prefixNode.offset;
    _addResult(prefixOffset, nextNode.offset - prefixOffset);
  }
}

/// Search support for an [AnalysisDriver].
class Search {
  final AnalysisDriver _driver;

  Search(this._driver);

  /// Returns class or mixin members with the given [name].
  Future<List<Element>> classMembers(
      String name, SearchedFiles searchedFiles) async {
    List<Element> elements = <Element>[];

    void addElement(Element element) {
      if (!element.isSynthetic && element.displayName == name) {
        elements.add(element);
      }
    }

    void addElements(InterfaceElement element) {
      element.accessors.forEach(addElement);
      element.fields.forEach(addElement);
      element.methods.forEach(addElement);
    }

    List<String> files = await _driver.getFilesDefiningClassMemberName(name);
    for (String file in files) {
      if (searchedFiles.add(file, this)) {
        var unitResult = await _driver.getUnitElement(file);
        if (unitResult is UnitElementResult) {
          unitResult.element.classes.forEach(addElements);
          unitResult.element.enums.forEach(addElements);
          unitResult.element.mixins.forEach(addElements);
        }
      }
    }
    return elements;
  }

  /// Return the prefixes used to reference the [element] in any of the
  /// compilation units in the [library]. The returned set will include an empty
  /// string if the element is referenced without a prefix.
  Future<Set<String>> prefixesUsedInLibrary(
      LibraryElementImpl library, Element element) async {
    var prefixes = <String>{};
    for (var unit in library.units) {
      var index = await _driver.getIndex(unit.source.fullName);
      if (index != null) {
        _IndexRequest request = _IndexRequest(index);
        int elementId = request.findElementId(element);
        var prefixList = index.elementImportPrefixes[elementId].split(',');
        prefixes.addAll(prefixList);
      }
    }
    return prefixes;
  }

  /// Returns references to the [element].
  Future<List<SearchResult>> references(
      Element? element, SearchedFiles searchedFiles) async {
    if (element == null) {
      return const <SearchResult>[];
    }

    ElementKind kind = element.kind;
    if (element is ExtensionElement ||
        element is InterfaceElement ||
        element is PropertyAccessorElement && element.isSetter ||
        element is TypeAliasElement) {
      return _searchReferences(element, searchedFiles);
    } else if (element is ConstructorElement) {
      return await _searchReferences_Constructor(element, searchedFiles);
    } else if (element is CompilationUnitElement) {
      return _searchReferences_CompilationUnit(element);
    } else if (element is PropertyAccessorElement && element.isGetter) {
      return _searchReferences_Getter(element, searchedFiles);
    } else if (element is PropertyInducingElement) {
      return _searchReferences_Field(element, searchedFiles);
    } else if (kind == ElementKind.FUNCTION || kind == ElementKind.METHOD) {
      if (element.enclosingElement is ExecutableElement) {
        return _searchReferences_Local(
            element, (n) => n is Block, searchedFiles);
      }
      return _searchReferences_Function(element, searchedFiles);
    } else if (element is LibraryImportElement) {
      return _searchReferences_Import(element, searchedFiles);
    } else if (element is PatternVariableElementImpl) {
      return _searchReferences_PatternVariable(element, searchedFiles);
    } else if (kind == ElementKind.LABEL ||
        kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_Local(element, (n) => n is Block, searchedFiles);
    } else if (element is LibraryElement) {
      return _searchReferences_Library(element, searchedFiles);
    } else if (element is ParameterElement) {
      return _searchReferences_Parameter(element, searchedFiles);
    } else if (element is PrefixElement) {
      return _searchReferences_Prefix(element, searchedFiles);
    } else if (element is TypeParameterElement) {
      return _searchReferences_Local(
          element, (n) => n.parent is CompilationUnit, searchedFiles);
    }
    return const <SearchResult>[];
  }

  /// Returns subtypes of the given [type].
  ///
  /// The [searchedFiles] are consulted to see if a file is "owned" by this
  /// [Search] object, so should be only searched by it to avoid duplicate
  /// results; and updated to take ownership if the file is not owned yet.
  Future<List<SearchResult>> subTypes(
      InterfaceElement? type, SearchedFiles searchedFiles,
      {List<FileState>? filesToCheck}) async {
    if (type == null) {
      return const <SearchResult>[];
    }
    List<SearchResult> results = <SearchResult>[];
    await _addResults(
      results,
      type,
      searchedFiles,
      const {
        IndexRelationKind.IS_EXTENDED_BY:
            SearchResultKind.REFERENCE_IN_EXTENDS_CLAUSE,
        IndexRelationKind.IS_MIXED_IN_BY:
            SearchResultKind.REFERENCE_IN_WITH_CLAUSE,
        IndexRelationKind.IS_IMPLEMENTED_BY:
            SearchResultKind.REFERENCE_IN_IMPLEMENTS_CLAUSE,
        IndexRelationKind.CONSTRAINS: SearchResultKind.REFERENCE_IN_ON_CLAUSE,
      },
      filesToCheck: filesToCheck,
    );
    return results;
  }

  /// Return direct [SubtypeResult]s for either the [type] or [subtype].
  Future<List<SubtypeResult>> subtypes(SearchedFiles searchedFiles,
      {InterfaceElement? type, SubtypeResult? subtype}) async {
    String name;
    String id;
    if (type != null) {
      name = type.name;
      id = '${type.librarySource.uri};${type.source.uri};$name';
    } else {
      name = subtype!.name;
      id = subtype.id;
    }

    await _driver.discoverAvailableFiles();

    final List<SubtypeResult> results = [];

    // Note, this is a defensive copy.
    var files = _driver.fsState.getFilesSubtypingName(name)?.toList();

    if (files != null) {
      for (FileState file in files) {
        if (searchedFiles.add(file.path, this)) {
          var index = await _driver.getIndex(file.path);
          if (index != null) {
            var request = _IndexRequest(index);
            request.addSubtypes(id, results, file);
          }
        }
      }
    }

    return results;
  }

  /// Returns top-level elements with names matching the given [regExp].
  Future<List<Element>> topLevelElements(RegExp regExp) async {
    List<Element> elements = <Element>[];

    void addElement(Element element) {
      if (!element.isSynthetic && regExp.hasMatch(element.displayName)) {
        elements.add(element);
      }
    }

    List<FileState> knownFiles = _driver.fsState.knownFiles.toList();
    for (FileState file in knownFiles) {
      var unitResult = await _driver.getUnitElement(file.path);
      if (unitResult is UnitElementResult) {
        CompilationUnitElement unitElement = unitResult.element;
        unitElement.accessors.forEach(addElement);
        unitElement.classes.forEach(addElement);
        unitElement.enums.forEach(addElement);
        unitElement.extensions.forEach(addElement);
        unitElement.functions.forEach(addElement);
        unitElement.mixins.forEach(addElement);
        unitElement.topLevelVariables.forEach(addElement);
        unitElement.typeAliases.forEach(addElement);
      }
    }
    return elements;
  }

  /// Returns unresolved references to the given [name].
  Future<List<SearchResult>> unresolvedMemberReferences(
      String? name, SearchedFiles searchedFiles) async {
    if (name == null) {
      return const <SearchResult>[];
    }

    // Prepare the list of files that reference the name.
    List<String> files = await _driver.getFilesReferencingName(name);

    // Check the index of every file that references the element name.
    List<SearchResult> results = [];
    for (String file in files) {
      if (searchedFiles.add(file, this)) {
        var index = await _driver.getIndex(file);
        if (index != null) {
          _IndexRequest request = _IndexRequest(index);
          var fileResults = await request.getUnresolvedMemberReferences(
            name,
            const {
              IndexRelationKind.IS_READ_BY: SearchResultKind.READ,
              IndexRelationKind.IS_WRITTEN_BY: SearchResultKind.WRITE,
              IndexRelationKind.IS_READ_WRITTEN_BY: SearchResultKind.READ_WRITE,
              IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
            },
            () => _getUnitElement(file),
          );
          results.addAll(fileResults);
        }
      }
    }

    return results;
  }

  Future<void> _addResults(
      List<SearchResult> results,
      Element element,
      SearchedFiles searchedFiles,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      {List<FileState>? filesToCheck}) async {
    // Prepare the element name.
    String name = element.displayName;
    if (element is ConstructorElement) {
      name = element.enclosingElement.displayName;
    }

    // Prepare the list of files that reference the element name.
    List<String> files = <String>[];
    String path = element.source!.fullName;
    if (name.startsWith('_')) {
      String libraryPath = element.library!.source.fullName;
      if (searchedFiles.add(libraryPath, this)) {
        final libraryFile = _driver.fsState.getFileForPath(libraryPath);
        final libraryKind = libraryFile.kind;
        if (libraryKind is LibraryFileKind) {
          for (final file in libraryKind.files) {
            if (file.path == path || file.referencedNames.contains(name)) {
              files.add(file.path);
            }
          }
        }
      }
    } else {
      if (filesToCheck != null) {
        for (FileState file in filesToCheck) {
          if (file.referencedNames.contains(name)) {
            files.add(file.path);
          }
        }
      } else {
        files = await _driver.getFilesReferencingName(name);
      }
      if (searchedFiles.add(path, this) && !files.contains(path)) {
        files.add(path);
      }
    }

    // Check the index of every file that references the element name.
    for (String file in files) {
      if (searchedFiles.add(file, this)) {
        await _addResultsInFile(results, element, relationToResultKind, file);
      }
    }
  }

  /// Add results for [element] usage in the given [file].
  Future<void> _addResultsInFile(
      List<SearchResult> results,
      Element element,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      String file) async {
    var index = await _driver.getIndex(file);
    if (index != null) {
      _IndexRequest request = _IndexRequest(index);
      int elementId = request.findElementId(element);
      if (elementId != -1) {
        List<SearchResult> fileResults = await request.getRelations(
            elementId, relationToResultKind, () => _getUnitElement(file));
        results.addAll(fileResults);
      }
    }
  }

  Future<CompilationUnitElement?> _getUnitElement(String file) async {
    var result = await _driver.getUnitElement(file);
    return result is UnitElementResult ? result.element : null;
  }

  Future<List<SearchResult>> _searchReferences(
      Element element, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, element, searchedFiles,
        const {IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE});
    return results;
  }

  Future<List<SearchResult>> _searchReferences_CompilationUnit(
      CompilationUnitElement element) async {
    String path = element.source.fullName;

    final file = _driver.resourceProvider.getFile(path);
    final fileState = _driver.fsState.getExisting(file);

    // If the file is not known, then it is not referenced.
    if (fileState == null) {
      return const <SearchResult>[];
    }

    // Check files that reference the given file.
    List<SearchResult> results = <SearchResult>[];
    for (final reference in fileState.referencingFiles) {
      await _addResultsInFile(
        results,
        element,
        const {
          IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
        },
        reference.path,
      );
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Constructor(
      ConstructorElement element, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, element, searchedFiles, const {
      IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION,
      IndexRelationKind.IS_INVOKED_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS:
          SearchResultKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS,
      IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF:
          SearchResultKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF,
    });
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Field(
      PropertyInducingElement field, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    PropertyAccessorElement? getter = field.getter;
    PropertyAccessorElement? setter = field.setter;
    if (!field.isSynthetic) {
      await _addResults(results, field, searchedFiles, const {
        IndexRelationKind.IS_WRITTEN_BY: SearchResultKind.WRITE,
        IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE
      });
    }
    if (getter != null) {
      await _addResults(results, getter, searchedFiles, const {
        IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.READ,
        IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
      });
    }
    if (setter != null) {
      await _addResults(results, setter, searchedFiles,
          const {IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.WRITE});
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Function(
      Element element, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, element.declaration!, searchedFiles, const {
      IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
    });
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Getter(
      PropertyAccessorElement getter, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, getter, searchedFiles, const {
      IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
    });
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Import(
      LibraryImportElement element, SearchedFiles searchedFiles) async {
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      var unitResult = await _driver.getResult(unitPath);
      if (unitResult is ResolvedUnitResult) {
        var visitor = ImportElementReferencesVisitor(element, unitElement);
        unitResult.unit.accept(visitor);
        results.addAll(visitor.results);
      }
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Library(
      LibraryElement element, SearchedFiles searchedFiles) async {
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    for (CompilationUnitElement unitElement in element.units) {
      String unitPath = unitElement.source.fullName;
      var unitResult = await _driver.getResult(unitPath);
      if (unitResult is ResolvedUnitResult) {
        CompilationUnit unit = unitResult.unit;
        for (Directive directive in unit.directives) {
          if (directive is PartOfDirective && directive.element == element) {
            results.add(
              SearchResult._(
                unit.declaredElement!,
                SearchResultKind.REFERENCE,
                directive.libraryName!.offset,
                directive.libraryName!.length,
                true,
                false,
              ),
            );
          }
        }
      }
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Local(Element element,
      bool Function(AstNode n) isRootNode, SearchedFiles searchedFiles) async {
    String path = element.source!.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    // Prepare the unit.
    var unitResult = await _driver.getResult(path);
    if (unitResult is! ResolvedUnitResult) {
      return const <SearchResult>[];
    }
    var unit = unitResult.unit;

    // Prepare the node.
    var node = NodeLocator(element.nameOffset).searchWithin(unit);
    if (node == null) {
      return const <SearchResult>[];
    }

    // Prepare the enclosing node.
    var enclosingNode = node.thisOrAncestorMatching(isRootNode);
    if (enclosingNode == null) {
      return const <SearchResult>[];
    }

    // Find the matches.
    var visitor = _LocalReferencesVisitor({element}, unit.declaredElement!);
    enclosingNode.accept(visitor);
    return visitor.results;
  }

  Future<List<SearchResult>> _searchReferences_Parameter(
      ParameterElement parameter, SearchedFiles searchedFiles) async {
    List<SearchResult> results = <SearchResult>[];
    results.addAll(await _searchReferences_Local(
      parameter,
      (AstNode node) {
        var parent = node.parent;
        return parent is ClassDeclaration || parent is CompilationUnit;
      },
      searchedFiles,
    ));
    if (parameter.isNamed ||
        parameter.isOptionalPositional ||
        parameter.enclosingElement is ConstructorElement) {
      results.addAll(await _searchReferences(parameter, searchedFiles));
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_PatternVariable(
    PatternVariableElementImpl element,
    SearchedFiles searchedFiles,
  ) async {
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    var rootVariable = element.rootVariable;
    var transitiveVariables = rootVariable is JoinPatternVariableElementImpl
        ? rootVariable.transitiveVariables
        : [rootVariable];

    // Prepare a binding element for the variable.
    var bindElement = transitiveVariables
        .whereType<BindPatternVariableElementImpl>()
        .firstOrNull;
    if (bindElement == null) {
      return const <SearchResult>[];
    }

    // Prepare the root node for search.
    var rootNode = bindElement.node.thisOrAncestorMatching(
      (node) => node is SwitchExpression || node is Block,
    );
    if (rootNode == null) {
      return const <SearchResult>[];
    }

    // Find the matches.
    var visitor = _LocalReferencesVisitor(
      transitiveVariables.toSet(),
      bindElement.enclosingUnit,
    );
    rootNode.accept(visitor);
    return visitor.results;
  }

  Future<List<SearchResult>> _searchReferences_Prefix(
      PrefixElement element, SearchedFiles searchedFiles) async {
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      var unitResult = await _driver.getResult(unitPath);
      if (unitResult is ResolvedUnitResult) {
        var visitor = _LocalReferencesVisitor({element}, unitElement);
        unitResult.unit.accept(visitor);
        results.addAll(visitor.results);
      }
    }
    return results;
  }
}

/// Container that keeps track of file owners.
class SearchedFiles {
  final Map<String, Search> pathOwners = {};
  final Map<Uri, Search> uriOwners = {};

  bool add(String path, Search search) {
    final fsState = search._driver.fsState;
    final fileState = fsState.getExistingFromPath(path);
    if (fileState == null) {
      return false;
    }

    var pathOwner = pathOwners[path];
    var uriOwner = uriOwners[fileState.uri];
    if (pathOwner == null && uriOwner == null) {
      pathOwners[path] = search;
      uriOwners[fileState.uri] = search;
      return true;
    }
    return identical(pathOwner, search) && identical(uriOwner, search);
  }

  void ownAnalyzed(Search search) {
    for (var path in search._driver.addedFiles) {
      if (path.endsWith('.dart')) {
        add(path, search);
      }
    }
  }

  void ownKnown(Search search) {
    for (var path in search._driver.knownFiles) {
      if (path.endsWith('.dart')) {
        add(path, search);
      }
    }
  }
}

/// A single search result.
class SearchResult {
  /// The deep most element that contains this result.
  final Element enclosingElement;

  /// The kind of the [element] usage.
  final SearchResultKind kind;

  /// The offset relative to the beginning of the containing file.
  final int offset;

  /// The length of the usage in the containing file context.
  final int length;

  /// Is `true` if a field or a method is using with a qualifier.
  final bool isResolved;

  /// Is `true` if the result is a resolved reference to [element].
  final bool isQualified;

  SearchResult._(this.enclosingElement, this.kind, this.offset, this.length,
      this.isResolved, this.isQualified);

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write("SearchResult(kind=");
    buffer.write(kind);
    buffer.write(", enclosingElement=");
    buffer.write(enclosingElement);
    buffer.write(", offset=");
    buffer.write(offset);
    buffer.write(", length=");
    buffer.write(length);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
}

/// The kind of reference in a [SearchResult].
enum SearchResultKind {
  READ,
  READ_WRITE,
  WRITE,
  INVOCATION,
  INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS,
  REFERENCE,
  REFERENCE_BY_CONSTRUCTOR_TEAR_OFF,
  REFERENCE_IN_EXTENDS_CLAUSE,
  REFERENCE_IN_WITH_CLAUSE,
  REFERENCE_IN_ON_CLAUSE,
  REFERENCE_IN_IMPLEMENTS_CLAUSE,
}

/// A single subtype of a type.
class SubtypeResult {
  /// The URI of the library.
  final String libraryUri;

  /// The identifier of the subtype.
  final String id;

  /// The name of the subtype.
  final String name;

  /// The names of instance members declared in the class.
  final List<String> members;

  SubtypeResult(this.libraryUri, this.id, this.name, this.members);

  @override
  String toString() => id;
}

class WorkspaceSymbols {
  final List<Declaration> declarations = [];
  final List<String> files = [];
  final Map<String, int> _pathToIndex = {};

  /// Whether this search was marked cancelled before it completed.
  bool cancelled = false;

  bool hasMoreDeclarationsThan(int? maxResults) {
    return maxResults != null && declarations.length >= maxResults;
  }

  int _getPathIndex(String path) {
    var index = _pathToIndex[path];
    if (index == null) {
      index = files.length;
      files.add(path);
      _pathToIndex[path] = index;
    }
    return index;
  }
}

/// A visitor that finds the deep-most [Element] that contains the [offset].
class _ContainingElementFinder extends GeneralizingElementVisitor<void> {
  final int offset;
  Element? containingElement;

  _ContainingElementFinder(this.offset);

  @override
  void visitElement(Element element) {
    if (element is ElementImpl) {
      if (element.codeOffset != null &&
          element.codeOffset! <= offset &&
          offset <= element.codeOffset! + element.codeLength!) {
        containingElement = element;
        super.visitElement(element);
      }
    }
  }
}

class _FindCompilationUnitDeclarations {
  final CompilationUnitElement unit;
  final String filePath;
  final LineInfo lineInfo;
  final WorkspaceSymbols result;
  final int? maxResults;
  final FuzzyMatcher matcher;
  final void Function(Declaration) collect;

  _FindCompilationUnitDeclarations(
    this.unit,
    this.filePath,
    this.result,
    this.maxResults,
    this.matcher,
    this.collect,
  ) : lineInfo = unit.lineInfo;

  void compute(CancellationToken? cancellationToken) {
    if (result.hasMoreDeclarationsThan(maxResults)) {
      return;
    }

    _addAccessors(unit.accessors);
    _addClasses(unit.classes);
    _addClasses(unit.enums);
    _addClasses(unit.mixins);
    _addExtensions(unit.extensions);
    _addFunctions(unit.functions);
    _addTypeAliases(unit.typeAliases);
    _addVariables(unit.topLevelVariables);
  }

  void _addAccessors(List<PropertyAccessorElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (!element.isSynthetic) {
        _addDeclaration(element, element.displayName);
      }
    }
  }

  void _addClasses(List<InterfaceElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      _addDeclaration(element, element.name);
      _addAccessors(element.accessors);
      _addConstructors(element.constructors);
      _addFields(element.fields);
      _addMethods(element.methods);
    }
  }

  void _addConstructors(List<ConstructorElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (!element.isSynthetic) {
        _addDeclaration(element, element.name);
      }
    }
  }

  void _addDeclaration(Element element, String name) {
    if (result.hasMoreDeclarationsThan(maxResults)) {
      throw const _MaxNumberOfDeclarationsError();
    }

    if (matcher.score(name) < 0) {
      return;
    }

    var enclosing = element.enclosingElement;

    String? className;
    String? mixinName;
    if (enclosing is EnumElement) {
      // skip
    } else if (enclosing is MixinElement) {
      mixinName = enclosing.name;
    } else if (enclosing is InterfaceElement) {
      className = enclosing.name;
    }

    var kind = _getSearchElementKind(element);
    if (kind == null) {
      return;
    }

    String? parameters;
    if (element is ExecutableElement) {
      var displayString = element.getDisplayString(withNullability: true);
      var parameterIndex = displayString.indexOf('(');
      if (parameterIndex > 0) {
        parameters = displayString.substring(parameterIndex);
      }
    }

    element as ElementImpl; // to access codeOffset/codeLength
    var locationOffset = element.nameOffset;
    var locationStart = lineInfo.getLocation(locationOffset);

    collect(
      Declaration(
        result._getPathIndex(filePath),
        lineInfo,
        name,
        kind,
        locationOffset,
        locationStart.lineNumber,
        locationStart.columnNumber,
        element.codeOffset ?? 0,
        element.codeLength ?? 0,
        className,
        mixinName,
        parameters,
      ),
    );
  }

  void _addExtensions(List<ExtensionElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      var name = element.name;
      if (name != null) {
        _addDeclaration(element, name);
      }
      _addAccessors(element.accessors);
      _addFields(element.fields);
      _addMethods(element.methods);
    }
  }

  void _addFields(List<FieldElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (!element.isSynthetic) {
        _addDeclaration(element, element.name);
      }
    }
  }

  void _addFunctions(List<FunctionElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      _addDeclaration(element, element.name);
    }
  }

  void _addMethods(List<MethodElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      _addDeclaration(element, element.name);
    }
  }

  void _addTypeAliases(List<TypeAliasElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      _addDeclaration(element, element.name);
    }
  }

  void _addVariables(List<TopLevelVariableElement> elements) {
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (!element.isSynthetic) {
        _addDeclaration(element, element.name);
      }
    }
  }
}

/// Searches through [files] for declarations.
class _FindDeclarations {
  final List<MapEntry<Uri, AnalysisDriver>> fileEntries;
  final WorkspaceSymbols result;
  final int? maxResults;
  final String pattern;
  final FuzzyMatcher matcher;
  final String? onlyForFile;
  final OperationPerformanceImpl performance;

  _FindDeclarations(
    this.fileEntries,
    this.result,
    this.pattern,
    this.matcher,
    this.maxResults, {
    this.onlyForFile,
    required this.performance,
  });

  /// Add matching declarations to the [result].
  Future<void> compute(CancellationToken? cancellationToken) async {
    if (result.hasMoreDeclarationsThan(maxResults)) {
      return;
    }

    if (cancellationToken != null &&
        cancellationToken.isCancellationRequested) {
      result.cancelled = true;
      return;
    }

    var filesProcessed = 0;
    try {
      for (var entry in fileEntries) {
        var uri = entry.key;
        var analysisDriver = entry.value;

        final libraryElement = await performance.runAsync(
          'getLibraryByUri',
          (performance) async {
            final result = await analysisDriver.getLibraryByUri('$uri');
            if (result is LibraryElementResultImpl) {
              return result.element as LibraryElementImpl;
            }
            return null;
          },
        );

        if (libraryElement != null) {
          // Check if there is any name that could match the pattern.
          var match = libraryElement.nameUnion.contains(pattern);
          if (!match) {
            continue;
          }

          var units = libraryElement.units;
          for (var i = 0; i < units.length; i++) {
            var unit = units[i];
            var filePath = unit.source.fullName;
            if (onlyForFile != null && filePath != onlyForFile) {
              continue;
            }
            performance.run('unitDeclarations', (performance) {
              var finder = _FindCompilationUnitDeclarations(
                unit,
                filePath,
                result,
                maxResults,
                matcher,
                result.declarations.add,
              );
              finder.compute(cancellationToken);
            });
          }
        }

        // Periodically yield and check cancellation token.
        if (cancellationToken != null && (filesProcessed++) % 20 == 0) {
          await null; // allow cancellation requests to be processed.
          if (cancellationToken.isCancellationRequested) {
            result.cancelled = true;
            return;
          }
        }
      }
    } on _MaxNumberOfDeclarationsError {
      return;
    }
  }
}

class _IndexRequest {
  final AnalysisDriverUnitIndex index;

  _IndexRequest(this.index);

  void addSubtypes(
      String superIdString, List<SubtypeResult> results, FileState file) {
    var superId = getStringId(superIdString);
    if (superId == -1) {
      return;
    }

    var superIndex = _findFirstOccurrence(index.supertypes, superId);
    if (superIndex == -1) {
      return;
    }

    var library = file.kind.library;
    if (library == null) {
      return;
    }

    for (;
        superIndex < index.supertypes.length &&
            index.supertypes[superIndex] == superId;
        superIndex++) {
      var subtype = index.subtypes[superIndex];
      var name = index.strings[subtype.name];
      var subId = '${library.file.uriStr};${file.uriStr};$name';
      results.add(SubtypeResult(
        library.file.uriStr,
        subId,
        name,
        subtype.members.map((m) => index.strings[m]).toList(),
      ));
    }
  }

  /// Return the [element]'s identifier in the [index] or `-1` if the
  /// [element] is not referenced in the [index].
  int findElementId(Element element) {
    IndexElementInfo info = IndexElementInfo(element);
    element = info.element;
    // Find the id of the element's unit.
    int unitId = getUnitId(element);
    if (unitId == -1) {
      return -1;
    }
    // Prepare information about the element.
    var components = ElementNameComponents(element);
    int unitMemberId = getStringId(components.unitMemberName);
    if (unitMemberId == -1) {
      return -1;
    }
    int classMemberId = getStringId(components.classMemberName);
    if (classMemberId == -1) {
      return -1;
    }
    int parameterId = getStringId(components.parameterName);
    if (parameterId == -1) {
      return -1;
    }

    // Try to find the element id using classMemberId, parameterId, and kind.
    int elementId =
        _findFirstOccurrence(index.elementNameUnitMemberIds, unitMemberId);
    if (elementId == -1) {
      return -1;
    }
    for (;
        elementId < index.elementNameUnitMemberIds.length &&
            index.elementNameUnitMemberIds[elementId] == unitMemberId;
        elementId++) {
      if (index.elementUnits[elementId] == unitId &&
          index.elementNameClassMemberIds[elementId] == classMemberId &&
          index.elementNameParameterIds[elementId] == parameterId &&
          index.elementKinds[elementId] == info.kind) {
        return elementId;
      }
    }
    return -1;
  }

  /// Return a list of results where an element with the given [elementId] has
  /// a relation with the kind from [relationToResultKind].
  ///
  /// The function [getEnclosingUnitElement] is used to lazily compute the
  /// enclosing [CompilationUnitElement] if there is a relation of an
  /// interesting kind.
  Future<List<SearchResult>> getRelations(
      int elementId,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      Future<CompilationUnitElement?> Function()
          getEnclosingUnitElement) async {
    // Find the first usage of the element.
    int i = _findFirstOccurrence(index.usedElements, elementId);
    if (i == -1) {
      return const <SearchResult>[];
    }
    // Create locations for every usage of the element.
    List<SearchResult> results = <SearchResult>[];
    CompilationUnitElement? enclosingUnitElement;
    for (;
        i < index.usedElements.length && index.usedElements[i] == elementId;
        i++) {
      IndexRelationKind relationKind = index.usedElementKinds[i];
      SearchResultKind? resultKind = relationToResultKind[relationKind];
      if (resultKind != null) {
        int offset = index.usedElementOffsets[i];
        enclosingUnitElement ??= await getEnclosingUnitElement();
        if (enclosingUnitElement != null) {
          Element enclosingElement =
              _getEnclosingElement(enclosingUnitElement, offset);
          results.add(SearchResult._(
            enclosingElement,
            resultKind,
            offset,
            index.usedElementLengths[i],
            true,
            index.usedElementIsQualifiedFlags[i],
          ));
        }
      }
    }
    return results;
  }

  /// Return the identifier of [str] in the [index] or `-1` if [str] is not
  /// used in the [index].
  int getStringId(String? str) {
    if (str == null) {
      return index.nullStringId;
    }

    return binarySearch(index.strings, str);
  }

  /// Return the identifier of the [CompilationUnitElement] containing the
  /// [element] in the [index] or `-1` if not found.
  int getUnitId(Element element) {
    CompilationUnitElement unitElement = getUnitElement(element);
    int libraryUriId = getUriId(unitElement.library.source.uri);
    if (libraryUriId == -1) {
      return -1;
    }
    int unitUriId = getUriId(unitElement.source.uri);
    if (unitUriId == -1) {
      return -1;
    }
    for (int i = 0; i < index.unitLibraryUris.length; i++) {
      if (index.unitLibraryUris[i] == libraryUriId &&
          index.unitUnitUris[i] == unitUriId) {
        return i;
      }
    }
    return -1;
  }

  /// Return a list of results where a class members with the given [name] is
  /// referenced with a qualifier, but is not resolved.
  Future<List<SearchResult>> getUnresolvedMemberReferences(
      String name,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      Future<CompilationUnitElement?> Function()
          getEnclosingUnitElement) async {
    // Find the name identifier.
    int nameId = getStringId(name);
    if (nameId == -1) {
      return const <SearchResult>[];
    }

    // Find the first usage of the name.
    int i = _findFirstOccurrence(index.usedNames, nameId);
    if (i == -1) {
      return const <SearchResult>[];
    }

    // Create results for every usage of the name.
    List<SearchResult> results = <SearchResult>[];
    CompilationUnitElement? enclosingUnitElement;
    for (; i < index.usedNames.length && index.usedNames[i] == nameId; i++) {
      IndexRelationKind relationKind = index.usedNameKinds[i];
      SearchResultKind? resultKind = relationToResultKind[relationKind];
      if (resultKind != null) {
        int offset = index.usedNameOffsets[i];
        enclosingUnitElement ??= await getEnclosingUnitElement();
        if (enclosingUnitElement != null) {
          Element enclosingElement =
              _getEnclosingElement(enclosingUnitElement, offset);
          results.add(SearchResult._(enclosingElement, resultKind, offset,
              name.length, false, index.usedNameIsQualifiedFlags[i]));
        }
      }
    }

    return results;
  }

  /// Return the identifier of the [uri] in the [index] or `-1` if the [uri] is
  /// not used in the [index].
  int getUriId(Uri uri) {
    String str = uri.toString();
    return getStringId(str);
  }

  /// Return the index of the first occurrence of the [value] in the
  /// [sortedList], or `-1` if the [value] is not in the list.
  int _findFirstOccurrence(List<int> sortedList, int value) {
    // Find an occurrence.
    int i = binarySearch(sortedList, value);
    if (i == -1) {
      return -1;
    }
    // Find the first occurrence.
    while (i > 0 && sortedList[i - 1] == value) {
      i--;
    }
    return i;
  }
}

/// Visitor that adds [SearchResult]s for local elements of a block, method,
/// class or a library - labels, local functions, local variables and
/// parameters, type parameters, import prefixes.
class _LocalReferencesVisitor extends RecursiveAstVisitor<void> {
  final List<SearchResult> results = <SearchResult>[];

  final Set<Element> elements;
  final CompilationUnitElement enclosingUnitElement;

  _LocalReferencesVisitor(this.elements, this.enclosingUnitElement);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) {
    if (elements.contains(node.element)) {
      _addResult(node, SearchResultKind.WRITE);
    }

    super.visitAssignedVariablePattern(node);
  }

  @override
  void visitExtensionOverride(ExtensionOverride node) {
    node.importPrefix?.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    final element = node.element;
    if (elements.contains(element)) {
      _addResult(node.name, SearchResultKind.REFERENCE);
    }
  }

  @override
  void visitNamedType(NamedType node) {
    final element = node.element;
    if (elements.contains(element)) {
      _addResult(node.name2, SearchResultKind.REFERENCE);
    }

    node.importPrefix?.accept(this);
    node.typeArguments?.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    var element = node.staticElement;
    if (elements.contains(element)) {
      var parent = node.parent;
      SearchResultKind kind = SearchResultKind.REFERENCE;
      if (element is FunctionElement) {
        if (parent is MethodInvocation && parent.methodName == node) {
          kind = SearchResultKind.INVOCATION;
        }
      } else if (element is VariableElement) {
        bool isGet = node.inGetterContext();
        bool isSet = node.inSetterContext();
        if (isGet && isSet) {
          kind = SearchResultKind.READ_WRITE;
        } else if (isGet) {
          if (parent is MethodInvocation && parent.methodName == node) {
            kind = SearchResultKind.INVOCATION;
          } else {
            kind = SearchResultKind.READ;
          }
        } else if (isSet) {
          kind = SearchResultKind.WRITE;
        }
      }
      _addResult(node, kind);
    }
  }

  void _addResult(SyntacticEntity entity, SearchResultKind kind) {
    bool isQualified = entity is AstNode ? entity.parent is Label : false;
    Element enclosingElement =
        _getEnclosingElement(enclosingUnitElement, entity.offset);
    results.add(SearchResult._(enclosingElement, kind, entity.offset,
        entity.length, true, isQualified));
  }
}

/// The marker class that is thrown to stop adding declarations.
class _MaxNumberOfDeclarationsError {
  const _MaxNumberOfDeclarationsError();
}
