// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_helper;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
    hide Compiler;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';

/**
 * Map of whitelisted warnings and errors.
 *
 * Only add a whitelisting together with a bug report to dartbug.com and add
 * the bug issue number as a comment on the whitelisting.
 *
 * Use an identifiable suffix of the file uri as key. Use a fixed substring of
 * the error/warning message in the list of whitelistings for each file.
 */
// TODO(johnniwinther): Support canonical URIs as keys and message kinds as
// values.

class CollectingDiagnosticHandler extends FormattingDiagnosticHandler {
  bool hasWarnings = false;
  bool hasHint = false;
  bool hasErrors = false;

  Map<String, Map<String, int>> whiteListMap
      = new Map<String, Map<String, int>>();

  CollectingDiagnosticHandler(Map<String, List<String>> whiteList,
                              SourceFileProvider provider)
      : super(provider) {
    whiteList.forEach((String file, List<String> messageParts) {
      var useMap = new Map<String,int>();
      for (String messagePart in messageParts) {
        useMap[messagePart] = 0;
      }
      whiteListMap[file] = useMap;
    });
  }

  void checkResults() {
    Expect.isFalse(hasWarnings);
    Expect.isFalse(hasHint);
    Expect.isFalse(hasErrors);
    Expect.isTrue(checkWhiteListUse());
    reportWhiteListUse();
  }

  bool checkWhiteListUse() {
    bool allUsed = true;
    for (String file in whiteListMap.keys) {
      for (String messagePart in whiteListMap[file].keys) {
        if (whiteListMap[file][messagePart] == 0) {
          print("Whitelisting '$messagePart' is unused in '$file'. "
                "Remove the whitelisting from the whitelist map.");
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
        print("Whitelisted message '$messagePart' suppressed $useCount "
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
        // Suppress whitelisted warnings.
        return;
      }
      hasWarnings = true;
    }
    if (kind == api.Diagnostic.HINT) {
      if (checkWhiteList(uri, message)) {
        // Suppress whitelisted hints.
        return;
      }
      hasHint = true;
    }
    if (kind == api.Diagnostic.ERROR) {
      if (checkWhiteList(uri, message)) {
        // Suppress whitelisted errors.
        return;
      }
      hasErrors = true;
    }
    super.diagnosticHandler(uri, begin, end, message, kind);
  }
}

Future analyze(List<Uri> uriList, Map<String, List<String>> whiteList) {
  var libraryRoot = currentDirectory.resolve('sdk/');
  var provider = new CompilerSourceFileProvider();
  var handler = new CollectingDiagnosticHandler(whiteList, provider);
  var compiler = new Compiler(
      provider.readStringFromUri,
      null,
      handler.diagnosticHandler,
      libraryRoot, libraryRoot,
      <String>['--analyze-only', '--analyze-all',
               '--categories=Client,Server']);
  compiler.librariesToAnalyzeWhenRun = uriList;
  return compiler.run(null).then((_) {
    handler.checkResults();
  });
}
