// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nav_bar_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

@CustomTag('library-nav-menu')
class LibraryNavMenuElement extends ObservatoryElement {
  @published Library library;
  @published bool last = false;

  LibraryNavMenuElement.created() : super.created();
}
