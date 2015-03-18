// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Holds a couple utility functions used at various places in the system.
library dev_compiler.src.utils;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:analyzer/src/generated/ast.dart'
    show
        ImportDirective,
        ExportDirective,
        PartDirective,
        CompilationUnit,
        Identifier,
        AnnotatedNode,
        AstNode;
import 'package:analyzer/src/generated/engine.dart'
    show ParseDartTask, AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:crypto/crypto.dart' show CryptoUtils, MD5;
import 'package:source_span/source_span.dart';

import 'js/keywords.dart';

bool isDartPrivateLibrary(LibraryElement library) {
  var uri = library.source.uri;
  if (uri.scheme != "dart") return false;
  return Identifier.isPrivateName(uri.path);
}

/// Choose a canonical name from the library element. This is safe to use as a
/// namespace in JS and Dart code generation.  This never uses the library's
/// name (the identifier in the `library` declaration) as it doesn't have any
/// meaningful rules enforced.
String canonicalLibraryName(LibraryElement library) {
  var uri = library.source.uri;
  var name = path.basenameWithoutExtension(uri.pathSegments.last);
  return _toIdentifier(name);
}

/// Escape [name] to make it into a valid identifier.
String _toIdentifier(String name) {
  if (name.length == 0) return r'$';

  // Escape any invalid characters
  StringBuffer buffer = null;
  for (int i = 0; i < name.length; i++) {
    var ch = name[i];
    var needsEscape = ch == r'$' || _invalidCharInIdentifier.hasMatch(ch);
    if (needsEscape && buffer == null) {
      buffer = new StringBuffer(name.substring(0, i));
    }
    if (buffer != null) {
      buffer.write(needsEscape ? '\$${ch.codeUnits.join("")}' : ch);
    }
  }

  var result = buffer != null ? '$buffer' : name;
  // Ensure the idenifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(new RegExp('[0-9]')) || isJsKeyword(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = new RegExp(r'[^A-Za-z_$0-9]');

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

/// Returns the enclosing library of [e].
LibraryElement enclosingLibrary(Element e) {
  while (e != null && e is! LibraryElement) e = e.enclosingElement;
  return e;
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

/// Looks up the declaration that matches [member] in [type] or its superclasses
/// and interfaces, and returns its declared type.
// TODO(sigmund): add this to lookUp* in analyzer. The difference here is that
// we also look in interfaces in addition to superclasses.
FunctionType searchTypeFor(InterfaceType start, ExecutableElement member) {
  var getMemberTypeHelper = _memberTypeGetter(member);
  FunctionType search(InterfaceType type, bool first) {
    if (type == null) return null;
    var res = null;
    if (!first) {
      res = getMemberTypeHelper(type);
      if (res != null) return res;
    }

    for (var m in type.mixins.reversed) {
      res = search(m, false);
      if (res != null) return res;
    }

    res = search(type.superclass, false);
    if (res != null) return res;

    for (var i in type.interfaces) {
      res = search(i, false);
      if (res != null) return res;
    }

    return null;
  }

  return search(start, true);
}

/// Looks up the declaration that matches [member] in [type] and returns it's
/// declared type.
FunctionType getMemberType(InterfaceType type, ExecutableElement member) =>
    _memberTypeGetter(member)(type);

typedef FunctionType _MemberTypeGetter(InterfaceType type);

_MemberTypeGetter _memberTypeGetter(ExecutableElement member) {
  String memberName = member.name;
  final isGetter = member is PropertyAccessorElement && member.isGetter;
  final isSetter = member is PropertyAccessorElement && member.isSetter;

  FunctionType f(InterfaceType type) {
    ExecutableElement baseMethod;
    try {
      if (isGetter) {
        assert(!isSetter);
        // Look for getter or field.
        baseMethod = type.getGetter(memberName);
      } else if (isSetter) {
        baseMethod = type.getSetter(memberName);
      } else {
        baseMethod = type.getMethod(memberName);
      }
    } catch (e) {
      // TODO(sigmund): remove this try-catch block (see issue #48).
    }
    if (baseMethod == null || baseMethod.isStatic) return null;
    return baseMethod.type;
  }
  ;
  return f;
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
const String GREEN_COLOR = '\u001b[32m';
const String NO_COLOR = '\u001b[0m';

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

SourceLocation locationForOffset(CompilationUnit unit, Uri uri, int offset) {
  var lineInfo = unit.lineInfo.getLocation(offset);
  return new SourceLocation(offset,
      sourceUrl: uri,
      line: lineInfo.lineNumber - 1,
      column: lineInfo.columnNumber - 1);
}

// TODO(sigmund): change to show the span from the beginning of the line (#73)
SourceSpan spanForNode(CompilationUnit unit, Source source, AstNode node) {
  var currentToken = node is AnnotatedNode
      ? node.firstTokenAfterCommentAndMetadata
      : node.beginToken;
  var begin = currentToken.offset;
  var end = node.end;
  var text = source.contents.data.substring(begin, end);
  var uri = source.uri;
  return new SourceSpan(locationForOffset(unit, uri, begin),
      locationForOffset(unit, uri, end), '$text');
}

/// Computes a hash for the given contents.
String computeHash(String contents) {
  if (contents == null || contents == '') return null;
  return CryptoUtils.bytesToHex((new MD5()..add(contents.codeUnits)).close());
}

String resourceOutputPath(Uri resourceUri) {
  if (resourceUri.scheme == 'package') return resourceUri.path;

  // Only support file:/// urls for resources in the dev_compiler package
  if (resourceUri.scheme != 'file') return null;
  var segments = resourceUri.pathSegments;
  var len = segments.length;
  if (segments.length < 4 ||
      segments[len - 2] != 'runtime' ||
      segments[len - 3] != 'lib' ||
      // If loaded from sources this will be exactly dev_compiler, otherwise it
      // can be the name in the pub cache (typically dev_compiler-version).
      !segments[len - 4].startsWith('dev_compiler')) {
    return null;
  }
  return path.joinAll(['dev_compiler']..addAll(segments.skip(len - 2)));
}
