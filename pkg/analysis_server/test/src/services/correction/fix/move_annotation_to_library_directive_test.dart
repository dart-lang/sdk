// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveAnnotationToLibraryDirectiveTest);
  });
}

@reflectiveTest
class MoveAnnotationToLibraryDirectiveTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.moveAnnotationToLibraryDirective;

  @override
  String get lintCode => LintNames.library_annotations;

  Future<void> test_existingLibraryDirective() async {
    await resolveTestCode('''
/// Doc comment.
library;
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
/// Doc comment.
@pragma('dart2js:late:trust')
library;
import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_noExistingLibraryDirective_annotationIsFirst() async {
    await resolveTestCode('''
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_noExistingLibraryDirective_annotationOnDeclaration() async {
    await resolveTestCode('''
@deprecated
@pragma('dart2js:late:trust')
class C {}
''');
    await assertHasFix('''
@pragma('dart2js:late:trust')
library;

@deprecated
class C {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_annotationOnDeclaration_withMetadata() async {
    await resolveTestCode('''
@deprecated
@immutable
class C {}
''');
    // There is no `library_annotations` diagnostic on `@deprecated`.
    await assertNoFix();
  }

  Future<void>
  test_noExistingLibraryDirective_anotherAnnotationIsFirst() async {
    await resolveTestCode('''
@deprecated
@pragma('dart2js:late:trust')
/// Doc comment.
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
@deprecated
@pragma('dart2js:late:trust')
/// Doc comment.
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void> test_noExistingLibraryDirective_commentsAreFirst() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
// Comment 1.

// Comment 2.

@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_commentsAreFirst_andAnnotations() async {
    await resolveTestCode('''
// Comment 1.

// Comment 2.

@deprecated
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
// Comment 1.

// Comment 2.

@deprecated
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_documentationCommentIsFirst() async {
    await resolveTestCode('''
/// Doc comment.
@deprecated
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
/// Doc comment.
@deprecated
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_firstDirective_mixedTargets() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
@LibraryOnly()
@ImportOnly()
import 'dart:async';

import 'package:meta/meta_meta.dart';

Completer? completer;

@Target({TargetKind.library})
class LibraryOnly {
  const LibraryOnly();
}

@Target({TargetKind.importDirective})
class ImportOnly {
  const ImportOnly();
}
''');
    await assertHasFix('''
@LibraryOnly()
library;

@ImportOnly()
import 'dart:async';

import 'package:meta/meta_meta.dart';

Completer? completer;

@Target({TargetKind.library})
class LibraryOnly {
  const LibraryOnly();
}

@Target({TargetKind.importDirective})
class ImportOnly {
  const ImportOnly();
}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_firstDirective_mixedTargets_reversed() async {
    writeTestPackageConfig(meta: true);
    await resolveTestCode('''
@ImportOnly()
@LibraryOnly()
import 'dart:async';

import 'package:meta/meta_meta.dart';

Completer? completer;

@Target({TargetKind.library})
class LibraryOnly {
  const LibraryOnly();
}

@Target({TargetKind.importDirective})
class ImportOnly {
  const ImportOnly();
}
''');
    await assertHasFix('''
@LibraryOnly()
library;

@ImportOnly()
import 'dart:async';

import 'package:meta/meta_meta.dart';

Completer? completer;

@Target({TargetKind.library})
class LibraryOnly {
  const LibraryOnly();
}

@Target({TargetKind.importDirective})
class ImportOnly {
  const ImportOnly();
}
''');
  }

  Future<void> test_noExistingLibraryDirective_scriptTag() async {
    await resolveTestCode('''
#!/usr/bin/env dart
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
#!/usr/bin/env dart
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }

  Future<void>
  test_noExistingLibraryDirective_scriptTag_withCommentsAndAnnotations() async {
    await resolveTestCode('''
#!/usr/bin/env dart
// Copyright notice.

/// Doc comment.
@deprecated
@pragma('dart2js:late:trust')
import 'dart:async';

void f(Completer c) {}
''');
    await assertHasFix('''
#!/usr/bin/env dart
// Copyright notice.

/// Doc comment.
@deprecated
@pragma('dart2js:late:trust')
library;

import 'dart:async';

void f(Completer c) {}
''');
  }
}
