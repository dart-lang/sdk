// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nav_bar_element;

import 'dart:html' hide Notification;
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart' show Notification;
import 'package:polymer/polymer.dart';

@CustomTag('vm-nav-menu')
class VMNavMenuElement extends ObservatoryElement {
  @published bool last = false;
  @published VM vm;

  String nameAndAddress(name, target) {
    if (name != null && target != null) {
      return '${name}@${target.networkAddress}';
    } else {
      return '<initializing>';
    }
  }

  VMNavMenuElement.created() : super.created();
}

@CustomTag('library-nav-menu')
class LibraryNavMenuElement extends ObservatoryElement {
  @published Library library;
  @published bool last = false;

  LibraryNavMenuElement.created() : super.created();
}

@CustomTag('class-nav-menu')
class ClassNavMenuElement extends ObservatoryElement {
  @published Class cls;
  @published bool last = false;

  ClassNavMenuElement.created() : super.created();
}

@CustomTag('nav-notify')
class NavNotifyElement extends ObservatoryElement {
  @published ObservableList<Notification> notifications;
  @published bool notifyOnPause = true;

  NavNotifyElement.created() : super.created();
}

@CustomTag('nav-notify-event')
class NavNotifyEventElement extends ObservatoryElement {
  @published ObservableList<Notification> notifications;
  @published Notification notification;
  @published ServiceEvent event;
  @published bool notifyOnPause = true;

  void closeItem(MouseEvent e, var detail, Element target) {
    notifications.remove(notification);
  }

  NavNotifyEventElement.created() : super.created();
}

@CustomTag('nav-notify-exception')
class NavNotifyExceptionElement extends ObservatoryElement {
  @published ObservableList<Notification> notifications;
  @published Notification notification;
  @published var exception;
  @published var stacktrace;

  exceptionChanged() {
    notifyPropertyChange(#isNetworkError, true, false);
    notifyPropertyChange(#isUnexpectedError, true, false);
  }

  @observable get isNetworkError {
    return (exception is NetworkRpcException);
  }

  @observable get isUnexpectedError {
    return (exception is! NetworkRpcException);
  }

  void closeItem(MouseEvent e, var detail, Element target) {
    notifications.remove(notification);
  }

  NavNotifyExceptionElement.created() : super.created();
}
