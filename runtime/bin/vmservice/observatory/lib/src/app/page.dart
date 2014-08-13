// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// A [Page] controls the user interface of Observatory. At any given time
/// one page will be the current page. Pages are registered at startup.
/// When the user navigates within the application, each page is asked if it
/// can handle the current location, the first page to say yes, wins.
abstract class Page extends Observable {
  final ObservatoryApplication app;

  @observable ObservatoryElement element;
  @observable ObservableMap args;

  Page(this.app);

  /// Called when the page is installed, this callback must initialize
  /// [element].
  void onInstall();

  /// Called when the page is uninstalled, this callback must clear
  /// [element].
  void onUninstall() {
    element = null;
  }

  /// Called when the page should update its state based on [url].
  /// NOTE: Only called when the page is installed.
  void visit(String url, Map argsMap) {
    args = toObservable(argsMap);
    _visit(url);
  }

  // Overridden by subclasses.
  void _visit(String url);

  /// Called to test whether this page can visit [url].
  bool canVisit(String url);
}

/// A general service object viewer.
class ServiceObjectPage extends Page {
  ServiceObjectPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create page.
      element = new Element.tag('service-view');
    }
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    if (url == '') {
      // Nothing requested.
      return;
    }
    /// Request url from VM and display it.
    app.vm.get(url).then((obj) {
      ServiceObjectViewElement serviceElement = element;
      serviceElement.object = obj;
    }).catchError((e) {
      Logger.root.severe('ServiceObjectPage visit error: $e');
    });
  }

  /// Catch all.
  bool canVisit(String url) => true;
}

/// Class tree page.
class ClassTreePage extends Page {
  static const _urlPrefix = 'class-tree/';

  ClassTreePage(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('class-tree');
    }
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    // ClassTree urls are 'class-tree/isolate-id', chop off prefix, leaving
    // isolate url.
    url = url.substring(_urlPrefix.length);
    /// Request the isolate url.
    app.vm.get(url).then((i) {
      if (element != null) {
        /// Update the page.
        ClassTreeElement page = element;
        page.isolate = i;
      }
    }).catchError((e) {
      Logger.root.severe('ClassTreePage visit error: $e');
    });
  }

  /// Catch all.
  bool canVisit(String url) => url.startsWith(_urlPrefix);
}

class ErrorViewPage extends Page {
  ErrorViewPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create page.
      element = new Element.tag('service-view');
    }
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    (element as ServiceObjectViewElement).object = app.lastErrorOrException;
  }

  bool canVisit(String url) => url.startsWith('error/');
}

class VMConnectPage extends Page {
  VMConnectPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('vm-connect');
    }
    assert(element != null);
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
  }

  bool canVisit(String url) => url.startsWith('vm-connect/');
}
