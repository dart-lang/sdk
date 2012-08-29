// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides client-side behavior for generated docs using the static mode. */
#library('client-static');

#import('dart:html');
#import('../../lib/compiler/implementation/source_file.dart');
#import('dart:json');
#import('classify.dart');

#source('dropdown.dart');
#source('search.dart');
#source('nav.dart');
#source('client-shared.dart');
#source('tmp/nav.dart');

main() {
  setupLocation();

  enableCodeBlocks();

  setupSearch(json);
}
