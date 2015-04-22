// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  static ObservatoryApplication app;
  final _pageRegistry = new List<Page>();
  LocationManager _locationManager;
  LocationManager get locationManager => _locationManager;
  @observable Page currentPage;
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

  void _initOnce() {
    assert(app == null);
    app = this;
    _registerPages();
    Analytics.initialize();
    // Visit the current page.
    locationManager._visit();
  }

  void removePauseEvents(Isolate isolate) {
    bool isPauseEvent(var event) {
      return (event.eventType == ServiceEvent.kPauseStart ||
              event.eventType == ServiceEvent.kPauseExit ||
              event.eventType == ServiceEvent.kPauseBreakpoint ||
              event.eventType == ServiceEvent.kPauseInterrupted ||
              event.eventType == ServiceEvent.kPauseException);
    }

    notifications.removeWhere((oldEvent) {
        return (oldEvent.isolate == isolate &&
                isPauseEvent(oldEvent));
      });
  }

  void _onEvent(ServiceEvent event) {
    switch(event.eventType) {
      case ServiceEvent.kIsolateStart:
      case ServiceEvent.kIsolateUpdate:
      case ServiceEvent.kGraph:
      case ServiceEvent.kBreakpointAdded:
      case ServiceEvent.kBreakpointResolved:
      case ServiceEvent.kBreakpointRemoved:
      case ServiceEvent.kGC:
        // Ignore for now.
        break;

      case ServiceEvent.kIsolateExit:
      case ServiceEvent.kResume:
        removePauseEvents(event.isolate);
        break;

      case ServiceEvent.kPauseStart:
      case ServiceEvent.kPauseExit:
      case ServiceEvent.kPauseBreakpoint:
      case ServiceEvent.kPauseInterrupted:
      case ServiceEvent.kPauseException:
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
    _pageRegistry.add(new VMPage(this));
    _pageRegistry.add(new FlagsPage(this));
    _pageRegistry.add(new InspectPage(this));
    _pageRegistry.add(new ClassTreePage(this));
    _pageRegistry.add(new DebuggerPage(this));
    _pageRegistry.add(new CpuProfilerPage(this));
    _pageRegistry.add(new TableCpuProfilerPage(this));
    _pageRegistry.add(new AllocationProfilerPage(this));
    _pageRegistry.add(new HeapMapPage(this));
    _pageRegistry.add(new VMConnectPage(this));
    _pageRegistry.add(new ErrorViewPage(this));
    _pageRegistry.add(new MetricsPage(this));
    // Note that ErrorPage must be the last entry in the list as it is
    // the catch all.
    _pageRegistry.add(new ErrorPage(this));
  }

  void _onError(ServiceError error) {
    lastErrorOrException = error;
    _visit(Uri.parse('error/'), null);
  }

  void _onException(ServiceException exception) {
    lastErrorOrException = exception;
    if (exception.kind == 'NetworkException') {
      // Got a network exception, visit the vm-connect page.
      this.vm = null;
      locationManager.go(locationManager.makeLink('/vm-connect/'));
    } else {
      _visit(Uri.parse('error/'), null);
    }
  }

  void _visit(Uri uri, Map internalArguments) {
    if (internalArguments['trace'] != null) {
      var traceArg = internalArguments['trace'];
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
      if (page.canVisit(uri)) {
        _installPage(page);
        page.visit(uri, internalArguments);
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

  ObservatoryApplication(this.rootElement) :
      targets = new TargetManager() {
    _locationManager = new LocationManager(this);
    vm = new WebSocketVM(targets.defaultTarget);
    _initOnce();
  }

  void _removeDisconnectEvents() {
    notifications.removeWhere((oldEvent) {
        return (oldEvent.eventType == ServiceEvent.kVMDisconnected);
      });
  }

  _vmConnected(VM vm) {
    if (vm is WebSocketVM) {
      targets.add(vm.target);
    }
    _removeDisconnectEvents();
  }

  _vmDisconnected(VM vm) {
    if (this.vm != vm) {
      // This disconnect event occured *after* a new VM was installed.
      return;
    }
    this.vm = null;
    notifications.add(new ServiceEvent.vmDisconencted());
  }
}
