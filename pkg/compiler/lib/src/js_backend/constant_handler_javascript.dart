// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

/// [ConstantCompilerTask] for compilation of constants for the JavaScript
/// backend.
///
/// Since this task needs to distinguish between frontend and backend constants
/// the actual compilation of the constants is forwarded to a
/// [DartConstantCompiler] for the frontend interpretation of the constants and
/// to a [JavaScriptConstantCompiler] for the backend interpretation.
class JavaScriptConstantTask extends ConstantCompilerTask {
  DartConstantCompiler dartConstantCompiler;
  JavaScriptConstantCompiler jsConstantCompiler;

  JavaScriptConstantTask(Compiler compiler)
      : this.dartConstantCompiler = new DartConstantCompiler(compiler),
        this.jsConstantCompiler =
            new JavaScriptConstantCompiler(compiler),
        super(compiler);

  String get name => 'ConstantHandler';

  ConstantExpression getConstantForVariable(VariableElement element) {
    return dartConstantCompiler.getConstantForVariable(element);
  }

  ConstantExpression compileConstant(VariableElement element) {
    return measure(() {
      ConstantExpression result = dartConstantCompiler.compileConstant(element);
      jsConstantCompiler.compileConstant(element);
      return result;
    });
  }

  void compileVariable(VariableElement element) {
    measure(() {
      jsConstantCompiler.compileVariable(element);
    });
  }

  ConstantExpression compileNode(Node node, TreeElements elements) {
    return measure(() {
      ConstantExpression result =
          dartConstantCompiler.compileNode(node, elements);
      jsConstantCompiler.compileNode(node, elements);
      return result;
    });
  }

  ConstantExpression compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    return measure(() {
      ConstantExpression constant =
          dartConstantCompiler.compileMetadata(metadata, node, elements);
      jsConstantCompiler.compileMetadata(metadata, node, elements);
      return constant;
    });
  }
}

/**
 * The [JavaScriptConstantCompiler] is used to keep track of compile-time
 * constants, initializations of global and static fields, and default values of
 * optional parameters for the JavaScript interpretation of constants.
 */
class JavaScriptConstantCompiler extends ConstantCompilerBase
    implements BackendConstantEnvironment {

  /** Set of all registered compiled constants. */
  final Set<ConstantValue> compiledConstants = new Set<ConstantValue>();

  // TODO(johnniwinther): Move this to the backend constant handler.
  /** Caches the statics where the initial value cannot be eagerly compiled. */
  final Set<VariableElement> lazyStatics = new Set<VariableElement>();

  // Constants computed for constant expressions.
  final Map<Node, ConstantExpression> nodeConstantMap =
      new Map<Node, ConstantExpression>();

  // Constants computed for metadata.
  final Map<MetadataAnnotation, ConstantExpression> metadataConstantMap =
      new Map<MetadataAnnotation, ConstantExpression>();

  JavaScriptConstantCompiler(Compiler compiler)
      : super(compiler, JAVA_SCRIPT_CONSTANT_SYSTEM);

  ConstantExpression compileVariableWithDefinitions(VariableElement element,
                                          TreeElements definitions,
                                          {bool isConst: false}) {
    if (!isConst && lazyStatics.contains(element)) {
      return null;
    }
    ConstantExpression value = super.compileVariableWithDefinitions(
        element, definitions, isConst: isConst);
    if (!isConst && value == null) {
      lazyStatics.add(element);
    }
    return value;
  }

  void addCompileTimeConstantForEmission(ConstantValue constant) {
    compiledConstants.add(constant);
  }

  /**
   * Returns an [Iterable] of static non final fields that need to be
   * initialized. The fields list must be evaluated in order since they might
   * depend on each other.
   */
  Iterable<VariableElement> getStaticNonFinalFieldsForEmission() {
    return initialVariableValues.keys.where((element) {
      return element.kind == ElementKind.FIELD &&
             !element.isInstanceMember &&
             !element.modifiers.isFinal &&
             // The const fields are all either emitted elsewhere or inlined.
             !element.modifiers.isConst;
    });
  }

  List<VariableElement> getLazilyInitializedFieldsForEmission() {
    return new List<VariableElement>.from(lazyStatics);
  }

  /**
   * Returns a list of constants topologically sorted so that dependencies
   * appear before the dependent constant.  [preSortCompare] is a comparator
   * function that gives the constants a consistent order prior to the
   * topological sort which gives the constants an ordering that is less
   * sensitive to perturbations in the source code.
   */
  List<ConstantValue> getConstantsForEmission([preSortCompare]) {
    // We must emit dependencies before their uses.
    Set<ConstantValue> seenConstants = new Set<ConstantValue>();
    List<ConstantValue> result = new List<ConstantValue>();

    void addConstant(ConstantValue constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    List<ConstantValue> sorted = compiledConstants.toList();
    if (preSortCompare != null) {
      sorted.sort(preSortCompare);
    }
    sorted.forEach(addConstant);
    return result;
  }

  ConstantExpression getInitialValueFor(VariableElement element) {
    ConstantExpression initialValue =
        initialVariableValues[element.declaration];
    if (initialValue == null) {
      compiler.internalError(element, "No initial value for given element.");
    }
    return initialValue;
  }

  ConstantExpression compileNode(Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }

  ConstantExpression compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    ConstantExpression constant = nodeConstantMap[node];
    if (constant != null) {
      return constant;
    }
    constant =
        super.compileNodeWithDefinitions(node, definitions, isConst: isConst);
    if (constant != null) {
      nodeConstantMap[node] = constant;
    }
    return constant;
  }

  ConstantExpression getConstantForNode(Node node, TreeElements definitions) {
    ConstantExpression constant = nodeConstantMap[node];
    if (constant != null) {
      return constant;
    }
    return definitions.getConstant(node);
  }

  ConstantExpression getConstantForMetadata(MetadataAnnotation metadata) {
    return metadataConstantMap[metadata];
  }

  ConstantExpression compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    ConstantExpression constant =
        super.compileMetadata(metadata, node, elements);
    metadataConstantMap[metadata] = constant;
    return constant;
  }

  ConstantExpression createTypeConstant(TypeDeclarationElement element) {
    DartType elementType = element.rawType;
    DartType constantType =
        compiler.backend.typeImplementation.computeType(compiler);
    return new TypeConstantExpression(
        new TypeConstantValue(elementType, constantType), elementType);
  }

  void forgetElement(Element element) {
    super.forgetElement(element);
    element.accept(new ForgetConstantElementVisitor(this));
    if (element is AstElement && element.hasNode) {
      element.node.accept(new ForgetConstantNodeVisitor(this));
    }
  }
}

class ForgetConstantElementVisitor extends ElementVisitor {
  final JavaScriptConstantCompiler constants;

  ForgetConstantElementVisitor(this.constants);

  void visitElement(Element e) {
    for (MetadataAnnotation data in e.metadata) {
      constants.metadataConstantMap.remove(data);
      if (data.hasNode) {
        data.node.accept(new ForgetConstantNodeVisitor(constants));
      }
    }
  }

  void visitFunctionElement(FunctionElement e) {
    super.visitFunctionElement(e);
    if (e.hasFunctionSignature) {
      e.functionSignature.forEachParameter(this.visit);
    }
  }
}

class ForgetConstantNodeVisitor extends Visitor {
  final JavaScriptConstantCompiler constants;

  ForgetConstantNodeVisitor(this.constants);

  void visitNode(Node node) {
    node.visitChildren(this);
    constants.nodeConstantMap.remove(node);

    // TODO(ahe): This doesn't belong here. Rename this class and generalize.
    var closureClassMap =
        constants.compiler.closureToClassMapper.closureMappingCache
        .remove(node);
    if (closureClassMap != null) {
      closureClassMap.removeMyselfFrom(
          constants.compiler.enqueuer.codegen.universe);
    }
  }
}
