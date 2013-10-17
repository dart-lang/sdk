// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.all_phases_test;

import 'package:polymer/transformer.dart';
import 'package:polymer/src/build/script_compactor.dart' show MAIN_HEADER;
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = createDeployPhases(new TransformOptions());

  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('observable changes', phases, {
      'a|web/test.dart': _sampleObservable('A', 'foo'),
      'a|web/test2.dart': _sampleObservableOutput('B', 'bar'),
    }, {
      'a|web/test.dart': _sampleObservableOutput('A', 'foo'),
      'a|web/test2.dart': _sampleObservableOutput('B', 'bar'),
    });

  testPhases('single script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>',
      'a|web/test.dart': _sampleObservable('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '$SHADOW_DOM_TAG'
          '$CUSTOM_ELEMENT_TAG'
          '$INTEROP_TAG'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '<script src="packages/browser/dart.js"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;

          void main() {
            initPolymer([
                'a.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test.dart': _sampleObservableOutput('A', 'foo'),
    });

  testPhases('single inline script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">'
          '${_sampleObservable("B", "bar")}</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '$SHADOW_DOM_TAG'
          '$CUSTOM_ELEMENT_TAG'
          '$INTEROP_TAG'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '<script src="packages/browser/dart.js"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'test.html.0.dart' as i0;

          void main() {
            initPolymer([
                'test.html.0.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test.html.0.dart': _sampleObservableOutput("B", "bar"),
    });

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>'
          '<script type="application/dart">'
          '${_sampleObservable("B", "bar")}</script>'
          '</head><body><div>'
          '<script type="application/dart">'
          '${_sampleObservable("C", "car")}</script>'
          '</div>'
          '<script type="application/dart" src="d.dart"></script>',
      'a|web/a.dart': _sampleObservable('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '$SHADOW_DOM_TAG'
          '$CUSTOM_ELEMENT_TAG'
          '$INTEROP_TAG'
          '<div></div>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '<script src="packages/browser/dart.js"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'test.html.0.dart' as i1;
          import 'test.html.1.dart' as i2;
          import 'd.dart' as i3;

          void main() {
            initPolymer([
                'a.dart',
                'test.html.0.dart',
                'test.html.1.dart',
                'd.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleObservableOutput('A', 'foo'),
      'a|web/test.html.0.dart': _sampleObservableOutput("B", "bar"),
      'a|web/test.html.1.dart': _sampleObservableOutput("C", "car"),
    });

  testPhases('with imports', phases, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head><body>'
          '<script type="application/dart" src="b.dart"></script>'
          '<script type="application/dart">'
          '${_sampleObservable("C", "car")}</script>',
      'a|web/b.dart': _sampleObservable('B', 'bar'),
      'a|web/test2.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<polymer-element>1'
          '<script type="application/dart">'
          '${_sampleObservable("A", "foo")}</script>'
          '</polymer-element></html>',
    }, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head></head><body>'
          '$SHADOW_DOM_TAG'
          '$CUSTOM_ELEMENT_TAG'
          '$INTEROP_TAG'
          '<polymer-element>1</polymer-element>'
          '<script type="application/dart" '
          'src="index.html_bootstrap.dart"></script>'
          '<script src="packages/browser/dart.js"></script>'
          '</body></html>',
      'a|web/index.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'test2.html.0.dart' as i0;
          import 'b.dart' as i1;
          import 'index.html.0.dart' as i2;

          void main() {
            initPolymer([
                'test2.html.0.dart',
                'b.dart',
                'index.html.0.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test2.html.0.dart': _sampleObservableOutput("A", "foo"),
      'a|web/b.dart': _sampleObservableOutput('B', 'bar'),
      'a|web/index.html.0.dart': _sampleObservableOutput("C", "car"),
    });
}

String _sampleObservable(String className, String fieldName) => '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';

class $className extends ObservableBase {
  @observable int $fieldName;
  $className(this.$fieldName);
}
''';

String _sampleObservableOutput(String className, String field) =>
    "library ${className}_$field;\n"
    "import 'package:observe/observe.dart';\n\n"
    "class $className extends ChangeNotifierBase {\n"
    "  @reflectable @observable int get $field => __\$$field; "
      "int __\$$field; "
      "@reflectable set $field(int value) { "
      "__\$$field = notifyPropertyChange(#$field, __\$$field, value); "
      "}\n"
    "  $className($field) : __\$$field = $field;\n"
    "}\n";
