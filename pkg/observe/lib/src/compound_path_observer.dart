// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.src.compound_path_observer;

import 'dart:async';
import 'package:observe/observe.dart';

/**
 * CompoundPathObserver is an object which knows how to listen to multiple path
 * values (registered via [addPath]) and invoke a function when one or more
 * of the values have changed. The result of this function will be set into the
 * [value] property. When any value has changed, all current values are provided
 * to the function in the single `values` argument.
 *
 * For example:
 *
 *     var binding = new CompoundPathObserver(computeValue: (values) {
 *       var combinedValue;
 *       // compute combinedValue based on the current values which are provided
 *       return combinedValue;
 *     });
 *     binding.addPath(obj1, path1);
 *     binding.addPath(obj2, path2);
 *     //...
 *     binding.addPath(objN, pathN);
 */
// TODO(jmesserly): this isn't a full port of CompoundPathObserver. It is only
// what was needed for TemplateBinding.
class CompoundPathObserver extends ChangeNotifier {
  List<PathObserver> _observers = [];
  List<StreamSubscription> _subs = [];
  Object _value; // the last computed value

  // TODO(jmesserly): this is public in observe.js
  final Function _computeValue;

  bool _started = false;

  /** True if [start] has been called, otherwise false. */
  bool get started => _started;

  bool _scheduled = false;

  /**
   * Creates a new observer, optionally proving the [computeValue] function
   * for computing the value. You can also set [schedule] to true if you plan
   * to invoke [resolve] manually after initial construction of the binding.
   */
  CompoundPathObserver({computeValue(List values)})
      : _computeValue = computeValue;

  int get length => _observers.length;

  @reflectable get value => _value;

  void addPath(model, String path) {
    if (_started) {
      throw new StateError('Cannot add more paths once started.');
    }

    _observers.add(new PathObserver(model, path));
  }

  void start() {
    if (_started) return;
    _started = true;

    final scheduleResolve = _scheduleResolve;
    for (var observer in _observers) {
      _subs.add(observer.changes.listen(scheduleResolve));
    }
    _resolve();
  }

  // TODO(rafaelw): Is this the right processing model?
  // TODO(rafaelw): Consider having a seperate ChangeSummary for
  // CompoundBindings so to excess dirtyChecks.
  void _scheduleResolve(_) {
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_resolve);
  }

  void _resolve() {
    _scheduled = false;
    if (_observers.isEmpty) return;
    var newValue = _observers.map((o) => o.value).toList();
    if (_computeValue != null) newValue = _computeValue(newValue);
    _value = notifyPropertyChange(#value, _value, newValue);
  }

  /**
   * Closes the observer.
   *
   * This happens automatically if the [value] property is no longer observed,
   * but this can also be called explicitly.
   */
  void close() {
    if (_observers.isEmpty) return;

    if (_started) {
      for (StreamSubscription sub in _subs) {
        sub.cancel();
      }
    }
    _observers.clear();
    _subs.clear();
    _value = null;
  }

  observed() => start();
  unobserved() => close();
}
