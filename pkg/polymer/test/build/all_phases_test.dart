// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.all_phases_test;

import 'package:code_transformers/tests.dart' show testingDartSdkDirectory;
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/import_inliner.dart' show COMPONENT_WARNING;
import 'package:polymer/src/build/linter.dart' show USE_POLYMER_HTML;
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
      'warning: $USE_POLYMER_HTML'
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
          '<script type="application/dart;component=1" src="a.dart"></script>',
      'a|web/a.dart': _sampleInput('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js"></script>'
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
                  smoke_0.XA: const {},
                }));
            startPolymer([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleOutput('A', 'foo'),
    });

  testPhases('single inline script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<script type="application/dart;component=1">'
          '${_sampleInput("B", "bar")}</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js"></script>'
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
                  smoke_0.XB: const {},
                }));
            startPolymer([
                i0.m_bar,
                () => Polymer.register('x-B', i0.XB),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test.html.0.dart':
          _sampleOutput("B", "bar"),
    });

  testPhases('several application scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<script type="application/dart;component=1" src="a.dart"></script>'
          '<script type="application/dart">'
          '${_sampleInput("B", "bar")}</script>'
          '</head><body><div>'
          '<script type="application/dart">'
          '${_sampleInput("C", "car")}</script>'
          '</div>'
          '<script type="application/dart" src="d.dart"></script>',
      'a|web/a.dart': _sampleInput('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script src="test.html.0.dart.js"></script>'
          '<div>'                   
          '<script src="test.html.1.dart.js"></script>'
          '</div>'
          '<script src="d.dart.js"></script>'
          '<script src="test.html_bootstrap.dart.js"></script>'
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
                  smoke_0.XA: const {},
                }));
            startPolymer([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleOutput('A', 'foo'),
    }, [
      // These should not be emitted multiple times. See:
      // https://code.google.com/p/dart/issues/detail?id=17197
      'warning: $COMPONENT_WARNING (web/test.html 14 27)',
      'warning: $COMPONENT_WARNING (web/test.html 28 15)'
    ]);

  testPhases('several component scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<script type="application/dart;component=1" src="a.dart"></script>'
          '<script type="application/dart;component=1">'
          '${_sampleInput("B", "bar")}</script>'
          '</head><body><div>'
          '<script type="application/dart;component=1">'
          '${_sampleInput("C", "car")}</script>'
          '</div>',
      'a|web/a.dart': _sampleInput('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<div></div>'
          '<script src="test.html_bootstrap.dart.js"></script>'
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
                  smoke_0.XA: const {},
                  smoke_2.XB: const {},
                  smoke_3.XC: const {},
                }));
            startPolymer([
                i0.m_foo,
                () => Polymer.register('x-A', i0.XA),
                i1.m_bar,
                () => Polymer.register('x-B', i1.XB),
                i2.m_car,
                () => Polymer.register('x-C', i2.XC),
              ]);
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleOutput('A', 'foo'),
    }, []);

  testPhases('with imports', phases, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="packages/polymer/polymer.html">'
          '<link rel="import" href="test2.html">'
          '</head><body>'
          '<script type="application/dart;component=1" src="b.dart"></script>',
      'a|web/b.dart': _sampleInput('B', 'bar'),
      'a|web/test2.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<polymer-element name="x-a">1'
          '<script type="application/dart;component=1">'
          '${_sampleInput("A", "foo")}</script>'
          '</polymer-element></html>',
    }, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body><polymer-element name="x-a">1</polymer-element>'
          '<script src="index.html_bootstrap.dart.js"></script>'
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
                  smoke_2.XB: const {},
                  smoke_0.XA: const {},
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
      'a|web/b.dart': _sampleOutput('B', 'bar'),
    });
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
''';
}
