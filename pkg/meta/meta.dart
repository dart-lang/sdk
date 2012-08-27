// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library contains the definitions of annotations that provide additional
 * semantic information about the program being annotated. These annotations are
 * intended to be used by tools to provide a better user experience.
 */
library meta;

/**
 * An annotation used to mark a class, field, getter, setter, method, top-level
 * variable, or top-level function as one that should no longer be used. Tools
 * can use this annotation to provide a warning on references to the marked
 * element.
 */
const deprecated = const _Deprecated();

class _Deprecated {
  const _Deprecated();
}

/**
 * An annotation used to mark an instance member (method, field, getter or
 * setter) as overriding an inherited class member. Tools can use this
 * annotation to provide a warning if there is no overridden member.
 */
const override = const _Override();

class _Override {
  const _Override();
}
