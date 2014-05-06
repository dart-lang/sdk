// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library curly_block_element;

import 'package:polymer/polymer.dart';

@CustomTag('curly-block')
class CurlyBlockElement extends PolymerElement {
  CurlyBlockElement.created() : super.created();

  @observable bool expanded = false;
  @observable bool busy = false;
  @published var callback = null;
  @published bool expand = false;

  void expandChanged(oldValue) {
    expanded = expand;
  }

  void doneCallback() {
    expanded = !expanded;
    busy = false;
  }

  void toggleExpand(var a, var b, var c) {
    assert(callback == null || expand == false);
    if (busy) {
      return;
    }
    if (callback != null) {
      busy = true;
      callback(!expanded, doneCallback);
    } else {
      expanded = !expanded;
    }
  }
}
