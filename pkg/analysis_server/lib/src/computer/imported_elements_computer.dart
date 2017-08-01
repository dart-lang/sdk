// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/**
 * An object used to compute the list of elements referenced within a given
 * region of a compilation unit that are imported into the compilation unit's
 * library.
 */
class ImportedElementsComputer {
  /**
   * The compilation unit in which the elements are referenced.
   */
  final CompilationUnit unit;

  /**
   * The offset of the region containing the references to be returned.
   */
  final int offset;

  /**
   * The length of the region containing the references to be returned.
   */
  final int length;

  /**
   * Initialize a newly created computer to compute the list of imported
   * elements referenced in the given [unit] within the region with the given
   * [offset] and [length].
   */
  ImportedElementsComputer(this.unit, this.offset, this.length);

  /**
   * Compute and return the list of imported elements.
   */
  List<ImportedElements> compute() {
    _Visitor visitor =
        new _Visitor(unit.element.library, offset, offset + length);
    unit.accept(visitor);
    return visitor.importedElements.values.toList();
  }
}

/**
 * The visitor used by an [ImportedElementsComputer] to record the names of all
 * imported elements.
 */
class _Visitor extends UnifyingAstVisitor<Object> {
  /**
   * The element representing the library containing the code being visited.
   */
  final LibraryElement containingLibrary;

  /**
   * The offset of the start of the region of text being copied.
   */
  final int startOffset;

  /**
   * The offset of the end of the region of text being copied.
   */
  final int endOffset;

  /**
   * A table mapping library path and prefix keys to the imported elements from
   * that library.
   */
  Map<String, ImportedElements> importedElements = <String, ImportedElements>{};

  /**
   * Initialize a newly created visitor to visit nodes within a specified
   * region.
   */
  _Visitor(this.containingLibrary, this.startOffset, this.endOffset);

  @override
  Object visitNode(AstNode node) {
    if (node.offset <= endOffset && node.end >= startOffset) {
      node.visitChildren(this);
    }
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext() &&
        node.offset <= endOffset &&
        node.end >= startOffset) {
      Element nodeElement = node.staticElement;
      if (nodeElement != null &&
          nodeElement.enclosingElement is CompilationUnitElement) {
        LibraryElement nodeLibrary = nodeElement.library;
        String path = nodeLibrary.definingCompilationUnit.source.fullName;
        String prefix = '';
        AstNode parent = node.parent;
        if (parent is PrefixedIdentifier && parent.identifier == node) {
          SimpleIdentifier prefixIdentifier = parent.prefix;
          if (prefixIdentifier.offset <= endOffset &&
              prefixIdentifier.end >= startOffset) {
            Element prefixElement = prefixIdentifier.staticElement;
            if (prefixElement is PrefixElement) {
              prefix = prefixElement.name;
            }
          }
        }
        String key = '$prefix;$path';
        ImportedElements elements = importedElements.putIfAbsent(
            key, () => new ImportedElements(path, prefix, <String>[]));
        List<String> elementNames = elements.elements;
        String elementName = nodeElement.name;
        if (!elementNames.contains(elementName)) {
          elementNames.add(elementName);
        }
      }
    }
    return null;
  }
}
