// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library curly_block_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('curly-block')
class CurlyBlockElement extends ObservatoryElement {
  CurlyBlockElement.created() : super.created();

  @observable bool expanded = false;
  @observable bool busy = false;
  @published var callback = null;
  @published bool expand = false;
  @published String expandKey;

  void expandChanged(oldValue) {
    expanded = expand;
  }

  void expandKeyChanged(oldValue) {
    if (expandKey != null) {
      var value = app.expansions[expandKey];
      if (value != null) {
        if (expanded != value) {
          toggleExpand(null, null, null);
        }
      }
    }
  }

  void doneCallback() {
    expanded = !expanded;
    if (expandKey != null) {
      app.expansions[expandKey] = expanded;
    }
    busy = false;
  }

  void toggleExpand(var event, var b, var c) {
    assert(callback == null || expand == false);
    if (busy) {
      return;
    }
    busy = true;
    if (callback != null) {
      callback(!expanded, doneCallback);
    } else {
      doneCallback();
    }
  }
}
