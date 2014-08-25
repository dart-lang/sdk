// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_tree_element;

import 'observatory_element.dart';
import 'dart:html';
import 'package:logging/logging.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

class ClassTreeRow extends TableTreeRow {
  @reflectable final Isolate isolate;
  @reflectable final Class cls;
  ClassTreeRow(this.isolate, this.cls, ClassTreeRow parent) : super(parent) {
    assert(isolate != null);
    assert(cls != null);
  }

  void onShow() {
    if (children.length > 0) {
      // Child rows already created.
      return;
    }
    for (var subclass in cls.subclasses) {
      if (subclass.isPatch) {
        continue;
      }
      var row = new ClassTreeRow(isolate, subclass, this);
      children.add(row);
    }
  }

  void onHide() {
  }

  bool hasChildren() {
    return cls.subclasses.length > 0;
  }
}


@CustomTag('class-tree')
class ClassTreeElement extends ObservatoryElement {
  @observable Isolate isolate;

  TableTree tree;

  ClassTreeElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    tree = new TableTree();
    if (isolate != null) {
      _update(isolate.objectClass);
    }
  }

  isolateChanged(oldValue) {
    isolate.getClassHierarchy().then((objectClass) {
      _update(objectClass);
    });
  }

  void _update(Class root) {
    try {
      var rootRow = new ClassTreeRow(isolate, root, null);
      rootRow.children.add(new ClassTreeRow(isolate, root, rootRow));
      tree.initialize(rootRow);
    } catch (e, stackTrace) {
      Logger.root.warning('_update', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (tree.rows.length == 1) {
      tree.toggle(0);
    }
    notifyPropertyChange(#tree, null, tree);
  }

  @observable String padding(TableTreeRow row) {
    return 'padding-left: ${row.depth * 16}px;';
  }

  @observable String coloring(TableTreeRow row) {
    const colors = const ['rowColor0', 'rowColor1', 'rowColor2', 'rowColor3',
                          'rowColor4', 'rowColor5', 'rowColor6', 'rowColor7',
                          'rowColor8'];
    var index = (row.depth - 1) % colors.length;
    return colors[index];
  }

  @observable void toggleExpanded(Event e, var detail, Element target) {
    // We only want to expand a tree row if the target of the click is
    // the table cell (passed in as target) or the span containing the
    // expander symbol (#expand).
    var eventTarget = e.target;
    if ((eventTarget.id != 'expand') && (e.target != target)) {
      // Target of click was not the expander span or the table cell.
      return;
    }
    var row = target.parent;
    if (row is TableRowElement) {
      try {
        // Subtract 1 to get 0 based indexing.
        tree.toggle(row.rowIndex - 1);
      }  catch (e, stackTrace) {
        Logger.root.warning('toggleExpanded', e, stackTrace);
      }
    }
  }

}
