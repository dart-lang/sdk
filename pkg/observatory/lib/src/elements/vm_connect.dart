// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_connect_element;

import 'dart:async';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/rendering_scheduler.dart';
import 'nav/notify.dart';
import 'nav/top_menu.dart';
import 'vm_connect_target.dart';

class VMConnectElement extends CustomElement implements Renderable {
  late RenderingScheduler<VMConnectElement> _r;

  Stream<RenderedEvent<VMConnectElement>> get onRendered => _r.onRendered;

  late M.NotificationRepository _notifications;
  late M.TargetRepository _targets;
  late StreamSubscription _targetsSubscription;

  late String _address;

  factory VMConnectElement(
    M.TargetRepository targets,
    M.NotificationRepository notifications, {
    String address = '',
    RenderingQueue? queue,
  }) {
    VMConnectElement e = new VMConnectElement.created();
    e._r = new RenderingScheduler<VMConnectElement>(e, queue: queue);
    e._address = address;
    e._notifications = notifications;
    e._targets = targets;
    return e;
  }

  VMConnectElement.created() : super.created('vm-connect');

  @override
  void attached() {
    super.attached();
    _targetsSubscription = _targets.onChange.listen((_) => _r.dirty());
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    removeChildren();
    _r.disable(notify: true);
    _targetsSubscription.cancel();
  }

  void render() {
    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      new HTMLDivElement()
        ..className = 'content-centered'
        ..appendChildren(<HTMLElement>[
          new HTMLHeadingElement.h1()..textContent = 'Connect to a Dart VM',
          new HTMLHRElement(),
          new HTMLBRElement(),
          new HTMLDivElement()
            ..className = 'flex-row'
            ..appendChildren(<HTMLElement>[
              new HTMLDivElement()
                ..className = 'flex-item-40-percent'
                ..appendChildren(<HTMLElement>[
                  new HTMLHeadingElement.h2()
                    ..textContent = 'Connect over WebSocket',
                  new HTMLBRElement(),
                  new HTMLUListElement()..appendChildren(
                    _targets.list().map<HTMLElement>((target) {
                      final bool current = _targets.isConnectedVMTarget(target);
                      return new HTMLLIElement()..appendChild(
                        (new VMConnectTargetElement(
                                target,
                                current: current,
                                queue: _r.queue,
                              )
                              ..onConnect.listen(_connect)
                              ..onDelete.listen(_delete))
                            .element,
                      );
                    }),
                  ),
                  new HTMLHRElement(),
                  new HTMLFormElement()
                    ..autocomplete = 'on'
                    ..appendChildren(<HTMLElement>[
                      _createAddressBox(),
                      new HTMLSpanElement()..textContent = ' ',
                      new HTMLButtonElement()
                        ..className = 'vm_connect'
                        ..textContent = 'Connect'
                        ..onClick.listen((e) {
                          e.preventDefault();
                          _createAndConnect();
                        }),
                    ]),
                  new HTMLBRElement(),
                  new HTMLPreElement.pre()
                    ..className = 'well'
                    ..textContent = 'Run Standalone with: \'--observe\'',
                ]),
              new HTMLDivElement()..className = 'flex-item-20-percent',
            ]),
        ]),
    ];
  }

  HTMLInputElement _createAddressBox() {
    var textbox = new HTMLInputElement()
      ..className = 'textbox'
      ..placeholder = 'http://127.0.0.1:8181/...'
      ..value = _address
      ..onKeyUp.where((e) => e.key == '\n').listen((e) {
        e.preventDefault();
        _createAndConnect();
      });
    textbox.onInput.listen((e) {
      _address = textbox.value;
    });
    return textbox;
  }

  void _createAndConnect() {
    if (_address.isEmpty) return;
    String normalizedNetworkAddress = _normalizeStandaloneAddress(_address);
    _targets.add(normalizedNetworkAddress);
    var target = _targets.find(normalizedNetworkAddress);
    assert(target != null);
    _targets.setCurrent(target!);
    // the navigation to the VM page is done in the ObservatoryApplication
  }

  void _connect(TargetEvent e) {
    _targets.setCurrent(e.target);
  }

  void _delete(TargetEvent e) => _targets.delete(e.target);

  static String _normalizeStandaloneAddress(String networkAddress) {
    if (!networkAddress.startsWith('http') &&
        !networkAddress.startsWith('ws')) {
      networkAddress = 'http://$networkAddress';
    }
    try {
      Uri uri = Uri.parse(networkAddress);
      if (uri.path.endsWith('/ws')) {
        return 'ws://${uri.authority}${uri.path}';
      }
      return 'ws://${uri.authority}${uri.path}/ws';
    } catch (e) {
      print('caught exception with: $networkAddress -- $e');
      return networkAddress;
    }
  }
}
