// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.9

// This is a work-around for the automagically selecting weak/strong mode.
// By marking this file (the entry) as non-nnbd, it becomes weak mode which
// is required because many of the imports are not (yet) nnbd.

export 'unit_test_suites_impl.dart';
