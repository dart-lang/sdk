// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_view_element;

import 'observatory_element.dart';
import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';

/// Displays an Error ServiceObject.
@CustomTag('error-view')
class ErrorViewElement extends ObservatoryElement {
  @published ServiceObject error;

  ErrorViewElement.created() : super.created();
}