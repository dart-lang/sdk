// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart';

main() {
  File exe = new File(Platform.resolvedExecutable).absolute;
  int steps = 0;
  Directory parent = exe.parent.parent;
  while (true) {
    Set<String> foundDirs = {};
    for (FileSystemEntity entry in parent.listSync(recursive: false)) {
      if (entry is Directory) {
        List<String> pathSegments = entry.uri.pathSegments;
        String name = pathSegments[pathSegments.length - 2];
        foundDirs.add(name);
      }
    }
    if (foundDirs.contains("pkg") &&
        foundDirs.contains("tools") &&
        foundDirs.contains("tests")) {
      break;
    }
    steps++;
    if (parent.uri == parent.parent.uri) {
      throw "Reached end without finding the root.";
    }
    parent = parent.parent;
  }
  // We had to go $steps steps to reach the "root" --- now we should go 2 steps
  // shorter to be in the "compiled dir".
  parent = exe.parent;
  for (int i = steps - 2; i >= 0; i--) {
    parent = parent.parent;
  }

  List<File> dills = [];
  for (FileSystemEntity entry in parent.listSync(recursive: false)) {
    if (entry is File) {
      if (entry.path.toLowerCase().endsWith(".dill")) {
        dills.add(entry);
      }
    }
  }
  Directory sdk = new Directory.fromUri(parent.uri.resolve("dart-sdk/"));
  for (FileSystemEntity entry in sdk.listSync(recursive: true)) {
    if (entry is File) {
      if (entry.path.toLowerCase().endsWith(".dill")) {
        dills.add(entry);
      }
    }
  }

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
