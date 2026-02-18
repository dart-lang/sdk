// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
// ignore: unnecessary_library_name
library meta;

import 'meta_meta.dart';

/// Annotation marking a function as always throwing.
///
/// Used to annotate a function. Indicates that the function always throws.
/// Any instance members that override an annotated function
/// are also expected to conform to this contract.
///
/// In pre Dart 2.0 code, tools like as the analyzer could use this to
/// understand whether a block of code "exits". For example:
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
const Object alwaysThrows = _AlwaysThrows();

/// Annotation on asynchronous function whose [Future] can be ignored.
///
/// Used to annotate a [Future]-returning function (including constructors,
/// getters, methods, and operators), or a [Future]-typed variable declaration
/// (including top-level, instance, and static variables).
/// Indicates that the [Future] value does not need to be awaited.
/// This means both that the future will *not* complete with an error,
/// and that any value it completes with does not need to be disposed or handled
/// in any way.
///
/// Any instance member that override an annotated member,
/// are also expected to conform to this contract.
///
/// Tools, such as the analyzer, can use this to decide whether to report
/// that a [Future]-typed value needs to be awaited:
///
/// ```dart
/// @awaitNotRequired
/// Future<LogMessage> log(String message) { ... }
///
/// void fn() {
///   log('Message'); // Not necessary to wait for logging to complete.
/// }
/// ```
///
/// Without the annotation on `log`, the analyzer may report a lint diagnostic
/// at the call to `log`, such as `discarded_futures` or `unawaited_futures`,
/// regarding the danger of not awaiting the function call, depending on what
/// lint rules are enabled.
///
/// Tools, such as the analyzer, can also provide feedback if
///
/// * the annotation is associated with anything other than a constructor,
///   function, method, operator or variable, or
/// * the annotation is associated with a constructor, function, method, or
///   operator that does not return a [Future], or
/// * the annotation is associated with a field or top-level variable that is
///   not typed as a [Future].
const Object awaitNotRequired = _AwaitNotRequired();

/// Annotation that no longer has any effect.
///
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
const Object checked = _Checked();

/// Annotation on function or property whose value must not be stored.
///
/// Used to annotate a method, getter, top-level function, or top-level getter
/// to indicate that the value obtained by invoking it should not be stored in a
/// field or top-level variable. The annotation can also be applied to a class
/// to implicitly annotate all of the valid members of the class, or applied to
/// a library to annotate all of the valid members of the library, including
/// classes. If a value returned by an element marked as `doNotStore` is
/// returned from a function or getter, that function or getter should be
/// similarly annotated.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a library, class,
///   method or getter, top-level getter or function, or
/// * an invocation of a member that has this annotation is returned by a
///   method, function or getter that is not similarly annotated as
///   `doNotStore`, or
/// * an invocation of a member that has this annotation is assigned to a field
///   or top-level variable.
const Object doNotStore = _DoNotStore();

/// Annotation marking declaration that should be removed before publishing.
///
/// Used to annotate an optional parameter, method, getter or top-level getter
/// or function that is not intended to be accessed in checked-in code, but
/// might be ephemerally used during development or local testing.
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
const Object doNotSubmit = _DoNotSubmit();

/// Annotation marking declaration as experimental and subject to change.
///
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
const Object experimental = _Experimental();

/// Annotation on a function that creates new objects.
///
/// Used to annotate an instance or static method.
///
/// Indicates that the method must either be abstract (for an instance method)
/// or must return either a newly allocated object or `null`.
/// In addition, every instance method that implements or overrides the method
/// is implicitly annotated with this same annotation.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a method, or
/// * a method that has this annotation can return anything other than a newly
///   allocated object or `null`.
const Object factory = _Factory();

/// Annotation on an immutable class.
///
/// Used to annotate a class declaration.
///
/// Indicates that the class, and all subtypes of it, must be immutable.
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

/// Annotation on declaration that should not be used outside of its package.
///
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
const Object internal = _Internal();

/// Annotation on a test framework function that introduces a single test.
///
/// Used to annotate a test framework function that runs a single test.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the test.
const Object isTest = _IsTest();

/// Annotation on a test framework function that introduces a group of tests.
///
/// Used to annotate a test framework function that runs a group of tests.
///
/// Tools, such as IDEs, can show invocations of such function in a file
/// structure view to help the user navigating in large test files.
///
/// The first parameter of the function must be the description of the group.
const Object isTestGroup = _IsTestGroup();

/// Annotation on constructor that must be invoked with `const` if possible.
///
/// Used to annotate a const constructor. Indicates that any invocation of
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
const Object literal = _Literal();

/// Annotation on a parameter whose arguments must be constants.
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
/// Notice that if an annotated instance member overrides a superclass member
/// where the same parameter is not annotated with this annotation, then a user
/// can cast to the superclass and invoke with a non-constant argument without
/// any warnings.
///
/// An example use could be the arguments to functions annotated with
/// [RecordUse], as only constant arguments can be made available
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
const Object mustBeConst = _MustBeConst();

/// Annotation on instance members that must be overridden by subclasses.
///
/// Used to annotate an instance member in a class or mixin declaration.
/// Indicates that every concrete subclass must declare an override for the
/// annotated member.
///
/// The intention of this annotation is to "re-abstract" a member that was
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
const Object mustBeOverridden = _MustBeOverridden();

/// Annotation on instance member that overriding members must call.
///
/// Used to annotate an instance member (method, getter, setter, operator, or
/// field). Indicates that every invocation of an overriding member
/// will also invoke the current implementation of the member.
/// In addition, every overriding member is implicitly annotated
/// with this same annotation.
///
/// Note that private members with this annotation cannot be overridden
/// outside of the library that defines the annotated member.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
/// * the annotation is applied to an instance member with no concrete
///   implementation, or
/// * a member that overrides a member that has this annotation can return
///   without invoking the overridden member.
const Object mustCallSuper = _MustCallSuper();

/// Annotation on instance member that must not be overridden.
///
/// Used to annotate an instance member (method, getter, setter, operator, or
/// field) in a class or mixin declaration. Indicates that the member must
/// not be overridden in any subclass that extends the class or
/// mixes in the mixin.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than an instance member,
/// * the annotation is associated with an abstract member (because subclasses
///   would be required to override the member),
/// * the annotation is associated with an extension method,
/// * the annotation is associated with a member `m` in class or mixin `C`,
///   and there is a class `D` that extends or mixes in `C`, that declares an
///   overriding member `m`.
const Object nonVirtual = _NonVirtual();

/// Annotation on type arguments that can safely be omitted.
///
/// Used to annotate a class, mixin, extension, function, method, or typedef
/// declaration. Indicates that any type arguments of the declaration are
/// optional.
///
/// Tools such as the analyzer and linter can use this information to suppress
/// warnings that would otherwise require type arguments to be provided.
/// _The language itself always allows omitting type arguments, this annotation
/// only affects optional and opt-in warnings about omitting type arguments._
const Object optionalTypeArgs = _OptionalTypeArgs();

/// Annotation on instance member that should only be used by subclasses.
///
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
const Object protected = _Protected();

/// Annotation on extension type members which redeclare superinterface members.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with anything other than a valid instance
///   member of an extension type (a method, operator, getter, or setter) or
/// * is applied to a member that does not redeclare a member from either the
///   extended type or a superinterface.
const Object redeclare = _Redeclare();

/// Annotation on declaration with less access restrictions than superinterface.
///
/// Indicates that the annotated class, mixin, or mixin class declaration
/// intentionally allows subtypes outside the library to implement it, or extend
/// it, or mix it in, even though it has some superinterfaces whose restrictions
/// prevent inheritance.
/// Such a subtype would otherwise cause lint warnings from the
/// `implicit_reopen` lint.
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
const Object reopen = _Reopen();

/// Annotation on named parameter that should always have an argument supplied.
///
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
/// **Deprecated:** This annotation is set to be removed in a future release of
/// `package:meta`.
///
/// In Dart 2.12 and later, use the built-in `required` keyword
/// to mark a named parameter as required.
/// To learn more about `required`, check out the documentation on
/// [named parameters](https://dart.dev/language/functions#named-parameters).
@Deprecated(
    'In Dart 2.12 and later, use the built-in `required` keyword to mark a '
    'named parameter as required.')
const Required required = Required();

/// Annotation on class that must not be subclassed outside of its package.
///
/// Classes in the same package as the marked class may extend, implement or
/// mix-in the annotated class as normal.
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
const Object sealed = _Sealed();

/// Annotation on function or property whose value must not be ignored.
///
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

/// Annotation which no longer has any effect.
///
/// Used to annotate a field that is allowed to be overridden in Strong Mode.
///
/// **Deprecated:** This annotation is deprecated and will be
/// removed in a future release of `package:meta`.
/// In Dart 2 and later, overriding fields is allowed by default,
/// so this annotation no longer has any meaning.
/// All uses of the annotation should be removed.
@Deprecated('No longer has meaning')
const Object virtual = _Virtual();

/// Annotation on declaration that should not be used outside of its package.
///
/// Used to annotate an instance member that was made public so that it could be
/// overridden but that is not intended to be referenced from outside the
/// defining library.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration other than a public
///   instance member in a class or mixin, or
/// * the member is referenced outside of the defining library.
const Object visibleForOverriding = _VisibleForOverriding();

/// Annotation on a public declaration that should only be used in tests.
///
/// Used to annotate a declaration that was made public only for tests.
///
/// The declaration should not be treated as available, and should not
/// be used outside of testing, and not outside of the declaring package
/// unless explicitly allowed.
///
/// The annotation is only intended for declarations that are otherwise
/// publicly available, meaning an accessible declaration in the `lib/` folder
/// of a package.
///
/// Tools, such as the analyzer, can provide feedback if
///
/// * the annotation is associated with a declaration not in the `lib` folder
///   of a package, or a private declaration, or a declaration in an unnamed
///   static extension, or
/// * the declaration is referenced outside of its defining library or a
///   library which is in the `test` folder of a package.
const Object visibleForTesting = _VisibleForTesting();

/// Annotation on an immutable class.
///
/// Used to annotate a class declaration.
///
/// Indicates that the class, and all subtypes of it, must be immutable.
///
/// A class is immutable if all of the instance fields of the class, whether
/// defined directly or inherited, are `final`.
///
/// This class has a [reason] field that can be displayed as part of the
/// error message if a subclass is not immutable.
///
/// See [immutable] for more details.
@Target({
  TargetKind.classType,
  TargetKind.extensionType,
  TargetKind.mixinType,
})
class Immutable {
  /// A human-readable explanation of the reason why the class is immutable.
  final String reason;

  /// Creates annotation for being immutable with the given [reason].
  const Immutable([this.reason = '']);
}

/// Annotation on static method or class whose accesses will be recorded.
///
/// Applies to static functions, top-level functions, extension methods, or
/// classes with constant constructors.
///
/// During compilation, all statically resolved calls to an annotated function
/// or accesses to constant instances of an annotated class in reachable code
/// are recorded. Information about these usages is then made available to
/// post-compile steps.
///
/// Only usages in reachable code (executable code) are tracked.
/// Usages appearing within metadata (annotations) are ignored.
// TODO(srawlins): Enforce with `TargetKind.method` or `TargetKind.classType`.
@experimental
class RecordUse {
  /// Creates a [RecordUse] instance.
  ///
  /// This annotation can be placed as an annotation on functions or classes
  /// whose usages in reachable code should be registered.
  const RecordUse();
}

/// Annotation on a required named parameter.
///
/// See [required] for more details.
///
/// **Deprecated:** This annotation is set to be removed in a future release of
/// `package:meta`.
///
/// In Dart 2.12 and later, use the built-in `required` keyword
/// to mark a named parameter as required.
/// To learn more about `required`, check out the documentation on
/// [named parameters](https://dart.dev/language/functions#named-parameters).
@Deprecated(
    'In Dart 2.12 and later, use the built-in `required` keyword to mark a '
    'named parameter as required.')
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

/// Annotation on function or property whose value must not be ignored.
///
/// See [useResult] for more details.
///
/// Using this class's constructor allows providing a [reason] text
/// that can be displayed along with the error if a result value is not used.
///
/// Also allows defining a separate parameter of the same function,
/// which if passed, will be considered as using the the result.
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
  /// Example:
  /// ```dart
  /// @UseResult.unless(
  ///   parameterDefined: 'disposer',
  ///   reason: 'must be disposed',
  /// )
  /// Resource allocateResource({Disposer? disposer}) {
  ///   var resource = _newResource();
  ///   disposer?.scheduleDisposal(resource);
  ///   return resource;
  /// }
  /// ```
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

/// See [awaitNotRequired] for more details.
@Target({
  TargetKind.constructor,
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.topLevelVariable,
  TargetKind.typedefType,
})
class _AwaitNotRequired {
  const _AwaitNotRequired();
}

class _Checked {
  const _Checked();
}

@Target({
  TargetKind.classType,
  TargetKind.constructor,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.library,
  TargetKind.method,
  TargetKind.mixinType,
})
class _DoNotStore {
  const _DoNotStore();
}

@Target({
  TargetKind.constructor,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.optionalParameter,
  TargetKind.setter,
  TargetKind.topLevelVariable,
})
class _DoNotSubmit {
  const _DoNotSubmit();
}

class _Experimental {
  const _Experimental();
}

@Target({
  TargetKind.method,
})
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

@Target({
  TargetKind.constructor,
})
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
  TargetKind.overridableMember,
})
class _MustBeOverridden {
  const _MustBeOverridden();
}

@Target({
  TargetKind.overridableMember,
})
class _MustCallSuper {
  const _MustCallSuper();
}

@Target({TargetKind.overridableMember})
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

@Target({
  TargetKind.classType,
})
class _Sealed {
  const _Sealed();
}

@Deprecated('No longer has meaning')
class _Virtual {
  const _Virtual();
}

@Target({
  TargetKind.overridableMember,
})
class _VisibleForOverriding {
  const _VisibleForOverriding();
}

@Target({
  TargetKind.constructor,
  TargetKind.enumValue,
  TargetKind.extension,
  TargetKind.extensionType,
  TargetKind.field,
  TargetKind.function,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.parameter,
  TargetKind.setter,
  TargetKind.typedefType,
  TargetKind.type,
  TargetKind.topLevelVariable,
})
class _VisibleForTesting {
  const _VisibleForTesting();
}
