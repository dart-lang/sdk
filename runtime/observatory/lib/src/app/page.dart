// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of app;

/// A [Page] controls the user interface of Observatory. At any given time
/// one page will be the current page. Pages are registered at startup.
/// When the user navigates within the application, each page is asked if it
/// can handle the current location, the first page to say yes, wins.
abstract class Page extends Observable {
  final ObservatoryApplication app;

  @observable ObservatoryElement element;
  @observable ObservableMap args;

  Page(this.app);

  /// Called when the page is installed, this callback must initialize
  /// [element].
  void onInstall();

  /// Called when the page is uninstalled, this callback must clear
  /// [element].
  void onUninstall() {
    element = null;
  }

  /// Called when the page should update its state based on [url].
  /// NOTE: Only called when the page is installed.
  void visit(String url, Map argsMap) {
    args = toObservable(argsMap);
    _visit(url);
  }

  // Overridden by subclasses.
  void _visit(String url);

  /// Called to test whether this page can visit [url].
  bool canVisit(String url);
}

/// A general service object viewer.
class ServiceObjectPage extends Page {
  ServiceObjectPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      /// Lazily create page.
      element = new Element.tag('service-view');
    }
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    if (url == '') {
      // Nothing requested.
      return;
    }
    /// Request url from VM and display it.
    app.vm.getDeprecated(url).then((obj) {
      ServiceObjectViewElement serviceElement = element;
      serviceElement.object = obj;
    }).catchError((e) {
      Logger.root.severe('ServiceObjectPage visit error: $e');
    });
  }

  /// Catch all.
  bool canVisit(String url) => true;
}

class IsolateSuffixPage extends Page {
  final String pagePrefix;
  final String elementTagName;
  String _isolateId;
  String get isolateId => _isolateId;
  IsolateSuffixPage(this.pagePrefix, this.elementTagName, app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag(elementTagName);
    }
  }

  void _visit(String url) {
    assert(url != null);
    assert(canVisit(url));
    _isolateId = url.substring(pagePrefix.length);
  }

  Future<Isolate> getIsolate() {
    return app.vm.getIsolate(isolateId).catchError((e) {
      Logger.root.severe('$pagePrefix visit error: $e');
      return e;
    });
  }

  bool canVisit(String url) => url.startsWith(pagePrefix);
}


/// Class tree page.
class ClassTreePage extends IsolateSuffixPage {
  ClassTreePage(app) : super('class-tree/', 'class-tree', app);

  void _visit(String url) {
    super._visit(url);
    getIsolate().then((isolate) {
      if (element != null) {
        /// Update the page.
        ClassTreeElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class DebuggerPage extends IsolateSuffixPage {
  DebuggerPage(app) : super('debugger/', 'debugger-page', app);

  void _visit(String url) {
    super._visit(url);
    getIsolate().then((isolate) {
      if (element != null) {
        /// Update the page.
        DebuggerPageElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class CpuProfilerPage extends IsolateSuffixPage {
  CpuProfilerPage(app) : super('profiler/', 'cpu-profile', app);

  void _visit(String url) {
    super._visit(url);
    getIsolate().then((isolate) {
      if (element != null) {
        /// Update the page.
        CpuProfileElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class AllocationProfilerPage extends IsolateSuffixPage {
  AllocationProfilerPage(app)
      : super('allocation-profiler/', 'heap-profile', app);

  void _visit(String url) {
    super._visit(url);
    getIsolate().then((isolate) {
      if (element != null) {
        /// Update the page.
        HeapProfileElement page = element;
        page.isolate = isolate;
      }
    });
  }
}

class HeapMapPage extends IsolateSuffixPage {
  HeapMapPage(app) : super('heap-map/', 'heap-map', app);

  void _visit(String url) {
    super._visit(url);
    getIsolate().then((isolate) {
      if (element != null) {
        /// Update the page.
        HeapMapElement page = element;
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

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    (element as ServiceObjectViewElement).object = app.lastErrorOrException;
  }

  bool canVisit(String url) => url.startsWith('error/');
}

class VMConnectPage extends Page {
  VMConnectPage(app) : super(app);

  void onInstall() {
    if (element == null) {
      element = new Element.tag('vm-connect');
    }
    assert(element != null);
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
  }

  bool canVisit(String url) => url.startsWith('vm-connect/');
}

class MetricsPage extends Page {
  static RegExp _matcher = new RegExp(r'isolates/.*/metrics');
  static RegExp _isolateMatcher = new RegExp(r'isolates/.*/');

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

  String _isolateId(String url) {
    // Grab isolate prefix.
    String isolateId = _isolateMatcher.stringMatch(url);
    // Remove the trailing slash.
    return isolateId.substring(0, isolateId.length - 1);
  }

  void _visit(String url) {
    assert(element != null);
    assert(canVisit(url));
    app.vm.getIsolate(_isolateId(url)).then((i) {
      (element as MetricsPageElement).isolate = i;
    });
  }

  bool canVisit(String url) => _matcher.hasMatch(url);
}
