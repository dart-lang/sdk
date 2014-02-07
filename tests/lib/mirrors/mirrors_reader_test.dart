// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that everything reachable from a [MirrorSystem] can be accessed.

library test.mirrors.reader;

import 'dart:mirrors';
import 'mirrors_reader.dart';

class RuntimeMirrorsReader extends MirrorsReader {
  final String mirrorSystemType;

  RuntimeMirrorsReader(MirrorSystem mirrorSystem,
                      {bool verbose: false, bool includeStackTrace: false})
      : this.mirrorSystemType = '${mirrorSystem.runtimeType}',
        super(verbose: verbose, includeStackTrace: includeStackTrace);

  bool allowUnsupported(var receiver, String tag, UnsupportedError exception) {
    if (mirrorSystemType == '_LocalMirrorSystem') {
      // VM mirror system.
    } else if (mirrorSystemType == 'JsMirrorSystem') {
      // Dart2js runtime mirror system.
      if (tag.endsWith('.metadata')) {
        return true;// Issue 10905.
      }
    }
    return false;
  }

  bool expectUnsupported(var receiver, String tag, UnsupportedError exception) {
    // [DeclarationMirror.location] is intentionally not supported in runtime
    // mirrors.
    if (receiver is DeclarationMirror && tag == 'location') {
      return true;
    }
    if (mirrorSystemType == '_LocalMirrorSystem') {
      // VM mirror system.
    } else if (mirrorSystemType == 'JsMirrorSystem') {
      // Dart2js runtime mirror system.
    }
    return false;
  }
}

void main([List<String> arguments = const <String>[]]) {
  MirrorSystem mirrors = currentMirrorSystem();
  MirrorsReader reader = new RuntimeMirrorsReader(mirrors,
      verbose: arguments.contains('-v'),
      includeStackTrace: arguments.contains('-s'));
  reader.checkMirrorSystem(mirrors);
}
