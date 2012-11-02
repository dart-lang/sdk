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

import 'dart:io';

// TODO(rnystrom): Use "package:" URL (#4968).
import '../lib/dartdoc.dart';
import '../../args/lib/args.dart';

/**
 * Run this from the `pkg/dartdoc` directory.
 */
main() {
  // Need this because ArgParser.getUsage doesn't show command invocation.
  final USAGE = 'Usage dartdoc [options] <entrypoint(s)>\n[options] include:';

  final args = new Options().arguments;

  final dartdoc = new Dartdoc();

  final argParser = new ArgParser();

  final Path libPath = scriptDir.append('../../../');
  Path pkgPath = scriptDir.append('../../../pkg/');

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
          dartdoc.outputDir = new Path.fromNative(outDir);
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
          dartdoc.excludedLibraries = allLibs;
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

  argParser.addOption('pkg',
      help: 'Sets the package directory to the specified directory.\n'
        'If omitted the package directory is the SDK pkg/ dir',
      callback: (pkgDir) {
        if(pkgDir != null) {
          pkgPath = new Path.fromNative(pkgDir);
        }
      });

  dartdoc.dartdocPath = libPath.append('pkg/dartdoc');

  if (args.isEmpty) {
    print('No arguments provided.');
    print(USAGE);
    print(argParser.getUsage());
    return;
  }

  final entrypoints = <Path>[];
  try {
    final option = argParser.parse(args);
    for(final arg in option.rest) {
      entrypoints.add(new Path.fromNative(arg));
    }
  } on FormatException catch (e) {
    print(e.message);
    print(USAGE);
    print(argParser.getUsage());
    return;
  }

  if (entrypoints.isEmpty) {
    print('No entrypoints provided.');
    print(argParser.getUsage());
    return;
  }

  cleanOutputDirectory(dartdoc.outputDir);

  dartdoc.documentLibraries(entrypoints, libPath, pkgPath);

  Future compiled = compileScript(dartdoc.mode, dartdoc.outputDir, libPath);
  Future filesCopied = copyDirectory(scriptDir.append('../static'),
                                     dartdoc.outputDir);

  Futures.wait([compiled, filesCopied]).then((_) {
    dartdoc.cleanup();
    print('Documented ${dartdoc.totalLibraries} libraries, '
          '${dartdoc.totalTypes} types, and ${dartdoc.totalMembers} members.');
  });
}
