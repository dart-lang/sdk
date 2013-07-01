// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [SelectElement] API. */
class _SelectElementExtension extends _ElementExtension {
  _SelectElementExtension(SelectElement node) : super(node);

  SelectElement get node => super.node;

  _SelectedIndexBinding _valueBinding;

  void bind(String name, model, String path) {
    if (name.toLowerCase() == 'selectedindex') {
      unbind('selectedindex');
      node.attributes.remove('selectedindex');
      _valueBinding = new _SelectedIndexBinding(node, model, path);
      return;
    }
    super.bind(name, model, path);
  }

  void unbind(String name) {
    if (name.toLowerCase() == 'selectedindex' && _valueBinding != null) {
      _valueBinding.unbind();
      _valueBinding = null;
      return;
    }
    super.unbind(name);
  }

  void unbindAll() {
    unbind('selectedindex');
    super.unbindAll();
  }
}


class _SelectedIndexBinding extends _InputBinding {
  _SelectedIndexBinding(element, model, path) : super(element, model, path);

  SelectElement get element => super.element;

  void valueChanged(value) {
    var newValue = _toInt(value);
    if (newValue <= element.length) {
      element.selectedIndex = newValue;
      return;
    }

    // The binding may wish to bind to an <option> which has not yet been
    // produced by a child <template>. Delay a maximum of twice -- once for
    // iterating <optgroup> and once for <option>.
    var maxRetries = 2;
    delaySetSelectedIndex() {
      if (newValue > element.length && --maxRetries >= 0) {
        runAsync(delaySetSelectedIndex);
      } else {
        element.selectedIndex = newValue;
      }
    }

    // TODO(jmesserly): we aren't matching MDV here. They schedule "model=" to
    // happen async and then delay using the same scheduler. By using "runAsync"
    // we're going to happen quite a bit later.
    // We need to port the "ensureScheduled" function:
    // https://github.com/Polymer/mdv/commit/9a51ad7ed74a292bf71662cea28acbd151ff65c8
    runAsync(delaySetSelectedIndex);
  }

  void updateBinding(e) {
    binding.value = element.selectedIndex;
  }

  // TODO(jmesserly,sigmund): I wonder how many bindings typically convert from
  // one type to another (e.g. value-as-number) and whether it is useful to
  // have something like a int/num binding converter (either as a base class or
  // a wrapper).
  static int _toInt(value) {
    if (value is String) return int.parse(value, onError: (_) => null);
    return value is int ? value : null;
  }
}
