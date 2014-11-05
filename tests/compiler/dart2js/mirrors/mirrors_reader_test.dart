// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that everything reachable from a [MirrorSystem] can be accessed.

library test.mirrors.reader;

import "dart:mirrors" hide SourceLocation;

import "package:async_helper/async_helper.dart";

import "mirrors_test_helper.dart";
import "../../../lib/mirrors/mirrors_reader.dart";
import "package:compiler/src/util/util.dart";
import "package:compiler/src/mirrors/dart2js_mirrors.dart";
import "package:compiler/src/mirrors/source_mirrors.dart";

class SourceMirrorsReader extends MirrorsReader {
  final Dart2JsMirrorSystem mirrorSystem;

  SourceMirrorsReader(this.mirrorSystem,
                      {bool verbose: false, bool includeStackTrace: false})
      : super(verbose: verbose, includeStackTrace: includeStackTrace);

  evaluate(f()) {
    try {
      return f();
    } on SpannableAssertionFailure catch (e) {
      mirrorSystem.compiler.reportAssertionFailure(e);
      rethrow;
    }
  }

  visitMirror(Mirror mirror) {
    if (mirror is CombinatorMirror) {
      visitCombinatorMirror(mirror);
    } else if (mirror is LibraryDependencyMirror) {
      visitLibraryDependencyMirror(mirror);
    } else if (mirror is CommentInstanceMirror) {
      visitCommentInstanceMirror(mirror);
    } else if (mirror is ListInstanceMirror) {
      visitListInstanceMirror(mirror);
    } else if (mirror is MapInstanceMirror) {
      visitMapInstanceMirror(mirror);
    } else if (mirror is TypeInstanceMirror) {
      visitTypeInstanceMirror(mirror);
    } else {
      super.visitMirror(mirror);
    }
  }

  visitDeclarationMirror(DeclarationSourceMirror mirror) {
    super.visitDeclarationMirror(mirror);
    visit(mirror, 'isNameSynthetic', () => mirror.isNameSynthetic);
  }

  visitClassMirror(ClassSourceMirror mirror) {
    super.visitClassMirror(mirror);
    visit(mirror, 'isAbstract', () => mirror.isAbstract);
  }

  visitLibraryMirror(LibrarySourceMirror mirror) {
    super.visitLibraryMirror(mirror);
    visit(mirror, 'libraryDependencies', () => mirror.libraryDependencies);
  }

  visitParameterMirror(ParameterMirror mirror) {
    super.visitParameterMirror(mirror);
    if (mirror is ParameterSourceMirror) {
      visit(mirror, 'isInitializingFormal', () => mirror.isInitializingFormal);
      visit(mirror, 'initializedField', () => mirror.initializedField);
    }
  }

  visitTypeMirror(TypeSourceMirror mirror) {
    super.visitTypeMirror(mirror);
    visit(mirror, 'isVoid', () => mirror.isVoid);
    visit(mirror, 'isDynamic', () => mirror.isDynamic);
  }

  visitSourceLocation(SourceLocation location) {
    super.visitSourceLocation(location);
    visit(location, 'line', () => location.line);
    visit(location, 'column', () => location.column);
    visit(location, 'offset', () => location.offset);
    visit(location, 'length', () => location.length);
    visit(location, 'text', () => location.text);
    visit(location, 'sourceUri', () => location.sourceUri);
    visit(location, 'sourceText', () => location.sourceText);
  }

  visitCombinatorMirror(CombinatorMirror mirror) {
    visit(mirror, 'identifiers', () => mirror.identifiers);
    visit(mirror, 'isShow', () => mirror.isShow);
    visit(mirror, 'isHide', () => mirror.isHide);
  }

  visitLibraryDependencyMirror(LibraryDependencyMirror mirror) {
    visit(mirror, 'isImport', () => mirror.isImport);
    visit(mirror, 'isExport', () => mirror.isExport);
    visit(mirror, 'sourceLibrary', () => mirror.sourceLibrary);
    visit(mirror, 'targetLibrary', () => mirror.targetLibrary);
    visit(mirror, 'prefix', () => mirror.prefix);
    visit(mirror, 'combinators', () => mirror.combinators);
    visit(mirror, 'location', () => mirror.location);
  }

  visitCommentInstanceMirror(CommentInstanceMirror mirror) {
    visitInstanceMirror(mirror);
    visit(mirror, 'text', () => mirror.text);
    visit(mirror, 'trimmedText', () => mirror.trimmedText);
    visit(mirror, 'isDocComment', () => mirror.isDocComment);
  }

  visitListInstanceMirror(ListInstanceMirror mirror) {
    visitInstanceMirror(mirror);
    visit(mirror, 'length', () => mirror.length);
  }

  visitMapInstanceMirror(MapInstanceMirror mirror) {
    visitInstanceMirror(mirror);
    visit(mirror, 'keys', () => mirror.keys);
    visit(mirror, 'length', () => mirror.length);
  }

  visitTypeInstanceMirror(TypeInstanceMirror mirror) {
    visitInstanceMirror(mirror);
    visit(mirror, 'representedType', () => mirror.representedType);
  }
}

main(List<String> arguments) {
  asyncTest(() => analyzeUri(Uri.parse('dart:core')).
      then((MirrorSystem mirrors) {
    MirrorsReader reader = new SourceMirrorsReader(mirrors,
        verbose: arguments.contains('-v'),
        includeStackTrace: arguments.contains('-s'));
    reader.checkMirrorSystem(mirrors);
  }));
}
