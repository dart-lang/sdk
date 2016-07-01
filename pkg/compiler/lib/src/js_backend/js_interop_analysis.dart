// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Analysis to determine how to generate code for typed JavaScript interop.
library compiler.src.js_backend.js_interop_analysis;

import '../common.dart';
import '../constants/values.dart'
    show ConstantValue, ConstructedConstantValue, StringConstantValue;
import '../dart_types.dart'
    show
        DartType,
        DynamicType,
        FunctionType;
import '../diagnostics/messages.dart' show MessageKind;
import '../elements/elements.dart'
    show
        ClassElement,
        Element,
        FieldElement,
        FunctionElement,
        LibraryElement,
        ParameterElement,
        MetadataAnnotation;
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../universe/selector.dart' show Selector;
import '../universe/universe.dart' show SelectorConstraints;
import 'backend_helpers.dart' show BackendHelpers;
import 'js_backend.dart' show JavaScriptBackend;

class JsInteropAnalysis {
  final JavaScriptBackend backend;

  /// The resolved [FieldElement] for `Js.name`.
  FieldElement nameField;
  bool enabledJsInterop = false;

  /// Whether the backend is currently processing the codegen queue.
  bool _inCodegen = false;

  JsInteropAnalysis(this.backend);

  BackendHelpers get helpers => backend.helpers;

  void onQueueClosed() {
    if (_inCodegen) return;

    if (helpers.jsAnnotationClass != null) {
      nameField = helpers.jsAnnotationClass.lookupMember('name');
      backend.compiler.libraryLoader.libraries
          .forEach(processJsInteropAnnotationsInLibrary);
    }
  }

  void onCodegenStart() {
    _inCodegen = true;
  }

  void processJsInteropAnnotation(Element e) {
    for (MetadataAnnotation annotation in e.implementation.metadata) {
      // TODO(johnniwinther): Avoid processing unresolved elements.
      if (annotation.constant == null) continue;
      ConstantValue constant =
          backend.compiler.constants.getConstantValue(annotation.constant);
      if (constant == null || constant is! ConstructedConstantValue) continue;
      ConstructedConstantValue constructedConstant = constant;
      if (constructedConstant.type.element == helpers.jsAnnotationClass) {
        ConstantValue value = constructedConstant.fields[nameField];
        if (value.isString) {
          StringConstantValue stringValue = value;
          backend.nativeData
              .setJsInteropName(e, stringValue.primitiveValue.slowToString());
        } else {
          // TODO(jacobr): report a warning if the value is not a String.
          backend.nativeData.setJsInteropName(e, '');
        }
        enabledJsInterop = true;
        return;
      }
    }
  }

  bool hasAnonymousAnnotation(Element element) {
    if (backend.helpers.jsAnonymousClass == null) return false;
    return element.metadata.any((MetadataAnnotation annotation) {
      ConstantValue constant =
          backend.compiler.constants.getConstantValue(annotation.constant);
      if (constant == null || constant is! ConstructedConstantValue)
        return false;
      ConstructedConstantValue constructedConstant = constant;
      return constructedConstant.type.element ==
          backend.helpers.jsAnonymousClass;
    });
  }

  void _checkFunctionParameters(FunctionElement fn) {
    if (fn.hasFunctionSignature &&
        fn.functionSignature.optionalParametersAreNamed) {
      backend.reporter.reportErrorMessage(
          fn,
          MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
          {'method': fn.name});
    }
  }

  void processJsInteropAnnotationsInLibrary(LibraryElement library) {
    processJsInteropAnnotation(library);
    library.implementation.forEachLocalMember((Element element) {
      processJsInteropAnnotation(element);
      if (!backend.isJsInterop(element)) return;
      if (element is FunctionElement) {
        _checkFunctionParameters(element);
      }

      if (!element.isClass) return;

      ClassElement classElement = element;

      // Skip classes that are completely unreachable. This should only happen
      // when all of jsinterop types are unreachable from main.
      if (!backend.compiler.world.isImplemented(classElement)) return;

      if (!classElement.implementsInterface(helpers.jsJavaScriptObjectClass)) {
        backend.reporter.reportErrorMessage(classElement,
            MessageKind.JS_INTEROP_CLASS_CANNOT_EXTEND_DART_CLASS, {
          'cls': classElement.name,
          'superclass': classElement.superclass.name
        });
      }

      classElement.forEachMember((ClassElement classElement, Element member) {
        processJsInteropAnnotation(member);

        if (!member.isSynthesized &&
            backend.isJsInterop(classElement) &&
            member is FunctionElement) {
          FunctionElement fn = member;
          if (!fn.isExternal &&
              !fn.isAbstract &&
              !fn.isConstructor &&
              !fn.isStatic) {
            backend.reporter.reportErrorMessage(
                fn,
                MessageKind.JS_INTEROP_CLASS_NON_EXTERNAL_MEMBER,
                {'cls': classElement.name, 'member': member.name});
          }

          if (fn.isFactoryConstructor && hasAnonymousAnnotation(classElement)) {
            fn.functionSignature
                .orderedForEachParameter((ParameterElement parameter) {
              if (!parameter.isNamed) {
                backend.reporter.reportErrorMessage(
                    parameter,
                    MessageKind
                        .JS_OBJECT_LITERAL_CONSTRUCTOR_WITH_POSITIONAL_ARGUMENTS,
                    {'parameter': parameter.name, 'cls': classElement.name});
              }
            });
          } else {
            _checkFunctionParameters(fn);
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
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
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

  FunctionType buildJsFunctionType() {
    // TODO(jacobr): consider using codegenWorld.isChecks to determine the
    // range of positional arguments that need to be supported by JavaScript
    // function types.
    return new FunctionType.synthesized(
      const DynamicType(),
      [],
      new List<DartType>.filled(16, const DynamicType()));
  }
}
