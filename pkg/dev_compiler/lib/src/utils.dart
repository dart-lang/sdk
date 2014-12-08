/// Holds a couple utility functions used at various places in the system.
library ddc.src.utils;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:source_span/source_span.dart';

/// Returns all libraries transitively imported or exported from [start].
List<LibraryElement> reachableLibraries(LibraryElement start) {
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

/// Cache of [SourceFile]s per [Source], so we avoid recomputing line-breaks and
/// source-span information on a file multiple times.
// TODO(sigmund): consider truncating the size of this cache.
final Map<Source, SourceFile> _sources = <Source, SourceFile>{};

/// Returns [SourceSpan] for a segment between the [begin] offset and [end]
/// offset in [source].
SourceSpan spanFor(Source source, int begin, int end) {
  var file = _sources.putIfAbsent(source, 
      () => new SourceFile(source.contents.data, url: source.uri));
  return file.span(begin, end);
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
