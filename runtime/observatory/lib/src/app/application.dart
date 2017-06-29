// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication {
  static ObservatoryApplication app;
  final RenderingQueue queue = new RenderingQueue();
  final TargetRepository targets = new TargetRepository();
  final EventRepository events = new EventRepository();
  final NotificationRepository notifications = new NotificationRepository();
  final _pageRegistry = new List<Page>();
  LocationManager _locationManager;
  LocationManager get locationManager => _locationManager;
  Page currentPage;
  bool _vmConnected = false;
  VM _vm;
  VM get vm => _vm;

  bool isConnectedVMTarget(WebSocketVMTarget target) {
    if (_vm is CommonWebSocketVM) {
      if ((_vm as CommonWebSocketVM).target == target) {
        return _vm.isConnected;
      }
    }
    return false;
  }

  _switchVM(VM newVM) {
    final VM oldVM = _vm;

    Logger.root.info('_switchVM from:${oldVM} to:${newVM}');

    if (oldVM == newVM) {
      // Do nothing.
      return;
    }

    if (oldVM != null) {
      print('disconnecting from the old VM ${oldVM}--');
      // Disconnect from current VM.
      stopGCEventListener();
      notifications.deleteAll();
      oldVM.disconnect();
    }

    if (newVM != null) {
      // Mark that we haven't connected yet.
      _vmConnected = false;
      // On connect:
      newVM.onConnect.then((_) {
        // We connected.
        _vmConnected = true;
        notifications.deleteDisconnectEvents();
      });
      // On disconnect:
      newVM.onDisconnect.then((String reason) {
        if (this.vm != newVM) {
          // This disconnect event occured *after* a new VM was installed.
          return;
        }
        // Let anyone looking at the targets know that we have disconnected
        // from one.
        targets.emitDisconnectEvent();
        if (!_vmConnected) {
          // Connection error. Navigate back to the connect page.
          Logger.root.info('Connection failed, navigating to VM connect page.');
          // Clear the vm.
          _vm = null;
          app.locationManager.go(Uris.vmConnect());
        } else {
          // Disconnect. Stay at the current page and push an a connection
          // closed event.
          Logger.root.info('Lost an existing connection to a VM');
          events.add(new ConnectionClosedEvent(new DateTime.now(), reason));
        }
      });
      // TODO(cbernaschina) smart connection of streams in the events object.
      newVM.listenEventStream(VM.kVMStream, _onEvent);
      newVM.listenEventStream(VM.kIsolateStream, _onEvent);
      newVM.listenEventStream(VM.kDebugStream, _onEvent);
    }

    _vm = newVM;
  }

  StreamSubscription _gcSubscription;
  StreamSubscription _loggingSubscription;

  Future startGCEventListener() async {
    if (_gcSubscription != null || _vm == null) {
      return;
    }
    _gcSubscription = await _vm.listenEventStream(VM.kGCStream, _onEvent);
  }

  Future startLoggingEventListener() async {
    if (_loggingSubscription != null || _vm == null) {
      return;
    }
    _loggingSubscription =
        await _vm.listenEventStream(Isolate.kLoggingStream, _onEvent);
  }

  Future stopGCEventListener() async {
    if (_gcSubscription == null) {
      return;
    }
    _gcSubscription.cancel();
    _gcSubscription = null;
  }

  Future stopLoggingEventListener() async {
    if (_loggingSubscription == null) {
      return;
    }
    _loggingSubscription.cancel();
    _loggingSubscription = null;
  }

  final ObservatoryApplicationElement rootElement;

  ServiceObject lastErrorOrException;

  void _initOnce() {
    assert(app == null);
    app = this;
    _registerPages();
    Analytics.initialize();
    // Visit the current page.
    locationManager._visit();
  }

  void _deletePauseEvents(e) {
    notifications.deletePauseEvents(isolate: e.isolate);
  }

  void _addNotification(M.Event e) {
    notifications.add(new EventNotification(e));
  }

  void _onEvent(ServiceEvent event) {
    assert(event.kind != ServiceEvent.kNone);
    M.Event e = createEventFromServiceEvent(event);
    if (e != null) {
      events.add(e);
    }
  }

  void _registerPages() {
    _pageRegistry.add(new VMPage(this));
    _pageRegistry.add(new FlagsPage(this));
    _pageRegistry.add(new NativeMemoryProfilerPage(this));
    _pageRegistry.add(new InspectPage(this));
    _pageRegistry.add(new ClassTreePage(this));
    _pageRegistry.add(new DebuggerPage(this));
    _pageRegistry.add(new ObjectStorePage(this));
    _pageRegistry.add(new CpuProfilerPage(this));
    _pageRegistry.add(new TableCpuProfilerPage(this));
    _pageRegistry.add(new AllocationProfilerPage(this));
    _pageRegistry.add(new HeapMapPage(this));
    _pageRegistry.add(new HeapSnapshotPage(this));
    _pageRegistry.add(new VMConnectPage(this));
    _pageRegistry.add(new IsolateReconnectPage(this));
    _pageRegistry.add(new ErrorViewPage(this));
    _pageRegistry.add(new MetricsPage(this));
    _pageRegistry.add(new PersistentHandlesPage(this));
    _pageRegistry.add(new PortsPage(this));
    _pageRegistry.add(new LoggingPage(this));
    _pageRegistry.add(new TimelinePage(this));
    _pageRegistry.add(new MemoryDashboardPage(this));
    // Note that ErrorPage must be the last entry in the list as it is
    // the catch all.
    _pageRegistry.add(new ErrorPage(this));
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
      // Already installed.
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

    // Remember page.
    currentPage = page;
  }

  ObservatoryApplication(this.rootElement) {
    _locationManager = new LocationManager(this);
    targets.onChange.listen((TargetChangeEvent e) {
      if (e.disconnected) {
        // We don't care about disconnected events.
        return;
      }
      if (targets.current == null) {
        _switchVM(null);
      }
      final bool currentTarget =
          (_vm as WebSocketVM)?.target == targets.current;
      final bool currentTargetConnected = (_vm != null) && !_vm.isDisconnected;
      if (!currentTarget || !currentTargetConnected) {
        _switchVM(new WebSocketVM(targets.current));
        app.locationManager.go(Uris.vm());
      }
    });

    Logger.root.info('Setting initial target to ${targets.current.name}');
    _switchVM(new WebSocketVM(targets.current));
    _initOnce();

    // delete pause events.
    events.onIsolateExit.listen(_deletePauseEvents);
    events.onResume.listen(_deletePauseEvents);
    events.onPauseStart.listen(_deletePauseEvents);
    events.onPauseExit.listen(_deletePauseEvents);
    events.onPauseBreakpoint.listen(_deletePauseEvents);
    events.onPauseInterrupted.listen(_deletePauseEvents);
    events.onPauseException.listen(_deletePauseEvents);

    // show notification for an event.
    events.onIsolateReload.listen(_addNotification);
    events.onPauseExit.listen(_addNotification);
    events.onPauseBreakpoint.listen(_addNotification);
    events.onPauseInterrupted.listen(_addNotification);
    events.onPauseException.listen(_addNotification);
    events.onInspect.listen(_addNotification);
    events.onConnectionClosed.listen(_addNotification);
  }

  loadCrashDump(Map crashDump) {
    _switchVM(new FakeVM(crashDump['result']));
    app.locationManager.go(Uris.vm());
  }

  void handleException(e, st) {
    if (e is ServerRpcException) {
      if (e.code == ServerRpcException.kFeatureDisabled) return;
      if (e.code == ServerRpcException.kIsolateMustBePaused) return;
      if (e.code == ServerRpcException.kCannotAddBreakpoint) return;
      Logger.root.fine('Dropping exception: ${e}\n${st}');
    }

    // TODO(turnidge): Report this failure via analytics.
    Logger.root.warning('Caught exception: ${e}\n${st}');
    notifications.add(new ExceptionNotification(e, stacktrace: st));
  }

  // This map keeps track of which curly-blocks have been expanded by the user.
  Map<String, bool> expansions = {};
}
