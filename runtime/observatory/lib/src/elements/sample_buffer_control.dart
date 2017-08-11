// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/utils.dart';

class SampleBufferControlChangedElement {
  final SampleBufferControlElement element;
  SampleBufferControlChangedElement(this.element);
}

class SampleBufferControlElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<SampleBufferControlElement>('sample-buffer-control');

  RenderingScheduler<SampleBufferControlElement> _r;

  Stream<RenderedEvent<SampleBufferControlElement>> get onRendered =>
      _r.onRendered;

  StreamController<SampleBufferControlChangedElement> _onTagChange =
      new StreamController<SampleBufferControlChangedElement>.broadcast();
  Stream<SampleBufferControlChangedElement> get onTagChange =>
      _onTagChange.stream;

  M.VM _vm;
  Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  M.SampleProfileLoadingProgress _progress;
  M.SampleProfileTag _tag;
  bool _showTag = false;
  bool _profileVM = false;
  StreamSubscription _subscription;

  M.SampleProfileLoadingProgress get progress => _progress;
  M.SampleProfileTag get selectedTag => _tag;
  bool get showTag => _showTag;
  bool get profileVM => _profileVM;

  set selectedTag(M.SampleProfileTag value) =>
      _tag = _r.checkAndReact(_tag, value);
  set showTag(bool value) => _showTag = _r.checkAndReact(_showTag, value);
  set profileVM(bool value) => _profileVM = _r.checkAndReact(_profileVM, value);

  factory SampleBufferControlElement(
      M.VM vm,
      M.SampleProfileLoadingProgress progress,
      Stream<M.SampleProfileLoadingProgressEvent> progressStream,
      {M.SampleProfileTag selectedTag: M.SampleProfileTag.none,
      bool showTag: true,
      RenderingQueue queue}) {
    assert(progress != null);
    assert(progressStream != null);
    assert(selectedTag != null);
    assert(showTag != null);
    SampleBufferControlElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._vm = vm;
    e._progress = progress;
    e._progressStream = progressStream;
    e._tag = selectedTag;
    e._showTag = showTag;
    return e;
  }

  SampleBufferControlElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
    _subscription = _progressStream.listen((e) {
      _progress = e.progress;
      _r.dirty();
    });
  }

  @override
  void detached() {
    super.detached();
    _r.disable(notify: true);
    children = const [];
    _subscription.cancel();
  }

  void render() {
    var content = <Element>[
      new HeadingElement.h2()..text = 'Sample buffer',
      new HRElement()
    ];
    switch (_progress.status) {
      case M.SampleProfileLoadingStatus.fetching:
        content.addAll(_createStatusMessage('Fetching profile from VM...'));
        break;
      case M.SampleProfileLoadingStatus.loading:
        content.addAll(_createStatusMessage('Loading profile...',
            progress: _progress.progress));
        break;
      case M.SampleProfileLoadingStatus.disabled:
        content.addAll(_createDisabledMessage());
        break;
      case M.SampleProfileLoadingStatus.loaded:
        content.addAll(_createStatusReport());
        break;
    }
    children = [
      new DivElement()
        ..classes = ['content-centered-big']
        ..children = content
    ];
  }

  static List<Element> _createStatusMessage(String message,
      {double progress: 0.0}) {
    return [
      new DivElement()
        ..classes = ['statusBox', 'shadow', 'center']
        ..children = [
          new DivElement()
            ..classes = ['statusMessage']
            ..text = message,
          new DivElement()
            ..style.background = '#0489c3'
            ..style.width = '$progress%'
            ..style.height = '15px'
            ..style.borderRadius = '4px'
        ]
    ];
  }

  List<Element> _createDisabledMessage() {
    return [
      new DivElement()
        ..classes = ['statusBox' 'shadow' 'center']
        ..children = [
          new DivElement()
            ..children = [
              new HeadingElement.h1()..text = 'Profiling is disabled',
              new BRElement(),
              new DivElement()
                ..innerHtml = 'Perhaps the <b>profile</b> '
                    'flag has been disabled for this VM.',
              new BRElement(),
              new ButtonElement()
                ..text = 'Enable profiler'
                ..onClick.listen((_) {
                  _enableProfiler();
                })
            ]
        ]
    ];
  }

  List<Element> _createStatusReport() {
    final fetchT = Utils.formatDurationInSeconds(_progress.fetchingTime);
    final loadT = Utils.formatDurationInSeconds(_progress.loadingTime);
    final sampleCount = _progress.profile.sampleCount;
    final refreshT = new DateTime.now();
    final stackDepth = _progress.profile.stackDepth;
    final sampleRate = _progress.profile.sampleRate.toStringAsFixed(0);
    final timeSpan = _progress.profile.sampleCount == 0
        ? '0s'
        : Utils.formatTimePrecise(_progress.profile.timeSpan);

    var content = <Element>[
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Refreshed at',
          new DivElement()
            ..classes = ['memberValue']
            ..text = '$refreshT (fetched in ${fetchT}s) (loaded in ${loadT}s)'
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Profile contains ',
          new DivElement()
            ..classes = ['memberValue']
            ..text = '$sampleCount samples (spanning $timeSpan)'
        ],
      new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Sampling',
          new DivElement()
            ..classes = ['memberValue']
            ..text = '$stackDepth stack frames @ ${sampleRate}Hz'
        ],
    ];
    if (_showTag) {
      content.add(new DivElement()
        ..classes = ['memberItem']
        ..children = [
          new DivElement()
            ..classes = ['memberName']
            ..text = 'Tag Order',
          new DivElement()
            ..classes = ['memberValue']
            ..children = _createTagSelect()
        ]);
    }
    return [
      new DivElement()
        ..classes = ['memberList']
        ..children = content
    ];
  }

  List<Element> _createTagSelect() {
    var values = M.SampleProfileTag.values;
    if (!_profileVM) {
      values = const [M.SampleProfileTag.userOnly, M.SampleProfileTag.none];
    }
    var s;
    return [
      s = new SelectElement()
        ..classes = ['tag-select']
        ..value = tagToString(_tag)
        ..children = values.map((tag) {
          return new OptionElement(
              value: tagToString(tag), selected: _tag == tag)
            ..text = tagToString(tag);
        }).toList(growable: false)
        ..onChange.listen((_) {
          _tag = values[s.selectedIndex];
        })
        ..onChange.map(_toEvent).listen(_triggerModeChange),
    ];
  }

  static String tagToString(M.SampleProfileTag tag) {
    switch (tag) {
      case M.SampleProfileTag.userVM:
        return 'User > VM';
      case M.SampleProfileTag.userOnly:
        return 'User';
      case M.SampleProfileTag.vmUser:
        return 'VM > User';
      case M.SampleProfileTag.vmOnly:
        return 'VM';
      case M.SampleProfileTag.none:
        return 'None';
    }
    throw new Exception('Unknown tagToString');
  }

  SampleBufferControlChangedElement _toEvent(_) {
    return new SampleBufferControlChangedElement(this);
  }

  void _enableProfiler() {
    _vm.enableProfiler().then((_) {
      _triggerModeChange(_toEvent(null));
    });
  }

  void _triggerModeChange(e) => _onTagChange.add(e);
}
