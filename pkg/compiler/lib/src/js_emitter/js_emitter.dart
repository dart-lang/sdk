// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import 'package:js_ast/src/precedence.dart' as js_precedence;
import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;
import 'package:js_runtime/shared/embedded_names.dart' show JsBuiltin;


import '../common.dart';
import '../common/names.dart' show
    Identifiers;
import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../constants/values.dart';
import '../closure.dart' show
    ClosureClassElement,
    ClosureClassMap,
    ClosureFieldElement,
    CapturedVariable;
import '../dart_types.dart' show
    DartType,
    FunctionType,
    InterfaceType,
    TypedefType,
    Types,
    TypeVariableType;
import '../deferred_load.dart' show
    OutputUnit;
import '../elements/elements.dart' show
    ClassElement,
    ConstructorBodyElement,
    Element,
    Elements,
    ElementKind,
    FieldElement,
    FunctionElement,
    FunctionSignature,
    MetadataAnnotation,
    MethodElement,
    MemberElement,
    MixinApplicationElement,
    ParameterElement,
    TypeVariableElement;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/backend_helpers.dart' show
    BackendHelpers;
import '../js_backend/js_backend.dart' show
    CheckedModeHelper,
    CompoundName,
    ConstantEmitter,
    CustomElementsAnalysis,
    GetterName,
    JavaScriptBackend,
    JavaScriptConstantCompiler,
    Namer,
    RuntimeTypes,
    RuntimeTypesEncoder,
    SetterName,
    Substitution,
    TypeCheck,
    TypeChecks,
    TypeVariableHandler;
import '../native/native.dart' as native;
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;
import '../universe/universe.dart' show
    SelectorConstraints;
import '../util/util.dart' show
    Setlet;


import 'full_emitter/emitter.dart' as full_js_emitter;
import 'lazy_emitter/emitter.dart' as lazy_js_emitter;
import 'model.dart';
import 'program_builder/program_builder.dart';
import 'startup_emitter/emitter.dart' as startup_js_emitter;

part 'class_stub_generator.dart';
part 'code_emitter_task.dart';
part 'helpers.dart';
part 'interceptor_stub_generator.dart';
part 'main_call_stub_generator.dart';
part 'metadata_collector.dart';
part 'native_emitter.dart';
part 'native_generator.dart';
part 'parameter_stub_generator.dart';
part 'runtime_type_generator.dart';
part 'type_test_registry.dart';
