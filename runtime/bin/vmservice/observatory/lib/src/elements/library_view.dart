// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_view_element;

import 'dart:async';
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';


@CustomTag('library-view')
class LibraryViewElement extends ObservatoryElement {
  @published Library library;

  LibraryViewElement.created() : super.created();

  Future<ServiceObject> eval(String text) {
    return library.isolate.get(
        library.id + "/eval?expr=${Uri.encodeComponent(text)}");
  }

  void refresh(var done) {
    library.reload().whenComplete(done);
  }

  void refreshCoverage(var done) {
    library.refreshCoverage().whenComplete(done);
  }
}
