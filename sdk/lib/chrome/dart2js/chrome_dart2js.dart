library chrome;

import 'dart:_foreign_helper' show JS;
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:chrome library.



// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// This is an example of exposing chrome APIs in Dart and will be replaced with
// the proper implementation in the future.

class AppModule {
  AppModule._();

  WindowModule get window => new WindowModule._();
}

class WindowModule {
  WindowModule._();

  void create(String url) {
    var chrome = JS('', 'chrome');

    if (chrome == null) {
      throw new UnsupportedError('Not supported by current browser');
    }
    var app = JS('', '#.app', chrome);
    if (app == null) {
      throw new UnsupportedError('Not supported by current browser');
    }
    var window = JS('', '#.window', app);
    if (app == null) {
      throw new UnsupportedError('Not supported by current browser');
    }
    JS('void', '#.create(#)', window, url);
  }
}

final app = new AppModule._();
