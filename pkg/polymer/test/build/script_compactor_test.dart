// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.script_compactor_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/script_compactor.dart';
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = [[new ScriptCompactor(new TransformOptions())]];

  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html.scriptUrls': '[]',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('no changes outside web/', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>',
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>',
    });

  testPhases('single script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="a.dart"></script>',
      'a|web/test.html.scriptUrls': '[]',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" '
          'src="test.html_bootstrap.dart"></script>'
          '</head><body></body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;

          void main() {
            configureForDeployment([
                'a.dart',
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><div>'
          '<script type="application/dart" src="d.dart"></script>'
          '</div>',
      'a|web/test.html.scriptUrls':
          '[["a", "web/a.dart"],["a", "web/b.dart"],["a", "web/c.dart"]]',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body><div>'
          '<script type="application/dart" src="test.html_bootstrap.dart">'
          '</script>'
          '</div>'
          '</body></html>',

      'a|web/test.html_bootstrap.dart':
          '''$MAIN_HEADER
          import 'a.dart' as i0;
          import 'b.dart' as i1;
          import 'c.dart' as i2;
          import 'd.dart' as i3;

          void main() {
            configureForDeployment([
                'a.dart',
                'b.dart',
                'c.dart',
                'd.dart',
              ]);
            i3.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });
}
