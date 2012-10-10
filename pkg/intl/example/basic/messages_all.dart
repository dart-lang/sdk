// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * In order to avoid needing to import the libraries for each locale
 * individually in each program file, we make a separate library that imports
 * all of them. In this example there's only one program file, so it doesn't
 * make very much difference.
 */
#library('messages_all.dart');

#import('messages_th_th.dart', prefix: 'th_TH');
#import('messages_de.dart', prefix: 'de');
