// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/nav_bar.dart';
import 'helpers/nav_menu.dart';
import 'helpers/rendering_scheduler.dart';
import 'helpers/uris.dart';
import 'nav/notify.dart';
import 'nav/refresh.dart';
import 'nav/top_menu.dart';
import 'nav/vm_menu.dart';

class TimelinePageElement extends CustomElement implements Renderable {
  late RenderingScheduler<TimelinePageElement> _r;

  Stream<RenderedEvent<TimelinePageElement>> get onRendered => _r.onRendered;

  late M.VM _vm;
  late M.TimelineRepository _repository;
  late M.EventRepository _events;
  late M.NotificationRepository _notifications;
  M.TimelineRecorder? _recorder;
  late Set<M.TimelineStream> _availableStreams;
  late Set<M.TimelineStream> _recordedStreams;
  late Set<M.TimelineProfile> _profiles;

  M.VM get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory TimelinePageElement(
    M.VM vm,
    M.TimelineRepository repository,
    M.EventRepository events,
    M.NotificationRepository notifications, {
    RenderingQueue? queue,
  }) {
    TimelinePageElement e = new TimelinePageElement.created();
    e._r = new RenderingScheduler<TimelinePageElement>(e, queue: queue);
    e._vm = vm;
    e._repository = repository;
    e._events = events;
    e._notifications = notifications;
    return e;
  }

  TimelinePageElement.created() : super.created('timeline-page');

  @override
  attached() {
    super.attached();
    _r.enable();
    _updateRecorderUI();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    removeChildren();
  }

  HTMLIFrameElement? _frame;
  HTMLDivElement? _content;

  bool get usingVMRecorder =>
      _recorder!.name != "Fuchsia" &&
      _recorder!.name != "Systrace" &&
      _recorder!.name != "Macos";

  void render() {
    if (_frame == null) {
      _frame = new HTMLIFrameElement()..src = 'timeline.html';
      _frame!.onLoad.listen((event) {
        _refresh();
      });
    }
    if (_content == null) {
      _content = new HTMLDivElement()..className = 'content-centered-big';
    }
    _content!.setChildren(<HTMLElement>[
      new HTMLHeadingElement.h1()..textContent = 'Timeline settings',
      _recorder == null
          ? (new HTMLDivElement()..textContent = 'Loading...')
          : (new HTMLDivElement()
              ..className = 'memberList'
              ..appendChildren(<HTMLElement>[
                new HTMLDivElement()
                  ..className = 'memberItem'
                  ..appendChildren(<HTMLElement>[
                    new HTMLDivElement()
                      ..className = 'memberName'
                      ..textContent = 'Recorder:',
                    new HTMLDivElement()
                      ..className = 'memberValue'
                      ..textContent = _recorder!.name,
                  ]),
                new HTMLDivElement()
                  ..className = 'memberItem'
                  ..appendChildren(<HTMLElement>[
                    new HTMLDivElement()
                      ..className = 'memberName'
                      ..textContent = 'Recorded Streams Profile:',
                    new HTMLDivElement()
                      ..className = 'memberValue'
                      ..appendChildren(_createProfileSelect()),
                  ]),
                new HTMLDivElement()
                  ..className = 'memberItem'
                  ..appendChildren(<HTMLElement>[
                    new HTMLDivElement()
                      ..className = 'memberName'
                      ..textContent = 'Recorded Streams:',
                    new HTMLDivElement()
                      ..className = 'memberValue'
                      ..appendChildren(
                        _availableStreams.map<HTMLElement>(_makeStreamToggle),
                      ),
                  ]),
              ])),
    ]);

    children = <HTMLElement>[
      navBar(<HTMLElement>[
        new NavTopMenuElement(queue: _r.queue).element,
        new NavVMMenuElement(vm, _events, queue: _r.queue).element,
        navMenu('timeline', link: Uris.timeline()),
        (new NavRefreshElement(queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                await _refresh();
                e.element.disabled = !usingVMRecorder;
              }))
            .element,
        (new NavRefreshElement(label: 'clear', queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                await _clear();
                e.element.disabled = !usingVMRecorder;
              }))
            .element,
        (new NavRefreshElement(label: 'save', queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                await _save();
                e.element.disabled = !usingVMRecorder;
              }))
            .element,
        (new NavRefreshElement(label: 'load', queue: _r.queue)
              ..onRefresh.listen((e) async {
                e.element.disabled = true;
                await _load();
                e.element.disabled = !usingVMRecorder;
              }))
            .element,
        new NavNotifyElement(_notifications, queue: _r.queue).element,
      ]),
      _content!,
      _createIFrameOrMessage(),
    ];
  }

  HTMLElement _createIFrameOrMessage() {
    final recorder = _recorder;
    if (recorder == null) {
      return new HTMLDivElement()
        ..className = 'content-centered-big'
        ..textContent = 'Loading...';
    }

    if (recorder.name == "Fuchsia") {
      return new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLBRElement(),
          new HTMLSpanElement()
            ..textContent =
                "This VM is forwarding timeline events to Fuchsia's system tracing. See the ",
          new HTMLAnchorElement()
            ..textContent = "Fuchsia Tracing Usage Guide"
            ..href = "https://fuchsia.dev/fuchsia-src/development/tracing",
          new HTMLSpanElement()..textContent = ".",
        ]);
    }

    if (recorder.name == "Systrace") {
      return new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLBRElement(),
          new HTMLSpanElement()
            ..textContent =
                "This VM is forwarding timeline events to Android's systrace. See the ",
          new HTMLAnchorElement()
            ..textContent = "systrace usage guide"
            ..href =
                "https://developer.android.com/studio/command-line/systrace",
          new HTMLSpanElement()..textContent = ".",
        ]);
    }

    if (recorder.name == "Macos") {
      return new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(<HTMLElement>[
          new HTMLBRElement(),
          new HTMLSpanElement()
            ..textContent =
                "This VM is forwarding timeline events to macOS's Unified Logging. "
                "To track these events, open 'Instruments' and add the 'os_signpost' Filter. See the ",
          new HTMLAnchorElement()
            ..textContent = "Instruments Usage Guide"
            ..href = "https://help.apple.com/instruments",
          new HTMLSpanElement()..textContent = ".",
        ]);
    }

    return new HTMLDivElement()
      ..className = 'iframe'
      ..appendChild(_frame!);
  }

  List<HTMLElement> _createProfileSelect() {
    return [
      new HTMLSpanElement()..appendChildren(
        _profiles
            .expand(
              (profile) => <HTMLElement>[
                new HTMLButtonElement()
                  ..textContent = profile.name
                  ..onClick.listen((_) {
                    _applyPreset(profile);
                  }),
                new HTMLSpanElement()..textContent = ' - ',
              ],
            )
            .toList()
          ..removeLast(),
      ),
    ];
  }

  Future _refresh() async {
    _postMessage('loading');
    final params = new Map<String, dynamic>.from(
      await _repository.getIFrameParams(vm),
    );
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

  Future _postMessage(
    String method, [
    Map<dynamic, dynamic> params = const <dynamic, dynamic>{},
  ]) async {
    if (_frame!.contentWindow == null) {
      return null;
    }
    var message = {'method': method, 'params': params};
    _frame!.contentWindow!.postMessage(
      json.encode(message).toJS,
      window.location.href.toJS,
    );
    return null;
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
      flags.streams.where((s) => s.isRecorded),
    );
    // Update the set of presets.
    _profiles = new Set<M.TimelineProfile>.from(flags.profiles);
    // Refresh the UI.
    _r.dirty();
  }

  HTMLElement _makeStreamToggle(M.TimelineStream stream) {
    HTMLLabelElement label = new HTMLLabelElement();
    label.style.paddingLeft = '8px';
    HTMLSpanElement span = new HTMLSpanElement();
    span.textContent = stream.name;
    HTMLInputElement checkbox = new HTMLInputElement();
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
    label
      ..appendChild(checkbox)
      ..appendChild(span);
    return label;
  }

  Future _applyStreamChanges() {
    return _repository.setRecordedStreams(vm, _recordedStreams);
  }
}
