// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to query for code dependencies. Currently this tool only
/// supports the `some_path` query, which gives you the shortest path for how
/// one function depends on another.
///
/// You can run this tool as follows:
/// ```bash
/// pub global activate dart2js_info
/// dart2js_info_code_deps out.js.info.json some_path main foo
/// ```
///
/// The arguments to the query are regular expressions that can be used to
/// select a single element in your program. If your regular expression is too
/// general and has more than one match, this tool will pick
/// the first match and ignore the rest. Regular expressions are matched against
/// a fully qualified element name, which includes the library and class name
/// (if any) that contains it. A typical qualified name is of this form:
///
///     libraryName::ClassName.elementName
///
/// If the name of a function your are looking for is unique enough, it might be
/// sufficient to just write that name as your regular expression.
library dart2js_info.bin.code_deps;

import 'dart:collection';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/graph.dart';
import 'package:dart2js_info/src/util.dart';

main(args) async {
  if (args.length < 2) {
    print('usage: dart2js_info_code_deps path-to.info.json <query>');
    print('   where <query> can be:');
    print('     - some_path <element-regexp-1> <element-regexp-2>');
    // TODO(sigmund): add other queries, such as 'all_paths'.
    exit(1);
  }

  var info = await infoFromFile(args.first);
  var graph = graphFromInfo(info);

  var queryName = args[1];
  if (queryName == 'some_path') {
    if (args.length < 4) {
      print('missing arguments for `some_path`');
      exit(1);
    }
    var source = info.functions
        .firstWhere(_longNameMatcher(new RegExp(args[2])), orElse: () => null);
    var target = info.functions
        .firstWhere(_longNameMatcher(new RegExp(args[3])), orElse: () => null);
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
