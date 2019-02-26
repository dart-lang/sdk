// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/index.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:collection/collection.dart';

Element _getEnclosingElement(CompilationUnitElement unitElement, int offset) {
  var finder = new _ContainingElementFinder(offset);
  unitElement.accept(finder);
  Element element = finder.containingElement;
  assert(element != null,
      'No containing element in ${unitElement.source.fullName} at $offset');
  return element;
}

/**
 * An element declaration.
 */
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
  final String className;
  final String mixinName;
  final String parameters;

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
      this.parameters);
}

/**
 * The kind of a [Declaration].
 */
enum DeclarationKind {
  CLASS,
  CLASS_TYPE_ALIAS,
  CONSTRUCTOR,
  ENUM,
  ENUM_CONSTANT,
  FIELD,
  FUNCTION,
  FUNCTION_TYPE_ALIAS,
  GETTER,
  METHOD,
  MIXIN,
  SETTER,
  VARIABLE
}

/**
 * Search support for an [AnalysisDriver].
 */
class Search {
  final AnalysisDriver _driver;

  Search(this._driver);

  /**
   * Returns class or mixin members with the given [name].
   */
  Future<List<Element>> classMembers(String name) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<Element> elements = <Element>[];

    void addElement(Element element) {
      if (!element.isSynthetic && element.displayName == name) {
        elements.add(element);
      }
    }

    void addElements(ClassElement element) {
      element.accessors.forEach(addElement);
      element.fields.forEach(addElement);
      element.methods.forEach(addElement);
    }

    List<String> files = await _driver.getFilesDefiningClassMemberName(name);
    for (String file in files) {
      UnitElementResult unitResult = await _driver.getUnitElement(file);
      if (unitResult != null) {
        unitResult.element.types.forEach(addElements);
        unitResult.element.mixins.forEach(addElements);
      }
    }
    return elements;
  }

  /**
   * Return top-level and class member declarations.
   *
   * If [regExp] is not `null`, only declaration with names matching it are
   * returned. Otherwise, all declarations are returned.
   *
   * If [maxResults] is not `null`, it sets the maximum number of returned
   * declarations.
   *
   * The path of each file with at least one declaration is added to [files].
   */
  Future<List<Declaration>> declarations(
      RegExp regExp, int maxResults, LinkedHashSet<String> files,
      {String onlyForFile}) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<Declaration> declarations = <Declaration>[];

    DeclarationKind getExecutableKind(
        UnlinkedExecutable executable, bool topLevel) {
      switch (executable.kind) {
        case UnlinkedExecutableKind.constructor:
          return DeclarationKind.CONSTRUCTOR;
        case UnlinkedExecutableKind.functionOrMethod:
          if (topLevel) {
            return DeclarationKind.FUNCTION;
          }
          return DeclarationKind.METHOD;
        case UnlinkedExecutableKind.getter:
          return DeclarationKind.GETTER;
          break;
        default:
          return DeclarationKind.SETTER;
      }
    }

    await _driver.discoverAvailableFiles();

    try {
      List<FileState> knownFiles = _driver.fsState.knownFiles.toList();
      for (FileState file in knownFiles) {
        if (onlyForFile != null && file.path != onlyForFile) {
          continue;
        }
        if (files.contains(file.path)) {
          continue;
        }

        int fileIndex;

        void addDeclaration(String name, DeclarationKind kind, int offset,
            int codeOffset, int codeLength,
            {String className, String mixinName, String parameters}) {
          if (maxResults != null && declarations.length >= maxResults) {
            throw const _MaxNumberOfDeclarationsError();
          }

          if (name.endsWith('=')) {
            name = name.substring(0, name.length - 1);
          }
          if (regExp != null && !regExp.hasMatch(name)) {
            return;
          }

          if (fileIndex == null) {
            fileIndex = files.length;
            files.add(file.path);
          }

          var location = file.lineInfo.getLocation(offset);
          declarations.add(new Declaration(
              fileIndex,
              file.lineInfo,
              name,
              kind,
              offset,
              location.lineNumber,
              location.columnNumber,
              codeOffset,
              codeLength,
              className,
              mixinName,
              parameters));
        }

        UnlinkedUnit unlinkedUnit = file.unlinked;
        var parameterComposer = new _UnlinkedParameterComposer(unlinkedUnit);

        String getParametersString(List<UnlinkedParam> parameters) {
          parameterComposer.clear();
          parameterComposer.appendParameters(parameters);
          return parameterComposer.buffer.toString();
        }

        String getExecutableParameters(UnlinkedExecutable executable) {
          if (executable.kind == UnlinkedExecutableKind.getter) {
            return null;
          }
          return getParametersString(executable.parameters);
        }

        void addUnlinkedClass(UnlinkedClass class_, DeclarationKind kind,
            {String className, String mixinName}) {
          addDeclaration(class_.name, kind, class_.nameOffset,
              class_.codeRange.offset, class_.codeRange.length);

          parameterComposer.outerTypeParameters = class_.typeParameters;

          for (var field in class_.fields) {
            addDeclaration(field.name, DeclarationKind.FIELD, field.nameOffset,
                field.codeRange.offset, field.codeRange.length,
                className: className, mixinName: mixinName);
          }

          for (var executable in class_.executables) {
            parameterComposer.innerTypeParameters = executable.typeParameters;
            addDeclaration(
                executable.name,
                getExecutableKind(executable, false),
                executable.nameOffset,
                executable.codeRange.offset,
                executable.codeRange.length,
                className: className,
                mixinName: mixinName,
                parameters: getExecutableParameters(executable));
            parameterComposer.innerTypeParameters = const [];
          }

          parameterComposer.outerTypeParameters = const [];
        }

        for (var class_ in unlinkedUnit.classes) {
          var kind = class_.isMixinApplication
              ? DeclarationKind.CLASS_TYPE_ALIAS
              : DeclarationKind.CLASS;
          addUnlinkedClass(class_, kind, className: class_.name);
        }

        for (var mixin in unlinkedUnit.mixins) {
          addUnlinkedClass(mixin, DeclarationKind.MIXIN, mixinName: mixin.name);
        }

        for (var enum_ in unlinkedUnit.enums) {
          addDeclaration(enum_.name, DeclarationKind.ENUM, enum_.nameOffset,
              enum_.codeRange.offset, enum_.codeRange.length);
          for (var value in enum_.values) {
            addDeclaration(value.name, DeclarationKind.ENUM_CONSTANT,
                value.nameOffset, value.nameOffset, value.name.length);
          }
        }

        for (var executable in unlinkedUnit.executables) {
          parameterComposer.outerTypeParameters = executable.typeParameters;
          addDeclaration(
              executable.name,
              getExecutableKind(executable, true),
              executable.nameOffset,
              executable.codeRange.offset,
              executable.codeRange.length,
              parameters: getExecutableParameters(executable));
        }

        for (var typedef_ in unlinkedUnit.typedefs) {
          parameterComposer.outerTypeParameters = typedef_.typeParameters;
          addDeclaration(
              typedef_.name,
              DeclarationKind.FUNCTION_TYPE_ALIAS,
              typedef_.nameOffset,
              typedef_.codeRange.offset,
              typedef_.codeRange.length,
              parameters: getParametersString(typedef_.parameters));
          parameterComposer.outerTypeParameters = const [];
        }

        for (var variable in unlinkedUnit.variables) {
          addDeclaration(
              variable.name,
              DeclarationKind.VARIABLE,
              variable.nameOffset,
              variable.codeRange.offset,
              variable.codeRange.length);
        }
      }
    } on _MaxNumberOfDeclarationsError {}

    return declarations;
  }

  /**
   * Returns references to the [element].
   */
  Future<List<SearchResult>> references(
      Element element, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (element == null) {
      return const <SearchResult>[];
    }

    ElementKind kind = element.kind;
    if (kind == ElementKind.CLASS ||
        kind == ElementKind.CONSTRUCTOR ||
        kind == ElementKind.FUNCTION_TYPE_ALIAS ||
        kind == ElementKind.SETTER) {
      return _searchReferences(element, searchedFiles);
    } else if (kind == ElementKind.COMPILATION_UNIT) {
      return _searchReferences_CompilationUnit(element);
    } else if (kind == ElementKind.GETTER) {
      return _searchReferences_Getter(element, searchedFiles);
    } else if (kind == ElementKind.FIELD ||
        kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return _searchReferences_Field(element, searchedFiles);
    } else if (kind == ElementKind.FUNCTION || kind == ElementKind.METHOD) {
      if (element.enclosingElement is ExecutableElement) {
        return _searchReferences_Local(
            element, (n) => n is Block, searchedFiles);
      }
      return _searchReferences_Function(element, searchedFiles);
    } else if (kind == ElementKind.IMPORT) {
      return _searchReferences_Import(element, searchedFiles);
    } else if (kind == ElementKind.LABEL ||
        kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_Local(element, (n) => n is Block, searchedFiles);
    } else if (kind == ElementKind.LIBRARY) {
      return _searchReferences_Library(element, searchedFiles);
    } else if (kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element, searchedFiles);
    } else if (kind == ElementKind.PREFIX) {
      return _searchReferences_Prefix(element, searchedFiles);
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_Local(
          element, (n) => n.parent is CompilationUnit, searchedFiles);
    }
    return const <SearchResult>[];
  }

  /**
   * Returns subtypes of the given [type].
   *
   * The [searchedFiles] are consulted to see if a file is "owned" by this
   * [Search] object, so should be only searched by it to avoid duplicate
   * results; and updated to take ownership if the file is not owned yet.
   */
  Future<List<SearchResult>> subTypes(
      ClassElement type, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (type == null) {
      return const <SearchResult>[];
    }
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, type, searchedFiles, const {
      IndexRelationKind.IS_EXTENDED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_MIXED_IN_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_IMPLEMENTED_BY: SearchResultKind.REFERENCE
    });
    return results;
  }

  /**
   * Return direct [SubtypeResult]s for either the [type] or [subtype].
   */
  Future<List<SubtypeResult>> subtypes(
      {ClassElement type, SubtypeResult subtype}) async {
    String name;
    String id;
    if (type != null) {
      name = type.name;
      id = '${type.librarySource.uri};${type.source.uri};$name';
    } else {
      name = subtype.name;
      id = subtype.id;
    }

    await _driver.discoverAvailableFiles();

    final List<SubtypeResult> results = [];

    // Note, this is a defensive copy.
    var files = _driver.fsState.getFilesSubtypingName(name)?.toList();

    if (files != null) {
      for (FileState file in files) {
        AnalysisDriverUnitIndex index = await _driver.getIndex(file.path);
        if (index != null) {
          var request = new _IndexRequest(index);
          request.addSubtypes(id, results, file);
        }
      }
    }

    return results;
  }

  /**
   * Returns top-level elements with names matching the given [regExp].
   */
  Future<List<Element>> topLevelElements(RegExp regExp) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<Element> elements = <Element>[];

    void addElement(Element element) {
      if (!element.isSynthetic && regExp.hasMatch(element.displayName)) {
        elements.add(element);
      }
    }

    List<FileState> knownFiles = _driver.fsState.knownFiles.toList();
    for (FileState file in knownFiles) {
      UnitElementResult unitResult = await _driver.getUnitElement(file.path);
      if (unitResult != null) {
        CompilationUnitElement unitElement = unitResult.element;
        unitElement.accessors.forEach(addElement);
        unitElement.enums.forEach(addElement);
        unitElement.functions.forEach(addElement);
        unitElement.functionTypeAliases.forEach(addElement);
        unitElement.mixins.forEach(addElement);
        unitElement.topLevelVariables.forEach(addElement);
        unitElement.types.forEach(addElement);
      }
    }
    return elements;
  }

  /**
   * Returns unresolved references to the given [name].
   */
  Future<List<SearchResult>> unresolvedMemberReferences(
      String name, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (name == null) {
      return const <SearchResult>[];
    }

    // Prepare the list of files that reference the name.
    List<String> files = await _driver.getFilesReferencingName(name);

    // Check the index of every file that references the element name.
    List<SearchResult> results = [];
    for (String file in files) {
      if (searchedFiles.add(file, this)) {
        AnalysisDriverUnitIndex index = await _driver.getIndex(file);
        if (index != null) {
          _IndexRequest request = new _IndexRequest(index);
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
      Map<IndexRelationKind, SearchResultKind> relationToResultKind) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Prepare the element name.
    String name = element.displayName;
    if (element is ConstructorElement) {
      name = element.enclosingElement.displayName;
    }

    // Prepare the list of files that reference the element name.
    List<String> files = <String>[];
    String path = element.source.fullName;
    if (name.startsWith('_')) {
      String libraryPath = element.library.source.fullName;
      if (searchedFiles.add(libraryPath, this)) {
        FileState library = _driver.fsState.getFileForPath(libraryPath);
        for (FileState file in library.libraryFiles) {
          if (file.path == path || file.referencedNames.contains(name)) {
            files.add(file.path);
          }
        }
      }
    } else {
      files = await _driver.getFilesReferencingName(name);
      if (!files.contains(path)) {
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

  /**
   * Add results for [element] usage in the given [file].
   */
  Future<void> _addResultsInFile(
      List<SearchResult> results,
      Element element,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      String file) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    AnalysisDriverUnitIndex index = await _driver.getIndex(file);
    if (index != null) {
      _IndexRequest request = new _IndexRequest(index);
      int elementId = request.findElementId(element);
      if (elementId != -1) {
        List<SearchResult> fileResults = await request.getRelations(
            elementId, relationToResultKind, () => _getUnitElement(file));
        results.addAll(fileResults);
      }
    }
  }

  Future<CompilationUnitElement> _getUnitElement(String file) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    UnitElementResult result = await _driver.getUnitElement(file);
    return result?.element;
  }

  Future<List<SearchResult>> _searchReferences(
      Element element, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, element, searchedFiles,
        const {IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE});
    return results;
  }

  Future<List<SearchResult>> _searchReferences_CompilationUnit(
      CompilationUnitElement element) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String path = element.source.fullName;

    // If the path is not known, then the file is not referenced.
    if (!_driver.fsState.knownFilePaths.contains(path)) {
      return const <SearchResult>[];
    }

    // Check every file that references the given path.
    List<SearchResult> results = <SearchResult>[];
    List<FileState> knownFiles = _driver.fsState.knownFiles.toList();
    for (FileState file in knownFiles) {
      for (FileState referencedFile in file.directReferencedFiles) {
        if (referencedFile.path == path) {
          await _addResultsInFile(
              results,
              element,
              const {
                IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE
              },
              file.path);
        }
      }
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Field(
      PropertyInducingElement field, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> results = <SearchResult>[];
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
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
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, element, searchedFiles, const {
      IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
    });
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Getter(
      PropertyAccessorElement getter, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> results = <SearchResult>[];
    await _addResults(results, getter, searchedFiles, const {
      IndexRelationKind.IS_REFERENCED_BY: SearchResultKind.REFERENCE,
      IndexRelationKind.IS_INVOKED_BY: SearchResultKind.INVOCATION
    });
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Import(
      ImportElement element, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      ResolvedUnitResult unitResult = await _driver.getResult(unitPath);
      _ImportElementReferencesVisitor visitor =
          new _ImportElementReferencesVisitor(element, unitElement);
      unitResult.unit.accept(visitor);
      results.addAll(visitor.results);
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Library(
      LibraryElement element, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    for (CompilationUnitElement unitElement in element.units) {
      String unitPath = unitElement.source.fullName;
      ResolvedUnitResult unitResult = await _driver.getResult(unitPath);
      CompilationUnit unit = unitResult.unit;
      for (Directive directive in unit.directives) {
        if (directive is PartOfDirective && directive.element == element) {
          results.add(new SearchResult._(
              unit.declaredElement,
              SearchResultKind.REFERENCE,
              directive.libraryName.offset,
              directive.libraryName.length,
              true,
              false));
        }
      }
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Local(Element element,
      bool isRootNode(AstNode n), SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    // Prepare the unit.
    ResolvedUnitResult unitResult = await _driver.getResult(path);
    CompilationUnit unit = unitResult.unit;
    if (unit == null) {
      return const <SearchResult>[];
    }

    // Prepare the node.
    AstNode node = new NodeLocator(element.nameOffset).searchWithin(unit);
    if (node == null) {
      return const <SearchResult>[];
    }

    // Prepare the enclosing node.
    AstNode enclosingNode = node.thisOrAncestorMatching(isRootNode);
    if (enclosingNode == null) {
      return const <SearchResult>[];
    }

    // Find the matches.
    _LocalReferencesVisitor visitor =
        new _LocalReferencesVisitor(element, unit.declaredElement);
    enclosingNode.accept(visitor);
    return visitor.results;
  }

  Future<List<SearchResult>> _searchReferences_Parameter(
      ParameterElement parameter, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    List<SearchResult> results = <SearchResult>[];
    results.addAll(await _searchReferences_Local(
      parameter,
      (AstNode node) {
        AstNode parent = node.parent;
        return parent is ClassDeclaration || parent is CompilationUnit;
      },
      searchedFiles,
    ));
    if (parameter.isOptional) {
      results.addAll(await _searchReferences(parameter, searchedFiles));
    }
    return results;
  }

  Future<List<SearchResult>> _searchReferences_Prefix(
      PrefixElement element, SearchedFiles searchedFiles) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    String path = element.source.fullName;
    if (!searchedFiles.add(path, this)) {
      return const <SearchResult>[];
    }

    List<SearchResult> results = <SearchResult>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      ResolvedUnitResult unitResult = await _driver.getResult(unitPath);
      _LocalReferencesVisitor visitor =
          new _LocalReferencesVisitor(element, unitElement);
      unitResult.unit.accept(visitor);
      results.addAll(visitor.results);
    }
    return results;
  }
}

/**
 * Container that keeps track of file owners.
 */
class SearchedFiles {
  final Map<String, Search> pathOwners = {};
  final Map<Uri, Search> uriOwners = {};

  bool add(String path, Search search) {
    var file = search._driver.fsState.getFileForPath(path);
    var pathOwner = pathOwners[path];
    var uriOwner = uriOwners[file.uri];
    if (pathOwner == null && uriOwner == null) {
      pathOwners[path] = search;
      uriOwners[file.uri] = search;
      return true;
    }
    return identical(pathOwner, search) && identical(uriOwner, search);
  }

  void ownAdded(Search search) {
    for (var path in search._driver.addedFiles) {
      add(path, search);
    }
  }
}

/**
 * A single search result.
 */
class SearchResult {
  /**
   * The deep most element that contains this result.
   */
  final Element enclosingElement;

  /**
   * The kind of the [element] usage.
   */
  final SearchResultKind kind;

  /**
   * The offset relative to the beginning of the containing file.
   */
  final int offset;

  /**
   * The length of the usage in the containing file context.
   */
  final int length;

  /**
   * Is `true` if a field or a method is using with a qualifier.
   */
  final bool isResolved;

  /**
   * Is `true` if the result is a resolved reference to [element].
   */
  final bool isQualified;

  SearchResult._(this.enclosingElement, this.kind, this.offset, this.length,
      this.isResolved, this.isQualified)
      : assert(enclosingElement != null);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
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

/**
 * The kind of reference in a [SearchResult].
 */
enum SearchResultKind { READ, READ_WRITE, WRITE, INVOCATION, REFERENCE }

/**
 * A single subtype of a type.
 */
class SubtypeResult {
  /**
   * The URI of the library.
   */
  final String libraryUri;

  /**
   * The identifier of the subtype.
   */
  final String id;

  /**
   * The name of the subtype.
   */
  final String name;

  /**
   * The names of instance members declared in the class.
   */
  final List<String> members;

  SubtypeResult(this.libraryUri, this.id, this.name, this.members);

  @override
  String toString() => id;
}

/**
 * A visitor that finds the deep-most [Element] that contains the [offset].
 */
class _ContainingElementFinder extends GeneralizingElementVisitor {
  final int offset;
  Element containingElement;

  _ContainingElementFinder(this.offset);

  visitElement(Element element) {
    if (element is ElementImpl) {
      if (element.codeOffset != null &&
          element.codeOffset <= offset &&
          offset <= element.codeOffset + element.codeLength) {
        containingElement = element;
        super.visitElement(element);
      }
    }
  }
}

/**
 * Visitor that adds [SearchResult]s for references to the [importElement].
 */
class _ImportElementReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchResult> results = <SearchResult>[];

  final ImportElement importElement;
  final CompilationUnitElement enclosingUnitElement;

  Set<Element> importedElements;

  _ImportElementReferencesVisitor(
      ImportElement element, this.enclosingUnitElement)
      : importElement = element {
    importedElements = element.namespace.definedNames.values.toSet();
  }

  @override
  visitExportDirective(ExportDirective node) {}

  @override
  visitImportDirective(ImportDirective node) {}

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (importElement.prefix != null) {
      if (node.staticElement == importElement.prefix) {
        AstNode parent = node.parent;
        if (parent is PrefixedIdentifier && parent.prefix == node) {
          if (importedElements.contains(parent.staticElement)) {
            _addResultForPrefix(node, parent.identifier);
          }
        }
        if (parent is MethodInvocation && parent.target == node) {
          if (importedElements.contains(parent.methodName.staticElement)) {
            _addResultForPrefix(node, parent.methodName);
          }
        }
      }
    } else {
      if (importedElements.contains(node.staticElement)) {
        _addResult(node.offset, 0);
      }
    }
  }

  void _addResult(int offset, int length) {
    Element enclosingElement =
        _getEnclosingElement(enclosingUnitElement, offset);
    results.add(new SearchResult._(enclosingElement, SearchResultKind.REFERENCE,
        offset, length, true, false));
  }

  void _addResultForPrefix(SimpleIdentifier prefixNode, AstNode nextNode) {
    int prefixOffset = prefixNode.offset;
    _addResult(prefixOffset, nextNode.offset - prefixOffset);
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

    var library = file.library ?? file;
    for (; index.supertypes[superIndex] == superId; superIndex++) {
      var subtype = index.subtypes[superIndex];
      var name = index.strings[subtype.name];
      var subId = '${library.uriStr};${file.uriStr};$name';
      results.add(new SubtypeResult(
        library.uriStr,
        subId,
        name,
        subtype.members.map((m) => index.strings[m]).toList(),
      ));
    }
  }

  /**
   * Return the [element]'s identifier in the [index] or `-1` if the
   * [element] is not referenced in the [index].
   */
  int findElementId(Element element) {
    IndexElementInfo info = new IndexElementInfo(element);
    element = info.element;
    // Find the id of the element's unit.
    int unitId = getUnitId(element);
    if (unitId == -1) {
      return -1;
    }
    // Prepare information about the element.
    int unitMemberId = getElementUnitMemberId(element);
    if (unitMemberId == -1) {
      return -1;
    }
    int classMemberId = getElementClassMemberId(element);
    if (classMemberId == -1) {
      return -1;
    }
    int parameterId = getElementParameterId(element);
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

  /**
   * Return the [element]'s class member name identifier, `null` is not a class
   * member, or `-1` if the [element] is not referenced in the [index].
   */
  int getElementClassMemberId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element.enclosingElement is ClassElement) {
        return getStringId(element.name);
      }
    }
    return index.nullStringId;
  }

  /**
   * Return the [element]'s class member name identifier, `null` is not a class
   * member, or `-1` if the [element] is not referenced in the [index].
   */
  int getElementParameterId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element is ParameterElement) {
        return getStringId(element.name);
      }
    }
    return index.nullStringId;
  }

  /**
   * Return the [element]'s top-level name identifier, `0` is the unit, or
   * `-1` if the [element] is not referenced in the [index].
   */
  int getElementUnitMemberId(Element element) {
    for (; element != null; element = element.enclosingElement) {
      if (element.enclosingElement is CompilationUnitElement) {
        return getStringId(element.name);
      }
    }
    return index.nullStringId;
  }

  /**
   * Return a list of results where an element with the given [elementId] has
   * a relation with the kind from [relationToResultKind].
   *
   * The function [getEnclosingUnitElement] is used to lazily compute the
   * enclosing [CompilationUnitElement] if there is a relation of an
   * interesting kind.
   */
  Future<List<SearchResult>> getRelations(
      int elementId,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      Future<CompilationUnitElement> getEnclosingUnitElement()) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Find the first usage of the element.
    int i = _findFirstOccurrence(index.usedElements, elementId);
    if (i == -1) {
      return const <SearchResult>[];
    }
    // Create locations for every usage of the element.
    List<SearchResult> results = <SearchResult>[];
    CompilationUnitElement enclosingUnitElement = null;
    for (;
        i < index.usedElements.length && index.usedElements[i] == elementId;
        i++) {
      IndexRelationKind relationKind = index.usedElementKinds[i];
      SearchResultKind resultKind = relationToResultKind[relationKind];
      if (resultKind != null) {
        int offset = index.usedElementOffsets[i];
        enclosingUnitElement ??= await getEnclosingUnitElement();
        if (enclosingUnitElement != null) {
          Element enclosingElement =
              _getEnclosingElement(enclosingUnitElement, offset);
          results.add(new SearchResult._(
              enclosingElement,
              resultKind,
              offset,
              index.usedElementLengths[i],
              true,
              index.usedElementIsQualifiedFlags[i]));
        }
      }
    }
    return results;
  }

  /**
   * Return the identifier of [str] in the [index] or `-1` if [str] is not
   * used in the [index].
   */
  int getStringId(String str) {
    return binarySearch(index.strings, str);
  }

  /**
   * Return the identifier of the [CompilationUnitElement] containing the
   * [element] in the [index] or `-1` if not found.
   */
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

  /**
   * Return a list of results where a class members with the given [name] is
   * referenced with a qualifier, but is not resolved.
   */
  Future<List<SearchResult>> getUnresolvedMemberReferences(
      String name,
      Map<IndexRelationKind, SearchResultKind> relationToResultKind,
      Future<CompilationUnitElement> getEnclosingUnitElement()) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
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
    CompilationUnitElement enclosingUnitElement = null;
    for (; i < index.usedNames.length && index.usedNames[i] == nameId; i++) {
      IndexRelationKind relationKind = index.usedNameKinds[i];
      SearchResultKind resultKind = relationToResultKind[relationKind];
      if (resultKind != null) {
        int offset = index.usedNameOffsets[i];
        enclosingUnitElement ??= await getEnclosingUnitElement();
        if (enclosingUnitElement != null) {
          Element enclosingElement =
              _getEnclosingElement(enclosingUnitElement, offset);
          results.add(new SearchResult._(enclosingElement, resultKind, offset,
              name.length, false, index.usedNameIsQualifiedFlags[i]));
        }
      }
    }

    return results;
  }

  /**
   * Return the identifier of the [uri] in the [index] or `-1` if the [uri] is
   * not used in the [index].
   */
  int getUriId(Uri uri) {
    String str = uri.toString();
    return getStringId(str);
  }

  /**
   * Return the index of the first occurrence of the [value] in the [sortedList],
   * or `-1` if the [value] is not in the list.
   */
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

/**
 * Visitor that adds [SearchResult]s for local elements of a block, method,
 * class or a library - labels, local functions, local variables and parameters,
 * type parameters, import prefixes.
 */
class _LocalReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchResult> results = <SearchResult>[];

  final Element element;
  final CompilationUnitElement enclosingUnitElement;

  _LocalReferencesVisitor(this.element, this.enclosingUnitElement);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (node.staticElement == element) {
      AstNode parent = node.parent;
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

  void _addResult(AstNode node, SearchResultKind kind) {
    bool isQualified = node.parent is Label;
    Element enclosingElement =
        _getEnclosingElement(enclosingUnitElement, node.offset);
    results.add(new SearchResult._(
        enclosingElement, kind, node.offset, node.length, true, isQualified));
  }
}

/**
 * The marker class that is thrown to stop adding declarations.
 */
class _MaxNumberOfDeclarationsError {
  const _MaxNumberOfDeclarationsError();
}

/**
 * Helper for composing parameter strings.
 */
class _UnlinkedParameterComposer {
  final UnlinkedUnit unlinkedUnit;
  final StringBuffer buffer = new StringBuffer();

  List<UnlinkedTypeParam> outerTypeParameters = const [];
  List<UnlinkedTypeParam> innerTypeParameters = const [];

  _UnlinkedParameterComposer(this.unlinkedUnit);

  void appendParameter(UnlinkedParam parameter) {
    bool hasType = appendType(parameter.type);
    if (hasType && parameter.name.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(parameter.name);
    if (parameter.isFunctionTyped) {
      appendParameters(parameter.parameters);
    }
  }

  void appendParameters(List<UnlinkedParam> parameters) {
    buffer.write('(');

    bool isFirstParameter = true;
    for (var parameter in parameters) {
      if (isFirstParameter) {
        isFirstParameter = false;
      } else {
        buffer.write(', ');
      }
      appendParameter(parameter);
    }

    buffer.write(')');
  }

  bool appendType(EntityRef type) {
    EntityRefKind kind = type?.entityKind;
    if (kind == EntityRefKind.named) {
      if (type.reference != 0) {
        UnlinkedReference typeRef = unlinkedUnit.references[type.reference];
        buffer.write(typeRef.name);
        appendTypeArguments(type);
        return true;
      }
      if (type.paramReference != 0) {
        int ref = type.paramReference;
        if (ref <= innerTypeParameters.length) {
          var param = innerTypeParameters[innerTypeParameters.length - ref];
          buffer.write(param.name);
          return true;
        }
        ref -= innerTypeParameters.length;
        if (ref <= outerTypeParameters.length) {
          var param = outerTypeParameters[outerTypeParameters.length - ref];
          buffer.write(param.name);
          return true;
        }
        return false;
      }
    }
    if (kind == EntityRefKind.genericFunctionType) {
      if (appendType(type.syntheticReturnType)) {
        buffer.write(' ');
      }
      buffer.write('Function');
      appendParameters(type.syntheticParams);
      return true;
    }
    return false;
  }

  void appendTypeArguments(EntityRef type) {
    if (type.typeArguments.isNotEmpty) {
      buffer.write('<');
      bool first = true;
      for (var arguments in type.typeArguments) {
        if (first) {
          first = false;
        } else {
          buffer.write(', ');
        }
        appendType(arguments);
      }
      buffer.write('>');
    }
  }

  void clear() {
    buffer.clear();
  }
}
