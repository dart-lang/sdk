// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library action_link_element;

import 'package:polymer/polymer.dart';

@CustomTag('action-link')
class ActionLinkElement extends PolymerElement {
  ActionLinkElement.created() : super.created();

  @observable bool busy = false;
  @published var callback = null;
  @published String label = 'action';
  @published String color = null;

  void doAction(var a, var b, var c) {
    if (busy) {
      return;
    }
    if (callback != null) {
      busy = true;
      // TODO(turnidge): Track down why adding a dummy argument makes
      // this work but having a no-argument callback doesn't.
      callback(null).whenComplete(() {
          busy = false;
        });
    }
  }
}
