// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  final _paneRegistry = new List<Pane>();
  ServiceObjectPane _serviceObjectPane;
  Pane _currentPane;
  @observable final LocationManager locationManager;
  @observable final VM vm;
  @observable Isolate isolate;
  @reflectable final ObservatoryApplicationElement rootElement;

  @reflectable ServiceObject lastErrorOrException;

  void _initOnce() {
    _registerPanes();
    vm.errors.stream.listen(_onError);
    vm.exceptions.stream.listen(_onException);
    location = locationManager;
    locationManager._init(this);
  }

  void _registerPanes() {
    if (_serviceObjectPane != null) {
      // Already done.
      return;
    }
    // Register ClassTreePane.
    _paneRegistry.add(new ClassTreePane(this));
    _paneRegistry.add(new ErrorViewPane(this));
    // Note that ServiceObjectPane must be the last entry in the list as it is
    // the catch all.
    _serviceObjectPane = new ServiceObjectPane(this);
    _paneRegistry.add(_serviceObjectPane);
  }

  void _onError(ServiceError error) {
    lastErrorOrException = error;
    _visit('error/', null);
  }

  void _onException(ServiceException exception) {
    lastErrorOrException = exception;
    _visit('error/', null);
  }

  void _visit(String url, String args) {
    // TODO(johnmccutchan): Pass [args] to pane.
    for (var i = 0; i < _paneRegistry.length; i++) {
      var pane = _paneRegistry[i];
      if (pane.canVisit(url)) {
        _installPane(pane);
        pane.visit(url);
        return;
      }
    }
    throw new FallThroughError();
  }

  /// Set the Observatory application pane.
  void _installPane(Pane pane) {
    assert(pane != null);
    print('Installing $pane');
    if (_currentPane == pane) {
      // Already isntalled.
      return;
    }
    if (_currentPane != null) {
      _currentPane.onUninstall();
    }
    pane.onInstall();
    // Clear children.
    rootElement.children.clear();
    // Add new pane.
    rootElement.children.add(pane.element);
    // Remember pane.
    _currentPane = pane;
  }

  ObservatoryApplication.devtools(this.rootElement) :
      locationManager = new HashLocationManager(),
      vm = new DartiumVM() {
    _initOnce();
  }

  ObservatoryApplication(this.rootElement) :
      locationManager = new HashLocationManager(),
      vm = new HttpVM() {
    _initOnce();
  }
}

LocationManager location;
