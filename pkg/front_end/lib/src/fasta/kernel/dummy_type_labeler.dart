// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show Constant, DartType;

import 'package:kernel/text/ast_to_text.dart' show NameSystem, Printer;

class DummyTypeLabeler {
  NameSystem nameSystem = new NameSystem();

  List<Object> labelType(DartType type) {
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer, syntheticNames: nameSystem).writeNode(type);
    return [buffer];
  }

  List<Object> labelConstant(Constant constant) {
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer, syntheticNames: nameSystem).writeNode(constant);
    return [buffer];
  }

  String get originMessages => "";
}
