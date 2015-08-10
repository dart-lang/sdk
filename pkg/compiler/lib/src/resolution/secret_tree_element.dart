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

import '../dart2jslib.dart' show invariant, Spannable;

/// Interface for associating
abstract class TreeElementMixin {
  Object get _element;
  void set _element(Object value);
}

/// Null implementation of [TreeElementMixin] which does not allow association
/// of elements.
///
/// This class is the superclass of all AST nodes.
abstract class NullTreeElementMixin implements TreeElementMixin, Spannable {

  // Deliberately using [Object] here to thwart code completion.
  // You're not really supposed to access this field anyways.
  Object get _element => null;
  set _element(_) {
    assert(invariant(this, false,
        message: "Elements cannot be associated with ${runtimeType}."));
  }
}

/// Actual implementation of [TreeElementMixin] which stores the associated
/// element in the private field [_element].
///
/// This class is mixed into the node classes that are actually associated with
/// elements.
abstract class StoredTreeElementMixin implements TreeElementMixin {
  Object _element;
}

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 *
 * Using [Object] as return type to thwart code completion.
 */
Object getTreeElement(TreeElementMixin node) => node._element;

/**
 * Do not call this method directly.  Instead, use an instance of
 * TreeElements.
 */
void setTreeElement(TreeElementMixin node, Object value) {
  node._element = value;
}
