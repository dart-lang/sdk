// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service_html.dart';
import 'package:polymer/polymer.dart';


@CustomTag('timeline-page')
class TimelinePageElement extends ObservatoryElement {
  TimelinePageElement.created() : super.created();

  attached() {
    super.attached();
    _resizeSubscription = window.onResize.listen((_) => _updateSize());
    _updateSize();
    // Click refresh button.
    NavRefreshElement refreshButton = $['refresh'];
    refreshButton.buttonClick(null, null, null);
  }

  detached() {
    super.detached();
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
    }
  }

  Future postMessage(String method) {
    IFrameElement e = $['root'];
    var isolateIds = new List();
    for (var isolate in app.vm.isolates) {
      isolateIds.add(isolate.id);
    }
    var message = {
      'method': method,
      'params': {
        'vmAddress': (app.vm as WebSocketVM).target.networkAddress,
        'isolateIds': isolateIds
      }
    };
    e.contentWindow.postMessage(JSON.encode(message), window.location.href);
    return null;
  }

  Future refresh() async {
    await app.vm.reload();
    await app.vm.reloadIsolates();
    return postMessage('refresh');
  }

  Future clear() async {
    await app.vm.invokeRpc('_clearVMTimeline', {});
    return postMessage('clear');
  }

  Future recordOn() async {
    return app.vm.invokeRpc('_setVMTimelineFlags', {
      'recordedStreams': ['all'],
    });
  }

  Future recordOff() async {
    return app.vm.invokeRpc('_setVMTimelineFlags', {
      'recordedStreams': [],
    });
  }

  Future saveTimeline() async {
    return postMessage('save');
  }

  Future loadTimeline() async {
    return postMessage('load');
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
