// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:observatory/app.dart';
import 'package:observatory/service_html.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/shims/binding.dart';
import 'package:observatory/src/elements/vm_connect_target.dart';

@bindable
class VMConnectTargetElementWrapper extends HtmlElement {
  static const binder = const Binder<VMConnectTargetElementWrapper>(const {
      'target': #target
    });

  static const tag =
    const Tag<VMConnectTargetElementWrapper>('vm-connect-target');

  WebSocketVMTarget _target;
  WebSocketVMTarget get target => _target;
  void set target(WebSocketVMTarget target) { _target = target; render(); }

  VMConnectTargetElementWrapper.created() : super.created() {
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
    if (target == null) return;

    shadowRoot.children = [
      new StyleElement()
        ..text = '''
        vm-connect-target-wrapped > button.delete-button {
          margin-left: 0.28em;
          padding: 4px;
          background: transparent;
          border: none !important;
        }

        vm-connect-target-wrapped > button.delete-button:hover {
          background: #ff0000;
        }''',
      new VMConnectTargetElement(target, current: current,
          queue: application.queue)
        ..onConnect.listen(connectToVm)
        ..onDelete.listen(deleteVm)
    ];
  }

  static ObservatoryApplication get application => ObservatoryApplication.app;

  bool get current {
    if (application.vm == null) { return false; }
    return (application.vm as WebSocketVM).target == target;
  }

  static void connectToVm(TargetEvent event) {
    WebSocketVM currentVM = application.vm;
    if ((currentVM == null) ||
        currentVM.isDisconnected ||
        (currentVM.target != event.target)) {
      application.vm = new WebSocketVM(event.target);
    }
  }

  static void deleteVm(TargetEvent event) {
    application.targets.remove(event.target);
  }
}
