// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';

import 'package:front_end/src/api_unstable/ddc.dart'
    show parseExperimentalArguments;
import 'package:path/path.dart' as p;

import '../compiler/module_builder.dart';

/// Compiler options for the `dartdevc` backend.
class Options {
  /// Whether to emit the source mapping file.
  ///
  /// This supports debugging the original source code instead of the generated
  /// code.
  final bool sourceMap;

  /// Whether to emit the source mapping file in the program text, so the
  /// runtime can enable synchronous stack trace deobfuscation.
  final bool inlineSourceMap;

  /// Whether to emit the full compiled kernel.
  ///
  /// This is used by expression compiler worker, launched from the debugger
  /// in webdev and google3 scenarios, for expression evaluation features.
  /// Full kernel for compiled files is needed to be able to compile
  /// expressions on demand in the current scope of a breakpoint.
  final bool emitFullCompiledKernel;

  /// Whether to emit a summary file containing API signatures.
  ///
  /// This is required for a modular build process.
  final bool summarizeApi;

  // Whether to enable assertions.
  final bool enableAsserts;

  /// Whether to compile code in a more permissive REPL mode allowing access
  /// to private members across library boundaries.
  ///
  /// This should only set `true` by our REPL compiler.
  bool replCompile;

  /// Whether to emit the debug metadata
  ///
  /// Debugger uses this information about to construct mapping between
  /// modules and libraries that otherwise requires expensive communication with
  /// the browser.
  final bool emitDebugMetadata;

  /// Whether to emit the debug symbols
  ///
  /// Debugger uses this information about to construct mapping between
  /// dart and js objects that otherwise requires expensive communication with
  /// the browser.
  final bool emitDebugSymbols;

  final Map<String, String> summaryModules;

  final List<ModuleFormat> moduleFormats;

  /// The name of the module.
  ///
  /// This is used to support file concatenation. The JS module will contain its
  /// module name inside itself, allowing it to declare the module name
  /// independently of the file.
  final String moduleName;

  /// Custom scheme to indicate a multi-root uri.
  final String multiRootScheme;

  /// Path to set multi-root files relative to when generating source-maps.
  final String? multiRootOutputPath;

  /// Experimental language features that are enabled/disabled, see
  /// [the spec](https://github.com/dart-lang/sdk/blob/master/docs/process/experimental-flags.md)
  /// for more details.
  final Map<String, bool> experiments;

  final bool soundNullSafety;

  /// Whether or not the `--canary` flag was specified during compilation.
  final bool canaryFeatures;

  /// When `true` the [Component] will be compiled into a format compatible with
  /// hot reload.
  ///
  /// The output will still be a single file containing each library in an
  /// isolated namespace.
  final bool emitLibraryBundle;

  /// Whether the compiler is generating a dynamic module.
  final bool dynamicModule;

  /// When `true` stars "*" will appear to represent legacy types when printing
  /// runtime types in the compiled application.
  final bool printLegacyStars = false;

  /// Raw precompiled macro options, each of the format
  /// `<program-uri>;<macro-library-uri>`.
  ///
  /// Multiple library URIs may be provided separated by additional semicolons.
  final List<String> precompiledMacros;

  /// The serialization mode to use for macro communication.
  final String? macroSerializationMode;

  Options(
      {this.sourceMap = true,
      this.inlineSourceMap = false,
      this.summarizeApi = true,
      this.enableAsserts = true,
      this.replCompile = false,
      this.emitDebugMetadata = false,
      this.emitDebugSymbols = false,
      this.emitFullCompiledKernel = false,
      this.summaryModules = const {},
      this.moduleFormats = const [],
      required this.moduleName,
      this.multiRootScheme = 'org-dartlang-app',
      this.multiRootOutputPath,
      this.experiments = const {},
      this.soundNullSafety = true,
      this.canaryFeatures = false,
      this.dynamicModule = false,
      this.precompiledMacros = const [],
      this.macroSerializationMode})
      : emitLibraryBundle = canaryFeatures &&
            moduleFormats.length == 1 &&
            moduleFormats.single == ModuleFormat.ddc;

  Options.fromArguments(ArgResults args)
      : this(
            sourceMap: args['source-map'] as bool,
            inlineSourceMap: args['inline-source-map'] as bool,
            summarizeApi: args['summarize'] as bool,
            enableAsserts: args['enable-asserts'] as bool,
            replCompile: args['repl-compile'] as bool,
            emitDebugMetadata: args['experimental-emit-debug-metadata'] as bool,
            emitDebugSymbols: args['emit-debug-symbols'] as bool,
            emitFullCompiledKernel:
                args['experimental-output-compiled-kernel'] as bool,
            summaryModules:
                _parseCustomSummaryModules(args['summary'] as List<String>),
            moduleFormats: parseModuleFormatOption(args),
            moduleName: _getModuleName(args),
            multiRootScheme: args['multi-root-scheme'] as String,
            multiRootOutputPath: args['multi-root-output-path'] as String?,
            experiments: parseExperimentalArguments(
                args['enable-experiment'] as List<String>),
            soundNullSafety: args['sound-null-safety'] as bool,
            canaryFeatures: args['canary'] as bool,
            dynamicModule: args['dynamic-module'] as bool,
            precompiledMacros: args['precompiled-macro'] as List<String>,
            macroSerializationMode:
                args['macro-serialization-mode'] as String?);

  Options.fromSdkRequiredArguments(ArgResults args)
      : this(
            summarizeApi: false,
            moduleFormats: parseModuleFormatOption(args),
            // When compiling the SDK use dart_sdk as the default. This is the
            // assumed name in various places around the build systems.
            moduleName:
                args['module-name'] != null ? _getModuleName(args) : 'dart_sdk',
            multiRootScheme: args['multi-root-scheme'] as String,
            multiRootOutputPath: args['multi-root-output-path'] as String?,
            experiments: parseExperimentalArguments(
                args['enable-experiment'] as List<String>),
            soundNullSafety: args['sound-null-safety'] as bool,
            canaryFeatures: args['canary'] as bool);

  static void addArguments(ArgParser parser, {bool hide = true}) {
    addSdkRequiredArguments(parser, hide: hide);

    parser
      ..addMultiOption('summary',
          abbr: 's',
          help: 'API summary file(s) of imported libraries, optionally\n'
              'with module import path: -s path.dill=js/import/path')
      ..addFlag('summarize',
          help: 'Emit an API summary file.', defaultsTo: true, hide: hide)
      ..addFlag('source-map',
          help: 'Emit source mapping.', defaultsTo: true, hide: hide)
      ..addFlag('inline-source-map',
          help: 'Emit source mapping inline.', defaultsTo: false, hide: hide)
      ..addFlag('enable-asserts',
          help: 'Enable assertions.', defaultsTo: true, hide: hide)
      ..addFlag('repl-compile',
          help: 'Compile in a more permissive REPL mode, allowing access'
              ' to private members across library boundaries. This should'
              ' only be used by debugging tools.',
          defaultsTo: false,
          hide: hide)
      // TODO(41852) Define a process for breaking changes before graduating from
      // experimental.
      ..addFlag('experimental-emit-debug-metadata',
          help: 'Experimental option for compiler development.\n'
              'Output a metadata file for debug tools next to the .js output.',
          defaultsTo: false,
          hide: true)
      ..addFlag('emit-debug-symbols',
          help: 'Experimental option for compiler development.\n'
              'Output a symbols file for debug tools next to the .js output.',
          defaultsTo: false,
          hide: true)
      ..addFlag('experimental-output-compiled-kernel',
          help: 'Experimental option for compiler development.\n'
              'Output a full kernel file for currently compiled module next to '
              'the .js output.',
          defaultsTo: false,
          hide: true)
      ..addMultiOption('precompiled-macro',
          help:
              'Configuration for precompiled macro binaries or kernel files.\n'
              'The expected format of this option is as follows: '
              '<absolute-path-to-binary>;<macro-library-uri>\nFor example: '
              '--precompiled-macro="/path/to/compiled/macro;'
              'package:some_macro/some_macro.dart". Multiple library uris may be '
              'passed as well (separated by semicolons).',
          hide: true)
      ..addOption('macro-serialization-mode',
          help: 'The serialization mode for communicating with macros.',
          allowed: ['bytedata', 'json'],
          defaultsTo: 'bytedata')
      ..addFlag('dynamic-module',
          help: 'Compile to generate a dynamic module',
          negatable: false,
          defaultsTo: false);
  }

  /// Adds only the arguments used to compile the SDK from a full dill file.
  ///
  /// NOTE: The 'module-name' option will have a special default value of
  /// 'dart_sdk' when compiling the SDK.
  /// See [SharedOptions.fromSdkRequiredArguments].
  static void addSdkRequiredArguments(ArgParser parser, {bool hide = true}) {
    addModuleFormatOptions(parser, hide: hide);
    parser
      ..addMultiOption('out', abbr: 'o', help: 'Output file (required).')
      ..addOption('module-name',
          help: 'The output module name, used in some JS module formats.\n'
              'Defaults to the output file name (without .js).')
      ..addOption('multi-root-scheme',
          help: 'The custom scheme to indicate a multi-root uri.',
          defaultsTo: 'org-dartlang-app')
      ..addOption('multi-root-output-path',
          help: 'Path to set multi-root files relative to when generating'
              ' source-maps.',
          hide: true)
      ..addMultiOption('enable-experiment',
          help: 'Enable/disable experimental language features.', hide: hide)
      ..addFlag('sound-null-safety',
          help: 'Compile for sound null safety at runtime.',
          negatable: true,
          defaultsTo: true)
      ..addFlag('canary',
          help: 'Enable all compiler features under active development. '
              'This option is intended for compiler development only. '
              'Canary features are likely to be unstable and can be removed '
              'without warning.',
          defaultsTo: false,
          hide: true);
  }

  static String _getModuleName(ArgResults args) {
    var moduleName = args['module-name'] as String?;
    if (moduleName == null) {
      var outPaths = args['out'] as List<String>;
      if (outPaths.isEmpty) {
        throw UnsupportedError(
            'No module name provided and unable to synthesize one without any '
            'output paths.');
      }
      var outPath = outPaths.first;
      moduleName = p.basenameWithoutExtension(outPath);
    }
    // TODO(jmesserly): this should probably use sourcePathToUri.
    //
    // Also we should not need this logic if the user passed in the module name
    // explicitly. It is here for backwards compatibility until we can confirm
    // that build systems do not depend on passing windows-style paths here.
    return p.toUri(moduleName).toString();
  }
}

/// Finds explicit module names of the form `path=name` in [summaryPaths],
/// and returns the path to mapping in an ordered map from `path` to `name`.
///
/// A summary path can contain "=" followed by an explicit module name to
/// allow working with summaries whose physical location is outside of the
/// module root directory.
Map<String, String> _parseCustomSummaryModules(List<String> summaryPaths,
    [String? moduleRoot, String? summaryExt]) {
  var pathToModule = <String, String>{};
  for (var summaryPath in summaryPaths) {
    var equalSign = summaryPath.indexOf('=');
    String modulePath;
    var summaryPathWithoutExt = summaryExt != null
        ? summaryPath.substring(
            0,
            // Strip off the extension, including the last `.`.
            summaryPath.length - (summaryExt.length + 1))
        : p.withoutExtension(summaryPath);
    if (equalSign != -1) {
      modulePath = summaryPath.substring(equalSign + 1);
      summaryPath = summaryPath.substring(0, equalSign);
    } else if (moduleRoot != null && p.isWithin(moduleRoot, summaryPath)) {
      // TODO: Determine if this logic is still needed.
      modulePath = p.url.joinAll(
          p.split(p.relative(summaryPathWithoutExt, from: moduleRoot)));
    } else {
      modulePath = p.basename(summaryPathWithoutExt);
    }
    pathToModule[summaryPath] = modulePath;
  }
  return pathToModule;
}

/// Taken from analyzer to implement `--ignore-unrecognized-flags`
List<String> filterUnknownArguments(List<String> args, ArgParser parser) {
  if (!args.contains('--ignore-unrecognized-flags')) return args;

  var knownOptions = <String>{};
  var knownAbbreviations = <String>{};
  parser.options.forEach((String name, Option option) {
    knownOptions.add(name);
    var abbreviation = option.abbr;
    if (abbreviation != null) {
      knownAbbreviations.add(abbreviation);
    }
    if (option.negatable != null && option.negatable!) {
      knownOptions.add('no-$name');
    }
  });

  String optionName(int prefixLength, String arg) {
    var equalsOffset = arg.lastIndexOf('=');
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
