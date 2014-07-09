// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.bindable;

/// An object that can be data bound.
// Normally this is used with 'package:template_binding'.
// TODO(jmesserly): Node.bind polyfill calls this "observable"
abstract class Bindable {
  // Dart note: changed setValue to be "set value" and discardChanges() to
  // be "get value".

  /// Initiates observation and returns the initial value.
  /// The callback will be called with the updated [value].
  ///
  /// Some subtypes may chose to provide additional arguments, such as
  /// [PathObserver] providing the old value as the second argument.
  /// However, they must support callbacks with as few as 0 or 1 argument.
  /// This can be implemented by performing an "is" type test on the callback.
  open(callback);

  /// Stops future notifications and frees the reference to the callback passed
  /// to [open], so its memory can be collected even if this Bindable is alive.
  void close();

  /// Gets the current value of the bindings.
  /// Note: once the value of a [Bindable] is fetched, the callback passed to
  /// [open] should not be called again with this new value.
  /// In other words, any pending change notifications must be discarded.
  // TODO(jmesserly): I don't like a getter with side effects. Should we just
  // rename the getter/setter pair to discardChanges/setValue like they are in
  // JavaScript?
  get value;

  /// This can be implemented for two-way bindings. By default does nothing.
  set value(newValue) {}

  /// Deliver changes. Typically this will perform dirty-checking, if any is
  /// needed.
  void deliver() {}
}
