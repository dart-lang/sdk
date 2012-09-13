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
#library('dartdoc');

#import('dart:io');

// TODO(rnystrom): Use "package:" URL (#4968).
#import('../lib/dartdoc.dart');

// TODO(johnniwinther): Note that [IN_SDK] gets initialized to true when this
// file is modified by the SDK deployment script. If you change, be sure to test
// that dartdoc still works when run from the built SDK directory.
const bool _IN_SDK = false;

// TODO(johnniwinther): Trailing slashes matter due to the use of [libPath] as
// a base URI with [Uri.resolve].
/// Relative path to the library in which dart2js resides.
Path get libPath => _IN_SDK
    ? scriptDir.append('../../../lib/dart2js/')
    : scriptDir.append('../../../');

/**
 * Run this from the `pkg/dartdoc` directory.
 */
main() {
  final args = new Options().arguments;

  final dartdoc = new Dartdoc();

  if (args.isEmpty()) {
    print('No arguments provided.');
    printUsage();
    return;
  }

  final entrypoints = <Path>[];

  var i = 0;
  while (i < args.length) {
    final arg = args[i];
    if (!arg.startsWith('--')) {
      // The remaining arguments must be entry points.
      break;
    }

    switch (arg) {
      case '--no-code':
        dartdoc.includeSource = false;
        break;

      case '--mode=static':
        dartdoc.mode = MODE_STATIC;
        break;

      case '--mode=live-nav':
        dartdoc.mode = MODE_LIVE_NAV;
        break;

      case '--generate-app-cache':
      case '--generate-app-cache=true':
        dartdoc.generateAppCache = true;
        break;

      case '--omit-generation-time':
        dartdoc.omitGenerationTime = true;
        break;
      case '--verbose':
        dartdoc.verbose = true;
        break;
      case '--include-api':
        dartdoc.includeApi = true;
        break;
      case '--link-api':
        dartdoc.linkToApi = true;
        break;

      default:
        if (arg.startsWith('--out=')) {
          dartdoc.outputDir =
              new Path.fromNative(arg.substring('--out='.length));
        } else if (arg.startsWith('--include-lib=')) {
          dartdoc.includedLibraries =
              arg.substring('--include-lib='.length).split(',');
        } else if (arg.startsWith('--exclude-lib=')) {
          dartdoc.excludedLibraries =
              arg.substring('--exclude-lib='.length).split(',');
        } else {
          print('Unknown option: $arg');
          printUsage();
          return;
        }
        break;
    }
    i++;
  }
  while (i < args.length) {
    final arg = args[i];
    entrypoints.add(new Path.fromNative(arg));
    i++;
  }

  if (entrypoints.isEmpty()) {
    print('No entrypoints provided.');
    printUsage();
    return;
  }

  cleanOutputDirectory(dartdoc.outputDir);

  dartdoc.documentLibraries(entrypoints, libPath);

  Future compiled = compileScript(dartdoc.mode, dartdoc.outputDir, libPath);
  Future filesCopied = copyDirectory(scriptDir.append('../static'),
                                     dartdoc.outputDir);

  Futures.wait([compiled, filesCopied]).then((_) {
    dartdoc.cleanup();
    print('Documented ${dartdoc.totalLibraries} libraries, '
          '${dartdoc.totalTypes} types, and ${dartdoc.totalMembers} members.');
  });
}

void printUsage() {
  print('''
Usage dartdoc [options] <entrypoint(s)>
[options] include
 --no-code                   Do not include source code in the documentation.

 --mode=static               Generates completely static HTML containing
                             everything you need to browse the docs. The only
                             client side behavior is trivial stuff like syntax
                             highlighting code.

 --mode=live-nav             (default) Generated docs do not include baked HTML
                             navigation. Instead, a single `nav.json` file is
                             created and the appropriate navigation is generated
                             client-side by parsing that and building HTML.
                                This dramatically reduces the generated size of
                             the HTML since a large fraction of each static page
                             is just redundant navigation links.
                                In this mode, the browser will do a XHR for
                             nav.json which means that to preview docs locally,
                             you will need to enable requesting file:// links in
                             your browser or run a little local server like
                             `python -m SimpleHTTPServer`.

 --generate-app-cache        Generates the App Cache manifest file, enabling
                             offline doc viewing.

 --out=<dir>                 Generates files into directory <dir>. If omitted
                             the files are generated into ./docs/

 --link-api                  Link to the online language API in the generated
                             documentation. The option overrides inclusion
                             through --include-api or --include-lib.

 --include-api               Include the used API libraries in the generated
                             documentation.  If the --link-api option is used,
                             this option is ignored.

 --include-lib=<libs>        Use this option to explicitly specify which
                             libraries to include in the documentation. If
                             omitted, all used libraries are included by
                             default. <libs> is comma-separated list of library
                             names.

 --exclude-lib=<libs>        Use this option to explicitly specify which
                             libraries to exclude from the documentation. If
                             omitted, no libraries are excluded. <libs> is
                             comma-separated list of library names.

 --verbose                   Print verbose information during generation.
''');
}