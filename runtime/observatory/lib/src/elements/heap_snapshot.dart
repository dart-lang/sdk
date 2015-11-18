// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library heap_snapshot_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:observatory/app.dart';
import 'package:observatory/service.dart';
import 'package:observatory/elements.dart';
import 'package:observatory/object_graph.dart';
import 'package:polymer/polymer.dart';
import 'package:logging/logging.dart';

class DominatorTreeRow extends TableTreeRow {
  final ObjectVertex vertex;
  final HeapSnapshot snapshot;

  var _domTreeChildren;
  get domTreeChildren {
    if (_domTreeChildren == null) {
      _domTreeChildren = vertex.dominatorTreeChildren();
    }
    return _domTreeChildren;
  }

  DominatorTreeRow(TableTree tree,
                   TableTreeRow parent,
                   this.vertex,
                   this.snapshot)
      : super(tree, parent) {
  }

  bool hasChildren() {
    return domTreeChildren.length > 0;
  }

  static const int kMaxChildren = 100;
  static const int kMinRetainedSize = 4096;

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      domTreeChildren.sort((a, b) => b.retainedSize - a.retainedSize);
      int includedChildren = 0;
      for (var childVertex in domTreeChildren) {
        if (childVertex.retainedSize >= kMinRetainedSize) {
          if (++includedChildren <= kMaxChildren) {
            var row = new DominatorTreeRow(tree, this, childVertex, snapshot);
            children.add(row);
          }
        }
      }
    }

    var firstColumn = flexColumns[0];
    firstColumn.style.justifyContent = 'flex-start';
    firstColumn.style.position = 'relative';
    firstColumn.style.alignItems = 'center';
    firstColumn.style.setProperty('overflow-x', 'hidden');

    var percentRetained = vertex.retainedSize / snapshot.graph.size;
    var percentNode = new SpanElement();
    percentNode.text =  Utils.formatPercentNormalized(percentRetained);
    percentNode.style.minWidth = '5em';
    percentNode.style.textAlign = 'right';
    percentNode.title = "Percent of heap being retained";
    percentNode.style.display = 'inline-block';
    firstColumn.children.add(percentNode);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.style.display = 'inline-block';
    firstColumn.children.add(gap);

    AnyServiceRefElement objectRef = new Element.tag("any-service-ref");
    snapshot.isolate.getObjectByAddress(vertex.address).then((obj) {
      objectRef.ref = obj;
    });
    objectRef.style.alignSelf = 'center';
    firstColumn.children.add(objectRef);

    var secondColumn = flexColumns[1];
    secondColumn.style.justifyContent = 'flex-end';
    secondColumn.style.position = 'relative';
    secondColumn.style.alignItems = 'center';
    secondColumn.style.paddingRight = '0.5em';
    secondColumn.text = Utils.formatSize(vertex.retainedSize);
  }
}


class MergedVerticesRow extends TableTreeRow {
  final Isolate isolate;
  final List<MergedVertex> mergedVertices;

  MergedVerticesRow(TableTree tree,
                   TableTreeRow parent,
                   this.isolate,
                   this.mergedVertices)
      : super(tree, parent) {
  }

  bool hasChildren() {
    return mergedVertices.length > 0;
  }

  void onShow() {
    super.onShow();

    if (children.length == 0) {
      mergedVertices.sort((a, b) => b.shallowSize - a.shallowSize);
      for (var mergedVertex in mergedVertices) {
        if (mergedVertex.instances > 0) {
          var row = new MergedVertexRow(tree, this, isolate, mergedVertex);
          children.add(row);
        }
      }
    }
  }
}

class MergedVertexRow extends TableTreeRow {
  final Isolate isolate;
  final MergedVertex vertex;

  MergedVertexRow(TableTree tree,
                  TableTreeRow parent,
                  this.isolate,
                  this.vertex)
      : super(tree, parent) {
  }

  bool hasChildren() {
    return vertex.outgoingEdges.length > 0 ||
           vertex.incomingEdges.length > 0;
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      children.add(new MergedEdgesRow(tree, this, isolate, vertex, true));
      children.add(new MergedEdgesRow(tree, this, isolate, vertex, false));
    }


    var firstColumn = flexColumns[0];
    firstColumn.style.justifyContent = 'flex-start';
    firstColumn.style.position = 'relative';
    firstColumn.style.alignItems = 'center';

    var percentNode = new SpanElement();
    percentNode.text = "${vertex.instances} instances of";
    percentNode.style.minWidth = '5em';
    percentNode.style.textAlign = 'right';
    firstColumn.children.add(percentNode);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.style.display = 'inline-block';
    firstColumn.children.add(gap);

    ClassRefElement classRef = new Element.tag("class-ref");
    classRef.ref = isolate.getClassByCid(vertex.cid);
    classRef.style.alignSelf = 'center';
    firstColumn.children.add(classRef);

    var secondColumn = flexColumns[1];
    secondColumn.style.justifyContent = 'flex-end';
    secondColumn.style.position = 'relative';
    secondColumn.style.alignItems = 'center';
    secondColumn.style.paddingRight = '0.5em';
    secondColumn.text = Utils.formatSize(vertex.shallowSize);
  }
}

class MergedEdgesRow extends TableTreeRow {
  final Isolate isolate;
  final MergedVertex vertex;
  final bool outgoing;

  MergedEdgesRow(TableTree tree,
                 TableTreeRow parent,
                 this.isolate,
                 this.vertex,
                 this.outgoing)
      : super(tree, parent) {
  }

  bool hasChildren() {
    return outgoing
            ? vertex.outgoingEdges.length > 0
            : vertex.incomingEdges.length > 0;
  }

  void onShow() {
    super.onShow();
    if (children.length == 0) {
      if (outgoing) {
        var outgoingEdges = vertex.outgoingEdges.values.toList();
        outgoingEdges.sort((a, b) => b.shallowSize - a.shallowSize);
        for (var edge in outgoingEdges) {
          if (edge.count > 0) {
            var row = new MergedEdgeRow(tree, this, isolate, edge, true);
            children.add(row);
          }
        }
      } else {
        vertex.incomingEdges.sort((a, b) => b.shallowSize - a.shallowSize);
        for (var edge in vertex.incomingEdges) {
          if (edge.count > 0) {
            var row = new MergedEdgeRow(tree, this, isolate, edge, false);
            children.add(row);
          }
        }
      }
    }

    var count = 0;
    var shallowSize = 0;
    var edges = outgoing ? vertex.outgoingEdges.values : vertex.incomingEdges;
    for (var edge in edges) {
      count += edge.count;
      shallowSize += edge.shallowSize;
    }

    var firstColumn = flexColumns[0];
    firstColumn.style.justifyContent = 'flex-start';
    firstColumn.style.position = 'relative';
    firstColumn.style.alignItems = 'center';

    var countNode = new SpanElement();
    countNode.text = "$count";
    countNode.style.minWidth = '5em';
    countNode.style.textAlign = 'right';
    firstColumn.children.add(countNode);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.style.display = 'inline-block';
    firstColumn.children.add(gap);

    var labelNode = new SpanElement();
    labelNode.text = outgoing ? "Outgoing references" : "Incoming references";
    firstColumn.children.add(labelNode);

    var secondColumn = flexColumns[1];
    secondColumn.style.justifyContent = 'flex-end';
    secondColumn.style.position = 'relative';
    secondColumn.style.alignItems = 'center';
    secondColumn.style.paddingRight = '0.5em';
    secondColumn.text = Utils.formatSize(shallowSize);
  }
}

class MergedEdgeRow extends TableTreeRow {
  final Isolate isolate;
  final MergedEdge edge;
  final bool outgoing;

  MergedEdgeRow(TableTree tree,
                TableTreeRow parent,
                this.isolate,
                this.edge,
                this.outgoing)
      : super(tree, parent) {
  }

  bool hasChildren() => false;

  void onShow() {
    super.onShow();

    var firstColumn = flexColumns[0];
    firstColumn.style.justifyContent = 'flex-start';
    firstColumn.style.position = 'relative';
    firstColumn.style.alignItems = 'center';

    var percentNode = new SpanElement();
    var preposition = outgoing ? "to" : "from";
    percentNode.text = "${edge.count} references $preposition instances of";
    percentNode.style.minWidth = '5em';
    percentNode.style.textAlign = 'right';
    firstColumn.children.add(percentNode);

    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.style.display = 'inline-block';
    firstColumn.children.add(gap);

    MergedVertex v = outgoing ? edge.target : edge.source;
    if (v.cid == 0) {
      var rootName = new SpanElement();
      rootName.text = '<root>';
      firstColumn.children.add(rootName);
    } else {
      ClassRefElement classRef = new Element.tag("class-ref");
      classRef.ref = isolate.getClassByCid(v.cid);
      classRef.style.alignSelf = 'center';
      firstColumn.children.add(classRef);
    }

    var secondColumn = flexColumns[1];
    secondColumn.style.justifyContent = 'flex-end';
    secondColumn.style.position = 'relative';
    secondColumn.style.alignItems = 'center';
    secondColumn.style.paddingRight = '0.5em';
    secondColumn.text = Utils.formatSize(edge.shallowSize);
  }
}


class MergedEdge {
  final MergedVertex source;
  final MergedVertex target;
  int count = 0;
  int shallowSize = 0;
  int retainedSize = 0;

  MergedEdge(this.source, this.target);
}

class MergedVertex {
  final int cid;
  int instances = 0;
  int shallowSize = 0;
  int retainedSize = 0;

  List<MergedEdge> incomingEdges = new List<MergedEdge>();
  Map<int, MergedEdge> outgoingEdges = new Map<int, MergedEdge>();

  MergedVertex(this.cid);
}


Future<List<MergedVertex>> buildMergedVertices(ObjectGraph graph) async {
  Logger.root.info("Start merge vertices");

  var cidToMergedVertex = {};

  for (var vertex in graph.vertices) {
    var cid = vertex.vmCid;
    MergedVertex source = cidToMergedVertex[cid];
    if (source == null) {
      cidToMergedVertex[cid] = source = new MergedVertex(cid);
    }

    source.instances++;
    source.shallowSize += (vertex.shallowSize == null ? 0 : vertex.shallowSize);

    for (var vertex2 in vertex.successors) {
      var cid2 = vertex2.vmCid;
      MergedEdge edge = source.outgoingEdges[cid2];
      if (edge == null) {
        MergedVertex target = cidToMergedVertex[cid2];
        if (target == null) {
          cidToMergedVertex[cid2] = target = new MergedVertex(cid2);
        }
        edge = new MergedEdge(source, target);
        source.outgoingEdges[cid2] = edge;
        target.incomingEdges.add(edge);
      }
      edge.count++;
      // An over-estimate if there are multiple references to the same object.
      edge.shallowSize += vertex2.shallowSize == null ? 0 : vertex2.shallowSize;
    }
  }

  Logger.root.info("End merge vertices");

  return cidToMergedVertex.values.toList();
}

@CustomTag('heap-snapshot')
class HeapSnapshotElement extends ObservatoryElement {
  @published Isolate isolate;
  @observable HeapSnapshot snapshot;

  @published String state = 'Requested';
  @published String analysisSelector = 'DominatorTree';

  HeapSnapshotElement.created() : super.created();

  void analysisSelectorChanged(oldValue) {
    _update();
  }

  void isolateChanged(oldValue) {
    if (isolate == null) return;

    if (isolate.latestSnapshot == null) {
      _getHeapSnapshot();
    } else {
      snapshot = isolate.latestSnapshot;
      state = 'Loaded';
      _update();
    }
  }

  Future refresh() {
    return _getHeapSnapshot();
  }

  Future _getHeapSnapshot() {
    var completer = new Completer();
    state = "Requesting heap snapshot...";
    isolate.getClassRefs();
    var stopwatch = new Stopwatch()..start();
    isolate.fetchHeapSnapshot().listen((event) {
      if (event is String) {
        print("${stopwatch.elapsedMilliseconds} $event");
        state = event;
      } else if (event is HeapSnapshot) {
        snapshot = event;
        state = 'Loaded';
        completer.complete(snapshot);
        _update();
      } else {
        throw "Unexpected event $event";
      }
    });
    return completer.future;
  }

  void _update() {
    if (snapshot == null) {
      return;
    }

    switch(analysisSelector) {
    case 'DominatorTree':
      _buildDominatorTree();
      break;
    case 'MergeByClass':
      _buildMergedVertices();
      break;
    }
  }

  void _buildDominatorTree() {
    var tableBody = shadowRoot.querySelector('#treeBody');
    var tree = new TableTree(tableBody, 2);
    var rootRow =
        new DominatorTreeRow(tree, null, snapshot.graph.root, snapshot);
    tree.initialize(rootRow);
    return;
  }

  void _buildMergedVertices() {
    state = 'Grouping...';
    var tableBody = shadowRoot.querySelector('#treeBody');
    var tree = new TableTree(tableBody, 2);
    tableBody.children.clear();

    new Future.delayed(const Duration(milliseconds: 500), () {
      buildMergedVertices(snapshot.graph).then((vertices) {
        state = 'Loaded';
        var rootRow = new MergedVerticesRow(tree, null, isolate, vertices);
        tree.initialize(rootRow);
      });
    });
  }
}
