// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

AllocationProfileRepository _allocationProfileRepository
    = new AllocationProfileRepository();
ClassRepository _classRepository = new ClassRepository();
ContextRepository _contextRepository = new ContextRepository();
FieldRepository _fieldRepository = new FieldRepository();
FunctionRepository _functionRepository = new FunctionRepository();
HeapSnapshotRepository _heapSnapshotRepository
    = new HeapSnapshotRepository();
ICDataRepository _icdataRepository = new ICDataRepository();
InboundReferencesRepository _inboundReferencesRepository
    = new InboundReferencesRepository();
InstanceRepository _instanceRepository = new InstanceRepository();
IsolateSampleProfileRepository _isolateSampleProfileRepository
    = new IsolateSampleProfileRepository();
MegamorphicCacheRepository _megamorphicCacheRepository
    = new MegamorphicCacheRepository();
ObjectPoolRepository _objectPoolRepository
    = new ObjectPoolRepository();
ObjectStoreRepository _objectstoreRepository
    = new ObjectStoreRepository();
ObjectRepository _objectRepository = new ObjectRepository();
PersistentHandlesRepository _persistentHandlesRepository
    = new PersistentHandlesRepository();
PortsRepository _portsRepository = new PortsRepository();
ScriptRepository _scriptRepository = new ScriptRepository();

class IsolateNotFound implements Exception {
  String isolateId;
  IsolateNotFound(this.isolateId);
  String toString() => "IsolateNotFound: $isolateId";
}
RetainedSizeRepository _retainedSizeRepository = new RetainedSizeRepository();
ReachableSizeRepository _reachableSizeRepository
    = new ReachableSizeRepository();
RetainingPathRepository _retainingPathRepository
    = new RetainingPathRepository();

/// A [Page] controls the user interface of Observatory. At any given time
/// one page will be the current page. Pages are registered at startup.
/// When the user navigates within the application, each page is asked if it
/// can handle the current location, the first page to say yes, wins.
abstract class Page extends Observable {
  final ObservatoryApplication app;
  final ObservableMap<String, String> internalArguments =
      new ObservableMap<String, String>();
  @observable HtmlElement element;

  Page(this.app);

  /// Called when the page is installed, this callback must initialize
  /// [element].
  void onInstall();

  /// Called when the page is uninstalled, this callback must clear
  /// [element].
  void onUninstall() {
    element = null;
  }

  /// Called when the page should update its state based on [uri].
  void visit(Uri uri, Map internalArguments) {
    this.internalArguments.clear();
    this.internalArguments.addAll(internalArguments);
    Analytics.reportPageView(uri);
    _visit(uri);
  }

  // Overridden by subclasses.
  void _visit(Uri uri);

  /// Called to test whether this page can visit [uri].
  bool canVisit(Uri uri);
}

/// A [MatchingPage] matches a single uri path.
abstract class MatchingPage extends Page {
  final String path;
  MatchingPage(this.path, app) : super(app);

  void _visit(Uri uri) {
    assert(uri != null);
    assert(canVisit(uri));
  }

  Future<Isolate> getIsolate(Uri uri) {
    var isolateId = uri.queryParameters['isolateId'];
    return app.vm.getIsolate(isolateId).then((isolate) {
      if (isolate == null) {
        throw new IsolateNotFound(isolateId);
      }
      return isolate;
    });
  }

  bool canVisit(Uri uri) => uri.path == path;
}

/// A [SimplePage] matches a single uri path and displays a single element.
class SimplePage extends MatchingPage {
  final String elementTagName;
  SimplePage(String path, this.elementTagName, app) : super(path, app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag(elementTagName);
    }
  }
}

/// Error page for unrecognized paths.
class ErrorPage extends Page {
  ErrorPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      // Lazily create page.
      element = new GeneralErrorElement(app.notifications, queue: app.queue);
    }
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));

    (element as GeneralErrorElement).message = "Path '${uri.path}' not found";
  }

  /// Catch all.
  bool canVisit(Uri uri) => true;
}

/// Top-level vm info page.
class VMPage extends SimplePage {
  VMPage(app) : super('vm', 'vm-view', app);

  void _visit(Uri uri) {
    super._visit(uri);
    app.vm.reload().then((vm) {
      if (element != null) {
        VMViewElement serviceElement = element;
        serviceElement.vm = vm;
      }
    }).catchError((e, stack) {
      Logger.root.severe('VMPage visit error: $e');
      // Reroute to vm-connect.
      app.locationManager.go(app.locationManager.makeLink('/vm-connect'));
    });
  }
}

class FlagsPage extends SimplePage {
  FlagsPage(app) : super('flags', 'flag-list', app);

  @override
  onInstall() {
    element = new FlagListElement(app.vm,
                                  app.events,
                                  new FlagsRepository(app.vm),
                                  app.notifications);
  }

  void _visit(Uri uri) {
    super._visit(uri);
  }
}

class InspectPage extends MatchingPage {
  InspectPage(app) : super('inspect', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      var objectId = uri.queryParameters['objectId'];
      if (objectId == null) {
        isolate.reload().then(_visitObject);
      } else {
        isolate.getObject(objectId).then(_visitObject);
      }
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }

  Future _visitObject(obj) async {
    container.children = [];
    await obj.reload();
    if (obj is Context) {
      container.children = [
        new ContextViewElement(app.vm, obj.isolate, obj, app.events,
                               app.notifications,
                               _contextRepository,
                               _retainedSizeRepository,
                               _reachableSizeRepository,
                               _inboundReferencesRepository,
                               _retainingPathRepository,
                               _instanceRepository,
                               queue: app.queue)
      ];
    } else if (obj is DartError) {
      container.children = [
        new ErrorViewElement(app.notifications, obj, queue: app.queue)
      ];
    } else if (obj is Field) {
      container.children = [
        new FieldViewElement(app.vm, obj.isolate, obj, app.events,
                             app.notifications,
                             _fieldRepository,
                             _classRepository,
                             _retainedSizeRepository,
                             _reachableSizeRepository,
                             _inboundReferencesRepository,
                             _retainingPathRepository,
                             _scriptRepository,
                             _instanceRepository,
                             queue: app.queue)
      ];
    } else if (obj is ServiceFunction) {
      container.children = [
        new FunctionViewElement(app.vm, obj.isolate, obj, app.events,
                                app.notifications,
                                _functionRepository,
                                _classRepository,
                                _retainedSizeRepository,
                                _reachableSizeRepository,
                                _inboundReferencesRepository,
                                _retainingPathRepository,
                                _scriptRepository,
                                _instanceRepository,
                                queue: app.queue)
      ];
    } else if (obj is ICData) {
      container.children = [
        new ICDataViewElement(app.vm, obj.isolate, obj, app.events,
                               app.notifications,
                               _icdataRepository,
                               _retainedSizeRepository,
                               _reachableSizeRepository,
                               _inboundReferencesRepository,
                               _retainingPathRepository,
                               _instanceRepository,
                               queue: app.queue)
      ];
    } else if (obj is MegamorphicCache) {
      container.children = [
        new MegamorphicCacheViewElement(app.vm, obj.isolate, obj, app.events,
                                        app.notifications,
                                        _megamorphicCacheRepository,
                                        _retainedSizeRepository,
                                        _reachableSizeRepository,
                                        _inboundReferencesRepository,
                                        _retainingPathRepository,
                                        _instanceRepository,
                                        queue: app.queue)
      ];
    } else if (obj is ObjectPool) {
      container.children = [
        new ObjectPoolViewElement(app.vm, obj.isolate, obj, app.events,
                                  app.notifications,
                                  _objectPoolRepository,
                                  _retainedSizeRepository,
                                  _reachableSizeRepository,
                                  _inboundReferencesRepository,
                                  _retainingPathRepository,
                                  _instanceRepository,
                                  queue: app.queue)
      ];
    } else if (obj is Script) {
      var pos;
      if (app.locationManager.internalArguments['pos'] != null) {
        try {
          pos = int.parse(app.locationManager.internalArguments['pos']);
        } catch (_) {}
      }
      container.children = [
        new ScriptViewElement(app.vm, obj.isolate, obj, app.events,
                              app.notifications,
                              _scriptRepository,
                              _retainedSizeRepository,
                              _reachableSizeRepository,
                              _inboundReferencesRepository,
                              _retainingPathRepository,
                              _instanceRepository,
                              pos: pos, queue: app.queue)
      ];
    } else if (obj.kind == 'Object') {
      container.children = [
        new ObjectViewElement(app.vm, obj.isolate, obj, app.events,
                               app.notifications,
                               _objectRepository,
                               _retainedSizeRepository,
                               _reachableSizeRepository,
                               _inboundReferencesRepository,
                               _retainingPathRepository,
                               _instanceRepository,
                               queue: app.queue)
      ];
    } else {
      ServiceObjectViewElement serviceElement =new Element.tag('service-view');
      serviceElement.object = obj;
      container.children = [serviceElement];
    }
  }
}


/// Class tree page.
class ClassTreePage extends SimplePage {
  ClassTreePage(app) : super('class-tree', 'class-tree', app);

  final DivElement container = new DivElement();

  @override
  void onInstall() {
    element = container;
  }

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new ClassTreeElement(app.vm,
                             isolate,
                             app.events,
                             app.notifications,
                             _classRepository)
      ];
    });
  }
}

class DebuggerPage extends SimplePage {
  DebuggerPage(app) : super('debugger', 'debugger-page', app);

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      if (element != null) {
        /// Update the page.
        DebuggerPageElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class ObjectStorePage extends MatchingPage {
  ObjectStorePage(app) : super('object-store', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) async {
      container.children = [
        new ObjectStoreViewElement(isolate.vm, isolate,
                                   app.events,
                                   app.notifications,
                                   _objectstoreRepository,
                                   _instanceRepository)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }
}

class CpuProfilerPage extends MatchingPage {
  CpuProfilerPage(app) : super('profiler', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new CpuProfileElement(isolate.vm, isolate, app.events,
                              app.notifications,
                              _isolateSampleProfileRepository)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }
}

class TableCpuProfilerPage extends MatchingPage {
  TableCpuProfilerPage(app) : super('profiler-table', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new CpuProfileTableElement(isolate.vm, isolate, app.events,
                                   app.notifications,
                                   _isolateSampleProfileRepository)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }
}

class AllocationProfilerPage extends MatchingPage {
  AllocationProfilerPage(app) : super('allocation-profiler', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new AllocationProfileElement(isolate.vm, isolate, app.events,
                                     app.notifications,
                                     _allocationProfileRepository,
                                     queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    app.startGCEventListener();
  }

  void onUninstall() {
    super.onUninstall();
    app.stopGCEventListener();
  }
}

class PortsPage extends MatchingPage {
  PortsPage(app) : super('ports', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new PortsElement(isolate.vm, isolate, app.events, app.notifications,
                         _portsRepository, _instanceRepository,
                         queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
  }
}

class PersistentHandlesPage extends MatchingPage {
  PersistentHandlesPage(app) : super('persistent-handles', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new PersistentHandlesPageElement(isolate.vm, isolate, app.events,
                                         app.notifications,
                                         _persistentHandlesRepository,
                                         _instanceRepository, queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
  }
}

class HeapMapPage extends MatchingPage {
  HeapMapPage(app) : super('heap-map', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new HeapMapElement(isolate.vm, isolate, app.events, app.notifications,
                           queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
  }
}

class HeapSnapshotPage extends MatchingPage {
  HeapSnapshotPage(app) : super('heap-snapshot', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      container.children = [
        new HeapSnapshotElement(isolate.vm, isolate, app.events,
                                app.notifications, _heapSnapshotRepository,
                                _instanceRepository, queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
  }
}


class LoggingPage extends SimplePage {
  LoggingPage(app) : super('logging', 'logging-page', app);

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) {
      if (element != null) {
        /// Update the page.
        LoggingPageElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class ErrorViewPage extends Page {
  ErrorViewPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create page.
      element = new Element.tag('service-view');
    }
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
    (element as ServiceObjectViewElement).object = app.lastErrorOrException;
  }

  // TODO(turnidge): How to test this page?
  bool canVisit(Uri uri) => uri.path == 'error';
}

class VMConnectPage extends Page {
  VMConnectPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new VMConnectElement(
            ObservatoryApplication.app.targets,
            ObservatoryApplication.app.loadCrashDump,
            ObservatoryApplication.app.notifications,
            queue: ObservatoryApplication.app.queue);
    }
    assert(element != null);
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
  }

  bool canVisit(Uri uri) => uri.path == 'vm-connect';
}

class IsolateReconnectPage extends Page {
  IsolateReconnectPage(app) : super(app);

  final DivElement container = new DivElement();

  void onInstall() {
    element = container;
  }

  void _visit(Uri uri) {
    app.vm.reload();
    container.children = [
      new IsolateReconnectElement(app.vm, app.events, app.notifications,
                                  uri.queryParameters['isolateId'],
                                  Uri.parse(uri.queryParameters['originalUri']))
    ];
    assert(element != null);
    assert(canVisit(uri));
  }

  bool canVisit(Uri uri) => uri.path == 'isolate-reconnect';
}

class MetricsPage extends Page {
  // Page state, retained as long as ObservatoryApplication.
  String selectedMetricId;

  final Map<int, MetricPoller> pollers = new Map<int, MetricPoller>();

  // 8 seconds, 4 seconds, 2 seconds, 1 second, and one hundred milliseconds.
  static final List<int> POLL_PERIODS = [8000,
                                         4000,
                                         2000,
                                         1000,
                                         100];

  MetricsPage(app) : super(app) {
    for (var i = 0; i < POLL_PERIODS.length; i++) {
      pollers[POLL_PERIODS[i]] = new MetricPoller(POLL_PERIODS[i]);
    }
  }

  void onInstall() {
    if (element == null) {
      element = new Element.tag('metrics-page');
      (element as MetricsPageElement).page = this;
    }
    assert(element != null);
  }

  void setRefreshPeriod(int refreshPeriod, ServiceMetric metric) {
    if (metric.poller != null) {
      if (metric.poller.pollPeriod.inMilliseconds == refreshPeriod) {
        return;
      }
      // Remove from current poller.
      metric.poller.metrics.remove(metric);
      metric.poller = null;
    }
    if (refreshPeriod == 0) {
      return;
    }
    var poller = pollers[refreshPeriod];
    if (poller != null) {
      poller.metrics.add(metric);
      metric.poller = poller;
      return;
    }
    throw new FallThroughError();
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
    app.vm.getIsolate(uri.queryParameters['isolateId']).then((i) {
      (element as MetricsPageElement).isolate = i;
    });
  }

  bool canVisit(Uri uri) => uri.path == 'metrics';
}

class TimelinePage extends Page {
  TimelinePage(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('timeline-page');
    }
    assert(element != null);
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
  }

  bool canVisit(Uri uri) => uri.path == 'timeline';
}
