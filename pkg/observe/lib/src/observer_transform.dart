// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.observer_transform;

import 'package:observe/observe.dart';

/// ObserverTransform is used to dynamically transform observed value(s).
///
///    var obj = new ObservableBox(10);
///    var observer = new PathObserver(obj, 'value');
///    var transform = new ObserverTransform(observer,
///        (x) => x * 2, setValue: (x) => x ~/ 2);
///
///    // Open returns the current value of 20.
///    transform.open((newValue) => print('new: $newValue'));
///
///    obj.value = 20; // prints 'new: 40' async
///    new Future(() {
///      transform.value = 4; // obj.value will be 2
///    });
///
/// ObserverTransform can also be used to reduce a set of observed values to a
/// single value:
///
///    var obj = new ObservableMap.from({'a': 1, 'b': 2, 'c': 3});
///    var observer = new CompoundObserver()
///      ..addPath(obj, 'a')
///      ..addPath(obj, 'b')
///      ..addPath(obj, 'c');
///
///    var transform = new ObserverTransform(observer,
///        (values) => values.fold(0, (x, y) => x + y));
///
///    // Open returns the current value of 6.
///    transform.open((newValue) => print('new: $newValue'));
///
///    obj['a'] = 2;
///    obj['c'] = 10; // will print 'new 14' asynchronously
///
class ObserverTransform extends Bindable {
  Bindable _bindable;
  Function _getTransformer, _setTransformer;
  Function _notifyCallback;
  var _value;

  ObserverTransform(Bindable bindable, computeValue(value), {setValue(value)})
      : _bindable = bindable,
        _getTransformer = computeValue,
        _setTransformer = setValue;

  open(callback(value)) {
    _notifyCallback = callback;
    _value = _getTransformer(_bindable.open(_observedCallback));
    return _value;
  }

  _observedCallback(newValue) {
    final value = _getTransformer(newValue);
    if (value == _value) return null;
    _value = value;
    return _notifyCallback(value);
  }

  void close() {
    if (_bindable != null) _bindable.close();
    _bindable = null;
    _getTransformer = null;
    _setTransformer = null;
    _notifyCallback = null;
    _value = null;
  }

  get value => _value = _getTransformer(_bindable.value);

  set value(newValue) {
    if (_setTransformer != null) {
      newValue = _setTransformer(newValue);
    }
    _bindable.value = newValue;
  }

  deliver() => _bindable.deliver();
}
