// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library resolution;

import 'dart:collection' show Queue;

import '../compile_time_constants.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../core_types.dart';
import '../dart_backend/dart_backend.dart' show DartBackend;
import '../dart_types.dart';
import '../dart2jslib.dart' hide DynamicAccess;
import '../tree/tree.dart';
import '../scanner/scannerlib.dart';
import '../elements/elements.dart';

import '../elements/modelx.dart' show
    BaseClassElementX,
    BaseFunctionElementX,
    ConstructorElementX,
    ErroneousConstructorElementX,
    ErroneousElementX,
    ErroneousFieldElementX,
    ErroneousInitializingFormalElementX,
    FieldElementX,
    FormalElementX,
    FunctionElementX,
    FunctionSignatureX,
    GetterElementX,
    InitializingFormalElementX,
    JumpTargetX,
    LabelDefinitionX,
    LocalFunctionElementX,
    LocalParameterElementX,
    LocalVariableElementX,
    MetadataAnnotationX,
    MethodElementX,
    MixinApplicationElementX,
    ParameterElementX,
    ParameterMetadataAnnotation,
    SetterElementX,
    SynthesizedConstructorElementX,
    TypeVariableElementX,
    TypedefElementX,
    VariableElementX,
    VariableList;

import '../ordered_typeset.dart' show OrderedTypeSet, OrderedTypeSetBuilder;
import '../types/types.dart' show TypeMask;
import '../util/util.dart';
import '../universe/universe.dart' show
    CallStructure,
    SelectorKind,
    UniverseSelector;

import 'access_semantics.dart';
import 'class_members.dart' show MembersCreator;
import 'enum_creator.dart';
import 'operators.dart';
import 'secret_tree_element.dart' show getTreeElement, setTreeElement;
import 'send_structure.dart';

part 'class_hierarchy.dart';
part 'constructors.dart';
part 'label_scope.dart';
part 'members.dart';
part 'registry.dart';
part 'resolution_common.dart';
part 'resolution_result.dart';
part 'scope.dart';
part 'signatures.dart';
part 'tree_elements.dart';
part 'typedefs.dart';
part 'type_resolver.dart';
part 'variables.dart';
