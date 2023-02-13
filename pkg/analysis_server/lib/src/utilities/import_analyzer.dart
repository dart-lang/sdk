// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';

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
  final Set<Element> movingDeclarations = {};

  /// The elements for the declarations that are staying.
  final Set<Element> stayingDeclarations = {};

  /// A map from the elements referenced by the declarations to be moved to the
  /// set of prefixes used to reference those declarations.
  final Map<Element, Set<String>> movingReferences = {};

  /// A map from the elements referenced by the declarations that are staying to
  /// the set of prefixes used to reference those declarations.
  final Map<Element, Set<String>> stayingReferences = {};

  /// Analyze the given library [result] to find the declarations and references
  /// being moved and that are staying. The declarations being moved are in the
  /// file at the given [path] in the given [range].
  ImportAnalyzer(this.result, String path, List<SourceRange> ranges) {
    for (var unit in result.units) {
      var finder = _ReferenceFinder(
          _ElementRecorder(this, path == unit.path ? ranges : []));
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

  /// Record that the [element] is declared in the library.
  void recordDeclaration(Element? declaredElement) {
    if (declaredElement != null) {
      if (_isBeingMoved(declaredElement.nameOffset)) {
        analyzer.movingDeclarations.add(declaredElement);
      } else {
        analyzer.stayingDeclarations.add(declaredElement);
      }
    }
  }

  /// Record that the [element] is referenced in the library at the
  /// [referenceOffset]. The [prefix] is the prefix used to reference the
  /// element, or an empty string if no prefix was used.
  void recordReference(
      Element referencedElement, int referenceOffset, String prefix) {
    if (referencedElement is PropertyAccessorElement &&
        referencedElement.isSynthetic) {
      referencedElement = referencedElement.variable;
    }
    if (_isBeingMoved(referenceOffset)) {
      var prefixes =
          analyzer.movingReferences.putIfAbsent(referencedElement, () => {});
      prefixes.add(prefix);
    } else {
      var prefixes =
          analyzer.stayingReferences.putIfAbsent(referencedElement, () => {});
      prefixes.add(prefix);
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

  /// Initialize a newly created finder to send information to the [recorder].
  _ReferenceFinder(this.recorder);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var writeElement = node.writeElement;
    if (writeElement != null) {
      recorder.recordReference(writeElement, node.offset,
          _getPrefixFromExpression(node.leftHandSide));
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitClassTypeAlias(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    var extensionElement = node.declaredElement;
    if (extensionElement != null) {
      recorder.recordDeclaration(extensionElement);
      for (var accessor in extensionElement.accessors) {
        if (!accessor.isStatic && !accessor.isSynthetic) {
          recorder.recordDeclaration(accessor);
        }
      }
      for (var field in extensionElement.fields) {
        if (!field.isStatic && !field.isSynthetic) {
          recorder.recordDeclaration(field);
        }
      }
      for (var method in extensionElement.methods) {
        if (!method.isStatic) {
          recorder.recordDeclaration(method);
        }
      }
    }
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    recorder.recordDeclaration(node.declaredElement);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.staticElement;
    if (element is ExecutableElement &&
        element.enclosingElement is ExtensionElement &&
        !element.isStatic) {
      element = element.enclosingElement;
    }
    if (element != null && element.isInterestingReference) {
      recorder.recordReference(
          element, node.offset, _getPrefixForIdentifier(node));
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (var variable in node.variables.variables) {
      recorder.recordDeclaration(variable.declaredElement);
    }
    super.visitTopLevelVariableDeclaration(node);
  }

  /// Return the prefix used to reference the [node].
  String _getPrefixForIdentifier(SimpleIdentifier node) {
    return _getPrefixFromExpression(node.parent);
  }

  /// Return the prefix used to reference the [node].
  String _getPrefixFromExpression(AstNode? node) {
    if (node is PrefixedIdentifier) {
      var prefix = node.prefix;
      if (prefix.staticElement is PrefixElement) {
        return prefix.name;
      }
    } else if (node is PropertyAccess) {
      // TODO(brianwilkerson) Remove this branch after all prefixes are
      //  rewritten as a `PrefixedIdentifier`.
      var propertyName = node.propertyName;
      if (propertyName.staticElement is PrefixElement) {
        return propertyName.name;
      }
    }
    return '';
  }
}

extension on Element {
  /// Return `true` if this element reference is an interesting reference from
  /// the perspective of determining which imports need to be added.
  bool get isInterestingReference => enclosingElement is CompilationUnitElement;
}
