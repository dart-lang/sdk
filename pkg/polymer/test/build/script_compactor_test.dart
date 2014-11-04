// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.script_compactor_test;

import 'dart:convert';

import 'package:code_transformers/tests.dart' show testingDartSdkDirectory;
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/messages.dart';
import 'package:polymer/src/build/script_compactor.dart';
import 'package:smoke/codegen/generator.dart' show DEFAULT_IMPORTS;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = [[new ScriptCompactor(new TransformOptions(),
      sdkDir: testingDartSdkDirectory)]];
  group('initializers', () => initializerTests(phases));
  group('experimental', () => initializerTestsExperimental(phases));
  group('codegen', () => codegenTests(phases));
  group('log element injection', logElementInjectionTests);
}

initializerTests(phases) {
  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html._data': EMPTY_DATA,
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('no changes outside web/', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>',
      'a|lib/test.html._data': expectedData(['lib/a.dart']),
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>',
      'a|lib/test.html._data': expectedData(['lib/a.dart']),
    });

  testPhases('single script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'main(){}',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false));
            configureForDeployment([]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'main(){}',
    });

  testPhases('simple initialization', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '}\n'
          'main(){}',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {},
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testPhases('use const expressions', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/b.dart':
          'library a;\n'
          'const x = "x";\n',
      'a|web/c.dart':
          'part of a;\n'
          'const dash = "-";\n',
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'import "b.dart";\n'
          'part "c.dart";\n'
          'const letterO = "o";\n'
          '@CustomTag("\$x\${dash}f\${letterO}o2")\n'
          'class XFoo extends PolymerElement {\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {},
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo2\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });


  testLogOutput(
      (options) =>
          new ScriptCompactor(options, sdkDir: testingDartSdkDirectory),
      'invalid const expression logs', {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data': expectedData(['web/a.dart']),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.dart";\n'
            '@CustomTag("\${x}-foo")\n' // invalid, x is not defined
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {}, [
        'warning: ${INVALID_ANNOTATION_ARGUMENT.create(
            {'name': 'CustomTag'}).snippet} (web/a.dart 2 11)',
      ]);

  testPhases(
      'invalid const expression', phases, {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data': expectedData(['web/a.dart']),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.dart";\n'
            '@CustomTag("\${x}-foo")\n' // invalid, x is not defined
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {
        'a|web/test.html_bootstrap.dart':
            '''$MAIN_HEADER
            import 'a.dart' as i0;
            ${DEFAULT_IMPORTS.join('\n')}
            import 'a.dart' as smoke_0;
            import 'package:polymer/polymer.dart' as smoke_1;

            void main() {
              useGeneratedCode(new StaticConfiguration(
                  checkedMode: false,
                  parents: {
                    smoke_0.XFoo: smoke_1.PolymerElement,
                  },
                  declarations: {
                    smoke_0.XFoo: {},
                  }));
              configureForDeployment([]);
              i0.main();
            }
            '''.replaceAll('\n            ', '\n'),

      });

  testPhases('no polymer import (no warning, but no crash either)', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.broken.import.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '}\n'
          'main(){}',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false));
            configureForDeployment([]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),

    }, []);

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><div></div>',
      'a|web/test.html._data':
          expectedData(['web/a.dart', 'web/b.dart', 'web/c.dart',
              'web/i.dart', 'web/j.dart', 'web/d.dart']),
      'a|web/d.dart':
          'library d;\n'
          'import "package:polymer/polymer.dart";\n'
          'main(){}\n@initMethod mD(){}',

      'a|web/a.dart':
          'import "package:polymer/polymer.dart";\n'
          'export "i.dart" hide mI2;\n'
          '@initMethod mA(){}\n',

      'a|web/b.dart':
          'import "package:polymer/polymer.dart";\n'
          'export "e.dart";\n'
          'export "f.dart" show XF1, mF1;\n'
          'export "g.dart" hide XG1, mG1;\n'
          'export "h.dart" show XH1, mH1 hide mH1, mH2;\n'
          '@initMethod mB(){}\n',

      'a|web/c.dart':
          'import "package:polymer/polymer.dart";\n'
          'part "c_part.dart";\n'
          '@CustomTag("x-c1") class XC1 extends PolymerElement {}\n',

      'a|web/c_part.dart':
          '@CustomTag("x-c2") class XC2 extends PolymerElement {}\n',

      'a|web/e.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-e") class XE extends PolymerElement {}\n'
          '@initMethod mE(){}\n',

      'a|web/f.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-f1") class XF1 extends PolymerElement {}\n'
          '@initMethod mF1(){}\n'
          '@CustomTag("x-f2") class XF2 extends PolymerElement {}\n'
          '@initMethod mF2(){}\n',

      'a|web/g.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-g1") class XG1 extends PolymerElement {}\n'
          '@initMethod mG1(){}\n'
          '@CustomTag("x-g2") class XG2 extends PolymerElement {}\n'
          '@initMethod mG2(){}\n',

      'a|web/h.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-h1") class XH1 extends PolymerElement {}\n'
          '@initMethod mH1(){}\n'
          '@CustomTag("x-h2") class XH2 extends PolymerElement {}\n'
          '@initMethod mH2(){}\n',

      'a|web/i.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-i") class XI extends PolymerElement {}\n'
          '@initMethod mI1(){}\n'
          '@initMethod mI2(){}\n',

      'a|web/j.dart':
          'export "a.dart";\n',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body><div></div>'
          '<script type="application/dart" src="test.html_bootstrap.dart">'
          '</script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'b.dart' as i1;
          import 'c.dart' as i2;
          import 'i.dart' as i3;
          import 'j.dart' as i4;
          import 'd.dart' as i5;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'i.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;
          import 'e.dart' as smoke_2;
          import 'f.dart' as smoke_3;
          import 'g.dart' as smoke_4;
          import 'h.dart' as smoke_5;
          import 'c.dart' as smoke_6;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_6.XC1: smoke_1.PolymerElement,
                  smoke_6.XC2: smoke_1.PolymerElement,
                  smoke_2.XE: smoke_1.PolymerElement,
                  smoke_3.XF1: smoke_1.PolymerElement,
                  smoke_4.XG2: smoke_1.PolymerElement,
                  smoke_5.XH1: smoke_1.PolymerElement,
                  smoke_0.XI: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_6.XC1: {},
                  smoke_6.XC2: {},
                  smoke_2.XE: {},
                  smoke_3.XF1: {},
                  smoke_4.XG2: {},
                  smoke_5.XH1: {},
                  smoke_0.XI: {},
                }));
            configureForDeployment([
                i0.mA,
                i0.mI1,
                () => Polymer.register('x-i', i0.XI),
                i1.mB,
                i1.mE,
                i1.mF1,
                i1.mG2,
                () => Polymer.register('x-e', i1.XE),
                () => Polymer.register('x-f1', i1.XF1),
                () => Polymer.register('x-g2', i1.XG2),
                () => Polymer.register('x-h1', i1.XH1),
                () => Polymer.register('x-c1', i2.XC1),
                () => Polymer.register('x-c2', i2.XC2),
                i3.mI2,
                i5.mD,
              ]);
            i5.main();
          }
          '''.replaceAll('\n          ', '\n'),
    }, null);
}

initializerTestsExperimental(phases) {
  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html._data': EMPTY_DATA,
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('no changes outside web/', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>',
      'a|lib/test.html._data': expectedData(['lib/a.dart'], experimental: true),
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>',
      'a|lib/test.html._data': expectedData(['lib/a.dart'], experimental: true),
    });

  testPhases('single script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart'], experimental: true),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@initMethod main(){}',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false));
            startPolymer([
                i0.main,
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@initMethod main(){}',
    });

  testPhases('simple initialization', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart'], experimental: true),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '}\n'
          '@initMethod main(){}',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {},
                }));
            startPolymer([
                i0.main,
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testPhases('use const expressions', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart'], experimental: true),
      'a|web/b.dart':
          'library a;\n'
          'const x = "x";\n',
      'a|web/c.dart':
          'part of a;\n'
          'const dash = "-";\n',
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'import "b.dart";\n'
          'part "c.dart";\n'
          'const letterO = "o";\n'
          '@CustomTag("\$x\${dash}f\${letterO}o2")\n'
          'class XFoo extends PolymerElement {\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {},
                }));
            startPolymer([
                () => Polymer.register(\'x-foo2\', i0.XFoo),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testLogOutput(
      (options) =>
          new ScriptCompactor(options, sdkDir: testingDartSdkDirectory),
      'invalid const expression logs', {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data':
            expectedData(['web/a.dart'], experimental: true),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.dart";\n'
            '@CustomTag("\${x}-foo")\n' // invalid, x is not defined
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {}, [
        'warning: ${INVALID_ANNOTATION_ARGUMENT.create(
            {'name': 'CustomTag'}).snippet} (web/a.dart 2 11)',
        'warning: ${NO_INITIALIZATION.snippet}',
      ]);

  testPhases(
      'invalid const expression', phases, {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data':
            expectedData(['web/a.dart'], experimental: true),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.dart";\n'
            '@CustomTag("\${x}-foo")\n' // invalid, x is not defined
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {
        'a|web/test.html_bootstrap.dart':
            '''$MAIN_HEADER
            import 'a.dart' as i0;
            ${DEFAULT_IMPORTS.join('\n')}
            import 'a.dart' as smoke_0;
            import 'package:polymer/polymer.dart' as smoke_1;

            void main() {
              useGeneratedCode(new StaticConfiguration(
                  checkedMode: false,
                  parents: {
                    smoke_0.XFoo: smoke_1.PolymerElement,
                  },
                  declarations: {
                    smoke_0.XFoo: {},
                  }));
              startPolymer([]);
            }
            '''.replaceAll('\n            ', '\n'),
      });

  testLogOutput(
      (options) =>
          new ScriptCompactor(options, sdkDir: testingDartSdkDirectory),
      'no polymer import logs', {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data': expectedData(['web/a.dart'], experimental: true),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.broken.import.dart";\n'
            '@CustomTag("x-foo")\n'
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {}, [
        'warning: ${NO_INITIALIZATION.snippet}',
      ]);

  testPhases(
      'no polymer import', phases, {
        'a|web/test.html':
            '<!DOCTYPE html><html><head>',
        'a|web/test.html._data':
            expectedData(['web/a.dart'], experimental: true),
        'a|web/a.dart':
            'library a;\n'
            'import "package:polymer/polymer.broken.import.dart";\n'
            '@CustomTag("x-foo")\n'
            'class XFoo extends PolymerElement {\n'
            '}\n'
            'main(){}',
      }, {
        'a|web/test.html_bootstrap.dart':
            '''$MAIN_HEADER
            import 'a.dart' as i0;
            ${DEFAULT_IMPORTS.join('\n')}

            void main() {
              useGeneratedCode(new StaticConfiguration(
                  checkedMode: false));
              startPolymer([]);
            }
            '''.replaceAll('\n            ', '\n'),

      });

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><div></div>',
      'a|web/test.html._data':
          expectedData(['web/a.dart', 'web/b.dart', 'web/c.dart', 'web/d.dart'], experimental: true),
      'a|web/d.dart':
          'library d;\n'
          'import "package:polymer/polymer.dart";\n'
          '@initMethod main(){}\n@initMethod mD(){}',

      'a|web/a.dart':
          'import "package:polymer/polymer.dart";\n'
          '@initMethod mA(){}\n',

      'a|web/b.dart':
          'import "package:polymer/polymer.dart";\n'
          'export "e.dart";\n'
          'export "f.dart" show XF1, mF1;\n'
          'export "g.dart" hide XG1, mG1;\n'
          'export "h.dart" show XH1, mH1 hide mH1, mH2;\n'
          '@initMethod mB(){}\n',

      'a|web/c.dart':
          'import "package:polymer/polymer.dart";\n'
          'part "c_part.dart";\n'
          '@CustomTag("x-c1") class XC1 extends PolymerElement {}\n',

      'a|web/c_part.dart':
          '@CustomTag("x-c2") class XC2 extends PolymerElement {}\n',

      'a|web/e.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-e") class XE extends PolymerElement {}\n'
          '@initMethod mE(){}\n',

      'a|web/f.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-f1") class XF1 extends PolymerElement {}\n'
          '@initMethod mF1(){}\n'
          '@CustomTag("x-f2") class XF2 extends PolymerElement {}\n'
          '@initMethod mF2(){}\n',

      'a|web/g.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-g1") class XG1 extends PolymerElement {}\n'
          '@initMethod mG1(){}\n'
          '@CustomTag("x-g2") class XG2 extends PolymerElement {}\n'
          '@initMethod mG2(){}\n',

      'a|web/h.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-h1") class XH1 extends PolymerElement {}\n'
          '@initMethod mH1(){}\n'
          '@CustomTag("x-h2") class XH2 extends PolymerElement {}\n'
          '@initMethod mH2(){}\n',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body><div></div>'
          '<script type="application/dart" src="test.html_bootstrap.dart">'
          '</script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'b.dart' as i1;
          import 'c.dart' as i2;
          import 'd.dart' as i3;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'e.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;
          import 'f.dart' as smoke_2;
          import 'g.dart' as smoke_3;
          import 'h.dart' as smoke_4;
          import 'c.dart' as smoke_5;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_5.XC1: smoke_1.PolymerElement,
                  smoke_5.XC2: smoke_1.PolymerElement,
                  smoke_0.XE: smoke_1.PolymerElement,
                  smoke_2.XF1: smoke_1.PolymerElement,
                  smoke_3.XG2: smoke_1.PolymerElement,
                  smoke_4.XH1: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_5.XC1: {},
                  smoke_5.XC2: {},
                  smoke_0.XE: {},
                  smoke_2.XF1: {},
                  smoke_3.XG2: {},
                  smoke_4.XH1: {},
                }));
            startPolymer([
                i0.mA,
                i1.mB,
                i1.mE,
                i1.mF1,
                i1.mG2,
                () => Polymer.register('x-e', i1.XE),
                () => Polymer.register('x-f1', i1.XF1),
                () => Polymer.register('x-g2', i1.XG2),
                () => Polymer.register('x-h1', i1.XH1),
                () => Polymer.register('x-c1', i2.XC1),
                () => Polymer.register('x-c2', i2.XC2),
                i3.main,
                i3.mD,
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
    }, null);
}

codegenTests(phases) {
  testPhases('bindings', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<polymer-element name="foo-bar"><template>'
          '<div>{{a.node}}</div>'
          '<div>{{ anotherNode }}</div>' // extra space inside bindings is OK
          '<div>{{a.call1(a)}}</div>'
          '<div>{{call2(a)}}</div>'
          '<div>{{}}</div>'              // empty bindings are ignored
          '<div>{{ }}</div>'
          '<div class="{{an.attribute}}"></div>'
          '<a href="path/{{within.an.attribute}}/foo/bar"></a>'
          '<div data-attribute="{{anotherAttribute}}"></div>'
          // input and custom-element attributes are treated as 2-way bindings:
          '<input value="{{this.iS.twoWay}}">'
          '<input value="{{this.iS.twoWayInt | intToStringTransformer}}">'
          '<something-else my-attribute="{{here.too}}"></something-else>'
          '<div on-click="{{methodName}}"></div>'
          '<div on-click="{{ methodName2 }}"></div>' // extra space is OK
          // empty handlers are invalid, but we still produce valid output.
          '<div on-click="{{}}"></div>'
          '<div on-click="{{ }}"></div>'
          '</template></polymer-element>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'main(){}',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                getters: {
                  #a: (o) => o.a,
                  #an: (o) => o.an,
                  #anotherAttribute: (o) => o.anotherAttribute,
                  #anotherNode: (o) => o.anotherNode,
                  #attribute: (o) => o.attribute,
                  #call1: (o) => o.call1,
                  #call2: (o) => o.call2,
                  #here: (o) => o.here,
                  #iS: (o) => o.iS,
                  #intToStringTransformer: (o) => o.intToStringTransformer,
                  #methodName: (o) => o.methodName,
                  #methodName2: (o) => o.methodName2,
                  #node: (o) => o.node,
                  #too: (o) => o.too,
                  #twoWay: (o) => o.twoWay,
                  #twoWayInt: (o) => o.twoWayInt,
                  #within: (o) => o.within,
                },
                setters: {
                  #too: (o, v) { o.too = v; },
                  #twoWay: (o, v) { o.twoWay = v; },
                  #twoWayInt: (o, v) { o.twoWayInt = v; },
                },
                names: {
                  #a: r'a',
                  #an: r'an',
                  #anotherAttribute: r'anotherAttribute',
                  #anotherNode: r'anotherNode',
                  #attribute: r'attribute',
                  #call1: r'call1',
                  #call2: r'call2',
                  #here: r'here',
                  #iS: r'iS',
                  #intToStringTransformer: r'intToStringTransformer',
                  #methodName: r'methodName',
                  #methodName2: r'methodName2',
                  #node: r'node',
                  #too: r'too',
                  #twoWay: r'twoWay',
                  #twoWayInt: r'twoWayInt',
                  #within: r'within',
                }));
            configureForDeployment([]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          'main(){}',
    });

  computedDeclaration(name, expr) =>
      '#$name: const Declaration(#$name, dynamic, kind: PROPERTY,'
      ' isFinal: true, annotations: const [const smoke_1.ComputedProperty'
      '(\'$expr\')])';

  testPhases('computed properties', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<polymer-element name="x-foo"><template>'
          '</template></polymer-element>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '  @ComputedProperty("ta.tb")\n'
          '  get pa => readValue(#pa);\n'
          '  @ComputedProperty(" tc ")\n' // extra space inside is OK
          '  get pb => null;\n'
          '  @ComputedProperty("td.m1(te)")\n'
          '  get pc => null;\n'
          '  @ComputedProperty("m2(tf)")\n'
          '  get pd => null;\n'
          '  @ComputedProperty("")\n'              // empty is ignored
          '  get pe => null;\n'
          '  @ComputedProperty(" ")\n'
          '  get pf => null;\n'
          '  @ComputedProperty("tg + th")\n'
          '  get pg => null;\n'
          '  @ComputedProperty("ti.tj | tk")\n'
          '  get ph => null;\n'
          '}\n'
          'main(){}',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                getters: {
                  #m1: (o) => o.m1,
                  #m2: (o) => o.m2,
                  #pa: (o) => o.pa,
                  #pb: (o) => o.pb,
                  #pc: (o) => o.pc,
                  #pd: (o) => o.pd,
                  #pe: (o) => o.pe,
                  #pf: (o) => o.pf,
                  #pg: (o) => o.pg,
                  #ph: (o) => o.ph,
                  #ta: (o) => o.ta,
                  #tb: (o) => o.tb,
                  #tc: (o) => o.tc,
                  #td: (o) => o.td,
                  #te: (o) => o.te,
                  #tf: (o) => o.tf,
                  #tg: (o) => o.tg,
                  #th: (o) => o.th,
                  #ti: (o) => o.ti,
                  #tj: (o) => o.tj,
                  #tk: (o) => o.tk,
                },
                setters: {
                  #tb: (o, v) { o.tb = v; },
                  #tc: (o, v) { o.tc = v; },
                  #tj: (o, v) { o.tj = v; },
                },
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {
                    ${computedDeclaration('pa', 'ta.tb')},
                    ${computedDeclaration('pb', ' tc ')},
                    ${computedDeclaration('pc', 'td.m1(te)')},
                    ${computedDeclaration('pd', 'm2(tf)')},
                    ${computedDeclaration('pe', '')},
                    ${computedDeclaration('pf', ' ')},
                    ${computedDeclaration('pg', 'tg + th')},
                    ${computedDeclaration('ph', 'ti.tj | tk')},
                  },
                },
                names: {
                  #m1: r'm1',
                  #m2: r'm2',
                  #pa: r'pa',
                  #pb: r'pb',
                  #pc: r'pc',
                  #pd: r'pd',
                  #pe: r'pe',
                  #pf: r'pf',
                  #pg: r'pg',
                  #ph: r'ph',
                  #ta: r'ta',
                  #tb: r'tb',
                  #tc: r'tc',
                  #td: r'td',
                  #te: r'te',
                  #tf: r'tf',
                  #tg: r'tg',
                  #th: r'th',
                  #ti: r'ti',
                  #tj: r'tj',
                  #tk: r'tk',
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  final field1Details = "annotations: const [smoke_1.published]";
  final field3Details = "isFinal: true, annotations: const [smoke_1.published]";
  final prop1Details = "kind: PROPERTY, annotations: const [smoke_1.published]";
  final prop3Details =
      "kind: PROPERTY, isFinal: true, annotations: const [smoke_1.published]";
  testPhases('published via annotation', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '  @published int field1;\n'
          '  int field2;\n'
          '  @published final int field3;\n'
          '  final int field4;\n'
          '  @published int get prop1 => 1;\n'
          '  set prop1(int x) {};\n'
          '  int get prop2 => 2;\n'
          '  set prop2(int x) {};\n'
          '  @published int get prop3 => 3;\n'
          '  int get prop4 => 4;\n'
          '  @published int method1() => 1;\n'
          '  int method2() => 2;\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                getters: {
                  #field1: (o) => o.field1,
                  #field3: (o) => o.field3,
                  #prop1: (o) => o.prop1,
                  #prop3: (o) => o.prop3,
                },
                setters: {
                  #field1: (o, v) { o.field1 = v; },
                  #prop1: (o, v) { o.prop1 = v; },
                },
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {
                    #field1: const Declaration(#field1, int, $field1Details),
                    #field3: const Declaration(#field3, int, $field3Details),
                    #prop1: const Declaration(#prop1, int, $prop1Details),
                    #prop3: const Declaration(#prop3, int, $prop3Details),
                  },
                },
                names: {
                  #field1: r'field1',
                  #field3: r'field3',
                  #prop1: r'prop1',
                  #prop3: r'prop3',
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testPhases('published via attributes', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '<polymer-element name="x-foo" attributes="field1,prop2">'
          '</polymer-element>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '  int field1;\n'
          '  int field2;\n'
          '  int get prop1 => 1;\n'
          '  set prop1(int x) {};\n'
          '  int get prop2 => 2;\n'
          '  set prop2(int x) {};\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                getters: {
                  #field1: (o) => o.field1,
                  #prop2: (o) => o.prop2,
                },
                setters: {
                  #field1: (o, v) { o.field1 = v; },
                  #prop2: (o, v) { o.prop2 = v; },
                },
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {
                    #field1: const Declaration(#field1, int),
                    #prop2: const Declaration(#prop2, int, kind: PROPERTY),
                  },
                },
                names: {
                  #field1: r'field1',
                  #prop2: r'prop2',
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  final fooDetails =
      "kind: METHOD, annotations: const [const smoke_1.ObserveProperty('x')]";
  final xChangedDetails = "Function, kind: METHOD";
  testPhases('ObserveProperty and *Changed methods', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '</polymer-element>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '  int x;\n'
          '  void xChanged() {}\n'
          '  void attributeChanged() {}\n' // should be excluded
          '  @ObserveProperty("x")'
          '  void foo() {}\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                getters: {
                  #foo: (o) => o.foo,
                  #xChanged: (o) => o.xChanged,
                },
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {
                    #foo: const Declaration(#foo, Function, $fooDetails),
                    #xChanged: const Declaration(#xChanged, $xChangedDetails),
                  },
                },
                names: {
                  #foo: r'foo',
                  #xChanged: r'xChanged',
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  final rcDetails = "#registerCallback, Function, kind: METHOD, isStatic: true";
  testPhases('register callback is included', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><body>'
          '</polymer-element>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
          'library a;\n'
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-foo")\n'
          'class XFoo extends PolymerElement {\n'
          '  static registerCallback() {};\n'
          '  static foo() {};\n'
          '}\n',
    }, {
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XFoo: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XFoo: {
                    #registerCallback: const Declaration($rcDetails),
                  },
                },
                staticMethods: {
                  smoke_0.XFoo: {
                    #registerCallback: smoke_0.XFoo.registerCallback,
                  },
                },
                names: {
                  #registerCallback: r'registerCallback',
                }));
            configureForDeployment([
                () => Polymer.register(\'x-foo\', i0.XFoo),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });
}

void logElementInjectionTests() {
  final outputLogsPhases = [[new ScriptCompactor(
      new TransformOptions(injectBuildLogsInOutput: true, releaseMode: false),
      sdkDir: testingDartSdkDirectory)]];

  testPhases('Injects logging element and styles', outputLogsPhases, {
      'a|web/test.html': '<!DOCTYPE html><html><head>',
      'a|web/test.html._data': expectedData(['web/a.dart']),
      'a|web/a.dart':
        'library a;\n'
        'import "package:polymer/polymer.dart";\n'
        'main(){}',
    }, {
      'a|web/test.html':
        '<!DOCTYPE html><html><head>'
        '<link rel="stylesheet" type="text/css" '
          'href="packages/polymer/src/build/log_injector.css">'
        '</head><body>'
        '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
        '</body></html>',
      'a|web/test.html_bootstrap.dart':
        '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'package:polymer/src/build/log_injector.dart';
          ${DEFAULT_IMPORTS.join('\n')}

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false));
            new LogInjector().injectLogsFromUrl('test.html._buildLogs');
            configureForDeployment([]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart':
        'library a;\n'
        'import "package:polymer/polymer.dart";\n'
        'main(){}',
    });
}
