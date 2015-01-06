// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_ref_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('error-ref')
class ErrorRefElement extends ServiceRefElement {
  ErrorRefElement.created() : super.created();
}
