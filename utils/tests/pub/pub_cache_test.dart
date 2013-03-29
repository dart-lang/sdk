// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_cache_test;

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';

import '../../pub/io.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

main() {
  initConfig();
  
  integration('running pub cache displays error message', () {
    schedulePub(args: ['cache'], 
        output: '''
          Inspect the system cache.

          Usage: pub cache list
          ''',
        error: 'The cache command expects one argument.',
        exitCode: 64);
  });
  
  integration('running pub cache foo displays error message', () {
    schedulePub(args: ['cache' ,'foo'], 
        output: '''
          Inspect the system cache.

          Usage: pub cache list
          ''',
        error: 'Unknown cache command "foo".',
        exitCode: 64);
  });
  
  integration('running pub cache list when there is no cache', () {      
    schedulePub(args: ['cache', 'list'], output: '{"packages":{}}');
  });
  
  integration('running pub cache list on empty cache', () {      
    // Set up a cache.
    d.dir(cachePath, [
      d.dir('hosted', [
         d.dir('pub.dartlang.org', [
        ])
      ])
    ]).create();
    
    schedulePub(args: ['cache', 'list'], output: '{"packages":{}}');
  });
  
  integration('running pub cache list', () {
    // Set up a cache.
    d.dir(cachePath, [
      d.dir('hosted', [
         d.dir('pub.dartlang.org', [
          d.dir("foo-1.2.3", [
            d.libPubspec("foo", "1.2.3"),
            d.libDir("foo")
          ]),
          d.dir("bar-2.0.0", [
            d.libPubspec("bar", "2.0.0"),
            d.libDir("bar") ])
        ])
      ])
    ]).create();
    
    schedulePub(args: ['cache', 'list'], output: 
      new RegExp(r'\{"packages":\{"bar":\{"version":"2\.0\.0","location":'
          r'"[^"]+bar-2\.0\.0"\},"foo":\{"version":"1\.2\.3","location":'
          r'"[^"]+foo-1\.2\.3"\}\}\}$'));
  });
  
}