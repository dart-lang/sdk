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

/// Used to annotate an instance method `m`. Indicates that `m` must either be
/// abstract or must return a newly allocated object. In addition, every method
/// that either implements or overrides `m` is implicitly annotated with this
/// same annotation.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than an instance method,
///   or
/// * a method that has this annotation that can return anything other than a
///   newly allocated object.
const _Factory factory = const _Factory();

/// Used to annotate an instance method `m`. Indicates that every invocation of
/// a method that overrides `m` must also invoke `m`. In addition, every method
/// that overrides `m` is implicitly annotated with this same annotation.
///
/// Note that private methods with this annotation cannot be validly overridden
/// outside of the library that defines the annotated method.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than an instance method,
///   or
/// * a method that overrides a method that has this annotation can return
///   without invoking the overridden method.
const _MustCallSuper mustCallSuper = const _MustCallSuper();

/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) `m` in a class `C`. If the annotation is on a field it applies to the
/// getter, and setter if appropriate, that are induced by the field. Indicates
/// that `m` should only be invoked from instance methods of `C` or classes that
/// extend or mix in `C`, either directly or indirectly. Additionally indicates
/// that `m` should only be invoked on `this`, whether explicitly or implicitly.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than an instance member,
///   or
/// * an invocation of a member that has this annotation is used outside of an
///   instance member defined on a class that extends or mixes in the class in
///   which the protected member is defined, or that uses a receiver other than
///   `this`.
const _Protected protected = const _Protected();

/// Used to annotate a named parameter `p` in a method or function `f`.
/// Indicates that every invocation of `f` must include an argument
/// corresponding to `p`, despite the fact that `p` would otherwise be an
/// optional parameter.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than a named parameter,
/// * the annotation is associated with a named parameter in a method `m1` that
///   overrides a method `m0` and `m0` defines a named parameter with the same
///   name that does not have this annotation, or
/// * an invocation of a method or function does not include an argument
///   corresponding to a named parameter that has this annotation.
const _Required required = const _Required();

class _Factory {
  const _Factory();
}

class _MustCallSuper {
  const _MustCallSuper();
}

class _Protected {
  const _Protected();
}

class _Required {
  const _Required();
}
