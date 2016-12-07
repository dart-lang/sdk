// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.variables;

import '../common.dart';
import '../common/resolution.dart';
import '../elements/modelx.dart' show LocalVariableElementX, VariableList;
import '../tree/tree.dart';
import '../universe/use.dart' show TypeUse;
import '../universe/feature.dart';
import '../util/util.dart' show Link;
import 'members.dart' show ResolverVisitor;
import 'registry.dart' show ResolutionRegistry;
import 'resolution_common.dart' show CommonResolverVisitor;
import 'scope.dart' show VariableDefinitionScope;

class VariableDefinitionsVisitor extends CommonResolverVisitor<Identifier> {
  VariableDefinitions definitions;
  ResolverVisitor resolver;
  VariableList variables;

  VariableDefinitionsVisitor(
      Resolution resolution, this.definitions, this.resolver, this.variables)
      : super(resolution);

  ResolutionRegistry get registry => resolver.registry;

  Identifier visitSendSet(SendSet node) {
    assert(node.arguments.tail.isEmpty); // Sanity check
    Identifier identifier = node.selector;
    String name = identifier.source;
    VariableDefinitionScope scope =
        new VariableDefinitionScope(resolver.scope, name);
    resolver.visitIn(node.arguments.head, scope);
    if (scope.variableReferencedInInitializer) {
      reporter.reportErrorMessage(identifier,
          MessageKind.REFERENCE_IN_INITIALIZATION, {'variableName': name});
    }
    return identifier;
  }

  Identifier visitIdentifier(Identifier node) {
    if (!resolver.inCatchParameters) {
      // The variable is initialized to null.
      registry.registerFeature(Feature.LOCAL_WITHOUT_INITIALIZER);
    }
    if (definitions.modifiers.isConst) {
      if (resolver.inLoopVariable) {
        reporter.reportErrorMessage(node, MessageKind.CONST_LOOP_VARIABLE);
      } else {
        reporter.reportErrorMessage(
            node, MessageKind.CONST_WITHOUT_INITIALIZER);
      }
    }
    if (definitions.modifiers.isFinal && !resolver.inLoopVariable) {
      reporter.reportErrorMessage(node, MessageKind.FINAL_WITHOUT_INITIALIZER);
    }
    return node;
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      Identifier name = visit(link.head);
      LocalVariableElementX element = new LocalVariableElementX(
          name.source, resolver.enclosingElement, variables, name.token);
      resolver.defineLocalVariable(link.head, element);
      resolver.addToScope(element);
      if (definitions.modifiers.isConst) {
        addDeferredAction(element, () {
          element.constant =
              resolution.resolver.constantCompiler.compileConstant(element);
        });
      }
    }
  }
}
