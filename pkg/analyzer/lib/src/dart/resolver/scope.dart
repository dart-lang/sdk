// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.resolver.scope;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * The scope defined by a block.
 */
class BlockScope extends EnclosedScope {
  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope],
   * based on the given [block].
   */
  BlockScope(Scope enclosingScope, Block block) : super(enclosingScope) {
    if (block == null) {
      throw new ArgumentError("block cannot be null");
    }
    _defineElements(block);
  }

  void _defineElements(Block block) {
    for (Element element in elementsInBlock(block)) {
      define(element);
    }
  }

  /**
   * Return the elements that are declared directly in the given [block]. This
   * does not include elements declared in nested blocks.
   */
  static Iterable<Element> elementsInBlock(Block block) sync* {
    NodeList<Statement> statements = block.statements;
    int statementCount = statements.length;
    for (int i = 0; i < statementCount; i++) {
      Statement statement = statements[i];
      if (statement is VariableDeclarationStatement) {
        NodeList<VariableDeclaration> variables = statement.variables.variables;
        int variableCount = variables.length;
        for (int j = 0; j < variableCount; j++) {
          yield variables[j].element;
        }
      } else if (statement is FunctionDeclarationStatement) {
        yield statement.functionDeclaration.element;
      }
    }
  }
}

/**
 * The scope defined by a class.
 */
class ClassScope extends EnclosedScope {
  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope],
   * based on the given [classElement].
   */
  ClassScope(Scope enclosingScope, ClassElement classElement)
      : super(enclosingScope) {
    if (classElement == null) {
      throw new ArgumentError("class element cannot be null");
    }
    _defineMembers(classElement);
  }

  @override
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PropertyAccessorElement && duplicate is MethodElement) {
      if (existing.nameOffset < duplicate.nameOffset) {
        return new AnalysisError(
            duplicate.source,
            duplicate.nameOffset,
            duplicate.nameLength,
            CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME,
            [existing.displayName]);
      } else {
        return new AnalysisError(
            existing.source,
            existing.nameOffset,
            existing.nameLength,
            CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME,
            [existing.displayName]);
      }
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Define the instance members defined by the given [classElement].
   */
  void _defineMembers(ClassElement classElement) {
    List<PropertyAccessorElement> accessors = classElement.accessors;
    int accessorLength = accessors.length;
    for (int i = 0; i < accessorLength; i++) {
      define(accessors[i]);
    }
    List<MethodElement> methods = classElement.methods;
    int methodLength = methods.length;
    for (int i = 0; i < methodLength; i++) {
      define(methods[i]);
    }
  }
}

/**
 * The scope defined for the initializers in a constructor.
 */
class ConstructorInitializerScope extends EnclosedScope {
  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope].
   */
  ConstructorInitializerScope(Scope enclosingScope, ConstructorElement element)
      : super(enclosingScope) {
    _initializeFieldFormalParameters(element);
  }

  /**
   * Initialize the local scope with all of the field formal parameters.
   */
  void _initializeFieldFormalParameters(ConstructorElement element) {
    for (ParameterElement parameter in element.parameters) {
      if (parameter is FieldFormalParameterElement) {
        define(parameter);
      }
    }
  }
}

/**
 * A scope that is lexically enclosed in another scope.
 */
class EnclosedScope extends Scope {
  /**
   * The scope in which this scope is lexically enclosed.
   */
  @override
  final Scope enclosingScope;

  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope].
   */
  EnclosedScope(this.enclosingScope);

  @override
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    // Check enclosing scope.
    return enclosingScope.internalLookup(identifier, name, referencingLibrary);
  }

  @override
  Element _internalLookupPrefixed(PrefixedIdentifier identifier, String prefix,
      String name, LibraryElement referencingLibrary) {
    return enclosingScope._internalLookupPrefixed(
        identifier, prefix, name, referencingLibrary);
  }
}

/**
 * The scope defined by a function.
 */
class FunctionScope extends EnclosedScope {
  /**
   * The element representing the function that defines this scope.
   */
  final FunctionTypedElement _functionElement;

  /**
   * A flag indicating whether the parameters have already been defined, used to
   * prevent the parameters from being defined multiple times.
   */
  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope],
   * that represents the given [_functionElement].
   */
  FunctionScope(Scope enclosingScope, this._functionElement)
      : super(new EnclosedScope(new EnclosedScope(enclosingScope))) {
    if (_functionElement == null) {
      throw new ArgumentError("function element cannot be null");
    }
    _defineTypeParameters();
  }

  /**
   * Define the parameters for the given function in the scope that encloses
   * this function.
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    Scope parameterScope = enclosingScope;
    List<ParameterElement> parameters = _functionElement.parameters;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      if (!parameter.isInitializingFormal) {
        parameterScope.define(parameter);
      }
    }
  }

  /**
   * Define the type parameters for the function.
   */
  void _defineTypeParameters() {
    Scope typeParameterScope = enclosingScope.enclosingScope;
    List<TypeParameterElement> typeParameters = _functionElement.typeParameters;
    int length = typeParameters.length;
    for (int i = 0; i < length; i++) {
      TypeParameterElement typeParameter = typeParameters[i];
      typeParameterScope.define(typeParameter);
    }
  }
}

/**
 * The scope defined by a function type alias.
 */
class FunctionTypeScope extends EnclosedScope {
  final FunctionTypeAliasElement _typeElement;

  bool _parametersDefined = false;

  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope],
   * that represents the given [_typeElement].
   */
  FunctionTypeScope(Scope enclosingScope, this._typeElement)
      : super(new EnclosedScope(enclosingScope)) {
    _defineTypeParameters();
  }

  /**
   * Define the parameters for the function type alias.
   */
  void defineParameters() {
    if (_parametersDefined) {
      return;
    }
    _parametersDefined = true;
    for (ParameterElement parameter in _typeElement.parameters) {
      define(parameter);
    }
  }

  /**
   * Define the type parameters for the function type alias.
   */
  void _defineTypeParameters() {
    Scope typeParameterScope = enclosingScope;
    for (TypeParameterElement typeParameter in _typeElement.typeParameters) {
      typeParameterScope.define(typeParameter);
    }
  }
}

/**
 * The scope statements that can be the target of unlabeled `break` and
 * `continue` statements.
 */
class ImplicitLabelScope {
  /**
   * The implicit label scope associated with the top level of a function.
   */
  static const ImplicitLabelScope ROOT = const ImplicitLabelScope._(null, null);

  /**
   * The implicit label scope enclosing this implicit label scope.
   */
  final ImplicitLabelScope outerScope;

  /**
   * The statement that acts as a target for break and/or continue statements
   * at this scoping level.
   */
  final Statement statement;

  /**
   * Initialize a newly created scope, enclosed within the [outerScope],
   * representing the given [statement].
   */
  const ImplicitLabelScope._(this.outerScope, this.statement);

  /**
   * Return the statement which should be the target of an unlabeled `break` or
   * `continue` statement, or `null` if there is no appropriate target.
   */
  Statement getTarget(bool isContinue) {
    if (outerScope == null) {
      // This scope represents the toplevel of a function body, so it doesn't
      // match either break or continue.
      return null;
    }
    if (isContinue && statement is SwitchStatement) {
      return outerScope.getTarget(isContinue);
    }
    return statement;
  }

  /**
   * Initialize a newly created scope to represent a switch statement or loop
   * nested within the current scope.  [statement] is the statement associated
   * with the newly created scope.
   */
  ImplicitLabelScope nest(Statement statement) =>
      new ImplicitLabelScope._(this, statement);
}

/**
 * A scope in which a single label is defined.
 */
class LabelScope {
  /**
   * The label scope enclosing this label scope.
   */
  final LabelScope _outerScope;

  /**
   * The label defined in this scope.
   */
  final String _label;

  /**
   * The element to which the label resolves.
   */
  final LabelElement element;

  /**
   * The AST node to which the label resolves.
   */
  final AstNode node;

  /**
   * Initialize a newly created scope, enclosed within the [_outerScope],
   * representing the label [_label]. The [node] is the AST node the label
   * resolves to. The [element] is the element the label resolves to.
   */
  LabelScope(this._outerScope, this._label, this.node, this.element);

  /**
   * Return the LabelScope which defines [targetLabel], or `null` if it is not
   * defined in this scope.
   */
  LabelScope lookup(String targetLabel) {
    if (_label == targetLabel) {
      return this;
    }
    return _outerScope?.lookup(targetLabel);
  }
}

/**
 * The scope containing all of the names available from imported libraries.
 */
class LibraryImportScope extends Scope {
  /**
   * The name of the property containing a list of the elements from the SDK
   * that conflict with the single name imported from non-SDK libraries. The
   * value of the property is always of type `List<Element>`.
   */
  static const String conflictingSdkElements = 'conflictingSdkElements';

  /**
   * The element representing the library in which this scope is enclosed.
   */
  final LibraryElement _definingLibrary;

  /**
   * A list of the namespaces representing the names that are available in this scope from imported
   * libraries.
   */
  List<Namespace> _importedNamespaces;

  /**
   * A table mapping prefixes that have been referenced to a map from the names
   * that have been referenced to the element associated with the prefixed name.
   */
  Map<String, Map<String, Element>> _definedPrefixedNames;

  /**
   * Initialize a newly created scope representing the names imported into the
   * [_definingLibrary].
   */
  LibraryImportScope(this._definingLibrary) {
    _createImportedNamespaces();
  }

  @override
  void define(Element element) {
    if (!Scope.isPrivateName(element.displayName)) {
      super.define(element);
    }
  }

  @override
  Source getSource(AstNode node) {
    Source source = super.getSource(node);
    if (source == null) {
      source = _definingLibrary.definingCompilationUnit.source;
    }
    return source;
  }

  @override
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary) {
    Element element = localLookup(name, referencingLibrary);
    if (element != null) {
      return element;
    }
    element = _lookupInImportedNamespaces(
        identifier, (Namespace namespace) => namespace.get(name));
    if (element != null) {
      defineNameWithoutChecking(name, element);
    }
    return element;
  }

  @override
  bool shouldIgnoreUndefined(Identifier node) {
    Iterable<NamespaceCombinator> getShowCombinators(
            ImportElement importElement) =>
        importElement.combinators.where((NamespaceCombinator combinator) =>
            combinator is ShowElementCombinator);
    if (node is PrefixedIdentifier) {
      String prefix = node.prefix.name;
      String name = node.identifier.name;
      List<ImportElement> imports = _definingLibrary.imports;
      int count = imports.length;
      for (int i = 0; i < count; i++) {
        ImportElement importElement = imports[i];
        if (importElement.prefix?.name == prefix &&
            importElement.importedLibrary?.isSynthetic != false) {
          Iterable<NamespaceCombinator> showCombinators =
              getShowCombinators(importElement);
          if (showCombinators.isEmpty) {
            return true;
          }
          for (ShowElementCombinator combinator in showCombinators) {
            if (combinator.shownNames.contains(name)) {
              return true;
            }
          }
        }
      }
    } else if (node is SimpleIdentifier) {
      String name = node.name;
      List<ImportElement> imports = _definingLibrary.imports;
      int count = imports.length;
      for (int i = 0; i < count; i++) {
        ImportElement importElement = imports[i];
        if (importElement.prefix == null &&
            importElement.importedLibrary?.isSynthetic != false) {
          for (ShowElementCombinator combinator
              in getShowCombinators(importElement)) {
            if (combinator.shownNames.contains(name)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /**
   * Create all of the namespaces associated with the libraries imported into
   * this library. The names are not added to this scope, but are stored for
   * later reference.
   */
  void _createImportedNamespaces() {
    NamespaceBuilder builder = new NamespaceBuilder();
    List<ImportElement> imports = _definingLibrary.imports;
    int count = imports.length;
    _importedNamespaces = new List<Namespace>(count);
    for (int i = 0; i < count; i++) {
      _importedNamespaces[i] =
          builder.createImportNamespaceForDirective(imports[i]);
    }
  }

  /**
   * Add the given [element] to this scope without checking for duplication or
   * hiding.
   */
  void _definePrefixedNameWithoutChecking(
      String prefix, String name, Element element) {
    _definedPrefixedNames ??= new HashMap<String, Map<String, Element>>();
    Map<String, Element> unprefixedNames = _definedPrefixedNames.putIfAbsent(
        prefix, () => new HashMap<String, Element>());
    unprefixedNames[name] = element;
  }

  @override
  Element _internalLookupPrefixed(PrefixedIdentifier identifier, String prefix,
      String name, LibraryElement referencingLibrary) {
    Element element = _localPrefixedLookup(prefix, name);
    if (element != null) {
      return element;
    }
    element = _lookupInImportedNamespaces(identifier.identifier,
        (Namespace namespace) => namespace.getPrefixed(prefix, name));
    if (element != null) {
      _definePrefixedNameWithoutChecking(prefix, name, element);
    }
    return element;
  }

  /**
   * Return the element with which the given [prefix] and [name] are associated,
   * or `null` if the name is not defined within this scope.
   */
  Element _localPrefixedLookup(String prefix, String name) {
    if (_definedPrefixedNames != null) {
      Map<String, Element> unprefixedNames = _definedPrefixedNames[prefix];
      if (unprefixedNames != null) {
        return unprefixedNames[name];
      }
    }
    return null;
  }

  Element _lookupInImportedNamespaces(
      Identifier identifier, Element lookup(Namespace namespace)) {
    Set<Element> sdkElements = new HashSet<Element>();
    Set<Element> nonSdkElements = new HashSet<Element>();
    for (int i = 0; i < _importedNamespaces.length; i++) {
      Element element = lookup(_importedNamespaces[i]);
      if (element != null) {
        if (element.library.isInSdk) {
          sdkElements.add(element);
        } else {
          nonSdkElements.add(element);
        }
      }
    }
    int nonSdkCount = nonSdkElements.length;
    int sdkCount = sdkElements.length;
    if (nonSdkCount == 0) {
      if (sdkCount == 0) {
        return null;
      } else if (sdkCount == 1) {
        return sdkElements.first;
      }
    }
    if (nonSdkCount == 1) {
      if (sdkCount > 0) {
        identifier.setProperty(
            conflictingSdkElements, sdkElements.toList(growable: false));
      }
      return nonSdkElements.first;
    }
    return new MultiplyDefinedElementImpl(
        _definingLibrary.context,
        sdkElements.toList(growable: false),
        nonSdkElements.toList(growable: false));
  }
}

/**
 * A scope containing all of the names defined in a given library.
 */
class LibraryScope extends EnclosedScope {
  /**
   * Initialize a newly created scope representing the names defined in the
   * [definingLibrary].
   */
  LibraryScope(LibraryElement definingLibrary)
      : super(new LibraryImportScope(definingLibrary)) {
    _defineTopLevelNames(definingLibrary);
  }

  @override
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    if (existing is PrefixElement) {
      // TODO(scheglov) consider providing actual 'nameOffset' from the
      // synthetic accessor
      int offset = duplicate.nameOffset;
      if (duplicate is PropertyAccessorElement) {
        PropertyAccessorElement accessor = duplicate;
        if (accessor.isSynthetic) {
          offset = accessor.variable.nameOffset;
        }
      }
      return new AnalysisError(
          duplicate.source,
          offset,
          duplicate.nameLength,
          CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER,
          [existing.displayName]);
    }
    return super.getErrorForDuplicate(existing, duplicate);
  }

  /**
   * Add to this scope all of the public top-level names that are defined in the
   * given [compilationUnit].
   */
  void _defineLocalNames(CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      define(element);
    }
    for (ClassElement element in compilationUnit.enums) {
      define(element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      define(element);
    }
    for (FunctionTypeAliasElement element
        in compilationUnit.functionTypeAliases) {
      define(element);
    }
    for (ClassElement element in compilationUnit.types) {
      define(element);
    }
  }

  /**
   * Add to this scope all of the names that are explicitly defined in the
   * [definingLibrary].
   */
  void _defineTopLevelNames(LibraryElement definingLibrary) {
    for (PrefixElement prefix in definingLibrary.prefixes) {
      define(prefix);
    }
    _defineLocalNames(definingLibrary.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in definingLibrary.parts) {
      _defineLocalNames(compilationUnit);
    }
  }
}

/**
 * A mapping of identifiers to the elements represented by those identifiers.
 * Namespaces are the building blocks for scopes.
 */
class Namespace {
  /**
   * An empty namespace.
   */
  static Namespace EMPTY = new Namespace(new HashMap<String, Element>());

  /**
   * A table mapping names that are defined in this namespace to the element
   * representing the thing declared with that name.
   */
  final Map<String, Element> _definedNames;

  /**
   * Initialize a newly created namespace to have the [_definedNames].
   */
  Namespace(this._definedNames);

  /**
   * Return a table containing the same mappings as those defined by this
   * namespace.
   */
  Map<String, Element> get definedNames => _definedNames;

  /**
   * Return the element in this namespace that is available to the containing
   * scope using the given name, or `null` if there is no such element.
   */
  Element get(String name) => _definedNames[name];

  /**
   * Return the element in this namespace whose name is the result of combining
   * the [prefix] and the [name], separated by a period, or `null` if there is
   * no such element.
   */
  Element getPrefixed(String prefix, String name) => null;
}

/**
 * The builder used to build a namespace. Namespace builders are thread-safe and
 * re-usable.
 */
class NamespaceBuilder {
  /**
   * Create a namespace representing the export namespace of the given [element].
   */
  Namespace createExportNamespaceForDirective(ExportElement element) {
    LibraryElement exportedLibrary = element.exportedLibrary;
    if (exportedLibrary == null) {
      //
      // The exported library will be null if the URI does not reference a valid
      // library.
      //
      return Namespace.EMPTY;
    }
    Map<String, Element> exportedNames = _getExportMapping(exportedLibrary);
    exportedNames = _applyCombinators(exportedNames, element.combinators);
    return new Namespace(exportedNames);
  }

  /**
   * Create a namespace representing the export namespace of the given [library].
   */
  Namespace createExportNamespaceForLibrary(LibraryElement library) {
    Map<String, Element> exportedNames = _getExportMapping(library);
    return new Namespace(exportedNames);
  }

  /**
   * Create a namespace representing the import namespace of the given [element].
   */
  Namespace createImportNamespaceForDirective(ImportElement element) {
    LibraryElement importedLibrary = element.importedLibrary;
    if (importedLibrary == null) {
      //
      // The imported library will be null if the URI does not reference a valid
      // library.
      //
      return Namespace.EMPTY;
    }
    Map<String, Element> exportedNames = _getExportMapping(importedLibrary);
    exportedNames = _applyCombinators(exportedNames, element.combinators);
    PrefixElement prefix = element.prefix;
    if (prefix != null) {
      return new PrefixedNamespace(prefix.name, exportedNames);
    }
    return new Namespace(exportedNames);
  }

  /**
   * Create a namespace representing the public namespace of the given
   * [library].
   */
  Namespace createPublicNamespaceForLibrary(LibraryElement library) {
    Map<String, Element> definedNames = new HashMap<String, Element>();
    _addPublicNames(definedNames, library.definingCompilationUnit);
    for (CompilationUnitElement compilationUnit in library.parts) {
      _addPublicNames(definedNames, compilationUnit);
    }
    return new Namespace(definedNames);
  }

  /**
   * Add all of the names in the given [namespace] to the table of
   * [definedNames].
   */
  void _addAllFromNamespace(
      Map<String, Element> definedNames, Namespace namespace) {
    if (namespace != null) {
      definedNames.addAll(namespace.definedNames);
    }
  }

  /**
   * Add the given [element] to the table of [definedNames] if it has a
   * publicly visible name.
   */
  void _addIfPublic(Map<String, Element> definedNames, Element element) {
    String name = element.name;
    if (name != null && !Scope.isPrivateName(name)) {
      definedNames[name] = element;
    }
  }

  /**
   * Add to the table of [definedNames] all of the public top-level names that
   * are defined in the given [compilationUnit].
   *          namespace
   */
  void _addPublicNames(Map<String, Element> definedNames,
      CompilationUnitElement compilationUnit) {
    for (PropertyAccessorElement element in compilationUnit.accessors) {
      _addIfPublic(definedNames, element);
    }
    for (ClassElement element in compilationUnit.enums) {
      _addIfPublic(definedNames, element);
    }
    for (FunctionElement element in compilationUnit.functions) {
      _addIfPublic(definedNames, element);
    }
    for (FunctionTypeAliasElement element
        in compilationUnit.functionTypeAliases) {
      _addIfPublic(definedNames, element);
    }
    for (ClassElement element in compilationUnit.types) {
      _addIfPublic(definedNames, element);
    }
  }

  /**
   * Apply the given [combinators] to all of the names in the given table of
   * [definedNames].
   */
  Map<String, Element> _applyCombinators(Map<String, Element> definedNames,
      List<NamespaceCombinator> combinators) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        definedNames = _hide(definedNames, combinator.hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = _show(definedNames, combinator.shownNames);
      } else {
        // Internal error.
        AnalysisEngine.instance.logger
            .logError("Unknown type of combinator: ${combinator.runtimeType}");
      }
    }
    return definedNames;
  }

  /**
   * Create a mapping table representing the export namespace of the given
   * [library]. The set of [visitedElements] contains the libraries that do not
   * need to be visited when processing the export directives of the given
   * library because all of the names defined by them will be added by another
   * library.
   */
  Map<String, Element> _computeExportMapping(
      LibraryElement library, HashSet<LibraryElement> visitedElements) {
    visitedElements.add(library);
    try {
      Map<String, Element> definedNames = new HashMap<String, Element>();
      for (ExportElement element in library.exports) {
        LibraryElement exportedLibrary = element.exportedLibrary;
        if (exportedLibrary != null &&
            !visitedElements.contains(exportedLibrary)) {
          //
          // The exported library will be null if the URI does not reference a
          // valid library.
          //
          Map<String, Element> exportedNames =
              _computeExportMapping(exportedLibrary, visitedElements);
          exportedNames = _applyCombinators(exportedNames, element.combinators);
          definedNames.addAll(exportedNames);
        }
      }
      _addAllFromNamespace(
          definedNames,
          (library.context as InternalAnalysisContext)
              .getPublicNamespace(library));
      return definedNames;
    } finally {
      visitedElements.remove(library);
    }
  }

  Map<String, Element> _getExportMapping(LibraryElement library) {
    if (library.exportNamespace != null) {
      return library.exportNamespace.definedNames;
    }
    if (library is LibraryElementImpl) {
      Map<String, Element> exportMapping =
          _computeExportMapping(library, new HashSet<LibraryElement>());
      library.exportNamespace = new Namespace(exportMapping);
      return exportMapping;
    }
    return _computeExportMapping(library, new HashSet<LibraryElement>());
  }

  /**
   * Return a new map of names which has all the names from [definedNames]
   * with exception of [hiddenNames].
   */
  Map<String, Element> _hide(
      Map<String, Element> definedNames, List<String> hiddenNames) {
    Map<String, Element> newNames =
        new HashMap<String, Element>.from(definedNames);
    for (String name in hiddenNames) {
      newNames.remove(name);
      newNames.remove("$name=");
    }
    return newNames;
  }

  /**
   * Return a new map of names which has only [shownNames] from [definedNames].
   */
  Map<String, Element> _show(
      Map<String, Element> definedNames, List<String> shownNames) {
    Map<String, Element> newNames = new HashMap<String, Element>();
    for (String name in shownNames) {
      Element element = definedNames[name];
      if (element != null) {
        newNames[name] = element;
      }
      String setterName = "$name=";
      element = definedNames[setterName];
      if (element != null) {
        newNames[setterName] = element;
      }
    }
    return newNames;
  }
}

/**
 * A mapping of identifiers to the elements represented by those identifiers.
 * Namespaces are the building blocks for scopes.
 */
class PrefixedNamespace implements Namespace {
  /**
   * The prefix that is prepended to each of the defined names.
   */
  final String _prefix;

  /**
   * The length of the prefix.
   */
  final int _length;

  /**
   * A table mapping names that are defined in this namespace to the element
   * representing the thing declared with that name.
   */
  final Map<String, Element> _definedNames;

  /**
   * Initialize a newly created namespace to have the names resulting from
   * prefixing each of the [_definedNames] with the given [_prefix] (and a
   * period).
   */
  PrefixedNamespace(String prefix, this._definedNames)
      : _prefix = prefix,
        _length = prefix.length;

  @override
  Map<String, Element> get definedNames {
    Map<String, Element> definedNames = <String, Element>{};
    _definedNames.forEach((String name, Element element) {
      definedNames["$_prefix.$name"] = element;
    });
    return definedNames;
  }

  @override
  Element get(String name) {
    if (name.length > _length && name.startsWith(_prefix)) {
      if (name.codeUnitAt(_length) == '.'.codeUnitAt(0)) {
        return _definedNames[name.substring(_length + 1)];
      }
    }
    return null;
  }

  @override
  Element getPrefixed(String prefix, String name) {
    if (prefix == _prefix) {
      return _definedNames[name];
    }
    return null;
  }
}

/**
 * A name scope used by the resolver to determine which names are visible at any
 * given point in the code.
 */
abstract class Scope {
  /**
   * The prefix used to mark an identifier as being private to its library.
   */
  static int PRIVATE_NAME_PREFIX = 0x5F;

  /**
   * The suffix added to the declared name of a setter when looking up the
   * setter. Used to disambiguate between a getter and a setter that have the
   * same name.
   */
  static String SETTER_SUFFIX = "=";

  /**
   * The name used to look up the method used to implement the unary minus
   * operator. Used to disambiguate between the unary and binary operators.
   */
  static String UNARY_MINUS = "unary-";

  /**
   * A table mapping names that are defined in this scope to the element
   * representing the thing declared with that name.
   */
  Map<String, Element> _definedNames = null;

  /**
   * Return the scope in which this scope is lexically enclosed.
   */
  Scope get enclosingScope => null;

  /**
   * Add the given [element] to this scope. If there is already an element with
   * the given name defined in this scope, then the original element will
   * continue to be mapped to the name.
   */
  void define(Element element) {
    String name = _getName(element);
    if (name != null && !name.isEmpty) {
      _definedNames ??= new HashMap<String, Element>();
      _definedNames.putIfAbsent(name, () => element);
    }
  }

  /**
   * Add the given [element] to this scope without checking for duplication or
   * hiding.
   */
  void defineNameWithoutChecking(String name, Element element) {
    _definedNames ??= new HashMap<String, Element>();
    _definedNames[name] = element;
  }

  /**
   * Add the given [element] to this scope without checking for duplication or
   * hiding.
   */
  void defineWithoutChecking(Element element) {
    _definedNames ??= new HashMap<String, Element>();
    _definedNames[_getName(element)] = element;
  }

  /**
   * Return the error code to be used when reporting that a name being defined
   * locally conflicts with another element of the same name in the local scope.
   * [existing] is the first element to be declared with the conflicting name,
   * while [duplicate] another element declared with the conflicting name.
   */
  AnalysisError getErrorForDuplicate(Element existing, Element duplicate) {
    // TODO(brianwilkerson) Customize the error message based on the types of
    // elements that share the same name.
    // TODO(jwren) There are 4 error codes for duplicate, but only 1 is being
    // generated.
    Source source = duplicate.source;
    return new AnalysisError(source, duplicate.nameOffset, duplicate.nameLength,
        CompileTimeErrorCode.DUPLICATE_DEFINITION, [existing.displayName]);
  }

  /**
   * Return the source that contains the given [identifier], or the source
   * associated with this scope if the source containing the identifier could
   * not be determined.
   */
  Source getSource(AstNode identifier) {
    CompilationUnit unit =
        identifier.getAncestor((node) => node is CompilationUnit);
    if (unit != null) {
      CompilationUnitElement unitElement = unit.element;
      if (unitElement != null) {
        return unitElement.source;
      }
    }
    return null;
  }

  /**
   * Return the element with which the given [name] is associated, or `null` if
   * the name is not defined within this scope. The [identifier] is the
   * identifier node to lookup element for, used to report correct kind of a
   * problem and associate problem with. The [referencingLibrary] is the library
   * that contains the reference to the name, used to implement library-level
   * privacy.
   */
  Element internalLookup(
      Identifier identifier, String name, LibraryElement referencingLibrary);

  /**
   * Return the element with which the given [name] is associated, or `null` if
   * the name is not defined within this scope. This method only returns
   * elements that are directly defined within this scope, not elements that are
   * defined in an enclosing scope. The [referencingLibrary] is the library that
   * contains the reference to the name, used to implement library-level privacy.
   */
  Element localLookup(String name, LibraryElement referencingLibrary) {
    if (_definedNames != null) {
      return _definedNames[name];
    }
    return null;
  }

  /**
   * Return the element with which the given [identifier] is associated, or
   * `null` if the name is not defined within this scope. The
   * [referencingLibrary] is the library that contains the reference to the
   * name, used to implement library-level privacy.
   */
  Element lookup(Identifier identifier, LibraryElement referencingLibrary) {
    if (identifier is PrefixedIdentifier) {
      return _internalLookupPrefixed(identifier, identifier.prefix.name,
          identifier.identifier.name, referencingLibrary);
    }
    return internalLookup(identifier, identifier.name, referencingLibrary);
  }

  /**
   * Return `true` if the fact that the given [node] is not defined should be
   * ignored (from the perspective of error reporting). This will be the case if
   * there is at least one import that defines the node's prefix, and if that
   * import either has no show combinators or has a show combinator that
   * explicitly lists the node's name.
   */
  bool shouldIgnoreUndefined(Identifier node) {
    if (enclosingScope != null) {
      return enclosingScope.shouldIgnoreUndefined(node);
    }
    return false;
  }

  /**
   * Return the name that will be used to look up the given [element].
   */
  String _getName(Element element) {
    if (element is MethodElement) {
      MethodElement method = element;
      if (method.name == "-" && method.parameters.length == 0) {
        return UNARY_MINUS;
      }
    }
    return element.name;
  }

  /**
   * Return the element with which the given [prefix] and [name] are associated,
   * or `null` if the name is not defined within this scope. The [identifier] is
   * the identifier node to lookup element for, used to report correct kind of a
   * problem and associate problem with. The [referencingLibrary] is the library
   * that contains the reference to the name, used to implement library-level
   * privacy.
   */
  Element _internalLookupPrefixed(PrefixedIdentifier identifier, String prefix,
      String name, LibraryElement referencingLibrary);

  /**
   * Return `true` if the given [name] is a library-private name.
   */
  static bool isPrivateName(String name) =>
      name != null && StringUtilities.startsWithChar(name, PRIVATE_NAME_PREFIX);
}

/**
 * The scope defined by the type parameters in an element that defines type
 * parameters.
 */
class TypeParameterScope extends EnclosedScope {
  /**
   * Initialize a newly created scope, enclosed within the [enclosingScope],
   * that defines the type parameters from the given [element].
   */
  TypeParameterScope(Scope enclosingScope, TypeParameterizedElement element)
      : super(enclosingScope) {
    if (element == null) {
      throw new ArgumentError("element cannot be null");
    }
    _defineTypeParameters(element);
  }

  /**
   * Define the type parameters declared by the [element].
   */
  void _defineTypeParameters(TypeParameterizedElement element) {
    for (TypeParameterElement typeParameter in element.typeParameters) {
      define(typeParameter);
    }
  }
}
