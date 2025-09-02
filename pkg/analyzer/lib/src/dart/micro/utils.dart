// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Return the [Element] of the given [node], or `null` if [node] is `null` or
/// does not have an element.
Element? getElementOfNode2(AstNode? node) {
  if (node == null) {
    return null;
  }
  if (node is SimpleIdentifier && node.parent is LibraryIdentifier) {
    node = node.parent;
  }
  if (node is LibraryIdentifier) {
    node = node.parent;
  }
  if (node is StringLiteral && node.parent is UriBasedDirective) {
    return null;
  }

  Element? element;
  switch (node) {
    case ImportDirective():
      return MockLibraryImportElement(node.libraryImport!);
    case ImportPrefixReference():
      element = node.element;
    default:
      element = ElementLocator.locate(node);
  }

  if (node is SimpleIdentifier && element is PrefixElement) {
    var parent = node.parent;
    if (parent is ImportDirective) {
      element = MockLibraryImportElement(parent.libraryImport!);
    } else {
      element = _getImportElementInfo2(node);
    }
  } else if (node is ImportPrefixReference && element is PrefixElement) {
    element = _getImportElementInfoFromReference(node);
  }

  return element;
}

/// If the given [constructor] is a synthetic constructor created for a
/// [ClassTypeAlias], return the actual constructor of a [ClassDeclaration]
/// which is invoked.  Return `null` if a redirection cycle is detected.
ConstructorElement? _getActualConstructorElement(
  ConstructorElement? constructor,
) {
  var seenConstructors = <ConstructorElement?>{};
  while (constructor is ConstructorElementImpl && constructor.isSynthetic) {
    var enclosing = constructor.enclosingElement;
    if (enclosing is ClassElementImpl && enclosing.isMixinApplication) {
      var superInvocation = constructor.constantInitializers
          .whereType<SuperConstructorInvocation>()
          .singleOrNull;
      if (superInvocation != null) {
        constructor = superInvocation.element;
      }
    } else {
      break;
    }
    // fail if a cycle is detected
    if (!seenConstructors.add(constructor)) {
      return null;
    }
  }
  return constructor;
}

/// Returns the [LibraryImportElement] that is referenced by [prefixNode] with a
/// [PrefixElement], maybe `null`.
MockLibraryImportElement? _getImportElementInfo2(SimpleIdentifier prefixNode) {
  // prepare environment
  var parent = prefixNode.parent;
  var unit = prefixNode.thisOrAncestorOfType<CompilationUnitImpl>();
  var libraryFragment = unit?.declaredFragment;
  if (libraryFragment == null) {
    return null;
  }
  // prepare used element
  Element? usedElement;
  if (parent is PrefixedIdentifier) {
    var prefixed = parent;
    if (prefixed.prefix == prefixNode) {
      usedElement = prefixed.element;
    }
  } else if (parent is MethodInvocation) {
    var invocation = parent;
    if (invocation.target == prefixNode) {
      usedElement = invocation.methodName.element;
    }
  }
  // we need used Element
  if (usedElement == null) {
    return null;
  }
  // find ImportElement
  var prefix = prefixNode.name;
  var importElementsMap = <LibraryImport, Set<Element>>{};
  return _getMockImportElement(
    libraryFragment,
    prefix,
    usedElement,
    importElementsMap,
  );
}

/// Returns the [LibraryImportElement] that is referenced by [prefixNode] with a
/// [PrefixElement], maybe `null`.
MockLibraryImportElement? _getImportElementInfoFromReference(
  ImportPrefixReference prefixNode,
) {
  // prepare environment
  var unit = prefixNode.thisOrAncestorOfType<CompilationUnitImpl>();
  var libraryFragment = unit?.declaredFragment;
  if (libraryFragment == null) {
    return null;
  }

  // prepare used element
  Element? usedElement;
  var parent = prefixNode.parent;
  if (parent is ExtensionOverride) {
    usedElement = parent.element;
  } else if (parent is NamedType) {
    usedElement = parent.element;
  }
  if (usedElement == null) {
    return null;
  }

  // find ImportElement
  var prefix = prefixNode.name.lexeme;
  var importElementsMap = <LibraryImport, Set<Element>>{};
  return _getMockImportElement(
    libraryFragment,
    prefix,
    usedElement,
    importElementsMap,
  );
}

/// Returns the [LibraryImportElement] that declared [prefix] and imports [element].
///
/// [libraryFragment] - the [LibraryFragmentImpl] where reference is.
/// [prefix] - the import prefix, maybe `null`.
/// [element] - the referenced element.
/// [importElementsMap] - the cache of [Element]s imported by [LibraryImportElement]s.
MockLibraryImportElement? _getMockImportElement(
  LibraryFragmentImpl libraryFragment,
  String prefix,
  Element element,
  Map<LibraryImport, Set<Element>> importElementsMap,
) {
  if (element.enclosingElement is! LibraryElement) {
    return null;
  }
  var usedLibrary = element.library;
  // find ImportElement that imports used library with used prefix
  List<LibraryImport>? candidates;
  var libraryImports = libraryFragment.withEnclosing2
      .expand((fragment) => fragment.libraryImports)
      .toList();
  for (var importElement in libraryImports) {
    // required library
    if (importElement.importedLibrary != usedLibrary) {
      continue;
    }
    // required prefix
    var prefixElement = importElement.prefix?.element;
    if (prefixElement == null) {
      continue;
    }
    if (prefix != prefixElement.name) {
      continue;
    }
    // no combinators => only possible candidate
    if (importElement.combinators.isEmpty) {
      return MockLibraryImportElement(importElement);
    }
    // OK, we have candidate
    candidates ??= [];
    candidates.add(importElement);
  }
  // no candidates, probably element is defined in this library
  if (candidates == null) {
    return null;
  }
  // one candidate
  if (candidates.length == 1) {
    return MockLibraryImportElement(candidates[0]);
  }
  // ensure that each ImportElement has set of elements
  for (var importElement in candidates) {
    if (importElementsMap.containsKey(importElement)) {
      continue;
    }
    var namespace = importElement.namespace;
    var elements = namespace.definedNames2.values.toSet();
    importElementsMap[importElement] = elements;
  }
  // use import namespace to choose correct one
  for (var entry in importElementsMap.entries) {
    var importElement = entry.key;
    var elements = entry.value;
    if (elements.contains(element)) {
      return MockLibraryImportElement(importElement);
    }
  }
  // not found
  return null;
}

class MatchInfo {
  final int offset;
  final int length;
  final MatchKind matchKind;

  MatchInfo(this.offset, this.length, this.matchKind);
}

/// Instances of the enum [MatchKind] represent the kind of reference that was
/// found when a match represents a reference to an element.
class MatchKind {
  /// A declaration of an element.
  static const MatchKind DECLARATION = MatchKind('DECLARATION');

  /// A reference to an element in which it is being read.
  static const MatchKind READ = MatchKind('READ');

  /// A reference to an element in which it is being both read and written.
  static const MatchKind READ_WRITE = MatchKind('READ_WRITE');

  /// A reference to an element in which it is being written.
  static const MatchKind WRITE = MatchKind('WRITE');

  /// A reference to an element in which it is being invoked.
  static const MatchKind INVOCATION = MatchKind('INVOCATION');

  /// An invocation of an enum constructor from an enum constant without
  /// arguments.
  static const MatchKind INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS =
      MatchKind('INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS');

  /// A reference to an element in which it is referenced.
  static const MatchKind REFERENCE = MatchKind('REFERENCE');

  /// A tear-off reference to a constructor.
  static const MatchKind REFERENCE_BY_CONSTRUCTOR_TEAR_OFF = MatchKind(
    'REFERENCE_BY_CONSTRUCTOR_TEAR_OFF',
  );

  final String name;

  const MatchKind(this.name);

  @override
  String toString() => name;
}

class ReferencesCollector extends GeneralizingAstVisitor<void> {
  final Element element;
  final List<MatchInfo> references = [];

  ReferencesCollector(this.element);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var writeElement = node.writeElement;
    if (writeElement is PropertyAccessorElement) {
      var kind = MatchKind.WRITE;
      if (writeElement.variable == element || writeElement == element) {
        if (node.leftHandSide is SimpleIdentifier) {
          references.add(
            MatchInfo(node.leftHandSide.offset, node.leftHandSide.length, kind),
          );
        } else if (node.leftHandSide is PrefixedIdentifier) {
          var prefixIdentifier = node.leftHandSide as PrefixedIdentifier;
          references.add(
            MatchInfo(
              prefixIdentifier.identifier.offset,
              prefixIdentifier.identifier.length,
              kind,
            ),
          );
        } else if (node.leftHandSide is PropertyAccess) {
          var accessor = node.leftHandSide as PropertyAccess;
          references.add(
            MatchInfo(accessor.propertyName.offset, accessor.length, kind),
          );
        }
      }
    }

    var readElement = node.readElement;
    if (readElement is PropertyAccessorElement) {
      if (readElement.variable == element) {
        references.add(
          MatchInfo(
            node.rightHandSide.offset,
            node.rightHandSide.length,
            MatchKind.READ,
          ),
        );
      }
    }
  }

  @override
  visitCommentReference(CommentReference node) {
    var expression = node.expression;
    if (expression is Identifier) {
      var element = expression.element;
      if (element is ConstructorElement) {
        if (expression is PrefixedIdentifier) {
          var offset = expression.prefix.end;
          var length = expression.end - offset;
          references.add(MatchInfo(offset, length, MatchKind.REFERENCE));
          return;
        } else {
          var offset = expression.end;
          references.add(MatchInfo(offset, 0, MatchKind.REFERENCE));
          return;
        }
      }
    } else if (expression is PropertyAccess) {
      // Nothing to do?
    } else {
      throw UnimplementedError(
        'Unhandled CommentReference expression type: '
        '${expression.runtimeType}',
      );
    }
  }

  @override
  visitConstructorDeclaration(covariant ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment;
    if (fragment?.element == element) {
      if ((node.period, node.name) case (var period?, var nameToken?)) {
        var offset = period.offset;
        var length = nameToken.end - offset;
        references.add(MatchInfo(offset, length, MatchKind.DECLARATION));
      } else {
        references.add(
          MatchInfo(node.returnType.end, 0, MatchKind.DECLARATION),
        );
      }
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    var e = node.element?.baseElement;
    e = _getActualConstructorElement(e);
    MatchKind kind;
    int offset;
    int length;
    if (e == element) {
      if (node.parent is ConstructorReference) {
        kind = MatchKind.REFERENCE_BY_CONSTRUCTOR_TEAR_OFF;
      } else if (node.parent is InstanceCreationExpression) {
        kind = MatchKind.INVOCATION;
      } else {
        kind = MatchKind.REFERENCE;
      }
      if (node.name != null) {
        offset = node.period!.offset;
        length = node.name!.end - offset;
      } else {
        offset = node.type.end;
        length = 0;
      }
      references.add(MatchInfo(offset, length, kind));
    } else if (e != null && e.enclosingElement == element) {
      kind = MatchKind.REFERENCE;
      offset = node.offset;
      length = element.name?.length ?? 0;
      references.add(MatchInfo(offset, length, kind));
    }
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var constructorElement = node.constructorElement;
    if (constructorElement != null && constructorElement == element) {
      int offset;
      int length;
      var constructorSelector = node.arguments?.constructorSelector;
      if (constructorSelector != null) {
        offset = constructorSelector.period.offset;
        length = constructorSelector.name.end - offset;
      } else {
        offset = node.name.end;
        length = 0;
      }
      var kind = node.arguments == null
          ? MatchKind.INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS
          : MatchKind.INVOCATION;
      references.add(MatchInfo(offset, length, kind));
    }
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.element == element) {
      references.add(
        MatchInfo(node.name.offset, node.name.length, MatchKind.REFERENCE),
      );
    }

    node.importPrefix?.accept(this);
    node.typeArguments?.accept(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    var e = node.element;
    if (e == element) {
      if (node.constructorName != null) {
        int offset = node.period!.offset;
        int length = node.constructorName!.end - offset;
        references.add(MatchInfo(offset, length, MatchKind.INVOCATION));
      } else {
        int offset = node.thisKeyword.end;
        references.add(MatchInfo(offset, 0, MatchKind.INVOCATION));
      }
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    var e = node.element;
    if (e == element) {
      references.add(MatchInfo(node.offset, node.length, MatchKind.REFERENCE));
    } else if (e is GetterElement && e.variable == element) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      MatchKind kind;
      if (inGetterContext && inSetterContext) {
        kind = MatchKind.READ_WRITE;
      } else if (inGetterContext) {
        kind = MatchKind.READ;
      } else {
        kind = MatchKind.WRITE;
      }
      references.add(MatchInfo(node.offset, node.length, kind));
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var e = node.element;
    if (e == element) {
      if (node.constructorName != null) {
        int offset = node.period!.offset;
        int length = node.constructorName!.end - offset;
        references.add(MatchInfo(offset, length, MatchKind.INVOCATION));
      } else {
        int offset = node.superKeyword.end;
        references.add(MatchInfo(offset, 0, MatchKind.INVOCATION));
      }
    }
  }
}
