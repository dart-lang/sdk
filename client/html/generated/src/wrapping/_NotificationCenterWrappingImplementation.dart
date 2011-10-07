// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class NotificationCenterWrappingImplementation extends DOMWrapperBase implements NotificationCenter {
  NotificationCenterWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int checkPermission() {
    return _ptr.checkPermission();
  }

  Notification createHTMLNotification(String url) {
    return LevelDom.wrapNotification(_ptr.createHTMLNotification(url));
  }

  Notification createNotification(String iconUrl, String title, String body) {
    return LevelDom.wrapNotification(_ptr.createNotification(iconUrl, title, body));
  }

  void requestPermission(VoidCallback callback) {
    _ptr.requestPermission(LevelDom.unwrap(callback));
    return;
  }
}
