// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library with code coverage models.
library runtime.coverage.model;

import 'dart:collection' show SplayTreeMap;

import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:analyzer/src/generated/ast.dart' show AstNode;

import 'utils.dart';


/// Contains information about the application.
class AppInfo {
  final nodeStack = new List<NodeInfo>();
  final units = new List<UnitInfo>();
  final pathToFile = new Map<String, UnitInfo>();
  NodeInfo currentNode;
  int nextId = 0;

  void enterUnit(String path, String content) {
    var unit = new UnitInfo(this, path, content);
    units.add(unit);
    currentNode = unit;
  }

  void enter(String kind, String name) {
    nodeStack.add(currentNode);
    currentNode = new NodeInfo(this, currentNode, kind, name);
  }

  void leave() {
    currentNode = nodeStack.removeLast();
  }

  int addNode(AstNode node) {
    return currentNode.addNode(node);
  }

  void write(StringSink sink, Set<int> executedIds) {
    sink.writeln('{');
    units.fold(null, (prev, unit) {
      if (prev != null) sink.writeln(',');
      return unit..write(sink, executedIds, '  ');
    });
    sink.writeln();
    sink.writeln('}');
  }
}

/// Information about some node - unit, class, method, function.
class NodeInfo {
  final AppInfo appInfo;
  final NodeInfo parent;
  final String kind;
  final String name;
  final idToRange = new SplayTreeMap<int, SourceRange>();
  final children = <NodeInfo>[];

  NodeInfo(this.appInfo, this.parent, this.kind, this.name) {
    if (parent != null) {
      parent.children.add(this);
    }
  }

  int addNode(AstNode node) {
    var id = appInfo.nextId++;
    var range = new SourceRange(node.offset, node.length);
    idToRange[id] = range;
    return id;
  }

  void write(StringSink sink, Set<int> executedIds, String prefix) {
    sink.writeln('$prefix"$name": {');
    // Kind.
    sink.writeln('$prefix  "kind": "$kind",');
    // Print children.
    if (children.isNotEmpty) {
      sink.writeln('$prefix  "children": {');
      children.fold(null, (prev, child) {
        if (prev != null) sink.writeln(',');
        return child..write(sink, executedIds, '$prefix    ');
      });
      sink.writeln();
      sink.writeln('$prefix  }');
    }
    // Print source and line ranges.
    if (children.isEmpty) {
      sink.write('$prefix  "ranges": [');
      var rangePrinter = new RangePrinter(unit, sink, executedIds);
      idToRange.forEach(rangePrinter.handle);
      rangePrinter.printRange();
      sink.writeln(']');
    }
    // Close this node.
    sink.write('$prefix}');
  }

  UnitInfo get unit => parent.unit;
}

/// Helper for printing merged source/line intervals.
class RangePrinter {
  final UnitInfo unit;
  final StringSink sink;
  final Set<int> executedIds;

  bool first = true;
  int startId = -1;
  int startOffset = -1;
  int endId = -1;
  int endOffset = -1;

  RangePrinter(this.unit, this.sink, this.executedIds);

  handle(int id, SourceRange range) {
    if (executedIds.contains(id)) {
      printRange();
    } else {
      if (endId == id - 1) {
        endId = id;
        endOffset = range.end;
      } else {
        startId = id;
        endId = id;
        startOffset = range.offset;
        endOffset = range.end;
      }
    }
  }

  void printRange() {
    if (endId == -1) return;
    printSeparator();
    var startLine = unit.getLine(startOffset);
    var endLine = unit.getLine(endOffset);
    sink.write('$startOffset,$endOffset,$startLine,$endLine');
    startId = startOffset = startLine = -1;
    endId = endOffset = endLine = -1;
  }

  void printSeparator() {
    if (first) {
      first = false;
    } else {
      sink.write(', ');
    }
  }
}

/// Contains information about the single unit of the application.
class UnitInfo extends NodeInfo {
  List<int> lineOffsets;

  UnitInfo(AppInfo appInfo, String path, String content)
      : super(appInfo, null, 'unit', path) {
    lineOffsets = getLineOffsets(content);
  }

  UnitInfo get unit => this;

  int getLine(int offset) {
    return binarySearch(lineOffsets, (x) => x >= offset);
  }
}
