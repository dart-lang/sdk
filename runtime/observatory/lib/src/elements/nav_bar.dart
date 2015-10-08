// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nav_bar_element;

import 'dart:async';
import 'dart:html' hide Notification;
import 'observatory_element.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart' show Notification;
import 'package:polymer/polymer.dart';


@CustomTag('nav-bar')
class NavBarElement extends ObservatoryElement {
  @published bool notifyOnPause = true;
  @published bool pad = true;

  NavBarElement.created() : super.created();
}

@CustomTag('nav-menu')
class NavMenuElement extends ObservatoryElement {
  @published String link = '#';
  @published String anchor = '---';
  @published bool last = false;

  NavMenuElement.created() : super.created();
}

@CustomTag('nav-menu-item')
class NavMenuItemElement extends ObservatoryElement {
  @published String link = '#';
  @published String anchor = '---';

  NavMenuItemElement.created() : super.created();
}

typedef Future RefreshCallback();

@CustomTag('nav-refresh')
class NavRefreshElement extends ObservatoryElement {
  @published RefreshCallback callback;
  @published bool active = false;
  @published String label = 'Refresh';

  NavRefreshElement.created() : super.created();

  void buttonClick(Event e, var detail, Node target) {
    if (active) {
      return;
    }
    active = true;
    if (callback != null) {
      callback()
        .catchError(app.handleException)
        .whenComplete(refreshDone);
    }
  }

  void refreshDone() {
    active = false;
  }
}

@CustomTag('top-nav-menu')
class TopNavMenuElement extends ObservatoryElement {
  @published bool last = false;

  TopNavMenuElement.created() : super.created();
}

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

@CustomTag('isolate-nav-menu')
class IsolateNavMenuElement extends ObservatoryElement {
  @published bool last = false;
  @published Isolate isolate;

  IsolateNavMenuElement.created() : super.created();
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
