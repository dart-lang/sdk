// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show JSON;

import 'dart:io';

import 'package:testing/src/run_tests.dart' show CommandLine;

main(List<String> arguments) async {
  CommandLine cl = CommandLine.parse(arguments);
  Set<String> fields = cl.commaSeparated("--fields=");
  if (fields.isEmpty) {
    fields.addAll(["uri", "offset", "json:error"]);
  }
  for (String filename in cl.arguments) {
    String json = await new File(filename).readAsString();
    Map<String, dynamic> data = JSON.decode(json) as Map<String, dynamic>;
    StringBuffer sb = new StringBuffer();
    bool isFirst = true;
    for (String field in fields) {
      if (!isFirst) {
        sb.write(":");
      }
      if (field.startsWith("json:")) {
        field = field.substring(5);
        sb.write(JSON.encode(data[field]));
      } else {
        sb.write(data[field]);
      }
      isFirst = false;
    }
    print("$sb");
  }
}
