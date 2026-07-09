// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

import 'find_sdk_dills.dart';

void main() {
  List<File> dills = findSdkDills();
  print("Found ${dills.length} dills!");

  List<File> errors = [];
  for (File dill in dills) {
    if (!tryFile(dill)) {
      errors.add(dill);
    }
  }
  if (errors.isEmpty) {
    print("All OK.");
  } else {
    print("Errors when reading:");
    for (File error in errors) {
      print(error);
    }
    exitCode = 1;
  }
}

bool tryFile(File dill) {
  print("Reading $dill");
  Uint8List bytes = dill.readAsBytesSync();

  try {
    Component component = new Component();
    new BinaryBuilderWithMetadata(bytes).readComponent(component);
    LocationTester tester = new LocationTester();
    component.accept(tester);
    return tester.ok;
  } catch (e, st) {
    print("Error for $dill:");
    print(e);
    print(st);
    print("");
    print("--------------------");
    print("");
    return false;
  }
}

class LocationTester extends RecursiveVisitor {
  bool ok = true;

  @override
  void defaultTreeNode(TreeNode node) {
    super.defaultTreeNode(node);
    try {
      node.location;
    } catch (e) {
      ok = false;
      print("Failure on $node: $e");
      try {
        print(node.parent?.location);
      } catch (e) {}
    }
  }
}
