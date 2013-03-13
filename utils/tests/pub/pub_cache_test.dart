// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_cache_test;

import 'dart:io';
import 'dart:json' as json;
import 'test_pub.dart';
import '../../pub/io.dart';

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
    dir(cachePath, [
      dir('hosted', [
         dir('pub.dartlang.org', [
        ])
      ])
    ]).scheduleCreate();
    
    schedulePub(args: ['cache', 'list'], output: '{"packages":{}}');
  });
  
  integration('running pub cache list', () {
    // Set up a cache.
    dir(cachePath, [
      dir('hosted', [
         dir('pub.dartlang.org', [
          dir("foo-1.2.3", [
            libPubspec("foo", "1.2.3"),
            libDir("foo")
          ]),
          dir("bar-2.0.0", [
            libPubspec("bar", "2.0.0"),
            libDir("bar") ])
        ])
      ])
    ]).scheduleCreate();
    
    schedulePub(args: ['cache', 'list'], output: 
      new RegExp(r'\{"packages":\{"bar":\{"version":"2\.0\.0","location":"[^"]+bar-2\.0\.0"\},"foo":\{"version":"1\.2\.3","location":"[^"]+foo-1\.2\.3"\}\}\}$'));
  });
  
}