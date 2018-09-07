// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io' show Platform;
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'module_builder.dart';

/// Shared code between Analyzer and Kernel CLI interfaces.
///
/// This file should only implement functionality that does not depend on
/// Analyzer/Kernel imports.

/// Variables that indicate which libraries are available in dev compiler.
// TODO(jmesserly): provide an option to compile without dart:html & friends?
Map<String, String> sdkLibraryVariables = {
  'dart.isVM': 'false',
  'dart.library.async': 'true',
  'dart.library.core': 'true',
  'dart.library.collection': 'true',
  'dart.library.convert': 'true',
  // TODO(jmesserly): this is not really supported in dart4web other than
  // `debugger()`
  'dart.library.developer': 'true',
  'dart.library.io': 'false',
  'dart.library.isolate': 'false',
  'dart.library.js': 'true',
  'dart.library.js_util': 'true',
  'dart.library.math': 'true',
  'dart.library.mirrors': 'false',
  'dart.library.typed_data': 'true',
  'dart.library.indexed_db': 'true',
  'dart.library.html': 'true',
  'dart.library.html_common': 'true',
  'dart.library.svg': 'true',
  'dart.library.ui': 'false',
  'dart.library.web_audio': 'true',
  'dart.library.web_gl': 'true',
  'dart.library.web_sql': 'true',
};

/// Shared compiler options between `dartdevc` and `dartdevk`.
class SharedCompilerOptions {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  /// Whether to preserve metdata only accessible via mirrors.
  final bool emitMetadata;

  // Whether to enable assertions.
  final bool enableAsserts;

  /// Whether to compile code in a more permissive REPL mode allowing access
  /// to private members across library boundaries.
  ///
  /// This should only set `true` by our REPL compiler.
  bool replCompile;

  /// Mapping from absolute file paths to bazel short path to substitute in
  /// source maps.
  final Map<String, String> bazelMapping;

  final Map<String, String> summaryModules;

  final List<ModuleFormat> moduleFormats;

  SharedCompilerOptions(
      {this.sourceMap = true,
      this.summarizeApi = true,
      this.emitMetadata = false,
      this.enableAsserts = true,
      this.replCompile = false,
      this.bazelMapping = const {},
      this.summaryModules = const {},
      this.moduleFormats = const []});

  SharedCompilerOptions.fromArguments(ArgResults args,
      [String moduleRoot, String summaryExtension])
      : this(
            sourceMap: args['source-map'] as bool,
            summarizeApi: args['summarize'] as bool,
            emitMetadata: args['emit-metadata'] as bool,
            enableAsserts: args['enable-asserts'] as bool,
            bazelMapping:
                _parseBazelMappings(args['bazel-mapping'] as List<String>),
            summaryModules: _parseCustomSummaryModules(
                args['summary'] as List<String>, moduleRoot, summaryExtension),
            moduleFormats: parseModuleFormatOption(args));

  static void addArguments(ArgParser parser, {bool hide = true}) {
    addModuleFormatOptions(parser, allowMultiple: true, hide: hide);

    parser
      ..addMultiOption('summary',
          abbr: 's',
          help: 'summary file(s) of imported libraries, optionally\n'
              'with module import path: -s path.sum=js/import/path')
      ..addFlag('summarize',
          help: 'emit an API summary file', defaultsTo: true, hide: hide)
      ..addFlag('source-map',
          help: 'emit source mapping', defaultsTo: true, hide: hide)
      ..addFlag('emit-metadata',
          help: 'emit metadata annotations queriable via mirrors', hide: hide)
      ..addFlag('enable-asserts',
          help: 'enable assertions', defaultsTo: true, hide: hide)
      // TODO(jmesserly): rename this, it has nothing to do with bazel.
      ..addMultiOption('bazel-mapping',
          help: '--bazel-mapping=gen/to/library.dart,to/library.dart\n'
              'adjusts the path in source maps.',
          splitCommas: false,
          hide: hide);
  }
}

/// Finds explicit module names of the form `path=name` in [summaryPaths],
/// and returns the path to mapping in an ordered map from `path` to `name`.
///
/// A summary path can contain "=" followed by an explicit module name to
/// allow working with summaries whose physical location is outside of the
/// module root directory.
Map<String, String> _parseCustomSummaryModules(List<String> summaryPaths,
    [String moduleRoot, String summaryExt]) {
  var pathToModule = <String, String>{};
  if (summaryPaths == null) return pathToModule;
  for (var summaryPath in summaryPaths) {
    var equalSign = summaryPath.indexOf("=");
    String modulePath;
    var summaryPathWithoutExt = summaryExt != null
        ? summaryPath.substring(
            0,
            // Strip off the extension, including the last `.`.
            summaryPath.length - (summaryExt.length + 1))
        : path.withoutExtension(summaryPath);
    if (equalSign != -1) {
      modulePath = summaryPath.substring(equalSign + 1);
      summaryPath = summaryPath.substring(0, equalSign);
    } else if (moduleRoot != null && path.isWithin(moduleRoot, summaryPath)) {
      // TODO(jmesserly): remove this, it's legacy --module-root support.
      modulePath = path.url.joinAll(
          path.split(path.relative(summaryPathWithoutExt, from: moduleRoot)));
    } else {
      modulePath = path.basename(summaryPathWithoutExt);
    }
    pathToModule[summaryPath] = modulePath;
  }
  return pathToModule;
}

Map<String, String> _parseBazelMappings(List<String> argument) {
  var mappings = <String, String>{};
  for (var mapping in argument) {
    var splitMapping = mapping.split(',');
    if (splitMapping.length >= 2) {
      mappings[path.absolute(splitMapping[0])] = splitMapping[1];
    }
  }
  return mappings;
}

/// Taken from analyzer to implement `--ignore-unrecognized-flags`
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  if (!args.contains('--ignore-unrecognized-flags')) return args;

  var knownOptions = new HashSet<String>();
  var knownAbbreviations = new HashSet<String>();
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    var abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
    if (option.negatable) {
      knownOptions.add('no-$name');
    }
  });

  String optionName(int prefixLength, String arg) {
    int equalsOffset = arg.lastIndexOf('=');
    if (equalsOffset < 0) {
      return arg.substring(prefixLength);
    }
    return arg.substring(prefixLength, equalsOffset);
  }

  var filtered = <String>[];
  for (var arg in args) {
    if (arg.startsWith('--') && arg.length > 2) {
      if (knownOptions.contains(optionName(2, arg))) {
        filtered.add(arg);
      }
    } else if (arg.startsWith('-') && arg.length > 1) {
      if (knownAbbreviations.contains(optionName(1, arg))) {
        filtered.add(arg);
      }
    } else {
      filtered.add(arg);
    }
  }
  return filtered;
}

/// Convert a [source] string to a Uri, where the source may be a
/// dart/file/package URI or a local win/mac/linux path.
Uri sourcePathToUri(String source, {bool windows}) {
  if (windows == null) {
    // Running on the web the Platform check will fail, and we can't use
    // fromEnvironment because internally it's set to true for dart.library.io.
    // So just catch the exception and if it fails then we're definitely not on
    // Windows.
    try {
      windows = Platform.isWindows;
    } catch (e) {
      windows = false;
    }
  }
  if (windows) {
    source = source.replaceAll("\\", "/");
  }

  Uri result = Uri.base.resolve(source);
  if (windows && result.scheme.length == 1) {
    // Assume c: or similar --- interpret as file path.
    return Uri.file(source, windows: true);
  }
  return result;
}

Uri sourcePathToRelativeUri(String source, {bool windows}) {
  var uri = sourcePathToUri(source, windows: windows);
  if (uri.scheme == 'file') {
    var uriPath = uri.path;
    var root = Uri.base.path;
    if (uriPath.startsWith(root)) {
      return path.toUri(uriPath.substring(root.length));
    }
  }
  return uri;
}

/// Adjusts the source paths in [sourceMap] to be relative to [sourceMapPath],
/// and returns the new map.  Relative paths are in terms of URIs ('/'), not
/// local OS paths (e.g., windows '\').
// TODO(jmesserly): find a new home for this.
Map placeSourceMap(Map sourceMap, String sourceMapPath,
    Map<String, String> bazelMappings, String customScheme) {
  var map = Map.from(sourceMap);
  // Convert to a local file path if it's not.
  sourceMapPath = path.fromUri(sourcePathToUri(sourceMapPath));
  var sourceMapDir = path.dirname(path.absolute(sourceMapPath));
  var list = (map['sources'] as List).toList();
  map['sources'] = list;

  String makeRelative(String sourcePath) {
    var uri = sourcePathToUri(sourcePath);
    var scheme = uri.scheme;
    if (scheme == 'dart' || scheme == 'package' || scheme == customScheme) {
      return sourcePath;
    }

    // Convert to a local file path if it's not.
    sourcePath = path.absolute(path.fromUri(uri));

    // Allow bazel mappings to override.
    var match = bazelMappings[sourcePath];
    if (match != null) return match;

    // Fall back to a relative path against the source map itself.
    sourcePath = path.relative(sourcePath, from: sourceMapDir);

    // Convert from relative local path to relative URI.
    return path.toUri(sourcePath).path;
  }

  for (int i = 0; i < list.length; i++) {
    list[i] = makeRelative(list[i] as String);
  }
  map['file'] = makeRelative(map['file'] as String);
  return map;
}
