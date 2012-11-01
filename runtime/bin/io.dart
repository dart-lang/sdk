// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We should be able to get rid of this file. This is used to set up
// the dart:io library for the VM because it cannot use the actual library
// file which is in lib/io/io.dart.

#library("dart:io");
#import("dart:coreimpl");
#import("dart:crypto");
#import("dart:isolate");
#import("dart:math");
#import("dart:nativewrappers");
#import("dart:scalarlist");
#import("dart:uri");
#import("dart:utf");
