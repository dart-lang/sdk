// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  static ObservatoryApplication app;
  final _paneRegistry = new List<Pane>();
  Pane _currentPane;
  @observable final LocationManager locationManager;
  VM _vm;
  VM get vm => _vm;
  set vm(VM vm) {
    if (_vm == vm) {
      // Do nothing.
      return;
    }
    if (_vm != null) {
      // Disconnect from current VM.
      _vm.disconnect();
    }
    if (vm != null) {
      Logger.root.info('Registering new VM callbacks');
      vm.onConnect.then(_vmConnected);
      vm.onDisconnect.then(_vmDisconnected);
      vm.errors.stream.listen(_onError);
      vm.exceptions.stream.listen(_onException);
    }
    _vm = vm;
  }
  final TargetManager targets;
  @observable Isolate isolate;
  @reflectable final ObservatoryApplicationElement rootElement;

  @reflectable ServiceObject lastErrorOrException;
  @observable ObservableList<ServiceEvent> notifications =
      new ObservableList<ServiceEvent>();

  void _initOnce(bool chromium) {
    assert(app == null);
    app = this;
    _registerPanes();
    locationManager._init(this);
  }

  void removePauseEvents(Isolate isolate) {
    bool isPauseEvent(var event) {
      return (event.eventType == 'IsolateInterrupted' ||
              event.eventType == 'BreakpointReached' ||
              event.eventType == 'ExceptionThrown');
    }

    notifications.removeWhere((oldEvent) {
        return (oldEvent.isolate == isolate &&
                isPauseEvent(oldEvent));
      });
  }

  void _handleEvent(ServiceEvent event) {
    switch(event.eventType) {
      case 'IsolateCreated':
        // vm.reload();
        break;

      case 'IsolateShutdown':
        // TODO(turnidge): Should we show the user isolate shutdown events?
        // What if there are hundreds of them?  Coalesce multiple
        // shutdown events into one notification?
        removePauseEvents(event.isolate);
        // vm.reload();
        break;
        
      case 'BreakpointResolved':
        // Do nothing.
        break;

      case 'BreakpointReached':
      case 'IsolateInterrupted':
      case 'ExceptionThrown':
        removePauseEvents(event.isolate);
        notifications.add(event);
        break;

      default:
        // Ignore unrecognized events.
        Logger.root.severe('Unrecognized event type: ${event.eventType}');
        break;
    }
  }

  void _registerPanes() {
    // Register ClassTreePane.
    _paneRegistry.add(new ClassTreePane(this));
    _paneRegistry.add(new VMConnectPane(this));
    _paneRegistry.add(new ErrorViewPane(this));
    // Note that ServiceObjectPane must be the last entry in the list as it is
    // the catch all.
    _paneRegistry.add(new ServiceObjectPane(this));
  }

  void _onError(ServiceError error) {
    lastErrorOrException = error;
    _visit('error/', null);
  }

  void _onException(ServiceException exception) {
    lastErrorOrException = exception;
    if (exception.kind == 'NetworkException') {
      // Got a network exception, visit the vm-connect pane.
      locationManager.go(locationManager.makeLink('/vm-connect/'));
    } else {
      _visit('error/', null);
    }
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
    if (_currentPane == pane) {
      // Already isntalled.
      return;
    }
    if (_currentPane != null) {
      Logger.root.info('Uninstalling pane: $_currentPane');
      _currentPane.onUninstall();
      // Clear children.
      rootElement.children.clear();
    }
    Logger.root.info('Installing pane: $pane');
    try {
      pane.onInstall();
    } catch (e) {
      Logger.root.severe('Failed to install pane: $e');
    }
    // Add new pane.
    rootElement.children.add(pane.element);
    // Remember pane.
    _currentPane = pane;
  }

  ObservatoryApplication.devtools(this.rootElement) :
      locationManager = new HashLocationManager(),
      targets = null {
    vm = new PostMessageVM();
    _initOnce(true);
  }

  ObservatoryApplication(this.rootElement) :
      locationManager = new HashLocationManager(),
      targets = new TargetManager() {
    vm = new WebSocketVM(targets.defaultTarget);
    _initOnce(false);
  }

  _vmConnected(VM vm) {
    if (vm is WebSocketVM) {
      targets.add(vm.target);
    }
  }

  _vmDisconnected(VM vm) {
    if (this.vm != vm) {
      // This disconnect event occured *after* a new VM was installed.
      return;
    }
    this.vm = null;
    locationManager.go(locationManager.makeLink('/vm-connect/'));
  }
}
