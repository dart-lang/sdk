library todomvc.web.elements.td_model;

import 'dart:html';
import 'package:polymer/polymer.dart';
import '../lib-elements/polymer_localstorage.dart';

class Todo extends Observable {
  @observable String title;
  @observable bool completed = false;

  Todo(this.title);

  Todo.fromJson(Map json)
      : title = json['title'], completed = json['completed'];

  Map toJson() => { 'title': title, 'completed': completed };

  String toString() => "$title (${completed ? '' : 'not '}done)";
}

@CustomTag('td-model')
class TodoModel extends PolymerElement {
  @published ObservableList<Todo> items;
  @published Iterable<Todo> filtered;
  @published String storageId;

  @observable int completedCount = 0;
  @observable int activeCount = 0;
  @observable bool allCompleted = false;
  @observable PolymerLocalStorage storage;
  @observable String filter;
  @observable String activeItemWord;

  final filters = {
    'active': (item) => !item.completed,
    'completed': (item) => item.completed
  };

  factory TodoModel() => new Element.tag('td-model');
  TodoModel.created() : super.created();

  void ready() {
    async((_) {
      if (items == null) items = new ObservableList<Todo>();
    });
  }

  void filterChanged() {
    filterItems();
  }

  void itemsChanged() {
    completedCount = items.where(filters['completed']).length;
    activeCount = items.length - completedCount;
    allCompleted = completedCount > 0 && activeCount == 0;

    filterItems();
    if (storage != null) {
      storage.value = items;
      storage.save();
    }

    // TODO(jmesserly): polymer_expressions lacks ternary operator.
    activeItemWord = activeCount == 1 ? 'item' : 'items';
  }

  void storageIdChanged() {
    storage = document.querySelector('#$storageId');
    if (storage != null && storage.value != null) {
      items = toObservable(storage.value.map((i) => new Todo.fromJson(i)));
    }
  }

  void filterItems() {
    var fn = filters[filter];
    filtered = fn != null ? items.where(fn) : items;
  }

  void newItem(String title) {
    title = title.trim();
    if (title != '') {
      items.add(new Todo(title));
      itemsChanged();
    }
  }

  void destroyItem(Todo item) {
    if (items.remove(item)) itemsChanged();
  }

  void clearItems() {
    items.removeWhere(filters['completed']);
  }

  void setItemsCompleted(bool completed) {
    for (var item in items) {
      item.completed = completed;
    }
    itemsChanged();
  }
}
