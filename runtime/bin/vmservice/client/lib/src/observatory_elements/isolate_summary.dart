// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate_summary_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

@CustomTag('isolate-summary')
class IsolateSummaryElement extends ObservatoryElement {
  @published int isolate;
  @published String name = '';

  IsolateSummaryElement.created() : super.created();
}