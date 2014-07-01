// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// A [Pane] controls the user interface of Observatory. At any given time
/// one pane will be the current pane. Panes are registered at startup.
/// When the user navigates within the application, each pane is asked if it
/// can handle the current location, the first pane to say yes, wins.
abstract class Pane extends Observable {
  final ObservatoryApplication app;

  @observable ObservatoryElement element;

  Pane(this.app);

  /// Called when the pane is installed, this callback must initialize
  /// [element].
  void onInstall();

  /// Called when the pane is uninstalled, this callback must clear
  /// [element].
  void onUninstall() {
    element = null;
  }

  /// Called when the pane should update its state based on [url].
  /// NOTE: Only called when the pane is installed.
  void visit(String url);

  /// Called to test whether this pane can visit [url].
  bool canVisit(String url);
}

/// A general service object viewer.
class ServiceObjectPane extends Pane {
  ServiceObjectPane(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create pane.
      element = new Element.tag('service-view');
    }
  }

  void visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    if (url == '') {
      // Nothing requested.
      return;
    }
    /// Request url from VM and display it.
    app.vm.get(url).then((obj) {
      ServiceObjectViewElement pane = element;
      pane.object = obj;
    }).catchError((e) {
      Logger.root.severe('ServiceObjectPane visit error: $e');
    });
  }

  /// Catch all.
  bool canVisit(String url) => true;
}

/// Class tree pane.
class ClassTreePane extends Pane {
  static const _urlPrefix = 'class-tree/';

  ClassTreePane(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('class-tree');
    }
  }

  void visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    // ClassTree urls are 'class-tree/isolate-id', chop off prefix, leaving
    // isolate url.
    url = url.substring(_urlPrefix.length);
    /// Request the isolate url.
    app.vm.get(url).then((i) {
      if (element != null) {
        /// Update the pane.
        ClassTreeElement pane = element;
        pane.isolate = i;
      }
    }).catchError((e) {
      Logger.root.severe('ClassTreePane visit error: $e');
    });
  }

  /// Catch all.
  bool canVisit(String url) => url.startsWith(_urlPrefix);
}

class ErrorViewPane extends Pane {
  ErrorViewPane(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create pane.
      element = new Element.tag('service-view');
    }
  }

  void visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    (element as ServiceObjectViewElement).object = app.lastErrorOrException;
  }

  bool canVisit(String url) => url.startsWith('error/');
}

class VMConnectPane extends Pane {
  VMConnectPane(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('vm-connect');
    }
    assert(element != null);
  }

  void visit(String url) {
    assert(element != null);
    assert(canVisit(url));
  }

  bool canVisit(String url) => url.startsWith('vm-connect/');
}
