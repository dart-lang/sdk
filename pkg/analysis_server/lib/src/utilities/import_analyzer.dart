// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';

/// A utility class used to analyze a library from which some set of
/// declarations are being moved in order to compute the set of changes needed
/// in order for the imports to be correct in both the library from which the
/// declarations will be removed and the library to which the declarations will
/// be added.
class ImportAnalyzer {
  /// The result of resolving the library containing the declarations to be
  /// moved.
  final ResolvedLibraryResult result;

  /// The elements for the declarations to be moved.
  final Set<Element2> movingDeclarations = {};

  /// The elements for the declarations that are staying.
  final Set<Element2> stayingDeclarations = {};

  /// A map from the elements referenced by the declarations to be moved to the
  /// set of imports used to reference those declarations.
  final Map<Element2, Set<LibraryImport>> movingReferences = {};

  /// A map from the elements referenced by the declarations that are staying to
  /// the set of imports used to reference those declarations.
  final Map<Element2, Set<LibraryImport>> stayingReferences = {};

  /// Analyze the given library [result] to find the declarations and references
  /// being moved and that are staying. The declarations being moved are in the
  /// file at the given [path] in the given [range].
  ImportAnalyzer(this.result, String path, List<SourceRange> ranges) {
    for (var unit in result.units) {
      var finder = _ReferenceFinder(
          unit, _ElementRecorder(this, path == unit.path ? ranges : []));
      unit.unit.accept(finder);
    }
    // Remove references that will be within the same file.
    for (var element in movingDeclarations) {
      movingReferences.remove(element);
    }
    for (var element in stayingDeclarations) {
      stayingReferences.remove(element);
    }
  }

  /// Return `true` if there are any references in the code that's being moved
  /// to any of the declarations that are staying. If there are, then the
  /// library to which the declarations are being moved needs to have an import
  /// for the library from which they are being moved.
  bool get hasMovingReferenceToStayingDeclaration {
    for (var declaration in stayingDeclarations) {
      if (movingReferences.containsKey(declaration)) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if there are any references in the code that's staying to
  /// any of the declarations that are being moved. If there are, then the
  /// library from which the declarations are being moved needs to have an
  /// import for the library to which they are being moved.
  bool get hasStayingReferenceToMovingDeclaration {
    for (var declaration in movingDeclarations) {
      if (stayingReferences.containsKey(declaration)) {
        return true;
      }
    }
    return false;
  }
}

class _ElementRecorder {
  /// The import analyzer to which declaration and reference information will be
  /// sent.
  final ImportAnalyzer analyzer;

  /// The range of characters being moved, or `null` if the code being moved is
  /// in a different compilation unit that the one currently being visited.
  final List<SourceRange> ranges;

  /// Initialize a newly created recorder to use the [analyzer] to record
  /// declarations of and references to elements, based on whether the reference
  /// is within the [range].
  _ElementRecorder(this.analyzer, this.ranges);

  /// Record that the [declaredElement] is declared in the library.
  ///
  /// The [offset] is the decision offset, used to decide whether the element
  /// is being moved. Not necessary the offset of the name. For example to
  /// a [MethodDeclaration] it would be the offset of the enclosing
  /// [ClassDeclaration] because we move the whole top-level declarations.
  void recordDeclaration(int offset, Element2? declaredElement) {
    if (declaredElement == null) {
      return;
    }

    if (_isBeingMoved(offset)) {
      analyzer.movingDeclarations.add(declaredElement);
    } else {
      analyzer.stayingDeclarations.add(declaredElement);
    }
  }

  /// Record that [referencedElement] is referenced in the library at the
  /// [referenceOffset]. [import] is the specific import used to reference the
  /// including any prefix, show, hide.
  void recordReference(
      Element2 referencedElement, int referenceOffset, LibraryImport? import) {
    switch (referencedElement) {
      case GetterElement():
        if (referencedElement.isSynthetic) {
          var variable = referencedElement.variable3;
          if (variable == null) {
            return;
          }
          referencedElement = variable;
        }
      case SetterElement():
        if (referencedElement.isSynthetic) {
          var variable = referencedElement.variable3;
          if (variable == null) {
            return;
          }
          referencedElement = variable;
        }
    }

    if (_isBeingMoved(referenceOffset)) {
      var imports =
          analyzer.movingReferences.putIfAbsent(referencedElement, () => {});
      if (import != null) {
        imports.add(import);
      }
    } else {
      var imports =
          analyzer.stayingReferences.putIfAbsent(referencedElement, () => {});
      if (import != null) {
        imports.add(import);
      }
    }
  }

  // Return `true` if the code at the [offset] is being moved to a different
  // file.
  bool _isBeingMoved(int offset) {
    for (var range in ranges) {
      if (range.contains(offset)) {
        return true;
      }
    }
    return false;
  }
}

class _ReferenceFinder extends RecursiveAstVisitor<void> {
  /// The import analyzer to which declaration and reference information will be
  /// sent.
  final _ElementRecorder recorder;

  /// The unit being searched for references.
  final ResolvedUnitResult unit;

  /// A mapping of prefixes to the imports with those prefixes. An
  /// empty string is used for unprefixed imports.
  ///
  /// Library imports are ordered the same as they appear in the source file
  /// (since this is a [LinkedHashSet]).
  final _importsByPrefix = <String, Set<LibraryImport>>{};

  /// Initialize a newly created finder to send information to the [recorder].
  _ReferenceFinder(this.unit, this.recorder) {
    for (var import in unit.libraryElement2.firstFragment.libraryImports2) {
      _importsByPrefix
          .putIfAbsent(import.prefix2?.element.name3 ?? '', () => {})
          .add(import);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _recordReference(node.writeElement2, node, node.leftHandSide);
    _recordReference(node.readElement2, node, node.leftHandSide);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    _recordReference(node.element, node, node.parent);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var extensionElement = node.declaredFragment?.element;
    if (extensionElement != null) {
      recorder.recordDeclaration(node.offset, extensionElement);
      for (var getter in extensionElement.getters2) {
        if (!getter.isStatic && !getter.isSynthetic) {
          recorder.recordDeclaration(node.offset, getter);
        }
      }
      for (var setter in extensionElement.setters2) {
        if (!setter.isStatic && !setter.isSynthetic) {
          recorder.recordDeclaration(node.offset, setter);
        }
      }
      for (var field in extensionElement.fields2) {
        if (!field.isStatic && !field.isSynthetic) {
          recorder.recordDeclaration(node.offset, field);
        }
      }
      for (var method in extensionElement.methods2) {
        if (!method.isStatic) {
          recorder.recordDeclaration(node.offset, method);
        }
      }
    }
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    recorder.recordDeclaration(node.offset, node.declaredFragment?.element);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _recordReference(node.element2, node, node);
    super.visitNamedType(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _recordReference(node.writeElement2, node, node.operand);
    _recordReference(node.readElement2, node, node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _recordReference(node.writeElement2, node, node.operand);
    _recordReference(node.readElement2, node, node.operand);
    super.visitPrefixExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _recordReference(node.element, node, node.parent);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      recorder.recordDeclaration(
        node.offset,
        variable.declaredFragment?.element,
      );
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  /// Finds the [LibraryImportElement] that is used to import [element] for use
  /// in [node].
  LibraryImport? _getImportForElement(AstNode? node, Element2 element) {
    var prefix = _getPrefixFromExpression(node)?.name3;
    var elementName = element.name3;
    // We cannot locate imports for unnamed elements.
    if (elementName == null) {
      return null;
    }

    var import = _importsByPrefix[prefix ?? '']?.where((import) {
      // Check if this import is providing our element with the correct
      // prefix/name.
      var exportedElement = prefix != null
          ? import.namespace.getPrefixed2(prefix, elementName)
          : import.namespace.get2(elementName);
      return exportedElement == element;
    }).firstOrNull;

    // Extensions can be used without a prefix, so we can use any import that
    // brings in the extension.
    if (import == null && prefix == null && element is ExtensionElement2) {
      import = _importsByPrefix.values.flattenedToList
          .where((import) =>
              // Because we don't know what prefix we're looking for (any is
              // allowed), use the imports own prefix when checking for the
              // element.
              import.namespace.getPrefixed2(
                  import.prefix2?.element.name3 ?? '', elementName) ==
              element)
          .firstOrNull;
    }

    return import;
  }

  /// Return the prefix used in [node].
  PrefixElement2? _getPrefixFromExpression(AstNode? node) {
    if (node is PrefixedIdentifier) {
      var prefix = node.prefix;
      var element = prefix.element;
      if (element is PrefixElement2) {
        return element;
      }
    } else if (node is PropertyAccess) {
      var target = node.target;
      if (target is PrefixedIdentifier) {
        var element = target.prefix.element;
        if (element is PrefixElement2) {
          return element;
        }
      }
    } else if (node is MethodInvocation) {
      var target = node.target;
      if (target is SimpleIdentifier) {
        var element = target.element;
        if (element is PrefixElement2) {
          return element;
        }
      }
    } else if (node is NamedType) {
      return node.importPrefix?.element2.ifTypeOrNull();
    }
    return null;
  }

  /// Records a reference to [element] (if not null) at the offset of [node],
  /// extracting any prefix from [prefixNode].
  void _recordReference(Element2? element, AstNode node, AstNode? prefixNode) {
    if (element is ExecutableElement2 &&
        element.enclosingElement2 is ExtensionElement2 &&
        !element.isStatic) {
      element = element.enclosingElement2;
    }
    if (element == null) {
      return;
    }
    if (!element.isInterestingReference) {
      return;
    }

    var import = _getImportForElement(prefixNode, element);
    recorder.recordReference(element, node.offset, import);
  }
}

extension on Element2 {
  /// Return `true` if this element reference is an interesting reference from
  /// the perspective of determining which imports need to be added.
  bool get isInterestingReference {
    return this is! PrefixElement2 && enclosingElement2 is LibraryElement2;
  }
}
