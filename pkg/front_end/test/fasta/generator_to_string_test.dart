// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of toString on generators.

import 'package:expect/expect.dart' show Expect;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Class,
        DartType,
        Expression,
        FunctionNode,
        Library,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        StringLiteral,
        TypeParameter,
        VariableDeclaration,
        VariableGet,
        VoidType;

import 'package:kernel/target/targets.dart' show NoneTarget, TargetFlags;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/kernel_builder.dart'
    show
        KernelLibraryBuilder,
        KernelTypeVariableBuilder,
        LoadLibraryBuilder,
        PrefixBuilder,
        TypeDeclarationBuilder;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show Message, templateUnspecified;

import 'package:front_end/src/fasta/kernel/expression_generator.dart'
    show
        DeferredAccessGenerator,
        Generator,
        IncompleteErrorGenerator,
        IncompletePropertyAccessGenerator,
        IndexedAccessGenerator,
        LargeIntAccessGenerator,
        LoadLibraryGenerator,
        NullAwarePropertyAccessGenerator,
        ParenthesizedExpressionGenerator,
        PropertyAccessGenerator,
        ReadOnlyAccessGenerator,
        SendAccessGenerator,
        StaticAccessGenerator,
        SuperIndexedAccessGenerator,
        SuperPropertyAccessGenerator,
        ThisAccessGenerator,
        ThisIndexedAccessGenerator,
        ThisPropertyAccessGenerator,
        TypeDeclarationAccessGenerator,
        UnresolvedNameGenerator,
        VariableUseGenerator;

import 'package:front_end/src/fasta/kernel/body_builder.dart'
    show DelayedAssignment, DelayedPostfixIncrement;

import 'package:front_end/src/fasta/kernel/kernel_body_builder.dart'
    show KernelBodyBuilder;

import 'package:front_end/src/fasta/scanner.dart' show Token, scanString;

void check(String expected, Generator<Arguments> generator) {
  Expect.stringEquals(expected, "$generator");
}

main() {
  CompilerContext.runWithDefaultOptions((CompilerContext c) {
    Token token = scanString("    myToken").tokens;
    Uri uri = Uri.parse("org-dartlang-test:my_library.dart");

    Arguments arguments = new Arguments(<Expression>[new StringLiteral("arg")]);
    DartType type = const VoidType();
    Expression expression =
        new VariableGet(new VariableDeclaration("expression"));
    Expression index = new VariableGet(new VariableDeclaration("index"));
    KernelLibraryBuilder libraryBuilder = new KernelLibraryBuilder(
        uri,
        uri,
        new KernelTarget(
                null,
                false,
                new DillTarget(null, null, new NoneTarget(new TargetFlags())),
                null)
            .loader,
        null,
        null);
    LoadLibraryBuilder loadLibraryBuilder =
        new LoadLibraryBuilder(libraryBuilder, null, -1);
    Member getter = new Procedure(
        new Name("myGetter"), ProcedureKind.Getter, new FunctionNode(null));
    Member interfaceTarget = new Procedure(new Name("myInterfaceTarget"),
        ProcedureKind.Method, new FunctionNode(null));
    Member setter = new Procedure(
        new Name("mySetter"), ProcedureKind.Setter, new FunctionNode(null));
    Message message = templateUnspecified.withArguments("My Message.");
    Name binaryOperator = new Name("+");
    Name name = new Name("bar");
    PrefixBuilder prefixBuilder =
        new PrefixBuilder("myPrefix", false, libraryBuilder, -1);
    String assignmentOperator = "+=";
    TypeDeclarationBuilder declaration =
        new KernelTypeVariableBuilder.fromKernel(
            new TypeParameter("T"), libraryBuilder);
    VariableDeclaration variable = new VariableDeclaration(null);

    KernelBodyBuilder helper = new KernelBodyBuilder(
        libraryBuilder, null, null, null, null, null, null, false, uri, null);

    Generator generator =
        new ThisAccessGenerator<Arguments>(helper, token, false);

    Library library = new Library(uri);
    Class cls = new Class();
    library.addClass(cls);
    library.addProcedure(getter);
    library.addProcedure(setter);
    cls.addMember(interfaceTarget);

    check(
        "DelayedAssignment(offset: 4, value: expression,"
        " assignmentOperator: +=)",
        new DelayedAssignment<Arguments>(
            helper, token, generator, expression, assignmentOperator));
    check(
        "DelayedPostfixIncrement(offset: 4, binaryOperator: +,"
        " interfaceTarget: $uri::#class1::myInterfaceTarget)",
        new DelayedPostfixIncrement<Arguments>(
            helper, token, generator, binaryOperator, interfaceTarget));
    check(
        "VariableUseGenerator(offset: 4, variable: dynamic #t1;\n,"
        " promotedType: void)",
        new VariableUseGenerator<Arguments>(helper, token, variable, type));
    check(
        "PropertyAccessGenerator(offset: 4, _receiverVariable: null,"
        " receiver: expression, name: bar, getter: $uri::myGetter,"
        " setter: $uri::mySetter)",
        new PropertyAccessGenerator<Arguments>.internal(
            helper, token, expression, name, getter, setter));
    check(
        "ThisPropertyAccessGenerator(offset: 4, name: bar,"
        " getter: $uri::myGetter, setter: $uri::mySetter)",
        new ThisPropertyAccessGenerator<Arguments>(
            helper, token, name, getter, setter));
    check(
        "NullAwarePropertyAccessGenerator(offset: 4,"
        " receiver: final dynamic #t1 = expression;\n,"
        " receiverExpression: expression, name: bar, getter: $uri::myGetter,"
        " setter: $uri::mySetter, type: void)",
        new NullAwarePropertyAccessGenerator<Arguments>(
            helper, token, expression, name, getter, setter, type));
    check(
        "SuperPropertyAccessGenerator(offset: 4, name: bar,"
        " getter: $uri::myGetter, setter: $uri::mySetter)",
        new SuperPropertyAccessGenerator<Arguments>(
            helper, token, name, getter, setter));
    check(
        "IndexedAccessGenerator(offset: 4, receiver: expression, index: index,"
        " getter: $uri::myGetter, setter: $uri::mySetter,"
        " receiverVariable: null, indexVariable: null)",
        new IndexedAccessGenerator<Arguments>.internal(
            helper, token, expression, index, getter, setter));
    check(
        "ThisIndexedAccessGenerator(offset: 4, index: index,"
        " getter: $uri::myGetter, setter: $uri::mySetter, indexVariable: null)",
        new ThisIndexedAccessGenerator<Arguments>(
            helper, token, index, getter, setter));
    check(
        "SuperIndexedAccessGenerator(offset: 4, index: index,"
        " getter: $uri::myGetter, setter: $uri::mySetter, indexVariable: null)",
        new SuperIndexedAccessGenerator<Arguments>(
            helper, token, index, getter, setter));
    check(
        "StaticAccessGenerator(offset: 4, readTarget: $uri::myGetter,"
        " writeTarget: $uri::mySetter)",
        new StaticAccessGenerator<Arguments>(helper, token, getter, setter));
    check(
        "LoadLibraryGenerator(offset: 4,"
        " builder: Instance of 'LoadLibraryBuilder')",
        new LoadLibraryGenerator<Arguments>(helper, token, loadLibraryBuilder));
    check(
        "ThisAccessGenerator(offset: 4, isInitializer: false, isSuper: false)",
        new ThisAccessGenerator<Arguments>(helper, token, false));
    check("IncompleteErrorGenerator(offset: 4, message: Unspecified)",
        new IncompleteErrorGenerator<Arguments>(helper, token, message));
    check("SendAccessGenerator(offset: 4, name: bar, arguments: (\"arg\"))",
        new SendAccessGenerator<Arguments>(helper, token, name, arguments));
    check("IncompletePropertyAccessGenerator(offset: 4, name: bar)",
        new IncompletePropertyAccessGenerator<Arguments>(helper, token, name));
    check(
        "DeferredAccessGenerator(offset: 4, "
        "builder: Instance of 'PrefixBuilder',"
        " generator: ThisAccessGenerator(offset: 4, isInitializer: false,"
        " isSuper: false))",
        new DeferredAccessGenerator<Arguments>(
            helper, token, prefixBuilder, generator));
    check(
        "ReadOnlyAccessGenerator(offset: 4, expression: expression,"
        " plainNameForRead: foo, value: null)",
        new ReadOnlyAccessGenerator<Arguments>(
            helper, token, expression, "foo"));
    check("LargeIntAccessGenerator(offset: 4, lexeme: myToken)",
        new LargeIntAccessGenerator<Arguments>(helper, token));
    check(
        "ParenthesizedExpressionGenerator(offset: 4, expression: expression,"
        " plainNameForRead: null, value: null)",
        new ParenthesizedExpressionGenerator<Arguments>(
            helper, token, expression));
    check(
        "TypeDeclarationAccessGenerator(offset: 4, expression: T,"
        " plainNameForRead: foo, value: null)",
        new TypeDeclarationAccessGenerator<Arguments>(
            helper, token, prefixBuilder, -1, declaration, "foo"));
    check("UnresolvedNameGenerator(offset: 4, name: bar)",
        new UnresolvedNameGenerator<Arguments>(helper, token, name));
  });
}
