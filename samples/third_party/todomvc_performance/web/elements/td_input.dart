library todomvc.web.elements.td_input;

import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('td-input')
class TodoInput extends InputElement with Polymer, Observable {
  factory TodoInput() => new Element.tag('input', 'td-input');
  TodoInput.created() : super.created() {
    polymerCreated();
  }

  keypressAction(e) {
    // Listen for enter on keypress but esc on keyup, because
    // IE doesn't fire keyup for enter.
    if (e.keyCode == KeyCode.ENTER) {
      e.preventDefault();
      fire('td-input-commit');
    }
  }

  keyupAction(e) {
    if (e.keyCode == KeyCode.ESC) {
      fire('td-input-cancel');
    }
  }
}
