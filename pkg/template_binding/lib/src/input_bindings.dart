// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;


// Note: the JavaScript version monkeypatches(!!) the close method of the passed
// in Bindable. We use a wrapper instead.
class _InputBinding extends Bindable {
  // Note: node can be an InputElement or TextAreaElement. Both have "value".
  var _node;
  StreamSubscription _eventSub;
  Bindable _bindable;
  String _propertyName;

  _InputBinding(this._node, this._bindable, this._propertyName) {
    _eventSub = _getStreamForInputType(_node).listen(_nodeChanged);
    _updateNode(open(_updateNode));
  }

  void _updateNode(newValue) => _updateProperty(_node, newValue, _propertyName);

  static void _updateProperty(node, newValue, String propertyName) {
    switch (propertyName) {
      case 'checked':
        node.checked = _toBoolean(newValue);
        return;
      case 'selectedIndex':
        node.selectedIndex = _toInt(newValue);
        return;
      case 'value':
        node.value = _sanitizeValue(newValue);
        return;
    }
  }

  void _nodeChanged(e) {
    switch (_propertyName) {
      case 'value':
        value = _node.value;
        break;
      case 'checked':
        value = _node.checked;

        // Only the radio button that is getting checked gets an event. We
        // therefore find all the associated radio buttons and update their
        // checked binding manually.
        if (_node is InputElement && _node.type == 'radio') {
          for (var r in _getAssociatedRadioButtons(_node)) {
            var checkedBinding = nodeBind(r).bindings['checked'];
            if (checkedBinding != null) {
              // Set the value directly to avoid an infinite call stack.
              checkedBinding.value = false;
            }
          }
        }
        break;
      case 'selectedIndex':
        value = _node.selectedIndex;
        break;
    }

    Observable.dirtyCheck();
  }

  open(callback(value)) => _bindable.open(callback);
  get value => _bindable.value;
  set value(newValue) => _bindable.value = newValue;

  void close() {
    if (_eventSub != null) {
      _eventSub.cancel();
      _eventSub = null;
    }
    if (_bindable != null) {
      _bindable.close();
      _bindable = null;
    }
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
      case 'range':
        if (window.navigator.userAgent.contains(new RegExp('Trident|MSIE'))) {
          return element.onChange;
        }
    }
    return element.onInput;
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

  // TODO(jmesserly,sigmund): I wonder how many bindings typically convert from
  // one type to another (e.g. value-as-number) and whether it is useful to
  // have something like a int/num binding converter (either as a base class or
  // a wrapper).
  static int _toInt(value) {
    if (value is String) return int.parse(value, onError: (_) => 0);
    return value is int ? value : 0;
  }
}

_getTreeScope(Node node) {
  Node parent;
  while ((parent = node.parentNode) != null ) {
    node = parent;
  }

  return _hasGetElementById(node) ? node : null;
}

// Note: JS code tests that getElementById is present. We can't do that
// easily, so instead check for the types known to implement it.
bool _hasGetElementById(Node node) =>
    node is Document || node is ShadowRoot || node is SvgSvgElement;
