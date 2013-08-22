// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.transform.script_compactor_test;

import 'package:polymer/src/transform/script_compactor.dart';
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();

  testPhases('no changes', [[new ScriptCompactor()]], {
      'a|test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('single script', [[new ScriptCompactor()]], {
      'a|test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>',
    }, {
      'a|test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '</body></html>',

      'a|test.html_bootstrap.dart':
          '''library app_bootstrap;

          import 'package:polymer/polymer.dart';
          import 'dart:mirrors' show currentMirrorSystem;

          import 'a.dart' as i0;

          void main() {
            initPolymer([
                'a.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testPhases('several scripts', [[new ScriptCompactor()]], {
      'a|test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>'
          '<script type="application/dart" src="b.dart"></script>'
          '</head><body><div>'
          '<script type="application/dart" src="c.dart"></script>'
          '</div>'
          '<script type="application/dart" src="d.dart"></script>',
    }, {
      'a|test.html':
          '<!DOCTYPE html><html><head></head><body><div></div>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '</body></html>',

      'a|test.html_bootstrap.dart':
          '''library app_bootstrap;

          import 'package:polymer/polymer.dart';
          import 'dart:mirrors' show currentMirrorSystem;

          import 'a.dart' as i0;
          import 'b.dart' as i1;
          import 'c.dart' as i2;
          import 'd.dart' as i3;

          void main() {
            initPolymer([
                'a.dart',
                'b.dart',
                'c.dart',
                'd.dart',
              ], currentMirrorSystem().isolate.rootLibrary.uri.toString());
          }
          '''.replaceAll('\n          ', '\n'),
    });
}
