// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file use methods that aren't used by dart2js.dart, but that we wish to
/// keep anyway. This might be general API that isn't currently in use,
/// debugging aids, or API only used for testing (see TODO below).

library dart2js.use_unused_api;

import '../compiler.dart' as api;

import 'colors.dart' as colors;
import 'constants/constant_system.dart' as constants;
import 'constants/expressions.dart' as constants;
import 'constants/values.dart' as constants;
import 'cps_ir/cps_ir_builder.dart' as ir_builder;
import 'cps_ir/cps_ir_builder_task.dart' as ir_builder;
import 'tree_ir/tree_ir_nodes.dart' as tree_ir;
import 'dart_types.dart' as dart_types;
import 'dart2js.dart' as dart2js;
import 'dart2jslib.dart' as dart2jslib;
import 'elements/elements.dart' as elements;
import 'elements/modelx.dart' as modelx;
import 'elements/visitor.dart' as elements_visitor;
import 'filenames.dart' as filenames;
import 'inferrer/concrete_types_inferrer.dart' as concrete_types_inferrer;
import 'inferrer/type_graph_inferrer.dart' as type_graph_inferrer;
import 'io/code_output.dart' as io;
import 'io/source_map_builder.dart' as io;
import 'js/js.dart' as js;
import 'js_backend/js_backend.dart' as js_backend;
import 'js_emitter/js_emitter.dart' as js_emitter;
import 'js_emitter/program_builder.dart' as program_builder;
import 'resolution/semantic_visitor.dart' as semantic_visitor;
import 'source_file_provider.dart' as source_file_provider;
import 'ssa/ssa.dart' as ssa;
import 'tree/tree.dart' as tree;
import 'universe/universe.dart' as universe;
import 'util/util.dart' as util;

import 'scanner/scannerlib.dart' show
    PartialClassElement,
    PartialFunctionElement;

class ElementVisitor extends elements_visitor.BaseElementVisitor {
  visitElement(e, a) {}
}

void main(List<String> arguments) {
  useApi();
  dart2js.main(arguments);
  dart2jslib.isPublicName(null);
  useConstant(null, null, null, null, null);
  useNode(null);
  useUtil(null);
  useSetlet(null);
  useImmutableEmptySet(null);
  useElementVisitor(new ElementVisitor());
  useJsNode(new js.Program(null));
  useJsNode(new js.NamedFunction(null, null));
  useJsNode(new js.ArrayHole());
  useJsOther(new js.SimpleJavaScriptPrintingContext());
  useJsBackend(null);
  useConcreteTypesInferrer(null);
  useColor();
  useFilenames();
  useSsa(null);
  useIo(null, null);
  usedByTests();
  useElements();
  useIr(null);
  useCompiler(null);
  useTypes();
  useCodeEmitterTask(null);
  useScript(null);
  useProgramBuilder(null);
  useSemanticVisitor();
  useTreeVisitors();
}

useApi() {
  api.ReadStringFromUri uri;
}

void useConstant(constants.ConstantValue constant,
                 constants.ConstantExpression expression,
                 constants.ConstructedConstantExpression constructedConstant,
                 constants.ConstantSystem cs,
                 constants.Environment env) {
  constant.isObject;
  cs.isBool(constant);
  constructedConstant.computeInstanceType();
  constructedConstant.computeInstanceFields();
  expression.evaluate(null, null);
}

void useNode(tree.Node node) {
  node
    ..asAsyncModifier()
    ..asAsyncForIn()
    ..asAwait()
    ..asBreakStatement()
    ..asCascade()
    ..asCatchBlock()
    ..asClassNode()
    ..asCombinator()
    ..asConditional()
    ..asContinueStatement()
    ..asEnum()
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
    ..asReturn()
    ..asStatement()
    ..asStringInterpolation()
    ..asStringInterpolationPart()
    ..asStringJuxtaposition()
    ..asStringNode()
    ..asSwitchCase()
    ..asSwitchStatement()
    ..asSyncForIn()
    ..asTryStatement()
    ..asTypeAnnotation()
    ..asTypeVariable()
    ..asTypedef()
    ..asWhile()
    ..asYield();
}

void useUtil(util.Link link) {
  link.reversePrependAll(link);
  link.copyWithout(link);
  util.longestCommonPrefixLength(null, null);
  new util.Pair(null, null);
}

void useSetlet(util.Setlet setlet) {
  setlet.difference(setlet);
  setlet.retainWhere(null);
}

void useImmutableEmptySet(util.ImmutableEmptySet set) {
  set.retainWhere(null);
}

void useElementVisitor(ElementVisitor visitor) {
  visitor
    ..visit(null, null)
    ..visitAbstractFieldElement(null, null)
    ..visitAmbiguousElement(null, null)
    ..visitBoxFieldElement(null, null)
    ..visitClassElement(null, null)
    ..visitClosureClassElement(null, null)
    ..visitClosureFieldElement(null, null)
    ..visitCompilationUnitElement(null, null)
    ..visitConstructorBodyElement(null, null)
    ..visitElement(null, null)
    ..visitErroneousElement(null, null)
    ..visitFieldParameterElement(null, null)
    ..visitFunctionElement(null, null)
    ..visitLibraryElement(null, null)
    ..visitMixinApplicationElement(null, null)
    ..visitPrefixElement(null, null)
    ..visitScopeContainerElement(null, null)
    ..visitTypeDeclarationElement(null, null)
    ..visitTypeVariableElement(null, null)
    ..visitTypedefElement(null, null)
    ..visitVariableElement(null, null)
    ..visitWarnOnUseElement(null, null);
}

useJsNode(js.Node node) {
  node.asVariableUse();
}

useJsOther(js.SimpleJavaScriptPrintingContext context) {
  context.getText();
}

useJsBackend(js_backend.JavaScriptBackend backend) {
  backend.assembleCode(null);
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

useIo(io.CodeBuffer buffer, io.LineColumnMap map) {
  map..addFirst(null, null, null)
     ..forEachLine(null)
     ..getFirstElementsInLine(null)
     ..forEachColumn(null, null);
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
  new universe.TypedSelector.subclass(null, null, compiler.world);
  new universe.TypedSelector.subtype(null, null, compiler.world);
  new universe.TypedSelector.exact(null, null, compiler.world);
  sourceFileProvider.readStringFromUri(null);
}

useElements(
    [elements.ClassElement e,
     elements.Name n,
     modelx.FieldElementX f,
     PartialClassElement pce,
     PartialFunctionElement pfe,
     elements.LibraryElement l]) {
  e.lookupClassMember(null);
  e.lookupInterfaceMember(null);
  n.isAccessibleFrom(null);
  f.reuseElement();
  pce.copyWithEnclosing(null);
  pfe.copyWithEnclosing(null);
  l.forEachImport(null);
}

useIr(ir_builder.IrBuilder builder) {
  builder
    ..buildStringConstant(null)
    ..buildDynamicGet(null, null);
}

useCompiler(dart2jslib.Compiler compiler) {
  compiler.libraryLoader
      ..reset()
      ..resetAsync(null)
      ..lookupLibrary(null);
  compiler.forgetElement(null);
  compiler.backend.constantCompilerTask.copyConstantValues(null);
}

useTypes() {
  new dart_types.ResolvedTypedefType(null, null, null).unalias(null);
}

useCodeEmitterTask(js_emitter.CodeEmitterTask codeEmitterTask) {
  codeEmitterTask.oldEmitter.clearCspPrecompiledNodes();
  codeEmitterTask.oldEmitter.
      buildLazilyInitializedStaticField(null, isolateProperties: null);
}

useScript(dart2jslib.Script script) {
  script.copyWithFile(null);
}

useProgramBuilder(program_builder.ProgramBuilder builder) {
  builder.buildMethodHackForIncrementalCompilation(null);
  builder.buildFieldsHackForIncrementalCompilation(null);
}

useSemanticVisitor() {
  new semantic_visitor.BulkSendVisitor().apply(null, null);
  new semantic_visitor.TraversalVisitor(null).apply(null, null);
  new semantic_visitor.BulkDeclarationVisitor().apply(null, null);
}

class TreeVisitor1 extends tree_ir.ExpressionVisitor1
                      with tree_ir.StatementVisitor1 {
  noSuchMethod(inv) {}
}

useTreeVisitors() {
  new TreeVisitor1().visitExpression(null, null);
  new TreeVisitor1().visitStatement(null, null);
}
