// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Computes measurements about sends in a function.
library compiler.src.info.send_info;

import 'dart:convert';

import 'package:dart2js_info/src/measurements.dart';
import 'package:dart2js_info/src/util.dart' show
    recursiveDiagnosticString;

import '../common.dart';
import '../common/tasks.dart' show
    CompilerTask;
import '../compiler.dart' show
    Compiler;
import '../dart_types.dart';
import '../closure.dart';
import '../elements/elements.dart';
import '../elements/visitor.dart' show
    ElementVisitor;
import '../resolution/operators.dart';
import '../resolution/semantic_visitor.dart';
import '../resolution/send_resolver.dart';
import '../resolution/tree_elements.dart';
import '../constants/expressions.dart';
import '../parser/partial_elements.dart' show
    PartialElement;
import '../tree/tree.dart';
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;

import 'analysis_result.dart';
import 'naive_analysis_result.dart';
import 'trusted_types_analysis_result.dart';

/// Collects a set of [Measurements] about send expressions in the function [f].
// TODO(sigmund): collect information on initializers too.
Measurements collectSendMeasurements(FunctionElement f,
                                     Compiler compiler) {
  DiagnosticReporter reporter = compiler.reporter;
  return reporter.withCurrentElement(f, () {
    // TODO(sigmund): enable for platform too.
    if (f.library.isPlatformLibrary) return null;
    var name = _qualifiedName(f);
    if (!f.hasNode) {
      if (f is PartialElement) return const Measurements.unreachableFunction();
      assert (f is ConstructorElement && f.isSynthesized);
      // TODO(sigmund): measure synthethic forwarding sends, measure
      // initializers
      return new Measurements.reachableFunction();
    }
    if (!f.hasResolvedAst) {
      _debug('no resolved ast ${f.runtimeType}');
      return null;
    }
    var resolvedAst = f.resolvedAst;
    if (resolvedAst.node == null) {
      _debug('no node ${f.runtimeType}');
      return null;
    }
    var def = resolvedAst.elements.getFunctionDefinition(resolvedAst.node);
    if (def == null) {
      assert (f is PartialElement);
      return const Measurements.unreachableFunction();
    }

    var visitor = new _StatsTraversalVisitor(
        compiler, resolvedAst.elements,
        reporter.spanFromSpannable(resolvedAst.node).uri);
    resolvedAst.node.accept(visitor);
    return visitor.measurements;
  });
}

_qualifiedName(FunctionElement f) {
  var cls = f.enclosingClass;
  return (cls != null) ? '${cls.name}.${f.name}' : f.name;
}

/// Visitor that categorizes data about an individual send.
class _StatsVisitor<T> extends Visitor
    with SendResolverMixin, SemanticSendResolvedMixin<dynamic, T>
    implements SemanticSendVisitor<dynamic, T> {

  // TODO(sigmund): consider passing in several AnalysisResults at once, so we
  // can compute the different metrics together.
  /// Information we know about the program from static analysis.
  final AnalysisResult info;

  /// Results from this function.
  final Measurements measurements;

  final DiagnosticReporter reporter;
  final TreeElements elements;

  SemanticSendVisitor<dynamic, T> get sendVisitor => this;

  _StatsVisitor(this.reporter, this.elements, this.info, Uri sourceUri)
      : measurements = new Measurements.reachableFunction(sourceUri);

  visitNode(Node node) => throw "unhandled ${node.runtimeType}: $node";
  apply(Node node, T arg) => throw "missing apply ${node.runtimeType}: $node";
  internalError(Node node, String arg) => throw "internal error on $node";

  visitSend(Send node) {
    _checkInvariant(node, 'before');
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.send, span.begin, span.end);
    if (node is SendSet) {
      if ((node.assignmentOperator != null &&
                node.assignmentOperator.source != '=') ||
            node.isPrefix ||
            node.isPostfix) {
        assert(!node.isIfNullAssignment);
        // We count get and set separately in case one of them is defined by the
        // other could be a nSM error.
        measurements.record(Metric.send, span.begin, span.end);
        measurements.record(Metric.send, span.begin, span.end);
      } else if (node.isIfNullAssignment) {
        measurements.record(Metric.send, span.begin, span.end);
      }
    }
    super.visitSend(node);
    _checkInvariant(node, 'after ');
  }

  visitNewExpression(NewExpression node) {
    _checkInvariant(node, 'before');
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.send, span.begin, span.end);
    super.visitNewExpression(node);
    _checkInvariant(node, 'after ');
  }

  /// A monomorphic local variable read.
  ///
  /// See [Metric.send] for a full categorization of sends.
  handleLocal(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.localSend, span.begin, span.end);
  }

  /// A monomorphic virual call on [node], where we know which function is the
  /// target of the call (for example, because only one type in a class
  /// hierarchy implements a function with a given name).
  ///
  /// See [Metric.send] for a full categorization of sends.
  handleSingleInstance(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.instanceSend, span.begin, span.end);
  }

  /// A monomorphic call that goes through an interceptor. This is equivalent in
  /// terms of what the compiler knows as we do with [handleSignleInstance], and
  /// because we know the target of the call, we also know that it doesn't live
  /// in the object instance, but on an interceptor on the side.
  ///
  /// See [Metric.send] for a full categorization of sends.
  handleSingleInterceptor(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.interceptorSend, span.begin, span.end);
  }

  /// A polymorphic call that goes through an interceptor.
  ///
  /// See [Metric.send] for a full categorization of sends.
  handleMultiInterceptor(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.polymorphicSend, span.begin, span.end);
    measurements.record(Metric.multiInterceptorSend, span.begin, span.end);
  }

  handleConstructor(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.constructorSend, span.begin, span.end);
  }

  handleDynamic(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.polymorphicSend, span.begin, span.end);
    measurements.record(Metric.dynamicSend, span.begin, span.end);
  }

  handleVirtual(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.polymorphicSend, span.begin, span.end);
    measurements.record(Metric.virtualSend, span.begin, span.end);
  }

  handleNSMError(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.nsmErrorSend, span.begin, span.end);
  }

  handleNSMSingle(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.singleNsmCallSend, span.begin, span.end);
  }

  handleNSMSuper(Node node, ClassElement type) {
    var superclass = type.superclass;
    var member = superclass.lookupMember('noSuchMethod');
    if (!member.enclosingClass.isObject) {
      handleNSMSingle(node);
    } else {
      handleNSMError(node);
    }
  }

  handleNSMAny(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.polymorphicSend, span.begin, span.end);
    measurements.record(Metric.multiNsmCallSend, span.begin, span.end);
  }

  handleSuper(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.superSend, span.begin, span.end);
  }
  handleTypeVariable(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.typeVariableSend, span.begin, span.end);
  }
  handleStatic(Node node) {
    var span = reporter.spanFromSpannable(node);
    measurements.record(Metric.monomorphicSend, span.begin, span.end);
    measurements.record(Metric.staticSend, span.begin, span.end);
  }

  handleNoSend(Node node) {
    measurements.popLast(Metric.send);
  }

  void handleDynamicProperty(Node node, Node receiver, Selector selector) {
    // staticSend: no (automatically)
    // superSend: no (automatically)
    // localSend: no (automatically)
    // constructorSend: no (automatically)
    // typeVariableSend: no (automatically)

    // nsmErrorSend:      receiver has no `selector` nor nSM.
    // singleNsmCallSend: receiver has no `selector`, but definitely has `nSM`
    // instanceSend:      receiver has `selector`, no need to use an interceptor
    // interceptorSend:   receiver has `selector`, but we know we need an
    //                    interceptor to get it

    // multiNsmCallSend:  receiver has no `selector`, not sure if receiver has
    //                    nSM, or not sure which nSM is called (does this one
    //                    matter, or does nSM is treated like an instance method
    //                    call)?
    // virtualSend:       receiver has `selector`, we know we do not need an
    //                    interceptor, not sure which specific type implements
    //                    the selector.
    // multiInterceptorSend: multiple possible receiver types, all using an
    //                       interceptor to get the `selector`, might be
    //                       possbile to pick a special selector logic for this
    //                       combination?
    // dynamicSend: any combination of the above.

    ReceiverInfo receiverInfo = info.infoForReceiver(receiver);
    SelectorInfo selectorInfo = info.infoForSelector(receiver, selector);
    Boolish hasSelector = selectorInfo.exists;
    Boolish hasNsm = receiverInfo.hasNoSuchMethod;

    if (hasSelector == Boolish.no) {
      if (hasNsm == Boolish.no) {
        handleNSMError(node);
      } else if (hasNsm == Boolish.yes) {
        if (receiverInfo.possibleNsmTargets == 1) {
          handleNSMSingle(node);
        } else {
          handleNSMAny(node);
        }
      } else {
        handleDynamic(node);
      }
      return;
    }

    Boolish usesInterceptor = selectorInfo.usesInterceptor;
    if (hasSelector == Boolish.yes) {
      if (selectorInfo.isAccurate && selectorInfo.possibleTargets == 1) {
        assert (usesInterceptor != Boolish.maybe);
        if (usesInterceptor == Boolish.yes) {
          handleSingleInterceptor(node);
        } else {
          handleSingleInstance(node);
        }
      } else {
        if (usesInterceptor == Boolish.no) {
          handleVirtual(node);
        } else if (usesInterceptor == Boolish.yes) {
          handleMultiInterceptor(node);
        } else {
          handleDynamic(node);
        }
      }
      return;
    }
    handleDynamic(node);
  }

  void handleThisProperty(Send node, Selector selector) {
    handleDynamicProperty(node, node.receiver, selector);
  }

  void handleIndex(Node node) {
    handleDynamic(node);
  }

  void handleOperator(Node node) {
    handleDynamic(node);
  }

  void handleInvoke(Node node) {
    handleDynamic(node);
  }

  void handleEquals(Node node) {
    handleDynamic(node);
  }

  // Constructors

  void visitAbstractClassConstructorInvoke(NewExpression node,
      ConstructorElement element, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleConstructor(node);
  }

  void visitBoolFromEnvironmentConstructorInvoke(NewExpression node,
      BoolFromEnvironmentConstantExpression constant, T arg) {
    handleConstructor(node);
  }

  void visitConstConstructorInvoke(
      NewExpression node, ConstructedConstantExpression constant, T arg) {
    handleConstructor(node);
  }

  void visitGenerativeConstructorInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleConstructor(node);
  }

  void visitIntFromEnvironmentConstructorInvoke(NewExpression node,
      IntFromEnvironmentConstantExpression constant, T arg) {
    handleConstructor(node);
  }

  void visitRedirectingFactoryConstructorInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type,
      ConstructorElement effectiveTarget, InterfaceType effectiveTargetType,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleConstructor(node);
  }

  void visitRedirectingGenerativeConstructorInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleConstructor(node);
  }

  void visitStringFromEnvironmentConstructorInvoke(NewExpression node,
      StringFromEnvironmentConstantExpression constant, T arg) {
    handleConstructor(node);
  }

  // Dynamic sends


  // TODO(sigmund): many many things to add:
  // -- support for operators, indexers, etc.
  // -- logic about nullables
  // -- int, JSArray
  // -- all interceptors

  void visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, T arg) {
    handleOperator(node);
  }

  void visitCompoundIndexSet(SendSet node, Node receiver, Node index,
      AssignmentOperator operator, Node rhs, T arg) {
    handleIndex(node); // t1 = receiver[index]
    handleOperator(node); // t2 = t1 op rhs
    handleIndex(node); // receiver[index] = t2
  }

  void visitDynamicPropertyCompound(Send node, Node receiver,
      Name name, AssignmentOperator operator, Node rhs, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }


  void visitDynamicPropertyGet(
      Send node, Node receiver, Name name, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
  }

  void visitDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, T arg) {
    handleDynamicProperty(node, receiver, selector);
  }

  void visitDynamicPropertyPostfix(Send node, Node receiver,
       Name name, IncDecOperator operator, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitDynamicPropertyPrefix(Send node, Node receiver, Name name,
      IncDecOperator operator, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, T arg) {
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, T arg) {
    // read to check for null?
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitEquals(Send node, Node left, Node right, T arg) {
    handleEquals(node);
  }

  void visitExpressionInvoke(Send node, Node expression, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitIfNotNullDynamicPropertyCompound(Send node, Node receiver,
      Name name, AssignmentOperator operator, Node rhs, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitIfNotNullDynamicPropertyGet(
      Send node, Node receiver, Name name, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
  }

  void visitIfNotNullDynamicPropertyInvoke(
      Send node, Node receiver, NodeList arguments, Selector selector, T arg) {
    handleDynamicProperty(node, receiver, selector);
  }

  void visitIfNotNullDynamicPropertyPostfix(Send node, Node receiver, Name name,
      IncDecOperator operator, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitIfNotNullDynamicPropertyPrefix(Send node, Node receiver, Name name,
      IncDecOperator operator, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleOperator(node);
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitIfNotNullDynamicPropertySet(
      SendSet node, Node receiver, Name name, Node rhs, T arg) {
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitIfNotNullDynamicPropertySetIfNull(
      Send node, Node receiver, Name name, Node rhs, T arg) {
    handleDynamicProperty(node, receiver, new Selector.getter(name));
    handleDynamicProperty(node, receiver, new Selector.setter(name));
  }

  void visitIndex(Send node, Node receiver, Node index, T arg) {
    handleIndex(node);
  }

  void visitIndexPostfix(
      Send node, Node receiver, Node index, IncDecOperator operator, T arg) {
    handleIndex(node);
    handleOperator(node);
    handleIndex(node);
  }

  void visitIndexPrefix(
      Send node, Node receiver, Node index, IncDecOperator operator, T arg) {
    handleIndex(node);
    handleOperator(node);
    handleIndex(node);
  }

  void visitIndexSet(SendSet node, Node receiver, Node index, Node rhs, T arg) {
    handleIndex(node);
  }

  void visitLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitLocalVariableInvoke(Send node, LocalVariableElement variable,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitNotEquals(Send node, Node left, Node right, T arg) {
    handleEquals(node);
  }

  void visitParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitParameterInvoke(Send node, ParameterElement parameter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleLocal(node);
  }

  void visitStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitStaticFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitStaticGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitStaticGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitStaticGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitStaticGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldFieldCompound(Send node, FieldElement readField,
      FieldElement writtenField, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldFieldPostfix(Send node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldFieldPrefix(Send node, FieldElement readField,
      FieldElement writtenField, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldFieldSetIfNull(
      Send node, FieldElement readField, FieldElement writtenField, Node rhs,
      T arg) {
    handleSuper(node);
    handleNSMSuper(node, readField.enclosingClass);
  }

  void visitSuperFieldInvoke(Send node, FieldElement field, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldSetterCompound(Send node, FieldElement field,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldSetterPostfix(Send node, FieldElement field,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldSetterPrefix(Send node, FieldElement field,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperFieldSetterSetIfNull(Send node, FieldElement field,
      FunctionElement setter, Node rhs, T arg) {
    handleSuper(node);
    handleSuper(node);
  }

  void visitSuperGetterFieldCompound(Send node, FunctionElement getter,
      FieldElement field, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterFieldPostfix(Send node, FunctionElement getter,
      FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterFieldPrefix(Send node, FunctionElement getter,
      FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterFieldSetIfNull(Send node, FunctionElement getter,
      FieldElement field, Node rhs, T arg) {
    handleSuper(node);
    handleSuper(node);
  }

  void visitSuperGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitSuperGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperGetterSetterSetIfNull(Send node, FunctionElement getter,
      FunctionElement setter, Node rhs, T arg) {
    handleSuper(node);
    handleSuper(node);
  }

  void visitSuperIndexPostfix(Send node, MethodElement indexFunction,
      MethodElement indexSetFunction, Node index, IncDecOperator operator,
      T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperIndexPrefix(Send node, MethodElement indexFunction,
      MethodElement indexSetFunction, Node index, IncDecOperator operator,
      T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitSuperMethodSetterCompound(Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleNSMSuper(node, method.enclosingClass);
    handleSuper(node);
  }

  void visitSuperMethodSetterPostfix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleNSMSuper(node, method.enclosingClass);
    handleSuper(node);
  }

  void visitSuperMethodSetterPrefix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleNSMSuper(node, method.enclosingClass);
    handleSuper(node);
  }

  void visitSuperMethodSetterSetIfNull(Send node, FunctionElement method,
      FunctionElement setter, Node rhs, T arg) {
    handleSuper(node);
    handleSuper(node);
  }

  void visitThisPropertyCompound(Send node, Name name,
      AssignmentOperator operator, Node rhs, T arg) {
    handleThisProperty(node, new Selector.getter(name));
    handleOperator(node);
    handleThisProperty(node, new Selector.setter(name));
  }

  void visitThisPropertyInvoke(
      Send node, NodeList arguments, Selector selector, T arg) {
    handleThisProperty(node, selector);
  }

  void visitThisPropertyPostfix(Send node, Name name, IncDecOperator operator,
      T arg) {
    handleThisProperty(node, new Selector.getter(name));
    handleOperator(node);
    handleThisProperty(node, new Selector.setter(name));
  }

  void visitThisPropertyPrefix(Send node, Name name, IncDecOperator operator,
      T arg) {
    handleThisProperty(node, new Selector.getter(name));
    handleOperator(node);
    handleThisProperty(node, new Selector.setter(name));
  }

  void visitTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitTopLevelFieldInvoke(Send node, FieldElement field,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitTopLevelGetterInvoke(Send node, FunctionElement getter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleInvoke(node);
  }

  void visitTopLevelGetterSetterCompound(Send node, FunctionElement getter,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitTopLevelGetterSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitTopLevelGetterSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleStatic(node);
  }

  void visitUnary(Send node, UnaryOperator operator, Node expression, T arg) {
    handleDynamic(node);
  }

  // Local variable sends

  void visitLocalFunctionGet(Send node, LocalFunctionElement function, T arg) {
    handleLocal(node);
  }

  void visitLocalFunctionInvoke(Send node, LocalFunctionElement function,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleLocal(node);
  }

  void visitLocalVariableGet(Send node, LocalVariableElement variable, T arg) {
    handleLocal(node);
  }

  void visitLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, T arg) {
    handleLocal(node);
  }

  void visitLocalVariableSetIfNull(
      SendSet node, LocalVariableElement variable, Node rhs, T arg) {
    handleLocal(node);
    handleLocal(node);
  }

  void visitParameterGet(Send node, ParameterElement parameter, T arg) {
    handleLocal(node);
  }

  void visitParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, T arg) {
    handleLocal(node);
  }

  void visitParameterSetIfNull(
      Send node, ParameterElement parameter, Node rhs, T arg) {
    handleLocal(node);
    handleLocal(node);
  }

  // Super monomorphic sends

  void visitSuperBinary(Send node, FunctionElement function,
      BinaryOperator operator, Node argument, T arg) {
    handleSuper(node);
  }

  void visitSuperEquals(
      Send node, FunctionElement function, Node argument, T arg) {
    handleSuper(node);
  }

  void visitSuperFieldGet(Send node, FieldElement field, T arg) {
    handleSuper(node);
  }

  void visitSuperFieldSet(SendSet node, FieldElement field, Node rhs, T arg) {
    handleSuper(node);
  }

  void visitSuperFieldSetIfNull(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleSuper(node);
    handleSuper(node);
  }

  void visitSuperGetterGet(Send node, FunctionElement getter, T arg) {
    handleSuper(node);
  }

  void visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, T arg) {
    handleSuper(node);
  }

  void visitSuperIndex(Send node, FunctionElement function, Node index, T arg) {
    handleSuper(node);
  }

  void visitSuperIndexSet(
      SendSet node, FunctionElement function, Node index, Node rhs, T arg) {
    handleSuper(node);
  }

  void visitSuperMethodGet(Send node, MethodElement method, T arg) {
    handleSuper(node);
  }

  void visitSuperMethodInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleSuper(node);
  }

  void visitSuperNotEquals(
      Send node, FunctionElement function, Node argument, T arg) {
    handleSuper(node);
  }

  void visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, T arg) {
    handleSuper(node);
  }

  void visitSuperUnary(
      Send node, UnaryOperator operator, FunctionElement function, T arg) {
    handleSuper(node);
  }

  // Statically known "no such method" sends

  void visitConstructorIncompatibleInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitFinalLocalVariableCompound(Send node, LocalVariableElement variable,
      AssignmentOperator operator, Node rhs, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalLocalVariablePostfix(Send node, LocalVariableElement variable,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalLocalVariablePrefix(Send node, LocalVariableElement variable,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalLocalVariableSet(
      SendSet node, LocalVariableElement variable, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitFinalLocalVariableSetIfNull(
      SendSet node, LocalVariableElement variable, Node rhs, T arg) {
    handleLocal(node); // read for null
    handleNSMError(node); // set fails
  }

  void visitFinalParameterCompound(Send node, ParameterElement parameter,
      AssignmentOperator operator, Node rhs, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalParameterPostfix(
      Send node, ParameterElement parameter, IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalParameterPrefix(
      Send node, ParameterElement parameter, IncDecOperator operator, T arg) {
    handleLocal(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalParameterSet(
      SendSet node, ParameterElement parameter, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitFinalParameterSetIfNull(
      SendSet node, ParameterElement parameter, Node rhs, T arg) {
    handleLocal(node);
    handleNSMError(node);
  }

  void visitFinalStaticFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalStaticFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalStaticFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitFinalStaticFieldSetIfNull(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitFinalSuperFieldSetIfNull(Send node, FieldElement field,
      Node rhs, T arg) {
    handleSuper(node);
    handleNSMSuper(node, field.enclosingClass);
  }

  void visitFinalSuperFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, field.enclosingClass);
  }

  void visitFinalSuperFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, field.enclosingClass);
  }

  void visitFinalSuperFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, field.enclosingClass);
  }

  void visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleNSMSuper(node, field.enclosingClass);
  }

  void visitFinalTopLevelFieldCompound(Send node, FieldElement field,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalTopLevelFieldPostfix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalTopLevelFieldPrefix(
      Send node, FieldElement field, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleOperator(node);
    handleNSMError(node);
  }

  void visitFinalTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitFinalTopLevelFieldSetIfNull(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitTopLevelGetterSetterSetIfNull(Send node, FunctionElement getter,
      FunctionElement setter, Node rhs, T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitTopLevelMethodSetterSetIfNull(Send node, FunctionElement method,
      FunctionElement setter, Node rhs, T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitTopLevelMethodSetIfNull(Send node, FunctionElement method,
      Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitLocalFunctionIncompatibleInvoke(Send node,
      LocalFunctionElement function, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitLocalFunctionCompound(Send node, LocalFunctionElement function,
      AssignmentOperator operator, Node rhs, T arg) {
    handleLocal(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitLocalFunctionPostfix(Send node, LocalFunctionElement function,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitLocalFunctionPrefix(Send node, LocalFunctionElement function,
      IncDecOperator operator, T arg) {
    handleLocal(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitLocalFunctionSet(
      SendSet node, LocalFunctionElement function, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitLocalFunctionSetIfNull(
      SendSet node, LocalFunctionElement function, Node rhs, T arg) {
    handleLocal(node);
    handleNSMError(node);
  }

  void visitStaticFunctionIncompatibleInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitStaticFunctionSet(
      Send node, MethodElement function, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitStaticMethodCompound(Send node, MethodElement method,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node); // operator on a method closure yields nSM
    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitStaticMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitStaticMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitStaticMethodSetterCompound(Send node, MethodElement method,
      MethodElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node); // operator on a method closure yields nSM
    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitStaticMethodSetterPostfix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitStaticMethodSetterPrefix(Send node, FunctionElement getter,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitStaticSetterGet(Send node, FunctionElement setter, T arg) {
    handleNSMError(node);
  }

  void visitStaticSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitSuperMethodCompound(Send node, FunctionElement method,
      AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);

    // An operator send on a method closure yields nSM
    handleNSMSuper(node, method.enclosingClass);

    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitSuperMethodIncompatibleInvoke(Send node, MethodElement method,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMSuper(node, method.enclosingClass);
  }

  void visitSuperMethodPostfix(
      Send node, FunctionElement method, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleNSMSuper(node, method.enclosingClass);
    handleNoSend(node);
  }

  void visitSuperMethodPrefix(
      Send node, FunctionElement method, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleNSMSuper(node, method.enclosingClass);
    handleNoSend(node);
  }

  void visitSuperMethodSet(Send node, MethodElement method, Node rhs, T arg) {
    handleNSMSuper(node, method.enclosingClass);
  }

  void visitSuperMethodSetIfNull(
      Send node, MethodElement method, Node rhs, T arg) {
    handleNSMSuper(node, method.enclosingClass);
  }

  void visitSuperSetterGet(Send node, FunctionElement setter, T arg) {
    handleNSMSuper(node, setter.enclosingClass);
  }

  void visitSuperSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMSuper(node, setter.enclosingClass);
  }

  void visitTopLevelFunctionIncompatibleInvoke(Send node,
      MethodElement function, NodeList arguments, CallStructure callStructure,
      T arg) {
    handleNSMError(node);
  }

  void visitTopLevelFunctionSet(
      Send node, MethodElement function, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitTopLevelGetterSet(
      SendSet node, FunctionElement getter, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitTopLevelMethodCompound(Send node, FunctionElement method,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node); // operator on a method closure yields nSM
    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitTopLevelMethodPostfix(
      Send node, MethodElement method, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTopLevelMethodPrefix(
      Send node, MethodElement method, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTopLevelMethodSetterCompound(Send node, FunctionElement method,
      FunctionElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node); // operator on a method closure yields nSM
    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitTopLevelMethodSetterPostfix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTopLevelMethodSetterPrefix(Send node, FunctionElement method,
      FunctionElement setter, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTopLevelSetterGet(Send node, FunctionElement setter, T arg) {
    handleNSMError(node);
  }

  void visitTopLevelSetterInvoke(Send node, FunctionElement setter,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitTypeVariableTypeLiteralCompound(Send node,
      TypeVariableElement element, AssignmentOperator operator, Node rhs,
      T arg) {
    handleTypeVariable(node);
    handleNSMError(node); // operator on a method closure yields nSM
    handleNoSend(node); // setter is not invoked, don't count it.
  }

  void visitTypeVariableTypeLiteralGet(
      Send node, TypeVariableElement element, T arg) {
    handleTypeVariable(node);
  }

  void visitTypeVariableTypeLiteralInvoke(Send node,
      TypeVariableElement element, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitTypeVariableTypeLiteralPostfix(
      Send node, TypeVariableElement element, IncDecOperator operator, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTypeVariableTypeLiteralPrefix(
      Send node, TypeVariableElement element, IncDecOperator operator, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTypeVariableTypeLiteralSet(
      SendSet node, TypeVariableElement element, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitTypeVariableTypeLiteralSetIfNull(
      SendSet node, TypeVariableElement element, Node rhs, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
  }

  void visitTypedefTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, T arg) {
    handleTypeVariable(node);
  }

  void visitTypedefTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitTypedefTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTypedefTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleTypeVariable(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitTypedefTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitTypedefTypeLiteralSetIfNull(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitUnresolvedClassConstructorInvoke(NewExpression node,
      Element element, DartType type, NodeList arguments, Selector selector,
      T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedCompound(Send node, Element element,
      AssignmentOperator operator, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedConstructorInvoke(NewExpression node, Element constructor,
      DartType type, NodeList arguments, Selector selector, T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedGet(Send node, Element element, T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedInvoke(Send node, Element element, NodeList arguments,
      Selector selector, T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedPostfix(
      Send node, Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedPrefix(
      Send node, Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedRedirectingFactoryConstructorInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedSet(Send node, Element element, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitUnresolvedSetIfNull(Send node, Element element, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticGetterSetIfNull(Send node, Element element,
      MethodElement setter, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedStaticSetterSetIfNull(Send node, MethodElement getter,
      Element element, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitUnresolvedSuperBinary(Send node, Element element,
      BinaryOperator operator, Node argument, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperCompound(Send node, Element element,
      AssignmentOperator operator, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    // TODO(sigmund): we should only count the next 2 if we know that the
    // superclass has a nSM method.
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperCompoundIndexSet(Send node, Element element,
      Node index, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleNoSend(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperGet(Send node, Element element, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetIfNull(
      Send node, Element element, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleNoSend(node);
  }

  void visitUnresolvedSuperGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterCompoundIndexSet(Send node, Element element,
      MethodElement setter, Node index, AssignmentOperator operator, Node rhs,
      T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterIndexPostfix(Send node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterIndexPrefix(Send node, Element element,
      MethodElement setter, Node index, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleSuper(node);
  }

  void visitUnresolvedSuperGetterSetIfNull(Send node, Element element,
      MethodElement setter, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleSuper(node);
  }

  void visitUnresolvedSuperIndex(
      Send node, Element element, Node index, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperIndexPostfix(
      Send node, Element element, Node index, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperIndexPrefix(
      Send node, Element element, Node index, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperIndexSet(
      Send node, Element element, Node index, Node rhs, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperInvoke(Send node, Element element,
      NodeList arguments, Selector selector, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperPostfix(
      Send node, Element element, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperPrefix(
      Send node, Element element, IncDecOperator operator, T arg) {
    handleNSMSuper(node, element.enclosingClass);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterCompoundIndexSet(Send node,
      MethodElement getter, Element element, Node index,
      AssignmentOperator operator, Node rhs, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterIndexPostfix(Send node,
      MethodElement indexFunction, Element element, Node index,
      IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterIndexPrefix(Send node,
      MethodElement indexFunction, Element element, Node index,
      IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleSuper(node);
    handleOperator(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperSetterSetIfNull(Send node, MethodElement getter,
      Element element, Node rhs, T arg) {
    handleSuper(node);
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedSuperUnary(
      Send node, UnaryOperator operator, Element element, T arg) {
    handleNSMSuper(node, element.enclosingClass);
  }

  void visitUnresolvedTopLevelGetterCompound(Send node, Element element,
      MethodElement setter, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelGetterPostfix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelGetterPrefix(Send node, Element element,
      MethodElement setter, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelGetterSetIfNull(Send node, Element element,
      MethodElement setter, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelSetterCompound(Send node, MethodElement getter,
      Element element, AssignmentOperator operator, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelSetterPostfix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelSetterPrefix(Send node, MethodElement getter,
      Element element, IncDecOperator operator, T arg) {
    handleNSMError(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void visitUnresolvedTopLevelSetterSetIfNull(Send node, MethodElement getter,
      Element element, Node rhs, T arg) {
    handleNSMError(node);
    handleNoSend(node);
  }

  // Static

  void visitConstantGet(Send node, ConstantExpression constant, T arg) {
    handleStatic(node);
  }

  void visitConstantInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStreucture, T arg) {
    handleStatic(node);
  }

  void visitFactoryConstructorInvoke(NewExpression node,
      ConstructorElement constructor, InterfaceType type, NodeList arguments,
      CallStructure callStructure, T arg) {
    handleStatic(node);
  }

  void visitStaticFieldGet(Send node, FieldElement field, T arg) {
    handleStatic(node);
  }

  void visitStaticFieldSet(SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
  }

  void visitStaticFieldSetIfNull(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitStaticFunctionGet(Send node, MethodElement function, T arg) {
    handleStatic(node);
  }

  void visitStaticFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleStatic(node);
  }

  void visitStaticGetterGet(Send node, FunctionElement getter, T arg) {
    handleStatic(node);
  }

  void visitStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, T arg) {
    handleStatic(node);
  }

  void visitStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, T arg) {
    handleStatic(node);
  }

  void visitStaticGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitStaticMethodSetterSetIfNull(
      Send node,
      MethodElement method,
      MethodElement setter,
      Node rhs,
      T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitStaticMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitTopLevelFieldGet(Send node, FieldElement field, T arg) {
    handleStatic(node);
  }

  void visitTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
  }

  void visitTopLevelFieldSetIfNull(
      SendSet node, FieldElement field, Node rhs, T arg) {
    handleStatic(node);
    handleStatic(node);
  }

  void visitTopLevelFunctionGet(Send node, MethodElement function, T arg) {
    handleStatic(node);
  }

  void visitTopLevelFunctionInvoke(Send node, MethodElement function,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleStatic(node);
  }

  void visitTopLevelGetterGet(Send node, FunctionElement getter, T arg) {
    handleStatic(node);
  }

  void visitTopLevelSetterSet(
      SendSet node, FunctionElement setter, Node rhs, T arg) {
    handleStatic(node);
  }

  // Virtual

  void visitSuperCompoundIndexSet(SendSet node, MethodElement getter,
      MethodElement setter, Node index, AssignmentOperator operator, Node rhs,
      T arg) {
    handleSuper(node);
    handleOperator(node);
    handleSuper(node);
  }

  void visitThisGet(Identifier node, T arg) {
    handleLocal(node); // TODO(sigmund): should we add a metric for "this"?
  }

  void visitThisInvoke(
      Send node, NodeList arguments, CallStructure callStructure, T arg) {
    // TODO(sigmund): implement (treat like this.call())
    handleDynamic(node);
  }

  void visitThisPropertyGet(Send node, Name name, T arg) {
    handleThisProperty(node, new Selector.getter(name));
  }

  void visitThisPropertySet(SendSet node, Name name, Node rhs, T arg) {
    handleThisProperty(node, new Selector.setter(name));
  }

  void visitThisPropertySetIfNull(Send node, Name name, Node rhs, T arg) {
    handleThisProperty(node, new Selector.getter(name));
    handleThisProperty(node, new Selector.setter(name));
  }

  // Not count

  void errorNonConstantConstructorInvoke(NewExpression node, Element element,
      DartType type, NodeList arguments, CallStructure callStructure, T arg) {
    handleNoSend(node);
  }

  void errorUndefinedBinaryExpression(
      Send node, Node left, Operator operator, Node right, T arg) {
    handleNoSend(node);
  }

  void errorUndefinedUnaryExpression(
      Send node, Operator operator, Node expression, T arg) {
    handleNoSend(node);
  }

  void errorInvalidGet(
      Send node,
      ErroneousElement error,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidInvoke(
      Send node,
      ErroneousElement error,
      NodeList arguments,
      Selector selector,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidSet(
      Send node,
      ErroneousElement error,
      Node rhs,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidSetIfNull(
      Send node, ErroneousElement error, Node rhs, T arg) {
    handleNoSend(node);
    handleNoSend(node);
  }


  void errorInvalidPrefix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidPostfix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidCompound(
      Send node,
      ErroneousElement error,
      AssignmentOperator operator,
      Node rhs,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidUnary(
      Send node,
      UnaryOperator operator,
      ErroneousElement error,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidEquals(
      Send node,
      ErroneousElement error,
      Node right,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidNotEquals(
      Send node,
      ErroneousElement error,
      Node right,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidBinary(
      Send node,
      ErroneousElement error,
      BinaryOperator operator,
      Node right,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidIndex(
      Send node,
      ErroneousElement error,
      Node index,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      Node rhs,
      T arg) {
    handleNoSend(node);
  }

  void errorInvalidCompoundIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      T arg) {
    handleNoSend(node);
    handleNoSend(node);
    handleNoSend(node);
  }

  void errorInvalidIndexPrefix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      T arg) {
    handleNoSend(node);
    handleNoSend(node);
  }

  void errorInvalidIndexPostfix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      T arg) {
    handleNoSend(node);
    handleNoSend(node);
  }

  void previsitDeferredAccess(
      Send node,
      PrefixElement prefix,
      T arg) {
  }


  void visitAs(Send node, Node expression, DartType type, T arg) {
    handleNoSend(node);
  }

  void visitClassTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitClassTypeLiteralGet(Send node, ConstantExpression constant, T arg) {
    handleStatic(node);
  }

  void visitClassTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitClassTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitClassTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitClassTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitClassTypeLiteralSetIfNull(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitDynamicTypeLiteralCompound(Send node, ConstantExpression constant,
      AssignmentOperator operator, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, T arg) {
    handleNSMError(node);
  }

  void visitDynamicTypeLiteralInvoke(Send node, ConstantExpression constant,
      NodeList arguments, CallStructure callStructure, T arg) {
    handleNSMError(node);
  }

  void visitDynamicTypeLiteralPostfix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitDynamicTypeLiteralPrefix(
      Send node, ConstantExpression constant, IncDecOperator operator, T arg) {
    handleStatic(node);
    handleNSMError(node);
    handleNoSend(node);
  }

  void visitDynamicTypeLiteralSet(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleNSMError(node);
  }

  void visitDynamicTypeLiteralSetIfNull(
      SendSet node, ConstantExpression constant, Node rhs, T arg) {
    handleStatic(node);
    handleNSMError(node);
  }

  void visitIfNull(Send node, Node left, Node right, T arg) {
    handleNoSend(node);
  }

  void visitIs(Send node, Node expression, DartType type, T arg) {
    handleNoSend(node);
  }

  void visitIsNot(Send node, Node expression, DartType type, T arg) {
    handleNoSend(node);
  }

  void visitLogicalAnd(Send node, Node left, Node right, T arg) {
    handleNoSend(node);
  }

  void visitLogicalOr(Send node, Node left, Node right, T arg) {
    handleNoSend(node);
  }

  void visitNot(Send node, Node expression, T arg) {
    handleNoSend(node);
  }

  String last;
  _checkInvariant(node, String msg) {
    msg = '$msg ${recursiveDiagnosticString(measurements, Metric.send)}';
    if (!measurements.checkInvariant(Metric.send) ||
        !measurements.checkInvariant(Metric.monomorphicSend) ||
        !measurements.checkInvariant(Metric.polymorphicSend)) {
      reporter.reportErrorMessage(node,
          MessageKind.GENERIC, {'text': 'bad\n-- $msg\nlast:\n-- $last\n'});
      last = msg;
    } else {
      last = msg;
    }
  }
}

/// Visitor that collects statistics for a single function.
class _StatsTraversalVisitor<T> extends TraversalVisitor<dynamic, T>
    implements SemanticSendVisitor<dynamic, T> {
  final DiagnosticReporter reporter;
  final _StatsVisitor statsVisitor;
  Measurements get measurements => statsVisitor.measurements;
  _StatsTraversalVisitor(
      Compiler compiler, TreeElements elements, Uri sourceUri)
      : reporter = compiler.reporter,
        statsVisitor = new _StatsVisitor(compiler.reporter, elements,
            // TODO(sigmund): accept a list of analyses, so we can compare them
            // together.
            true
            ? new TrustTypesAnalysisResult(elements, compiler.world)
            : new NaiveAnalysisResult(),
            sourceUri),
        super(elements);

  void visitSend(Send node) {
    try {
      node.accept(statsVisitor);
    } catch (e, t) {
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC, {'text': '$e\n$t'});
    }
    super.visitSend(node);
  }

  void visitNewExpression(NewExpression node) {
    try {
      node.accept(statsVisitor);
    } catch (e, t) {
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC, {'text': '$e\n$t'});
    }
    super.visitNewExpression(node);
  }
}

/// Helper to visit elements recursively
// TODO(sigmund): maybe generalize and move to elements/visitor.dart?
abstract class RecursiveElementVisitor<R, A> extends ElementVisitor<R, A> {

  @override
  R visitWarnOnUseElement(WarnOnUseElement e, A arg) =>
      e.wrappedElement.accept(this, arg);

  R visitScopeContainerElement(ScopeContainerElement e, A arg) {
    e.forEachLocalMember((l) => l.accept(this, arg));
    return null;
  }

  @override
  R visitCompilationUnitElement(CompilationUnitElement e, A arg) {
    e.forEachLocalMember((l) => l.accept(this, arg));
    return null;
  }

  @override
  R visitLibraryElement(LibraryElement e, A arg) {
    e.implementation.compilationUnits.forEach((u) => u.accept(this, arg));
    return null;
  }

  @override
  R visitVariableElement(VariableElement e, A arg) => null;

  @override
  R visitParameterElement(ParameterElement e, A arg) => null;

  @override
  R visitFormalElement(FormalElement e, A arg) => null;

  @override
  R visitFieldElement(FieldElement e, A arg) => null;

  @override
  R visitFieldParameterElement(InitializingFormalElement e, A arg) => null;

  @override
  R visitAbstractFieldElement(AbstractFieldElement e, A arg) => null;

  @override
  R visitFunctionElement(FunctionElement e, A arg) => null;

  @override
  R visitConstructorElement(ConstructorElement e, A arg) {
    return visitFunctionElement(e, arg);
  }

  @override
  R visitConstructorBodyElement(ConstructorBodyElement e, A arg) {
    return visitFunctionElement(e.constructor, arg);
  }

  @override
  R visitClassElement(ClassElement e, A arg) {
    return visitScopeContainerElement(e, arg);
  }

  @override
  R visitEnumClassElement(EnumClassElement e, A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitBoxFieldElement(BoxFieldElement e, A arg) => null;

  @override
  R visitClosureClassElement(ClosureClassElement e, A arg) {
    return visitClassElement(e, arg);
  }

  @override
  R visitClosureFieldElement(ClosureFieldElement e, A arg) {
    return visitVariableElement(e, arg);
  }
}

// TODO(sigmund): get rid of debug messages.
_debug(String message) {
  print('[33mdebug:[0m $message');
}
