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
      'a|web/a.dart': 'library a;\nmain(){}',
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
              ]);
            i0.main();
          }
          '''.replaceAll('\n          ', '\n'),
      'a|web/a.dart': 'library a;\nmain(){}',
    });

  testPhases('several scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '</head><body><div>'
          '<script type="application/dart" src="d.dart"></script>'
          '</div>',
      'a|web/test.html.scriptUrls':
          '[["a", "web/a.dart"],["a", "web/b.dart"],["a", "web/c.dart"]]',
      'a|web/d.dart': 'library d;\nmain(){}\n@initMethod mD(){}',

      'a|web/a.dart':
          'import "package:polymer/polymer.dart";\n'
          '@initMethod mA(){}\n',

      'a|web/b.dart':
          'export "e.dart";\n'
          'export "f.dart" show XF1, mF1;\n'
          'export "g.dart" hide XG1, mG1;\n'
          'export "h.dart" show XH1, mH1 hide mH1, mH2;\n'
          '@initMethod mB(){}\n',

      'a|web/c.dart':
          'import "package:polymer/polymer.dart";\n'
          'part "c_part.dart"\n'
          '@CustomTag("x-c2") class XC2 {}\n',

      'a|web/c_part.dart':
          '@CustomTag("x-c1") class XC1 {}\n',

      'a|web/e.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-e") class XE {}\n'
          '@initMethod mE(){}\n',

      'a|web/f.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-f1") class XF1 {}\n'
          '@initMethod mF1(){}\n'
          '@CustomTag("x-f2") class XF2 {}\n'
          '@initMethod mF2(){}\n',

      'a|web/g.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-g1") class XG1 {}\n'
          '@initMethod mG1(){}\n'
          '@CustomTag("x-g2") class XG2 {}\n'
          '@initMethod mG2(){}\n',

      'a|web/h.dart':
          'import "package:polymer/polymer.dart";\n'
          '@CustomTag("x-h1") class XH1 {}\n'
          '@initMethod mH1(){}\n'
          '@CustomTag("x-h2") class XH2 {}\n'
          '@initMethod mH2(){}\n',
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
                i0.mA,
                () => Polymer.register('x-e', i1.XE),
                i1.mE,
                () => Polymer.register('x-f1', i1.XF1),
                i1.mF1,
                () => Polymer.register('x-g2', i1.XG2),
                i1.mG2,
                () => Polymer.register('x-h1', i1.XH1),
                i1.mB,
                () => Polymer.register('x-c1', i2.XC1),
                () => Polymer.register('x-c2', i2.XC2),
                i3.mD,
              ]);
            i3.main();
          }
          '''.replaceAll('\n          ', '\n'),
    });
}
