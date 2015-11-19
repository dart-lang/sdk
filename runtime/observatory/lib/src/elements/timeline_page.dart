// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart';
import 'package:polymer/polymer.dart';


@CustomTag('timeline-page')
class TimelinePageElement extends ObservatoryElement {
  TimelinePageElement.created() : super.created();

  attached() {
    super.attached();
    _resizeSubscription = window.onResize.listen((_) => _updateSize());
    _updateSize();
  }

  detached() {
    super.detached();
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
    }
  }

  Future postMessage(String method) {
    IFrameElement e = $['root'];
    var message = {
      'method': method,
      'params': {
        'vmAddress': (app.vm as WebSocketVM).target.networkAddress
      }
    };
    e.contentWindow.postMessage(JSON.encode(message), window.location.href);
    return null;
  }

  Future refresh() async {
    return postMessage('refresh');
  }

  Future clear() async {
    await app.vm.invokeRpc('_clearVMTimeline', {});
    return postMessage('clear');
  }

  Future recordOn() async {
    return app.vm.invokeRpc('_setVMTimelineFlag', {
      '_record': 'all',
    });
  }

  Future recordOff() async {
    return app.vm.invokeRpc('_setVMTimelineFlag', {
      '_record': 'none',
    });
  }

  _updateSize() {
    IFrameElement e = $['root'];
    final totalHeight = window.innerHeight;
    final top = e.offset.top;
    final bottomMargin = 32;
    final mainHeight = totalHeight - top - bottomMargin;
    e.style.setProperty('height', '${mainHeight}px');
    e.style.setProperty('width', '100%');
  }


  StreamSubscription _resizeSubscription;
}
