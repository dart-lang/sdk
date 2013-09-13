// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.code_extractor_test;

import 'package:polymer/src/build/code_extractor.dart';
import 'package:polymer/src/build/common.dart';
import 'package:unittest/compact_vm_config.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();
  var phases = [[new InlineCodeExtractor(new TransformOptions())]];

  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('single script, no library in script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">main() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="test.html.0.dart"></script>'
          '</head><body></body></html>',

      'a|web/test.html.0.dart':
          'library web_test_html_0;\nmain() { }',
    });

  testPhases('single script, with library', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library f;\nmain() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="test.html.0.dart"></script>'
          '</head><body></body></html>',

      'a|web/test.html.0.dart':
          'library f;\nmain() { }',
    });

  testPhases('under lib/ directory also transformed', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library f;\nmain() { }</script>',
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="test.html.0.dart"></script>'
          '</head><body></body></html>',

      'a|lib/test.html.0.dart':
          'library f;\nmain() { }',
    });

  testPhases('multiple scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">library a1;\nmain1() { }</script>'
          '<script type="application/dart">library a2;\nmain2() { }</script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="test.html.0.dart"></script>'
          '<script type="application/dart" src="test.html.1.dart"></script>'
          '</head><body></body></html>',

      'a|web/test.html.0.dart':
          'library a1;\nmain1() { }',

      'a|web/test.html.1.dart':
          'library a2;\nmain2() { }',
    });

  testPhases('multiple deeper scripts', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart">main1() { }</script>'
          '</head><body><div>'
          '<script type="application/dart">main2() { }</script>'
          '</div><div><div>'
          '<script type="application/dart">main3() { }</script>'
          '</div></div>'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '<script type="application/dart" src="test.html.0.dart"></script>'
          '</head><body><div>'
          '<script type="application/dart" src="test.html.1.dart"></script>'
          '</div><div><div>'
          '<script type="application/dart" src="test.html.2.dart"></script>'
          '</div></div></body></html>',

      'a|web/test.html.0.dart':
          'library web_test_html_0;\nmain1() { }',

      'a|web/test.html.1.dart':
          'library web_test_html_1;\nmain2() { }',

      'a|web/test.html.2.dart':
          'library web_test_html_2;\nmain3() { }',
    });
}
