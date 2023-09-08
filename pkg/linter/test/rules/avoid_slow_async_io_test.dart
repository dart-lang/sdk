// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSlowAsyncIoTest);
  });
}

@reflectiveTest
class AvoidSlowAsyncIoTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_slow_async_io';

  test_directory_exists() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(Directory dir) async {
  await dir.exists();
}
''', [
      lint(56, 12),
    ]);
  }

  test_directory_existsSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(Directory dir) async {
  dir.existsSync();
}
''');
  }

  test_directory_stat() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(Directory dir) async {
  await dir.stat();
}
''', [
      lint(56, 10),
    ]);
  }

  test_directory_statSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(Directory dir) async {
  dir.statSync();
}
''');
  }

  test_file_exists() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  await file.exists();
}
''', [
      lint(52, 13),
    ]);
  }

  test_file_existsSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  file.existsSync();
}
''');
  }

  test_file_lastModified() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  await file.lastModified();
}
''', [
      lint(52, 19),
    ]);
  }

  test_file_lastModifiedSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  file.lastModifiedSync();
}
''');
  }

  test_file_stat() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  await file.stat();
}
''', [
      lint(52, 11),
    ]);
  }

  test_file_statSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(File file) async {
  file.statSync();
}
''');
  }

  test_fileSystemEntity_isDirectory() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  await FileSystemEntity.isDirectory(path);
}
''', [
      lint(54, 34),
    ]);
  }

  test_fileSystemEntity_isDirectorySync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  FileSystemEntity.isDirectorySync(path);
}
''');
  }

  test_fileSystemEntity_isFile() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  await FileSystemEntity.isFile(path);
}
''', [
      lint(54, 29),
    ]);
  }

  test_fileSystemEntity_isFileSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  FileSystemEntity.isFileSync(path);
}
''');
  }

  test_fileSystemEntity_isLink() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  await FileSystemEntity.isLink(path);
}
''', [
      lint(54, 29),
    ]);
  }

  test_fileSystemEntity_isLinkSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  FileSystemEntity.isLinkSync(path);
}
''');
  }

  test_fileSystemEntity_type() async {
    await assertDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  FileSystemEntity.type(path);
}
''', [
      lint(48, 27),
    ]);
  }

  test_fileSystemEntity_typeSync() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f(String path) async {
  FileSystemEntity.typeSync(path);
}
''');
  }
}
