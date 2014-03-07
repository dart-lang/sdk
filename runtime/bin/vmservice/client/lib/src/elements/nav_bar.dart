// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library nav_bar_element;

import 'dart:html';
import 'isolate_element.dart';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';


@CustomTag('nav-bar')
class NavBarElement extends ObservatoryElement {
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

@CustomTag('top-nav-menu')
class TopNavMenuElement extends ObservatoryElement {
  @published bool last = false;

  TopNavMenuElement.created() : super.created();
}

@CustomTag('isolate-nav-menu')
class IsolateNavMenuElement extends IsolateElement {
  @published bool last = false;

  IsolateNavMenuElement.created() : super.created();
}

@CustomTag('library-nav-menu')
class LibraryNavMenuElement extends IsolateElement {
  @published Map library;
  @published bool last = false;

  LibraryNavMenuElement.created() : super.created();
}

@CustomTag('class-nav-menu')
class ClassNavMenuElement extends IsolateElement {
  @published Map cls;
  @published bool last = false;

  ClassNavMenuElement.created() : super.created();
}
