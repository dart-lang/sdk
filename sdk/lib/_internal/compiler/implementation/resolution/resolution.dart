// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution;

import 'dart:collection' show Queue;

import '../dart2jslib.dart' hide Diagnostic;
import '../dart_types.dart';
import '../../compiler.dart' show Diagnostic;
import '../tree/tree.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show BaseClassElementX,
         FunctionElementX,
         ErroneousElementX,
         VariableElementX,
         FieldParameterElementX,
         VariableListElementX,
         FunctionSignatureX,
         LabelElementX,
         TargetElementX,
         MixinApplicationElementX,
         TypeVariableElementX,
         TypedefElementX,
         SynthesizedConstructorElementX;
import '../util/util.dart';
import '../scanner/scannerlib.dart' show PartialMetadataAnnotation;

import 'secret_tree_element.dart' show getTreeElement, setTreeElement;
import '../ordered_typeset.dart' show OrderedTypeSet, OrderedTypeSetBuilder;

part 'members.dart';
part 'scope.dart';
