// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree;

import 'dart:collection';

import '../scanner/scannerlib.dart';
import '../util/util.dart';
import '../util/characters.dart';

import '../resolution/secret_tree_element.dart'
    show StoredTreeElementMixin, NullTreeElementMixin;

import '../elements/elements.dart' show MetadataAnnotation;

part 'dartstring.dart';
part 'nodes.dart';
part 'prettyprint.dart';
part 'unparser.dart';
part 'visitors.dart';
