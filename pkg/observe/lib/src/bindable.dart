// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.bindable;

/// An object that can be data bound.
// Normally this is used with 'package:template_binding'.
// TODO(jmesserly): Node.bind polyfill calls this "observable"
abstract class Bindable {
  // TODO(jmesserly): since we have "value", should open be a void method?
  // Dart note: changed setValue to be "set value" and discardChanges() to
  // be "get value". Also "set value" implies discard changes.
  // TOOD(jmesserly): is this change too subtle? Is there any other way to
  // make Bindable friendly in a world with getters/setters?

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
  get value;

  /// This can be implemented for two-way bindings. By default does nothing.
  /// Note: setting the value of a [Bindable] must not call the [callback] with
  /// the new value. Any pending change notifications must be discarded.
  set value(newValue) {}
}
