// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_connect_element;

import 'dart:convert';
import 'dart:html';

import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service_html.dart';
import 'package:polymer/polymer.dart';

void _connectToVM(ObservatoryApplication app, WebSocketVMTarget target) {
  app.vm = new WebSocketVM(target);
}

@CustomTag('vm-connect-target')
class VMConnectTargetElement extends ObservatoryElement {
  @published WebSocketVMTarget target;

  VMConnectTargetElement.created() : super.created();

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
    if ((currentVM == null) ||
        currentVM.isDisconnected ||
        (currentVM.target != target)) {
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

  VMConnectElement.created() : super.created() {
  }

  void _connect(WebSocketVMTarget target) {
    _connectToVM(app, target);
    app.locationManager.goForwardingParameters('/vm');
  }

  @override
  void attached() {
    super.attached();
    var fileInput = shadowRoot.querySelector('#crashDumpFile');
    fileInput.onChange.listen(_onCrashDumpFileChange);
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
    if (standaloneVmAddress == null) {
      return;
    }
    if (standaloneVmAddress.isEmpty) {
      return;
    }
    var targetAddress = _normalizeStandaloneAddress(standaloneVmAddress);
    var target = app.targets.findOrMake(targetAddress);
    _connect(target);
  }

  _onCrashDumpFileChange(e) {
    var fileInput = shadowRoot.querySelector('#crashDumpFile');
    var reader = new FileReader();
    reader.readAsText(fileInput.files[0]);
    reader.onLoad.listen((_) {
      var crashDump = JSON.decode(reader.result);
      app.loadCrashDump(crashDump);
    });
  }
}
