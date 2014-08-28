// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.search.element_visitors;

import 'package:analyzer/src/generated/element.dart';


/**
 * Uses [processor] to visit all of the children of [element].
 * If [processor] returns `true`, then children of a child are visited too.
 */
void visitChildren(Element element, ElementProcessor processor) {
  element.visitChildren(new _ElementVisitorAdapter(processor));
}


/**
 * Uses [processor] to visit all of the top-level elements of [library].
 */
void visitLibraryTopLevelElements(LibraryElement library,
    ElementProcessor processor) {
  library.visitChildren(new _TopLevelElementsVisitor(processor));
}


/**
 * An [Element] processor function type.
 * If `true` is returned, children of [element] will be visited.
 */
typedef bool ElementProcessor(Element element);


/**
 * A [GeneralizingElementVisitor] adapter for [ElementProcessor].
 */
class _ElementVisitorAdapter extends GeneralizingElementVisitor {
  final ElementProcessor processor;

  _ElementVisitorAdapter(this.processor);

  @override
  void visitElement(Element element) {
    bool visitChildren = processor(element);
    if (visitChildren == true) {
      element.visitChildren(this);
    }
  }
}


/**
 * A [GeneralizingElementVisitor] for visiting top-level elements.
 */
class _TopLevelElementsVisitor extends GeneralizingElementVisitor {
  final ElementProcessor processor;

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
