#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to merge the SDK libraries and our patch files.
/// This is currently designed as an offline tool, but we could automate it.
library ddc.tool.patch_sdk;

import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as path;

import 'input_sdk_src/lib/_internal/libraries.dart' as sdk;

void main(List<String> argv) {
  var toolDir = path.relative(path.dirname(Platform.script.path));
  var sdkIn = path.join(toolDir, 'input_sdk_src', 'lib');
  var patchIn = path.join(toolDir, 'input_sdk_patch');
  var sdkOut =
      path.normalize(path.join(toolDir, '..', 'test', 'generated_sdk', 'lib'));

  if (argv.isNotEmpty) {
    print('Usage: ${path.relative(Platform.script.path)}\n');
    print('input SDK directory: $sdkIn');
    print('input patch directory: $patchIn');
    print('output SDK directory: $sdkOut');
    exit(1);
  }

  // Copy libraries.dart and version
  _writeSync(path.join(sdkOut, '_internal', 'libraries.dart'),
      new File(path.join(sdkIn, '_internal', 'libraries.dart'))
          .readAsStringSync());
  _writeSync(path.join(sdkOut, '..', 'version'),
      new File(path.join(sdkIn, '..', 'version')).readAsStringSync());

  // Enumerate core libraries and apply patches
  for (var library in sdk.LIBRARIES.values) {
    if (library.platforms & sdk.DART2JS_PLATFORM == 0) continue;

    var libraryPath = path.join(sdkIn, library.path);

    var libraryFile = new File(libraryPath);
    if (libraryFile.existsSync()) {
      var contents = <String>[];
      var paths = <String>[];
      var libraryContents = libraryFile.readAsStringSync();
      paths.add(libraryPath);
      contents.add(libraryContents);
      for (var part in parseDirectives(libraryContents).directives) {
        if (part is PartDirective) {
          paths.add(path.join(path.dirname(libraryPath), part.uri.stringValue));
          contents.add(new File(paths.last).readAsStringSync());
        }
      }

      if (library.dart2jsPatchPath != null) {
        var patchPath = path.join(patchIn, library.dart2jsPatchPath.replaceAll(
            '_internal/compiler/js_lib/', ''));
        var patchContents = new File(patchPath).readAsStringSync();

        contents = _patchLibrary(contents, patchContents);
      }
      for (var i = 0; i < paths.length; i++) {
        var outPath = path.join(sdkOut, path.relative(paths[i], from: sdkIn));
        _writeSync(outPath, contents[i]);
      }
    }
  }
}

/// Writes a file, creating the directory if needed.
void _writeSync(String filePath, String contents) {
  print('Writing $filePath');

  var outDir = new Directory(path.dirname(filePath));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  new File(filePath).writeAsStringSync(contents);
}

/// Merges dart:* library code with code from *_patch.dart file.
///
/// Takes a list of the library's parts contents, with the main library contents
/// first in the list, and the contents of the patch file.
///
/// The result will have `@patch` implementations merged into the correct place
/// (e.g. the class or top-level function declaration) and all other
/// declarations introduced by the patch will be placed into the main library
/// file.
///
/// This is purely a syntactic transformation. Unlike dart2js patch files, there
/// is no semantic meaning given to the *_patch files, and they do not magically
/// get their own library scope, etc.
///
/// Editorializing: the dart2js approach requires a Dart front end such as
/// package:analyzer to semantically model a feature beyond what is specified
/// in the Dart language. Since this feature is only for the convenience of
/// writing the dart:* libraries, and not a tool given to Dart developers, it
/// seems like a non-ideal situation. Instead we keep the preprocessing simple.
List<String> _patchLibrary(List<String> partsContents, String patchContents) {
  var results = <StringEditBuffer>[];

  // Parse the patch first. We'll need to extract bits of this as we go through
  // the other files.
  var patchFinder = new PatchFinder.parseAndVisit(patchContents);

  // Merge `external` declarations with the corresponding `@patch` code.
  for (var partContent in partsContents) {
    var partEdits = new StringEditBuffer(partContent);
    var partUnit = parseCompilationUnit(partContent);
    partUnit.accept(new PatchApplier(partEdits, patchFinder));
    results.add(partEdits);
  }
  return new List<String>.from(results.map((e) => e.toString()));
}

/// Merge `@patch` declarations into `external` declarations.
class PatchApplier extends GeneralizingAstVisitor {
  final StringEditBuffer edits;
  final PatchFinder patch;

  bool _isLibrary = true; // until proven otherwise.

  PatchApplier(this.edits, this.patch);

  @override visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    if (_isLibrary) _mergeUnpatched(node);
  }

  /// Merges directives and declarations that are not `@patch` into the library.
  void _mergeUnpatched(CompilationUnit unit) {
    // Merge directives from the patch
    // TODO(jmesserly): remove duplicate imports
    var directivePos = unit.directives.last.end;
    for (var directive in patch.unit.directives) {
      var code = patch.contents.substring(directive.offset, directive.end);
      edits.insert(directivePos, '\n' + code);
    }

    // Merge declarations from the patch
    var declarationPos = edits.original.length;
    for (var declaration in patch.mergeDeclarations) {
      var code = patch.contents.substring(declaration.offset, declaration.end);
      edits.insert(declarationPos, '\n' + code);
    }
  }

  @override visitPartOfDirective(PartOfDirective node) {
    _isLibrary = false;
  }

  @override visitFunctionDeclaration(FunctionDeclaration node) {
    _maybePatch(node);
  }

  /// Merge patches and extensions into the class
  @override visitClassDeclaration(ClassDeclaration node) {
    node.members.forEach(_maybePatch);

    var mergeMembers = patch.mergeMembers[_qualifiedName(node)];
    if (mergeMembers == null) return;

    // Merge members from the patch
    var pos = node.members.last.end;
    for (var member in mergeMembers) {
      var code = patch.contents.substring(member.offset, member.end);
      edits.insert(pos, '\n\n  ' + code);
    }
  }

  void _maybePatch(AstNode node) {
    if (node is FieldDeclaration) return;

    var externalKeyword = (node as dynamic).externalKeyword;
    if (externalKeyword == null) return;

    var name = _qualifiedName(node);
    var patchNode = patch.patches[name];
    if (patchNode == null) throw 'patch not found for $name: $node';

    Annotation patchMeta = patchNode.metadata.lastWhere(_isPatchAnnotation);
    int start = patchMeta.endToken.next.offset;
    var code = patch.contents.substring(start, patchNode.end);

    // For some node like static fields, the node's offset doesn't include
    // the external keyword. Also starting from the keyword lets us preserve
    // documentation comments.
    edits.replace(externalKeyword.offset, node.end, code);
  }
}

class PatchFinder extends GeneralizingAstVisitor {
  final String contents;
  final CompilationUnit unit;

  final Map patches = <String, Declaration>{};
  final Map mergeMembers = <String, List<ClassMember>>{};
  final List mergeDeclarations = <CompilationUnitMember>[];

  PatchFinder.parseAndVisit(String contents)
      : contents = contents,
        unit = parseCompilationUnit(contents) {
    visitCompilationUnit(unit);
  }

  @override visitCompilationUnitMember(CompilationUnitMember node) {
    mergeDeclarations.add(node);
  }

  @override visitClassDeclaration(ClassDeclaration node) {
    if (_isPatch(node)) {
      var members = <ClassMember>[];
      for (var member in node.members) {
        if (_isPatch(member)) {
          patches[_qualifiedName(member)] = member;
        } else {
          members.add(member);
        }
      }
      if (members.isNotEmpty) {
        mergeMembers[_qualifiedName(node)] = members;
      }
    } else {
      mergeDeclarations.add(node);
    }
  }

  @override visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isPatch(node)) {
      patches[_qualifiedName(node)] = node;
    } else {
      mergeDeclarations.add(node);
    }
  }

  @override visitFunctionBody(node) {} // skip method bodies
}

String _qualifiedName(Declaration node) {
  assert(node is MethodDeclaration ||
      node is FunctionDeclaration ||
      node is ConstructorDeclaration);

  var parent = node.parent;
  var className = '';
  if (parent is ClassDeclaration) {
    className = parent.name.name + '.';
  }
  var name = (node as dynamic).name;
  return className + (name != null ? name.name : '');
}

bool _isPatch(AnnotatedNode node) => node.metadata.any(_isPatchAnnotation);

bool _isPatchAnnotation(Annotation m) =>
    m.name.name == 'patch' && m.constructorName == null && m.arguments == null;

/// Editable string buffer.
///
/// Applies a series of edits (insertions, removals, replacements) using
/// original location information, and composes them into the edited string.
///
/// For example, starting with a parsed AST with original source locations,
/// this type allows edits to be made without regards to other edits.
class StringEditBuffer {
  final String original;
  final _edits = <_StringEdit>[];

  /// Creates a new transaction.
  StringEditBuffer(this.original);

  bool get hasEdits => _edits.length > 0;

  /// Edit the original text, replacing text on the range [begin] and
  /// exclusive [end] with the [replacement] string.
  void replace(int begin, int end, String replacement) {
    _edits.add(new _StringEdit(begin, end, replacement));
  }

  /// Insert [string] at [offset].
  /// Equivalent to `replace(offset, offset, string)`.
  void insert(int offset, String string) => replace(offset, offset, string);

  /// Remove text from the range [begin] to exclusive [end].
  /// Equivalent to `replace(begin, end, '')`.
  void remove(int begin, int end) => replace(begin, end, '');

  /// Applies all pending [edit]s and returns a new string.
  ///
  /// This method is non-destructive: it does not discard existing edits or
  /// change the [original] string. Further edits can be added and this method
  /// can be called again.
  ///
  /// Throws [UnsupportedError] if the edits were overlapping. If no edits were
  /// made, the original string will be returned.
  String toString() {
    var sb = new StringBuffer();
    if (_edits.length == 0) return original;

    // Sort edits by start location.
    _edits.sort();

    int consumed = 0;
    for (var edit in _edits) {
      if (consumed > edit.begin) {
        sb = new StringBuffer();
        sb.write('overlapping edits. Insert at offset ');
        sb.write(edit.begin);
        sb.write(' but have consumed ');
        sb.write(consumed);
        sb.write(' input characters. List of edits:');
        for (var e in _edits) {
          sb.write('\n    ');
          sb.write(e);
        }
        throw new UnsupportedError(sb.toString());
      }

      // Add characters from the original string between this edit and the last
      // one, if any.
      var betweenEdits = original.substring(consumed, edit.begin);
      sb.write(betweenEdits);
      sb.write(edit.replace);
      consumed = edit.end;
    }

    // Add any text from the end of the original string that was not replaced.
    sb.write(original.substring(consumed));
    return sb.toString();
  }
}

class _StringEdit implements Comparable<_StringEdit> {
  final int begin;
  final int end;
  final String replace;

  _StringEdit(this.begin, this.end, this.replace);

  int get length => end - begin;

  String toString() => '(Edit @ $begin,$end: "$replace")';

  int compareTo(_StringEdit other) {
    int diff = begin - other.begin;
    if (diff != 0) return diff;
    return end - other.end;
  }
}
