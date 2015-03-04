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
  ClassTreeRow(this.isolate, this.cls, TableTree tree, ClassTreeRow parent)
      : super(tree, parent) {
    assert(isolate != null);
    assert(cls != null);
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      for (var subclass in cls.subclasses) {
        if (subclass.isPatch) {
          continue;
        }
        var row = new ClassTreeRow(isolate, subclass, tree, this);
        children.add(row);
      }
    }
    var classCell = flexColumns[0];
    classCell.style.justifyContent = 'flex-start';
    var classRef = new Element.tag('class-ref');
    classRef.ref = cls;
    classRef.style.alignSelf = 'center';
    classCell.children.add(classRef);
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
    var tableBody = shadowRoot.querySelector('#tableTreeBody');
    assert(tableBody != null);
    tree = new TableTree(tableBody, 1);
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
      var rootRow = new ClassTreeRow(isolate, root, tree, null);
      rootRow.children.add(new ClassTreeRow(isolate, root, tree, rootRow));
      tree.initialize(rootRow);
    } catch (e, stackTrace) {
      Logger.root.warning('_update', e, stackTrace);
    }
    // Check if we only have one node at the root and expand it.
    if (tree.rows.length == 1) {
      tree.toggle(tree.rows[0]);
    }
    notifyPropertyChange(#tree, null, tree);
  }
}
