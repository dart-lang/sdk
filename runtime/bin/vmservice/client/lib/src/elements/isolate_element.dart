// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_element;

import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

/// Base class for all custom elements which reference an isolate.
/// Holds an observable [Isolate].
@CustomTag('isolate-element')
class IsolateElement extends ObservatoryElement {
  IsolateElement.created() : super.created();
  @published Isolate isolate;
}
