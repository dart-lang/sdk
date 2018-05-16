#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_from_binary.dart';

import 'util.dart';

void usage() {
  print("Gives an overview of which parts of the dill file");
  print("contributes how many bytes.");
  print("");
  print("Usage: dart <script> dillFile.dill");
  print("The given argument should be an existing file");
  print("that is valid to load as a dill file.");
  exit(1);
}

main(args) {
  CommandLineHelper.requireExactlyOneArgument(true, args, usage);
  List<int> bytes = new File(args[0]).readAsBytesSync();
  try {
    Component p = new Component();
    new WrappedBinaryBuilder(bytes).readComponent(p);
  } catch (e) {
    print("Argument given isn't a dill file that can be loaded.");
    usage();
  }
}

class WrappedBinaryBuilder extends BinaryBuilder {
  WrappedBinaryBuilder(var _bytes) : super(_bytes, disableLazyReading: true);

  void readStringTable(List<String> table) {
    int size = -byteOffset;
    super.readStringTable(table);
    size += super.byteOffset;
    print("String table: ${_bytesToReadable(size)}.");
  }

  void readLinkTable(CanonicalName linkRoot) {
    int size = -byteOffset;
    super.readLinkTable(linkRoot);
    size += super.byteOffset;
    print("Link table: ${_bytesToReadable(size)}.");
  }

  Map<Uri, Source> readUriToSource() {
    int size = -byteOffset;
    var result = super.readUriToSource();
    size += super.byteOffset;
    print("URI to sources map: ${_bytesToReadable(size)}.");
    return result;
  }

  void readConstantTable() {
    int size = -byteOffset;
    super.readConstantTable();
    size += super.byteOffset;
    print("Constant table: ${_bytesToReadable(size)}.");
  }

  Library readLibrary(Component component, int endOffset) {
    int size = -byteOffset;
    var result = super.readLibrary(component, endOffset);
    size += super.byteOffset;
    print("Library '${result.importUri}': ${_bytesToReadable(size)}.");
    return result;
  }

  String _bytesToReadable(int size) {
    const List<String> what = const ["B", "KB", "MB", "GB", "TB"];
    int idx = 0;
    double dSize = size + 0.0;
    while ((idx + 1) < what.length && dSize >= 512) {
      ++idx;
      dSize /= 1024;
    }
    return "${dSize.toStringAsFixed(1)} ${what[idx]} ($size B)";
  }
}
