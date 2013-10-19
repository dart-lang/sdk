// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/** The callback used in the [CompoundBinding.combinator] field. */
typedef Object CompoundBindingCombinator(Map objects);

/**
 * CompoundBinding is an object which knows how to listen to multiple path
 * values (registered via [bind]) and invoke its [combinator] when one or more
 * of the values have changed and set its [value] property to the return value
 * of the function. When any value has changed, all current values are provided
 * to the [combinator] in the single `values` argument.
 *
 * For example:
 *
 *     var binding = new CompoundBinding((values) {
 *       var combinedValue;
 *       // compute combinedValue based on the current values which are provided
 *       return combinedValue;
 *     });
 *     binding.bind('name1', obj1, path1);
 *     binding.bind('name2', obj2, path2);
 *     //...
 *     binding.bind('nameN', objN, pathN);
 */
// TODO(jmesserly): rename to something that indicates it's a computed value?
class CompoundBinding extends ChangeNotifier {
  CompoundBindingCombinator _combinator;

  // TODO(jmesserly): ideally these would be String keys, but sometimes we
  // use integers.
  Map<dynamic, StreamSubscription> _observers = new Map();
  Map _values = new Map();
  Object _value;

  /**
   * True if [resolve] is scheduled. You can set this to true if you plan to
   * call [resolve] manually, avoiding the need for scheduling an asynchronous
   * resolve.
   */
  // TODO(jmesserly): I don't like having this public, is the optimization
  // really needed? "scheduleMicrotask" in Dart should be pretty cheap.
  bool scheduled = false;

  /**
   * Creates a new CompoundBinding, optionally proving the [combinator] function
   * for computing the value. You can also set [schedule] to true if you plan
   * to invoke [resolve] manually after initial construction of the binding.
   */
  CompoundBinding([CompoundBindingCombinator combinator]) {
    // TODO(jmesserly): this is a tweak to the original code, it seemed to me
    // that passing the combinator to the constructor should be equivalent to
    // setting it via the property.
    // I also added a null check to the combinator setter.
    this.combinator = combinator;
  }

  CompoundBindingCombinator get combinator => _combinator;

  set combinator(CompoundBindingCombinator combinator) {
    _combinator = combinator;
    if (combinator != null) _scheduleResolve();
  }

  int get length => _observers.length;

  @reflectable get value => _value;

  @reflectable void set value(newValue) {
    _value = notifyPropertyChange(#value, _value, newValue);
  }

  void bind(name, model, String path) {
    unbind(name);

     // TODO(jmesserly): should we delay observing until we are observed,
     // similar to PathObserver?
    _observers[name] = new PathObserver(model, path).bindSync((value) {
      _values[name] = value;
      _scheduleResolve();
    });
  }

  void unbind(name, {bool suppressResolve: false}) {
    var binding = _observers.remove(name);
    if (binding == null) return;

    binding.cancel();
    _values.remove(name);
    if (!suppressResolve) _scheduleResolve();
  }

  // TODO(rafaelw): Is this the right processing model?
  // TODO(rafaelw): Consider having a seperate ChangeSummary for
  // CompoundBindings so to excess dirtyChecks.
  void _scheduleResolve() {
    if (scheduled) return;
    scheduled = true;
    scheduleMicrotask(resolve);
  }

  void resolve() {
    if (_observers.isEmpty) return;
    scheduled = false;

    if (_combinator == null) {
      throw new StateError(
          'CompoundBinding attempted to resolve without a combinator');
    }

    value = _combinator(_values);
  }

  /**
   * Closes the observer.
   *
   * This happens automatically if the [value] property is no longer observed,
   * but this can also be called explicitly.
   */
  void close() {
    for (var binding in _observers.values) {
      binding.cancel();
    }
    _observers.clear();
    _values.clear();
    value = null;
  }

  _unobserved() => close();
}
