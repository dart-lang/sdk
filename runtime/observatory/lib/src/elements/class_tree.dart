// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library class_tree_element;

import 'observatory_element.dart';
import 'dart:async';
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

  void _addChildren(List<Class> subclasses) {
    for (var subclass in subclasses) {
      if (subclass.isPatch) {
        continue;
      }
      if (subclass.mixin != null) {
        _addChildren(subclass.subclasses);
      } else {
        var row = new ClassTreeRow(isolate, subclass, tree, this);
        children.add(row);
      }
    }
  }

  Future _addMixins(Class cls) async {
    var classCell = flexColumns[0];
    if (cls.superclass == null) {
      return;
    }
    bool first = true;
    while (cls.superclass != null && cls.superclass.mixin != null) {
      cls = cls.superclass;
      await cls.mixin.load();
      var span = new SpanElement();
      span.style.alignSelf = 'center';
      span.style.whiteSpace = 'pre';
      if (first) {
        span.text = ' with ';
      } else {
        span.text = ', ';
      }
      classCell.children.add(span);
      var mixinRef = new Element.tag('class-ref');
      mixinRef.ref = cls.mixin.typeClass;
      mixinRef.style.alignSelf = 'center';
      classCell.children.add(mixinRef);
      first = false;
    }
  }

  Future _addClass(Class cls) async {
    var classCell = flexColumns[0];
    classCell.style.justifyContent = 'flex-start';
    var classRef = new Element.tag('class-ref');
    classRef.ref = cls;
    classRef.style.alignSelf = 'center';
    classCell.children.add(classRef);
    if (cls.superclass != null && cls.superclass.mixin != null) {
      await _addMixins(cls);
    }
    if (cls.subclasses.isNotEmpty) {
      var span = new SpanElement();
      span.style.paddingLeft = '.5em';
      span.style.alignSelf = 'center';
      int subclassCount = _indirectSubclassCount(cls) - 1;
      if (subclassCount > 1) {
        span.text = '($subclassCount subclasses)';
      } else {
        span.text = '($subclassCount subclass)';
      }
      classCell.children.add(span);
    }
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      _addChildren(cls.subclasses);
    }
    _addClass(cls);
  }

  static int _indirectSubclassCount(var cls) {
    int count = 0;
    if (cls.mixin == null) {
      // Don't count synthetic mixin classes in subclass count.
      count++;
    }
    for (var subclass in cls.subclasses) {
      count += _indirectSubclassCount(subclass);
    }
    return count;
  }

  bool hasChildren() {
    return cls.subclasses.isNotEmpty;
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
