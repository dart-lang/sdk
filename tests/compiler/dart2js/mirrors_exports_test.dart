// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';
import 'memory_compiler.dart';
import 'package:compiler/src/mirrors/source_mirrors.dart';

const SOURCE_FILES = const {
'main.dart': '''
import 'a.dart' show A1, A2;
import 'b.dart' as b hide B1;
export 'a.dart' show A2 hide A3, A1;
export 'b.dart' hide B1, B2 show B3;
import 'dart:core' as core;

main() {}
''',
'a.dart': '''
class A1 {}
class A2 {}
class A3 {}
''',
'b.dart': '''
class B1 {}
class B2 {}
class B3 {}
'''
};

void main() {
  asyncTest(() => mirrorSystemFor(SOURCE_FILES).then((MirrorSystem mirrors) {
    LibrarySourceMirror mainLibrary =
        mirrors.libraries[Uri.parse('memory:main.dart')];
    Expect.isNotNull(mainLibrary);

    LibrarySourceMirror aLibrary =
        mirrors.libraries[Uri.parse('memory:a.dart')];
    Expect.isNotNull(aLibrary);

    LibrarySourceMirror bLibrary =
        mirrors.libraries[Uri.parse('memory:b.dart')];
    Expect.isNotNull(bLibrary);

    LibrarySourceMirror coreLibrary =
        mirrors.libraries[Uri.parse('dart:core')];
    Expect.isNotNull(coreLibrary);

    var dependencies = mainLibrary.libraryDependencies;
    Expect.isNotNull(dependencies);
    Expect.equals(5, dependencies.length);

    // import 'a.dart' show A1, A2;
    var dependency = dependencies[0];
    Expect.isNotNull(dependency);
    Expect.isTrue(dependency.isImport);
    Expect.isFalse(dependency.isExport);
    Expect.equals(mainLibrary, dependency.sourceLibrary);
    Expect.equals(aLibrary, dependency.targetLibrary);
    Expect.isNull(dependency.prefix);

    var combinators = dependency.combinators;
    Expect.isNotNull(combinators);
    Expect.equals(1, combinators.length);

    var combinator = combinators[0];
    Expect.isNotNull(combinator);
    Expect.isTrue(combinator.isShow);
    Expect.isFalse(combinator.isHide);
    Expect.listEquals(['A1', 'A2'], combinator.identifiers);

    // import 'b.dart' as b hide B1;
    dependency = dependencies[1];
    Expect.isNotNull(dependency);
    Expect.isTrue(dependency.isImport);
    Expect.isFalse(dependency.isExport);
    Expect.equals(mainLibrary, dependency.sourceLibrary);
    Expect.equals(bLibrary, dependency.targetLibrary);
    Expect.equals('b', dependency.prefix);

    combinators = dependency.combinators;
    Expect.isNotNull(combinators);
    Expect.equals(1, combinators.length);

    combinator = combinators[0];
    Expect.isNotNull(combinator);
    Expect.isFalse(combinator.isShow);
    Expect.isTrue(combinator.isHide);
    Expect.listEquals(['B1'], combinator.identifiers);

    // export 'a.dart' show A2 hide A3, A1;
    dependency = dependencies[2];
    Expect.isNotNull(dependency);
    Expect.isFalse(dependency.isImport);
    Expect.isTrue(dependency.isExport);
    Expect.equals(mainLibrary, dependency.sourceLibrary);
    Expect.equals(aLibrary, dependency.targetLibrary);
    Expect.isNull(dependency.prefix);

    combinators = dependency.combinators;
    Expect.isNotNull(combinators);
    Expect.equals(2, combinators.length);

    combinator = combinators[0];
    Expect.isNotNull(combinator);
    Expect.isTrue(combinator.isShow);
    Expect.isFalse(combinator.isHide);
    Expect.listEquals(['A2'], combinator.identifiers);

    combinator = combinators[1];
    Expect.isNotNull(combinator);
    Expect.isFalse(combinator.isShow);
    Expect.isTrue(combinator.isHide);
    Expect.listEquals(['A3', 'A1'], combinator.identifiers);

    // export 'b.dart' hide B1, B2 show B3;
    dependency = dependencies[3];
    Expect.isNotNull(dependency);
    Expect.isFalse(dependency.isImport);
    Expect.isTrue(dependency.isExport);
    Expect.equals(mainLibrary, dependency.sourceLibrary);
    Expect.equals(bLibrary, dependency.targetLibrary);
    Expect.isNull(dependency.prefix);

    combinators = dependency.combinators;
    Expect.isNotNull(combinators);
    Expect.equals(2, combinators.length);

    combinator = combinators[0];
    Expect.isNotNull(combinator);
    Expect.isFalse(combinator.isShow);
    Expect.isTrue(combinator.isHide);
    Expect.listEquals(['B1', 'B2'], combinator.identifiers);

    combinator = combinators[1];
    Expect.isNotNull(combinator);
    Expect.isTrue(combinator.isShow);
    Expect.isFalse(combinator.isHide);
    Expect.listEquals(['B3'], combinator.identifiers);

    // import 'dart:core' as core;
    dependency = dependencies[4];
    Expect.isNotNull(dependency);
    Expect.isTrue(dependency.isImport);
    Expect.isFalse(dependency.isExport);
    Expect.equals(mainLibrary, dependency.sourceLibrary);
    Expect.equals(coreLibrary, dependency.targetLibrary);
    Expect.equals('core', dependency.prefix);

    combinators = dependency.combinators;
    Expect.isNotNull(combinators);
    Expect.equals(0, combinators.length);
  }));
}