// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.all_phases_test;

import 'package:code_transformers/tests.dart' show testingDartSdkDirectory;
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/linter.dart' show USE_POLYMER_HTML,
    USE_INIT_DART, ONLY_ONE_TAG;
import 'package:polymer/src/build/script_compactor.dart' show MAIN_HEADER;
import 'package:polymer/transformer.dart';
import 'package:smoke/codegen/generator.dart' show DEFAULT_IMPORTS;
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = createDeployPhases(new TransformOptions(),
      sdkDir: testingDartSdkDirectory);

  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {}, [
      'warning: $USE_INIT_DART'
    ]);

  testPhases('observable changes', phases, {
      'a|web/test.dart': _sampleInput('A', 'foo'),
      'a|web/test2.dart': _sampleOutput('B', 'bar'),
    }, {
      'a|web/test.dart': _sampleOutput('A', 'foo'),
      'a|web/test2.dart': _sampleOutput('B', 'bar'),
    });

  testPhases('single script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<script type="application/dart" src="a.dart"></script>',
      'a|web/a.dart': _sampleInput('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js" async=""></script>'
          '</body></html>',

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
                  smoke_0.XA: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XA: {},
                }));
            configureForDeployment([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleOutput('A', 'foo'),
    }, []);

  testPhases('single inline script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<script type="application/dart">'
          '${_sampleInput("B", "bar")}</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js" async=""></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'test.html.0.dart' as i0;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'test.html.0.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XB: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XB: {},
                }));
            configureForDeployment([
                i0.m_bar,
                () => Polymer.register('x-B', i0.XB),
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test.html.0.dart':
          _sampleOutput("B", "bar"),
    });

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">\n'
          '<script type="application/dart" src="a.dart"></script>\n'
          '<script type="application/dart">'
          '${_sampleInput("B", "bar")}</script>'
          '</head><body><div>\n'
          '<script type="application/dart">'
          '${_sampleInput("C", "car")}</script>'
          '</div>\n'
          '<script type="application/dart" src="d.dart"></script>',
      'a|web/a.dart': _sampleInput('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG\n\n'
          '</head><body>'
          '<div>\n</div>\n'
          '<script src="test.html_bootstrap.dart.js" async=""></script>'
          '</body></html>',
      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'test.html.0.dart' as i1;
          import 'test.html.1.dart' as i2;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'a.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;
          import 'test.html.0.dart' as smoke_2;
          import 'test.html.1.dart' as smoke_3;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XA: smoke_1.PolymerElement,
                  smoke_2.XB: smoke_1.PolymerElement,
                  smoke_3.XC: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XA: {},
                  smoke_2.XB: {},
                  smoke_3.XC: {},
                }));
            configureForDeployment([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
                i1.m_bar,
                () => Polymer.register('x-B', i1.XB),
                i2.m_car,
                () => Polymer.register('x-C', i2.XC),
              ]);
            i2.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleOutput('A', 'foo'),
    }, [
      // These should not be emitted multiple times. See:
      // https://code.google.com/p/dart/issues/detail?id=17197
      'warning: $ONLY_ONE_TAG (web/test.html 2 0)',
      'warning: $ONLY_ONE_TAG (web/test.html 18 0)',
      'warning: $ONLY_ONE_TAG (web/test.html 34 0)',
      'warning: Script file at "d.dart" not found. (web/test.html 34 0)',
    ]);

  testPhases('with imports', phases, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<link rel="import" href="packages/a/test2.html">'
          '</head><body>'
          '<script type="application/dart" src="b.dart"></script>',
      'a|web/b.dart': _sampleInput('B', 'bar'),
      'a|lib/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="../../packages/polymer/polymer.html">'
          '</head><body>'
          '<polymer-element name="x-a">1'
          '<script type="application/dart">'
          '${_sampleInput("A", "foo")}</script>'
          '</polymer-element></html>',
    }, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body><polymer-element name="x-a">1</polymer-element>'
          '<script src="index.html_bootstrap.dart.js" async=""></script>'
          '</body></html>',
      'a|web/index.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'index.html.0.dart' as i0;
          import 'b.dart' as i1;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'index.html.0.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;
          import 'b.dart' as smoke_2;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_2.XB: smoke_1.PolymerElement,
                  smoke_0.XA: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_2.XB: {},
                  smoke_0.XA: {},
                }));
            configureForDeployment([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
                i1.m_bar,
                () => Polymer.register('x-B', i1.XB),
              ]);
            i1.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/index.html.0.dart': _sampleOutput("A", "foo"),
      'a|web/b.dart': _sampleOutput('B', 'bar'),
    }, []);

  testPhases('experimental bootstrap', phases, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" '
          'href="packages/polymer/polymer_experimental.html">'
          '<link rel="import" href="packages/a/test2.html">'
          '<link rel="import" href="packages/a/load_b.html">',
      'a|lib/b.dart': _sampleInput('B', 'bar'),
      'a|lib/test2.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="../../packages/polymer/polymer.html">'
          '</head><body>'
          '<polymer-element name="x-a">1'
          '<script type="application/dart">'
          '${_sampleInput("A", "foo")}</script>'
          '</polymer-element></html>',
      'a|lib/load_b.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" src="b.dart"></script>',
    }, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body><polymer-element name="x-a">1</polymer-element>'
          '<script src="index.html_bootstrap.dart.js" async=""></script>'
          '</body></html>',
      'a|web/index.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'index.html.0.dart' as i0;
          import 'package:a/b.dart' as i1;
          ${DEFAULT_IMPORTS.join('\n')}
          import 'index.html.0.dart' as smoke_0;
          import 'package:polymer/polymer.dart' as smoke_1;
          import 'package:a/b.dart' as smoke_2;

          void main() {
            useGeneratedCode(new StaticConfiguration(
                checkedMode: false,
                parents: {
                  smoke_0.XA: smoke_1.PolymerElement,
                  smoke_2.XB: smoke_1.PolymerElement,
                },
                declarations: {
                  smoke_0.XA: {},
                  smoke_2.XB: {},
                }));
            startPolymer([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
                i1.m_bar,
                () => Polymer.register('x-B', i1.XB),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/index.html.0.dart': _sampleOutput("A", "foo"),
      'a|lib/b.dart': _sampleOutput('B', 'bar'),
    }, []);
}

String _sampleInput(String className, String fieldName) => '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';
import 'package:polymer/polymer.dart';

class $className extends Observable {
  @observable int $fieldName;
  $className(this.$fieldName);
}

@CustomTag('x-$className')
class X${className} extends PolymerElement {
  X${className}.created() : super.created();
}
@initMethod m_$fieldName() {}
main() {}
''';


String _sampleOutput(String className, String fieldName) {
  var fieldReplacement = '@reflectable @observable '
      'int get $fieldName => __\$$fieldName; '
      'int __\$$fieldName; '
      '@reflectable set $fieldName(int value) { '
      '__\$$fieldName = notifyPropertyChange(#$fieldName, '
      '__\$$fieldName, value); }';
  return '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';
import 'package:polymer/polymer.dart';

class $className extends ChangeNotifier {
  $fieldReplacement
  $className($fieldName) : __\$$fieldName = $fieldName;
}

@CustomTag('x-$className')
class X${className} extends PolymerElement {
  X${className}.created() : super.created();
}
@initMethod m_$fieldName() {}
main() {}
''';
}
