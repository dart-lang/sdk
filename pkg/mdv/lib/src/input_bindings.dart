// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

abstract class _InputBinding {
  // InputElement or SelectElement
  final element;
  PathObserver binding;
  StreamSubscription _pathSub;
  StreamSubscription _eventSub;

  _InputBinding(this.element, model, String path) {
    binding = new PathObserver(model, path);
    _pathSub = binding.bindSync(valueChanged);
    _eventSub = _getStreamForInputType(element).listen(updateBinding);
  }

  void valueChanged(newValue);

  void updateBinding(e);

  void unbind() {
    binding = null;
    _pathSub.cancel();
    _eventSub.cancel();
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
  _ValueBinding(element, model, path) : super(element, model, path);

  void valueChanged(value) {
    // Note: element can be an InputElement or TextAreaElement.
    element.value = value == null ? '' : '$value';
  }

  void updateBinding(e) {
    binding.value = element.value;
  }
}

class _CheckedBinding extends _InputBinding {
  _CheckedBinding(element, model, path) : super(element, model, path);

  InputElement get element => super.element;

  void valueChanged(value) {
    element.checked = _toBoolean(value);
  }

  void updateBinding(e) {
    binding.value = element.checked;

    // Only the radio button that is getting checked gets an event. We
    // therefore find all the associated radio buttons and update their
    // CheckedBinding manually.
    if (element is InputElement && element.type == 'radio') {
      for (var r in _getAssociatedRadioButtons(element)) {
        var checkedBinding = _mdv(r)._checkedBinding;
        if (checkedBinding != null) {
          // Set the value directly to avoid an infinite call stack.
          checkedBinding.binding.value = false;
        }
      }
    }
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
    if (!_isNodeInDocument(element)) return [];
    if (element.form != null) {
      return element.form.nodes.where((el) {
        return el != element &&
            el is InputElement &&
            el.type == 'radio' &&
            el.name == element.name;
      });
    } else {
      var radios = element.document.queryAll(
          'input[type="radio"][name="${element.name}"]');
      return radios.where((el) => el != element && el.form == null);
    }
  }

  // TODO(jmesserly): polyfill document.contains API instead of doing it here
  static bool _isNodeInDocument(Node node) {
    // On non-IE this works:
    // return node.document.contains(node);
    var document = node.document;
    if (node == document || node.parentNode == document) return true;
    return document.documentElement.contains(node);
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
    // produced by a child <template>. Furthermore, we may need to wait for
    // <optgroup> iterating and then for <option>.
    //
    // Unlike the JavaScript MDV, we don't have a special "Object.observe" event
    // loop to schedule on. (See the the "ensureScheduled" function:
    // https://github.com/Polymer/mdv/commit/9a51ad7ed74a292bf71662cea28acbd151ff65c8)
    //
    // Instead we use runAsync. Each <template repeat> needs a delay of 3:
    //   * once to happen after the child _TemplateIterator is created
    //   * once to be after _TemplateIterator.inputs CompoundBinding resolve
    //   * once to be after _TemplateIterator._valueBinding PathObserver fires
    // And then we need to do this delay sequence twice:
    //   * once for OPTGROUP
    //   * once for OPTION.
    // The resulting 2 * 3 is our maxRetries.
    var maxRetries = 6;
    delaySetSelectedIndex() {
      if (newValue > element.length && --maxRetries >= 0) {
        runAsync(delaySetSelectedIndex);
      } else {
        element.selectedIndex = newValue;
      }
    }

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
