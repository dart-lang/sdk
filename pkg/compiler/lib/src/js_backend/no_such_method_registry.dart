// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/**
 * Categorizes `noSuchMethod` implementations.
 *
 * If user code includes `noSuchMethod` implementations, type inference is
 * hindered because (for instance) any selector where the type of the
 * receiver is not known all implementations of `noSuchMethod` must be taken
 * into account when inferring the return type.
 *
 * The situation can be ameliorated with some heuristics for disregarding some
 * `noSuchMethod` implementations during type inference. We can partition
 * `noSuchMethod` implementations into 3 categories.
 *
 * Implementations in category A are the default implementations
 * `Object.noSuchMethod` and `Interceptor.noSuchMethod`.
 *
 * Implementations in category B syntactically immediately throw, for example:
 *
 *     noSuchMethod(x) => throw 'not implemented'
 *
 * Implementations that do not fall into category A or B are in category C. They
 * are the only category of implementation that are considered during type
 * inference.
 *
 * Implementations that syntactically just forward to the super implementation,
 * for example:
 *
 *     noSuchMethod(x) => super.noSuchMethod(x);
 *
 * are in the same category as the superclass implementation. This covers a
 * common case, where users implement `noSuchMethod` with these dummy
 * implementations to avoid warnings.
 */
class NoSuchMethodRegistry {
  /// The implementations that fall into category A, described above.
  final Set<FunctionElement> defaultImpls = new Set<FunctionElement>();
  /// The implementations that fall into category B, described above.
  final Set<FunctionElement> throwingImpls = new Set<FunctionElement>();
  /// The implementations that fall into category C, described above.
  final Set<FunctionElement> otherImpls = new Set<FunctionElement>();

  /// The implementations that fall into category C1
  final Set<FunctionElement> complexNoReturnImpls = new Set<FunctionElement>();
  /// The implementations that fall into category C2
  final Set<FunctionElement> complexReturningImpls = new Set<FunctionElement>();

  /// The implementations that have not yet been categorized.
  final Set<FunctionElement> _uncategorizedImpls = new Set<FunctionElement>();

  final JavaScriptBackend _backend;
  final Compiler _compiler;

  NoSuchMethodRegistry(JavaScriptBackend backend)
      : this._backend = backend,
        this._compiler = backend.compiler;

  bool get hasThrowingNoSuchMethod => throwingImpls.isNotEmpty;
  bool get hasComplexNoSuchMethod => otherImpls.isNotEmpty;

  void registerNoSuchMethod(FunctionElement noSuchMethodElement) {
    _uncategorizedImpls.add(noSuchMethodElement);
  }

  void onQueueEmpty() {
    _uncategorizedImpls.forEach(_categorizeImpl);
    _uncategorizedImpls.clear();
  }

  /// Now that type inference is complete, split category C into two
  /// subcategories: C1, those that have no return type, and C2, those
  /// that have a return type.
  void onTypeInferenceComplete() {
    otherImpls.forEach(_subcategorizeOther);
  }

  /// Emits a diagnostic
  void emitDiagnostic() {
    throwingImpls.forEach((e) {
        if (!_hasForwardingSyntax(e)) {
          _compiler.reportHint(e,
                               MessageKind.DIRECTLY_THROWING_NSM);
        }
      });
    complexNoReturnImpls.forEach((e) {
        if (!_hasForwardingSyntax(e)) {
          _compiler.reportHint(e,
                               MessageKind.COMPLEX_THROWING_NSM);
        }
      });
    complexReturningImpls.forEach((e) {
        if (!_hasForwardingSyntax(e)) {
          _compiler.reportHint(e,
                               MessageKind.COMPLEX_RETURNING_NSM);
        }
      });
  }

  /// Returns [true] if the given element is a complex [noSuchMethod]
  /// implementation. An implementation is complex if it falls into
  /// category C, as described above.
  bool isComplex(FunctionElement element) {
    assert(element.name == Compiler.NO_SUCH_METHOD);
    return otherImpls.contains(element);
  }

  _subcategorizeOther(FunctionElement element) {
    TypeMask returnType =
        _compiler.typesTask.getGuaranteedReturnTypeOfElement(element);
    if (returnType == const TypeMask.nonNullEmpty()) {
      complexNoReturnImpls.add(element);
    } else {
      complexReturningImpls.add(element);
    }
  }

  NsmCategory _categorizeImpl(FunctionElement element) {
    assert(element.name == Compiler.NO_SUCH_METHOD);
    if (defaultImpls.contains(element)) {
      return NsmCategory.DEFAULT;
    }
    if (throwingImpls.contains(element)) {
      return NsmCategory.THROWING;
    }
    if (otherImpls.contains(element)) {
      return NsmCategory.OTHER;
    }
    if (!_compiler.noSuchMethodSelector.signatureApplies(element)) {
      otherImpls.add(element);
      return NsmCategory.OTHER;
    }
    if (_isDefaultNoSuchMethodImplementation(element)) {
      defaultImpls.add(element);
      return NsmCategory.DEFAULT;
    } else if (_hasForwardingSyntax(element)) {
      // If the implementation is 'noSuchMethod(x) => super.noSuchMethod(x);'
      // then it is in the same category as the super call.
      Element superCall = element.enclosingClass
          .lookupSuperByName(_compiler.noSuchMethodSelector.memberName);
      NsmCategory category = _categorizeImpl(superCall);
      switch(category) {
        case NsmCategory.DEFAULT:
          defaultImpls.add(element);
          break;
        case NsmCategory.THROWING:
          throwingImpls.add(element);
          break;
        case NsmCategory.OTHER:
          otherImpls.add(element);
          break;
      }
      return category;
    } else if (_hasThrowingSyntax(element)) {
      throwingImpls.add(element);
      return NsmCategory.THROWING;
    } else {
      otherImpls.add(element);
      return NsmCategory.OTHER;
    }
  }

  bool _isDefaultNoSuchMethodImplementation(FunctionElement element) {
    ClassElement classElement = element.enclosingClass;
    return classElement == _compiler.objectClass
        || classElement == _backend.jsInterceptorClass
        || classElement == _backend.jsNullClass;
  }

  bool _hasForwardingSyntax(FunctionElement element) {
    // At this point we know that this is signature-compatible with
    // Object.noSuchMethod, but it may have more than one argument as long as
    // it only has one required argument.
    String param = element.parameters.first.name;
    Statement body = element.node.body;
    Expression expr;
    if (body is Return && body.isArrowBody) {
      expr = body.expression;
    } else if (body is Block &&
        !body.statements.isEmpty &&
        body.statements.nodes.tail.isEmpty) {
      Statement stmt = body.statements.nodes.head;
      if (stmt is Return && stmt.hasExpression) {
        expr = stmt.expression;
      }
    }
    if (expr is Send &&
        expr.isSuperCall &&
        expr.selector is Identifier &&
        (expr.selector as Identifier).source == Compiler.NO_SUCH_METHOD) {
      var arg = expr.arguments.head;
      if (expr.arguments.tail.isEmpty &&
          arg is Send &&
          arg.argumentsNode == null &&
          arg.receiver == null &&
          arg.selector is Identifier &&
          arg.selector.source == param) {
        return true;
      }
    }
    return false;
  }

  bool _hasThrowingSyntax(FunctionElement element) {
    Statement body = element.node.body;
    if (body is Return && body.isArrowBody) {
      if (body.expression is Throw) {
        return true;
      }
    } else if (body is Block &&
        !body.statements.isEmpty &&
        body.statements.nodes.tail.isEmpty) {
      if (body.statements.nodes.head is ExpressionStatement) {
        ExpressionStatement stmt = body.statements.nodes.head;
        return stmt.expression is Throw;
      }
    }
    return false;
  }
}

enum NsmCategory { DEFAULT, THROWING, OTHER }