// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

final _allocationProfileRepository = new AllocationProfileRepository();
final _breakpointRepository = new BreakpointRepository();
final _classRepository = new ClassRepository();
final _classSampleProfileRepository = new ClassSampleProfileRepository();
final _contextRepository = new ContextRepository();
final _evalRepository = new EvalRepository();
final _fieldRepository = new FieldRepository();
final _functionRepository = new FunctionRepository();
final _heapSnapshotRepository = new HeapSnapshotRepository();
final _icdataRepository = new ICDataRepository();
final _inboundReferencesRepository = new InboundReferencesRepository();
final _instanceRepository = new InstanceRepository();
final _isolateRepository = new IsolateRepository();
final _isolateSampleProfileRepository = new IsolateSampleProfileRepository();
final _libraryRepository = new LibraryRepository();
final _megamorphicCacheRepository = new MegamorphicCacheRepository();
final _metricRepository = new MetricRepository();
final _nativeMemorySampleProfileRepository =
    new NativeMemorySampleProfileRepository();
final _objectPoolRepository = new ObjectPoolRepository();
final _objectRepository = new ObjectRepository();
final _objectstoreRepository = new ObjectStoreRepository();
final _persistentHandlesRepository = new PersistentHandlesRepository();
final _portsRepository = new PortsRepository();
final _scriptRepository = new ScriptRepository();
final _singleTargetCacheRepository = new SingleTargetCacheRepository();
final _stronglyReachangleInstancesRepository =
    new StronglyReachableInstancesRepository();
final _subtypeTestCacheRepository = new SubtypeTestCacheRepository();
final _topRetainingInstancesRepository = new TopRetainingInstancesRepository();
final _typeArgumentsRepository = new TypeArgumentsRepository();
final _unlinkedCallRepository = new UnlinkedCallRepository();

class IsolateNotFound implements Exception {
  String isolateId;
  IsolateNotFound(this.isolateId);
  String toString() => "IsolateNotFound: $isolateId";
}

RetainedSizeRepository _retainedSizeRepository = new RetainedSizeRepository();
ReachableSizeRepository _reachableSizeRepository =
    new ReachableSizeRepository();
RetainingPathRepository _retainingPathRepository =
    new RetainingPathRepository();

/// A [Page] controls the user interface of Observatory. At any given time
/// one page will be the current page. Pages are registered at startup.
/// When the user navigates within the application, each page is asked if it
/// can handle the current location, the first page to say yes, wins.
abstract class Page {
  final ObservatoryApplication app;
  final Map<String, String> internalArguments = <String, String>{};
  HtmlElement element;

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
class VMPage extends MatchingPage {
  VMPage(app) : super('vm', app);

  final DivElement container = new DivElement();

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }

  void _visit(Uri uri) {
    super._visit(uri);
    if (app.vm == null) {
      Logger.root.severe('VMPage has no VM');
      // Reroute to vm-connect.
      app.locationManager.go(Uris.vmConnect());
      return;
    }
    app.vm.reload().then((VM vm) {
      container.children = [
        new VMViewElement(vm, app.events, app.notifications, _isolateRepository,
            _scriptRepository,
            queue: app.queue)
      ];
    }).catchError((e, stack) {
      Logger.root.severe('VMPage visit error: $e');
      // Reroute to vm-connect.
      app.locationManager.go(Uris.vmConnect());
    });
  }
}

class FlagsPage extends SimplePage {
  FlagsPage(app) : super('flags', 'flag-list', app);

  @override
  onInstall() {
    element = new FlagListElement(
        app.vm, app.events, new FlagsRepository(app.vm), app.notifications,
        queue: app.queue);
  }

  void _visit(Uri uri) {
    super._visit(uri);
  }
}

class NativeMemoryProfilerPage extends SimplePage {
  NativeMemoryProfilerPage(app)
      : super('native-memory-profile', 'native-memory-profile', app);
  @override
  onInstall() {
    if (element == null) {
      element = new NativeMemoryProfileElement(app.vm, app.events,
          app.notifications, _nativeMemorySampleProfileRepository,
          queue: app.queue);
    }
    assert(element != null);
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
    if (obj is Class) {
      container.children = [
        new ClassViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _classRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _fieldRepository,
            _scriptRepository,
            _objectRepository,
            _evalRepository,
            _stronglyReachangleInstancesRepository,
            _topRetainingInstancesRepository,
            _classSampleProfileRepository,
            queue: app.queue)
      ];
    } else if (obj is Code) {
      await obj.loadScript();
      container.children = [
        new CodeViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is Context) {
      container.children = [
        new ContextViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _contextRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is DartError) {
      container.children = [
        new ErrorViewElement(app.notifications, obj, queue: app.queue)
      ];
    } else if (obj is Field) {
      container.children = [
        new FieldViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _fieldRepository,
            _classRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _scriptRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is Instance) {
      container.children = [
        new InstanceViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _objectRepository,
            _classRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _scriptRepository,
            _evalRepository,
            _typeArgumentsRepository,
            _breakpointRepository,
            _functionRepository,
            queue: app.queue)
      ];
    } else if (obj is Isolate) {
      container.children = [
        new IsolateViewElement(
            app.vm,
            obj,
            app.events,
            app.notifications,
            _isolateRepository,
            _scriptRepository,
            _functionRepository,
            _libraryRepository,
            _objectRepository,
            _evalRepository,
            queue: app.queue)
      ];
    } else if (obj is ServiceFunction) {
      container.children = [
        new FunctionViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _functionRepository,
            _classRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _scriptRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is ICData) {
      container.children = [
        new ICDataViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _icdataRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is SingleTargetCache) {
      container.children = [
        new SingleTargetCacheViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _singleTargetCacheRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is SubtypeTestCache) {
      container.children = [
        new SubtypeTestCacheViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _subtypeTestCacheRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is UnlinkedCall) {
      container.children = [
        new UnlinkedCallViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _unlinkedCallRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is Library) {
      container.children = [
        new LibraryViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _libraryRepository,
            _fieldRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _scriptRepository,
            _objectRepository,
            _evalRepository,
            queue: app.queue)
      ];
    } else if (obj is MegamorphicCache) {
      container.children = [
        new MegamorphicCacheViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _megamorphicCacheRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is ObjectPool) {
      container.children = [
        new ObjectPoolViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _objectPoolRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
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
        new ScriptViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _scriptRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            pos: pos,
            queue: app.queue)
      ];
    } else if (obj is HeapObject) {
      container.children = [
        new ObjectViewElement(
            app.vm,
            obj.isolate,
            obj,
            app.events,
            app.notifications,
            _objectRepository,
            _retainedSizeRepository,
            _reachableSizeRepository,
            _inboundReferencesRepository,
            _retainingPathRepository,
            _objectRepository,
            queue: app.queue)
      ];
    } else if (obj is Sentinel) {
      container.children = [
        new SentinelViewElement(
            app.vm, obj.isolate, obj, app.events, app.notifications,
            queue: app.queue)
      ];
    } else {
      container.children = [
        new JSONViewElement(obj, app.notifications, queue: app.queue)
      ];
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
        new ClassTreeElement(
            app.vm, isolate, app.events, app.notifications, _classRepository)
      ];
    });
  }
}

class DebuggerPage extends MatchingPage {
  DebuggerPage(app) : super('debugger', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) async {
      container.children = [
        new DebuggerPageElement(
            isolate, _objectRepository, _scriptRepository, app.events)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
    assert(element != null);
  }

  @override
  void onUninstall() {
    super.onUninstall();
    container.children = const [];
  }
}

class ObjectStorePage extends MatchingPage {
  ObjectStorePage(app) : super('object-store', app);

  final DivElement container = new DivElement();

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) async {
      container.children = [
        new ObjectStoreViewElement(isolate.vm, isolate, app.events,
            app.notifications, _objectstoreRepository, _objectRepository)
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
            app.notifications, _isolateSampleProfileRepository)
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
            app.notifications, _isolateSampleProfileRepository)
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
            app.notifications, _allocationProfileRepository,
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

  @override
  void onUninstall() {
    super.onUninstall();
    app.stopGCEventListener();
    container.children = const [];
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
            _portsRepository, _objectRepository,
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
            app.notifications, _persistentHandlesRepository, _objectRepository,
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
            app.notifications, _heapSnapshotRepository, _objectRepository,
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

class LoggingPage extends MatchingPage {
  LoggingPage(app) : super('logging', app);

  final DivElement container = new DivElement();

  @override
  void onInstall() {
    element = container;
    container.children = const [];
    app.startLoggingEventListener();
  }

  @override
  void onUninstall() {
    super.onUninstall();
    container.children = const [];
    app.stopLoggingEventListener();
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
    getIsolate(uri).then((isolate) {
      container.children = [
        new LoggingPageElement(app.vm, isolate, app.events, app.notifications,
            queue: app.queue)
      ];
    });
  }
}

class ErrorViewPage extends Page {
  ErrorViewPage(app) : super(app);

  void onInstall() {
    element = new ErrorViewElement(
        app.notifications, app.lastErrorOrException as DartError,
        queue: app.queue);
  }

  void _visit(Uri uri) {
    assert(element != null);
    assert(canVisit(uri));
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
      new IsolateReconnectElement(
          app.vm,
          app.events,
          app.notifications,
          uri.queryParameters['isolateId'],
          Uri.parse(uri.queryParameters['originalUri']))
    ];
    assert(element != null);
    assert(canVisit(uri));
  }

  bool canVisit(Uri uri) => uri.path == 'isolate-reconnect';
}

class MetricsPage extends MatchingPage {
  MetricsPage(app) : super('metrics', app);

  final DivElement container = new DivElement();

  Isolate lastIsolate;

  void _visit(Uri uri) {
    super._visit(uri);
    getIsolate(uri).then((isolate) async {
      lastIsolate = isolate;
      container.children = const [];
      await _metricRepository.startSampling(isolate);
      container.children = [
        new MetricsPageElement(isolate.vm, isolate, app.events,
            app.notifications, _metricRepository,
            queue: app.queue)
      ];
    });
  }

  void onInstall() {
    if (element == null) {
      element = container;
    }
  }

  @override
  void onUninstall() {
    super.onUninstall();
    _metricRepository.stopSampling(lastIsolate);
    container.children = const [];
  }
}

class TimelinePage extends Page {
  TimelinePage(app) : super(app);

  void onInstall() {
    element = new TimelinePageElement(app.vm, app.events, app.notifications,
        queue: app.queue);
  }

  void _visit(Uri uri) {
    assert(canVisit(uri));
  }

  bool canVisit(Uri uri) => uri.path == 'timeline';
}
