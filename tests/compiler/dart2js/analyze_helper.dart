// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_helper;

import 'dart:async';
import 'dart:io';
import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/dart2jslib.dart'
    hide Compiler;
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/util/uri_extras.dart';

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
  bool lastWasWhitelisted = false;

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

  bool checkResults() {
    bool validWhiteListUse = checkWhiteListUse();
    reportWhiteListUse();
    return !hasWarnings && !hasHint && !hasErrors && validWhiteListUse;
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
      if (path.contains(file)) {
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
        lastWasWhitelisted = true;
        return;
      }
      hasWarnings = true;
    }
    if (kind == api.Diagnostic.HINT) {
      if (checkWhiteList(uri, message)) {
        // Suppress whitelisted hints.
        lastWasWhitelisted = true;
        return;
      }
      hasHint = true;
    }
    if (kind == api.Diagnostic.ERROR) {
      if (checkWhiteList(uri, message)) {
        // Suppress whitelisted errors.
        lastWasWhitelisted = true;
        return;
      }
      hasErrors = true;
    }
    if (kind == api.Diagnostic.INFO && lastWasWhitelisted) {
      return;
    }
    lastWasWhitelisted = false;
    super.diagnosticHandler(uri, begin, end, message, kind);
  }
}

typedef bool CheckResults(Compiler compiler,
                          CollectingDiagnosticHandler handler);

Future analyze(List<Uri> uriList,
               Map<String, List<String>> whiteList,
               {bool analyzeAll: true,
                CheckResults checkResults}) {
  String testFileName =
      relativize(Uri.base, Platform.script, Platform.isWindows);

  print("""


===
=== NOTE: If this test fails, update [WHITE_LIST] in $testFileName
===


""");

  var libraryRoot = currentDirectory.resolve('sdk/');
  var packageRoot =
      currentDirectory.resolveUri(new Uri.file('${Platform.packageRoot}/'));
  var provider = new CompilerSourceFileProvider();
  var handler = new CollectingDiagnosticHandler(whiteList, provider);
  var options = <String>['--analyze-only', '--categories=Client,Server'];
  if (analyzeAll) options.add('--analyze-all');
  var compiler = new Compiler(
      provider.readStringFromUri,
      null,
      handler.diagnosticHandler,
      libraryRoot, packageRoot,
      options,
      {});
  String MESSAGE = """


===
=== ERROR: Unexpected result of analysis.
===
=== Please update [WHITE_LIST] in $testFileName
===
""";

  void onCompletion(_) {
    bool result;
    if (checkResults != null) {
      result = checkResults(compiler, handler);
    } else {
      result = handler.checkResults();
    }
    if (!result) {
      print(MESSAGE);
      exit(1);
    }
  }
  if (analyzeAll) {
    compiler.librariesToAnalyzeWhenRun = uriList;
    return compiler.run(null).then(onCompletion);
  } else {
    return compiler.run(uriList.single).then(onCompletion);
  }
}
