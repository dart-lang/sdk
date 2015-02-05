// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library general_error_element;

import 'observatory_element.dart';
import 'package:polymer/polymer.dart';

/// Displays an error message
@CustomTag('general-error')
class GeneralErrorElement extends ObservatoryElement {
  @published String message;

  GeneralErrorElement.created() : super.created();
}
