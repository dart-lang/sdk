// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../util/element_printer.dart';
import '../../dart/resolution/node_text_expectations.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryFragmentElementTest_keepLinking);
    defineReflectiveTests(LibraryFragmentElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class LibraryFragmentElementTest extends ElementsBaseTest {
  test_scope_hasPrefix() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['prefix.exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['prefix.exitCode'],
      ),
    ], r'''
package:test/test.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  prefix.exitCode
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_hasPrefix_append() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:math' as prefix;
part 'aa.dart';
''');

    addSource('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
part 'aaa.dart';
''');

    addSource('$testPackageLibPath/aaa.dart', r'''
part of 'aa.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['prefix.File', 'prefix.Random'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['prefix.File', 'prefix.Random'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aa.dart',
        ['prefix.File', 'prefix.Random'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aaa.dart',
        ['prefix.File', 'prefix.Random'],
      ),
    ], r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: <null>
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
package:test/aaa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Random
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:math::<fragment>::@class::Random
''');
  }

  test_scope_hasPrefix_shadow() async {
    addSource('$testPackageLibPath/x.dart', r'''
class Directory {}
''');

    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'x.dart' as prefix;
part 'aa.dart';
''');

    addSource('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
part 'aaa.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io' as prefix;
part 'a.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['prefix.File', 'prefix.Directory'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['prefix.File', 'prefix.Directory'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aa.dart',
        ['prefix.File', 'prefix.Directory'],
      ),
    ], r'''
package:test/test.dart
  prefix.File
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibraryFragment>::@prefix::prefix
    getter: dart:io::<fragment>::@class::Directory
package:test/a.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: package:test/x.dart::<fragment>::@class::Directory
package:test/aa.dart
  prefix.File
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: dart:io::<fragment>::@class::File
  prefix.Directory
    prefix: <testLibrary>::@fragment::package:test/a.dart::@prefix::prefix
    getter: package:test/x.dart::<fragment>::@class::Directory
''');
  }

  test_scope_noPrefix_fragmentImportShadowsParent() async {
    addSource('$testPackageLibPath/x.dart', r'''
int get exitCode => 0;
''');

    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'x.dart';
part 'aa.dart';
''');

    addSource('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    addSource('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aa.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/b.dart',
        ['exitCode'],
      ),
    ], r'''
package:test/test.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  exitCode
    getter: package:test/x.dart::<fragment>::@getter::exitCode
package:test/aa.dart
  exitCode
    getter: package:test/x.dart::<fragment>::@getter::exitCode
package:test/b.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_noPrefix_implicitDartCore() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['Object'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['Object'],
      ),
    ], r'''
package:test/test.dart
  Object
    getter: dart:core::<fragment>::@class::Object
package:test/a.dart
  Object
    getter: dart:core::<fragment>::@class::Object
''');
  }

  test_scope_noPrefix_inheritsFromParentFragment_fromDefining() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['exit', 'exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['exit', 'exitCode'],
      ),
    ], r'''
package:test/test.dart
  exit
    getter: dart:io::<fragment>::@function::exit
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/a.dart
  exit
    getter: dart:io::<fragment>::@function::exit
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
''');
  }

  test_scope_noPrefix_inheritsFromParentFragment_fromPart() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
import 'dart:io';
part 'aa.dart';
''');

    addSource('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
''');

    addSource('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
part 'a.dart';
part 'b.dart';
''');

    // Both 'a' and 'aa' can see `exitCode`.
    // But not 'test.dart' and 'b'.
    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aa.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/b.dart',
        ['exitCode'],
      ),
    ], r'''
package:test/test.dart
  exitCode
    getter: <null>
package:test/a.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/aa.dart
  exitCode
    getter: dart:io::<fragment>::@getter::exitCode
    setter: dart:io::<fragment>::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
''');
  }

  test_scope_noPrefix_localShadowsImported_getter() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
int get exitCode => 0;
''');

    addSource('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/b.dart',
        ['exitCode'],
      ),
    ], r'''
package:test/test.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
package:test/a.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
package:test/b.dart
  exitCode
    getter: <testLibrary>::@fragment::package:test/a.dart::@getter::exitCode
''');
  }

  test_scope_noPrefix_localShadowsImported_setter() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
set exitCode(int _) {}
''');

    addSource('$testPackageLibPath/b.dart', r'''
part of 'test.dart';
''');

    var library = await buildLibrary(r'''
import 'dart:io';
part 'a.dart';
part 'b.dart';
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['exitCode'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/b.dart',
        ['exitCode'],
      ),
    ], r'''
package:test/test.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
package:test/a.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
package:test/b.dart
  exitCode
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::exitCode
''');
  }

  test_scope_noPrefix_localsOfFragments() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
part 'aa.dart';
class A {}
''');

    addSource('$testPackageLibPath/aa.dart', r'''
part of 'a.dart';
class B {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class Z {}
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['A', 'B', 'Z'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['A', 'B', 'Z'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/aa.dart',
        ['A', 'B', 'Z'],
      ),
    ], r'''
package:test/test.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
package:test/a.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
package:test/aa.dart
  A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::A
  B
    getter: <testLibrary>::@fragment::package:test/aa.dart::@class::B
  Z
    getter: <testLibraryFragment>::@class::Z
''');
  }

  test_scope_noPrefix_localsOfFragments_private() async {
    addSource('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
class _A {}
set _foo(int _) {}
''');

    var library = await buildLibrary(r'''
part 'a.dart';
class _Z {}
''');

    _assertScopeLookups(library, [
      LibraryFragmentScopeRequests(
        'package:test/test.dart',
        ['_A', '_Z', '_foo'],
      ),
      LibraryFragmentScopeRequests(
        'package:test/a.dart',
        ['_A', '_Z', '_foo'],
      ),
    ], r'''
package:test/test.dart
  _A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_A
  _Z
    getter: <testLibraryFragment>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::_foo
package:test/a.dart
  _A
    getter: <testLibrary>::@fragment::package:test/a.dart::@class::_A
  _Z
    getter: <testLibraryFragment>::@class::_Z
  _foo
    getter: <null>
    setter: <testLibrary>::@fragment::package:test/a.dart::@setter::_foo
''');
  }

  void _assertScopeLookups(
    LibraryElementImpl library,
    List<LibraryFragmentScopeRequests> fragmentRequests,
    String expected,
  ) {
    var buffer = StringBuffer();

    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    for (var fragmentRequest in fragmentRequests) {
      sink.writelnWithIndent(fragmentRequest.fragmentUri);
      sink.withIndent(() {
        var fragment = library.units.singleWhere((fragment) {
          return fragment.source.uri == fragmentRequest.fragmentUri;
        });

        for (var request in fragmentRequest.requests) {
          var periodIndex = request.indexOf('.');
          var (prefixName, rawName) = switch (periodIndex) {
            > 0 => (
                request.substring(0, periodIndex),
                request.substring(periodIndex + 1),
              ),
            _ => (null, request),
          };

          void writeResult(ScopeLookupResult result) {
            sink.withIndent(() {
              elementPrinter.writeNamedElement('getter', result.getter);
              if (result.setter case var setter?) {
                elementPrinter.writeNamedElement('setter', setter);
              }
            });
          }

          sink.writelnWithIndent(request);
          if (prefixName != null) {
            var prefixLookup = fragment.scope.lookup(prefixName);
            expect(prefixLookup.setter, isNull);
            var importPrefix = prefixLookup.getter;
            if (importPrefix == null) {
              sink.withIndent(() {
                elementPrinter.writeNamedElement(prefixName, importPrefix);
              });
            } else {
              importPrefix as PrefixElementImpl;
              sink.withIndent(() {
                elementPrinter.writeNamedElement(prefixName, importPrefix);
              });
              var result = importPrefix.scope.lookup(rawName);
              writeResult(result);
            }
          } else {
            var result = fragment.scope.lookup(rawName);
            writeResult(result);
          }
        }
      });
    }

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }
}

@reflectiveTest
class LibraryFragmentElementTest_fromBytes extends LibraryFragmentElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class LibraryFragmentElementTest_keepLinking
    extends LibraryFragmentElementTest {
  @override
  bool get keepLinkingLibraries => true;
}

class LibraryFragmentScopeRequests {
  final Uri fragmentUri;
  final List<String> requests;

  LibraryFragmentScopeRequests(
    String fragmentUriStr,
    this.requests,
  ) : fragmentUri = Uri.parse(fragmentUriStr);
}
