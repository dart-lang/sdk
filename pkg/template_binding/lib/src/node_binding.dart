// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.src.node_binding;

import 'dart:async' show StreamSubscription;
import 'dart:html' show Node;
import 'package:observe/observe.dart' show PathObserver, CompoundPathObserver;

/** Test only method. Not re-exported. */
getObserverForTest(NodeBinding binding) => binding._observer;

/**
 * A data binding on a [Node].
 * See [NodeBindExtension.bindings] and [NodeBindExtension.bind].
 */
abstract class NodeBinding {
  Node _node;
  var _model;

  // TODO(jmesserly): need common interface for PathObserver,
  // CompoundPathObserver.
  var _observer;
  StreamSubscription _pathSub;

  /** The property of [node] which will be data bound. */
  final String property;

  /** The property of [node] which will be data bound. */
  final String path;

  /** The node that has [property] which will be data bound. */
  Node get node => _node;

  /** The bound data model. */
  get model => _model;

  /** True if this binding has been [closed]. */
  bool get closed => _node == null;

  /** The value at the [path] on [model]. */
  get value => _observer.value;

  set value(newValue) {
    _observer.value = newValue;
  }

  NodeBinding(this._node, this.property, this._model, [String path])
      : path = path != null ? path : '' {

    // Fast path if we're observing "value"
    if ((model is PathObserver || model is CompoundPathObserver) &&
        path == 'value') {

      _observer = model;
    } else {
      // Create the path observer
      _observer = new PathObserver(model, this.path);
    }

    _pathSub = _observer.changes.listen((r) => valueChanged(value));
    valueChanged(value);
  }

  /** Called when [value] changes to update the [node]. */
  // TODO(jmesserly): the impl in template_binding uses reflection to set the
  // property, but that isn't used except for specific known fields like
  // "textContent", so I'm overridding this in the subclasses instead.
  void valueChanged(newValue);

  /** Called to sanitize the value before it is assigned into the property. */
  sanitizeBoundValue(value) => value == null ? '' : '$value';

  /**
   * Called by [NodeBindExtension.unbind] to close this binding and unobserve
   * the [path].
   *
   * This can be overridden in subclasses, but they must call `super.close()`
   * to free associated resources. They must also check [closed] and return
   * immediately if already closed.
   */
  void close() {
    if (closed) return;

    if (_pathSub != null) _pathSub.cancel();
    _pathSub = null;
    _observer = null;
    _node = null;
    _model = null;
  }
}
