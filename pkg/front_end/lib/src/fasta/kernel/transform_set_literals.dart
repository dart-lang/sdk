// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_set_literals;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Class,
        Constructor,
        ConstructorInvocation,
        DartType,
        Expression,
        InterfaceType,
        Let,
        Library,
        MapEntry,
        MapLiteral,
        MethodInvocation,
        Name,
        NullLiteral,
        Procedure,
        SetLiteral,
        StaticInvocation,
        TreeNode,
        VariableDeclaration,
        VariableGet;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show Transformer;

import '../source/source_loader.dart' show SourceLoader;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

// TODO(askesc): Delete this class when all backends support set literals.
class SetLiteralTransformer extends Transformer {
  final CoreTypes coreTypes;
  final DartType nullType;
  final Procedure setFactory;
  final Procedure addMethod;
  final Constructor unmodifiableSetConstructor;
  final bool transformConst;

  static Procedure _findSetFactory(CoreTypes coreTypes) {
    Procedure factory = coreTypes.index.getMember('dart:core', 'Set', '');
    RedirectingFactoryBody body = factory?.function?.body;
    return body?.target;
  }

  static Procedure _findAddMethod(CoreTypes coreTypes) {
    return coreTypes.index.getMember('dart:core', 'Set', 'add');
  }

  static Constructor _findUnmodifiableSetConstructor(SourceLoader loader) {
    // We should not generally dig into libraries like this, and we should
    // avoid dependencies on libraries other than the ones indexed by
    // CoreTypes. This is a temporary solution until all backends have
    // implemented support for set literals.
    Uri collectionUri = Uri.parse("dart:collection");
    Library collectionLibrary = loader.builders[collectionUri].target;
    for (int i = 0; i < collectionLibrary.classes.length; i++) {
      Class classNode = collectionLibrary.classes[i];
      if (classNode.name == "_UnmodifiableSet") {
        for (int j = 0; j < collectionLibrary.classes.length; j++) {
          Constructor constructor = classNode.constructors[j];
          if (constructor.name.name.isEmpty) {
            return constructor;
          }
        }
      }
    }
    return null;
  }

  SetLiteralTransformer(SourceLoader loader, {this.transformConst: true})
      : coreTypes = loader.coreTypes,
        nullType = new InterfaceType(loader.coreTypes.nullClass, []),
        setFactory = _findSetFactory(loader.coreTypes),
        addMethod = _findAddMethod(loader.coreTypes),
        unmodifiableSetConstructor = _findUnmodifiableSetConstructor(loader);

  TreeNode visitSetLiteral(SetLiteral node) {
    if (node.isConst) {
      if (!transformConst) return node;
      List<MapEntry> entries = new List<MapEntry>(node.expressions.length);
      for (int i = 0; i < node.expressions.length; i++) {
        // expression_i: null
        Expression entry = node.expressions[i].accept(this);
        entries[i] = new MapEntry(entry, new NullLiteral());
      }
      Expression mapExp = new MapLiteral(entries,
          keyType: node.typeArgument, valueType: nullType, isConst: true);
      return new ConstructorInvocation(unmodifiableSetConstructor,
          new Arguments([mapExp], types: [node.typeArgument]),
          isConst: true);
    } else {
      // Outermost declaration of let chain: Set<E> setVar = new Set<E>();
      VariableDeclaration setVar = new VariableDeclaration.forValue(
          new StaticInvocation(
              setFactory, new Arguments([], types: [node.typeArgument])),
          type: new InterfaceType(coreTypes.setClass, [node.typeArgument]));
      // Innermost body of let chain: setVar
      Expression setExp = new VariableGet(setVar);
      for (int i = node.expressions.length - 1; i >= 0; i--) {
        // let _ = setVar.add(expression) in rest
        Expression entry = node.expressions[i].accept(this);
        setExp = new Let(
            new VariableDeclaration.forValue(new MethodInvocation(
                new VariableGet(setVar),
                new Name("add"),
                new Arguments([entry]),
                addMethod)),
            setExp);
      }
      return new Let(setVar, setExp);
    }
  }
}
