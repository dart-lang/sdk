// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/repositories.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/nav/notify.dart';

class NavNotifyElementWrapper extends HtmlElement {
  static final binder = new Binder<NavNotifyElementWrapper>(
    const [const Binding('notifications'), const Binding('notifyOnPause')]);

  static const tag = const Tag<NavNotifyElementWrapper>('nav-notify');

  NotificationRepository _notifications;
  bool _notifyOnPause = true;
  NotificationRepository get notifications => _notifications;
  bool get notifyOnPause => _notifyOnPause;
  set notifications(NotificationRepository value) {
    _notifications = value; render();
  }
  set notifyOnPause(bool value) {
    _notifyOnPause = value; render();
  }

  NavNotifyElementWrapper.created() : super.created() {
    binder.registerCallback(this);
    createShadowRoot();
    render();
  }

  @override
  void attached() {
    super.attached();
    render();
  }

  void render() {
    shadowRoot.children = [];
    if (_notifications == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '''nav-notify-wrapped > div {
          float: right;
        }
        nav-notify-wrapped > div > div {
          display: block;
          position: absolute;
          top: 98%;
          right: 0;
          margin: 0;
          padding: 0;
          width: auto;
          z-index: 1000;
          background: none;
        }

        /* nav-exception & nav-event */

        nav-exception > div, nav-event > div {
          position: relative;
          padding: 16px;
          margin-top: 10px;
          margin-right: 10px;
          padding-right: 25px;
          width: 500px;
          color: #ddd;
          background: rgba(0,0,0,.6);
          border: solid 2px white;
          box-shadow: 0 0 5px black;
          border-radius: 5px;
          animation: fadein 1s;
        }

        nav-exception *, nav-event * {
          color: #ddd;
          font-size: 12px;
        }

        nav-exception > div > a, nav-event > div > a {
          color: white;
          text-decoration: none;
        }

        nav-exception > div > a:hover, nav-event > div > a:hover {
          text-decoration: underline;
        }

        nav-exception > div > div {
          margin-left:20px;
          white-space: pre
        }

        nav-exception > div > button, nav-event > div > button {
          background: transparent;
          border: none;
          position: absolute;
          display: block;
          top: 4px;
          right: 4px;
          height: 18px;
          width: 18px;
          line-height: 16px;
          border-radius: 9px;
          color: white;
          font-size: 18px;
          cursor: pointer;
          text-align: center;
        }

        nav-exception > div > button:hover, nav-event > div > button:hover {
          background: rgba(255,255,255,0.5);
        }''',
      new NavNotifyElement(_notifications, notifyOnPause: notifyOnPause,
                                 queue: ObservatoryApplication.app.queue)
    ];
  }
}
