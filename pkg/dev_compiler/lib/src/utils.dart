/// Holds a couple utility functions used at various places in the system.
library ddc.src.utils;

import 'dart:io';

import 'package:analyzer/src/generated/ast.dart'
    show
        ImportDirective,
        ExportDirective,
        PartDirective,
        CompilationUnit,
        Identifier;
import 'package:analyzer/src/generated/engine.dart'
    show ParseDartTask, AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/analyzer.dart' show parseDirectives;

bool isDartPrivateLibrary(LibraryElement library) {
  var uri = library.source.uri;
  if (uri.scheme != "dart") return false;
  return Identifier.isPrivateName(uri.path);
}

// Choose a canonical name for library
String libraryName(String name, Uri uri) {
  if (name != null && name != '') return name;

  // Fall back on the file name.
  var tail = uri.pathSegments.last;
  if (tail.endsWith('.dart')) tail = tail.substring(0, tail.length - 5);
  return tail;
}

// Choose a canonical name for library element
String libraryNameFromLibraryElement(LibraryElement library) {
  return libraryName(library.name, library.source.uri);
}

/// Returns all libraries transitively imported or exported from [start].
Iterable<LibraryElement> reachableLibraries(LibraryElement start) {
  var results = <LibraryElement>[];
  var seen = new Set();
  void find(LibraryElement lib) {
    if (seen.contains(lib)) return;
    seen.add(lib);
    results.add(lib);
    lib.importedLibraries.forEach(find);
    lib.exportedLibraries.forEach(find);
  }
  find(start);
  return results;
}

/// Returns all sources transitively imported or exported from [start] in
/// post-visit order. Internally this uses digest parsing to read only
/// directives from each source, that way library resolution can be done
/// bottom-up and improve performance of the analyzer internal cache.
Iterable<Source> reachableSources(Source start, AnalysisContext context) {
  var results = <Source>[];
  var seen = new Set();
  void find(Source source) {
    if (seen.contains(source)) return;
    seen.add(source);
    _importsAndExportsOf(source, context).forEach(find);
    results.add(source);
  }
  find(start);
  return results;
}

/// Returns sources that are imported or exported in [source] (parts are
/// excluded).
Iterable<Source> _importsAndExportsOf(Source source, AnalysisContext context) {
  var unit = parseDirectives(source.contents.data, name: source.fullName);
  return unit.directives
      .where((d) => d is ImportDirective || d is ExportDirective)
      .map((d) {
    var res = ParseDartTask.resolveDirective(context, source, d, null);
    if (res == null) print('error: couldn\'t resolve $d');
    return res;
  }).where((d) => d != null);
}

/// Returns sources that are included with part directives from [unit].
Iterable<Source> partsOf(CompilationUnit unit, AnalysisContext context) {
  return unit.directives.where((d) => d is PartDirective).map((d) {
    var res =
        ParseDartTask.resolveDirective(context, unit.element.source, d, null);
    if (res == null) print('error: couldn\'t resolve $d');
    return res;
  }).where((d) => d != null);
}

/// Returns an ANSII color escape sequence corresponding to [levelName]. Colors
/// are defined for: severe, error, warning, or info. Returns null if the level
/// name is not recognized.
String colorOf(String levelName) {
  levelName = levelName.toLowerCase();
  if (levelName == 'shout' || levelName == 'severe' || levelName == 'error') {
    return _RED_COLOR;
  }
  if (levelName == 'warning') return _MAGENTA_COLOR;
  if (levelName == 'info') return _CYAN_COLOR;
  return null;
}

const String _RED_COLOR = '\u001b[31m';
const String _MAGENTA_COLOR = '\u001b[35m';
const String _CYAN_COLOR = '\u001b[36m';

class OutWriter {
  final String _path;
  final StringBuffer _sb = new StringBuffer();
  int _indent = 0;
  String _prefix = "";
  bool _needsIndent = true;

  OutWriter(this._path);

  void write(String string, [int indent = 0]) {
    if (indent < 0) inc(indent);

    var lines = string.split('\n');
    for (var i = 0, end = lines.length - 1; i < end; i++) {
      _writeln(lines[i]);
    }
    _write(lines.last);

    if (indent > 0) inc(indent);
  }

  void _writeln(String string) {
    if (_needsIndent && string.isNotEmpty) _sb.write(_prefix);
    _sb.writeln(string);
    _needsIndent = true;
  }

  void _write(String string) {
    if (_needsIndent && string.isNotEmpty) {
      _sb.write(_prefix);
      _needsIndent = false;
    }
    _sb.write(string);
  }

  void inc([int n = 2]) {
    _indent = _indent + n;
    assert(_indent >= 0);
    _prefix = "".padRight(_indent);
  }

  void dec([int n = 2]) {
    _indent = _indent - n;
    assert(_indent >= 0);
    _prefix = "".padRight(_indent);
  }

  void close() {
    new File(_path).writeAsStringSync('$_sb');
  }
}
