// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library logging_page;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/utils.dart';
import 'package:polymer/polymer.dart';

@CustomTag('logging-page')
class LoggingPageElement extends ObservatoryElement {
  static const _kPageSelector = '#page';
  static const _kLogSelector = '#log';
  static const _kSeverityLevelSelector = '#severityLevelSelector';

  LoggingPageElement.created() : super.created();

  domReady() {
    super.domReady();
    _insertLevels();
  }

  attached() {
    super.attached();
    _sub();
    _resizeSubscription = window.onResize.listen((_) => _updatePageHeight());
    _updatePageHeight();
    // Turn on the periodic poll timer for this page.
    pollPeriod = const Duration(milliseconds:100);
  }

  detached() {
    super.detached();
    if (_resizeSubscription != null) {
      _resizeSubscription.cancel();
      _resizeSubscription = null;
    }
    _unsub();
  }

  void onPoll() {
    _flushPendingLogs();
  }

  _updatePageHeight() {
    HtmlElement e = shadowRoot.querySelector(_kPageSelector);
    final totalHeight = window.innerHeight;
    final top = e.offset.top;
    final bottomMargin = 32;
    final mainHeight = totalHeight - top - bottomMargin;
    e.style.setProperty('height', '${mainHeight}px');
  }

  _insertLevels() {
    SelectElement severityLevelSelector =
        shadowRoot.querySelector(_kSeverityLevelSelector);
    severityLevelSelector.children.clear();
    _maxLevelLabelLength = 0;
    for (var level in Level.LEVELS) {
      var option = new OptionElement();
      option.value = level.value.toString();
      option.label = level.name;
      if (level.name.length > _maxLevelLabelLength) {
        _maxLevelLabelLength = level.name.length;
      }
      severityLevelSelector.children.add(option);
    }
    severityLevelSelector.selectedIndex = 0;
    severityLevel = Level.ALL.value.toString();
  }

  _reset() {
    logRecords.clear();
    _unsub();
    _sub();
    _renderFull();
  }

  _unsub() {
    cancelFutureSubscription(_loggingSubscriptionFuture);
    _loggingSubscriptionFuture = null;
  }

  _sub() {
    if (_loggingSubscriptionFuture != null) {
      // Already subscribed.
      return;
    }
    _loggingSubscriptionFuture =
        app.vm.listenEventStream(Isolate.kLoggingStream, _onEvent);
  }

  _append(Map logRecord) {
    logRecords.add(logRecord);
    if (_shouldDisplay(logRecord)) {
      // Queue for display.
      pendingLogRecords.add(logRecord);
    }
  }

  Element _renderAppend(Map logRecord) {
    DivElement logContainer = shadowRoot.querySelector(_kLogSelector);
    var element = new DivElement();
    element.classes.add('logItem');
    element.classes.add(logRecord['level'].name);
    element.appendText(
        '${logRecord["level"].name.padLeft(_maxLevelLabelLength)} '
        '${Utils.formatDateTime(logRecord["time"])} '
        '${logRecord["message"].valueAsString}\n');
    logContainer.children.add(element);
    return element;
  }

  _renderFull() {
    DivElement logContainer = shadowRoot.querySelector(_kLogSelector);
    logContainer.children.clear();
    pendingLogRecords.clear();
    for (var logRecord in logRecords) {
      if (_shouldDisplay(logRecord)) {
        _renderAppend(logRecord);
      }
    }
    _scrollToBottom(logContainer);
  }

  /// Is [container] scrolled to the within [threshold] pixels of the bottom?
  static bool _isScrolledToBottom(DivElement container, [int threshold = 2]) {
    if (container == null) {
      return false;
    }
    // scrollHeight -> complete height of element including scrollable area.
    // clientHeight -> height of element on page.
    // scrollTop -> how far is an element scrolled (from 0 to scrollHeight).
    final distanceFromBottom =
        container.scrollHeight - container.clientHeight - container.scrollTop;
    const threshold = 2;  // 2 pixel slop.
    return distanceFromBottom <= threshold;
  }

  /// Scroll [container] so the bottom content is visible.
  static _scrollToBottom(DivElement container) {
    if (container == null) {
      return;
    }
    // Adjust scroll so that the bottom of the content is visible.
    container.scrollTop = container.scrollHeight - container.clientHeight;
  }

  _flushPendingLogs() {
    DivElement logContainer = shadowRoot.querySelector(_kLogSelector);
    bool autoScroll = _isScrolledToBottom(logContainer);
    var lastElement;
    for (var logRecord in pendingLogRecords) {
      lastElement = _renderAppend(logRecord);
    }
    if (autoScroll) {
      _scrollToBottom(logContainer);
    }
    pendingLogRecords.clear();
  }

  _onEvent(ServiceEvent event) {
    assert(event.kind == Isolate.kLoggingStream);
    _append(event.logRecord);
  }

  void isolateChanged(oldValue) {
    _reset();
  }

  void severityLevelChanged(oldValue) {
    _severityLevelValue = int.parse(severityLevel);
    _renderFull();
  }

  Future clear() {
    logRecords.clear();
    pendingLogRecords.clear();
    _renderFull();
    return new Future.value(null);
  }

  bool _shouldDisplay(Map logRecord) {
    return logRecord['level'].value >= _severityLevelValue;
  }

  @observable Isolate isolate;
  @observable String severityLevel;
  int _severityLevelValue = 0;
  int _maxLevelLabelLength = 0;
  Future<StreamSubscription> _loggingSubscriptionFuture;
  StreamSubscription _resizeSubscription;
  final List<Map> logRecords = new List<Map>();
  final List<Map> pendingLogRecords = new List<Map>();
}
