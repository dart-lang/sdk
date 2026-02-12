// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of toString on generators.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show Token, scanString;
import 'package:_fe_analyzer_shared/src/util/libraries_specification.dart'
    show Importability;
import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/base/compiler_context.dart' show CompilerContext;
import 'package:front_end/src/base/constant_context.dart';
import 'package:front_end/src/base/local_scope.dart';
import 'package:front_end/src/base/name_space.dart';
import 'package:front_end/src/base/uri_translator.dart';
import 'package:front_end/src/builder/compilation_unit.dart';
import 'package:front_end/src/builder/declaration_builders.dart';
import 'package:front_end/src/builder/prefix_builder.dart';
import 'package:front_end/src/builder/type_builder.dart';
import 'package:front_end/src/codes/cfe_codes.dart' show Message;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/dill/dill_type_parameter_builder.dart';
import 'package:front_end/src/kernel/body_builder.dart' show BodyBuilderImpl;
import 'package:front_end/src/kernel/body_builder_context.dart';
import 'package:front_end/src/kernel/expression_generator.dart';
import 'package:front_end/src/kernel/expression_generator_helper.dart';
import 'package:front_end/src/kernel/internal_ast.dart';
import 'package:front_end/src/kernel/kernel_target.dart' show KernelTarget;
import 'package:front_end/src/kernel/load_library_builder.dart';
import 'package:front_end/src/source/name_space_builder.dart';
import 'package:front_end/src/source/source_compilation_unit.dart'
    show SourceCompilationUnitImpl;
import 'package:front_end/src/source/source_library_builder.dart'
    show ImplicitLanguageVersion, SourceLibraryBuilder;
import 'package:front_end/src/source/source_loader.dart';
import 'package:front_end/src/type_inference/type_inference_engine.dart';
import 'package:front_end/src/type_inference/type_inferrer.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        Component,
        DynamicType,
        Expression,
        FunctionNode,
        Library,
        Name,
        Procedure,
        ProcedureKind,
        StringLiteral,
        TypeParameter,
        VariableDeclaration,
        VariableGet,
        defaultLanguageVersion;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'mock_file_system.dart';

void check(String expected, Object generator) {
  Expect.stringEquals(expected, "$generator");
}

Future<void> main() async {
  await CompilerContext.runWithDefaultOptions((CompilerContext c) async {
    await c.options.validateOptions(errorOnMissingInput: false);

    Token token = scanString("    myToken").tokens;
    Uri uri = Uri.parse("org-dartlang-test:my_library.dart");

    /// Create dummy variants of Component, CoreTypes and ClassHierarchy for
    /// the BodyBuilder. These are not actually used in the test.
    Component component = new Component();
    CoreTypes coreTypes = new CoreTypes(component);
    ClassHierarchy hierarchy = new ClassHierarchy(component, coreTypes);

    Expression argument = new StringLiteral("arg");
    ActualArguments arguments = new ActualArguments(
      argumentList: [new PositionalArgument(argument)],
      hasNamedBeforePositional: false,
      positionalCount: 1,
    );
    Expression expression = new VariableGet(
      new VariableDeclaration("expression"),
    );
    Expression index = new VariableGet(new VariableDeclaration("index"));
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    SourceLoader loader = new KernelTarget(
      c,
      const MockFileSystem(),
      false,
      new DillTarget(
        c,
        c.options.ticker,
        uriTranslator,
        new NoneTarget(new TargetFlags()),
      ),
      uriTranslator,
    ).loader;
    SourceCompilationUnit compilationUnit = new SourceCompilationUnitImpl(
      importUri: uri,
      fileUri: uri,
      packageUri: null,
      packageLanguageVersion: new ImplicitLanguageVersion(
        defaultLanguageVersion,
      ),
      originImportUri: uri,
      indexedLibrary: null,
      forAugmentationLibrary: false,
      augmentationRoot: null,
      resolveInLibrary: null,
      referenceIsPartOwner: null,
      forPatchLibrary: false,
      isAugmenting: false,
      conditionalImportSupported: true,
      loader: loader,
      mayImplementRestrictedTypes: false,
      importability: Importability.always,
    );
    SourceLibraryBuilder libraryBuilder = new SourceLibraryBuilder(
      compilationUnit: compilationUnit,
      packageUri: null,
      importUri: uri,
      fileUri: uri,
      originImportUri: uri,
      packageLanguageVersion: new ImplicitLanguageVersion(
        defaultLanguageVersion,
      ),
      loader: loader,
      conditionalImportSupported: true,
      isAugmentation: false,
      isPatch: false,
      importNameSpace: new ComputedMutableNameSpace(),
      libraryNameSpaceBuilder: new LibraryNameSpaceBuilder(),
    );
    libraryBuilder.compilationUnit.markLanguageVersionFinal();
    LoadLibraryBuilder loadLibraryBuilder = new LoadLibraryBuilder(
      libraryBuilder,
      /*dummyLibraryDependency,*/ -1,
      libraryBuilder.compilationUnit,
      'prefix',
      -1,
      null,
    );
    Procedure getter = new Procedure(
      new Name("myGetter"),
      ProcedureKind.Getter,
      new FunctionNode(null),
      fileUri: uri,
    );
    Procedure interfaceTarget = new Procedure(
      new Name("myInterfaceTarget"),
      ProcedureKind.Method,
      new FunctionNode(null),
      fileUri: uri,
    );
    Procedure setter = new Procedure(
      new Name("mySetter"),
      ProcedureKind.Setter,
      new FunctionNode(null),
      fileUri: uri,
    );
    Message message = diag.unspecified.withArguments(message: "My Message.");
    Name binaryOperator = new Name("+");
    Name name = new Name("bar");
    PrefixBuilder prefixBuilder = new PrefixBuilder(
      "myPrefix",
      false,
      libraryBuilder,
      null,
      fileUri: uri,
      prefixOffset: -1,
      importOffset: -1,
      parentPrefixBuilder: null,
    );
    String assignmentOperator = "+=";
    TypeDeclarationBuilder declaration = new DillNominalParameterBuilder(
      new TypeParameter("T", const DynamicType(), const DynamicType()),
      loader: null,
    );
    VariableDeclaration variable = new VariableDeclaration(
      null,
      isSynthesized: true,
    );

    TypeInferenceEngineImpl engine = new TypeInferenceEngineImpl();
    engine.prepareTopLevel(coreTypes, hierarchy);

    TypeInferrer typeInferrer = engine.createTypeInferrer(
      thisType: null,
      libraryBuilder: libraryBuilder,
      extensionScope: compilationUnit.extensionScope,
    );

    LocalScope lookupScope = new FixedLocalScope(
      kind: LocalScopeKind.enclosing,
    );
    ExpressionGeneratorHelper helper = new BodyBuilderImpl(
      libraryBuilder: libraryBuilder,
      context: new LibraryBodyBuilderContext(libraryBuilder),
      uri: uri,
      enclosingScope: lookupScope,
      extensionScope: compilationUnit.extensionScope,
      coreTypes: coreTypes,
      hierarchy: hierarchy,
      assignedVariables: typeInferrer.assignedVariables,
      typeEnvironment: typeInferrer.typeSchemaEnvironment,
      constantContext: ConstantContext.none,
      internalThisVariable: null,
    );

    Generator generator = new ThisAccessGenerator(
      helper,
      token,
      false,
      false,
      false,
    );

    Library library = new Library(uri, fileUri: uri);
    Class cls = new Class(name: 'foo', fileUri: uri);
    library.addClass(cls);
    library.addProcedure(getter);
    library.addProcedure(setter);
    cls.addProcedure(interfaceTarget);

    PrefixUseGenerator prefixUseGenerator = new PrefixUseGenerator(
      helper,
      token,
      prefixBuilder,
    );

    check(
      "DelayedAssignment(offset: 4, value: expression,"
      " assignmentOperator: +=)",
      new DelayedAssignment(
        helper,
        token,
        generator,
        expression,
        assignmentOperator,
      ),
    );
    check(
      "DelayedPostfixIncrement(offset: 4, binaryOperator: +)",
      new DelayedPostfixIncrement(helper, token, generator, binaryOperator),
    );
    check(
      "VariableUseGenerator(offset: 4, variable: dynamic #0;)",
      new VariableUseGenerator(helper, token, variable),
    );
    check(
      "PropertyAccessGenerator(offset: 4,"
      " receiver: expression, name: bar)",
      new PropertyAccessGenerator(helper, token, expression, name),
    );
    check(
      "ThisPropertyAccessGenerator(offset: 4, name: bar)",
      new ThisPropertyAccessGenerator(helper, token, name),
    );
    check(
      "NullAwarePropertyAccessGenerator(offset: 4,"
      " receiver: expression, name: bar)",
      new NullAwarePropertyAccessGenerator(helper, token, expression, name),
    );
    check(
      "SuperPropertyAccessGenerator(offset: 4, name: bar,"
      " getter: $uri::myGetter, setter: $uri::mySetter)",
      new SuperPropertyAccessGenerator(helper, token, name, getter, setter),
    );
    check(
      "IndexedAccessGenerator(offset: 4, receiver: expression, index: index,"
      " isNullAware: false)",
      new IndexedAccessGenerator(
        helper,
        token,
        expression,
        index,
        isNullAware: false,
      ),
    );
    check(
      "ThisIndexedAccessGenerator(offset: 4, index: index)",
      new ThisIndexedAccessGenerator(helper, token, index),
    );
    check(
      "SuperIndexedAccessGenerator(offset: 4, index: index,"
      " getter: $uri::myGetter, setter: $uri::mySetter)",
      new SuperIndexedAccessGenerator(helper, token, index, getter, setter),
    );
    check(
      "StaticAccessGenerator(offset: 4, targetName: foo,"
      " readTarget: $uri::myGetter,"
      " writeTarget: $uri::mySetter)",
      new StaticAccessGenerator(
        helper,
        token,
        new Name('foo'),
        getter,
        null,
        setter,
      ),
    );
    check(
      "LoadLibraryGenerator(offset: 4,"
      " builder: Instance of 'LoadLibraryBuilder')",
      new LoadLibraryGenerator(helper, token, loadLibraryBuilder),
    );
    check(
      "ThisAccessGenerator(offset: 4, isInitializer: false, "
      "inFieldInitializer: false, inLateFieldInitializer: false, "
      "isSuper: false)",
      new ThisAccessGenerator(helper, token, false, false, false),
    );
    check(
      "IncompleteErrorGenerator(offset: 4, message: Unspecified)",
      new IncompleteErrorGenerator(helper, token, message),
    );
    check(
      "InvocationSelector(offset: 4, name: bar, arguments: (\"arg\"))",
      new InvocationSelector(helper, token, name, null, null, arguments),
    );
    check(
      "PropertySelector(offset: 4, name: bar)",
      new PropertySelector(helper, token, name),
    );
    check(
      "DeferredAccessGenerator(offset: 4,"
      " prefixGenerator: PrefixUseGenerator("
      "offset: 4, prefix: myPrefix, deferred: false),"
      " suffixGenerator: ThisAccessGenerator(offset: 4, isInitializer: false,"
      " inFieldInitializer: false, inLateFieldInitializer: false,"
      " isSuper: false))",
      new DeferredAccessGenerator(helper, token, prefixUseGenerator, generator),
    );
    check(
      "ReadOnlyAccessGenerator(offset: 4, expression: expression,"
      " plainNameForRead: foo, kind: ReadOnlyAccessKind.FinalVariable)",
      new ReadOnlyAccessGenerator(
        helper,
        token,
        expression,
        "foo",
        ReadOnlyAccessKind.FinalVariable,
      ),
    );
    check(
      "ParenthesizedExpressionGenerator(offset: 4, expression: expression,"
      " plainNameForRead: , kind:"
      " ReadOnlyAccessKind.ParenthesizedExpression)",
      new ParenthesizedExpressionGenerator(helper, token, expression),
    );
    check(
      "TypeUseGenerator(offset: 4, "
      "declaration: DillNominalParameterBuilder(T), "
      "plainNameForRead: foo)",
      new TypeUseGenerator(
        helper,
        token,
        declaration,
        new SyntheticTypeName("foo", -1),
      ),
    );
    check(
      "UnresolvedNameGenerator(offset: 4, name: bar)",
      new UnresolvedNameGenerator.internal(
        helper,
        token,
        name,
        UnresolvedKind.Unknown,
        false,
      ),
    );
    check(
      "PrefixUseGenerator(offset: 4, prefix: myPrefix, deferred: false)",
      prefixUseGenerator,
    );
    check(
      "UnexpectedQualifiedUseGenerator("
      "offset: 4, prefixGenerator: , isInitializer: false,"
      " inFieldInitializer: false, inLateFieldInitializer: false,"
      " isSuper: false)",
      new UnexpectedQualifiedUseGenerator(
        helper,
        token,
        generator,
        errorHasBeenReported: false,
      ),
    );
    return Future<void>.value();
  });
}
