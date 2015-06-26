// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instructions_view;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('instructions-view')
class InstructionsViewElement extends ObservatoryElement {
  @published Instructions instructions;

  InstructionsViewElement.created() : super.created();

  Future refresh() {
    return instructions.reload();
  }
}
