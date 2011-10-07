// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Version of unittest library that uses the html library versions of 'window'
// and 'document'.

// TODO: When it is possible to use both dom and html in the same program
// (i.e. using namespaces to distinguish the two global window() getters),
// remove one of the versions.

#library("unittest");

#import("dart:html");

#source("unittestsuite.dart");
