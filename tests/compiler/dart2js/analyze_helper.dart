// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyze_helper;

import 'dart:async';
import 'dart:io';
import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/diagnostics/messages.dart'
    show Message, MessageKind;
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/options.dart' show CompilerOptions;
import 'package:compiler/src/source_file_provider.dart';
import 'package:compiler/src/util/uri_extras.dart';
import 'diagnostic_helper.dart';

/// Option for hiding whitelisted messages.
const String HIDE_WHITELISTED = '--hide-whitelisted';

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
  bool showWhitelisted = true;

  Map<String, Map<dynamic /* String|MessageKind */, int>> whiteListMap =
      new Map<String, Map<dynamic /* String|MessageKind */, int>>();
  List<MessageKind> skipList;
  List<CollectedMessage> collectedMessages = <CollectedMessage>[];

  CollectingDiagnosticHandler(
      Map<String, List /* <String|MessageKind> */ > whiteList,
      this.skipList,
      SourceFileProvider provider)
      : super(provider) {
    whiteList
        .forEach((String file, List /* <String|MessageKind> */ messageParts) {
      var useMap = new Map<dynamic /* String|MessageKind */, int>();
      for (var messagePart in messageParts) {
        useMap[messagePart] = 0;
      }
      whiteListMap[file] = useMap;
    });
  }

  bool checkResults() {
    bool validWhiteListUse = checkWhiteListUse();
    reportWhiteListUse();
    reportCollectedMessages();
    return !hasWarnings && !hasHint && !hasErrors && validWhiteListUse;
  }

  bool checkWhiteListUse() {
    bool allUsed = true;
    for (String file in whiteListMap.keys) {
      for (var messagePart in whiteListMap[file].keys) {
        if (whiteListMap[file][messagePart] == 0) {
          print("Whitelisting '$messagePart' is unused in '$file'. "
              "Remove the whitelisting from the whitelist map.");
          allUsed = false;
        }
      }
    }
    return allUsed;
  }

  void reportCollectedMessages() {
    if (collectedMessages.isNotEmpty) {
      print('----------------------------------------------------------------');
      print('Unexpected messages:');
      print('----------------------------------------------------------------');
      for (CollectedMessage message in collectedMessages) {
        super.report(message.message, message.uri, message.begin, message.end,
            message.text, message.kind);
      }
      print('----------------------------------------------------------------');
    }
  }

  void reportWhiteListUse() {
    for (String file in whiteListMap.keys) {
      for (var messagePart in whiteListMap[file].keys) {
        int useCount = whiteListMap[file][messagePart];
        print("Whitelisted message '$messagePart' suppressed $useCount "
            "time(s) in '$file'.");
      }
    }
  }

  bool checkWhiteList(Uri uri, Message message, String text) {
    if (uri == null) {
      return false;
    }
    if (skipList.contains(message.kind)) {
      return true;
    }
    String path = uri.path;
    for (String file in whiteListMap.keys) {
      if (path.contains(file)) {
        for (var messagePart in whiteListMap[file].keys) {
          bool found = false;
          if (messagePart is String) {
            found = text.contains(messagePart);
          } else {
            assert(messagePart is MessageKind);
            found = message.kind == messagePart;
          }
          if (found) {
            whiteListMap[file][messagePart]++;
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void report(Message message, Uri uri, int begin, int end, String text,
      api.Diagnostic kind) {
    if (kind == api.Diagnostic.WARNING) {
      if (checkWhiteList(uri, message, text)) {
        // Suppress whitelisted warnings.
        lastWasWhitelisted = true;
        if (showWhitelisted || verbose) {
          super.report(message, uri, begin, end, text, kind);
        }
        return;
      }
      hasWarnings = true;
    }
    if (kind == api.Diagnostic.HINT) {
      if (checkWhiteList(uri, message, text)) {
        // Suppress whitelisted hints.
        lastWasWhitelisted = true;
        if (showWhitelisted || verbose) {
          super.report(message, uri, begin, end, text, kind);
        }
        return;
      }
      hasHint = true;
    }
    if (kind == api.Diagnostic.ERROR) {
      if (checkWhiteList(uri, message, text)) {
        // Suppress whitelisted errors.
        lastWasWhitelisted = true;
        if (showWhitelisted || verbose) {
          super.report(message, uri, begin, end, text, kind);
        }
        return;
      }
      hasErrors = true;
    }
    if (kind == api.Diagnostic.INFO && lastWasWhitelisted) {
      return;
    }
    lastWasWhitelisted = false;
    if (kind != api.Diagnostic.VERBOSE_INFO) {
      collectedMessages
          .add(new CollectedMessage(message, uri, begin, end, text, kind));
    }
    super.report(message, uri, begin, end, text, kind);
  }
}

typedef bool CheckResults(
    CompilerImpl compiler, CollectingDiagnosticHandler handler);

enum AnalysisMode {
  /// Analyze all declarations in all libraries in one go.
  ALL,

  /// Analyze all declarations in the main library.
  MAIN,

  /// Analyze all declarations in the given URIs one at a time. This mode can
  /// handle URIs for parts (i.e. skips these).
  URI,

  /// Analyze all declarations reachable from the entry point.
  TREE_SHAKING,
}

/// Analyzes the file(s) in [uriList] using the provided [mode] and checks that
/// no messages (errors, warnings or hints) are emitted.
///
/// Messages can be generally allowed using [skipList] or on a per-file basis
/// using [whiteList].
Future analyze(
    List<Uri> uriList, Map<String, List /* <String|MessageKind> */ > whiteList,
    {AnalysisMode mode: AnalysisMode.ALL,
    CheckResults checkResults,
    List<String> options: const <String>[],
    List<MessageKind> skipList: const <MessageKind>[]}) async {
  String testFileName =
      relativize(Uri.base, Platform.script, Platform.isWindows);

  print("""


===
=== NOTE: If this test fails, update [WHITE_LIST] in $testFileName
===


""");

  var libraryRoot = currentDirectory.resolve('sdk/');
  var packageConfig = currentDirectory.resolve('.packages');
  var provider = new CompilerSourceFileProvider();
  var handler = new CollectingDiagnosticHandler(whiteList, skipList, provider);
  options = <String>[
    Flags.analyzeOnly,
    '--categories=Client,Server',
    Flags.showPackageWarnings
  ]..addAll(options);
  switch (mode) {
    case AnalysisMode.URI:
    case AnalysisMode.MAIN:
      options.add(Flags.analyzeMain);
      break;
    case AnalysisMode.ALL:
      options.add(Flags.analyzeAll);
      break;
    case AnalysisMode.TREE_SHAKING:
      break;
  }
  if (options.contains(Flags.verbose)) {
    handler.verbose = true;
  }
  if (options.contains(HIDE_WHITELISTED)) {
    handler.showWhitelisted = false;
  }
  var compiler = new CompilerImpl(
      provider,
      null,
      handler,
      new CompilerOptions.parse(
          libraryRoot: libraryRoot,
          packageConfig: packageConfig,
          options: options,
          environment: {}));
  String MESSAGE = """


===
=== ERROR: Unexpected result of analysis.
===
=== Please update [WHITE_LIST] in $testFileName
===
""";

  if (mode == AnalysisMode.URI) {
    for (Uri uri in uriList) {
      print('Analyzing uri: $uri');
      await compiler.analyzeUri(uri);
    }
  } else if (mode != AnalysisMode.TREE_SHAKING) {
    print('Analyzing libraries: $uriList');
    compiler.librariesToAnalyzeWhenRun = uriList;
    await compiler.run(null);
  } else {
    print('Analyzing entry point: ${uriList.single}');
    await compiler.run(uriList.single);
  }

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
