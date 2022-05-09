#!/usr/bin/env dart
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/kernel.dart'
    show Component, Source, loadComponentFromBytes;
import 'package:kernel/binary/tag.dart' show Tag;

void main(List<String> args) {
  if (args.length != 1) {
    throw "Usage: dart <script> <dillFile>";
  }
  File file = new File(args.single);
  if (!file.existsSync()) {
    throw "Given file doesn't exist.\n"
        "Usage: dart <script> <dillFile>";
  }
  Uint8List bytes = file.readAsBytesSync();
  List<Component> components = splitAndRead(bytes);
  print("Successfully read ${components.length} sub-components.");

  for (int i = 0; i < components.length; i++) {
    Component component = components[i];
    print("Component #${i + 1}:");
    for (MapEntry<Uri, Source> entry in component.uriToSource.entries) {
      String importUri = entry.value.importUri.toString();
      String fileUri = entry.key.toString();
      if (importUri != fileUri) {
        print(" - $importUri ($fileUri)");
      } else {
        print(" - $fileUri");
      }
    }
  }

  // TODO(jensj): Could we read _some_ (useful) data from a partial component
  // (e.g. one that stops after the first few libraries)?
}

List<Component> splitAndRead(Uint8List bytes) {
  List<Component> components = [];

  // Search for magic component file tag.
  List<int> magicTagBytes = [
    (Tag.ComponentFile >> 24) & 0XFF,
    (Tag.ComponentFile >> 16) & 0XFF,
    (Tag.ComponentFile >> 8) & 0XFF,
    (Tag.ComponentFile >> 0) & 0XFF,
  ];
  List<int> tagOffsets = [];
  for (int index = 0; index < bytes.length - 7; index++) {
    if (bytes[index] == magicTagBytes[0] &&
        bytes[index + 1] == magicTagBytes[1] &&
        bytes[index + 2] == magicTagBytes[2] &&
        bytes[index + 3] == magicTagBytes[3]) {
      // Try to read binary version too and see if it matches.
      int version = (bytes[index + 4] << 24) |
          (bytes[index + 5] << 16) |
          (bytes[index + 6] << 8) |
          bytes[index + 7];
      if (version != Tag.BinaryFormatVersion) {
        print("Found tag, but version mismatches "
            "('$version' vs readable version '${Tag.BinaryFormatVersion}'). "
            "Try again in a different checkout.");
      } else {
        tagOffsets.add(index);
      }
    }
  }
  print("Found ${tagOffsets.length} possible tag offsets.");

  // Add fake file tag after end of bytes to also attempt "last component".
  tagOffsets.add(bytes.length);

  // Warning: O(n²) algorithm (though, as the tag is assumed to be rather unique
  // in normal cases it will probably much better in practice
  // (and n will be low)).
  int fromIndex = 0;
  while (fromIndex < tagOffsets.length - 1) {
    int toIndex = fromIndex + 1;
    while (toIndex < tagOffsets.length) {
      // Cut bytes and try to load.
      int fromOffset = tagOffsets[fromIndex];
      int toOffset = tagOffsets[toIndex];
      Uint8List bytesView =
          new Uint8List.sublistView(bytes, fromOffset, toOffset);
      try {
        Component loaded = loadComponentFromBytes(bytesView);
        components.add(loaded);
        print("Loaded from tag ${fromIndex} to ${toIndex}.");
        break;
      } catch (e) {
        print("Failed loading from tag ${fromIndex} to ${toIndex}"
            " (${toOffset - fromOffset} bytes).");
        toIndex++;
      }
    }
    fromIndex++;
  }

  return components;
}
