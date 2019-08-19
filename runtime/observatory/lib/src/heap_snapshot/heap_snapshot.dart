// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of heap_snapshot;

// TODO(observatory): The two levels of interface (SnapshotGraph + HeapSnapshot)
// probably aren't providing any value after the removal of class-based
// reference merging that only happen in the second layer. Consider flattening.

class HeapSnapshot implements M.HeapSnapshot {
  SnapshotGraph graph;
  DateTime timestamp;
  int get size => graph.shallowSize + graph.externalSize;
  HeapSnapshotMergedDominatorNode mergedDominatorTree;
  List<SnapshotClass> classes;
  SnapshotObject get root => graph.root;
  List<ByteData> chunks;

  Stream<String> loadProgress(S.Isolate isolate, List<ByteData> chunks) {
    final progress = new StreamController<String>.broadcast();
    progress.add('Loading...');
    this.chunks = chunks;
    graph = new SnapshotGraph(chunks);
    (() async {
      timestamp = new DateTime.now();
      final stream = graph.process();
      stream.listen((status) {
        progress.add(status);
      });
      await stream.last;
      mergedDominatorTree =
          new HeapSnapshotMergedDominatorNode(isolate, graph.mergedRoot, null);
      classes = graph.classes.toList();
      progress.close();
    }());
    return progress.stream;
  }
}

class HeapSnapshotMergedDominatorNode
    implements M.HeapSnapshotMergedDominatorNode {
  final MergedObjectVertex v;
  final S.Isolate isolate;

  SnapshotClass get klass => v.klass;

  final _parent;
  HeapSnapshotMergedDominatorNode get parent => _parent ?? this;

  Iterable<HeapSnapshotMergedDominatorNode> _children;
  Iterable<HeapSnapshotMergedDominatorNode> get children {
    if (_children != null) {
      return _children;
    } else {
      return _children =
          new List.unmodifiable(v.dominatorTreeChildren().map((v) {
        return new HeapSnapshotMergedDominatorNode(isolate, v, this);
      }));
    }
  }

  List<SnapshotObject> get objects => v.objects;

  int get instanceCount => v.instanceCount;
  int get retainedSize => v.retainedSize;
  int get shallowSize => v.shallowSize;
  int get externalSize => v.externalSize;

  String get description => "$instanceCount instances of ${klass.name}";

  HeapSnapshotMergedDominatorNode(
      S.Isolate isolate, MergedObjectVertex vertex, this._parent)
      : isolate = isolate,
        v = vertex;
}
