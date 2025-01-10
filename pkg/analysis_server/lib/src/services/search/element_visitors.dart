// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Return the [Element] that is either [root], or one of its direct or
/// indirect children, and has the given [nameOffset].
Element? findElementByNameOffset(Element? root, int nameOffset) {
  if (root == null) {
    return null;
  }
  try {
    var visitor = _ElementByNameOffsetVisitor(nameOffset);
    root.accept(visitor);
  } on Element catch (result) {
    return result;
  }
  return null;
}

/// Return the [Element2] that is either [root], or one of its direct or
/// indirect children, and has the given [nameOffset].
Element2? findElementByNameOffset2(Element2? root, int nameOffset) =>
    findElementByNameOffset(root.asElement, nameOffset).asElement2;

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren(Element element, BoolElementProcessor processor) {
  element.visitChildren(_ElementVisitorAdapter(processor));
}

/// Uses [processor] to visit all of the children of [element].
/// If [processor] returns `true`, then children of a child are visited too.
void visitChildren2(Element2 element, BoolElementProcessor2 processor) {
  element.visitChildren2(_ElementVisitorAdapter2(processor));
}

/// Uses [processor] to visit all of the top-level elements of [library].
void visitLibraryTopLevelElements(
  LibraryElement library,
  VoidElementProcessor processor,
) {
  library.visitChildren(_TopLevelElementsVisitor(processor));
}

/// An [Element] processor function type.
/// If `true` is returned, children of [element] will be visited.
typedef BoolElementProcessor = bool Function(Element element);

/// An [Element2] processor function type.
/// If `true` is returned, children of [element] will be visited.
typedef BoolElementProcessor2 = bool Function(Element2 element);

/// An [Element] processor function type.
typedef VoidElementProcessor = void Function(Element element);

/// A visitor that finds the deep-most [Element] that contains the [nameOffset].
class _ElementByNameOffsetVisitor extends GeneralizingElementVisitor<void> {
  final int nameOffset;

  _ElementByNameOffsetVisitor(this.nameOffset);

  @override
  void visitElement(Element element) {
    if (element.nameOffset != -1 &&
        !element.isSynthetic &&
        element.nameOffset == nameOffset) {
      throw element;
    }
    super.visitElement(element);
  }
}

/// A [GeneralizingElementVisitor] adapter for [ElementProcessor].
class _ElementVisitorAdapter extends GeneralizingElementVisitor<void> {
  final BoolElementProcessor processor;

  _ElementVisitorAdapter(this.processor);

  @override
  void visitElement(Element element) {
    var visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren(this);
    }
  }
}

/// A [GeneralizingElementVisitor] adapter for [BoolElementProcessor2].
class _ElementVisitorAdapter2 extends GeneralizingElementVisitor2<void> {
  final BoolElementProcessor2 processor;

  _ElementVisitorAdapter2(this.processor);

  @override
  void visitElement(Element2 element) {
    var visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren2(this);
    }
  }
}

/// A [GeneralizingElementVisitor] for visiting top-level elements.
class _TopLevelElementsVisitor extends GeneralizingElementVisitor<void> {
  final VoidElementProcessor processor;

  _TopLevelElementsVisitor(this.processor);

  @override
  void visitElement(Element element) {
    if (element is CompilationUnitElement) {
      element.visitChildren(this);
    } else {
      processor(element);
    }
  }
}
