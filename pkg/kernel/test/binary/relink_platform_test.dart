// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/find_referenced_libraries.dart';

import '../relink_test.dart';
import 'find_sdk_dills.dart';

void main() {
  List<File> dills = findSdkDills();
  print("Found ${dills.length} dills!");

  for (File dill in dills) {
    readAndRelink(dill);
  }
}

void readAndRelink(File dill) {
  print("Reading $dill");
  Uint8List bytes = dill.readAsBytesSync();

  try {
    // Loading a component it should be self-contained.
    Component component1 = new Component();
    new BinaryBuilder(bytes,
            alwaysCreateNewNamedNodes: true, disableLazyReading: true)
        .readComponent(component1);
    checkReachable(component1);

    // Loading a component it should be self-contained.
    Component component2 = new Component(nameRoot: component1.root);
    new BinaryBuilder(bytes,
            alwaysCreateNewNamedNodes: true, disableLazyReading: true)
        .readComponent(component2);
    checkReachable(component2);

    // Now that we read "component 2" on top of "component 1" the 1-version is
    // no longer self-contained.
    try {
      checkReachable(component1);
      throw "Expected this one to fail.";
    } catch (e) {
      // Expected.
    }

    // Relinking it it should be back to being self contained though.
    component1.relink();
    checkReachable(component1);

    // Now that component 1 is relinked component 2 is no longer self contained.
    try {
      checkReachable(component2);
      throw "Expected this one to fail.";
    } catch (e) {
      // Expected.
    }

    // But relinking makes it self-contained again.
    component2.relink();
    checkReachable(component2);
  } catch (e, st) {
    print("Error for $dill:");
    print(e);
    print(st);
    print("");
    print("--------------------");
    print("");
    exitCode = 1;
  }
}

void checkReachable(Component component) {
  expectReachable(
      findAllReferencedLibraries(component.libraries), component.libraries);
  expectReachable(
      findAllReferencedLibraries(component.libraries,
          collectViaReferencesToo: true),
      component.libraries);
  if (duplicateLibrariesReachable(component.libraries)) {
    throw "Didn't expect duplicates libraries!";
  }
}
