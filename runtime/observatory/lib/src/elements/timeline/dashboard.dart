// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This page is not directly reachable from the main Observatory ui.
/// It is mainly mented to be used from editors as an integrated tool.
///
/// This page mainly targeting developers and not VM experts, so concepts like
/// timeline streams are hidden away.
///
/// The page exposes two views over the timeline data.
/// Both of them are filtered based on the optional argument `mode`.
/// See [_TimelineView] for the explanation of the two possible values.

import 'dart:async';
import 'dart:html';
import 'dart:convert';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/nav_bar.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/nav/notify.dart';

/// The two possible views are available.
/// * `string`
///   The events are just filtered by `mode` and maintain their original
///   timestamp.
/// * `frame`
///   The events are organized by frame.
///   The events are shifted in order to give a high level view of the
///   computation involved in a frame.
///   The frame are concatenated one after the other taking care of not
///   overlapping the related events.
enum _TimelineView { strict, frame }

class TimelineDashboardElement extends HtmlElement implements Renderable {
  static const tag = const Tag<TimelineDashboardElement>('timeline-dashboard',
      dependencies: const [NavNotifyElement.tag]);

  RenderingScheduler<TimelineDashboardElement> _r;

  Stream<RenderedEvent<TimelineDashboardElement>> get onRendered =>
      _r.onRendered;

  M.VM _vm;
  M.TimelineRepository _repository;
  M.NotificationRepository _notifications;
  M.TimelineFlags _flags;
  _TimelineView _view = _TimelineView.strict;

  M.VM get vm => _vm;
  M.NotificationRepository get notifications => _notifications;

  factory TimelineDashboardElement(M.VM vm, M.TimelineRepository repository,
      M.NotificationRepository notifications,
      {RenderingQueue queue}) {
    assert(vm != null);
    assert(repository != null);
    assert(notifications != null);
    TimelineDashboardElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._repository = repository;
    e._notifications = notifications;
    if (vm.embedder == 'Flutter') {
      e._view = _TimelineView.frame;
    }
    return e;
  }

  TimelineDashboardElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
    _refresh();
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
      _frame = new IFrameElement();
    }
    if (_content == null) {
      _content = new DivElement()..classes = ['content-centered-big'];
    }
    _frame.src = _makeFrameUrl();
    _content.children = [
      new HeadingElement.h1()
        ..children = ([new Text("Timeline")]
          ..addAll(_createButtons())
          ..addAll(_createTabs())),
      new Text(_view == _TimelineView.frame
          ? 'Logical view of the computation involved in each frame. '
              '(Timestamps may not be preserved)'
          : 'Sequence of events generated during the execution. '
          '(Timestamps are preserved)')
    ];
    if (children.isEmpty) {
      children = [
        navBar([new NavNotifyElement(_notifications, queue: _r.queue)]),
        _content,
        new DivElement()
          ..classes = ['iframe']
          ..children = [_frame]
      ];
    }
  }

  List<Element> _createButtons() {
    if (_flags == null) {
      return [new Text('Loading')];
    }
    if (_suggestedProfile(_flags.profiles).streams.any((s) => !s.isRecorded)) {
      return [
        new ButtonElement()
          ..classes = ['header_button']
          ..text = 'Enable'
          ..title = 'The Timeline is not fully enabled, click to enable'
          ..onClick.listen((e) => _enable()),
        new ButtonElement()
          ..classes = ['header_button']
          ..text = ' 📂 Load'
          ..title = 'Load a saved timeline from file'
          ..onClick.listen((e) => _load()),
      ];
    }
    return [
      new ButtonElement()
        ..classes = ['header_button']
        ..text = ' ↺ Refresh'
        ..title = 'Refresh the current timeline'
        ..onClick.listen((e) => _refresh()),
      new ButtonElement()
        ..classes = ['header_button']
        ..text = ' ❌ Clear'
        ..title = 'Clear the current Timeline to file'
        ..onClick.listen((e) => _clear()),
      new ButtonElement()
        ..classes = ['header_button']
        ..text = ' 💾 Save'
        ..title = 'Save the current Timeline to file'
        ..onClick.listen((e) => _save()),
      new ButtonElement()
        ..classes = ['header_button']
        ..text = ' 📂 Load'
        ..title = 'Load a saved timeline from file'
        ..onClick.listen((e) => _load()),
    ];
  }

  List<Element> _createTabs() {
    if (_vm.embedder != 'Flutter') {
      return const [];
    }
    return [
      new SpanElement()
        ..classes = ['tab_buttons']
        ..children = [
          new ButtonElement()
            ..text = 'Frame View'
            ..title = 'Logical view of the computation involved in each frame\n'
                'Timestamps may not be preserved'
            ..disabled = _view == _TimelineView.frame
            ..onClick.listen((_) {
              _view = _TimelineView.frame;
              _r.dirty();
            }),
          new ButtonElement()
            ..text = 'Time View'
            ..title = 'Sequence of events generated during the execution\n'
                'Timestamps are preserved'
            ..disabled = _view == _TimelineView.strict
            ..onClick.listen((_) {
              _view = _TimelineView.strict;
              _r.dirty();
            }),
        ]
    ];
  }

  String _makeFrameUrl() {
    final String mode = 'basic';
    final String view = _view == _TimelineView.frame ? 'frame' : 'strict';
    return 'timeline.html#mode=$mode&view=$view';
  }

  M.TimelineProfile _suggestedProfile(Iterable<M.TimelineProfile> profiles) {
    return profiles
        .where((profile) => profile.name == 'Flutter Developer')
        .single;
  }

  Future _enable() async {
    await _repository.setRecordedStreams(
        vm, _suggestedProfile(_flags.profiles).streams);
    _refresh();
  }

  Future _refresh() async {
    _flags = await _repository.getFlags(vm);
    _r.dirty();
    final params = new Map.from(await _repository.getIFrameParams(vm));
    return _postMessage('refresh', params);
  }

  Future _clear() async {
    await _repository.clear(_vm);
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
        .postMessage(json.encode(message), window.location.href);
    return null;
  }
}
