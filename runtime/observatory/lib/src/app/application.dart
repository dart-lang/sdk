// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// The observatory application. Instances of this are created and owned
/// by the observatory_application custom element.
class ObservatoryApplication extends Observable {
  static ObservatoryApplication app;
  final RenderingQueue queue = new RenderingQueue();
  final TargetRepository targets = new TargetRepository();
  final NotificationRepository notifications = new NotificationRepository();
  final _pageRegistry = new List<Page>();
  LocationManager _locationManager;
  LocationManager get locationManager => _locationManager;
  @observable Page currentPage;
  VM _vm;
  VM get vm => _vm;

  _setVM(VM vm) {
    if (_vm == vm) {
      // Do nothing.
      return;
    }
    if (_vm != null) {
      // Disconnect from current VM.
      notifications.deleteAll();
      _vm.disconnect();
    }
    if (vm != null) {
      Logger.root.info('Registering new VM callbacks');

      vm.onConnect.then((_) {
        notifications.deleteDisconnectEvents();
      });

      vm.onDisconnect.then((String reason) {
        if (this.vm != vm) {
          // This disconnect event occured *after* a new VM was installed.
          return;
        }
        notifications.add(
            new EventNotification.fromServiceEvent(
              new ServiceEvent.connectionClosed(reason)));
      });

      vm.listenEventStream(VM.kIsolateStream, _onEvent);
      vm.listenEventStream(VM.kDebugStream, _onEvent);
    }
    _vm = vm;
  }
  @reflectable final ObservatoryApplicationElement rootElement;

  TraceViewElement _traceView = null;

  @reflectable ServiceObject lastErrorOrException;

  void _initOnce() {
    assert(app == null);
    app = this;
    _registerPages();
    Analytics.initialize();
    // Visit the current page.
    locationManager._visit();
  }

  void _onEvent(ServiceEvent event) {
    assert(event.kind != ServiceEvent.kNone);

    switch(event.kind) {
      case ServiceEvent.kVMUpdate:
      case ServiceEvent.kIsolateStart:
      case ServiceEvent.kIsolateRunnable:
      case ServiceEvent.kIsolateUpdate:
      case ServiceEvent.kBreakpointAdded:
      case ServiceEvent.kBreakpointResolved:
      case ServiceEvent.kBreakpointRemoved:
      case ServiceEvent.kDebuggerSettingsUpdate:
        // Ignore for now.
        break;

      case ServiceEvent.kIsolateReload:
        notifications.add(new EventNotification.fromServiceEvent(event));
        break;

      case ServiceEvent.kIsolateExit:
      case ServiceEvent.kResume:
        notifications.deletePauseEvents(isolate: event.isolate);
        break;

      case ServiceEvent.kPauseStart:
      case ServiceEvent.kPauseExit:
      case ServiceEvent.kPauseBreakpoint:
      case ServiceEvent.kPauseInterrupted:
      case ServiceEvent.kPauseException:
        notifications.deletePauseEvents(isolate: event.isolate);
        notifications.add(new EventNotification.fromServiceEvent(event));
        break;

      case ServiceEvent.kInspect:
        notifications.add(new EventNotification.fromServiceEvent(event));
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

    // Add tracing support.
    _traceView = new Element.tag('trace-view');
    _traceView.tracer = Tracer.current;
    rootElement.children.add(_traceView);

    // Remember page.
    currentPage = page;
  }

  ObservatoryApplication(this.rootElement) {
    _locationManager = new LocationManager(this);
    targets.onChange.listen((e) {
      if (targets.current == null) return _setVM(null);
      if ((_vm as WebSocketVM)?.target != targets.current) {
        _setVM(new WebSocketVM(targets.current));
      }
    });
    _setVM(new WebSocketVM(targets.current));
    _initOnce();
  }

  loadCrashDump(Map crashDump) {
    _setVM(new FakeVM(crashDump['result']));
    app.locationManager.go('#/vm');
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
  Map<String,bool> expansions = {};
}
