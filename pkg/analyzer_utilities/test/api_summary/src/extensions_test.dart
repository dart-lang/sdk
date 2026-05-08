// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_utilities/src/api_summary/src/extensions.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionsTest);
  });
}

@reflectiveTest
class ExtensionsTest extends ApiSummaryTest {
  Future<void> test_element_apiName_classMember() async {
    var class_ = (await analyzeLibrary('''
class C {
  void method() {}
  int get getter => 0;
  set setter(int value) {}
  int field = 0;
  static const constant = 0;
}
''')).getClass('C')!;
    expect(class_.getMethod('method')!.apiName, 'method');
    expect(class_.getGetter('getter')!.apiName, 'getter');
    expect(class_.getSetter('setter')!.apiName, 'setter=');
    expect(class_.getField('field')!.apiName, 'field');
    expect(class_.getField('constant')!.apiName, 'constant');
  }

  Future<void> test_element_apiName_topLevel() async {
    var lib = await analyzeLibrary('''
void function() {}
int get getter => 0;
set setter(int value) {}
int variable = 0;
const constant = 0;
class Class {}
mixin Mixin {}
enum Enum { e }
extension Extension on int {}
extension type ExtensionType(int i) {}
''');
    expect(lib.getTopLevelFunction('function')!.apiName, 'function');
    expect(lib.getGetter('getter')!.apiName, 'getter');
    expect(lib.getSetter('setter')!.apiName, 'setter=');
    expect(lib.getTopLevelVariable('variable')!.apiName, 'variable');
    expect(lib.getTopLevelVariable('constant')!.apiName, 'constant');
    expect(lib.getClass('Class')!.apiName, 'Class');
    expect(lib.getMixin('Mixin')!.apiName, 'Mixin');
    expect(lib.getEnum('Enum')!.apiName, 'Enum');
    expect(lib.getExtension('Extension')!.apiName, 'Extension');
    expect(lib.getExtensionType('ExtensionType')!.apiName, 'ExtensionType');
  }

  Future<void> test_formalParameterElement_isDeprecated() async {
    var f = (await analyzeLibrary(
      'f({int? i, @deprecated int? j}) {}',
    )).getTopLevelFunction('f')!;
    expect(f.formalParameters[0].isDeprecated, isFalse);
    expect(f.formalParameters[1].isDeprecated, isTrue);
  }

  void test_iterableIterable_separatedBy() {
    expect(
      [
        ['a', 'b'],
        ['c', 'd'],
      ].separatedBy(),
      ['', 'a', 'b', ', ', 'c', 'd', ''],
    );
    expect(
      [
        ['a', 'b'],
        ['c', 'd'],
      ].separatedBy(prefix: '[', separator: '|', suffix: ']'),
      ['[', 'a', 'b', '|', 'c', 'd', ']'],
    );
    expect(
      <Iterable<Object?>>[].separatedBy(
        prefix: '[',
        separator: '|',
        suffix: ']',
      ),
      ['[', ']'],
    );
  }

  void test_string_isPublic() {
    expect('_'.isPublic, isFalse);
    expect('foo'.isPublic, isTrue);
    expect('_foo'.isPublic, isFalse);
  }

  void test_uri_isIn() {
    expect(Uri.parse('package:foo/bar.dart').isIn('foo'), isTrue);
    expect(Uri.parse('package:foo/bar.dart').isIn('bar.dart'), isFalse);
    expect(Uri.parse('dart:core').isIn('foo'), isFalse);
    expect(Uri.parse('dart:core').isIn('dart'), isFalse);
    expect(Uri.parse('dart:core').isIn('core'), isFalse);
  }

  void test_uri_isInPublicLibOf() {
    expect(Uri.parse('package:foo/bar.dart').isInPublicLibOf('foo'), isTrue);
    expect(
      Uri.parse('package:foo/bar.dart').isInPublicLibOf('bar.dart'),
      isFalse,
    );
    expect(
      Uri.parse('package:foo/src/bar.dart').isInPublicLibOf('foo'),
      isFalse,
    );
    expect(
      Uri.parse('package:foo/src/bar.dart').isInPublicLibOf('src'),
      isFalse,
    );
    expect(Uri.parse('dart:core').isInPublicLibOf('foo'), isFalse);
    expect(Uri.parse('dart:core').isInPublicLibOf('dart'), isFalse);
    expect(Uri.parse('dart:core').isInPublicLibOf('core'), isFalse);
  }
}
