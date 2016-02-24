// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constants for use in metadata annotations such as `@protected`.
///
/// See also `@deprecated` and `@override` in the `dart:core` library.
///
/// Annotations provide semantic information that tools can use to provide a
/// better user experience. For example, an IDE might not autocomplete the name
/// of a function that's been marked `@deprecated`, or it might display the
/// function's name differently.
///
/// For information on installing and importing this library, see the
/// [meta package on pub.dartlang.org] (http://pub.dartlang.org/packages/meta).
/// For examples of using annotations, see
/// [Metadata](https://www.dartlang.org/docs/dart-up-and-running/ch02.html#metadata)
/// in the language tour.
library meta;

/// Used to annotate an instance method `m` in a class `C`. Indicates that `m`
/// should only be invoked from instance methods of `C` or classes that extend
/// or mix in `C`, either directly or indirectly. Additionally indicates that
/// `m` should only be invoked on `this`, whether explicitly or implicitly.
///
/// Tools, such as the analyzer, can provide feedback if an invocation of a
/// method marked as being protected is used outside of an instance method
/// defined on a class that extends or mixes in the class in which the protected
/// method is defined, or that uses a receiver other than `this`.
const _Protected protected = const _Protected();

class _Protected {
  const _Protected();
}
