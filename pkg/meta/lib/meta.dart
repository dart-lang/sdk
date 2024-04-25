// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

/// Annotations that developers can use to express the intentions that otherwise
/// can't be deduced by statically analyzing the source code.
///
/// See also @[deprecated] and @[override] in the `dart:core` library.
///
/// Annotations provide semantic information that tools can use to provide a
/// better user experience. For example, an IDE might not autocomplete the name
/// of a function that's been marked `@deprecated`, or it might display the
/// function's name differently.
///
/// For information on installing and importing this library, see the
/// [meta package on pub.dev](https://pub.dev/packages/meta). To learn more
/// about using annotations, check out the
/// [Metadata](https://dart.dev/language/metadata) documentation.
library meta;

import 'meta_meta.dart';

/// Used to annotate a function `f`. Indicates that `f` always throws an
/// exception. Any functions that override `f`, in class inheritance, are also
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
///
/// **Deprecated:** This annotation is deprecated and will be
/// removed in a future release of `package:meta`.
/// After Dart 2.9, you can instead specify a return type of `Never`
/// to indicate that a function never returns.
@Deprecated("Use a return type of 'Never' instead")
const _AlwaysThrows alwaysThrows = _AlwaysThrows();

/// Used to annotate a parameter of an instance method that overrides another
/// method.
///
/// Indicates that this parameter may have a tighter type than the parameter on
/// its superclass. The actual argument will be checked at runtime to ensure it
/// is a subtype of the overridden parameter type.
///
/// **Deprecated:** This annotation is deprecated and will be
/// removed in a future release of `package:meta`.
/// In Dart 2 and later, you can instead use the built-in `covariant` modifier.
@Deprecated('Use the `covariant` modifier instead')
const _Checked checked = _Checked();

/// Used to annotate a method, getter or top-level getter or function to
/// indicate that the value obtained by invoking it should not be stored in a
/// field or top-level variable. The annotation can also be applied to a class
/// to implicitly annotate all of the valid members of the class, or applied to
/// a library to annotate all of the valid members of the library, including
/// classes. If a value returned by an element marked as `doNotStore` is returned
/// from a function or getter, that function or getter should be similarly
/// annotated.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a library, class,
///   method or getter, top-level getter or function, or
/// * an invocation of a member that has this annotation is returned by a method,
///   getter or function that is not similarly annotated as `doNotStore`, or
/// * an invocation of a member that has this annotation is assigned to a field
///   or top-level variable.
const _DoNotStore doNotStore = _DoNotStore();

/// Used to annotate a method, getter or top-level getter or function that is
/// not intended to be accessed in checked-in code, but might be ephemerally
/// used during development or local testing.
///
/// The intention of this annotation is to signify an API is available for
/// temporary or ephemeral use (such as debugging or local testing), but should
/// be removed before the code is submitted or merged into a tested branch of
/// the repository (e.g. `main` or similar).
///
/// For example:
///
/// ```dart
/// void test(
///   String name,
///   void Function() testFunction, {
///   @doNotSubmit bool skip = false,
/// }) { /* ... */ }
///
/// void main() {
///   // OK.
///   test('foo', () => print('foo'));
///
///   // HINT: Remove before submitting.
///   test('bar', () => print('bar'), skip: true);
/// }
/// ```
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * a declaration that has this annotation is referenced anywhere, including
///   the library in which it is declared, in checked-in code. Exceptions are
///   being referenced by a declaration that is also annotated with
///   `@doNotSubmit` _or_ referencing a parameter that is annotated with
///   `@doNotSubmit` in the same method or function.
const _DoNotSubmit doNotSubmit = _DoNotSubmit();

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
const _Experimental experimental = _Experimental();

/// Used to annotate an instance or static method `m`. Indicates that `m` must
/// either be abstract or must return a newly allocated object or `null`. In
/// addition, every method that either implements or overrides `m` is implicitly
/// annotated with this same annotation.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, or
/// * a method that has this annotation can return anything other than a newly
///   allocated object or `null`.
const _Factory factory = _Factory();

/// Used to annotate a class `C`. Indicates that `C` and all subtypes of `C`
/// must be immutable.
///
/// A class is immutable if all of the instance fields of the class, whether
/// defined directly or inherited, are `final`.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class, or
/// * a class that has this annotation or extends, implements or mixes in a
///   class that has this annotation is not immutable.
const Immutable immutable = Immutable();

/// Used to annotate a declaration which should only be used from within the
/// package in which it is declared, and which should not be exposed from said
/// package's public API.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the declaration is declared in a package's public API, or is exposed from
///   a package's public API, or
/// * the declaration is private, an unnamed extension, a static member of a
///   private class, mixin, or extension, a value of a private enum, or a
///   constructor of a private class, or
/// * the declaration is referenced outside the package in which it is declared.
const _Internal internal = _Internal();

/// Used to annotate a test framework function that runs a single test.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the test.
const _IsTest isTest = _IsTest();

/// Used to annotate a test framework function that runs a group of tests.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the group.
const _IsTestGroup isTestGroup = _IsTestGroup();

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
const _Literal literal = _Literal();

/// Used to annotate a parameter which should be constant.
///
/// The Dart type system does not allow distinguishing values of constant
/// expressions from other values of the same type, so a function cannot
/// ask to have only constant values as arguments.
/// This annotation marks a parameter as requiring a constant expression as
/// argument. The analyzer can warn, or err if so configured, if a non-constant
/// expression is used as argument.
///
/// The annotation can be applied to any parameter, but if it is applied to a
/// parameter of an instance member, subclasses overriding the member will not
/// inherit the annotation. If the subclass member also wants a constant
/// argument, it must annotate its own parameter as well.
///
/// Notice that if an annotatated instance member overrides a superclass member
/// where the same parameter is not annotated with this annotation, then a user
/// can cast to the superclass and invoke with a non-constant argument without
/// any warnings.
///
/// An example use could be the arguments to functions annotated with
/// [ResourceIdentifier], as only constant arguments can be made available
/// to the post-compile steps.
///
/// ```dart
/// import 'package:meta/meta.dart' show mustBeConst;
///
/// void main() {
///   f();
///   A().i = 3;
/// }
///
/// const v = 3;
///
/// int f() => g(v);
///
/// int g(@mustBeConst int value) => value + 1;
///
/// class A {
///   int? _i;
///
///   int? get i => _i;
///
///   set i(@mustBeConst int? value) {
///     _i = value;
///   }
/// }
/// ```
@experimental
const _MustBeConst mustBeConst = _MustBeConst();

/// Used to annotate an instance member `m` declared on a class or mixin `C`.
/// Indicates that every concrete subclass of `C` must directly override `m`.
///
/// The intention of this annotation is to "re-abtract" a member that was
/// previously concrete, and to ensure that subclasses provide their own
/// implementation of the member. For example:
///
/// ```dart
/// base class Entity {
///   @mustBeOverridden
///   String toString();
/// }
///
/// abstract class AbstractEntity extends Entity {
///   // OK: AbstractEntity is abstract.
/// }
///
/// sealed class SealedEntity extends Entity {
///   // OK: SealedEntity is sealed, which implies abstract.
/// }
///
/// mixin MixinEntity on Entity {
///  // OK: MixinEntity is abstract.
/// }
///
/// class Person extends Entity {
///   // ERROR: Missing new implementation of 'toString'.
/// }
///
/// class Animal extends Entity {
///   // OK: Animal provides its own implementation of 'toString'.
///   String toString() => 'Animal';
/// }
/// ```
///
/// This annotation places no restrictions on the overriding members. In
/// particular, it does not require that the overriding members invoke the
/// overridden member. The annotation [mustCallSuper] can be used to add that
/// requirement.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member
///   (a method, operator, field, getter, or setter) of a class or of a mixin,
///   or
/// * the annotation is associated with a member `m` in class or mixin `C`, and
///   there is a concrete class `D` which is a subclass of `C` (directly or
///   indirectly), and `D` does not directly declare a concrete override of `m`
///   and does not directly declare a concrete override of `noSuchMethod`.
const _MustBeOverridden mustBeOverridden = _MustBeOverridden();

/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) `m`. Indicates that every invocation of a member that overrides `m`
/// must also invoke `m`. In addition, every method that overrides `m` is
/// implicitly annotated with this same annotation.
///
/// Note that private members with this annotation cannot be validly overridden
/// outside of the library that defines the annotated member.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
///   or
/// * a member that overrides a member that has this annotation can return
///   without invoking the overridden member.
const _MustCallSuper mustCallSuper = _MustCallSuper();

/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) `m` in a class `C` or mixin `M`. Indicates that `m` should not be
/// overridden in any classes that extend or mixin `C` or `M`.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
/// * the annotation is associated with an abstract member (because subclasses
///   are required to override the member),
/// * the annotation is associated with an extension method,
/// * the annotation is associated with a member `m` in class `C`, and there is
///   a class `D` or mixin `M`, that extends or mixes in `C`, that declares an
///   overriding member `m`.
const _NonVirtual nonVirtual = _NonVirtual();

/// Used to annotate a class, mixin, extension, function, method, or typedef
/// declaration `C`. Indicates that any type arguments declared on `C` are to
/// be treated as optional.
///
/// Tools such as the analyzer and linter can use this information to suppress
/// warnings that would otherwise require type arguments on `C` to be provided.
const _OptionalTypeArgs optionalTypeArgs = _OptionalTypeArgs();

/// Used to annotate an instance member in a class or mixin which is meant to
/// be visible only within the declaring library, and to other instance members
/// of the class or mixin, and their subtypes.
///
/// If the annotation is on a field it applies to the getter, and setter if
/// appropriate, that are induced by the field.
///
/// Indicates that the annotated instance member (method, getter, setter,
/// operator, or field) `m` in a class or mixin `C` should only be referenced
/// in specific locations. A reference from within the library in which `C` is
/// declared is valid. Additionally, a reference from within an instance member
/// in `C`, or a class that extends, implements, or mixes in `C` (either
/// directly or indirectly) or a mixin that uses `C` as a superclass constraint
/// is valid. Additionally a reference from within an instance member in an
/// extension that applies to `C` is valid.
///
/// Additionally restricts the instance of `C` on which `m` is referenced: a
/// reference to `m` should either be in the same library in which `C` is
/// declared, or should refer to `this.m` (explicitly or implicitly), and not
/// `m` on any other instance of `C`.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
///   or
/// * a reference to a member `m` which has this annotation, declared in a
///   class or mixin `C`, is found outside of the declaring library and outside
///   of an instance member in any class that extends, implements, or mixes in
///   `C` or any mixin that uses `C` as a superclass constraint, or
/// * a reference to a member `m` which has this annotation, declared in a
///   class or mixin `C`, is found outside of the declaring library and the
///   receiver is something other than `this`.
// TODO(srawlins): Add a sentence which defines "referencing" and explicitly
// mentions tearing off, here and on the other annotations which use the word
// "referenced."
const _Protected protected = _Protected();

/// Used to annotate an instance member of an extension type that
/// redeclares a member from a superinterface.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a valid instance
///   member of an extension type (a method, operator, getter, or setter) or
/// * is applied to a member that does not redeclare a member from either the
///   extended type or a superinterface.
@experimental
const _Redeclare redeclare = _Redeclare();

/// Annotation for intentionally loosening restrictions on subtyping that would
/// otherwise cause lint warnings to be produced by the `implicit_reopen` lint.
///
/// Indicates that the annotated class, mixin, or mixin class declaration
/// intentionally allows subtypes outside the library to implement it, or extend
/// it, or mix it in, even though it has some superinterfaces whose restrictions
/// prevent inheritance.
///
/// A class, mixin, or mixin class declaration prevents inheritance if:
///
/// * it is marked `interface` or `final`
/// * it is marked `sealed`, and is implicitly `interface` or `final`
///   based on the modifiers of its superinterfaces
/// * it is an anonymous mixin application, and is implicitly `interface` or
///   `final` based on the modifiers of its superinterfaces
///
/// A declaration annotated with `@reopen` will suppress warnings from the
/// [`implicit_reopen`](https://dart.dev/lints/implicit_reopen) lint.
/// That lint will otherwise warn when a subtype has restrictions that are
/// not sufficient to enforce the restrictions declared by class modifiers on
/// one or more superinterfaces.
///
/// In addition, tools, such as the analyzer, can provide feedback if
///
/// * The annotation is applied to anything other than a class, mixin, or mixin
///   class.
/// * The annotation is applied to a class or mixin which does not require it.
///   (The intent to reopen was not satisfied.)
const _Reopen reopen = _Reopen();

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
///
/// **Deprecated:** This annotation is set to be deprecated and later
/// removed in a future release of `package:meta`.
/// In Dart 2.12 and later, use the built-in `required` keyword
/// to mark a named parameter as required.
/// To learn more about `required`, check out the documentation on
/// [named parameters](https://dart.dev/language/functions#named-parameters).
const Required required = Required();

/// Annotation marking a class as not allowed as a super-type
/// outside of the current package.
///
/// Classes in the same package as the marked class may extend, implement or
/// mix-in the annotated class.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a class,
/// * the annotation is associated with a class `C`, and there is a class or
///   mixin `D`, which extends, implements, mixes in, or constrains to `C`, and
///   `C` and `D` are declared in different packages.
///
/// **Note:** In Dart 3 and later, you can use built-in class modifiers to
/// control what forms of subtyping are allowed outside the current library.
/// To learn more about using class modifiers, check out the
/// [Class modifiers](https://dart.dev/language/class-modifiers) documentation.
const _Sealed sealed = _Sealed();

/// Used to annotate a method, field, or getter within a class, mixin, or
/// extension, or a or top-level getter, variable or function to indicate that
/// the value obtained by invoking it should be used. A value is considered used
/// if it is assigned to a variable, passed to a function, or used as the target
/// of an invocation, or invoked (if the result is itself a function).
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, field or
///   getter, top-level variable, getter or function or
/// * the value obtained by a method, field, getter or top-level getter,
///   variable or function annotated with `@useResult` is not used.
const UseResult useResult = UseResult();

/// Used to annotate a field that is allowed to be overridden in Strong Mode.
///
/// **Deprecated:** This annotation is deprecated and will be
/// removed in a future release of `package:meta`.
/// In Dart 2 and later, overriding fields is allowed by default,
/// so this annotation no longer has any meaning.
/// All uses of the annotation should be removed.
@Deprecated('No longer has meaning')
const _Virtual virtual = _Virtual();

/// Used to annotate an instance member that was made public so that it could be
/// overridden but that is not intended to be referenced from outside the
/// defining library.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration other than a public
///   instance member in a class or mixin, or
/// * the member is referenced outside of the defining library.
const _VisibleForOverriding visibleForOverriding = _VisibleForOverriding();

/// Used to annotate a declaration that was made public, so that it is more
/// visible than otherwise necessary, to make code testable.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration not in the `lib` folder
///   of a package, or a private declaration, or a declaration in an unnamed
///   static extension, or
/// * the declaration is referenced outside of its defining library or a
///   library which is in the `test` folder of the defining package.
const _VisibleForTesting visibleForTesting = _VisibleForTesting();

/// Used to annotate a class.
///
/// See [immutable] for more details.
// TODO(srawlins): Enforce with `TargetKind.classtype`.
class Immutable {
  /// A human-readable explanation of the reason why the class is immutable.
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Immutable([this.reason = '']);
}

/// Used to annotate a named parameter `p` in a method or function `f`.
///
/// See [required] for more details.
///
/// **Deprecated:** This annotation is set to be deprecated and later
/// removed in a future release of `package:meta`.
/// In Dart 2.12 and later, use the built-in `required` keyword
/// to mark a named parameter as required.
/// To learn more about `required`, check out the documentation on
/// [named parameters](https://dart.dev/language/functions#named-parameters).
class Required {
  /// A human-readable explanation of the reason why the annotated parameter is
  /// required. For example, the annotation might look like:
  ///
  /// ```dart
  /// ButtonWidget({
  ///     Function onHover,
  ///     @Required('Buttons must do something when pressed')
  ///     Function onPressed,
  ///     ...
  /// }) ...
  /// ```
  final String reason;

  /// Initialize a newly created instance to have the given [reason].
  const Required([this.reason = '']);
}

/// Annotates a static method as referencing a native resource.
///
/// Applies to static functions, top-level functions, or extension methods.
///
/// During compilation, all statically resolved calls to an annotated function
/// are registered, and information about the annotated functions, the calls,
/// and their arguments, is then made available to post-compile steps.
// TODO(srawlins): Enforce with `TargetKind.method`.
@experimental
class ResourceIdentifier {
  /// Information which is stored together with the function call.
  ///
  /// This could, for example, be the name of the package containing the
  /// function annotated with this annotation. Allowed types are [bool], [int],
  /// [double], and [String].
  final Object? metadata;

  /// Creates a [ResourceIdentifier] instance.
  ///
  /// This annotation can be placed as an annotation on functions whose
  /// statically resolved calls should be registered together with the optional
  /// [metadata] information.
  const ResourceIdentifier([this.metadata])
      : assert(
          metadata == null ||
              metadata is bool ||
              metadata is num ||
              metadata is String,
          'Valid metadata types are bool, int, double, and String.',
        );
}

/// See [useResult] for more details.
@Target({
  TargetKind.constructor,
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
})
class UseResult {
  /// A human-readable explanation of the reason why the value returned by
  /// accessing this member should be used.
  final String reason;

  /// Names a parameter of a method or function that, when present, signals that
  /// the annotated member's value is used by that method or function and does
  /// not need to be further checked.
  final String? parameterDefined;

  /// Initialize a newly created instance to have the given [reason].
  const UseResult([this.reason = '']) : parameterDefined = null;

  /// Initialize a newly created instance to annotate a function or method that
  /// identifies a parameter [parameterDefined] that when present signals that
  /// the result is used by the annotated member and does not need to be further
  /// checked.  For values that need to be used unconditionally, use the unnamed
  /// `UseResult` constructor, or if no reason is specified, the [useResult]
  /// constant.
  ///
  /// Tools, such as the analyzer, can provide feedback if
  ///
  /// * a parameter named by [parameterDefined] is not declared by the annotated
  ///   method or function.
  const UseResult.unless({required this.parameterDefined, this.reason = ''});
}

class _AlwaysThrows {
  const _AlwaysThrows();
}

class _Checked {
  const _Checked();
}

@Target({
  TargetKind.classType,
  // TODO(srawlins): Add `TargetKind.constructor` when this annotation has
  // functional tests. See https://github.com/dart-lang/sdk/issues/48476.
  TargetKind.function,
  TargetKind.getter,
  TargetKind.library,
  TargetKind.method,
})
class _DoNotStore {
  const _DoNotStore();
}

@Target({
  TargetKind.constructor,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.parameter,
  TargetKind.setter,
  TargetKind.topLevelVariable,
})
class _DoNotSubmit {
  const _DoNotSubmit();
}

class _Experimental {
  const _Experimental();
}

// TODO(srawlins): Enforce with `TargetKind.method`.
class _Factory {
  const _Factory();
}

class _Internal {
  const _Internal();
}

// TODO(srawlins): Enforce with `TargetKind.function` (and
// `TargetKind.method`?).
class _IsTest {
  const _IsTest();
}

// TODO(srawlins): Enforce with `TargetKind.function` (and
// `TargetKind.method`?).
class _IsTestGroup {
  const _IsTestGroup();
}

// TODO(srawlins): Enforce with `TargetKind.constructor`.
class _Literal {
  const _Literal();
}

@Target({
  TargetKind.parameter,
  TargetKind.extensionType,
})
class _MustBeConst {
  const _MustBeConst();
}

@Target({
  TargetKind.field,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.setter,
})
class _MustBeOverridden {
  const _MustBeOverridden();
}

@Target({
  TargetKind.field,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.setter,
})
class _MustCallSuper {
  const _MustCallSuper();
}

// TODO(srawlins): Enforce with `TargetKind.method`, `TargetKind.getter`,
// `TargetKind.setter`, `TargetKind.field`.
class _NonVirtual {
  const _NonVirtual();
}

@Target({
  TargetKind.classType,
  TargetKind.extension,
  TargetKind.extensionType,
  TargetKind.function,
  TargetKind.method,
  TargetKind.mixinType,
  TargetKind.typedefType,
})
class _OptionalTypeArgs {
  const _OptionalTypeArgs();
}

// TODO(srawlins): Enforce with `TargetKind.method`, `TargetKind.getter`,
// `TargetKind.setter`, `TargetKind.field`.
class _Protected {
  const _Protected();
}

@Target({
  // TODO(pq): restrict to instance members only
  TargetKind.getter,
  TargetKind.setter,
  TargetKind.method,
})
class _Redeclare {
  const _Redeclare();
}

@Target({
  TargetKind.classType,
  TargetKind.mixinType,
})
class _Reopen {
  const _Reopen();
}

class _Sealed {
  const _Sealed();
}

@Deprecated('No longer has meaning')
class _Virtual {
  const _Virtual();
}

// TODO(srawlins): Enforce with `TargetKind.method`, `TargetKind.getter`,
// `TargetKind.setter`, `TargetKind.field`.
class _VisibleForOverriding {
  const _VisibleForOverriding();
}

// TODO(srawlins): Enforce with `TargetKind.constructor`, `TargetKind.function`,
// `TargetKind.method`, `TargetKind.getter`, `TargetKind.setter`,
// `TargetKind.field`, `TargetKind.parameter`, `TargetKind.typedef`,
// `TargetKind.type`.
class _VisibleForTesting {
  const _VisibleForTesting();
}
