// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:html';
import 'dart:convert';
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
  M.TimelineRepository _repository;
  M.EventRepository _events;
  M.NotificationRepository _notifications;
  M.TimelineRecorder _recorder;
  Set<M.TimelineStream> _availableStreams;
  Set<M.TimelineStream> _recordedStreams;
  Set<M.TimelineProfile> _profiles;

  M.VM get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory TimelinePageElement(M.VM vm, M.TimelineRepository repository,
      M.EventRepository events, M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(repository != null);
    assert(events != null);
    assert(notifications != null);
    TimelinePageElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._repository = repository;
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
      _recorder == null
          ? (new DivElement()..text = 'Loading...')
          : (new DivElement()
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
                    ..text = _recorder.name
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
                    ..children =
                        _availableStreams.map(_makeStreamToggle).toList()
                ]
            ])
    ];
    if (children.isEmpty) {
      children = [
        navBar([
          new NavTopMenuElement(queue: _r.queue),
          new NavVMMenuElement(vm, _events, queue: _r.queue),
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
    return [
      new SpanElement()
        ..children = (_profiles.expand((profile) {
          return [
            new ButtonElement()
              ..text = profile.name
              ..onClick.listen((_) {
                _applyPreset(profile);
              }),
            new SpanElement()..text = ' - '
          ];
        }).toList()
          ..removeLast())
    ];
  }

  Future _refresh() async {
    final params = new Map.from(await _repository.getIFrameParams(vm));
    return _postMessage('refresh', params);
  }

  Future _clear() async {
    await _repository.clear(vm);
    return _postMessage('clear');
  }

  Future _save() async {
    return _postMessage('save');
  }

  Future _load() async {
    return _postMessage('load');
  }

  Future _postMessage(String method,
      [Map<String, dynamic> params = const <String, dynamic>{}]) async {
    var message = {'method': method, 'params': params};
    _frame.contentWindow
        .postMessage(JSON.encode(message), window.location.href);
    return null;
  }

  Future _setupInitialState() async {
    await _updateRecorderUI();
    await _refresh();
  }

  void _applyPreset(M.TimelineProfile profile) {
    _recordedStreams = new Set<M.TimelineStream>.from(profile.streams);
    _applyStreamChanges();
    _updateRecorderUI();
  }

  Future _updateRecorderUI() async {
    // Grab the current timeline flags.
    final M.TimelineFlags flags = await _repository.getFlags(vm);
    // Grab the recorder name.
    _recorder = flags.recorder;
    // Update the set of available streams.
    _availableStreams = new Set<M.TimelineStream>.from(flags.streams);
    // Update the set of recorded streams.
    _recordedStreams = new Set<M.TimelineStream>.from(
        flags.streams.where((s) => s.isRecorded));
    // Update the set of presets.
    _profiles = new Set<M.TimelineProfile>.from(flags.profiles);
    // Refresh the UI.
    _r.dirty();
  }

  Element _makeStreamToggle(M.TimelineStream stream) {
    LabelElement label = new LabelElement();
    label.style.paddingLeft = '8px';
    SpanElement span = new SpanElement();
    span.text = stream.name;
    InputElement checkbox = new InputElement();
    checkbox.onChange.listen((_) {
      if (checkbox.checked) {
        _recordedStreams.add(stream);
      } else {
        _recordedStreams.remove(stream);
      }
      _applyStreamChanges();
      _updateRecorderUI();
    });
    checkbox.type = 'checkbox';
    checkbox.checked = _recordedStreams.contains(stream);
    label.children.add(checkbox);
    label.children.add(span);
    return label;
  }

  Future _applyStreamChanges() {
    return _repository.setRecordedStreams(vm, _recordedStreams);
  }
}
