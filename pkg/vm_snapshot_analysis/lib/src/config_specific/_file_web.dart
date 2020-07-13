// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

Future<Object> loadJsonFromFile(File input) async {
  final reader = FileReader();
  Map<String, dynamic> json;
  reader.onLoad.listen((_) {
    return json = jsonDecode(reader.result);
  });
  reader.readAsText(input);
  return json;
}
