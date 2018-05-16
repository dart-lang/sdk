// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm_connect_element;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/src/elements/vm_connect_target.dart';

typedef void CrashDumpLoadCallback(Map dump);

class VMConnectElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<VMConnectElement>('vm-connect', dependencies: const [
    NavTopMenuElement.tag,
    NavNotifyElement.tag,
    ViewFooterElement.tag,
    VMConnectTargetElement.tag
  ]);

  RenderingScheduler _r;

  Stream<RenderedEvent<VMConnectElement>> get onRendered => _r.onRendered;

  CrashDumpLoadCallback _loadDump;
  M.NotificationRepository _notifications;
  M.TargetRepository _targets;
  StreamSubscription _targetsSubscription;

  String _address;

  factory VMConnectElement(M.TargetRepository targets,
      CrashDumpLoadCallback loadDump, M.NotificationRepository notifications,
      {String address: '', RenderingQueue queue}) {
    assert(address != null);
    assert(loadDump != null);
    assert(notifications != null);
    assert(targets != null);
    VMConnectElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._address = address;
    e._loadDump = loadDump;
    e._notifications = notifications;
    e._targets = targets;
    return e;
  }

  VMConnectElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _targetsSubscription = _targets.onChange.listen((_) => _r.dirty());
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
    _targetsSubscription.cancel();
  }

  void render() {
    final host = window.location.hostname;
    final port = window.location.port;
    children = [
      navBar([
        new NavTopMenuElement(queue: _r.queue),
        new NavNotifyElement(_notifications, queue: _r.queue)
      ]),
      new DivElement()
        ..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()..text = 'Connect to a Dart VM',
          new HRElement(),
          new BRElement(),
          new DivElement()
            ..classes = ['flex-row']
            ..children = [
              new DivElement()
                ..classes = ['flex-item-40-percent']
                ..children = [
                  new HeadingElement.h2()..text = 'Connect over WebSocket',
                  new BRElement(),
                  new UListElement()
                    ..children = _targets.list().map((target) {
                      final bool current = _targets.isConnectedVMTarget(target);
                      return new LIElement()
                        ..children = [
                          new VMConnectTargetElement(target,
                              current: current, queue: _r.queue)
                            ..onConnect.listen(_connect)
                            ..onDelete.listen(_delete)
                        ];
                    }).toList(),
                  new HRElement(),
                  new FormElement()
                    ..autocomplete = 'on'
                    ..children = [
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
              new DivElement()
                ..classes = ['flex-item-40-percent']
                ..children = [
                  new HeadingElement.h2()..text = 'View crash dump',
                  new BRElement(),
                  _createCrushDumpLoader(),
                  new BRElement(),
                  new BRElement(),
                  new PreElement()
                    ..classes = ['well']
                    ..text = 'Request a crash dump with:\n'
                        '\'curl $host:$port/_getCrashDump > dump.json\'',
                ]
            ],
        ],
      new ViewFooterElement(queue: _r.queue)
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

  FileUploadInputElement _createCrushDumpLoader() {
    FileUploadInputElement e = new FileUploadInputElement()
      ..id = 'crashDumpFile';
    e.onChange.listen((_) {
      var reader = new FileReader();
      reader.readAsText(e.files[0]);
      reader.onLoad.listen((_) {
        var crashDump = json.decode(reader.result);
        _loadDump(crashDump);
      });
    });
    return e;
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
