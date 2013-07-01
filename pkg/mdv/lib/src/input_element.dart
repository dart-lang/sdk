// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [InputElement] API. */
class _InputElementExtension extends _ElementExtension {
  _InputElementExtension(InputElement node) : super(node);

  InputElement get node => super.node;

  _ValueBinding _valueBinding;

  _CheckedBinding _checkedBinding;

  void bind(String name, model, String path) {
    switch (name) {
      case 'value':
        unbind('value');
        node.attributes.remove('value');
        _valueBinding = new _ValueBinding(node, model, path);
        break;
      case 'checked':
        unbind('checked');
        node.attributes.remove('checked');
        _checkedBinding = new _CheckedBinding(node, model, path);
        break;
      default:
        super.bind(name, model, path);
        break;
    }
  }

  void unbind(String name) {
    switch (name) {
      case 'value':
        if (_valueBinding != null) {
          _valueBinding.unbind();
          _valueBinding = null;
        }
        break;
      case 'checked':
        if (_checkedBinding != null) {
          _checkedBinding.unbind();
          _checkedBinding = null;
        }
        break;
      default:
        super.unbind(name);
        break;
    }
  }

  void unbindAll() {
    unbind('value');
    unbind('checked');
    super.unbindAll();
  }
}

class _ValueBinding extends _InputBinding {
  _ValueBinding(element, model, path) : super(element, model, path);

  InputElement get element => super.element;

  void valueChanged(value) {
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
