// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Constants for use in metadata annotations such as
 * `@proxy`.
 *
 * See also `@deprecated` and `@override` in the `dart:core` library.
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
