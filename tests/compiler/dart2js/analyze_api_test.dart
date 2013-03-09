// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_api;

import "package:expect/expect.dart";
import 'dart:uri';
import 'dart:io';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide Compiler;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/libraries.dart';

/**
 * Map of white-listed warnings and errors.
 *
 * Only add a white-listing together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the white-listing.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of white-listings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.
const Map<String,List<String>> WHITE_LIST = const { };

class CollectingDiagnosticHandler extends FormattingDiagnosticHandler {
  bool hasWarnings = false;
  bool hasErrors = false;

  Map<String,Map<String,int>> whiteListMap = new Map<String,Map<String,int>>();

  CollectingDiagnosticHandler(SourceFileProvider provider) : super(provider) {
    WHITE_LIST.forEach((String file, List<String> messageParts) {
      var useMap = new Map<String,int>();
      for (String messagePart in messageParts) {
        useMap[messagePart] = 0;
      }
      whiteListMap[file] = useMap;
    });
  }

  bool checkWhiteListUse() {
    bool allUsed = true;
    for (String file in whiteListMap.keys) {
      for (String messagePart in whiteListMap[file].keys) {
        if (whiteListMap[file][messagePart] == 0) {
          print("White-listing '$messagePart' is unused in '$file'. "
                "Remove the white-listing from the WHITE_LIST map.");
          allUsed = false;
        }
      }
    }
    return allUsed;
  }

  void reportWhiteListUse() {
    for (String file in whiteListMap.keys) {
      for (String messagePart in whiteListMap[file].keys) {
        int useCount = whiteListMap[file][messagePart];
        print("White-listed message '$messagePart' suppressed $useCount "
              "time(s) in '$file'.");
      }
    }
  }

  bool checkWhiteList(Uri uri, String message) {
    if (uri == null) {
      return false;
    }
    String path = uri.path;
    for (String file in whiteListMap.keys) {
      if (path.endsWith(file)) {
        for (String messagePart in whiteListMap[file].keys) {
          if (message.contains(messagePart)) {
            whiteListMap[file][messagePart]++;
            return true;
          }
        }
      }
    }
    return false;
  }

  void diagnosticHandler(Uri uri, int begin, int end, String message,
                         api.Diagnostic kind) {
    if (kind == api.Diagnostic.WARNING) {
      if (checkWhiteList(uri, message)) {
        // Suppress white listed warnings.
        return;
      }
      hasWarnings = true;
    }
    if (kind == api.Diagnostic.ERROR) {
      if (checkWhiteList(uri, message)) {
        // Suppress white listed warnings.
        return;
      }
      hasErrors = true;
    }
    super.diagnosticHandler(uri, begin, end, message, kind);
  }
}

void main() {
  Uri currentWorkingDirectory = getCurrentDirectory();
  var libraryRoot = currentWorkingDirectory.resolve('sdk/');
  var uriList = new List<Uri>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      uriList.add(new Uri.fromComponents(scheme: 'dart', path: name));
    }
  });
  var provider = new SourceFileProvider();
  var handler = new CollectingDiagnosticHandler(provider);
  var compiler = new Compiler(
      provider.readStringFromUri,
      null,
      handler.diagnosticHandler,
      libraryRoot, libraryRoot,
      <String>['--analyze-only', '--analyze-all',
               '--categories=Client,Server']);
  compiler.librariesToAnalyzeWhenRun = uriList;
  compiler.run(null);
  Expect.isFalse(handler.hasWarnings);
  Expect.isFalse(handler.hasErrors);
  Expect.isTrue(handler.checkWhiteListUse());
  handler.reportWhiteListUse();
}
