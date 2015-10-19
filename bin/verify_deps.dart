// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tools verifies that all elements that are included in the output are
/// reachable from the program entrypoint. If there are elements that are not
/// reachable from the entrypoint, then this indicates that we are missing
/// dependencies. If all functions are reachable from the entrypoint, this
/// script will return with exitcode 0. Otherwise it will list the unreachable
/// functions and return with exitcode 1.
library dart2js_info.bin.verify_deps;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/graph.dart';
import 'package:dart2js_info/src/util.dart';

Future main(List<String> args) async {
  if (args.length > 1) {
    printUsage();
    exit(1);
  }
  var json = JSON.decode(await new File(args[0]).readAsString());
  var info = new AllInfoJsonCodec().decode(json);
  var graph = graphFromInfo(info);
  var entrypoint = info.program.entrypoint;
  var reachables = findReachable(graph, entrypoint);

  var functionsAndFields = []..addAll(info.functions)..addAll(info.fields);
  var unreachables =
      functionsAndFields.where((func) => !reachables.contains(func));
  if (unreachables.isNotEmpty) {
    unreachables.forEach((x) => print(longName(x)));
    exit(1);
  } else {
    print('all elements are reachable from the entrypoint');
  }
}

/// Finds the set of nodes reachable from [start] in [graph].
Set<Info> findReachable(Graph<Info> graph, Info start) =>
    new Set.from(graph.preOrder(start));

void printUsage() {
  print('usage: dart2js_info_verify_deps <info file>');
}
