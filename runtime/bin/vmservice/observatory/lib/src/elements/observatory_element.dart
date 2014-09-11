// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

/// Base class for all Observatory custom elements.
@CustomTag('observatory-element')
class ObservatoryElement extends PolymerElement {
  ObservatoryElement.created() : super.created();

  ObservatoryApplication get app => ObservatoryApplication.app;
  Page get page => app.currentPage;
  ObservableMap get args => page.args;

  @override
  void attached() {
    super.attached();
    _startPoll();
  }

  @override
  void attributeChanged(String name, var oldValue, var newValue) {
    super.attributeChanged(name, oldValue, newValue);
  }

  @override
  void detached() {
    super.detached();
    _stopPoll();
  }

  @override
  void ready() {
    super.ready();
  }

  /// Set to a non-null value to enable polling on this element. When the poll
  /// timer fires, onPoll will be called.
  @observable Duration pollPeriod;
  Timer _pollTimer;

  /// Called every [pollPeriod] while the element is attached to the DOM.
  void onPoll() { }

  void pollPeriodChanged(oldValue) {
    if (pollPeriod != null) {
      _startPoll();
    } else {
      _stopPoll();
    }
  }

  void _startPoll() {
    if (pollPeriod == null) {
      return;
    }
    if (_pollTimer != null) {
      _pollTimer.cancel();
    }
    _pollTimer = new Timer(pollPeriod, _onPoll);
  }

  void _stopPoll() {
    if (_pollTimer != null) {
      _pollTimer.cancel();
    }
    _pollTimer = null;
  }

  void _onPoll() {
    onPoll();
    if (pollPeriod == null) {
      // Stop polling.
      _stopPoll();
      return;
    }
    // Restart timer.
    _pollTimer = new Timer(pollPeriod, _onPoll);
  }

  /// Utility method for handling on-click of <a> tags. Navigates
  /// within the application using the [LocationManager].
  void goto(MouseEvent event, var detail, Element target) {
    app.locationManager.onGoto(event, detail, target);
  }

  /// Create a link that can be consumed by [goto].
  String gotoLink(String url) {
    return app.locationManager.makeLink(url);
  }

  String formatTimePrecise(double time) => Utils.formatTimePrecise(time);

  String formatTime(double time) => Utils.formatTime(time);

  String formatSeconds(double x) => Utils.formatSeconds(x);


  String formatSize(int bytes) => Utils.formatSize(bytes);

  String fileAndLine(Map frame) {
    var file = frame['script'].name;
    var shortFile = file.substring(file.lastIndexOf('/') + 1);
    return "${shortFile}:${frame['line']}";
  }

  int parseInt(String value) => int.parse(value);

  String asStringLiteral(String value, [bool wasTruncated=false]) {
    var result = new List();
    result.add("'".codeUnitAt(0));
    for (int codeUnit in value.codeUnits) {
      if (codeUnit == '\n'.codeUnitAt(0)) result.addAll('\\n'.codeUnits);
      else if (codeUnit == '\r'.codeUnitAt(0)) result.addAll('\\r'.codeUnits);
      else if (codeUnit == '\f'.codeUnitAt(0)) result.addAll('\\f'.codeUnits);
      else if (codeUnit == '\b'.codeUnitAt(0)) result.addAll('\\b'.codeUnits);
      else if (codeUnit == '\t'.codeUnitAt(0)) result.addAll('\\t'.codeUnits);
      else if (codeUnit == '\v'.codeUnitAt(0)) result.addAll('\\v'.codeUnits);
      else if (codeUnit == '\$'.codeUnitAt(0)) result.addAll('\\\$'.codeUnits);
      else if (codeUnit == '\\'.codeUnitAt(0)) result.addAll('\\\\'.codeUnits);
      else if (codeUnit == "'".codeUnitAt(0)) result.addAll("'".codeUnits);
      else if (codeUnit < 32) {
         var escapeSequence = "\\u" + codeUnit.toRadixString(16).padLeft(4, "0");
         result.addAll(escapeSequence.codeUnits);
      } else result.add(codeUnit);
    }
    if (wasTruncated) {
      result.addAll("...".codeUnits);
    } else {
      result.add("'".codeUnitAt(0));
    }
    return new String.fromCharCodes(result);
  }
}
