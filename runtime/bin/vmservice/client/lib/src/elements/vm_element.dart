// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_element;

import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

/// Base class for all custom elements which reference a VM.
/// Holds an observable [VM].
@CustomTag('vm-element')
class VMElement extends ObservatoryElement {
  VMElement.created() : super.created();
  @published VM vm;
}
