// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_view_element;

import 'isolate_element.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

@CustomTag('library-view')
class LibraryViewElement extends IsolateElement {
  @published Map library = toObservable({});

  LibraryViewElement.created() : super.created();

  void refresh(var done) {
    isolate.getMap(library['id']).then((map) {
        library = map;
    }).catchError((e, trace) {
          Logger.root.severe('Error while refreshing library-view: $e\n$trace');
    }).whenComplete(done);
  }
}
