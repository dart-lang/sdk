#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Build logic that lets the Dart editor build examples in the background. */
library build;
import 'package:polymer/component_build.dart';
import 'dart:io';

void main() {
  build(new Options().arguments, [
    'example/component/news/web/index.html',
    'example/scoped_style/index.html',
    '../../samples/third_party/todomvc/web/index.html']);
}
