// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compile_time_constants.dart';
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/visitor.dart' show BaseElementVisitor;
import '../resolution/tree_elements.dart' show TreeElements;
import '../tree/tree.dart';
import 'constant_system_javascript.dart';

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
        this.jsConstantCompiler = new JavaScriptConstantCompiler(compiler),
        super(compiler.measurer);

  String get name => 'ConstantHandler';

  @override
  ConstantSystem get constantSystem => dartConstantCompiler.constantSystem;

  @override
  bool hasConstantValue(ConstantExpression expression) {
    return dartConstantCompiler.hasConstantValue(expression);
  }

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    return dartConstantCompiler.getConstantValue(expression);
  }

  @override
  ConstantValue getConstantValueForVariable(VariableElement element) {
    return dartConstantCompiler.getConstantValueForVariable(element);
  }

  @override
  ConstantExpression compileConstant(VariableElement element) {
    return measure(() {
      // TODO(het): Only report errors from one of the constant compilers
      ConstantExpression result = dartConstantCompiler.compileConstant(element);
      jsConstantCompiler.compileConstant(element);
      return result;
    });
  }

  @override
  void evaluate(ConstantExpression constant) {
    return measure(() {
      dartConstantCompiler.evaluate(constant);
      jsConstantCompiler.evaluate(constant);
    });
  }

  @override
  ConstantExpression compileVariable(VariableElement element) {
    return measure(() {
      return jsConstantCompiler.compileVariable(element);
    });
  }

  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true}) {
    return measure(() {
      ConstantExpression result = dartConstantCompiler
          .compileNode(node, elements, enforceConst: enforceConst);
      jsConstantCompiler.compileNode(node, elements,
          enforceConst: enforceConst);
      return result;
    });
  }

  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements) {
    return measure(() {
      ConstantExpression constant =
          dartConstantCompiler.compileMetadata(metadata, node, elements);
      jsConstantCompiler.compileMetadata(metadata, node, elements);
      return constant;
    });
  }

  // TODO(johnniwinther): Remove this when values are computed from the
  // expressions.
  @override
  void copyConstantValues(JavaScriptConstantTask task) {
    jsConstantCompiler.constantValueMap
        .addAll(task.jsConstantCompiler.constantValueMap);
    dartConstantCompiler.constantValueMap
        .addAll(task.dartConstantCompiler.constantValueMap);
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
  // TODO(johnniwinther): Remove this when no longer used by
  // poi/forget_element_test.
  final Map<MetadataAnnotation, ConstantExpression> metadataConstantMap =
      new Map<MetadataAnnotation, ConstantExpression>();

  JavaScriptConstantCompiler(Compiler compiler)
      : super(compiler, JAVA_SCRIPT_CONSTANT_SYSTEM);

  ConstantExpression compileVariableWithDefinitions(
      VariableElement element, TreeElements definitions,
      {bool isConst: false, bool checkType: true}) {
    if (!isConst && lazyStatics.contains(element)) {
      return null;
    }
    ConstantExpression value = super.compileVariableWithDefinitions(
        element, definitions,
        isConst: isConst, checkType: checkType);
    if (!isConst && value == null) {
      registerLazyStatic(element);
    }
    return value;
  }

  @override
  void registerLazyStatic(FieldElement element) {
    lazyStatics.add(element);
  }

  void addCompileTimeConstantForEmission(ConstantValue constant) {
    compiledConstants.add(constant);
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

  ConstantExpression compileNode(Node node, TreeElements elements,
      {bool enforceConst: true}) {
    return compileNodeWithDefinitions(node, elements, isConst: enforceConst);
  }

  ConstantExpression compileNodeWithDefinitions(
      Node node, TreeElements definitions,
      {bool isConst: true}) {
    ConstantExpression constant = nodeConstantMap[node];
    if (constant != null && getConstantValue(constant) != null) {
      return constant;
    }
    constant =
        super.compileNodeWithDefinitions(node, definitions, isConst: isConst);
    if (constant != null) {
      nodeConstantMap[node] = constant;
    }
    return constant;
  }

  ConstantValue getConstantValueForNode(Node node, TreeElements definitions) {
    return getConstantValue(getConstantForNode(node, definitions));
  }

  ConstantExpression getConstantForNode(Node node, TreeElements definitions) {
    ConstantExpression constant = nodeConstantMap[node];
    if (constant != null) {
      return constant;
    }
    return definitions.getConstant(node);
  }

  ConstantValue getConstantValueForMetadata(MetadataAnnotation metadata) {
    return getConstantValue(metadata.constant);
  }

  @override
  ConstantExpression compileMetadata(
      MetadataAnnotation metadata, Node node, TreeElements elements) {
    ConstantExpression constant =
        super.compileMetadata(metadata, node, elements);
    metadataConstantMap[metadata] = constant;
    return constant;
  }

  void forgetElement(Element element) {
    super.forgetElement(element);
    const ForgetConstantElementVisitor().visit(element, this);
    if (element is AstElement && element.hasNode) {
      element.node.accept(new ForgetConstantNodeVisitor(this));
    }
  }
}

class ForgetConstantElementVisitor
    extends BaseElementVisitor<dynamic, JavaScriptConstantCompiler> {
  const ForgetConstantElementVisitor();

  void visitElement(Element e, JavaScriptConstantCompiler constants) {
    for (MetadataAnnotation data in e.implementation.metadata) {
      constants.metadataConstantMap.remove(data);
      if (data.hasNode) {
        data.node.accept(new ForgetConstantNodeVisitor(constants));
      }
    }
  }

  void visitFunctionElement(
      FunctionElement e, JavaScriptConstantCompiler constants) {
    super.visitFunctionElement(e, constants);
    if (e.hasFunctionSignature) {
      e.functionSignature.forEachParameter((p) => visit(p, constants));
    }
  }
}

class ForgetConstantNodeVisitor extends Visitor {
  final JavaScriptConstantCompiler constants;

  ForgetConstantNodeVisitor(this.constants);

  void visitNode(Node node) {
    node.visitChildren(this);
    constants.nodeConstantMap.remove(node);
  }
}
