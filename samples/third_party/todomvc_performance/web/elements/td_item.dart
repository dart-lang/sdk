library todomvc.web.elements.td_item;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'td_model.dart';

@CustomTag('td-item')
class TodoItem extends LIElement with Polymer, Observable {
  @published bool editing = false;
  @published Todo item;

  factory TodoItem() => new Element.tag('li', 'td-item');
  TodoItem.created() : super.created() { polymerCreated(); }

  editAction() {
    editing = true;
    // schedule focus for the end of microtask, when the input will be visible
    async((_) => $['edit'].focus());
  }

  commitAction() {
    if (editing) {
      editing = false;
      item.title = item.title.trim();
      if (item.title == '') {
        destroyAction();
      }
      fire('td-item-changed');
    }
  }

  cancelAction() {
    editing = false;
  }

  itemChangeAction() {
    // TODO(jmesserly): asyncFire is needed because "click" fires before
    // "item.checked" is updated on Firefox. Need to check Polymer.js.
    asyncFire('td-item-changed');
  }

  destroyAction() {
    fire('td-destroy-item', detail: item);
  }
}
