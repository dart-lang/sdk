// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compile_time_constants.dart';
import '../compiler.dart' show Compiler;
import '../constants/constant_system.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/visitor.dart' show BaseElementVisitor;
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

  // TODO(johnniwinther): Remove this when values are computed from the
  // expressions.
  @override
  void copyConstantValues(covariant JavaScriptConstantTask task) {
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
  // TODO(johnniwinther): Move this to the backend constant handler.
  /** Caches the statics where the initial value cannot be eagerly compiled. */
  final Set<FieldEntity> lazyStatics = new Set<FieldEntity>();

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

  @override
  void registerLazyStatic(FieldEntity element) {
    lazyStatics.add(element);
  }

  List<FieldEntity> getLazilyInitializedFieldsForEmission() {
    return new List<FieldEntity>.from(lazyStatics);
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
