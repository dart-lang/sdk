// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library smoke.test.codegen.recorder_test;

import 'package:analyzer/src/generated/element.dart';
import 'package:smoke/codegen/generator.dart';
import 'package:smoke/codegen/recorder.dart';
import 'package:unittest/unittest.dart';

import 'common.dart' show checkResults;
import 'testing_resolver_utils.dart' show initAnalyzer;

main() {
  var provider = initAnalyzer(_SOURCES);
  var generator;
  var recorder;
  setUp(() {
    generator = new SmokeCodeGenerator();
    recorder = new Recorder(generator, resolveImportUrl);
  });

  group('parents', () {
    test('simple subclassing', () {
      var lib = provider.libraryFor('/a.dart');
      recorder.lookupParent(lib.getType('A'));
      recorder.lookupParent(lib.getType('C'));

      checkResults(generator,
          imports: [
            "import '/a.dart' as smoke_0;",
            "import '/b.dart' as smoke_1;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.A: smoke_1.B,\n'
            '      smoke_0.C: smoke_0.A,\n'
            '    }));\n');
    });

    test('single mixin', () {
      var lib = provider.libraryFor('/a.dart');
      recorder.lookupParent(lib.getType('E'));

      checkResults(generator,
          imports: [
            "import '/a.dart' as smoke_0;",
          ],
          topLevel: 'abstract class _M0 {} // A & D1\n',
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.E: _M0,\n'
            '      _M0: smoke_0.A,\n'
            '    }));\n');
    });

    test('multiple mixins', () {
      var lib = provider.libraryFor('/a.dart');
      recorder.lookupParent(lib.getType('F'));

      checkResults(generator,
          imports: [
            "import '/a.dart' as smoke_0;",
          ],
          topLevel:
            'abstract class _M0 {} // A & D1\n'
            'abstract class _M1 {} // _M0 & D2\n'
            'abstract class _M2 {} // _M1 & D3\n',
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.F: _M2,\n'
            '      _M0: smoke_0.A,\n'
            '      _M1: _M0,\n'
            '      _M2: _M1,\n'
            '    }));\n');
    });

    test('same as common_test', () {
      var lib = provider.libraryFor('/common.dart');
      recorder.lookupParent(lib.getType('Annot'));
      recorder.lookupParent(lib.getType('AnnotB'));
      recorder.lookupParent(lib.getType('A'));
      recorder.lookupParent(lib.getType('B'));
      recorder.lookupParent(lib.getType('C'));
      recorder.lookupParent(lib.getType('D'));
      recorder.lookupParent(lib.getType('E'));
      recorder.lookupParent(lib.getType('E2'));
      recorder.lookupParent(lib.getType('F'));
      recorder.lookupParent(lib.getType('F2'));
      recorder.lookupParent(lib.getType('G'));
      recorder.lookupParent(lib.getType('H'));
      var coreLib = lib.visibleLibraries.firstWhere(
          (l) => l.displayName == 'dart.core');
      recorder.lookupParent(coreLib.getType('int'));
      recorder.lookupParent(coreLib.getType('num'));

      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          topLevel:
            'abstract class _M0 {} // C & A\n',
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.AnnotB: smoke_0.Annot,\n'
            '      smoke_0.D: _M0,\n'
            '      smoke_0.E2: smoke_0.E,\n'
            '      smoke_0.F2: smoke_0.F,\n'
            '      smoke_0.H: smoke_0.G,\n'
            '      int: num,\n'
            '      _M0: smoke_0.C,\n'
            '    }));\n');
    });
  });

  test('add static method, no declaration', () {
    var lib = provider.libraryFor('/common.dart');
    recorder.addStaticMethod(lib.getType('A'), 'sM');
    checkResults(generator,
        imports: [
          "import '/common.dart' as smoke_0;",
        ],
        initCall:
          'useGeneratedCode(new StaticConfiguration(\n'
          '    checkedMode: false,\n'
          '    staticMethods: {\n'
          '      smoke_0.A: {\n'
          '        #sM: smoke_0.A.sM,\n'
          '      },\n'
          '    }));\n');
  });

  group('lookup member', () {
    var lib;
    setUp(() {
      lib = provider.libraryFor('/common.dart');
    });

    test('missing declaration', () {
      recorder.lookupMember(lib.getType('A'), 'q', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: const {},\n'
            '    }));\n');
    });

    test('field declaration', () {
      recorder.lookupMember(lib.getType('A'), 'i', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #i: const Declaration(#i, int),\n'
            '      },\n'
            '    }));\n');
    });

    test('sattic field declaration', () {
      recorder.lookupMember(lib.getType('A'), 'sI', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #sI: const Declaration(#sI, int, isStatic: true),\n'
            '      },\n'
            '    }));\n');
    });

    test('property declaration', () {
      recorder.lookupMember(lib.getType('A'), 'j2', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #j2: const Declaration(#j2, int, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');
    });

    test('static property declaration', () {
      recorder.lookupMember(lib.getType('A'), 'sJ', includeAccessors: false);
      final details = 'kind: PROPERTY, isFinal: true, isStatic: true';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #sJ: const Declaration(#sJ, int, $details),\n'
            '      },\n'
            '    }));\n');
    });

    test('field and property of dynamic type', () {
      recorder.lookupMember(lib.getType('I'), 'i1', includeAccessors: false);
      recorder.lookupMember(lib.getType('I'), 'i2', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.I: {\n'
            '        #i1: const Declaration(#i1, dynamic),\n'
            '        #i2: const Declaration(#i2, dynamic, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');
    });

    test('property of concrete type', () {
      recorder.lookupMember(lib.getType('I'), 'i3', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.I: {\n'
            '        #i3: const Declaration(#i3, smoke_0.G, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '      },\n'
            '    }));\n');
    });

    test('method declaration', () {
      recorder.lookupMember(lib.getType('A'), 'inc0', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #inc0: const Declaration(#inc0, Function, kind: METHOD),\n'
            '      },\n'
            '    }));\n');
    });

    test('static method declaration', () {
      recorder.lookupMember(lib.getType('A'), 'sM', includeAccessors: false);
      const details = 'kind: METHOD, isStatic: true';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #sM: const Declaration(#sM, Function, $details),\n'
            '      },\n'
            '    }));\n');
    });

    test('inherited field - not recursive', () {
      recorder.lookupMember(lib.getType('D'), 'i', includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.D: const {},\n'
            '    }));\n');
    });

    test('inherited field - recursive', () {
      recorder.lookupMember(lib.getType('D'), 'i', recursive: true,
          includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          topLevel: 'abstract class _M0 {} // C & A\n',
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.D: _M0,\n'
            '      _M0: smoke_0.C,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.D: const {},\n'
            '      _M0: {\n'
            '        #i: const Declaration(#i, int),\n'
            '      },\n'
            '    }));\n');
    });

    test('inherited field - recursive deep', () {
      recorder.lookupMember(lib.getType('J3'), 'i', recursive: true,
          includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.J2: smoke_0.J1,\n'
            '      smoke_0.J3: smoke_0.J2,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.J1: {\n'
            '        #i: const Declaration(#i, int),\n'
            '      },\n'
            '      smoke_0.J2: const {},\n'
            '      smoke_0.J3: const {},\n'
            '    }));\n');
    });

    test('inherited field - recursive - includeUpTo', () {
      recorder.lookupMember(lib.getType('J3'), 'i', recursive: true,
          includeAccessors: false, includeUpTo: lib.getType('J1'));
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.J2: smoke_0.J1,\n'
            '      smoke_0.J3: smoke_0.J2,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.J2: const {},\n'
            '      smoke_0.J3: const {},\n'
            '    }));\n');
    });
  });

  group('query', () {
    test('default query', () {
      var options = new QueryOptions();
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('A'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #i: const Declaration(#i, int),\n'
            '        #j: const Declaration(#j, int),\n'
            '        #j2: const Declaration(#j2, int, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');

    });

    test('only fields', () {
      var options = new QueryOptions(includeProperties: false);
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('A'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #i: const Declaration(#i, int),\n'
            '        #j: const Declaration(#j, int),\n'
            '      },\n'
            '    }));\n');

    });

    test('only properties', () {
      var options = new QueryOptions(includeFields: false);
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('A'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #j2: const Declaration(#j2, int, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');

    });

    test('fields, properties, and and methods', () {
      var options = new QueryOptions(includeMethods: true);
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('A'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #i: const Declaration(#i, int),\n'
            '        #inc0: const Declaration(#inc0, Function, kind: METHOD),\n'
            '        #inc1: const Declaration(#inc1, Function, kind: METHOD),\n'
            '        #inc2: const Declaration(#inc2, Function, kind: METHOD),\n'
            '        #j: const Declaration(#j, int),\n'
            '        #j2: const Declaration(#j2, int, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');
    });

    test('exclude inherited', () {
      var options = new QueryOptions(includeInherited: false);
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('D'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.D: {\n'
            '        #i2: const Declaration(#i2, int, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '        #x2: const Declaration(#x2, int, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '      },\n'
            '    }));\n');
    });

    test('include inherited', () {
      var options = new QueryOptions(includeInherited: true);
      var lib = provider.libraryFor('/common.dart');
      recorder.runQuery(lib.getType('D'), options, includeAccessors: false);
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          topLevel: 'abstract class _M0 {} // C & A\n',
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.D: _M0,\n'
            '      _M0: smoke_0.C,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.C: {\n'
            '        #b: const Declaration(#b, smoke_0.B),\n'
            '        #x: const Declaration(#x, int),\n'
            '        #y: const Declaration(#y, String),\n'
            '      },\n'
            '      smoke_0.D: {\n'
            '        #i2: const Declaration(#i2, int, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '        #x2: const Declaration(#x2, int, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '      },\n'
            '      _M0: {\n'
            '        #i: const Declaration(#i, int),\n'
            '        #j: const Declaration(#j, int),\n'
            '        #j2: const Declaration(#j2, int, kind: PROPERTY),\n'
            '      },\n'
            '    }));\n');
    });

    test('exact annotation', () {
      var lib = provider.libraryFor('/common.dart');
      var vars = lib.definingCompilationUnit.topLevelVariables;
      expect(vars[0].name, 'a1');
      var options = new QueryOptions(includeInherited: true,
          withAnnotations: [vars[0]]);
      recorder.runQuery(lib.getType('H'), options, includeAccessors: false);
      final annot = 'annotations: const [smoke_0.a1]';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.H: smoke_0.G,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.G: {\n'
            '        #b: const Declaration(#b, int, $annot),\n'
            '      },\n'
            '      smoke_0.H: {\n'
            '        #f: const Declaration(#f, int, $annot),\n'
            '        #g: const Declaration(#g, int, $annot),\n'
            '      },\n'
            '    }));\n');
    });

    test('type annotation', () {
      var lib = provider.libraryFor('/common.dart');
      var options = new QueryOptions(includeInherited: true,
          withAnnotations: [lib.getType('Annot')]);
      recorder.runQuery(lib.getType('H'), options, includeAccessors: false);
      final a1Annot = 'annotations: const [smoke_0.a1]';
      final a3Annot = 'annotations: const [smoke_0.a3]';
      final exprAnnot = 'annotations: const [const smoke_0.Annot(1)]';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    parents: {\n'
            '      smoke_0.H: smoke_0.G,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.G: {\n'
            '        #b: const Declaration(#b, int, $a1Annot),\n'
            '      },\n'
            '      smoke_0.H: {\n'
            '        #f: const Declaration(#f, int, $a1Annot),\n'
            '        #g: const Declaration(#g, int, $a1Annot),\n'
            '        #i: const Declaration(#i, int, $a3Annot),\n'
            '        #j: const Declaration(#j, int, $exprAnnot),\n'
            '      },\n'
            '    }));\n');
    });

    test('type annotation with named arguments', () {
      var lib = provider.libraryFor('/common.dart');
      var options = new QueryOptions(includeInherited: true,
          withAnnotations: [lib.getType('AnnotC')]);
      recorder.runQuery(lib.getType('K'), options, includeAccessors: false);
      final kAnnot = 'annotations: const [const smoke_0.AnnotC(named: true)]';
      final k2Annot = 'annotations: const [const smoke_0.AnnotC()]';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.K: {\n'
            '        #k: const Declaration(#k, int, $kAnnot),\n'
            '        #k2: const Declaration(#k2, int, $k2Annot),\n'
            '      },\n'
            '    }));\n');
    });
  });

  group('with accessors', () {
    test('lookup member', () {
      var lib = provider.libraryFor('/common.dart');
      recorder.lookupMember(lib.getType('I'), 'i1');
      recorder.lookupMember(lib.getType('I'), 'i2');
      recorder.lookupMember(lib.getType('I'), 'i3');
      recorder.lookupMember(lib.getType('I'), 'm4');
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    getters: {\n'
            '      #i1: (o) => o.i1,\n'
            '      #i2: (o) => o.i2,\n'
            '      #i3: (o) => o.i3,\n'
            '      #m4: (o) => o.m4,\n'
            '    },\n'
            '    setters: {\n' // #i3 is final
            '      #i1: (o, v) { o.i1 = v; },\n'
            '      #i2: (o, v) { o.i2 = v; },\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.I: {\n'
            '        #i1: const Declaration(#i1, dynamic),\n'
            '        #i2: const Declaration(#i2, dynamic, kind: PROPERTY),\n'
            '        #i3: const Declaration(#i3, smoke_0.G, kind: PROPERTY, '
                                           'isFinal: true),\n'
            '        #m4: const Declaration(#m4, Function, kind: METHOD),\n'
            '      },\n'
            '    },\n'
            '    names: {\n'
            '      #i1: r\'i1\',\n'
            '      #i2: r\'i2\',\n'
            '      #i3: r\'i3\',\n'
            '      #m4: r\'m4\',\n'
            '    }));\n');
    });

    test('static members', () {
      var lib = provider.libraryFor('/common.dart');
      recorder.lookupMember(lib.getType('A'), 'sI');
      recorder.lookupMember(lib.getType('A'), 'sJ');
      recorder.lookupMember(lib.getType('A'), 'sM');
      final pDetails = 'kind: PROPERTY, isFinal: true, isStatic: true';
      const mDetails = 'kind: METHOD, isStatic: true';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        #sI: const Declaration(#sI, int, isStatic: true),\n'
            '        #sJ: const Declaration(#sJ, int, $pDetails),\n'
            '        #sM: const Declaration(#sM, Function, $mDetails),\n'
            '      },\n'
            '    },\n'
            '    staticMethods: {\n'
            '      smoke_0.A: {\n'
            '        #sM: smoke_0.A.sM,\n'
            '      },\n'
            '    },\n'
            '    names: {\n'
            '      #sM: r\'sM\',\n'
            '    }));\n');
    });

    test('query', () {
      var lib = provider.libraryFor('/common.dart');
      var options = new QueryOptions(includeInherited: true,
          withAnnotations: [lib.getType('Annot')]);
      recorder.runQuery(lib.getType('H'), options);
      final a1Annot = 'annotations: const [smoke_0.a1]';
      final a3Annot = 'annotations: const [smoke_0.a3]';
      final exprAnnot = 'annotations: const [const smoke_0.Annot(1)]';
      checkResults(generator,
          imports: [
            "import '/common.dart' as smoke_0;",
          ],
          initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    getters: {\n'
            '      #b: (o) => o.b,\n'
            '      #f: (o) => o.f,\n'
            '      #g: (o) => o.g,\n'
            '      #i: (o) => o.i,\n'
            '      #j: (o) => o.j,\n'
            '    },\n'
            '    setters: {\n' // #i3 is final
            '      #b: (o, v) { o.b = v; },\n'
            '      #f: (o, v) { o.f = v; },\n'
            '      #g: (o, v) { o.g = v; },\n'
            '      #i: (o, v) { o.i = v; },\n'
            '      #j: (o, v) { o.j = v; },\n'
            '    },\n'
            '    parents: {\n'
            '      smoke_0.H: smoke_0.G,\n'
            '    },\n'
            '    declarations: {\n'
            '      smoke_0.G: {\n'
            '        #b: const Declaration(#b, int, $a1Annot),\n'
            '      },\n'
            '      smoke_0.H: {\n'
            '        #f: const Declaration(#f, int, $a1Annot),\n'
            '        #g: const Declaration(#g, int, $a1Annot),\n'
            '        #i: const Declaration(#i, int, $a3Annot),\n'
            '        #j: const Declaration(#j, int, $exprAnnot),\n'
            '      },\n'
            '    },\n'
            '    names: {\n'
            '      #b: r\'b\',\n'
            '      #f: r\'f\',\n'
            '      #g: r\'g\',\n'
            '      #i: r\'i\',\n'
            '      #j: r\'j\',\n'
            '    }));\n');
    });
  });
}

const _SOURCES = const {
  '/a.dart': '''
      library a;
      import '/b.dart';

      class Annot { const Annot(); }
      const annot = const Annot();

      class A extends B {}
      class C extends A {}
      class D1 {
        int d1;
      }
      class D2 {
        int d2;
      }
      class D3 {
        int d3;
      }
      class E extends A with D1 {
        int e1;
      }
      class F extends A with D1, D2, D3 {
        int f1;
      }
      ''',

  '/b.dart': '''
      library b;

      class B {}
      ''',
  '/common.dart': '''
      library common;

      class A {
        int i = 42;
        int j = 44;
        int get j2 => j;
        void set j2(int v) { j = v; }
        void inc0() { i++; }
        void inc1(int v) { i = i + (v == null ? -10 : v); }
        void inc2([int v]) { i = i + (v == null ? -10 : v); }
        static int sI;
        static int get sJ => 0;
        static void sM() {}
      }

      class B {
        final int f = 3;
        int _w;
        int get w => _w;
        set w(int v) { _w = v; }

        String z;
        A a;

        B(this._w, this.z, this.a);
      }

      class C {
        int x;
        String y;
        B b;

        inc(int n) {
          x = x + n;
        }
        dec(int n) {
          x = x - n;
        }

        C(this.x, this.y, this.b);
      }


      class D extends C with A {
        int get x2 => x;
        int get i2 => i;

        D(x, y, b) : super(x, y, b);
      }

      class E {
        set x(int v) { }
        int get y => 1;

        noSuchMethod(i) => y;
      }

      class E2 extends E {}

      class F {
        static int staticMethod(A a) => a.i;
      }

      class F2 extends F {}

      class Annot { const Annot(int ignore); }
      class AnnotB extends Annot { const AnnotB(); }
      class AnnotC { const AnnotC({bool named: false}); }
      const a1 = const Annot(0);
      const a2 = 32;
      const a3 = const AnnotB();


      class G {
        int a;
        @a1 int b;
        int c;
        @a2 int d;
      }

      class H extends G {
        int e;
        @a1 int f;
        @a1 int g;
        @a2 int h;
        @a3 int i;
        @Annot(1) int j;
      }

      class I {
        dynamic i1;
        get i2 => null;
        set i2(v) {}
        G get i3;
        G m4() {};
      }

      class J1 {
        int i;
      }
      class J2 extends J1 {
      }
      class J3 extends J2 {
      }

      class K {
        @AnnotC(named: true) int k;
        @AnnotC() int k2;
      }
      '''
};

resolveImportUrl(LibraryElement lib) =>
    lib.isDartCore ? 'dart:core' : '/${lib.displayName}.dart';
