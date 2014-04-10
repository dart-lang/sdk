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

  Constant getConstantForVariable(VariableElement element) {
    return dartConstantCompiler.getConstantForVariable(element);
  }

  Constant compileConstant(VariableElement element) {
    return measure(() {
      Constant result = dartConstantCompiler.compileConstant(element);
      jsConstantCompiler.compileConstant(element);
      return result;
    });
  }

  void compileVariable(VariableElement element) {
    measure(() {
      jsConstantCompiler.compileVariable(element);
    });
  }

  Constant compileNode(Node node, TreeElements elements) {
    return measure(() {
      Constant result =
          dartConstantCompiler.compileNode(node, elements);
      jsConstantCompiler.compileNode(node, elements);
      return result;
    });
  }

  Constant compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    return measure(() {
      Constant constant =
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
  final Set<Constant> compiledConstants = new Set<Constant>();

  // TODO(johnniwinther): Move this to the backend constant handler.
  /** Caches the statics where the initial value cannot be eagerly compiled. */
  final Set<VariableElement> lazyStatics = new Set<VariableElement>();

  // Constants computed for constant expressions.
  final Map<Node, Constant> nodeConstantMap = new Map<Node, Constant>();

  // Constants computed for metadata.
  final Map<MetadataAnnotation, Constant> metadataConstantMap =
      new Map<MetadataAnnotation, Constant>();

  JavaScriptConstantCompiler(Compiler compiler)
      : super(compiler, JAVA_SCRIPT_CONSTANT_SYSTEM);

  Constant compileVariableWithDefinitions(VariableElement element,
                                          TreeElements definitions,
                                          {bool isConst: false}) {
    if (!isConst && lazyStatics.contains(element)) {
      return null;
    }
    Constant value = super.compileVariableWithDefinitions(
        element, definitions, isConst: isConst);
    if (!isConst && value == null) {
      lazyStatics.add(element);
    }
    return value;
  }

  void addCompileTimeConstantForEmission(Constant constant) {
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
             !element.isInstanceMember() &&
             !element.modifiers.isFinal() &&
             // The const fields are all either emitted elsewhere or inlined.
             !element.modifiers.isConst();
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
  List<Constant> getConstantsForEmission([preSortCompare]) {
    // We must emit dependencies before their uses.
    Set<Constant> seenConstants = new Set<Constant>();
    List<Constant> result = new List<Constant>();

    void addConstant(Constant constant) {
      if (!seenConstants.contains(constant)) {
        constant.getDependencies().forEach(addConstant);
        assert(!seenConstants.contains(constant));
        result.add(constant);
        seenConstants.add(constant);
      }
    }

    List<Constant> sorted = compiledConstants.toList();
    if (preSortCompare != null) {
      sorted.sort(preSortCompare);
    }
    sorted.forEach(addConstant);
    return result;
  }

  Constant getInitialValueFor(VariableElement element) {
    Constant initialValue = initialVariableValues[element.declaration];
    if (initialValue == null) {
      compiler.internalError(element, "No initial value for given element.");
    }
    return initialValue;
  }

  Constant compileNode(Node node, TreeElements elements) {
    return compileNodeWithDefinitions(node, elements);
  }

  Constant compileNodeWithDefinitions(Node node,
                                      TreeElements definitions,
                                      {bool isConst: true}) {
    Constant constant = nodeConstantMap[node];
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

  Constant getConstantForNode(Node node, TreeElements definitions) {
    Constant constant = nodeConstantMap[node];
    if (constant != null) {
      return constant;
    }
    return definitions.getConstant(node);
  }

  Constant getConstantForMetadata(MetadataAnnotation metadata) {
    return metadataConstantMap[metadata];
  }

  Constant compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    Constant constant = super.compileMetadata(metadata, node, elements);
    metadataConstantMap[metadata] = constant;
    return constant;
  }

  Constant createTypeConstant(TypeDeclarationElement element) {
    DartType elementType = element.rawType;
    DartType constantType =
        compiler.backend.typeImplementation.computeType(compiler);
    return new TypeConstant(elementType, constantType);
  }
}
