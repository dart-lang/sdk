// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_frame_element;

import 'observatory_element.dart';
import 'package:polymer/polymer.dart';

@CustomTag('stack-frame')
class StackFrameElement extends ObservatoryElement {
  @published ObservableMap frame;
  StackFrameElement.created() : super.created();
}
