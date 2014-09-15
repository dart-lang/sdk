// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

abstract class LocationManager extends Observable {
  final _initialPath = '/vm';
  ObservatoryApplication _app;

  String _lastUrl;

  void _init(ObservatoryApplication app) {
    // Called once.
    assert(_app == null);
    _app = app;
    // Register for history events.
    window.onPopState.listen(_onLocationChange);
    _onStartup();
  }

  void _onStartup();
  void _onLocationChange(PopStateEvent event);

  void _pushUrl(String url) {
    if (_lastUrl != url) {
      Logger.root.info('Navigated to ${url}');
      window.history.pushState(url, document.title, url);
      _lastUrl = url;
    }
  }

  /// Go to a specific url.
  void go(String url) {
    if (_app.vm == null) {
      if (!window.confirm('Connection with VM has been lost. '
                          'Proceeding will lose current page.')) {
        return;
      }
      url = makeLink('/vm-connect/');
    }
    _pushUrl(url);
    _go(url);
  }

  void _go(String url) {
    // Chop off leading '#'.
    if (url.startsWith('#')) {
      url = url.substring(1);
    }
    // Fall through handles '#/'
    // Chop off leading '/'.
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    var args;
    // Parse out arguments.
    if (url.contains('---')) {
      var chunks = url.split('---');
      url = chunks[0];
      if ((chunks.length > 1) && (chunks[1] != '')) {
        args = chunks[1];
      }
    }
    _app._visit(url, args);
  }

  /// Go back.
  void back() {
    window.history.go(-1);
  }

  /// Go forward.
  void forward() {
    window.history.go(1);
  }

  /// Handle clicking on an application url link.
  void onGoto(MouseEvent event, var detail, Element target) {
    var href = target.attributes['href'];
    if (event.button > 0 || event.metaKey || event.ctrlKey ||
        event.shiftKey || event.altKey) {
      // Not a left-click or a left-click with a modifier key:
      // Let browser handle.
      return;
    }
    go(href);
    event.preventDefault();
  }

  /// Given an application url, generate a link.
  String makeLink(String url);
}

/// Uses location.hash to encode application urls.
class HashLocationManager extends LocationManager {
  void _onStartup() {
    String initialPath = '${window.location.hash}';
    if ((window.location.hash == '') || (window.location.hash == '#')) {
      initialPath = '#${_initialPath}';
    }
    window.history.pushState(initialPath, document.title, initialPath);
    _go(window.location.hash);
  }

  void _onLocationChange(PopStateEvent _) {
    _go(window.location.hash);
  }

  /// Given an application url, generate a link for an anchor tag.
  String makeLink(String url) {
    return '#$url';
  }
}

/// Uses location.pathname to encode application urls. Requires server side
/// rewriting to support copy and paste linking. pub serve makes this hard.
/// STATUS: Work in progress.
class LinkLocationManager extends LocationManager {
  void _onStartup() {
    Logger.root.warning('Using untested LinkLocationManager');
    String initialPath = window.location.pathname;
    if ((window.location.pathname == '/index.html') ||
        (window.location.pathname == '/')) {
      initialPath = '/vm';
    }
    window.history.replaceState(initialPath, document.title, initialPath);
    _go(window.location.pathname);
  }

  void _onLocationChange(PopStateEvent _) {
    _go(window.location.pathname);
  }

  /// Given an application url, generate a link for an anchor tag.
  String makeLink(String url) => url;
}
