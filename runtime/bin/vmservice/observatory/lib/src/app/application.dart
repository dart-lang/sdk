// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  static ObservatoryApplication app;
  final _pageRegistry = new List<Page>();
  @observable Page currentPage;
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
      notifications.clear();
      _vm.disconnect();
    }
    if (vm != null) {
      Logger.root.info('Registering new VM callbacks');
      vm.onConnect.then(_vmConnected);
      vm.onDisconnect.then(_vmDisconnected);
      vm.errors.stream.listen(_onError);
      vm.events.stream.listen(_onEvent);
      vm.exceptions.stream.listen(_onException);
    }
    _vm = vm;
  }
  final TargetManager targets;
  @reflectable final ObservatoryApplicationElement rootElement;

  TraceViewElement _traceView = null;

  @reflectable ServiceObject lastErrorOrException;
  @observable ObservableList<ServiceEvent> notifications =
      new ObservableList<ServiceEvent>();

  void _initOnce(bool chromium) {
    assert(app == null);
    app = this;
    _registerPages();
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

  void _onEvent(ServiceEvent event) {
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
        event.isolate.reloadBreakpoints();
        break;

      case 'BreakpointReached':
      case 'IsolateInterrupted':
      case 'ExceptionThrown':
        removePauseEvents(event.isolate);
        notifications.add(event);
        break;

      default:
        // Ignore unrecognized events.
        Logger.root.severe('Unrecognized event: $event');
        break;
    }
  }

  void _registerPages() {
    // Register ClassTreePage.
    _pageRegistry.add(new ClassTreePage(this));
    _pageRegistry.add(new VMConnectPage(this));
    _pageRegistry.add(new ErrorViewPage(this));
    // Note that ServiceObjectPage must be the last entry in the list as it is
    // the catch all.
    _pageRegistry.add(new ServiceObjectPage(this));
  }

  void _onError(ServiceError error) {
    lastErrorOrException = error;
    _visit('error/', null);
  }

  void _onException(ServiceException exception) {
    lastErrorOrException = exception;
    if (exception.kind == 'NetworkException') {
      // Got a network exception, visit the vm-connect page.
      locationManager.go(locationManager.makeLink('/vm-connect/'));
    } else {
      _visit('error/', null);
    }
  }

  void _visit(String url, String args) {
    var argsMap;
    if (args == null) {
      argsMap = {};
    } else {
      argsMap = Uri.splitQueryString(args);
    }
    if (argsMap['trace'] != null) {
      var traceArg = argsMap['trace'];
      if (traceArg == 'on') {
        Tracer.start();
      } else if (traceArg == 'off') {
        Tracer.stop();
      }
    }
    if (Tracer.current != null) {
      Tracer.current.reset();
    }
    if (_traceView != null) {
      _traceView.tracer = Tracer.current;
    }
    for (var i = 0; i < _pageRegistry.length; i++) {
      var page = _pageRegistry[i];
      if (page.canVisit(url)) {
        _installPage(page);
        page.visit(url, argsMap);
        return;
      }
    }
    throw new FallThroughError();
  }

  /// Set the Observatory application page.
  void _installPage(Page page) {
    assert(page != null);
    if (currentPage == page) {
      // Already isntalled.
      return;
    }
    if (currentPage != null) {
      Logger.root.info('Uninstalling page: $currentPage');
      currentPage.onUninstall();
      // Clear children.
      rootElement.children.clear();
    }
    Logger.root.info('Installing page: $page');
    try {
      page.onInstall();
    } catch (e) {
      Logger.root.severe('Failed to install page: $e');
    }
    // Add new page.
    rootElement.children.add(page.element);

    // Add tracing support.
    _traceView = new Element.tag('trace-view');
    _traceView.tracer = Tracer.current;
    rootElement.children.add(_traceView);

    // Remember page.
    currentPage = page;
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
