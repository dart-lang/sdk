// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';

/// An object used to compute the list of elements referenced within a given
/// portion of a compilation unit that are imported into the compilation unit's
/// library.
class ImportedElementsComputer {
  /// The compilation unit in which the elements are referenced.
  final CompilationUnit unit;

  /// The offset of the region containing the references to be returned.
  final int offset;

  /// The length of the region containing the references to be returned.
  final int length;

  /// Initialize a newly created computer to compute the list of imported
  /// elements referenced in the given [unit] within the region with the given
  /// [offset] and [length].
  ImportedElementsComputer(this.unit, this.offset, this.length);

  /// Compute and return the list of imported elements.
  List<ImportedElements> compute() {
    if (_regionIncludesDirectives()) {
      return const <ImportedElements>[];
    }
    var visitor = _Visitor(offset, offset + length);
    unit.accept(visitor);
    return visitor.importedElements.values.toList();
  }

  /// Return `true` if the region being copied includes any directives. This
  /// really only needs to check for import and export directives, but excluding
  /// other directives is unlikely to hurt the UX.
  bool _regionIncludesDirectives() {
    var directives = unit.directives;
    if (directives.isEmpty) {
      return false;
    }
    // This might be overly restrictive if there are directives after the first
    // declaration, but that should be a rare case given that it's invalid.
    return offset < directives.last.end;
  }
}

/// The visitor used by an [ImportedElementsComputer] to record the names of all
/// imported elements.
class _Visitor extends UnifyingAstVisitor<void> {
  /// The offset of the start of the portion of text being copied.
  final int startOffset;

  /// The offset of the end of the portion of text being copied.
  final int endOffset;

  /// A table mapping library path and prefix keys to the imported elements from
  /// that library.
  Map<String, ImportedElements> importedElements = <String, ImportedElements>{};

  /// Initialize a newly created visitor to visit nodes within a specified
  /// portion.
  _Visitor(this.startOffset, this.endOffset);

  @override
  void visitNamedType(NamedType node) {
    if (node.offset <= endOffset && node.end >= startOffset) {
      final importPrefix = node.importPrefix;
      final prefix = importPrefix?.element?.name ?? '';
      _addElement(prefix, node.element);
    }

    super.visitNamedType(node);
  }

  @override
  void visitNode(AstNode node) {
    if (node.offset <= endOffset && node.end >= startOffset) {
      node.visitChildren(this);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext() &&
        node.offset <= endOffset &&
        node.end >= startOffset &&
        !_isConstructorDeclarationReturnType(node)) {
      var nodeElement = node.writeOrReadElement;

      var prefix = '';
      var parent = node.parent;
      if (parent is PrefixedIdentifier && parent.identifier == node) {
        prefix = _getPrefixFrom(parent.prefix);
      } else if (parent is MethodInvocation && parent.methodName == node) {
        var target = parent.target;
        if (target is SimpleIdentifier) {
          prefix = _getPrefixFrom(target);
        }
      }

      _addElement(prefix, nodeElement);
    }
  }

  void _addElement(String prefix, Element? element) {
    if (element == null) {
      return;
    }
    if (element.enclosingElement is! CompilationUnitElement) {
      return;
    }

    final path = element.library?.definingCompilationUnit.source.fullName;
    if (path == null) {
      return;
    }

    var key = '$prefix;$path';
    var elements = importedElements.putIfAbsent(
        key, () => ImportedElements(path, prefix, <String>[]));
    var elementNames = elements.elements;
    var elementName = element.name;
    if (elementName != null && !elementNames.contains(elementName)) {
      elementNames.add(elementName);
    }
  }

  String _getPrefixFrom(SimpleIdentifier identifier) {
    if (identifier.offset <= endOffset && identifier.end >= startOffset) {
      var prefixElement = identifier.staticElement;
      if (prefixElement is PrefixElement) {
        return prefixElement.name;
      }
    }
    return '';
  }

  static bool _isConstructorDeclarationReturnType(SimpleIdentifier node) {
    var parent = node.parent;
    return parent is ConstructorDeclaration && parent.returnType == node;
  }
}
