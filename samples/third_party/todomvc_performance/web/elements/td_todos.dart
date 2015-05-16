library todomvc.web.elements.td_todos;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'td_input.dart';
import 'td_model.dart';

@CustomTag('td-todos')
class TodoList extends PolymerElement {
  @published String modelId;

  @observable TodoModel model;
  @observable String activeRoute;

  factory TodoList() => new Element.tag('td-todos');
  TodoList.created() : super.created();

  TodoInput get _newTodo => $['new-todo'];

  void modelIdChanged() {
    model = document.querySelector('#$modelId');
  }

  void routeAction(e, route) {
    if (model != null) model.filter = route;

    // TODO(jmesserly): polymer_expressions lacks boolean conversions.
    activeRoute = (route != null && route != '') ? route : 'all';
  }

  void addTodoAction() {
    model.newItem(_newTodo.value);
    // when polyfilling Object.observe, make sure we update immediately
    Observable.dirtyCheck();
    _newTodo.value = '';
  }

  void cancelAddTodoAction() {
    _newTodo.value = '';
  }

  void itemChangedAction() {
    if (model != null) model.itemsChanged();
  }

  void destroyItemAction(e, detail) {
    model.destroyItem(detail);
  }

  void toggleAllCompletedAction(e, detail, sender) {
    model.setItemsCompleted(sender.checked);
  }

  void clearCompletedAction() {
    model.clearItems();
  }

  // TODO(jmesserly): workaround for HTML Imports not setting correct baseURI
  String get baseUri =>
      declaration.element.ownerDocument == document ? '../' : '';
}
