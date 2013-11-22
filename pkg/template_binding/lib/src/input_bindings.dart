// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

abstract class _InputBinding extends NodeBinding {
  StreamSubscription _eventSub;

  _InputBinding(node, name, model, path): super(node, name, model, path) {
    _eventSub = _getStreamForInputType(node).listen(nodeValueChanged);
  }

  void valueChanged(newValue);

  void nodeValueChanged(e);

  void close() {
    if (closed) return;
    _eventSub.cancel();
    super.close();
  }

  static EventStreamProvider<Event> _checkboxEventType = () {
    // Attempt to feature-detect which event (change or click) is fired first
    // for checkboxes.
    var div = new DivElement();
    var checkbox = div.append(new InputElement());
    checkbox.type = 'checkbox';
    var fired = [];
    checkbox.onClick.listen((e) {
      fired.add(Element.clickEvent);
    });
    checkbox.onChange.listen((e) {
      fired.add(Element.changeEvent);
    });
    checkbox.dispatchEvent(new MouseEvent('click', view: window));
    // WebKit/Blink don't fire the change event if the element is outside the
    // document, so assume 'change' for that case.
    return fired.length == 1 ? Element.changeEvent : fired.first;
  }();

  static Stream<Event> _getStreamForInputType(element) {
    if (element is OptionElement) return element.onInput;
    switch (element.type) {
      case 'checkbox':
        return _checkboxEventType.forTarget(element);
      case 'radio':
      case 'select-multiple':
      case 'select-one':
        return element.onChange;
      default:
        return element.onInput;
    }
  }
}

class _ValueBinding extends _InputBinding {
  _ValueBinding(node, model, path) : super(node, 'value', model, path);

  get node => super.node;

  void valueChanged(newValue) {
    // Note: node can be an InputElement or TextAreaElement. Both have "value".
    node.value = sanitizeBoundValue(newValue);
  }

  void nodeValueChanged(e) {
    value = node.value;
    Observable.dirtyCheck();
  }
}

class _CheckedBinding extends _InputBinding {
  _CheckedBinding(node, model, path) : super(node, 'checked', model, path);

  InputElement get node => super.node;

  void valueChanged(newValue) {
    node.checked = _toBoolean(newValue);
  }

  void nodeValueChanged(e) {
    value = node.checked;

    // Only the radio button that is getting checked gets an event. We
    // therefore find all the associated radio buttons and update their
    // CheckedBinding manually.
    if (node is InputElement && node.type == 'radio') {
      for (var r in _getAssociatedRadioButtons(node)) {
        var checkedBinding = nodeBind(r).bindings['checked'];
        if (checkedBinding != null) {
          // Set the value directly to avoid an infinite call stack.
          checkedBinding.value = false;
        }
      }
    }

    Observable.dirtyCheck();
  }

  // |element| is assumed to be an HTMLInputElement with |type| == 'radio'.
  // Returns an array containing all radio buttons other than |element| that
  // have the same |name|, either in the form that |element| belongs to or,
  // if no form, in the document tree to which |element| belongs.
  //
  // This implementation is based upon the HTML spec definition of a
  // "radio button group":
  //   http://www.whatwg.org/specs/web-apps/current-work/multipage/number-state.html#radio-button-group
  //
  static Iterable _getAssociatedRadioButtons(element) {
    if (element.form != null) {
      return element.form.nodes.where((el) {
        return el != element &&
            el is InputElement &&
            el.type == 'radio' &&
            el.name == element.name;
      });
    } else {
      var treeScope = _getTreeScope(element);
      if (treeScope == null) return const [];

      var radios = treeScope.querySelectorAll(
          'input[type="radio"][name="${element.name}"]');
      return radios.where((el) => el != element && el.form == null);
    }
  }
}

class _SelectBinding extends _InputBinding {
  MutationObserver _onMutation;

  _SelectBinding(node, property, model, path)
      : super(node, property, model, path);

  SelectElement get node => super.node;

  void valueChanged(newValue) {
    _cancelMutationObserver();

    if (_tryUpdateValue(newValue)) return;

    // It could be that a template will expand an <option> child (or grandchild,
    // if we have an <optgroup> in between). Since selected index cannot be set
    // if the children aren't created yet, we need to wait for them to be
    // created do this with a MutationObserver.
    // Dart note: unlike JS we use mutation observers to avoid:
    // https://github.com/Polymer/NodeBind/issues/5

    // Note: it doesn't matter when the children get added; even if they get
    // added much later, presumably we want the selected index data binding to
    // still take effect.
    _onMutation = new MutationObserver((x, y) {
      if (_tryUpdateValue(value)) _cancelMutationObserver();
    })..observe(node, childList: true, subtree: true);
  }

  bool _tryUpdateValue(newValue) {
    if (property == 'selectedIndex') {
      var intValue = _toInt(newValue);
      node.selectedIndex = intValue;
      return node.selectedIndex == intValue;
    } else if (property == 'value') {
      node.value = sanitizeBoundValue(newValue);
      return node.value == newValue;
    }
  }

  void _cancelMutationObserver() {
    if (_onMutation != null) {
      _onMutation.disconnect();
      _onMutation = null;
    }
  }

  void nodeValueChanged(e) {
    _cancelMutationObserver();

    if (property == 'selectedIndex') {
      value = node.selectedIndex;
    } else if (property == 'value') {
      value = node.value;
    }
  }

  // TODO(jmesserly,sigmund): I wonder how many bindings typically convert from
  // one type to another (e.g. value-as-number) and whether it is useful to
  // have something like a int/num binding converter (either as a base class or
  // a wrapper).
  static int _toInt(value) {
    if (value is String) return int.parse(value, onError: (_) => 0);
    return value is int ? value : 0;
  }
}
