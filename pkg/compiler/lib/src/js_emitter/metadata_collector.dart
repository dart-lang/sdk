// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class MetadataCollector {
  final Compiler _compiler;
  final Emitter _emitter;

  /// A list of JS expressions that represent metadata, parameter names and
  /// type variable types.
  final List<jsAst.Expression> globalMetadata = <jsAst.Expression>[];

  /// A map used to canonicalize the entries of globalMetadata.
  final Map<String, int> _globalMetadataMap = <String, int>{};

  /// A map with lists of JS expressions, one list for each output unit. The
  /// entries represent types including function types and typedefs.
  final Map<OutputUnit, List<jsAst.Expression>> types =
      <OutputUnit, List<jsAst.Expression>>{};

  /// A map used to canonicalize the entries of types.
  final Map<OutputUnit, Map<String, int>> _typesMap =
      <OutputUnit, Map<String, int>>{};

  MetadataCollector(this._compiler, this._emitter);

  JavaScriptBackend get _backend => _compiler.backend;
  TypeVariableHandler get _typeVariableHandler => _backend.typeVariableHandler;

  bool _mustEmitMetadataFor(Element element) {
    return _backend.mustRetainMetadata &&
        _backend.referencedFromMirrorSystem(element);
  }

  /// The metadata function returns the metadata associated with
  /// [element] in generated code.  The metadata needs to be wrapped
  /// in a function as it refers to constants that may not have been
  /// constructed yet.  For example, a class is allowed to be
  /// annotated with itself.  The metadata function is used by
  /// mirrors_patch to implement DeclarationMirror.metadata.
  jsAst.Fun buildMetadataFunction(Element element) {
    if (!_mustEmitMetadataFor(element)) return null;
    return _compiler.withCurrentElement(element, () {
      List<jsAst.Expression> metadata = <jsAst.Expression>[];
      Link link = element.metadata;
      // TODO(ahe): Why is metadata sometimes null?
      if (link != null) {
        for (; !link.isEmpty; link = link.tail) {
          MetadataAnnotation annotation = link.head;
          ConstantValue constant =
              _backend.constants.getConstantValueForMetadata(annotation);
          if (constant == null) {
            _compiler.internalError(annotation, 'Annotation value is null.');
          } else {
            metadata.add(_emitter.constantReference(constant));
          }
        }
      }
      if (metadata.isEmpty) return null;
      return js('function() { return # }',
          new jsAst.ArrayInitializer(metadata));
    });
  }

  List<int> reifyDefaultArguments(FunctionElement function) {
    FunctionSignature signature = function.functionSignature;
    if (signature.optionalParameterCount == 0) return const [];
    List<int> defaultValues = <int>[];
    for (ParameterElement element in signature.optionalParameters) {
      ConstantValue constant =
          _backend.constants.getConstantValueForVariable(element);
      jsAst.Expression expression = (constant == null)
          ? null
          : _emitter.constantReference(constant);
      defaultValues.add(addGlobalMetadata(expression));
    }
    return defaultValues;
  }

  int reifyMetadata(MetadataAnnotation annotation) {
    ConstantValue constant =
        _backend.constants.getConstantValueForMetadata(annotation);
    if (constant == null) {
      _compiler.internalError(annotation, 'Annotation value is null.');
      return -1;
    }
    return addGlobalMetadata(_emitter.constantReference(constant));
  }

  int reifyType(DartType type, {bool ignoreTypeVariables: false}) {
    return reifyTypeForOutputUnit(type,
                                  _compiler.deferredLoadTask.mainOutputUnit,
                                  ignoreTypeVariables: ignoreTypeVariables);
  }

  int reifyTypeForOutputUnit(DartType type, OutputUnit outputUnit,
                             {bool ignoreTypeVariables: false}) {
    jsAst.Expression representation =
        _backend.rti.getTypeRepresentation(
            type,
            (variable) {
              if (ignoreTypeVariables) return new jsAst.LiteralNull();
              return js.number(
                  _typeVariableHandler.reifyTypeVariable(
                      variable.element));
            },
            (TypedefType typedef) {
              return _backend.isAccessibleByReflection(typedef.element);
            });

    if (representation is jsAst.LiteralString) {
      // We don't want the representation to be a string, since we use
      // strings as indicator for non-initialized types in the lazy emitter.
      _compiler.internalError(
          NO_LOCATION_SPANNABLE, 'reified types should not be strings.');
    }

    return addTypeInOutputUnit(representation, outputUnit);
  }

  int reifyName(String name) {
    return addGlobalMetadata(js('"$name"'));
  }

  int addGlobalMetadata(jsAst.Expression expression) {
    // TODO(sigmund): consider adding an effient way to compare expressions
    String string = jsAst.prettyPrint(expression, _compiler).getText();
    return _globalMetadataMap.putIfAbsent(string, () {
      globalMetadata.add(expression);
      return globalMetadata.length - 1;
    });
  }

  int addTypeInOutputUnit(jsAst.Expression type, OutputUnit outputUnit) {
    String string = jsAst.prettyPrint(type, _compiler).getText();
    if (_typesMap[outputUnit] == null) {
      _typesMap[outputUnit] = <String, int>{};
    }
    return _typesMap[outputUnit].putIfAbsent(string, () {

      if (types[outputUnit] == null) {
        types[outputUnit] = <jsAst.Expression>[];
      }

      types[outputUnit].add(type);
      return types[outputUnit].length - 1;
    });
  }

  List<int> computeMetadata(FunctionElement element) {
    return _compiler.withCurrentElement(element, () {
      if (!_mustEmitMetadataFor(element)) return const <int>[];
      List<int> metadata = <int>[];
      Link link = element.metadata;
      // TODO(ahe): Why is metadata sometimes null?
      if (link != null) {
        for (; !link.isEmpty; link = link.tail) {
          metadata.add(reifyMetadata(link.head));
        }
      }
      return metadata;
    });
  }
}
