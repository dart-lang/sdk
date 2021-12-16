// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the objects used for communication between the macro executor and
/// the isolate doing the work of macro loading and execution.
library protocol;

import '../executor.dart';
import '../api.dart';

/// Base class all requests extend, provides a unique id for each request.
class Request {
  final int id;

  Request() : id = _next++;

  static int _next = 0;
}

/// A generic response object that is either an instance of [T] or an error.
class GenericResponse<T> {
  final T? response;
  final Object? error;
  final int requestId;

  GenericResponse({this.response, this.error, required this.requestId})
      : assert(response != null || error != null),
        assert(response == null || error == null);
}

/// A request to load a macro in this isolate.
class LoadMacroRequest extends Request {
  final Uri library;
  final String name;

  LoadMacroRequest(this.library, this.name);
}

/// A request to instantiate a macro instance.
class InstantiateMacroRequest extends Request {
  final MacroClassIdentifier macroClass;
  final String constructorName;
  final Arguments arguments;

  InstantiateMacroRequest(
      this.macroClass, this.constructorName, this.arguments);
}

/// A request to execute a macro on a particular declaration in the definition
/// phase.
class ExecuteDefinitionsPhaseRequest extends Request {
  final MacroInstanceIdentifier macro;
  final Declaration declaration;
  final TypeResolver typeResolver;
  final ClassIntrospector classIntrospector;
  final TypeDeclarationResolver typeDeclarationResolver;

  ExecuteDefinitionsPhaseRequest(this.macro, this.declaration,
      this.typeResolver, this.classIntrospector, this.typeDeclarationResolver);
}
