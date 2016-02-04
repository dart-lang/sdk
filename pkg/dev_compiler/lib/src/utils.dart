// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Holds a couple utility functions used at various places in the system.

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
        AstNode,
        Expression,
        SimpleIdentifier,
        MethodInvocation;
import 'package:analyzer/src/generated/constant.dart' show DartObject;
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/error.dart' show ErrorCode;
import 'package:analyzer/src/task/dart.dart' show ParseDartTask;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:crypto/crypto.dart' show CryptoUtils, MD5;
import 'package:source_span/source_span.dart';

import 'codegen/js_names.dart' show invalidVariableName;

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
  // Ensure the identifier first character is not numeric and that the whole
  // identifier is not a keyword.
  if (result.startsWith(new RegExp('[0-9]')) || invalidVariableName(result)) {
    return '\$$result';
  }
  return result;
}

// Invalid characters for identifiers, which would need to be escaped.
final _invalidCharInIdentifier = new RegExp(r'[^A-Za-z_$0-9]');

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
  var unit =
      parseDirectives(context.getContents(source).data, name: source.fullName);
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

bool isDynamicTarget(Expression node) {
  if (node == null) return false;

  if (isLibraryPrefix(node)) return false;

  // Null type happens when we have unknown identifiers, like a dart: import
  // that doesn't resolve.
  var type = node.staticType;
  return type == null || type.isDynamic;
}

bool isLibraryPrefix(Expression node) =>
    node is SimpleIdentifier && node.staticElement is PrefixElement;

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

SourceLocation locationForOffset(LineInfo lineInfo, Uri uri, int offset) {
  var loc = lineInfo.getLocation(offset);
  return new SourceLocation(offset,
      sourceUrl: uri, line: loc.lineNumber - 1, column: loc.columnNumber - 1);
}

/// Computes a hash for the given contents.
String computeHash(String contents) {
  if (contents == null || contents == '') return null;
  return CryptoUtils.bytesToHex((new MD5()..add(contents.codeUnits)).close());
}

/// Computes a hash for the given file path (reads the contents in binary form).
String computeHashFromFile(String filepath) {
  var bytes = new File(filepath).readAsBytesSync();
  return CryptoUtils.bytesToHex((new MD5()..add(bytes)).close());
}

String resourceOutputPath(Uri resourceUri, Uri entryUri, String runtimeDir) {
  if (resourceUri.scheme == 'package') return resourceUri.path;

  if (resourceUri.scheme != 'file') return null;

  var entryPath = entryUri.path;
  // The entry uri is either a directory or a dart/html file.  If the latter,
  // trim the file.
  var entryDir = entryPath.endsWith('.dart') || entryPath.endsWith('.html')
      ? path.dirname(entryPath)
      : entryPath;
  var filepath = path.normalize(path.join(entryDir, resourceUri.path));
  if (path.isWithin(runtimeDir, filepath)) {
    filepath = path.relative(filepath, from: runtimeDir);
    return path.join('dev_compiler', 'runtime', filepath);
  }

  return path.relative(resourceUri.path, from: entryDir);
}

/// Given an annotated [node] and a [test] function, returns the first matching
/// constant valued annotation.
///
/// For example if we had the ClassDeclaration node for `FontElement`:
///
///    @js.JS('HTMLFontElement')
///    @deprecated
///    class FontElement { ... }
///
/// We could match `@deprecated` with a test function like:
///
///    (v) => v.type.name == 'Deprecated' && v.type.element.library.isDartCore
///
DartObject findAnnotation(Element element, bool test(DartObject value)) {
  for (var metadata in element.metadata) {
    var value = metadata.constantValue;
    if (value != null && test(value)) return value;
  }
  return null;
}

/// Given a constant [value], a [fieldName], and an [expectedType], returns the
/// value of that field.
///
/// If the field is missing or is not [expectedType], returns null.
DartObject getConstantField(
    DartObject value, String fieldName, DartType expectedType) {
  var f = value?.getField(fieldName);
  return (f == null || f.type != expectedType) ? null : f;
}

DartType fillDynamicTypeArgs(DartType t, TypeProvider types) {
  if (t is ParameterizedType) {
    var dyn = new List.filled(t.typeArguments.length, types.dynamicType);
    return t.substitute2(dyn, t.typeArguments);
  }
  return t;
}

/// Similar to [SimpleIdentifier] inGetterContext, inSetterContext, and
/// inDeclarationContext, this method returns true if [node] is used in an
/// invocation context such as a MethodInvocation.
bool inInvocationContext(SimpleIdentifier node) {
  var parent = node.parent;
  return parent is MethodInvocation && parent.methodName == node;
}

// TODO(vsm): Move this onto the appropriate class.  Ideally, we'd attach
// it to TypeProvider.

/// Searches all supertype, in order of most derived members, to see if any
/// [match] a condition. If so, returns the first match, otherwise returns null.
InterfaceType findSupertype(InterfaceType type, bool match(InterfaceType t)) {
  for (var m in type.mixins.reversed) {
    if (match(m)) return m;
  }
  var s = type.superclass;
  if (s == null) return null;

  if (match(s)) return type;
  return findSupertype(s, match);
}

SourceSpanWithContext createSpanHelper(
    LineInfo lineInfo, int start, int end, Source source, String content) {
  var startLoc = locationForOffset(lineInfo, source.uri, start);
  var endLoc = locationForOffset(lineInfo, source.uri, end);

  var lineStart = startLoc.offset - startLoc.column;
  // Find the end of the line. This is not exposed directly on LineInfo, but
  // we can find it pretty easily.
  // TODO(jmesserly): for now we do the simple linear scan. Ideally we can get
  // some help from the LineInfo API.
  int lineEnd = endLoc.offset;
  int lineNum = lineInfo.getLocation(lineEnd).lineNumber;
  while (lineEnd < content.length &&
      lineInfo.getLocation(++lineEnd).lineNumber == lineNum);

  var text = content.substring(start, end);
  var lineText = content.substring(lineStart, lineEnd);
  return new SourceSpanWithContext(startLoc, endLoc, text, lineText);
}

String _strongModeErrorPrefix = 'STRONG_MODE';

bool isStrongModeError(ErrorCode errorCode) {
  return errorCode.name.startsWith(_strongModeErrorPrefix);
}

String errorCodeName(ErrorCode errorCode) {
  if (isStrongModeError(errorCode)) {
    return errorCode.name.substring(_strongModeErrorPrefix.length + 1);
  } else {
    // TODO(jmesserly): this is for backwards compat, but not sure it's very
    // useful to log this.
    return 'AnalyzerMessage';
  }
}

bool isInlineJS(Element e) =>
    e is FunctionElement &&
    e.library.source.uri.toString() == 'dart:_foreign_helper' &&
    e.name == 'JS';

bool isDartMathMinMax(Element e) =>
    e is FunctionElement &&
    e.library.source.uri.toString() == 'dart:math' &&
    (e.name == 'min' || e.name == 'max');

/// Parses an enum value out of a string.
// TODO(ochafik): generic signature.
dynamic parseEnum(String s, List enumValues) =>
    enumValues.firstWhere((v) => s == getEnumName(v),
        orElse: () => throw new ArgumentError('Unknown enum value: $s '
            '(expected one of ${enumValues.map(getEnumName)})'));

/// Gets the "simple" name of an enum value.
getEnumName(v) {
  var parts = '$v'.split('.');
  if (parts.length != 2 || !parts.every((p) => p.isNotEmpty)) {
    throw new ArgumentError('Invalid enum value: $v');
  }
  return parts[1];
}

/// Simplistic directed graph.
class DirectedGraph<V> {
  final _adjacencyList = <V, Set<V>>{};

  void addEdge(V from, V to) {
    _adjacencyList.putIfAbsent(from, () => new Set<V>()).add(to);
  }

  /// Get all the vertices reachable from the provided [roots].
  Set<V> getTransitiveClosure(Iterable<V> roots) {
    final reached = new Set<V>();

    visit(V e) {
      if (reached.add(e)) {
        var destinations = _adjacencyList[e];
        if (destinations != null) destinations.forEach(visit);
      }
    }
    roots.forEach(visit);

    return reached;
  }
}

class FileSystem {
  const FileSystem();

  void _ensureParentExists(String file) {
    var dir = new Directory(path.dirname(file));
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }

  void copySync(String source, String destination) {
    _ensureParentExists(destination);
    new File(source).copySync(destination);
  }

  void writeAsStringSync(String file, String contents) {
    _ensureParentExists(file);
    new File(file).writeAsStringSync(contents);
  }
}
