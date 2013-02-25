// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.async;

import 'dart:async';
import 'dart:io';

import 'package:pathos/path.dart' as path;

import '../../descriptor.dart' as descriptor;
import '../../scheduled_test.dart';
import '../utils.dart';
import 'utils.dart';

/// A descriptor that validates that no file exists with the given name.
/// Creating this descriptor is a no-op and loading from it is invalid.
class Nothing extends descriptor.Entry {
  Nothing(Pattern name)
      : super(name);

  Future create([String parent]) => new Future.immediate(null);

  Future validate([String parent]) => schedule(() {
    if (parent == null) parent = descriptor.defaultRoot;
    if (name is String) {
      var fullPath = path.join(parent, name);
      if (new File(fullPath).existsSync()) {
        throw "Expected nothing to exist at '$fullPath', but found a file.";
      } else if (new Directory(fullPath).existsSync()) {
        throw "Expected nothing to exist at '$fullPath', but found a "
            "directory.";
      } else {
        return;
      }
    }

    return new Directory(parent).list().toList().then((entries) {
      var matchingEntries = entries
          .map((entry) => entry is File ? entry.fullPathSync() : entry.path)
          .where((entry) => path.basename(entry).contains(name))
          .toList();
      matchingEntries.sort();

      if (matchingEntries.length == 0) return;
      throw "Expected nothing to exist in '$parent' matching $nameDescription, "
              "but found:\n"
          "${matchingEntries.map((entry) => '* $entry').join('\n')}";
    });
  }, "validating $nameDescription doesn't exist");

  Stream<List<int>> load(String pathToLoad) => errorStream("Nothing "
      "descriptors don't support load().");

  Stream<List<int>> read() => errorStream("Nothing descriptors don't support "
      "read().");

  String describe() => "nothing at $nameDescription";
}
