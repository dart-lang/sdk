// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to query for code dependencies.
library compiler.tool.code_deps;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:compiler/src/info/info.dart';
import 'graph.dart';
import 'util.dart';

main(args) {
  if (args.length < 2) {
    print('usage: dart tool/code_deps.dart path-to-info.json <query>');
    print('   where <query> can be:');
    print('     - some_path elementA elementB');
    // TODO(sigmund): add other queries, such as 'all_paths'.
    exit(1);
  }

  var json = JSON.decode(new File(args[0]).readAsStringSync());
  var info = AllInfo.parseFromJson(json);
  var graph = graphFromInfo(info);

  var queryName = args[1];
  if (queryName == 'some_path') {
    if (args.length < 4) {
      print('missing arguments for `some_path`');
      exit(1);
    }
    var source =
        info.functions.firstWhere(_longNameMatcher(new RegExp(args[2])),
        orElse: () => null);
    var target =
        info.functions.firstWhere(_longNameMatcher(new RegExp(args[3])),
        orElse: () => null);
    print('query: some_path');
    if (source == null) {
      print("source '${args[2]}' not found in '${args[0]}'");
      exit(1);
    }
    print('source: ${longName(source)}');
    if (target == null) {
      print("target '${args[3]}' not found in '${args[0]}'");
      exit(1);
    }
    print('target: ${longName(target)}');
    var path = new SomePathQuery(source, target).run(graph);
    if (path.isEmpty) {
      print('result: no path found');
    } else {
      print('result:');
      for (int i = 0; i < path.length; i++) {
        print('  $i. ${longName(path[i])}');
      }
    }
  } else {
    print('unrecognized query: $queryName');
  }
}

/// A query supported by this tool.
abstract class Query {
  run(Graph<Info> graph);
}

/// Query that searches for a single path between two elements.
class SomePathQuery {
  /// The info associated with the source element.
  Info source;

  /// The info associated with the target element.
  Info target;

  SomePathQuery(this.source, this.target);

  List<Info> run(Graph<Info> graph) {
    var seen = {source: null};
    var queue = new Queue();
    queue.addLast(source);
    while (queue.isNotEmpty) {
      var node = queue.removeFirst();
      if (identical(node, target)) {
        var result = new Queue();
        while (node != null) {
          result.addFirst(node);
          node = seen[node];
        }
        return result.toList();
      }
      for (var neighbor in graph.targetsOf(node)) {
        if (seen.containsKey(neighbor)) continue;
        seen[neighbor] = node;
        queue.addLast(neighbor);
      }
    }
    return [];
  }
}

_longNameMatcher(RegExp regexp) => (e) => regexp.hasMatch(longName(e));
