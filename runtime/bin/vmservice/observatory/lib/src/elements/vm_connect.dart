// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_connect_element;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart';

void _connectToVM(ObservatoryApplication app, WebSocketVMTarget target) {
  app.vm = new WebSocketVM(target);
}

@CustomTag('vm-connect-target')
class VMConnectTargetElement extends ObservatoryElement {
  @published WebSocketVMTarget target;

  VMConnectTargetElement.created() : super.created();

  bool get isChromeTarget {
    if (target == null) {
      return false;
    }
    return target.chrome;
  }

  bool get isCurrentTarget {
    if (app.vm == null) {
      return false;
    }
    return (app.vm as WebSocketVM).target == target;
  }

  void connectToVm(MouseEvent event, var detail, Element node) {
    if (event.button > 0 || event.metaKey || event.ctrlKey ||
        event.shiftKey || event.altKey) {
      // Not a left-click or a left-click with a modifier key:
      // Let browser handle.
      return;
    }
    event.preventDefault();
    WebSocketVM currentVM = app.vm;
    if ((currentVM == null) || (currentVM.target != target)) {
      _connectToVM(app, target);
    }
    var href = node.attributes['href'];
    app.locationManager.go(href);
  }

  void deleteVm(MouseEvent event, var detail, Element node) {
    app.targets.remove(target);
  }
}

@CustomTag('vm-connect')
class VMConnectElement extends ObservatoryElement {
  @published String standaloneVmAddress = '';
  @published String chromiumAddress = 'localhost:9222';
  @observable ObservableList<WebSocketVMTarget> chromeTargets =
      new ObservableList<WebSocketVMTarget>();

  VMConnectElement.created() : super.created() {
    pollPeriod = new Duration(seconds: 1);
  }

  void _connect(WebSocketVMTarget target) {
    _connectToVM(app, target);
    app.locationManager.go('#/vm');
  }

  void onPoll() {
    _refreshTabs();
  }

  String _normalizeStandaloneAddress(String networkAddress) {
    if (networkAddress.startsWith('ws://')) {
      return networkAddress;
    }
    return 'ws://${networkAddress}/ws';
  }

  void connectStandalone(Event e, var detail, Node target) {
    // Prevent any form action.
    e.preventDefault();
    var targetAddress = _normalizeStandaloneAddress(standaloneVmAddress);
    var target = app.targets.findOrMake(targetAddress);
    _connect(target);
  }

  void getTabs(Event e, var detail, Node target) {
    // Prevent any form action.
    e.preventDefault();
    _refreshTabs();
  }

  void _refreshTabs() {
    ChromiumTargetLister.fetch(chromiumAddress).then((targets) {
      chromeTargets.clear();
      if (targets == null) {
        return;
      }
      for (var i = 0; i < targets.length; i++) {
        if (targets[i].networkAddress == null) {
          // Don't add targets that don't have a network address.
          // This happens when a tab has devtools open!
          continue;
        }
        chromeTargets.add(targets[i]);
      }
    }).catchError((e) {
      chromeTargets.clear();
    });
  }
}
