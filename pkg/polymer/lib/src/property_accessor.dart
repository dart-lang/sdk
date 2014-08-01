// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Code for property accessors from declaration/properties.js
part of polymer;

// Dart note: this matches the property defined by createPropertyAccessor in
// polymer-dev/src/declarations/properties.js. Unlike Javascript, we can't
// override the original property, so we instead ask users to write properties
// using this pattern:
//
//     class Foo extends PolymerElement {
//       ...
//       @published
//       get foo => readValue(#foo);
//       set foo(v) { writeValue(#foo, v); }
//
// and internally readValue/writeValue use an instance of this type to
// implement the semantics in createPropertyAccessor.
class _PropertyAccessor<T> {
  // Name of the property, in order to properly fire change notification events.
  final Symbol _name;

  /// The underlying value of the property.
  T _value;

  // Polymer element that contains this property, where change notifications are
  // expected to be fired from.
  final Polymer _target;

  /// Non-null when the property is bound.
  Bindable bindable;

  _PropertyAccessor(this._name, this._target, this._value);

  /// Updates the underlyling value and fires the expected notifications.
  void updateValue(T newValue) {
    var oldValue = _value;
    _value = _target.notifyPropertyChange(_name, oldValue, newValue);
    _target.emitPropertyChangeRecord(_name, newValue, oldValue);
  }

  /// The current value of the property. If the property is bound, reading this
  /// property ensures that the changes are first propagated in order to return
  /// the latest value. Similarly, when setting this property the binding (if
  /// any) will be updated too.
  T get value {
    if (bindable != null) bindable.deliver();
    return _value;
  }

  set value(T newValue) {
    if (bindable != null) {
      bindable.value = newValue;
    } else {
      updateValue(newValue);
    }
  }

  toString() {
    var name = smoke.symbolToName(_name);
    var hasBinding = bindable == null ? '(no-binding)' : '(with-binding)';
    return "[$runtimeType: $_target.$name: $_value $hasBinding]";
  }
}
