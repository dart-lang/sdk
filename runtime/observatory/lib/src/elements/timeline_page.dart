// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timeline_page_element;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/service_html.dart';
import 'package:polymer/polymer.dart';


@CustomTag('timeline-page')
class TimelinePageElement extends ObservatoryElement {
  TimelinePageElement.created() : super.created() {
  }

  attached() {
    super.attached();
    _resizeSubscription = window.onResize.listen((_) => _updateSize());
    _updateSize();
    _setupInitialState();
  }

  detached() {
    super.detached();
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
    }
  }

  Future postMessage(String method) {
    IFrameElement e = $['root'];
    var isolateIds = new List();
    for (var isolate in app.vm.isolates) {
      isolateIds.add(isolate.id);
    }
    var message = {
      'method': method,
      'params': {
        'vmAddress': (app.vm as WebSocketVM).target.networkAddress,
        'isolateIds': isolateIds
      }
    };
    e.contentWindow.postMessage(JSON.encode(message), window.location.href);
    return null;
  }

  void _processFlags(ServiceMap response) {
    // Grab the recorder name.
    recorderName = response['recorderName'];
    // Update the set of available streams.
    _availableStreams.clear();
    response['availableStreams'].forEach(
        (String streamName) => _availableStreams.add(streamName));
    // Update the set of recorded streams.
    _recordedStreams.clear();
    response['recordedStreams'].forEach(
        (String streamName) => _recordedStreams.add(streamName));
  }

  Future _applyStreamChanges() {
    return app.vm.invokeRpc('_setVMTimelineFlags', {
      'recordedStreams': '[${_recordedStreams.join(', ')}]',
    });
  }

  HtmlElement _makeStreamToggle(String streamName) {
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

  void _refreshRecorderUI() {
    DivElement e = $['streamList'];
    e.children.clear();

    for (String streamName in _availableStreams) {
      e.children.add(_makeStreamToggle(streamName));
    }

    streamPresetSelector = streamPresetFromRecordedStreams();
  }

  // Dart developers care about the following streams:
  List<String> _dartPreset =
      ['GC', 'Compiler', 'Dart'];

  // VM developers care about the following streams:
  List<String> _vmPreset =
      ['GC', 'Compiler', 'Dart', 'Debugger', 'Embedder', 'Isolate', 'VM'];

  String streamPresetFromRecordedStreams() {
    if (_availableStreams.length == 0) {
      return 'None';
    }
    if (_recordedStreams.length == 0) {
      return 'None';
    }
    if (_recordedStreams.length == _availableStreams.length) {
      return 'All';
    }
    if ((_vmPreset.length == _recordedStreams.length) &&
        _recordedStreams.containsAll(_vmPreset)) {
      return 'VM';
    }
    if ((_dartPreset.length == _recordedStreams.length) &&
        _recordedStreams.containsAll(_dartPreset)) {
      return 'Dart';
    }
    return 'Custom';
  }

  void _applyPreset() {
    switch (streamPresetSelector) {
      case 'None':
        _recordedStreams.clear();
        break;
      case 'All':
        _recordedStreams.clear();
        _recordedStreams.addAll(_availableStreams);
        break;
      case 'VM':
        _recordedStreams.clear();
        _recordedStreams.addAll(_vmPreset);
        break;
      case 'Dart':
        _recordedStreams.clear();
        _recordedStreams.addAll(_dartPreset);
        break;
      case 'Custom':
        return;
    }
    _applyStreamChanges();
    _updateRecorderUI();
  }

  Future _updateRecorderUI() async {
    // Grab the current timeline flags.
    ServiceMap response = await app.vm.invokeRpc('_getVMTimelineFlags', {});
    assert(response['type'] == 'TimelineFlags');
    // Process them so we know available streams.
    _processFlags(response);
    // Refresh the UI.
    _refreshRecorderUI();
  }

  Future _setupInitialState() async {
    await _updateRecorderUI();
    SelectElement e = $['selectPreset'];
    e.onChange.listen((_) {
      _applyPreset();
    });
    // Finally, trigger a reload so we start with the latest timeline.
    await refresh();
  }

  Future refresh() async {
    await app.vm.reload();
    await app.vm.reloadIsolates();
    return postMessage('refresh');
  }

  Future clear() async {
    await app.vm.invokeRpc('_clearVMTimeline', {});
    return postMessage('clear');
  }

  Future saveTimeline() async {
    return postMessage('save');
  }

  Future loadTimeline() async {
    return postMessage('load');
  }

  _updateSize() {
    IFrameElement e = $['root'];
    final totalHeight = window.innerHeight;
    final top = e.offset.top;
    final bottomMargin = 32;
    final mainHeight = totalHeight - top - bottomMargin;
    e.style.setProperty('height', '${mainHeight}px');
    e.style.setProperty('width', '100%');
  }


  StreamSubscription _resizeSubscription;
  @observable String recorderName;
  @observable String streamPresetSelector = 'None';
  final Set<String> _availableStreams = new Set<String>();
  final Set<String> _recordedStreams = new Set<String>();
}
