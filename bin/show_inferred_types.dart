// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Simple script that shows the inferred types of a function.
library compiler.tool.show_inferred_types;

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';

main(args) {
  if (args.length < 2) {
    var scriptName = Platform.script.pathSegments.last;
    print('usage: dart $scriptName <info.json> <function-name-regex> [-l]');
    print('  -l: print the long qualified name for a function.');
    exit(1);
  }

  var showLongName = args.length > 2 && args[2] == '-l';

  var json = jsonDecode(new File(args[0]).readAsStringSync());
  var info = new AllInfoJsonCodec().decode(json);
  var nameRegExp = new RegExp(args[1]);
  matches(e) => nameRegExp.hasMatch(longName(e));

  bool noResults = true;
  void showMethods() {
    var sources = info.functions.where(matches).toList();
    if (sources.isEmpty) return;
    noResults = false;
    for (var s in sources) {
      var params = s.parameters.map((p) => '${p.name}: ${p.type}').join(', ');
      var name = showLongName ? longName(s) : s.name;
      print('$name($params): ${s.returnType}');
    }
  }

  void showFields() {
    var sources = info.fields.where(matches).toList();
    if (sources.isEmpty) return;
    noResults = false;
    for (var s in sources) {
      var name = showLongName ? longName(s) : s.name;
      print('$name: ${s.inferredType}');
    }
  }

  showMethods();
  showFields();
  if (noResults) {
    print('error: no function or field that matches ${args[1]} was found.');
    exit(1);
  }
}
