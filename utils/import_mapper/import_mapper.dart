// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('import_mapper');

#import('dart:io');
// TODO(rnystrom): This should be dart:json.
#import('../../lib/json/json.dart');
#import('../../frog/lang.dart');
#import('../../frog/file_system.dart');
#import('../../frog/file_system_vm.dart');

typedef String ImportHook(ImportContext context, String name);

/**
 * Provides contextual information about the current import and environment
 * that the import hook can use to resolve an import.
 */
class ImportContext {
  // TODO(rnystrom): Fill in context here as we figure out what we want.
}

/** The generated import map. */
Map<String, String> _importMap;

ImportHook _hook;

/**
 * Uses the given import hook to generate an import map for all of the
 * libraries used by a [entrypoint]. Returns the generated map object.
 */
Map<String, String> generateImportMap(String entrypoint, ImportHook hook) {
  _importMap = <String>{};
  _hook = hook;

  // Initialize frog.
  final files = new VMFileSystem();
  parseOptions('../../frog', ['', '', '--libdir=../../frog/lib'], files);
  initializeWorld(files);
  _importMap = {};

  _walkLibrary(entrypoint);

  return _importMap;
}

/**
 * Uses the given import hook to generate an import map for all of the
 * libraries used by a given entrypoint. The entrypoint is assumed to be
 * provided as the first VM command line argument.
 *
 * Prints the import map data (a JSON object) to stdout.
 */
void printImportMap(ImportHook hook) {
  // The entrypoint of the library to generate an import map for.
  final argv = (new Options()).arguments;
  final entrypoint = argv[argv.length - 1];

  final map = generateImportMap(entrypoint, hook);
  print(JSON.stringify(map));
}

/**
 * Recursively traverses all of the `#import()` directives in the given library
 * entrypoint and runs the import hook on them. [entrypoint] should be a path
 * to a library file.
 */
void _walkLibrary(String entrypoint) {
  // TODO(rnystrom): Do more here when there's context we care about.
  final context = new ImportContext();

  final text = _readFile(entrypoint);
  final source = new SourceFile(entrypoint, text);
  final parser = new Parser(source, diet: true);

  final definitions = parser.compilationUnit();

  for (final definition in definitions) {
    // Only look at #import directives.
    if (definition is! DirectiveDefinition) continue;
    DirectiveDefinition directive = definition;
    if (directive.name.name != 'import') continue;

    // The first argument is expected to be a string literal.
    final name = directive.arguments[0].value.value.actualValue;

    // Only map a given import once.
    // TODO(rnystrom): Should invoke the hook again and ensure that it gets
    // the same result. It should be an error if the hook isn't
    // referentially transparent.
    if (!_importMap.containsKey(name)) {
      final uri = _hook(context, name);
      _importMap[name] = uri;

      // Recurse into this library.
      // TODO(rnystrom): Hackish. How should we handle corelib stuff?
      if (!uri.startsWith('dart:')) {
        _walkLibrary(_getFullPath(entrypoint, uri));
      }
    }
  }
}

// TODO(rnystrom): Copied from frog/library.dart (makeFullPath).
/**
 * Given the path to a library containing an #import() and the resolved URI for
 * that import, gives the full path to that library.
 */
String _getFullPath(String importingLibrary, String filename) {
  if (filename.startsWith('dart:')) return filename;
  // TODO(jmesserly): replace with node.js path.resolve
  if (filename.startsWith('/')) return filename;
  if (filename.startsWith('file:///')) return filename;
  if (filename.startsWith('http://')) return filename;
  if (const RegExp('^[a-zA-Z]:/').hasMatch(filename)) return filename;
  return joinPaths(dirname(importingLibrary), filename);
}

String _readFile(String filename) {
  // TODO(rnystrom): There must be an easier way than this.
  var file = (new File(filename)).openSync();
  var length = file.lengthSync();
  var buffer = new List<int>(length);
  var bytes = file.readListSync(buffer, 0, length);
  file.closeSync();
  return new String.fromCharCodes(buffer);
}
