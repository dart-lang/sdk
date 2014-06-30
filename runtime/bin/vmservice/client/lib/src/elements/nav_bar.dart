// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nav_bar_element;

import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';


@CustomTag('nav-bar')
class NavBarElement extends ObservatoryElement {
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

@CustomTag('nav-refresh')
class NavRefreshElement extends ObservatoryElement {
  @published var callback;
  @published bool active = false;
  @published String label = 'Refresh';

  NavRefreshElement.created() : super.created();

  void buttonClick(Event e, var detail, Node target) {
    if (active) {
      return;
    }
    active = true;
    if (callback != null) {
      callback(refreshDone);
    }
  }

  void refreshDone() {
    active = false;
  }
}

@CustomTag('nav-control')
class NavControlElement extends ObservatoryElement {
  NavControlElement.created() : super.created();

  void forward(Event e, var detail, Element target) {
    location.forward();
  }

  void back(Event e, var detail, Element target) {
    location.back();
  }
}

@CustomTag('top-nav-menu')
class TopNavMenuElement extends ObservatoryElement {
  @published bool last = false;

  TopNavMenuElement.created() : super.created();
}

@CustomTag('isolate-nav-menu')
class IsolateNavMenuElement extends ObservatoryElement {
  @published bool last = false;
  @published Isolate isolate;

  void isolateChanged(oldValue) {
    notifyPropertyChange(#hashLinkWorkaround, 0, 1);
  }

  // TODO(turnidge): Figure out why polymer needs this function.
  @reflectable
  String get hashLinkWorkaround {
    if (isolate != null) {
      return isolate.link;
    } else {
      return '';
    }
  }
  @reflectable set hashLinkWorkaround(var x) { /* silence polymer */ }

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
  @published ObservableList<ServiceEvent> events;
  
  NavNotifyElement.created() : super.created();
}

@CustomTag('nav-notify-item')
class NavNotifyItemElement extends ObservatoryElement {
  @published ObservableList<ServiceEvent> events;
  @published ServiceEvent event;
  
  void closeItem(MouseEvent e, var detail, Element target) {
    events.remove(event);
  }

  NavNotifyItemElement.created() : super.created();
}
