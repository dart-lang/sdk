// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class MetadataCollector {
  final Compiler _compiler;
  final Emitter _emitter;

  /// A list of JS expressions that represent metadata, parameter names and
  /// type variable types.
  final List<String> globalMetadata = <String>[];

  /// A map used to canonicalize the entries of globalMetadata.
  final Map<String, int> _globalMetadataMap = <String, int>{};

  /// A list of JS expression representing types including function types and
  /// typedefs.
  final List<String> types = <String>[];

  /// A map used to canonicalize the entries of types.
  final Map<String, int> _typesMap = <String, int>{};

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
          ConstantExpression constant =
              _backend.constants.getConstantForMetadata(annotation);
          if (constant == null) {
            _compiler.internalError(annotation, 'Annotation value is null.');
          } else {
            metadata.add(_emitter.constantReference(constant.value));
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
      ConstantExpression constant =
          _backend.constants.getConstantForVariable(element);
      String stringRepresentation = (constant == null)
          ? "null"
          : jsAst.prettyPrint(
              _emitter.constantReference(constant.value), _compiler).getText();
      defaultValues.add(addGlobalMetadata(stringRepresentation));
    }
    return defaultValues;
  }

  int reifyMetadata(MetadataAnnotation annotation) {
    ConstantExpression constant =
        _backend.constants.getConstantForMetadata(annotation);
    if (constant == null) {
      _compiler.internalError(annotation, 'Annotation value is null.');
      return -1;
    }
    return addGlobalMetadata(
        jsAst.prettyPrint(
            _emitter.constantReference(constant.value), _compiler).getText());
  }

  int reifyType(DartType type) {
    jsAst.Expression representation =
        _backend.rti.getTypeRepresentation(
            type,
            (variable) {
              return js.number(
                  _typeVariableHandler.reifyTypeVariable(
                      variable.element));
            },
            (TypedefType typedef) {
              return _backend.isAccessibleByReflection(typedef.element);
            });

    return addType(
        jsAst.prettyPrint(representation, _compiler).getText());
  }

  int reifyName(String name) {
    return addGlobalMetadata('"$name"');
  }

  int addGlobalMetadata(String string) {
    return _globalMetadataMap.putIfAbsent(string, () {
      globalMetadata.add(string);
      return globalMetadata.length - 1;
    });
  }

  int addType(String compiledType) {
    return _typesMap.putIfAbsent(compiledType, () {
      types.add(compiledType);
      return types.length - 1;
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
