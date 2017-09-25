// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constants for use in metadata annotations.
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

/// Used to annotate a function `f`. Indicates that `f` always throws an
/// exception. Any functions that override `f`, in class inheritence, are also
/// expected to conform to this contract.
///
/// Tools, such as the analyzer, can use this to understand whether a block of
/// code "exits". For example:
///
/// ```dart
/// @alwaysThrows toss() { throw 'Thrown'; }
///
/// int fn(bool b) {
///   if (b) {
///     return 0;
///   } else {
///     toss();
///     print("Hello.");
///   }
/// }
/// ```
///
/// Without the annotation on `toss`, it would look as though `fn` doesn't
/// always return a value. The annotation shows that `fn` does always exit. In
/// addition, the annotation reveals that any statements following a call to
/// `toss` (like the `print` call) are dead code.
///
/// Tools, such as the analyzer, can also expect this contract to be enforced;
/// that is, tools may emit warnings if a function with this annotation
/// _doesn't_ always throw.
const _AlwaysThrows alwaysThrows = const _AlwaysThrows();

/// Used to annotate a parameter of an instance method that overrides another
/// method.
///
/// Indicates that this parameter may have a tighter type than the parameter on
/// its superclass. The actual argument will be checked at runtime to ensure it
/// is a subtype of the overridden parameter type.
const _Checked checked = const _Checked();

/// Used to annotate a library, or any declaration that is part of the public
/// interface of a library (such as top-level members, class members, and
/// function parameters) to indicate that the annotated API is experimental and
/// may be removed or changed at any-time without updating the version of the
/// containing package, despite the fact that it would otherwise be a breaking
/// change.
///
/// If the annotation is applied to a library then it is equivalent to applying
/// the annotation to all of the top-level members of the library. Applying the
/// annotation to a class does *not* apply the annotation to subclasses, but
/// does apply the annotation to members of the class.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration that is not part of the
///   public interface of a library (such as a local variable or a declaration
///   that is private) or a directive other than the first directive in the
///   library, or
/// * the declaration is referenced by a package that has not explicitly
///   indicated its intention to use experimental APIs (details TBD).
const _Experimental experimental = const _Experimental();

/// Used to annotate an instance or static method `m`. Indicates that `m` must
/// either be abstract or must return a newly allocated object or `null`. In
/// addition, every method that either implements or overrides `m` is implicitly
/// annotated with this same annotation.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, or
/// * the annotation is associated with a method that has this annotation that
///   can return anything other than a newly allocated object or `null`.
const _Factory factory = const _Factory();

/// Used to annotate a class `C`. Indicates that `C` and all subtypes of `C`
/// must be immutable.
///
/// A class is immutable if all of the instance fields of the class, whether
/// defined directly or inherited, are `final`.
///
/// Tools, such as the analyzer, can provide feedback if
/// * the annotation is associated with anything other than a class, or
/// * a class that has this annotation or extends, implements or mixes in a
///   class that has this annotation is not immutable.
const Immutable immutable = const Immutable();

/// Used to annotate a const constructor `c`. Indicates that any invocation of
/// the constructor must use the keyword `const` unless one or more of the
/// arguments to the constructor is not a compile-time constant.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a const constructor,
///   or
/// * an invocation of a constructor that has this annotation is not invoked
///   using the `const` keyword unless one or more of the arguments to the
///   constructor is not a compile-time constant.
const _Literal literal = const _Literal();

/// Used to annotate an instance method `m`. Indicates that every invocation of
/// a method that overrides `m` must also invoke `m`. In addition, every method
/// that overrides `m` is implicitly annotated with this same annotation.
///
/// Note that private methods with this annotation cannot be validly overridden
/// outside of the library that defines the annotated method.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance method,
///   or
/// * a method that overrides a method that has this annotation can return
///   without invoking the overridden method.
const _MustCallSuper mustCallSuper = const _MustCallSuper();

/// Used to annotate a class that may not be consumed as an interface.
///
/// This is useful because changes that would result in minor version
/// increments require major version increments when applied to interfaces
/// so packages may want to prevent consumers from implementing certain
/// classes in order to protect semantic version guarantees.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class declaration
/// * a class that has this annotation is used, either directly or
///   transitively, as an interface (using `implements`)
const _NoImplement noImplement = const _NoImplement();

/// Used to annotate a class declaration `C`. Indicates that any type arguments
/// declared on `C` are to be treated as optional.  Tools such as the analyzer
/// and linter can use this information to suppress warnings that would
/// otherwise require type arguments to be provided for instances of `C`.
const _OptionalTypeArgs optionalTypeArgs = const _OptionalTypeArgs();

/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) `m` in a class `C`. If the annotation is on a field it applies to the
/// getter, and setter if appropriate, that are induced by the field. Indicates
/// that `m` should only be invoked from instance methods of `C` or classes that
/// extend, implement or mix in `C`, either directly or indirectly. Additionally
/// indicates that `m` should only be invoked on `this`, whether explicitly or
/// implicitly.
///
/// Tools, such as the analyzer, can provide feedback if
///
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
///
/// * the annotation is associated with anything other than a named parameter,
/// * the annotation is associated with a named parameter in a method `m1` that
///   overrides a method `m0` and `m0` defines a named parameter with the same
///   name that does not have this annotation, or
/// * an invocation of a method or function does not include an argument
///   corresponding to a named parameter that has this annotation.
const Required required = const Required();

/// Used to annotate a field that is allowed to be overridden in Strong Mode.
const _Virtual virtual = const _Virtual();

/// Used to annotate an instance member that was made public so that it could be
/// overridden but that is not intended to be referenced from outside the
/// defining library.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration other than a public
///   instance member in a class, or
/// * the member is referenced outside of the defining library.
const _VisibleForOverriding visibleForOverriding =
    const _VisibleForOverriding();

/// Used to annotate a declaration was made public, so that it is more visible
/// than otherwise necessary, to make code testable.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration not in the `lib` folder
///   of a package, or
/// * the declaration is referenced outside of its the defining library or a
///   library which is in the `test` folder of the defining package.
const _VisibleForTesting visibleForTesting = const _VisibleForTesting();

/// Used to annotate a class.
///
/// See [immutable] for more details.
class Immutable {
  /// A human-readable explanation of the reason why the class is immutable.
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Immutable([this.reason]);
}

/// Used to annotate a named parameter `p` in a method or function `f`.
///
/// See [required] for more details.
class Required {
  /// A human-readable explanation of the reason why the annotated parameter is
  /// required. For example, the annotation might look like:
  ///
  ///     ButtonWidget({
  ///         Function onHover,
  ///         @Required('Buttons must do something when pressed')
  ///         Function onPressed,
  ///         ...
  ///     }) ...
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Required([this.reason]);
}

class _AlwaysThrows {
  const _AlwaysThrows();
}

class _Checked {
  const _Checked();
}

class _Experimental {
  const _Experimental();
}

class _Factory {
  const _Factory();
}

class _Literal {
  const _Literal();
}

class _MustCallSuper {
  const _MustCallSuper();
}

class _NoImplement {
  const _NoImplement();
}

class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}

class _Protected {
  const _Protected();
}

class _Virtual {
  const _Virtual();
}

class _VisibleForOverriding {
  const _VisibleForOverriding();
}

class _VisibleForTesting {
  const _VisibleForTesting();
}
