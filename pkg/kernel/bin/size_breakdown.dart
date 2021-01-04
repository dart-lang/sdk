#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/src/tool/command_line_util.dart';

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
  CommandLineHelper.requireExactlyOneArgument(args, usage,
      requireFileExists: true);
  List<int> bytes = new File(args[0]).readAsBytesSync();
  try {
    Component p = new Component();
    new WrappedBinaryBuilder(bytes)
      ..readComponent(p)
      ..report();
  } catch (e) {
    print("Argument given isn't a dill file that can be loaded.");
    usage();
  }
}

class WrappedBinaryBuilder extends BinaryBuilder {
  WrappedBinaryBuilder(var _bytes) : super(_bytes, disableLazyReading: true);
  int offsetsSize = 0;
  int stringTableSize = 0;
  int linkTableSize = 0;
  int uriToSourceSize = 0;
  int constantTableSize = 0;
  Map<Uri, int> librarySizes = {};

  int readOffset() {
    offsetsSize -= byteOffset;
    int result = super.readOffset();
    offsetsSize += byteOffset;
    return result;
  }

  void readStringTable(List<String> table) {
    stringTableSize -= byteOffset;
    super.readStringTable(table);
    stringTableSize += byteOffset;
  }

  void readLinkTable(CanonicalName linkRoot) {
    linkTableSize -= byteOffset;
    super.readLinkTable(linkRoot);
    linkTableSize += byteOffset;
  }

  Map<Uri, Source> readUriToSource(bool readCoverage) {
    uriToSourceSize -= byteOffset;
    var result = super.readUriToSource(readCoverage);
    uriToSourceSize += byteOffset;
    return result;
  }

  void readConstantTable() {
    constantTableSize -= byteOffset;
    super.readConstantTable();
    constantTableSize += byteOffset;
  }

  Library readLibrary(Component component, int endOffset) {
    int size = -byteOffset;
    var result = super.readLibrary(component, endOffset);
    size += byteOffset;
    librarySizes[result.importUri] = size;
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

  void report() {
    print("Offsets: ${_bytesToReadable(offsetsSize)}");
    print("String table: ${_bytesToReadable(stringTableSize)}");
    print("Link table: ${_bytesToReadable(linkTableSize)}");
    print("URI to source table: ${_bytesToReadable(uriToSourceSize)}");
    print("Constant table: ${_bytesToReadable(constantTableSize)}");
    print("");
    for (Uri uri in librarySizes.keys) {
      print("Library '$uri': ${_bytesToReadable(librarySizes[uri])}.");
    }
  }
}
