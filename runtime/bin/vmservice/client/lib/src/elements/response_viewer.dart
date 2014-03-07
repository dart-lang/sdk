// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library response_viewer_element;

import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

@CustomTag('response-viewer')
class ResponseViewerElement extends ObservatoryElement {
  @published ObservatoryApplication app;
  ResponseViewerElement.created() : super.created();
}