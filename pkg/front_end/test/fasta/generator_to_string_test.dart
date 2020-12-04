// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of toString on generators.

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show Token, scanString;

import 'package:expect/expect.dart' show Expect;
import 'package:front_end/src/fasta/uri_translator.dart';

import 'package:kernel/ast.dart'
    show
        Arguments,
        Class,
        DartType,
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
        VoidType;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'package:front_end/src/fasta/builder/type_declaration_builder.dart';
import 'package:front_end/src/fasta/builder/prefix_builder.dart';
import 'package:front_end/src/fasta/builder/type_variable_builder.dart';

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show LoadLibraryBuilder;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show Message, templateUnspecified;

import 'package:front_end/src/fasta/kernel/expression_generator.dart';

import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

void check(String expected, Generator generator) {
  Expect.stringEquals(expected, "$generator");
}

main() async {
  await CompilerContext.runWithDefaultOptions((CompilerContext c) async {
    Token token = scanString("    myToken").tokens;
    Uri uri = Uri.parse("org-dartlang-test:my_library.dart");

    Arguments arguments = new Arguments(<Expression>[new StringLiteral("arg")]);
    DartType type = const VoidType();
    Expression expression =
        new VariableGet(new VariableDeclaration("expression"));
    Expression index = new VariableGet(new VariableDeclaration("index"));
    UriTranslator uriTranslator = await c.options.getUriTranslator();
    SourceLibraryBuilder libraryBuilder = new SourceLibraryBuilder(
        uri,
        uri,
        /*packageUri*/ null,
        new KernelTarget(
                null,
                false,
                new DillTarget(c.options.ticker, uriTranslator,
                    new NoneTarget(new TargetFlags())),
                uriTranslator)
            .loader,
        null);
    LoadLibraryBuilder loadLibraryBuilder =
        new LoadLibraryBuilder(libraryBuilder, null, -1);
    Procedure getter = new Procedure(
        new Name("myGetter"), ProcedureKind.Getter, new FunctionNode(null));
    Procedure interfaceTarget = new Procedure(new Name("myInterfaceTarget"),
        ProcedureKind.Method, new FunctionNode(null));
    Procedure setter = new Procedure(
        new Name("mySetter"), ProcedureKind.Setter, new FunctionNode(null));
    Message message = templateUnspecified.withArguments("My Message.");
    Name binaryOperator = new Name("+");
    Name name = new Name("bar");
    PrefixBuilder prefixBuilder =
        new PrefixBuilder("myPrefix", false, libraryBuilder, null, -1, -1);
    String assignmentOperator = "+=";
    TypeDeclarationBuilder declaration = new TypeVariableBuilder.fromKernel(
        new TypeParameter("T"), libraryBuilder);
    VariableDeclaration variable = new VariableDeclaration(null);

    BodyBuilder helper = new BodyBuilder(
        libraryBuilder: libraryBuilder,
        isDeclarationInstanceMember: false,
        uri: uri);

    Generator generator =
        new ThisAccessGenerator(helper, token, false, false, false);

    Library library = new Library(uri);
    Class cls = new Class();
    library.addClass(cls);
    library.addProcedure(getter);
    library.addProcedure(setter);
    cls.addProcedure(interfaceTarget);

    PrefixUseGenerator prefixUseGenerator =
        new PrefixUseGenerator(helper, token, prefixBuilder);

    check(
        "DelayedAssignment(offset: 4, value: expression,"
        " assignmentOperator: +=)",
        new DelayedAssignment(
            helper, token, generator, expression, assignmentOperator));
    check("DelayedPostfixIncrement(offset: 4, binaryOperator: +)",
        new DelayedPostfixIncrement(helper, token, generator, binaryOperator));
    check(
        "VariableUseGenerator(offset: 4, variable: dynamic #t1;\n,"
        " promotedType: void)",
        new VariableUseGenerator(helper, token, variable, type));
    check(
        "PropertyAccessGenerator(offset: 4,"
        " receiver: expression, name: bar)",
        new PropertyAccessGenerator(helper, token, expression, name));
    check("ThisPropertyAccessGenerator(offset: 4, name: bar)",
        new ThisPropertyAccessGenerator(helper, token, name));
    check(
        "NullAwarePropertyAccessGenerator(offset: 4,"
        " receiver: final dynamic #t1 = expression;\n,"
        " receiverExpression: expression, name: bar)",
        new NullAwarePropertyAccessGenerator(helper, token, expression, name));
    check(
        "SuperPropertyAccessGenerator(offset: 4, name: bar,"
        " getter: $uri::myGetter, setter: $uri::mySetter)",
        new SuperPropertyAccessGenerator(helper, token, name, getter, setter));
    check(
        "IndexedAccessGenerator(offset: 4, receiver: expression, index: index,"
        " isNullAware: false)",
        new IndexedAccessGenerator(helper, token, expression, index,
            isNullAware: false));
    check("ThisIndexedAccessGenerator(offset: 4, index: index)",
        new ThisIndexedAccessGenerator(helper, token, index));
    check(
        "SuperIndexedAccessGenerator(offset: 4, index: index,"
        " getter: $uri::myGetter, setter: $uri::mySetter)",
        new SuperIndexedAccessGenerator(helper, token, index, getter, setter));
    check(
        "StaticAccessGenerator(offset: 4, targetName: foo,"
        " readTarget: $uri::myGetter,"
        " writeTarget: $uri::mySetter)",
        new StaticAccessGenerator(helper, token, 'foo', getter, setter));
    check(
        "LoadLibraryGenerator(offset: 4,"
        " builder: Instance of 'LoadLibraryBuilder')",
        new LoadLibraryGenerator(helper, token, loadLibraryBuilder));
    check(
        "ThisAccessGenerator(offset: 4, isInitializer: false, "
        "inFieldInitializer: false, inLateFieldInitializer: false, "
        "isSuper: false)",
        new ThisAccessGenerator(helper, token, false, false, false));
    check("IncompleteErrorGenerator(offset: 4, message: Unspecified)",
        new IncompleteErrorGenerator(helper, token, message));
    check("SendAccessGenerator(offset: 4, name: bar, arguments: (\"arg\"))",
        new SendAccessGenerator(helper, token, name, null, arguments));
    check("IncompletePropertyAccessGenerator(offset: 4, name: bar)",
        new IncompletePropertyAccessGenerator(helper, token, name));
    check(
        "DeferredAccessGenerator(offset: 4,"
        " prefixGenerator: PrefixUseGenerator("
        "offset: 4, prefix: myPrefix, deferred: false),"
        " suffixGenerator: ThisAccessGenerator(offset: 4, isInitializer: false,"
        " inFieldInitializer: false, inLateFieldInitializer: false,"
        " isSuper: false))",
        new DeferredAccessGenerator(
            helper, token, prefixUseGenerator, generator));
    check(
        "ReadOnlyAccessGenerator(offset: 4, expression: expression,"
        " plainNameForRead: foo, kind: ReadOnlyAccessKind.FinalVariable)",
        new ReadOnlyAccessGenerator(helper, token, expression, "foo",
            ReadOnlyAccessKind.FinalVariable));
    check(
        "ParenthesizedExpressionGenerator(offset: 4, expression: expression,"
        " plainNameForRead: null, kind:"
        " ReadOnlyAccessKind.ParenthesizedExpression)",
        new ParenthesizedExpressionGenerator(helper, token, expression));
    check("TypeUseGenerator(offset: 4, declaration: T, plainNameForRead: foo)",
        new TypeUseGenerator(helper, token, declaration, "foo"));
    check("UnresolvedNameGenerator(offset: 4, name: bar)",
        new UnresolvedNameGenerator.internal(helper, token, name));
    check("PrefixUseGenerator(offset: 4, prefix: myPrefix, deferred: false)",
        prefixUseGenerator);
    check(
        "UnexpectedQualifiedUseGenerator("
        "offset: 4, prefixGenerator: , isInitializer: false,"
        " inFieldInitializer: false, inLateFieldInitializer: false,"
        " isSuper: false)",
        new UnexpectedQualifiedUseGenerator(helper, token, generator, false));
    return Future<void>.value();
  });
}
