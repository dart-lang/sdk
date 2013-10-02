// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter;

import 'dart:collection' show LinkedHashMap, Queue;

import '../js/js.dart' as jsAst;

import '../closure.dart' show ClosureClassMap, ClosureFieldElement, ClosureClassElement;
import '../dart2jslib.dart' show CompilerTask, CodeBuffer, ConstantHandler, Compiler, Constant, TypeConstant, InterceptorConstant, SourceString, Selector, TreeElements, invariant, MessageKind, NullConstant;
import '../dart_types.dart' show DartType, TypeVariableType, InterfaceType, FunctionType, Types;
import '../elements/elements.dart' show ClassElement, ClosureFieldElement, Element, FunctionElement, LibraryElement, MixinApplicationElement, TypedefElement, VariableElement, FunctionSignature, MetadataAnnotation, Elements;
import '../elements/modelx.dart' show FunctionElementX;
import '../js/js.dart' show js;
import '../js_backend/js_backend.dart' show ConstantEmitter, NativeEmitter, CheckedModeHelper, JavaScriptBackend, CheckedModeHelper, JavaScriptBackend, Namer, TypeChecks, RuntimeTypes, Substitution, TypeCheck;
import '../source_file.dart' show SourceFile;
import '../source_map_builder.dart' show SourceMapBuilder;
import '../tree/tree.dart' show Node;
import '../types/types.dart' show TypeMask;
import '../universe/universe.dart' show SelectorKind;
import '../util/characters.dart' show $$, $A, $HASH, $PERIOD, $Z, $a, $z;
import '../util/uri_extras.dart' show relativize;
import '../util/util.dart' show Link, SpannableAssertionFailure;

part 'emitter.dart';
