// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * To generate docs for a library, run this script with the path to an
 * entrypoint .dart file, like:
 *
 *     $ dart dartdoc.dart foo.dart
 *
 * This will create a "docs" directory with the docs for your libraries. To
 * create these beautiful docs, dartdoc parses your library and every library
 * it imports (recursively). From each library, it parses all classes and
 * members, finds the associated doc comments and builds crosslinked docs from
 * them.
 */
library dartdoc;

import 'dart:async';
import 'dart:io';

import '../lib/dartdoc.dart';
import '../lib/src/dartdoc/utils.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/**
 * Run this from the `lib/_internal/dartdoc` directory.
 */
main(List<String> arguments) {
  // Need this because ArgParser.getUsage doesn't show command invocation.
  final USAGE = 'Usage dartdoc [options] <entrypoint(s)>\n[options] include:';

  final dartdoc = new Dartdoc();

  final argParser = new ArgParser();

  String libPath = path.join(scriptDir, '..', '..', '..', '..');

  String packageRoot;

  argParser.addFlag('no-code',
      help: 'Do not include source code in the documentation.',
      defaultsTo: false, negatable: false,
      callback: (noCode) => dartdoc.includeSource = !noCode);

  argParser.addOption('mode', abbr: 'm',
      help: 'Define how HTML pages are generated.',
      allowed: ['static', 'live-nav'], allowedHelp: {
        'static': 'Generates completely static HTML containing\n'
          'everything you need to browse the docs. The only\n'
          'client side behavior is trivial stuff like syntax\n'
          'highlighting code, and the find-as-you-type search\n'
          'box.',
        'live-nav': '(Default) Generated docs do not included baked HTML\n'
          'navigation. Instead a single `nav.json` file is\n'
          'created and the appropriate navigation is generated\n'
          'client-side by parsing that and building HTML.\n'
          '\tThis dramatically reduces the generated size of\n'
          'the HTML since a large fraction of each static page\n'
          'is just redundant navigation links.\n'
          '\tIn this mode, the browser will do a XHR for\n'
          'nav.json which means that to preview docs locallly,\n'
          'you will need to enable requesting file:// links in\n'
          'your browser or run a little local server like\n'
          '`python -m  SimpleHTTPServer`.'},
        defaultsTo: 'live-nav',
        callback: (genMode) {
          dartdoc.mode = (genMode == 'static' ? MODE_STATIC : MODE_LIVE_NAV);
        });

  argParser.addFlag('generate-app-cache',
      help: 'Generates the App Cache manifest file, enabling\n'
        'offline doc viewing.',
        defaultsTo: false, negatable: false,
        callback: (generate) => dartdoc.generateAppCache = generate);

  argParser.addFlag('omit-generation-time',
      help: 'Omits generation timestamp from output.',
      defaultsTo: false, negatable: false,
      callback: (genTimestamp) => dartdoc.omitGenerationTime = genTimestamp);

  argParser.addFlag('verbose', abbr: 'v',
      help: 'Print verbose information during generation.',
      defaultsTo: false, negatable: false,
      callback: (verb) => dartdoc.verbose = verb);

  argParser.addFlag('include-api',
      help: 'Include the used API libraries in the generated\n'
        'documentation. If the --link-api option is used,\n'
        'this option is ignored.',
      defaultsTo: false, negatable: false,
      callback: (incApi) => dartdoc.includeApi = incApi);

  argParser.addFlag('link-api',
      help: 'Link to the online language API in the generated\n'
        'documentation. The option overrides inclusion\n'
        'through --include-api or --include-lib.',
      defaultsTo: false, negatable: false,
      callback: (linkApi) => dartdoc.linkToApi = linkApi);

  argParser.addFlag('show-private',
      help: 'Document private types and members.',
      defaultsTo: false,
      callback: (showPrivate) => dartdoc.showPrivate = showPrivate);

  argParser.addFlag('inherit-from-object',
      help: 'Show members inherited from Object.',
      defaultsTo: false, negatable: false,
      callback: (inherit) => dartdoc.inheritFromObject = inherit);

  argParser.addFlag('enable-diagnostic-colors', negatable: false);

  argParser.addOption('out',
      help: 'Generates files into directory specified. If\n'
        'omitted the files are generated into ./docs/',
      callback: (outDir) {
        if(outDir != null) {
          dartdoc.outputDir = outDir;
        }
      });

  argParser.addOption('include-lib',
      help: 'Use this option to explicitly specify which\n'
        'libraries to include in the documentation. If\n'
        'omitted, all used libraries are included by\n'
        'default. Specify a comma-separated list of\n'
        'library names, or call this option multiple times.',
      callback: (incLibs) {
        if(!incLibs.isEmpty) {
          List<String> allLibs = new List<String>();
          for(final lst in incLibs) {
            var someLibs = lst.split(',');
            for(final lib in someLibs) {
              allLibs.add(lib);
            }
          }
          dartdoc.includedLibraries = allLibs;
        }
      }, allowMultiple: true);

  argParser.addOption('exclude-lib',
      help: 'Use this option to explicitly specify which\n'
        'libraries to exclude from the documentation. If\n'
        'omitted, no libraries are excluded. Specify a\n'
        'comma-separated list of library names, or call\n'
        'this option multiple times.',
      callback: (excLibs) {
        if(!excLibs.isEmpty) {
          List<String> allLibs = new List<String>();
          for(final lst in excLibs) {
            var someLibs = lst.split(',');
            for(final lib in someLibs) {
              allLibs.add(lib);
            }
          }
          dartdoc.excludedLibraries = allLibs;
        }
      }, allowMultiple: true);

  argParser.addOption('package-root',
      help: 'Sets the package directory to the specified directory.\n'
        'If omitted the package directory is the closest packages directory to'
        ' the entrypoint.',
      callback: (packageDir) {
        if(packageDir != null) {
          packageRoot = packageDir;
        }
      });

  argParser.addOption('library-root',
      help: 'Sets the library root directory to the specified directory.',
      callback: (libraryRoot) {
        if (libraryRoot != null) {
          libPath = libraryRoot;
        }
      });

  // TODO(amouravski): This method is deprecated. Remove on April 22.
  argParser.addOption('pkg',
      help: 'Deprecated: same as --package-root.',
      callback: (packageDir) {
        if(packageDir != null) {
          packageRoot = packageDir;
        }
      });

  dartdoc.dartdocPath = path.join(libPath, 'lib', '_internal', 'dartdoc');

  if (arguments.isEmpty) {
    print('No arguments provided.');
    print(USAGE);
    print(argParser.getUsage());
    exit(1);
  }

  final entrypoints = <Uri>[];
  try {
    final option = argParser.parse(arguments, allowTrailingOptions: true);

    // This checks to see if the root of all entrypoints is the same.
    // If it is not, then we display a warning, as package imports might fail.
    var entrypointRoot;
    for (final entrypoint in option.rest) {
      var uri = Uri.parse(entrypoint);

      // If it looks like it was a file path (no scheme, or a one letter scheme
      // which is likely a drive letter on Windows), turn it into a file URL.
      if (uri.scheme == '' || uri.scheme.length == 1) {
        uri = path.toUri(entrypoint);
      }

      entrypoints.add(uri);

      if (uri.scheme != 'file') continue;
      if (entrypointRoot == null) {
        entrypointRoot = path.dirname(entrypoint);
      } else if (entrypointRoot != path.dirname(entrypoint)) {
        print('Warning: entrypoints are at different directories. "package:"'
            ' imports may fail.');
      }
    }
  } on FormatException catch (e) {
    print(e.message);
    print(USAGE);
    print(argParser.getUsage());
    exit(1);
  }

  if (entrypoints.isEmpty) {
    print('No entrypoints provided.');
    print(argParser.getUsage());
    exit(1);
  }

  if (packageRoot == null) packageRoot = _getPackageRoot(entrypoints);

  cleanOutputDirectory(dartdoc.outputDir);

  // Start the analysis and documentation.
  dartdoc.documentLibraries(entrypoints, libPath, packageRoot)
    // Prepare the dart2js script code and copy static resources.
    // TODO(amouravski): move compileScript out and pre-generate the client
    // scripts. This takes a long time and the js hardly ever changes.
    .then((_) => compileScript(dartdoc.mode, dartdoc.outputDir, libPath,
          dartdoc.tmpPath))
    .then((_) => copyDirectory(
          path.join(libPath, 'lib', '_internal', 'dartdoc', 'static'),
          dartdoc.outputDir))
    .then((_) {
      print(dartdoc.status);
      if (dartdoc.totals == 0) {
        exit(1);
      }
    })
    .catchError((e, trace) {
      print('Error: generation failed: ${e}');
      if (trace != null) print("StackTrace: $trace");
      dartdoc.cleanup();
      exit(1);
    })
    .whenComplete(() => dartdoc.cleanup());
}

String _getPackageRoot(List<Uri> entrypoints) {
  // Check if there's a `packages` directory in the entry point directory.
  var fileEntrypoint = entrypoints.firstWhere(
      (entrypoint) => entrypoint.scheme == 'file',
      orElse: () => null);
  if (fileEntrypoint == null) return;

  var script = path.normalize(path.absolute(path.fromUri(fileEntrypoint)));
  var dir = path.join(path.dirname(script), 'packages/');
  if (new Directory(dir).existsSync()) return dir;

  // If there is not, then check if the entrypoint is somewhere in a `lib`
  // directory.
  var parts = path.split(path.dirname(script));
  var libDir = parts.lastIndexOf('lib');
  if (libDir > 0) {
    return path.join(path.joinAll(parts.take(libDir)), 'packages');
  } else {
    return null;
  }
}
