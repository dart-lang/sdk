// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'package:observatory/service.dart' as S;
import 'package:observatory/service_html.dart' as SH;
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/nav_menu.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/nav/notify.dart';
import 'package:observatory/src/elements/nav/refresh.dart';
import 'package:observatory/src/elements/nav/top_menu.dart';
import 'package:observatory/src/elements/nav/vm_menu.dart';

enum _Profile { none, dart, vm, all, custom }

class TimelinePageElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<TimelinePageElement>('timeline-page', dependencies: const [
    NavTopMenuElement.tag,
    NavVMMenuElement.tag,
    NavRefreshElement.tag,
    NavNotifyElement.tag
  ]);

  RenderingScheduler<TimelinePageElement> _r;

  Stream<RenderedEvent<TimelinePageElement>> get onRendered => _r.onRendered;

  M.VM _vm;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  String _recorderName = '';
  _Profile _profile = _Profile.none;
  final Set<String> _availableStreams = new Set<String>();
  final Set<String> _recordedStreams = new Set<String>();

  M.VMRef get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory TimelinePageElement(
      M.VM vm, M.EventRepository events, M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(events != null);
    assert(notifications != null);
    TimelinePageElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  TimelinePageElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _setupInitialState();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  IFrameElement _frame;
  DivElement _content;

  void render() {
    if (_frame == null) {
      _frame = new IFrameElement()..src = 'timeline.html';
    }
    if (_content == null) {
      _content = new DivElement()..classes = ['content-centered-big'];
    }
    _content.children = [
      new HeadingElement.h1()..text = 'Timeline settings',
      new DivElement()
        ..classes = ['memberList']
        ..children = [
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Recorder:',
              new DivElement()
                ..classes = ['memberValue']
                ..text = _recorderName
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Recorded Streams Profile:',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _createProfileSelect()
            ],
          new DivElement()
            ..classes = ['memberItem']
            ..children = [
              new DivElement()
                ..classes = ['memberName']
                ..text = 'Recorded Streams:',
              new DivElement()
                ..classes = ['memberValue']
                ..children = _availableStreams.map(_makeStreamToggle).toList()
            ]
        ]
    ];
    if (children.isEmpty) {
      children = [
        navBar([
          new NavTopMenuElement(queue: _r.queue),
          new NavVMMenuElement(_vm, _events, queue: _r.queue),
          navMenu('timeline', link: Uris.timeline()),
          new NavRefreshElement(queue: _r.queue)
            ..onRefresh.listen((e) async {
              e.element.disabled = true;
              await _refresh();
              e.element.disabled = false;
            }),
          new NavRefreshElement(label: 'clear', queue: _r.queue)
            ..onRefresh.listen((e) async {
              e.element.disabled = true;
              await _clear();
              e.element.disabled = false;
            }),
          new NavRefreshElement(label: 'save', queue: _r.queue)
            ..onRefresh.listen((e) async {
              e.element.disabled = true;
              await _save();
              e.element.disabled = false;
            }),
          new NavRefreshElement(label: 'load', queue: _r.queue)
            ..onRefresh.listen((e) async {
              e.element.disabled = true;
              await _load();
              e.element.disabled = false;
            }),
          new NavNotifyElement(_notifications, queue: _r.queue)
        ]),
        _content,
        new DivElement()
          ..classes = ['iframe']
          ..children = [_frame]
      ];
    }
  }

  List<Element> _createProfileSelect() {
    var s;
    return [
      s = new SelectElement()
        ..classes = ['direction-select']
        ..value = _profileToString(_profile)
        ..children = _Profile.values.map((direction) {
          return new OptionElement(
              value: _profileToString(direction),
              selected: _profile == direction)
            ..text = _profileToString(direction);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _profile = _Profile.values[s.selectedIndex];
          _applyPreset();
          _r.dirty();
        })
    ];
  }

  String _profileToString(_Profile profile) {
    switch (profile) {
      case _Profile.none:
        return 'none';
      case _Profile.dart:
        return 'Dart Developer';
      case _Profile.vm:
        return 'VM Developer';
      case _Profile.all:
        return 'All';
      case _Profile.custom:
        return 'Custom';
    }
    throw new Exception('Unknown Profile ${profile}');
  }

  Future _refresh() async {
    S.VM vm = _vm as S.VM;
    await vm.reload();
    await vm.reloadIsolates();
    return _postMessage('refresh');
  }

  Future _clear() async {
    S.VM vm = _vm as S.VM;
    await vm.invokeRpc('_clearVMTimeline', {});
    return _postMessage('clear');
  }

  Future _save() async {
    return _postMessage('save');
  }

  Future _load() async {
    return _postMessage('load');
  }

  Future _postMessage(String method) {
    S.VM vm = _vm as S.VM;
    var isolateIds = new List();
    for (var isolate in vm.isolates) {
      isolateIds.add(isolate.id);
    }
    var message = {
      'method': method,
      'params': {
        'vmAddress': (vm as SH.WebSocketVM).target.networkAddress,
        'isolateIds': isolateIds
      }
    };
    _frame.contentWindow
        .postMessage(JSON.encode(message), window.location.href);
    return null;
  }

  Future _setupInitialState() async {
    await _updateRecorderUI();
    await _refresh();
  }

  // Dart developers care about the following streams:
  List<String> _dartPreset = ['GC', 'Compiler', 'Dart'];

  // VM developers care about the following streams:
  List<String> _vmPreset = [
    'GC',
    'Compiler',
    'Dart',
    'Debugger',
    'Embedder',
    'Isolate',
    'VM'
  ];

  void _applyPreset() {
    switch (_profile) {
      case _Profile.none:
        _recordedStreams.clear();
        break;
      case _Profile.all:
        _recordedStreams.clear();
        _recordedStreams.addAll(_availableStreams);
        break;
      case _Profile.vm:
        _recordedStreams.clear();
        _recordedStreams.addAll(_vmPreset);
        break;
      case _Profile.dart:
        _recordedStreams.clear();
        _recordedStreams.addAll(_dartPreset);
        break;
      case _Profile.custom:
        return;
    }
    _applyStreamChanges();
    _updateRecorderUI();
  }

  Future _updateRecorderUI() async {
    S.VM vm = _vm as S.VM;
    // Grab the current timeline flags.
    S.ServiceMap response = await vm.invokeRpc('_getVMTimelineFlags', {});
    assert(response['type'] == 'TimelineFlags');
    // Process them so we know available streams.
    _processFlags(response);
    // Refresh the UI.
    _r.dirty();
  }

  Element _makeStreamToggle(String streamName) {
    LabelElement label = new LabelElement();
    label.style.paddingLeft = '8px';
    SpanElement span = new SpanElement();
    span.text = streamName;
    InputElement checkbox = new InputElement();
    checkbox.onChange.listen((_) {
      if (checkbox.checked) {
        _recordedStreams.add(streamName);
      } else {
        _recordedStreams.remove(streamName);
      }
      _applyStreamChanges();
      _updateRecorderUI();
    });
    checkbox.type = 'checkbox';
    checkbox.checked = _recordedStreams.contains(streamName);
    label.children.add(checkbox);
    label.children.add(span);
    return label;
  }

  Future _applyStreamChanges() {
    S.VM vm = _vm as S.VM;
    return vm.invokeRpc('_setVMTimelineFlags', {
      'recordedStreams': '[${_recordedStreams.join(', ')}]',
    });
  }

  void _processFlags(S.ServiceMap response) {
    // Grab the recorder name.
    _recorderName = response['recorderName'];
    // Update the set of available streams.
    _availableStreams.clear();
    response['availableStreams']
        .forEach((String streamName) => _availableStreams.add(streamName));
    // Update the set of recorded streams.
    _recordedStreams.clear();
    response['recordedStreams']
        .forEach((String streamName) => _recordedStreams.add(streamName));
    _r.dirty();
  }
}
