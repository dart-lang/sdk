// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sliding_checkbox_element;

import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('sliding-checkbox')
class SlidingCheckboxElement extends PolymerElement {
  SlidingCheckboxElement.created() : super.created();
  @published bool checked;
  @published String checkedText;
  @published String uncheckedText;

  void change(Event e, var details, Node target) {
    CheckboxInputElement input = shadowRoot.querySelector('#slide-switch');
    checked = input.checked;
  }
}
