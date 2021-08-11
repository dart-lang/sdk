// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command to query for code dependencies. Currently this tool only
/// supports the `some_path` query, which gives you the shortest path for how
/// one function depends on another.
///
/// You can run this tool as follows:
/// ```bash
/// pub global activate dart2js_info
/// dart2js_info code_deps some_path out.js.info.json main foo
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

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/graph.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

class CodeDepsCommand extends Command<void> with PrintUsageException {
  final String name = "code_deps";
  final String description = "";

  CodeDepsCommand() {
    addSubcommand(new _SomePathQuery());
  }
}

class _SomePathQuery extends Command<void> with PrintUsageException {
  final String name = "some_path";
  final String description = "find a call-graph path between two elements.";

  @override
  void run() async {
    var args = argResults.rest;
    if (args.length < 3) {
      usageException("Missing arguments for some_path, expected: "
          "info.data <element-regexp-1> <element-regexp-2>");
      return;
    }

    var info = await infoFromFile(args.first);
    var graph = graphFromInfo(info);

    var source = info.functions
        .firstWhere(_longNameMatcher(new RegExp(args[1])), orElse: () => null);
    var target = info.functions
        .firstWhere(_longNameMatcher(new RegExp(args[2])), orElse: () => null);
    print('query: some_path');
    if (source == null) {
      usageException("source '${args[1]}' not found in '${args[0]}'");
    }
    print('source: ${longName(source)}');
    if (target == null) {
      usageException("target '${args[2]}' not found in '${args[0]}'");
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
    var seen = <Info, Info>{source: null};
    var queue = new Queue<Info>();
    queue.addLast(source);
    while (queue.isNotEmpty) {
      var node = queue.removeFirst();
      if (identical(node, target)) {
        var result = new Queue<Info>();
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

typedef bool LongNameMatcher(FunctionInfo info);

LongNameMatcher _longNameMatcher(RegExp regexp) =>
    (e) => regexp.hasMatch(longName(e));
