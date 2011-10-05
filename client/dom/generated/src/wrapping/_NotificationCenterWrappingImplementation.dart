// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NotificationCenterWrappingImplementation extends DOMWrapperBase implements NotificationCenter {
  _NotificationCenterWrappingImplementation() : super() {}

  static create__NotificationCenterWrappingImplementation() native {
    return new _NotificationCenterWrappingImplementation();
  }

  int checkPermission() {
    return _checkPermission(this);
  }
  static int _checkPermission(receiver) native;

  Notification createHTMLNotification(String url) {
    return _createHTMLNotification(this, url);
  }
  static Notification _createHTMLNotification(receiver, url) native;

  Notification createNotification(String iconUrl, String title, String body) {
    return _createNotification(this, iconUrl, title, body);
  }
  static Notification _createNotification(receiver, iconUrl, title, body) native;

  void requestPermission(VoidCallback callback) {
    _requestPermission(this, callback);
    return;
  }
  static void _requestPermission(receiver, callback) native;

  String get typeName() { return "NotificationCenter"; }
}
