// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.build.polyfill_injector_test;

import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/polyfill_injector.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'common.dart';

void main() {
  useCompactVMConfiguration();

  group('js', () => runTests());
  group('dart', () => runTests(js: false));
}

void runTests({bool js: true}) {
  var phases = [[new PolyfillInjector(new TransformOptions(
      directlyIncludeJS: js))]];

  var ext = js ? '.js' : '';
  var type = js ? '' : 'type="application/dart" ';
  var dartJsTag = js ? '' : DART_JS_TAG;
  var async = js ? ' async=""' : '';

  testPhases('no changes', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('no changes under lib ', phases, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" src="a.dart"></script>',
    }, {
      'a|lib/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" src="a.dart"></script>',
    });

  testPhases('with some script', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" src="a.dart"></script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script ${type}src="a.dart$ext"$async></script>'
          '$dartJsTag'
          '</body></html>',
    });

  testPhases('interop/shadow dom already present', phases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script type="application/dart" src="a.dart"></script>'
          '$dartJsTag'
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$WEB_COMPONENTS_TAG'
          '</head><body>'
          '<script ${type}src="a.dart$ext"$async></script>'
          '$dartJsTag'
          '</body></html>',
    });

  var noPlatformPhases = [[new PolyfillInjector(new TransformOptions(
        directlyIncludeJS: js, injectPlatformJs: false))]];

  testPhases('with no platform.js', noPlatformPhases, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head></head><body>'
          '<script type="application/dart" src="a.dart"></script>',
    }, {
      'a|web/test.html':
          '<!DOCTYPE html><html><head>'
          '$DART_SUPPORT_TAG'
          '</head><body>'
          '<script ${type}src="a.dart$ext"$async></script>'
          '$dartJsTag'
          '</body></html>',
    });
}
