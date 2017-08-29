// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of heap_snapshot;

class HeapSnapshot implements M.HeapSnapshot {
  ObjectGraph graph;
  DateTime timestamp;
  int get objects => graph.vertexCount;
  int get references => graph.edgeCount;
  int get size => graph.internalSize + graph.externalSize;
  HeapSnapshotDominatorNode dominatorTree;
  HeapSnapshotMergedDominatorNode mergedDominatorTree;
  List<MergedVertex> classReferences;

  static Future sleep([Duration duration = const Duration(microseconds: 0)]) {
    final Completer completer = new Completer();
    new Timer(duration, () => completer.complete());
    return completer.future;
  }

  Stream<List> loadProgress(S.Isolate isolate, S.RawHeapSnapshot raw) {
    final progress = new StreamController<List>.broadcast();
    progress.add(['', 0.0]);
    graph = new ObjectGraph(raw.chunks, raw.count);
    var signal = (String description, double p) {
      progress.add([description, p]);
      return sleep();
    };
    (() async {
      timestamp = new DateTime.now();
      final stream = graph.process();
      stream.listen((status) {
        status[1] /= 2.0;
        progress.add(status);
      });
      await stream.last;
      dominatorTree = new HeapSnapshotDominatorNode(isolate, graph.root);
      mergedDominatorTree =
          new HeapSnapshotMergedDominatorNode(isolate, graph.mergedRoot);
      classReferences = await buildMergedVertices(isolate, graph, signal);
      progress.close();
    }());
    return progress.stream;
  }

  Future<List<MergedVertex>> buildMergedVertices(
      S.Isolate isolate, ObjectGraph graph, signal) async {
    final cidToMergedVertex = {};

    int count = 0;
    final Stopwatch watch = new Stopwatch();
    watch.start();
    var needToUpdate = () {
      count++;
      if (((count % 256) == 0) && (watch.elapsedMilliseconds > 16)) {
        watch.reset();
        return true;
      }
      return false;
    };
    final length = graph.vertices.length;
    for (final vertex in graph.vertices) {
      if (vertex.vmCid == 0) {
        continue;
      }
      if (needToUpdate()) {
        await signal('', count * 50.0 / length + 50);
      }
      final cid = vertex.vmCid;
      MergedVertex source = cidToMergedVertex[cid];
      if (source == null) {
        cidToMergedVertex[cid] = source = new MergedVertex(isolate, cid);
      }

      source.instances++;
      source.shallowSize += vertex.shallowSize ?? 0;

      for (final vertex2 in vertex.successors) {
        if (vertex2.vmCid == 0) {
          continue;
        }
        final cid2 = vertex2.vmCid;
        MergedEdge edge = source.outgoingEdges[cid2];
        if (edge == null) {
          MergedVertex target = cidToMergedVertex[cid2];
          if (target == null) {
            cidToMergedVertex[cid2] = target = new MergedVertex(isolate, cid2);
          }
          edge = new MergedEdge(source, target);
          source.outgoingEdges[cid2] = edge;
          target.incomingEdges.add(edge);
        }
        edge.count++;
        // An over-estimate if there are multiple references to the same object.
        edge.shallowSize += vertex2.shallowSize ?? 0;
      }
    }
    return cidToMergedVertex.values.toList();
  }

  List<Future<S.ServiceObject>> getMostRetained(S.Isolate isolate,
      {int classId, int limit}) {
    var result = [];
    for (ObjectVertex v
        in graph.getMostRetained(classId: classId, limit: limit)) {
      result.add(
          isolate.getObjectByAddress(v.address).then((S.ServiceObject obj) {
        if (obj is S.HeapObject) {
          obj.retainedSize = v.retainedSize;
        } else {
          print("${obj.runtimeType} should be a HeapObject");
        }
        return obj;
      }));
    }
    return result;
  }
}

class HeapSnapshotDominatorNode implements M.HeapSnapshotDominatorNode {
  final ObjectVertex v;
  final S.Isolate isolate;
  S.HeapObject _preloaded;

  bool get isStack => v.isStack;

  Future<S.HeapObject> get object {
    if (_preloaded != null) {
      return new Future.value(_preloaded);
    } else {
      return isolate.getObjectByAddress(v.address).then((S.HeapObject obj) {
        return _preloaded = obj;
      });
    }
  }

  Iterable<HeapSnapshotDominatorNode> _children;
  Iterable<HeapSnapshotDominatorNode> get children {
    if (_children != null) {
      return _children;
    } else {
      return _children =
          new List.unmodifiable(v.dominatorTreeChildren().map((v) {
        return new HeapSnapshotDominatorNode(isolate, v);
      }));
    }
  }

  int get retainedSize => v.retainedSize;
  int get shallowSize => v.shallowSize;
  int get externalSize => v.externalSize;

  HeapSnapshotDominatorNode(S.Isolate isolate, ObjectVertex vertex)
      : isolate = isolate,
        v = vertex;
}

class HeapSnapshotMergedDominatorNode
    implements M.HeapSnapshotMergedDominatorNode {
  final MergedObjectVertex v;
  final S.Isolate isolate;

  bool get isStack => v.isStack;

  Future<S.HeapObject> get klass {
    return new Future.value(isolate.getClassByCid(v.vmCid));
  }

  Iterable<HeapSnapshotMergedDominatorNode> _children;
  Iterable<HeapSnapshotMergedDominatorNode> get children {
    if (_children != null) {
      return _children;
    } else {
      return _children =
          new List.unmodifiable(v.dominatorTreeChildren().map((v) {
        return new HeapSnapshotMergedDominatorNode(isolate, v);
      }));
    }
  }

  int get instanceCount => v.instanceCount;
  int get retainedSize => v.retainedSize;
  int get shallowSize => v.shallowSize;
  int get externalSize => v.externalSize;

  HeapSnapshotMergedDominatorNode(S.Isolate isolate, MergedObjectVertex vertex)
      : isolate = isolate,
        v = vertex;
}

class MergedEdge {
  final MergedVertex sourceVertex;
  final MergedVertex targetVertex;
  int count = 0;
  int shallowSize = 0;
  int retainedSize = 0;

  MergedEdge(this.sourceVertex, this.targetVertex);
}

class MergedVertex implements M.HeapSnapshotClassReferences {
  final int cid;
  final S.Isolate isolate;
  S.Class get clazz => isolate.getClassByCid(cid);
  int instances = 0;
  int shallowSize = 0;
  int retainedSize = 0;

  List<MergedEdge> incomingEdges = new List<MergedEdge>();
  Map<int, MergedEdge> outgoingEdges = new Map<int, MergedEdge>();

  Iterable<HeapSnapshotClassInbound> _inbounds;
  Iterable<HeapSnapshotClassInbound> get inbounds {
    if (_inbounds != null) {
      return _inbounds;
    } else {
      // It is important to keep the template.
      // https://github.com/dart-lang/sdk/issues/27144
      return _inbounds = new List<HeapSnapshotClassInbound>.unmodifiable(
          incomingEdges.map((edge) {
        return new HeapSnapshotClassInbound(this, edge);
      }));
    }
  }

  Iterable<HeapSnapshotClassOutbound> _outbounds;
  Iterable<HeapSnapshotClassOutbound> get outbounds {
    if (_outbounds != null) {
      return _outbounds;
    } else {
      // It is important to keep the template.
      // https://github.com/dart-lang/sdk/issues/27144
      return _outbounds = new List<HeapSnapshotClassOutbound>.unmodifiable(
          outgoingEdges.values.map((edge) {
        return new HeapSnapshotClassOutbound(this, edge);
      }));
    }
  }

  MergedVertex(this.isolate, this.cid);
}

class HeapSnapshotClassInbound implements M.HeapSnapshotClassInbound {
  final MergedVertex vertex;
  final MergedEdge edge;
  S.Class get source => edge.sourceVertex != vertex
      ? edge.sourceVertex.clazz
      : edge.targetVertex.clazz;
  int get count => edge.count;
  int get shallowSize => edge.shallowSize;
  int get retainedSize => edge.retainedSize;

  HeapSnapshotClassInbound(this.vertex, this.edge);
}

class HeapSnapshotClassOutbound implements M.HeapSnapshotClassOutbound {
  final MergedVertex vertex;
  final MergedEdge edge;
  S.Class get target => edge.sourceVertex != vertex
      ? edge.sourceVertex.clazz
      : edge.targetVertex.clazz;
  int get count => edge.count;
  int get shallowSize => edge.shallowSize;
  int get retainedSize => edge.retainedSize;

  HeapSnapshotClassOutbound(this.vertex, this.edge);
}
