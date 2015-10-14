// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Analysis to determine how to generate code for typed JavaScript interop.
library compiler.src.js_backend.js_interop_analysis;

import '../common/names.dart' show Identifiers;
import '../compiler.dart' show Compiler;
import '../diagnostics/messages.dart' show MessageKind;
import '../constants/values.dart'
    show
        ConstantValue,
        ConstructedConstantValue,
        ListConstantValue,
        NullConstantValue,
        StringConstantValue,
        TypeConstantValue;
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        FunctionElement,
        LibraryElement,
        MetadataAnnotation;

import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../universe/selector.dart' show Selector;
import '../universe/universe.dart' show SelectorConstraints;

import 'js_backend.dart' show JavaScriptBackend;

class JsInteropAnalysis {
  final JavaScriptBackend backend;

  /// The resolved [FieldElement] for `Js.name`.
  FieldElement nameField;
  bool enabledJsInterop = false;

  /// Whether the backend is currently processing the codegen queue.
  bool _inCodegen = false;

  JsInteropAnalysis(this.backend);

  void onQueueClosed() {
    if (_inCodegen) return;

    if (backend.jsAnnotationClass != null) {
      nameField = backend.jsAnnotationClass.lookupMember('name');
      backend.compiler.libraryLoader.libraries
          .forEach(processJsInteropAnnotationsInLibrary);
    }
  }

  void onCodegenStart() {
    _inCodegen = true;
  }

  void processJsInteropAnnotation(Element e) {
    for (MetadataAnnotation annotation in e.implementation.metadata) {
      ConstantValue constant = backend.compiler.constants.getConstantValue(
          annotation.constant);
      if (constant == null || constant is! ConstructedConstantValue) continue;
      ConstructedConstantValue constructedConstant = constant;
      if (constructedConstant.type.element == backend.jsAnnotationClass) {
        ConstantValue value = constructedConstant.fields[nameField];
        if (value.isString) {
          StringConstantValue stringValue = value;
          e.setJsInteropName(stringValue.primitiveValue.slowToString());
        } else {
          // TODO(jacobr): report a warning if the value is not a String.
          e.setJsInteropName('');
        }
        enabledJsInterop = true;
        return;
      }
    }
  }

  void processJsInteropAnnotationsInLibrary(LibraryElement library) {
    processJsInteropAnnotation(library);
    library.implementation.forEachLocalMember((Element element) {
      processJsInteropAnnotation(element);
      if (!element.isClass || !element.isJsInterop) return;

      ClassElement classElement = element;

      if (!classElement
          .implementsInterface(backend.jsJavaScriptObjectClass)) {
        backend.reporter.reportErrorMessage(classElement,
            MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS, {
          'cls': classElement.name,
          'superclass': classElement.superclass.name
        });
      }

      classElement.forEachMember(
          (ClassElement classElement, Element member) {
        processJsInteropAnnotation(member);

        if (!member.isSynthesized &&
            classElement.isJsInterop &&
            member is FunctionElement) {
          FunctionElement fn = member;
          if (!fn.isExternal && !fn.isAbstract) {
            backend.reporter.reportErrorMessage(
                fn,
                MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
                {'cls': classElement.name, 'member': member.name});
          }
        }
      });
    });
  }

  jsAst.Statement buildJsInteropBootstrap() {
    if (!enabledJsInterop) return null;
    List<jsAst.Statement> statements = <jsAst.Statement>[];
    backend.compiler.codegenWorld.forEachInvokedName(
        (String name, Map<Selector, SelectorConstraints> selectors) {
      selectors.forEach((Selector selector, SelectorConstraints constraints) {
        if (selector.isClosureCall) {
          // TODO(jacobr): support named arguments.
          if (selector.namedArgumentCount > 0) return;
          int argumentCount = selector.argumentCount;
          var candidateParameterNames =
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLOMOPQRSTUVWXYZ';
          var parameters = new List<String>.generate(
              argumentCount, (i) => candidateParameterNames[i]);

          var name = backend.namer.invocationName(selector);
          statements.add(js.statement(
              'Function.prototype.# = function(#) { return this(#) }',
              [name, parameters, parameters]));
        }
      });
    });
    return new jsAst.Block(statements);
  }
}
