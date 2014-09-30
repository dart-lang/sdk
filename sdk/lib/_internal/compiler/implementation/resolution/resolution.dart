// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution;

import 'dart:collection' show Queue;

import '../constants/expressions.dart';
import '../constants/values.dart';
import '../dart_backend/dart_backend.dart' show DartBackend;
import '../dart_types.dart';
import '../dart2jslib.dart';
import '../tree/tree.dart';
import '../elements/elements.dart';
import '../elements/modelx.dart'
    show BaseClassElementX,
         ConstructorElementX,
         ErroneousElementX,
         FieldElementX,
         FormalElementX,
         FunctionElementX,
         FunctionSignatureX,
         InitializingFormalElementX,
         LabelDefinitionX,
         LocalFunctionElementX,
         LocalParameterElementX,
         LocalVariableElementX,
         MetadataAnnotationX,
         MixinApplicationElementX,
         ParameterElementX,
         ParameterMetadataAnnotation,
         SynthesizedConstructorElementX,
         JumpTargetX,
         TypedefElementX,
         TypeVariableElementX,
         VariableElementX,
         VariableList;
import '../ordered_typeset.dart' show OrderedTypeSet, OrderedTypeSetBuilder;
import '../util/util.dart';

import 'class_members.dart' show MembersCreator;
import 'secret_tree_element.dart' show getTreeElement, setTreeElement;

part 'members.dart';
part 'registry.dart';
part 'scope.dart';
part 'signatures.dart';
