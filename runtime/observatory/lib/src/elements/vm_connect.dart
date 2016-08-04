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
import 'package:observatory/src/elements/nav/bar.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/view_footer.dart';
import 'package:observatory/src/elements/vm_connect_target.dart';

class VMConnectElement extends HtmlElement implements Renderable {
  static const tag = const Tag<VMConnectElement>('vm-connect',
                     dependencies: const [NavBarElement.tag,
                                          NavTopMenuElement.tag,
                                          NavNotifyElement.tag,
                                          ViewFooterElement.tag,
                                          VMConnectTargetElement.tag]);

  RenderingScheduler _r;

  Stream<RenderedEvent<VMConnectElement>> get onRendered => _r.onRendered;

  M.CrashDumpRepository _dump;
  M.NotificationRepository _notifications;
  M.TargetRepository _targets;
  StreamSubscription _targetsSubscription;

  String _address;

  factory VMConnectElement(M.TargetRepository targets,
                           M.CrashDumpRepository dump,
                           M.NotificationRepository notifications,
                           {String address: '', RenderingQueue queue}) {
    assert(address != null);
    assert(dump != null);
    assert(notifications != null);
    assert(targets != null);
    VMConnectElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._address = address;
    e._dump = dump;
    e._notifications = notifications;
    e._targets = targets;
    return e;
  }

  VMConnectElement.created() : super.created();

  @override
  void attached() {
    super.attached(); _r.enable();
    _targetsSubscription = _targets.onChange.listen((_) => _r.dirty());
  }

  @override
  void detached() {
    super.detached(); children = []; _r.disable(notify: true);
    _targetsSubscription.cancel(); _targetsSubscription = null;
  }

  void render() {
    final host = window.location.hostname;
    final port = window.location.port;
    children = [
      new NavBarElement(queue: _r.queue)
        ..children = [
          new NavTopMenuElement(last: true, queue: _r.queue),
          new NavNotifyElement(_notifications, queue: _r.queue)
        ],
      new DivElement()
        ..classes = ['content-centered']
        ..children = [
          new HeadingElement.h1()..text = 'Connect to a Dart VM',
          new BRElement(), new HRElement(),
          new DivElement()
            ..classes = ['flex-row']
            ..children = [
              new DivElement()
                ..classes = ['flex-item-40-percent']
                ..children = [
                  new HeadingElement.h2()..text = 'WebSocket',
                  new BRElement(),
                  new UListElement()
                    ..children = _targets.list().map((target) {
                      return new LIElement()
                        ..children = [new VMConnectTargetElement(target,
                          current: target == _targets.current, queue: _r.queue)
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
                          e.preventDefault(); _create(); }),
                    ],
                  new BRElement(),
                  new PreElement()
                    ..classes = ['well']
                    ..text = 'Run Standalone with: \'--observe\'',
                  new HRElement()
                ],
              new DivElement()
                ..classes = ['flex-item-20-percent'],
              new DivElement()
                ..classes = ['flex-item-40-percent']
                ..children = [
                  new HeadingElement.h2()..text = 'Crash dump',
                  new BRElement(),
                  _createCrushDumpLoader(),
                  new BRElement(), new BRElement(),
                  new PreElement()
                    ..classes = ['well']
                    ..text = 'Request a crash dump with:\n'
                      '\'curl $host:$port/_getCrashDump > dump.json\'',
                  new HRElement()
                ]
            ],
        ],
      new ViewFooterElement(queue: _r.queue)
    ];
  }

  TextInputElement _createAddressBox() {
    var textbox = new TextInputElement()
      ..classes = ['textbox']
      ..placeholder = 'localhost:8181'
      ..value = _address
      ..onKeyUp
        .where((e) => e.key == '\n')
        .listen((e) { e.preventDefault(); _create(); });
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
        var crashDump = JSON.decode(reader.result);
        _dump.load(crashDump);
      });
    });
    return e;
  }
  void _create() {
    if (_address == null || _address.isEmpty) return;
    _targets.add(_normalizeStandaloneAddress(_address));
  }
  void _connect(TargetEvent e) => _targets.setCurrent(e.target);
  void _delete(TargetEvent e) => _targets.delete(e.target);

  static String _normalizeStandaloneAddress(String networkAddress) {
    if (networkAddress.startsWith('ws://')) {
      return networkAddress;
    }
    return 'ws://${networkAddress}/ws';
  }
}
