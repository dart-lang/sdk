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
  final EventRepository events = new EventRepository();
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
        events.add(new ConnectionClosedEvent(new DateTime.now(), reason));
      });

      // TODO(cbernaschina) smart connection of streams in the events object.
      vm.listenEventStream(VM.kVMStream, _onEvent);
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

  void _deletePauseEvents(e) {
    notifications.deletePauseEvents(isolate: e.isolate);
  }
  void _addNotification(M.Event e) {
    notifications.add(new EventNotification(e));
  }

  void _onEvent(ServiceEvent event) {
    assert(event.kind != ServiceEvent.kNone);

    M.Event e;

    switch(event.kind) {
      case ServiceEvent.kVMUpdate:
        e = new VMUpdateEvent(event.timestamp, event.vm);
        break;
      case ServiceEvent.kIsolateStart:
        e = new IsolateStartEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kIsolateRunnable:
        e = new IsolateRunnableEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kIsolateUpdate:
        e = new IsolateUpdateEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kIsolateReload:
        e = new IsolateReloadEvent(event.timestamp, event.isolate, event.error);
        break;
      case ServiceEvent.kIsolateExit:
        e = new IsolateExitEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kBreakpointAdded:
        e = new BreakpointAddedEvent(event.timestamp, event.isolate,
            event.breakpoint);
        break;
      case ServiceEvent.kBreakpointResolved:
        e = new BreakpointResolvedEvent(event.timestamp, event.isolate,
            event.breakpoint);
        break;
      case ServiceEvent.kBreakpointRemoved:
        e = new BreakpointRemovedEvent(event.timestamp, event.isolate,
          event.breakpoint);
        break;
      case ServiceEvent.kDebuggerSettingsUpdate:
        e = new DebuggerSettingsUpdateEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kResume:
        e = new ResumeEvent(event.timestamp, event.isolate, event.topFrame);
        break;
      case ServiceEvent.kPauseStart:
        e = new PauseStartEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kPauseExit:
        e = new PauseExitEvent(event.timestamp, event.isolate);
        break;
      case ServiceEvent.kPauseBreakpoint:
        e = new PauseBreakpointEvent(event.timestamp, event.isolate,
            event.pauseBreakpoints, event.topFrame, event.atAsyncSuspension,
            event.breakpoint);
        break;
      case ServiceEvent.kPauseInterrupted:
        e = new PauseInterruptedEvent(event.timestamp, event.isolate,
            event.topFrame, event.atAsyncSuspension);
        break;
      case ServiceEvent.kPauseException:
        e = new PauseExceptionEvent(event.timestamp, event.isolate,
            event.topFrame, event.exception);
        break;
      case ServiceEvent.kInspect:
        e = new InspectEvent(event.timestamp, event.isolate,
            event.inspectee);
        break;
      default:
        // Ignore unrecognized events.
        Logger.root.severe('Unrecognized event: $event');
        return;
    }
    events.add(e);
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
