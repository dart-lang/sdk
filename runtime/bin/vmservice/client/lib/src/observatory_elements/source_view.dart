// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_view_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/observatory.dart';
import 'observatory_element.dart';

/// Displays an Error response.
@CustomTag('source-view')
class SourceViewElement extends ObservatoryElement {
  @published ScriptSource source;

  SourceViewElement.created() : super.created();
}