// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.vmstats;

class IsolateList {
  UListElement _listArea;

  static const String CSS_VISIBLE = 'isolate_details';
  static const String CSS_HIDDEN  = 'isolate_details_hidden';

  IsolateList(this._listArea) {}

  void updateList(IsolateListModel model) {
    var detailsClass = CSS_HIDDEN;
    if (_listArea.children.length > 0) {
      // Preserve visibility state.
      var listItem = _listArea.children.first;
      var item = listItem.children.first;
      if (item.classes.length > 0 && item.classes.first == CSS_VISIBLE) {
        detailsClass = CSS_VISIBLE;
      }
      _listArea.children.clear();
    }
    var iterator = model.iterator;
    while (iterator.moveNext()) {
      var isolate = iterator.current;
      var listItem = new LIElement();
      listItem.classes.add('isolate_list');
      listItem.text = isolate.name
          .replaceAll('\$', ': ')  // Split script from isolate, and ...
          .replaceAll('-', ' ');   // ... split name from port number.

      // Add isolate details as hidden children.
      var details = new DivElement();
      isolateDetails(isolate, details);
      details.classes.add(detailsClass);
      listItem.children.add(details);
      listItem.onClick.listen((e) => toggle(details));

      _listArea.children.add(listItem);
    }
  }

  void isolateDetails(Isolate isolate, DivElement parent) {
    var newSpace = new DivElement();
    newSpace.text = 'New space: ${isolate.newSpace.used}K';
    parent.children.add(newSpace);
    var oldSpace = new DivElement();
    oldSpace.text = 'Old space: ${isolate.oldSpace.used}K';
    parent.children.add(oldSpace);
    var stack = new DivElement();
    stack.text = 'Stack limit: ${(isolate.stackLimit / 1000000).round()}M';
    parent.children.add(stack);
  }

  void toggle(DivElement e) {
    e.classes.toggle(CSS_VISIBLE);
    e.classes.toggle(CSS_HIDDEN);
  }
}
