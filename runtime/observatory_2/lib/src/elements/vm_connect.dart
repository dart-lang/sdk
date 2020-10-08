// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_connect_element;

import 'dart:async';
import 'dart:html';

import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/helpers/nav_bar.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/src/elements/nav/notify.dart';
import 'package:observatory_2/src/elements/nav/top_menu.dart';
import 'package:observatory_2/src/elements/view_footer.dart';
import 'package:observatory_2/src/elements/vm_connect_target.dart';

class VMConnectElement extends CustomElement implements Renderable {
  RenderingScheduler<VMConnectElement> _r;

  Stream<RenderedEvent<VMConnectElement>> get onRendered => _r.onRendered;

  M.NotificationRepository _notifications;
  M.TargetRepository _targets;
  StreamSubscription _targetsSubscription;

  String _address;

  factory VMConnectElement(
      M.TargetRepository targets, M.NotificationRepository notifications,
      {String address: '', RenderingQueue queue}) {
    assert(address != null);
    assert(notifications != null);
    assert(targets != null);
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
    children = <Element>[];
    _r.disable(notify: true);
    _targetsSubscription.cancel();
  }

  void render() {
    final host = window.location.hostname;
    final port = window.location.port;
    children = <Element>[
      navBar(<Element>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavNotifyElement(_notifications, queue: _r.queue).element
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = <Element>[
          new HeadingElement.h1()..text = 'Connect to a Dart VM',
          new HRElement(),
          new BRElement(),
          new DivElement()
            ..classes = ['flex-row']
            ..children = <Element>[
              new DivElement()
                ..classes = ['flex-item-40-percent']
                ..children = <Element>[
                  new HeadingElement.h2()..text = 'Connect over WebSocket',
                  new BRElement(),
                  new UListElement()
                    ..children = _targets.list().map<Element>((target) {
                      final bool current = _targets.isConnectedVMTarget(target);
                      return new LIElement()
                        ..children = <Element>[
                          (new VMConnectTargetElement(target,
                                  current: current, queue: _r.queue)
                                ..onConnect.listen(_connect)
                                ..onDelete.listen(_delete))
                              .element
                        ];
                    }).toList(),
                  new HRElement(),
                  new FormElement()
                    ..autocomplete = 'on'
                    ..children = <Element>[
                      _createAddressBox(),
                      new SpanElement()..text = ' ',
                      new ButtonElement()
                        ..classes = ['vm_connect']
                        ..text = 'Connect'
                        ..onClick.listen((e) {
                          e.preventDefault();
                          _createAndConnect();
                        }),
                    ],
                  new BRElement(),
                  new PreElement()
                    ..classes = ['well']
                    ..text = 'Run Standalone with: \'--observe\'',
                ],
              new DivElement()..classes = ['flex-item-20-percent'],
            ],
        ],
      new ViewFooterElement(queue: _r.queue).element
    ];
  }

  TextInputElement _createAddressBox() {
    var textbox = new TextInputElement()
      ..classes = ['textbox']
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
    if (_address == null || _address.isEmpty) return;
    String normalizedNetworkAddress = _normalizeStandaloneAddress(_address);
    _targets.add(normalizedNetworkAddress);
    var target = _targets.find(normalizedNetworkAddress);
    assert(target != null);
    _targets.setCurrent(target);
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
