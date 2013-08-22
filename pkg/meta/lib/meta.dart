// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Constants for use in metadata annotations such as
 * `@deprecated`, `@override`, and `@proxy`.
 * 
 * Annotations provide semantic information
 * that tools can use to provide a better user experience.
 * For example, an IDE might not autocomplete
 * the name of a function that's been marked `@deprecated`,
 * or it might display the function's name differently.
 *
 * For information on installing and importing this library, see the
 * [meta package on pub.dartlang.org]
 * (http://pub.dartlang.org/packages/meta).
 * For examples of using annotations, see
 * [Metadata](https://www.dartlang.org/docs/dart-up-and-running/contents/ch02.html#ch02-metadata)
 * in the language tour.
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

/**
 * An annotation used to mark a class that should be considered to implement
 * every possible getter, setter and method. Tools can use this annotation to
 * suppress warnings when there is no explicit implementation of a referenced
 * member. Tools should provide a hint if this annotation is applied to a class
 * that does not implement or inherit an implementation of the method
 * [:noSuchMethod:] (other than the implementation in [Object]). Note that
 * classes are not affected by the use of this annotation on a supertype.
 */
const proxy = const _Proxy();

class _Proxy {
  const _Proxy();
}