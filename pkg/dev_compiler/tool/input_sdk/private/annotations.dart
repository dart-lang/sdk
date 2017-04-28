// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

/// Tells the optimizing compiler to always inline the annotated method.
class ForceInline {
  const ForceInline();
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

/// Marks a class as native and defines its JavaScript name(s).
class Native {
  final String name;
  const Native(this.name);
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
