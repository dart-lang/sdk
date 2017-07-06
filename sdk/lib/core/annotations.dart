// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:core";

/**
 * The annotation `@Deprecated('expires when')` marks a feature as deprecated.
 *
 * The annotation `@deprecated` is a shorthand for deprecating until
 * an unspecified "next release".
 *
 * The intent of the `@Deprecated` annotation is to inform users of a feature
 * that they should change their code, even if it is currently still working
 * correctly.
 *
 * A deprecated feature is scheduled to be removed at a later time, possibly
 * specified as the "expires" field of the annotation.
 * This means that a deprecated feature should not be used, or code using it
 * will break at some point in the future. If there is code using the feature,
 * that code should be rewritten to not use the deprecated feature.
 *
 * A deprecated feature should document how the same effect can be achieved,
 * so the programmer knows how to rewrite the code.
 *
 * The `@Deprecated` annotation applies to libraries, top-level declarations
 * (variables, getters, setters, functions, classes and typedefs),
 * class-level declarations (variables, getters, setters, methods, operators or
 * constructors, whether static or not), named optional arguments and
 * trailing optional positional parameters.
 *
 * Deprecation is transitive:
 *
 *  - If a library is deprecated, so is every member of it.
 *  - If a class is deprecated, so is every member of it.
 *  - If a variable is deprecated, so are its implicit getter and setter.
 *
 *
 * A tool that processes Dart source code may report when:
 *
 * - the code imports a deprecated library.
 * - the code exports a deprecated library, or any deprecated member of
 *   a non-deprecated library.
 * - the code refers statically to a deprecated declaration.
 * - the code dynamically uses a member of an object with a statically known
 *   type, where the member is deprecated on the static type of the object.
 * - the code dynamically calls a method with an argument where the
 *   corresponding optional parameter is deprecated on the object's static type.
 *
 *
 * If the deprecated use is inside a library, class or method which is itself
 * deprecated, the tool should not bother the user about it.
 * A deprecated feature is expected to use other deprecated features.
 */
class Deprecated {
  /**
   * A description of when the deprecated feature is expected to be retired.
   */
  final String expires;

  /**
   * Create a deprecation annotation which specifies the expiration of the
   * annotated feature.
   *
   * The [expires] argument should be readable by programmers, and should state
   * when an annotated feature is expected to be removed.
   * This can be specified, for example, as a date, as a release number, or
   * as relative to some other change (like "when bug 4418 is fixed").
   */
  const Deprecated(String expires) : this.expires = expires;

  String toString() => "Deprecated feature. Will be removed $expires";
}

class _Override {
  const _Override();
}

/**
 * Marks a feature as [Deprecated] until the next release.
 */
const Deprecated deprecated = const Deprecated("next release");

/**
 * The annotation `@override` marks an instance member as overriding a
 * superclass member with the same name.
 *
 * The annotation applies to instance methods, getters and setters, and to
 * instance fields, where it means that the implicit getter and setter of the
 * field is marked as overriding, but the field itself is not.
 *
 * The intent of the `@override` notation is to catch situations where a
 * superclass renames a member, and an independent subclass which used to
 * override the member, could silently continue working using the
 * superclass implementation.
 *
 * The editor, or a similar tool aimed at the programmer, may report if no
 * declaration of an annotated member is inherited by the class from either a
 * superclass or an interface.
 *
 * Use the `@override` annotation judiciously and only for methods where
 * the superclass is not under the programmer's control, the superclass is in a
 * different library or package, and it is not considered stable.
 * In any case, the use of `@override` is optional.
 *
 * For example, the annotation is intentionally not used in the Dart platform
 * libraries, since they only depend on themselves.
 */
const Object override = const _Override();

class _Proxy {
  const _Proxy();
}

/**
 * The annotation `@proxy` marks a class as implementing members dynamically
 * through `noSuchMethod`.
 *
 * The annotation applies to any class. It is inherited by subclasses from both
 * superclass and interfaces.
 *
 * If a class is annotated with `@proxy`, or it implements any class that is
 * annotated, then the class is considered to implement any member with regard
 * to static type analysis.
 * As such, it is not a static type warning to access any member of the object
 * which is not implemented by the class, or to call a method with a different
 * number of parameters than it is declared with.
 *
 * The annotation does not change which classes the annotated class implements,
 * and does not prevent static warnings for assigning an object to a variable
 * with a static type not implemented by the object.
 *
 * The suppression of warnings only affect static type warnings about
 * member access.
 * The runtime type of the object is unaffected.
 * It is not considered to implement any special interfaces,
 * so assigning it to a typed variable may fail in checked mode,
 * and testing it with the `is` operator
 * will only return true for types it actually implements or extends.
 * Accessing a member which isn't implemented by the class
 * will cause the `noSuchMethod` method to be called normally,
 * the `@proxy` annotation merely states the intent to handle (some of) those
 * `noSuchMethod` calls gracefully.
 *
 * A class that marked as `@proxy` should override the `noSuchMethod`
 * declared on [Object].
 *
 * The intent of the `@proxy` notation is to create objects that implement a
 * type (or multiple types) that are not known at compile time. If the types
 * are known at compile time, a class can be written that implements these
 * types.
 */
const Object proxy = const _Proxy();
