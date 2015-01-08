// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library context_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('context-view')
class ContextViewElement extends ObservatoryElement {
  @published Context context;

  ContextViewElement.created() : super.created();

  void refresh(Function onDone) {
    context.reload().whenComplete(onDone);
  }
}
