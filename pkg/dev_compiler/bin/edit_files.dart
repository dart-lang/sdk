#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to write checker errors as inline comments in the source
/// code of the program. This tool requires the info.json file created by
/// running dartdevc.dart passing the arguments
/// --dump-info --dump-info-file info.json

library dev_compiler.bin.edit_files;

import 'dart:io';
import 'dart:convert';

import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

import 'package:dev_compiler/src/analysis_context.dart';
import 'package:dev_compiler/src/options.dart';
import 'package:dev_compiler/src/summary.dart';

final ArgParser argParser = new ArgParser()
  ..addOption('level', help: 'Minimum error level', defaultsTo: "info")
  ..addOption('checkout-files-executable',
      help: 'Executable to check out files from source control (e.g. svn)',
      defaultsTo: null)
  ..addOption('checkout-files-arg',
      help: 'Arg to check out files from source control (e.g. checkout)',
      defaultsTo: null)
  ..addOption('include-pattern',
      help: 'regular expression of file names to include', defaultsTo: null)
  ..addOption('exclude-pattern',
      help: 'regular expression of file names to exclude', defaultsTo: null)
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addOption('package-root',
      abbr: 'p',
      help: 'Package root to resolve "package:" imports',
      defaultsTo: 'packages/')
  ..addFlag('use-multi-package',
      help: 'Whether to use the multi-package resolver for "package:" imports',
      defaultsTo: false)
  ..addOption('package-paths',
      help: 'if using the multi-package resolver, '
          'the list of directories where to look for packages.',
      defaultsTo: '')
  ..addFlag('help', abbr: 'h', help: 'Display this message');

void _showUsageAndExit() {
  print('usage: edit_files [<options>] <summary.json>\n');
  print('<summary.json> GlobalSummary serialized as json.\n');
  print('<options> include:\n');
  print(argParser.usage);
  exit(1);
}

class EditFileSummaryVisitor extends RecursiveSummaryVisitor {
  var _files = new Map<String, TextEditTransaction>();
  AnalysisContext context;
  String level;
  String checkoutFilesExecutable;
  String checkoutFilesArg;
  RegExp includePattern;
  RegExp excludePattern;

  final Map<Uri, Source> _sources = <Uri, Source>{};

  EditFileSummaryVisitor(this.context, this.level, this.checkoutFilesExecutable,
      this.checkoutFilesArg, this.includePattern, this.excludePattern);

  TextEditTransaction getEdits(String name) => _files.putIfAbsent(name, () {
        var fileContents = new File(name).readAsStringSync();
        return new TextEditTransaction(
            fileContents, new SourceFile(fileContents));
      });

  /// Find the corresponding [Source] for [uri].
  Source findSource(Uri uri) {
    var source = _sources[uri];
    if (source != null) return source;
    return _sources[uri] = context.sourceFactory.forUri('$uri');
  }

  @override
  void visitMessage(MessageSummary message) {
    var uri = message.span.sourceUrl;
    // Ignore dart: libraries.
    if (uri.scheme == 'dart') return;
    if (level != null) {
      // Filter out messages with lower severity.
      switch (message.level) {
        case "info":
          if (level != "info") return;
          break;
        case "warning":
          if (level == "severe") return;
          break;
      }
    }
    var fullName = findSource(uri).fullName;
    if (includePattern != null && !includePattern.hasMatch(fullName)) return;
    if (excludePattern != null && excludePattern.hasMatch(fullName)) return;
    var edits = getEdits(fullName);
    edits.edit(message.span.start.offset, message.span.start.offset,
        " /* DDC:${message.level}: ${message.kind}, ${message.message} */ ");
  }

  void build() {
    if (checkoutFilesExecutable != null) {
      Process.runSync(
          checkoutFilesExecutable, [checkoutFilesArg]..addAll(_files.keys));
    }
    _files.forEach((name, transaction) {
      var nestedPrinter = transaction.commit()..build(name);
      new File(name).writeAsStringSync(nestedPrinter.text, flush: true);
    });
  }
}

void main(List<String> argv) {
  ArgResults args = argParser.parse(argv);
  if (args['help']) _showUsageAndExit();

  if (args.rest.isEmpty) {
    print('Expected filename.');
    _showUsageAndExit();
  }

  var sdkDir = getSdkDir(argv);
  if (sdkDir == null) {
    print('Could not automatically find dart sdk path.');
    print('Please pass in explicitly: --dart-sdk <path>');
    exit(1);
  }

  var filename = args.rest.first;
  var options = new SourceResolverOptions(
      dartSdkPath: sdkDir.path,
      useMultiPackage: args['use-multi-package'],
      packageRoot: args['package-root'],
      packagePaths: args['package-paths'].split(','));

  Map json = JSON.decode(new File(filename).readAsStringSync());
  var summary = GlobalSummary.parse(json);
  var excludePattern = (args['exclude-pattern'] != null)
      ? new RegExp(args['exclude-pattern'])
      : null;
  var includePattern = (args['include-pattern'] != null)
      ? new RegExp(args['include-pattern'])
      : null;

  var context = createAnalysisContextWithSources(options);
  var visitor = new EditFileSummaryVisitor(
      context,
      args['level'],
      args['checkout-files-executable'],
      args['checkout-files-arg'],
      includePattern,
      excludePattern);
  summary.accept(visitor);
  visitor.build();
}
