// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/models.dart' as M;

/// Utility class for URIs generation.
abstract class Uris {
  static String _isolatePage(String path, M.IsolateRef isolate,
      {M.ObjectRef object}) {
    final parameters = {'isolateId': isolate.id};
    if (object != null) parameters['objectId'] = object.id;
    return '#' + new Uri(path: path, queryParameters: parameters).toString();
  }

  static String allocationProfiler(M.IsolateRef isolate) =>
      _isolatePage('/allocation-profiler', isolate);
  static String classTree(M.IsolateRef isolate) =>
      _isolatePage('/class-tree', isolate);
  static String cpuProfiler(M.IsolateRef isolate) =>
      _isolatePage('/profiler', isolate);
  static String cpuProfilerTable(M.IsolateRef isolate) =>
      _isolatePage('/profiler-table', isolate);
  static String debugger(M.IsolateRef isolate) =>
      _isolatePage('/debugger', isolate);
  static String flags() => '#/flags';
  static String heapMap(M.IsolateRef isolate) =>
      _isolatePage('/heap-map', isolate);
  static String heapSnapshot(M.IsolateRef isolate) =>
      _isolatePage('/heap-snapshot', isolate);
  static String inspect(M.IsolateRef isolate, {M.ObjectRef object, int pos}) {
    if (pos == null) {
      return _isolatePage('/inspect', isolate, object: object);
    }
    return _isolatePage('/inspect', isolate, object: object) + '---pos=${pos}';
  }

  static String logging(M.IsolateRef isolate) =>
      _isolatePage('/logging', isolate);
  static String metrics(M.IsolateRef isolate) =>
      _isolatePage('/metrics', isolate);
  static String nativeMemory() => '#/native-memory-profile';
  static String processSnapshot() => '#/process-snapshot';
  static String objectStore(M.IsolateRef isolate) =>
      _isolatePage('/object-store', isolate);
  static String persistentHandles(M.IsolateRef isolate) =>
      _isolatePage('/persistent-handles', isolate);
  static String ports(M.IsolateRef isolate) => _isolatePage('/ports', isolate);
  static String timeline() => '#/timeline';
  static String vm() => '#/vm';
  static String vmConnect() => '#/vm-connect';
}
