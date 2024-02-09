// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

import 'find_sdk_dills.dart';

void main() {
  List<File> dills = findSdkDills();
  print("Found ${dills.length} dills!");

  List<File> errors = [];
  for (File dill in dills) {
    if (!canRead(dill)) {
      errors.add(dill);
    }
  }
  if (errors.isEmpty) {
    print("Read all OK.");
  } else {
    print("Errors when reading:");
    for (File error in errors) {
      print(error);
    }
    exitCode = 1;
  }
}

bool canRead(File dill) {
  print("Reading $dill");
  List<int> bytes = dill.readAsBytesSync();

  try {
    Component component = new Component();
    new BinaryBuilderWithMetadata(bytes).readComponent(component);
    int libs = component.libraries.length;

    component = new Component();
    new BinaryBuilderWithMetadata(bytes).readComponentSource(component);

    component = new Component();
    new BinaryBuilder(bytes).readComponent(component);
    if (libs != component.libraries.length) {
      throw "Didn't get the same number of libraries: $libs when reading with "
          "BinaryBuilderWithMetadata and ${component.libraries.length} "
          "when reading with BinaryBuilder";
    }

    component = new Component();
    new BinaryBuilder(bytes).readComponentSource(component);

    return true;
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
