// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of template_binding;

/** Extensions to the [Text] API. */
class _TextExtension extends NodeBindExtension {
  _TextExtension(Text node) : super._(node);

  Bindable bind(String name, value, {bool oneTime: false}) {
    // Dart note: 'text' instead of 'textContent' to match the DOM property.
    if (name != 'text') {
      return super.bind(name, value, oneTime: oneTime);
    }
    if (oneTime) {
      _updateText(value);
      return null;
    }

    _open(value, _updateText);
    return _maybeUpdateBindings(name, value);
  }

  _updateText(value) {
    _node.text = _sanitizeValue(value);
  }
}

/** Called to sanitize the value before it is assigned into the property. */
_sanitizeValue(value) => value == null ? '' : '$value';
