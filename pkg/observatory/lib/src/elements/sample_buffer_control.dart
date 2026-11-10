// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../../models.dart' as M;
import 'helpers/custom_element.dart';
import 'helpers/element_utils.dart';
import 'helpers/rendering_scheduler.dart';
import '../../utils.dart';

class SampleBufferControlChangedElement {
  final SampleBufferControlElement element;
  SampleBufferControlChangedElement(this.element);
}

class SampleBufferControlElement extends CustomElement implements Renderable {
  late RenderingScheduler<SampleBufferControlElement> _r;

  Stream<RenderedEvent<SampleBufferControlElement>> get onRendered =>
      _r.onRendered;

  StreamController<SampleBufferControlChangedElement> _onTagChange =
      new StreamController<SampleBufferControlChangedElement>.broadcast();
  Stream<SampleBufferControlChangedElement> get onTagChange =>
      _onTagChange.stream;

  late M.VM _vm;
  late Stream<M.SampleProfileLoadingProgressEvent> _progressStream;
  late M.SampleProfileLoadingProgress _progress;
  late M.SampleProfileTag _tag;
  bool _showTag = false;
  bool _profileVM = false;
  late StreamSubscription _subscription;

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
    Stream<M.SampleProfileLoadingProgressEvent> progressStream, {
    M.SampleProfileTag selectedTag = M.SampleProfileTag.none,
    bool showTag = true,
    RenderingQueue? queue,
  }) {
    SampleBufferControlElement e = new SampleBufferControlElement.created();
    e._r = new RenderingScheduler<SampleBufferControlElement>(e, queue: queue);
    e._vm = vm;
    e._progress = progress;
    e._progressStream = progressStream;
    e._tag = selectedTag;
    e._showTag = showTag;
    return e;
  }

  SampleBufferControlElement.created() : super.created('sample-buffer-control');

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
    var content = <HTMLElement>[
      new HTMLHeadingElement.h2()..textContent = 'Sample buffer',
      new HTMLHRElement(),
    ];
    switch (_progress.status) {
      case M.SampleProfileLoadingStatus.fetching:
        content.addAll(_createStatusMessage('Fetching profile from VM...'));
        break;
      case M.SampleProfileLoadingStatus.loading:
        content.addAll(
          _createStatusMessage(
            'Loading profile...',
            progress: _progress.progress,
          ),
        );
        break;
      case M.SampleProfileLoadingStatus.disabled:
        content.addAll(_createDisabledMessage());
        break;
      case M.SampleProfileLoadingStatus.loaded:
        content.addAll(_createStatusReport());
        break;
    }
    children = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'content-centered-big'
        ..appendChildren(content),
    ];
  }

  static List<HTMLElement> _createStatusMessage(
    String message, {
    double progress = 0.0,
  }) {
    return [
      new HTMLDivElement()
        ..className = 'statusBox shadow center'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'statusMessage'
            ..textContent = message,
          new HTMLDivElement()
            ..style.background = '#0489c3'
            ..style.width = '$progress%'
            ..style.height = '15px'
            ..style.borderRadius = '4px',
        ]),
    ];
  }

  List<HTMLElement> _createDisabledMessage() {
    return [
      new HTMLDivElement()
        ..className =
            'statusBox'
            'shadow'
            'center'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()..appendChildren(<HTMLElement>[
            new HTMLHeadingElement.h1()..textContent = 'Profiling is disabled',
            new HTMLBRElement(),
            new HTMLDivElement()
              ..innerHTML =
                  'Perhaps the <b>profile</b> '
                          'flag has been disabled for this VM.'
                      .toJS,
            new HTMLBRElement(),
            new HTMLButtonElement()
              ..textContent = 'Enable profiler'
              ..onClick.listen((_) {
                _enableProfiler();
              }),
          ]),
        ]),
    ];
  }

  List<HTMLElement> _createStatusReport() {
    final fetchT = Utils.formatDurationInSeconds(_progress.fetchingTime);
    final loadT = Utils.formatDurationInSeconds(_progress.loadingTime);
    final sampleCount = _progress.profile.sampleCount;
    final refreshT = new DateTime.now();
    final maxStackDepth = _progress.profile.maxStackDepth;
    final sampleRate = _progress.profile.sampleRate.toStringAsFixed(0);
    final timeSpan = _progress.profile.sampleCount == 0
        ? '0s'
        : Utils.formatTimePrecise(_progress.profile.timeSpan);

    var content = <HTMLElement>[
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'Refreshed at',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent =
                '$refreshT (fetched in ${fetchT}s) (loaded in ${loadT}s)',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'Profile contains ',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = '$sampleCount samples (spanning $timeSpan)',
        ]),
      new HTMLDivElement()
        ..className = 'memberItem'
        ..appendChildren(<HTMLElement>[
          new HTMLDivElement()
            ..className = 'memberName'
            ..textContent = 'Sampling',
          new HTMLDivElement()
            ..className = 'memberValue'
            ..textContent = '$maxStackDepth stack frames @ ${sampleRate}Hz',
        ]),
    ];
    if (_showTag) {
      content.add(
        new HTMLDivElement()
          ..className = 'memberItem'
          ..appendChildren(<HTMLElement>[
            new HTMLDivElement()
              ..className = 'memberName'
              ..textContent = 'Tag Order',
            new HTMLDivElement()
              ..className = 'memberValue'
              ..appendChildren(_createTagSelect()),
          ]),
      );
    }
    return [
      new HTMLDivElement()
        ..className = 'memberList'
        ..appendChildren(content),
    ];
  }

  List<HTMLElement> _createTagSelect() {
    var values = M.SampleProfileTag.values;
    if (!_profileVM) {
      values = const [
        M.SampleProfileTag.userOnly,
        M.SampleProfileTag.vmOnly,
        M.SampleProfileTag.none,
      ];
    }
    final s = HTMLSelectElement()
      ..className = 'tag-select'
      ..value = tagToString(_tag)
      ..appendChildren(
        values.map(
          (tag) => HTMLOptionElement()
            ..value = tagToString(tag)
            ..selected = _tag == tag
            ..textContent = tagToString(tag),
        ),
      );
    s
      ..onChange.listen((_) {
        _tag = values[s.selectedIndex];
      })
      ..onChange.map(_toEvent).listen(_triggerModeChange);
    return [s];
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
