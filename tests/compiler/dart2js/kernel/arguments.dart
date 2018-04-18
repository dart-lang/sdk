// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.arguments;

import 'package:compiler/src/filenames.dart';

class Arguments {
  final String filename;
  final int start;
  final int end;
  final bool verbose;

  const Arguments({this.filename, this.start, this.end, this.verbose: false});

  factory Arguments.from(List<String> arguments) {
    String filename;
    int start;
    int end;
    for (String arg in arguments) {
      if (!arg.startsWith('-')) {
        int index = int.parse(arg, onError: (_) => null);
        if (index == null) {
          filename = arg;
        } else if (start == null) {
          start = index;
        } else {
          end = index;
        }
      }
    }
    bool verbose = arguments.contains('-v');
    return new Arguments(
        filename: filename, start: start, end: end, verbose: verbose);
  }

  Uri get uri {
    if (filename != null) {
      return Uri.base.resolve(nativeToUriPath(filename));
    }
    return null;
  }
}
