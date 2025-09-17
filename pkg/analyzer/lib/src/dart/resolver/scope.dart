// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fine/requirements.dart';
import 'package:analyzer/src/generated/engine.dart';

/// The scope defined by a block.
class BlockScope {
  /// Return the elements that are declared directly in the given [statements].
  /// This does not include elements declared in nested blocks.
  static Iterable<Element> elementsInStatements(
    List<Statement> statements,
  ) sync* {
    int statementCount = statements.length;
    for (int i = 0; i < statementCount; i++) {
      Statement statement = statements[i];
      if (statement is LabeledStatement) {
        statement = statement.statement;
      }
      if (statement is PatternVariableDeclarationStatementImpl) {
        for (var variable in statement.declaration.elements) {
          yield variable;
        }
      } else if (statement is VariableDeclarationStatement) {
        NodeList<VariableDeclaration> variables = statement.variables.variables;
        int variableCount = variables.length;
        for (int j = 0; j < variableCount; j++) {
          yield variables[j].declaredFragment!.element;
        }
      } else if (statement is FunctionDeclarationStatement) {
        yield statement.functionDeclaration.declaredFragment!.element;
      }
    }
  }
}

/// The scope statements that can be the target of unlabeled `break` and
/// `continue` statements.
class ImplicitLabelScope {
  /// The implicit label scope associated with the top level of a function.
  static const ImplicitLabelScope ROOT = ImplicitLabelScope._(null, null);

  /// The implicit label scope enclosing this implicit label scope.
  final ImplicitLabelScope? outerScope;

  /// The statement that acts as a target for break and/or continue statements
  /// at this scoping level.
  final Statement? statement;

  /// Initialize a newly created scope, enclosed within the [outerScope],
  /// representing the given [statement].
  const ImplicitLabelScope._(this.outerScope, this.statement);

  /// Return the statement which should be the target of an unlabeled `break` or
  /// `continue` statement, or `null` if there is no appropriate target.
  Statement? getTarget(bool isContinue) {
    if (outerScope == null) {
      // This scope represents the top-level of a function body, so it doesn't
      // match either break or continue.
      return null;
    }
    if (isContinue && statement is SwitchStatement) {
      return outerScope!.getTarget(isContinue);
    }
    return statement;
  }

  /// Initialize a newly created scope to represent a switch statement or loop
  /// nested within the current scope.  [statement] is the statement associated
  /// with the newly created scope.
  ImplicitLabelScope nest(Statement statement) =>
      ImplicitLabelScope._(this, statement);
}

/// A scope in which a single label is defined.
class LabelScope {
  /// The label scope enclosing this label scope.
  final LabelScope? _outerScope;

  /// The label defined in this scope.
  final String _label;

  /// The element to which the label resolves.
  final LabelElement element;

  /// The AST node to which the label resolves.
  final AstNode node;

  /// Initialize a newly created scope, enclosed within the [_outerScope],
  /// representing the label [_label]. The [node] is the AST node the label
  /// resolves to. The [element] is the element the label resolves to.
  LabelScope(this._outerScope, this._label, this.node, this.element);

  /// Return the LabelScope which defines [targetLabel], or `null` if it is not
  /// defined in this scope.
  LabelScope? lookup(String targetLabel) {
    if (_label == targetLabel) {
      return this;
    }
    return _outerScope?.lookup(targetLabel);
  }
}

/// A mapping of identifiers to the elements represented by those identifiers.
/// Namespaces are the building blocks for scopes.
@AnalyzerPublicApi(message: 'exposed from elements')
class Namespace {
  /// An empty namespace.
  static Namespace EMPTY = Namespace({});

  /// A table mapping names that are defined in this namespace to the element
  /// representing the thing declared with that name.
  final Map<String, Element> _definedNames;

  /// Initialize a newly created namespace to have the [_definedNames].
  Namespace(this._definedNames);

  /// Return a table containing the same mappings as those defined by this
  /// namespace.
  Map<String, Element> get definedNames2 => _definedNames;

  /// Return the element in this namespace that is available to the containing
  /// scope using the given name, or `null` if there is no such element.
  Element? get2(String name) => _definedNames[name];

  /// Return the element in this namespace whose name is the result of combining
  /// the [prefix] and the [name], separated by a period, or `null` if there is
  /// no such element.
  Element? getPrefixed2(String prefix, String name) => null;
}

/// The builder used to build a namespace. Namespace builders are thread-safe
/// and re-usable.
class NamespaceBuilder {
  /// Create a namespace representing the export namespace of the given
  /// [export].
  Namespace createExportNamespaceForDirective2(LibraryExportImpl export) {
    var exportedLibrary = export.exportedLibrary;
    if (exportedLibrary == null) {
      //
      // The exported library will be null if the URI does not reference a valid
      // library.
      //
      return Namespace.EMPTY;
    }
    var exportedNames = _getExportMapping(exportedLibrary);
    exportedNames = _applyCombinators(exportedNames, export.combinators);
    return Namespace(exportedNames);
  }

  /// Create a namespace representing the import namespace of the given
  /// [importedLibrary].
  Namespace createImportNamespaceForDirective({
    required LibraryElementImpl importedLibrary,
    required List<NamespaceCombinator> combinators,
    required PrefixFragment? prefix,
  }) {
    var exportedNames = _getExportMapping(importedLibrary);
    exportedNames = _applyCombinators(exportedNames, combinators);
    if (prefix?.name case var name?) {
      return PrefixedNamespace(name, exportedNames);
    }
    return Namespace(exportedNames);
  }

  /// Create a namespace representing the public namespace of the given
  /// [library].
  Namespace createPublicNamespaceForLibrary(LibraryElementImpl library) {
    var definedNames = <String, Element>{};
    for (var element in library.classes) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.enums) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.extensions) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.extensionTypes) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.getters) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.mixins) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.setters) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.topLevelFunctions) {
      _addIfPublic(definedNames, element);
    }
    for (var element in library.typeAliases) {
      _addIfPublic(definedNames, element);
    }

    // For libraries that import `dart:core` with a prefix, we have to add
    // `dynamic` to the `dart:core` [Namespace] specially. Note that this is not
    // true of, for instance, `Object`, because `Object` has a source definition
    // which is not possible for `dynamic`.
    if (library.isDartCore) {
      definedNames['dynamic'] = DynamicElementImpl.instance;
      definedNames['Never'] = NeverElementImpl.instance;
    }

    return Namespace(definedNames);
  }

  /// Add the given [element] to the table of [definedNames] if it has a
  /// publicly visible name.
  void _addIfPublic(Map<String, Element> definedNames, Element element) {
    var name = element.name;
    if (name != null && name.isNotEmpty && !Identifier.isPrivateName(name)) {
      definedNames[name] = element;
    }
  }

  /// Apply the given [combinators] to all of the names in the given table of
  /// [definedNames].
  Map<String, Element> _applyCombinators(
    Map<String, Element> definedNames,
    List<NamespaceCombinator> combinators,
  ) {
    for (NamespaceCombinator combinator in combinators) {
      if (combinator is HideElementCombinator) {
        definedNames = _hide(definedNames, combinator.hiddenNames);
      } else if (combinator is ShowElementCombinator) {
        definedNames = _show(definedNames, combinator.shownNames);
      } else {
        // Internal error.
        AnalysisEngine.instance.instrumentationService.logError(
          "Unknown type of combinator: ${combinator.runtimeType}",
        );
      }
    }
    return definedNames;
  }

  Map<String, Element> _getExportMapping(LibraryElementImpl library) {
    return library.exportNamespace.definedNames2;
  }

  /// Return a new map of names which has all the names from [definedNames]
  /// with exception of [hiddenNames].
  Map<String, Element> _hide(
    Map<String, Element> definedNames,
    List<String> hiddenNames,
  ) {
    var newNames = {...definedNames};
    for (String name in hiddenNames) {
      newNames.remove(name);
      newNames.remove("$name=");
    }
    return newNames;
  }

  /// Return a new map of names which has only [shownNames] from [definedNames].
  Map<String, Element> _show(
    Map<String, Element> definedNames,
    List<String> shownNames,
  ) {
    var newNames = <String, Element>{};
    for (String name in shownNames) {
      var element = definedNames[name];
      if (element != null) {
        newNames[name] = element;
      }
      String setterName = considerCanonicalizeString("$name=");
      element = definedNames[setterName];
      if (element != null) {
        newNames[setterName] = element;
      }
    }
    return newNames;
  }
}

/// A mapping of identifiers to the elements represented by those identifiers.
/// Namespaces are the building blocks for scopes.
class PrefixedNamespace implements Namespace {
  /// The prefix that is prepended to each of the defined names.
  final String _prefix;

  /// The length of the prefix.
  final int _length;

  /// A table mapping names that are defined in this namespace to the element
  /// representing the thing declared with that name.
  @override
  final Map<String, Element> _definedNames;

  /// Initialize a newly created namespace to have the names resulting from
  /// prefixing each of the [_definedNames] with the given [_prefix] (and a
  /// period).
  PrefixedNamespace(String prefix, this._definedNames)
    : _prefix = prefix,
      _length = prefix.length;

  @override
  Map<String, Element> get definedNames2 {
    return _definedNames;
  }

  @override
  Element? get2(String name) {
    if (name.length > _length && name.startsWith(_prefix)) {
      if (name.codeUnitAt(_length) == '.'.codeUnitAt(0)) {
        return _definedNames[name.substring(_length + 1)];
      }
    }
    return null;
  }

  @override
  Element? getPrefixed2(String prefix, String name) {
    if (prefix == _prefix) {
      return _definedNames[name];
    }
    return null;
  }
}

class RecordingExportNamespace implements Namespace {
  final LibraryElementImpl owner;
  final Namespace base;

  RecordingExportNamespace({required this.owner, required this.base});

  @override
  Map<String, Element> get definedNames2 {
    globalResultRequirements?.record_library_allExportedTopLevels(
      element: owner,
    );
    return base.definedNames2;
  }

  @override
  Map<String, Element> get _definedNames => throw UnimplementedError();

  @override
  Element? get2(String name) {
    globalResultRequirements?.record_library_exportScope_get(
      element: owner,
      name: name,
    );
    return base.get2(name);
  }

  @override
  Element? getPrefixed2(String prefix, String name) {
    return base.getPrefixed2(prefix, name);
  }
}
