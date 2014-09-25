// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library polymer.test.build.index_page_builder_test;

import 'dart:async';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';
import 'package:polymer/src/build/common.dart';
import 'package:polymer/src/build/index_page_builder.dart';

import 'common.dart';

final phases = [[new IndexPageBuilder(new TransformOptions())]];

void main() {
  useCompactVMConfiguration();

  testPhases('outputs index pages', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test2.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/test3.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/test4.html': '<!DOCTYPE html><html></html>',
      'a|web/foobar/test5.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test.html">test.html</a></li>'
          '<li><a href="test2.html">test2.html</a></li>'
          '<li><a href="foo/test3.html">foo/test3.html</a></li>'
          '<li><a href="foo/bar/test4.html">foo/bar/test4.html</a></li>'
          '<li><a href="foobar/test5.html">foobar/test5.html</a></li>'
          '</ul></body></html>',
      'a|web/foo/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test3.html">test3.html</a></li>'
          '<li><a href="bar/test4.html">bar/test4.html</a></li>'
          '</ul></body></html>',
      'a|web/foo/bar/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test4.html">test4.html</a></li>'
          '</ul></body></html>',
      'a|web/foobar/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test5.html">test5.html</a></li>'
          '</ul></body></html>',
    });

  testPhases('doesn\'t overwrite existing pages', phases, {
      'a|web/index.html': '<!DOCTYPE html><html></html>',
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/test.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/test.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/index.html': '<!DOCTYPE html><html></html>',
    });

  testPhases('can output pages while not overwriting existing ones', phases, {
      'a|web/test.html': '<!DOCTYPE html><html></html>',
      'a|web/test2.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/test3.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/test4.html': '<!DOCTYPE html><html></html>',
      'a|web/foobar/test5.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test.html">test.html</a></li>'
          '<li><a href="test2.html">test2.html</a></li>'
          '<li><a href="foo/index.html">foo/index.html</a></li>'
          '<li><a href="foo/test3.html">foo/test3.html</a></li>'
          '<li><a href="foo/bar/index.html">foo/bar/index.html</a></li>'
          '<li><a href="foo/bar/test4.html">foo/bar/test4.html</a></li>'
          '<li><a href="foobar/test5.html">foobar/test5.html</a></li>'
          '</ul></body></html>',
      'a|web/foo/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foo/bar/index.html': '<!DOCTYPE html><html></html>',
      'a|web/foobar/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test5.html">test5.html</a></li>'
          '</ul></body></html>',
    });

  final entryPointPhases = [[new IndexPageBuilder(
      new TransformOptions(entryPoints: [
          'web/test1.html', 'test/test2.html', 'example/test3.html']))]];
  
  testPhases('can output files for any entry points', entryPointPhases, {
      'a|web/test1.html': '<!DOCTYPE html><html></html>',
      'a|test/test2.html': '<!DOCTYPE html><html></html>',
      'a|example/test3.html': '<!DOCTYPE html><html></html>',
    }, {
      'a|web/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test1.html">test1.html</a></li>'
          '</ul></body></html>',
      'a|test/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test2.html">test2.html</a></li>'
          '</ul></body></html>',
      'a|example/index.html': '<!DOCTYPE html><html><body>'
          '<h1>Entry points</h1><ul>'
          '<li><a href="test3.html">test3.html</a></li>'
          '</ul></body></html>',
    });
}

