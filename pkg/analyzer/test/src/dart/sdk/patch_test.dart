// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/sdk/patch.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkPatcherTest);
  });
}

@reflectiveTest
class SdkPatcherTest {
  MemoryResourceProvider provider = new MemoryResourceProvider();
  Folder sdkFolder;
  FolderBasedDartSdk sdk;

  SdkPatcher patcher = new SdkPatcher();
  RecordingErrorListener listener = new RecordingErrorListener();

  void setUp() {
    sdkFolder = provider.getFolder(_p('/sdk'));
  }

  test_fail_noSuchLibrary() {
    expect(() {
      _setSdkLibraries('const LIBRARIES = const {};');
      _createSdk();
      File file = provider.newFile(_p('/sdk/lib/test/test.dart'), '');
      Source source = file.createSource(FastUri.parse('dart:test'));
      CompilationUnit unit = SdkPatcher.parse(source, true, listener);
      patcher.patch(sdk, SdkLibraryImpl.VM_PLATFORM, listener, source, unit);
    }, throwsArgumentError);
  }

  test_fail_patchFileDoesNotExist() {
    expect(() {
      _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'test' : const LibraryInfo(
    'test/test.dart',
    patches: {VM_PLATFORM: ['does_not_exists.dart']}),
};''');
      _createSdk();
      File file = provider.newFile(_p('/sdk/lib/test/test.dart'), '');
      Source source = file.createSource(FastUri.parse('dart:test'));
      CompilationUnit unit = SdkPatcher.parse(source, true, listener);
      patcher.patch(sdk, SdkLibraryImpl.VM_PLATFORM, listener, source, unit);
    }, throwsArgumentError);
  }

  test_topLevel_append() {
    CompilationUnit unit = _doTopLevelPatching(
        r'''
int bar() => 2;
''',
        r'''
int _foo1() => 1;
int get _foo2 => 1;
void set _foo3(int val) {}
''');
    _assertUnitCode(
        unit,
        'int bar() => 2; int _foo1() => 1; '
        'int get _foo2 => 1; void set _foo3(int val) {}');
  }

  test_topLevel_fail_append_notPrivate() {
    expect(() {
      _doTopLevelPatching(
          r'''
int foo() => 1;
''',
          r'''
int bar() => 2;
''');
    }, throwsArgumentError);
  }

  test_topLevel_fail_noExternalKeyword() {
    expect(() {
      _doTopLevelPatching(
          r'''
int foo();
''',
          r'''
@patch
int foo() => 1;
''');
    }, throwsArgumentError);
  }

  test_topLevel_patch_function() {
    CompilationUnit unit = _doTopLevelPatching(
        r'''
external int foo();
int bar() => 2;
''',
        r'''
@patch
int foo() => 1;
''');
    _assertUnitCode(unit, 'int foo() => 1; int bar() => 2;');
  }

  test_topLevel_patch_getter() {
    CompilationUnit unit = _doTopLevelPatching(
        r'''
external int get foo;
int bar() => 2;
''',
        r'''
@patch
int get foo => 1;
''');
    _assertUnitCode(unit, 'int get foo => 1; int bar() => 2;');
  }

  test_topLevel_patch_setter() {
    CompilationUnit unit = _doTopLevelPatching(
        r'''
external void set foo(int val);
int bar() => 2;
''',
        r'''
@patch
void set foo(int val) {}
''');
    _assertUnitCode(unit, 'void set foo(int val) {} int bar() => 2;');
  }

  void _assertUnitCode(CompilationUnit unit, String expectedCode) {
    expect(unit.toSource(), expectedCode);
  }

  void _createSdk() {
    sdk = new FolderBasedDartSdk(provider, sdkFolder);
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;
  }

  CompilationUnit _doTopLevelPatching(String baseCode, String patchCode) {
    _setSdkLibraries(r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'test' : const LibraryInfo(
    'test/test.dart',
    patches: {VM_PLATFORM: ['test/test_patch.dart']}),
};''');
    File file = provider.newFile(_p('/sdk/lib/test/test.dart'), baseCode);
    provider.newFile(_p('/sdk/lib/test/test_patch.dart'), patchCode);

    _createSdk();

    Source source = file.createSource(FastUri.parse('dart:test'));
    CompilationUnit unit = SdkPatcher.parse(source, true, listener);
    patcher.patch(sdk, SdkLibraryImpl.VM_PLATFORM, listener, source, unit);
    return unit;
  }

  String _p(String path) => provider.convertPath(path);

  void _setSdkLibraries(String code) {
    provider.newFile(
        _p('/sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart'), code);
  }
}
