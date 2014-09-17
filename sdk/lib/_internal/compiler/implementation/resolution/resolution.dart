// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution;

import 'dart:collection' show Queue;

import '../dart2jslib.dart';
import '../dart_types.dart';
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
import '../util/util.dart';

import 'secret_tree_element.dart' show getTreeElement, setTreeElement;
import '../ordered_typeset.dart' show OrderedTypeSet, OrderedTypeSetBuilder;
import 'class_members.dart' show MembersCreator;
import '../dart_backend/dart_backend.dart' show DartBackend;

part 'members.dart';
part 'registry.dart';
part 'scope.dart';
part 'signatures.dart';
