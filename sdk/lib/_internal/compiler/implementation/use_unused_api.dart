// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file use methods that aren't used by dart2js.dart, but that we wish to
/// keep anyway. This might be general API that isn't currently in use,
/// debugging aids, or API only used for testing (see TODO below).

library dart2js.use_unused_api;

import '../compiler.dart' as api;

import 'dart2js.dart' as dart2js;

import 'dart2jslib.dart' as dart2jslib;

import 'tree/tree.dart' as tree;

import 'util/util.dart' as util;

import 'elements/elements.dart' as elements;

import 'elements/visitor.dart' as elements_visitor;

import 'js/js.dart' as js;

import 'inferrer/concrete_types_inferrer.dart' as concrete_types_inferrer;

import 'colors.dart' as colors;

import 'filenames.dart' as filenames;

import 'dart_types.dart' as dart_types;

import 'universe/universe.dart' as universe;

import 'inferrer/type_graph_inferrer.dart' as type_graph_inferrer;

import 'source_file_provider.dart' as source_file_provider;

import 'ssa/ssa.dart' as ssa;

import 'cps_ir/cps_ir_nodes_sexpr.dart' as cps_ir_nodes_sexpr;

import 'cps_ir/cps_ir_builder.dart' as ir_builder;

class ElementVisitor extends elements_visitor.ElementVisitor {
  visitElement(e) {}
}

void main(List<String> arguments) {
  useApi();
  dart2js.main(arguments);
  useConstant(null, null);
  useNode(null);
  useUtil(null);
  useSetlet(null);
  useElementVisitor(new ElementVisitor());
  useJs(new js.Program(null));
  useJs(new js.Blob(null));
  useJs(new js.NamedFunction(null, null));
  useConcreteTypesInferrer(null);
  useColor();
  useFilenames();
  useSsa(null);
  useCodeBuffer(null);
  usedByTests();
  useElements(null, null);
  useIr(null, null);
  useCompiler(null);
}

useApi() {
  api.ReadStringFromUri uri;
}

void useConstant(dart2jslib.Constant constant, dart2jslib.ConstantSystem cs) {
  constant.isObject;
  cs.isBool(constant);
}

void useNode(tree.Node node) {
  node
    ..asBreakStatement()
    ..asCascade()
    ..asCatchBlock()
    ..asClassNode()
    ..asCombinator()
    ..asConditional()
    ..asContinueStatement()
    ..asErrorExpression()
    ..asExport()
    ..asFor()
    ..asFunctionDeclaration()
    ..asIf()
    ..asLabeledStatement()
    ..asLibraryDependency()
    ..asLibraryName()
    ..asLiteralDouble()
    ..asLiteralList()
    ..asLiteralMap()
    ..asLiteralMapEntry()
    ..asLiteralNull()
    ..asLiteralSymbol()
    ..asMetadata()
    ..asModifiers()
    ..asPart()
    ..asPartOf()
    ..asRethrow()
    ..asStatement()
    ..asStringInterpolation()
    ..asStringInterpolationPart()
    ..asStringJuxtaposition()
    ..asStringNode()
    ..asSwitchCase()
    ..asSwitchStatement()
    ..asTryStatement()
    ..asTypeAnnotation()
    ..asTypeVariable()
    ..asTypedef()
    ..asWhile();
}

void useUtil(util.Link link) {
  link.reversePrependAll(link);
}

void useSetlet(util.Setlet setlet) {
  setlet.difference(setlet);
}

void useElementVisitor(ElementVisitor visitor) {
  visitor
    ..visit(null)
    ..visitAbstractFieldElement(null)
    ..visitAmbiguousElement(null)
    ..visitBoxFieldElement(null)
    ..visitClassElement(null)
    ..visitClosureClassElement(null)
    ..visitClosureFieldElement(null)
    ..visitCompilationUnitElement(null)
    ..visitConstructorBodyElement(null)
    ..visitElement(null)
    ..visitErroneousElement(null)
    ..visitFieldParameterElement(null)
    ..visitFunctionElement(null)
    ..visitLibraryElement(null)
    ..visitMixinApplicationElement(null)
    ..visitPrefixElement(null)
    ..visitScopeContainerElement(null)
    ..visitTypeDeclarationElement(null)
    ..visitTypeVariableElement(null)
    ..visitTypedefElement(null)
    ..visitVariableElement(null)
    ..visitWarnOnUseElement(null);
}

useJs(js.Node node) {
  node.asVariableUse();
}

useConcreteTypesInferrer(concrete_types_inferrer.ConcreteTypesInferrer c) {
  c.debug();
}

useColor() {
  colors.white(null);
  colors.blue(null);
  colors.yellow(null);
  colors.black(null);
}

useFilenames() {
  filenames.appendSlash(null);
}

useSsa(ssa.HInstruction instruction) {
  instruction.isConstantNumber();
  new ssa.HAndOrBlockInformation(null, null, null);
  new ssa.HStatementSequenceInformation(null);
}

useCodeBuffer(dart2jslib.CodeBuffer buffer) {
  buffer.writeln();
}

usedByTests() {
  // TODO(ahe): We should try to avoid including API used only for tests. In
  // most cases, such API can be moved to a test library.
  dart2jslib.World world = null;
  dart2jslib.Compiler compiler = null;
  compiler.currentlyInUserCode();
  type_graph_inferrer.TypeGraphInferrer typeGraphInferrer = null;
  source_file_provider.SourceFileProvider sourceFileProvider = null;
  world.hasAnyUserDefinedGetter(null);
  typeGraphInferrer.getCallersOf(null);
  dart_types.Types.sorted(null);
  new dart_types.Types(compiler).copy(compiler);
  new universe.TypedSelector.subclass(null, null, compiler);
  new universe.TypedSelector.subtype(null, null, compiler);
  new universe.TypedSelector.exact(null, null, compiler);
  sourceFileProvider.readStringFromUri(null);
}

useElements(elements.ClassElement e, elements.Name n) {
  e.lookupClassMember(null);
  e.lookupInterfaceMember(null);
  n.isAccessibleFrom(null);
}

useIr(cps_ir_nodes_sexpr.SExpressionStringifier stringifier,
      ir_builder.IrBuilderTask task) {
  new cps_ir_nodes_sexpr.SExpressionStringifier();
  stringifier
    ..newContinuationName()
    ..newValueName()
    ..visitConstant(null)
    ..visitContinuation(null)
    ..visitDefinition(null)
    ..visitExpression(null)
    ..visitFunctionDefinition(null)
    ..visitInvokeStatic(null)
    ..visitLetCont(null)
    ..visitNode(null)
    ..visitParameter(null);
  task
    ..hasIr(null)
    ..getIr(null);
}

useCompiler(dart2jslib.Compiler compiler) {
  compiler.libraryLoader.reset();
  compiler.libraryLoader.lookupLibrary(null);
}