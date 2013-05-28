// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Encapsulates the field [TreeElementMixin._element].
 *
 * This library is an implementation detail of dart2js, and should not
 * be imported except by resolution and tree node libraries, or for
 * testing.
 *
 * We have taken great care to ensure AST nodes can be cached between
 * compiler instances.  Part of this requires that we always access
 * resolution results through TreeElements.
 *
 * So please, do not add additional elements to this library, and do
 * not import it.
 */
library secret_tree_element;

/**
 * The superclass of all AST nodes.
 */
abstract class TreeElementMixin {
  // Deliberately using [Object] here to thwart code completion.
  // You're not really supposed to access this field anyways.
  Object _element;
}

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 *
 * Using [Object] as return type to thwart code completion.
 */
Object getTreeElement(TreeElementMixin node) {
  return node._element;
}

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 */
void setTreeElement(TreeElementMixin node, Object value) {
  node._element = value;
}
