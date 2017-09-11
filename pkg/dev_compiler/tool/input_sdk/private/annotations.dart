// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

/// Tells the optimizing compiler to always inline the annotated method.
class ForceInline {
  const ForceInline();
}

/// Marks a variable or API to be non-nullable.
/// ****CAUTION******
/// This is currently unchecked, and hence should never be used
/// on any public interface where user code could subclass, implement,
/// or otherwise cause the contract to be violated.
/// TODO(leafp): Consider adding static checking and exposing
/// this to user code.
class NotNull {
  const NotNull();
}

const notNull = const NotNull();

/// Tells the development compiler to check a variable for null at its
/// declaration point, and then to assume that the variable is non-null
/// from that point forward.
/// ****CAUTION******
/// This is currently unchecked, and hence will not catch re-assignments
/// of a variable with null
class NullCheck {
  const NullCheck();
}

const nullCheck = const NullCheck();

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
