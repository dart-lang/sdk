// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.all_phases_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/script_compactor.dart' show MAIN_HEADER;
import 'package:polymer/transformer.dart';
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = new PolymerTransformerGroup(new TransformOptions()).phases;

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
      'a|web/a.dart': _sampleObservable('A', 'foo'),
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '$INTEROP_TAG'
          '<script src="test.html_bootstrap.dart.js"></script>'
          '</head><body></body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;

          void main() {
            configureForDeployment([
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleObservableOutput('A', 'foo'),
    });

  testPhases('single inline script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">'
          '${_sampleObservable("B", "bar")}</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '$INTEROP_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js"></script>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'test.html.0.dart' as i0;

          void main() {
            configureForDeployment([
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/test.html.0.dart':
          _sampleObservableOutput("B", "bar"),
    });

  const onlyOne = 'warning: Only one "application/dart" script tag per document'
      ' is allowed.';
  const moreNotSupported =
      'warning: more than one Dart script per HTML document is not supported. '
      'Script will be ignored.';

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>'
          // TODO(sigmund): provide a way to see logging warnings and errors.
          // For example, these extra tags produce warnings and are then removed
          // by the transformers. The test below checks that the output looks
          // correct, but we should also validate the messages logged.
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
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '$INTEROP_TAG'
          '</head><body>'
          '<script src="test.html_bootstrap.dart.js"></script>'
          '<div></div>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;

          void main() {
            configureForDeployment([
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': _sampleObservableOutput('A', 'foo'),
    }, [
      // These should not be emitted multiple times. See:
      // https://code.google.com/p/dart/issues/detail?id=17197
      '$onlyOne (web/test.html 0 81)',
      '$onlyOne (web/test.html 7 27)',
      '$onlyOne (web/test.html 14 15)',
      '$moreNotSupported (web/test.html 0 81)',
      '$moreNotSupported (web/test.html 7 27)',
      '$moreNotSupported (web/test.html 14 15)'
    ]);

  testPhases('with imports', phases, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '<link rel="import" href="test2.html">'
          '</head><body>'
          '<script type="application/dart" src="b.dart"></script>',
      'a|web/b.dart': _sampleObservable('B', 'bar'),
      'a|web/test2.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<polymer-element>1'
          '<script type="application/dart">'
          '${_sampleObservable("A", "foo")}</script>'
          '</polymer-element></html>',
    }, {
      'a|web/index.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '$INTEROP_TAG'
          '</head><body><polymer-element>1</polymer-element>'
          '<script src="index.html_bootstrap.dart.js"></script>'
          '</body></html>',
      'a|web/index.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'index.html.0.dart' as i0;
          import 'b.dart' as i1;

          void main() {
            configureForDeployment([
              ]);
            i1.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/index.html.0.dart': _sampleObservableOutput("A", "foo"),
      'a|web/b.dart': _sampleObservableOutput('B', 'bar'),
    });
}

String _sampleObservable(String className, String fieldName) => '''
library ${className}_$fieldName;
import 'package:observe/observe.dart';

class $className extends Observable {
  @observable int $fieldName;
  $className(this.$fieldName);
}
''';

String _sampleObservableOutput(String className, String field,
    {bool includeMain: false}) =>
    "library ${className}_$field;\n"
    "import 'package:observe/observe.dart';\n\n"
    "class $className extends ChangeNotifier {\n"
    "  @reflectable @observable int get $field => __\$$field; "
      "int __\$$field; "
      "@reflectable set $field(int value) { "
      "__\$$field = notifyPropertyChange(#$field, __\$$field, value); "
      "}\n"
    "  $className($field) : __\$$field = $field;\n"
    "}\n";
