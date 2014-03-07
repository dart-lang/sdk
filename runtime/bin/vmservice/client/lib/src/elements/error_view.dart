// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_view_element;

import 'package:polymer/polymer.dart';
import 'observatory_element.dart';

/// Displays an Error response.
@CustomTag('error-view')
class ErrorViewElement extends ObservatoryElement {
  @published Map error;

  ErrorViewElement.created() : super.created();
}