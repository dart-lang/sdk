// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class MetadataEmitter extends CodeEmitterHelper {
  /// A list of JS expressions that represent metadata, parameter names and
  /// type, and return types.
  final List<String> globalMetadata = [];

  /// A map used to canonicalize the entries of globalMetadata.
  final Map<String, int> globalMetadataMap = <String, int>{};

  /// The metadata function returns the metadata associated with
  /// [element] in generated code.  The metadata needs to be wrapped
  /// in a function as it refers to constants that may not have been
  /// constructed yet.  For example, a class is allowed to be
  /// annotated with itself.  The metadata function is used by
  /// mirrors_patch to implement DeclarationMirror.metadata.
  jsAst.Fun buildMetadataFunction(Element element) {
    if (!backend.retainMetadataOf(element)) return null;
    return compiler.withCurrentElement(element, () {
      var metadata = [];
      Link link = element.metadata;
      // TODO(ahe): Why is metadata sometimes null?
      if (link != null) {
        for (; !link.isEmpty; link = link.tail) {
          MetadataAnnotation annotation = link.head;
          Constant value =
              backend.constants.getConstantForMetadata(annotation);
          if (value == null) {
            compiler.internalError(annotation, 'Annotation value is null.');
          } else {
            metadata.add(task.constantReference(value));
          }
        }
      }
      if (metadata.isEmpty) return null;
      return js('function() { return # }',
          new jsAst.ArrayInitializer.from(metadata));
    });
  }

  List<int> reifyDefaultArguments(FunctionElement function) {
    FunctionSignature signature = function.functionSignature;
    if (signature.optionalParameterCount == 0) return const [];
    List<int> defaultValues = <int>[];
    for (Element element in signature.optionalParameters) {
      Constant value = backend.constants.getConstantForVariable(element);
      String stringRepresentation = (value == null)
          ? "null"
          : jsAst.prettyPrint(task.constantReference(value), compiler)
              .getText();
      defaultValues.add(addGlobalMetadata(stringRepresentation));
    }
    return defaultValues;
  }

  int reifyMetadata(MetadataAnnotation annotation) {
    Constant value = backend.constants.getConstantForMetadata(annotation);
    if (value == null) {
      compiler.internalError(annotation, 'Annotation value is null.');
      return -1;
    }
    return addGlobalMetadata(
        jsAst.prettyPrint(task.constantReference(value), compiler).getText());
  }

  int reifyType(DartType type) {
    jsAst.Expression representation =
        backend.rti.getTypeRepresentation(type, (variable) {
          return js.number(
              task.typeVariableHandler.reifyTypeVariable(variable.element));
        });

    return addGlobalMetadata(
        jsAst.prettyPrint(representation, compiler).getText());
  }

  int reifyName(String name) {
    return addGlobalMetadata('"$name"');
  }

  int addGlobalMetadata(String string) {
    return globalMetadataMap.putIfAbsent(string, () {
      globalMetadata.add(string);
      return globalMetadata.length - 1;
    });
  }

  void emitMetadata(CodeBuffer buffer) {
    buffer.write('init.metadata$_=$_[');
    for (String metadata in globalMetadata) {
      if (metadata is String) {
        if (metadata != 'null') {
          buffer.write(metadata);
        }
      } else {
        throw 'Unexpected value in metadata: ${Error.safeToString(metadata)}';
      }
      buffer.write(',$n');
    }
    buffer.write('];$n');
  }

  List<int> computeMetadata(FunctionElement element) {
    return compiler.withCurrentElement(element, () {
      if (!backend.retainMetadataOf(element)) return const <int>[];
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
