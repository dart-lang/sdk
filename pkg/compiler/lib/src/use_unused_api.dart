// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file use methods that aren't used by dart2js.dart, but that we wish to
/// keep anyway. This might be general API that isn't currently in use,
/// debugging aids, or API only used for testing (see TODO below).

library dart2js.use_unused_api;

import '../compiler.dart' as api;
import 'colors.dart' as colors;
import 'compiler.dart' as compiler;
import 'constants/constant_system.dart' as constants;
import 'constants/constructors.dart' as constants;
import 'constants/evaluation.dart' as constants;
import 'constants/expressions.dart' as constants;
import 'constants/values.dart' as constants;
import 'dart2js.dart' as dart2js;
import 'elements/resolution_types.dart' as dart_types;
import 'deferred_load.dart' as deferred_load;
import 'diagnostics/source_span.dart' as diagnostics;
import 'elements/elements.dart' as elements;
import 'elements/modelx.dart' as modelx;
import 'elements/names.dart' as names;
import 'elements/operators.dart' as operators;
import 'elements/visitor.dart' as elements_visitor;
import 'filenames.dart' as filenames;
import 'inferrer/type_graph_inferrer.dart' as type_graph_inferrer;
import 'io/location_provider.dart' as io;
import 'io/source_map_builder.dart' as io;
import 'js/js.dart' as js;
import 'js_backend/js_backend.dart' as js_backend;
import 'parser/partial_elements.dart'
    show PartialClassElement, PartialFunctionElement;
import 'resolution/semantic_visitor.dart' as semantic_visitor;
import 'script.dart';
import 'source_file_provider.dart' as source_file_provider;
import 'ssa/nodes.dart' as ssa;
import 'tree/tree.dart' as tree;
import 'util/util.dart' as util;
import 'world.dart';

class ElementVisitor extends elements_visitor.BaseElementVisitor {
  visitElement(e, a) {}
}

void main(List<String> arguments) {
  useApi(null);
  dart2js.main(arguments);
  names.Name.isPublicName(null);
  useConstant();
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
  useColor();
  useFilenames();
  useSsa(null);
  useIo();
  usedByTests();
  useElements();
  useCompiler(null);
  useTypes();
  useScript(null);
  useSemanticVisitor();
  useDeferred();
}

useApi([api.ReadStringFromUri uri, compiler.Compiler compiler]) {
  compiler.analyzeUri(null);
  new diagnostics.SourceSpan.fromNode(null, null);
}

class NullConstantConstructorVisitor
    extends constants.ConstantConstructorVisitor {
  @override
  visitGenerative(constants.GenerativeConstantConstructor constructor, arg) {}

  @override
  visitRedirectingFactory(
      constants.RedirectingFactoryConstantConstructor constructor, arg) {}

  @override
  visitRedirectingGenerative(
      constants.RedirectingGenerativeConstantConstructor constructor, arg) {}
}

void useConstant(
    [constants.ConstantValue constant,
    constants.ConstantExpression expression,
    constants.ConstructedConstantExpression constructedConstant,
    constants.ConstantSystem cs,
    constants.EvaluationEnvironment env]) {
  constant.isObject;
  cs.isBool(constant);
  constructedConstant.computeInstanceType(null);
  constructedConstant.computeInstanceFields(null);
  expression.evaluate(null, null);
  new NullConstantConstructorVisitor()
    ..visit(null, null)
    ..visitGenerative(null, null)
    ..visitRedirectingFactory(null, null)
    ..visitRedirectingGenerative(null, null);
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
    ..asImport()
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
    ..asNominalTypeAnnotation()
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
  backend.getGeneratedCode(null);
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

useIo([io.LineColumnMap map, io.LocationProvider provider]) {
  map
    ..addFirst(null, null, null)
    ..forEachLine(null)
    ..getFirstElementsInLine(null)
    ..forEachColumn(null, null);
}

usedByTests() {
  // TODO(ahe): We should try to avoid including API used only for tests. In
  // most cases, such API can be moved to a test library.
  ClosedWorldImpl closedWorld = null;
  type_graph_inferrer.TypeGraphInferrer typeGraphInferrer = null;
  source_file_provider.SourceFileProvider sourceFileProvider = null;
  sourceFileProvider.getSourceFile(null);
  closedWorld.hasAnyUserDefinedGetter(null, null);
  closedWorld.subclassesOf(null);
  closedWorld.getClassHierarchyNode(null);
  closedWorld.getClassSet(null);
  closedWorld.haveAnyCommonSubtypes(null, null);
  typeGraphInferrer.getCallersOf(null);
  dart_types.Types.sorted(null);
  new dart_types.Types(null).copy(null);
}

useElements(
    [elements.ClassElement e,
    names.Name n,
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

useCompiler(compiler.Compiler c) {
  c.libraryLoader
    ..reset()
    ..resetAsync(null)
    ..lookupLibrary(null);
  c.backend.constantCompilerTask.copyConstantValues(null);
  c.currentlyInUserCode();
}

useTypes() {}

useScript(Script script) {
  script.copyWithFile(null);
}

useSemanticVisitor() {
  operators.UnaryOperator.fromKind(null);
  operators.BinaryOperator.fromKind(null);
  new semantic_visitor.BulkSendVisitor()..apply(null, null);
  new semantic_visitor.TraversalVisitor(null).apply(null, null);
  new semantic_visitor.BulkDeclarationVisitor().apply(null, null);
}

useDeferred([deferred_load.DeferredLoadTask task]) {
  task.dump();
}
