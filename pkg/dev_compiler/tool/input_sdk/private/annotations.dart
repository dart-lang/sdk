// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

/// Tells the optimizing compiler that the annotated method has no
/// side-effects.
/// Requires @NoInline() to function correctly.
class NoSideEffects {
  const NoSideEffects();
}

/// Tells the optimizing compiler that the annotated method cannot throw.
/// Requires @NoInline() to function correctly.
class NoThrows {
  const NoThrows();
}

/// Tells the optimizing compiler to not inline the annotated method.
class NoInline {
  const NoInline();
}

// Ensures that the annotated method is represented internally using
// IR nodes ([:value == true:]) or AST nodes ([:value == false:]).
class IrRepresentation {
  final bool value;
  const IrRepresentation(this.value);
}

/// Marks a class as native and defines its JavaScript name(s).
class Native {
  final String name;
  const Native(this.name);
}

// TODO(jmesserly): move these somewhere else, e.g. package:js or dart:js

class JsName {
  /// The JavaScript name.
  /// Used for classes and libraries.
  /// Note that this could be an expression, e.g. `lib.TypeName` in JS, but it
  /// should be kept simple, as it will be generated directly into the code.
  final String name;
  const JsName({this.name});
}

class JsPeerInterface {
  /// The JavaScript type that we should match the API of.
  /// Used for classes where Dart subclasses should be callable from JavaScript
  /// matching the JavaScript calling conventions.
  final String name;
  const JsPeerInterface({this.name});
}

/// A Dart interface may only be implemented by a native JavaScript object
/// if it is marked with this annotation.
class SupportJsExtensionMethods {
  const SupportJsExtensionMethods();
}
