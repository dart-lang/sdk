// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_element;

import 'dart:async';
import 'dart:html';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:polymer/polymer.dart';

/// Base class for all Observatory custom elements.
@CustomTag('observatory-element')
class ObservatoryElement extends PolymerElement {
  ObservatoryElement.created() : super.created();

  ObservatoryApplication get app => ObservatoryApplication.app;
  Page get page => app.currentPage;

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
    app.locationManager.onGoto(event);
    event.stopPropagation();
  }

  void onClickGoto(MouseEvent event) {
    app.locationManager.onGoto(event);
    event.stopPropagation();
  }

  String makeLink(String url, [ServiceObject obj]) {
    if (obj != null) {
      if (obj is Isolate) {
        url = '${url}?isolateId=${Uri.encodeComponent(obj.id)}';
      } else {
        if (obj.id == null) {
          // No id
          return url;
        }
        url = ('${url}?isolateId=${Uri.encodeComponent(obj.isolate.id)}'
                       '&objectId=${Uri.encodeComponent(obj.id)}');
      }
    }
    return url;
  }

  /// Create a link that can be consumed by [goto].
  String gotoLink(String url, [ServiceObject obj]) {
    return app.locationManager.makeLink(makeLink(url, obj));
  }
  String gotoLinkForwardingParameters(String url, [ServiceObject obj]) {
    return app.locationManager.makeLinkForwardingParameters(makeLink(url, obj));
  }

  String formatTimePrecise(double time) => Utils.formatTimePrecise(time);
  String formatTimeMilliseconds(int millis) =>
      Utils.formatTimeMilliseconds(millis);
  String formatTime(double time) => Utils.formatTime(time);

  String formatSeconds(double x) => Utils.formatSeconds(x);


  String formatSize(int bytes) => Utils.formatSize(bytes);

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

  void clearShadowRoot() {
    // Remove all non-style elements.
    // Have to do the following because removeWhere doesn't work on DOM child
    // node lists. i.e. removeWhere((e) => e is! StyleElement);
    var styleElements = [];
    for (var child in shadowRoot.children) {
      if (child is StyleElement) {
        styleElements.add(child);
      }
    }
    shadowRoot.children.clear();
    for (var style in styleElements) {
      shadowRoot.children.add(style);
    }
  }

  void insertTextSpanIntoShadowRoot(String text) {
    var spanElement = new SpanElement();
    spanElement.text = text;
    shadowRoot.children.add(spanElement);
  }

  void insertLinkIntoShadowRoot(String label, String href, [String title]) {
    var anchorElement = new AnchorElement();
    anchorElement.href = href;
    anchorElement.text = label;
    if (title != null) {
      anchorElement.title = title;
    }
    anchorElement.onClick.listen(onClickGoto);
    shadowRoot.children.add(anchorElement);
  }


  var _onCopySubscription;
  /// Exclude nodes from being copied, for example the line numbers and
  /// breakpoint toggles in script insets. Must be called after [root]'s
  /// children have been added, and only supports one node at a time.
  void makeCssClassUncopyable(Element root, String className) {
    var noCopyNodes = root.getElementsByClassName(className);
    for (var node in noCopyNodes) {
      node.style.setProperty('-moz-user-select', 'none');
      node.style.setProperty('-khtml-user-select', 'none');
      node.style.setProperty('-webkit-user-select', 'none');
      node.style.setProperty('-ms-user-select', 'none');
      node.style.setProperty('user-select', 'none');
    }
    if (_onCopySubscription != null) {
      _onCopySubscription.cancel();
    }
    _onCopySubscription = root.onCopy.listen((event) {
      // Mark the nodes as hidden before the copy happens, then mark them as
      // visible on the next event loop turn.
      for (var node in noCopyNodes) {
        node.style.visibility = 'hidden';
      }
      Timer.run(() {
        for (var node in noCopyNodes) {
          node.style.visibility = 'visible';
        }
      });
    });
  }
}
