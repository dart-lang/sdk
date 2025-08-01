// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations to mark interfaces to JavaScript. All of these annotations are
/// exported via `package:js`.
library _js_annotations;

export 'dart:js_util' show allowInterop, allowInteropCaptureThis;

/// An annotation that indicates a library, class, or member is implemented
/// directly in JavaScript.
///
/// All external members of a class or library with this annotation implicitly
/// have it as well.
///
/// Specifying [name] customizes the JavaScript name to use. By default the
/// dart name is used. It is not valid to specify a custom [name] for class
/// instance members.
class JS {
  final String? name;
  const JS([this.name]);
}

class _Anonymous {
  const _Anonymous();
}

class _StaticInterop {
  const _StaticInterop();
}

/// An annotation that indicates a [JS] annotated class is structural and does
/// not have a known JavaScript prototype.
///
/// A class marked with [anonymous] allows external factories with named
/// parameters. Invoking these factories creates JavaScript object literals with
/// name-value pairs corresponding to any named parameters and their values. If
/// there are no named parameters, an empty JavaScript object is created.
///
/// [anonymous] classes have the following restrictions:
///   - They must contain a [JS] annotation, either from this library or from
///     `dart:js_interop`. If the latter, the class must also contain
///     [staticInterop].
///   - They cannot contain any non-external members unless it's a
///     [staticInterop] class, in which case it can also contain non-external
///     factories and static methods.
///   - They cannot contain any external generative constructors.
///   - Any external factory must not contain any positional parameters.
///   - They cannot extend or be extended by a non-[JS] annotated class.
///   - The annotation should only be applied to non-mixin classes and no other
///     declarations.
const _Anonymous anonymous = _Anonymous();

/// [staticInterop] enables the [JS] annotated class to be treated as a "static"
/// interop class.
///
/// These classes allow interop with native types, like the ones in `dart:html`.
/// These classes implicitly all erase to the internal interceptor
/// `JavaScriptObject`, so they can be freely casted to and from other
/// [staticInterop] types, `dart:html` types, and `JSObject` from
/// `dart:js_interop`. Non-[staticInterop] `package:js` types can be casted to
/// [staticInterop] types, but the reverse can fail if the underlying value is a
/// `@Native`-reserved type (like `dart:html` types).
///
/// [staticInterop] classes have the following restrictions:
///  - They must contain a [JS] annotation, either from this library or from
///    `dart:js_interop`.
///  - They should not contain any instance members, inherited or otherwise, and
///    should instead use static extension members, which can be external or
///    non-external.
///  - They can only contain factories and `static` members. They can be
///    combined with [anonymous] to make external factories create new
///    JavaScript object literals instead.
///  - They should not implement, extend, or mixin non-[staticInterop] classes
///    and vice-versa.
///  - The annotation should only be applied to non-mixin classes and no other
///    declarations.
const _StaticInterop staticInterop = _StaticInterop();

/// NOTE: [trustTypes] is an experimental annotation that may disappear at any
/// point in time. It exists solely to help users who wish to migrate classes
/// from the older style of JS interop to the new static interop model but wish
/// to preserve the older semantics for type checks. This annotation must be
/// used alongside [staticInterop] and it affects any external methods in any
/// extension to the static interop class.
class _TrustTypes {
  const _TrustTypes();
}

const _TrustTypes trustTypes = _TrustTypes();

/// Annotation to allow Dart classes to be wrapped with a JS object using
/// `dart:js_interop`'s `createJSInteropWrapper`.
///
/// When an instance of a class annotated with this annotation is passed to
/// `createJSInteropWrapper`, the method returns a JS object that contains
/// a property for each of the class' instance members. When called, these
/// properties forward to the instance's corresponding members.
///
/// You can either annotate specific instance members to only wrap those members
/// or you can annotate the entire class, which will include all of its instance
/// members.
///
/// By default, the property will have the same name as the corresponding
/// instance member. You can change the property name of a member in the JS
/// object by providing a [name] in the @[JSExport] annotation on the member,
/// like so:
/// ```
/// class Export {
///   @JSExport('printHelloWorld')
///   void printMessage() => print('Hello World!');
/// }
/// ```
/// which will then set the property 'printHelloWorld' in the JS object to
/// forward to `printMessage`.
///
/// Classes and mixins in the hierarchy of the annotated class are included only
/// if they are annotated as well or specific members in them are annotated. If
/// a superclass does not have an annotation anywhere, its members are not
/// included. If members are overridden, only the overriding member will
/// be wrapped as long as it or its class has this annotation.
///
/// Only concrete instance members can and will be wrapped, and it's an error to
/// annotate other members with this annotation.
class JSExport {
  final String name;
  const JSExport([this.name = '']);
}
