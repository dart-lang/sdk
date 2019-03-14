// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_collections;

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart'
    show
        Arguments,
        Block,
        BlockExpression,
        Class,
        DartType,
        DynamicType,
        Expression,
        ExpressionStatement,
        Field,
        ForInStatement,
        IfStatement,
        InterfaceType,
        InvalidExpression,
        ListLiteral,
        MapEntry,
        MapLiteral,
        MethodInvocation,
        Name,
        Not,
        NullLiteral,
        Procedure,
        PropertyGet,
        SetLiteral,
        Statement,
        StaticInvocation,
        TreeNode,
        VariableDeclaration,
        VariableGet;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/visitor.dart' show Transformer;

import 'collections.dart' show SpreadElement, SpreadMapEntry;

import '../source/source_loader.dart' show SourceLoader;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

class CollectionTransformer extends Transformer {
  final CoreTypes coreTypes;
  final Procedure listAdd;
  final Procedure setFactory;
  final Procedure setAdd;
  final Procedure objectEquals;
  final Procedure mapEntries;
  final Procedure mapPut;
  final Class mapEntryClass;
  final Field mapEntryKey;
  final Field mapEntryValue;

  static Procedure _findSetFactory(CoreTypes coreTypes) {
    Procedure factory = coreTypes.index.getMember('dart:core', 'Set', '');
    RedirectingFactoryBody body = factory?.function?.body;
    return body?.target;
  }

  CollectionTransformer(SourceLoader loader)
      : coreTypes = loader.coreTypes,
        listAdd = loader.coreTypes.index.getMember('dart:core', 'List', 'add'),
        setFactory = _findSetFactory(loader.coreTypes),
        setAdd = loader.coreTypes.index.getMember('dart:core', 'Set', 'add'),
        objectEquals =
            loader.coreTypes.index.getMember('dart:core', 'Object', '=='),
        mapEntries =
            loader.coreTypes.index.getMember('dart:core', 'Map', 'get:entries'),
        mapPut = loader.coreTypes.index.getMember('dart:core', 'Map', '[]='),
        mapEntryClass =
            loader.coreTypes.index.getClass('dart:core', 'MapEntry'),
        mapEntryKey =
            loader.coreTypes.index.getMember('dart:core', 'MapEntry', 'key'),
        mapEntryValue =
            loader.coreTypes.index.getMember('dart:core', 'MapEntry', 'value');

  TreeNode _translateListOrSet(
      Expression node, DartType elementType, List<Expression> elements,
      {bool isSet: false, bool isConst: false}) {
    // Translate elements in place up to the first spread if any.
    int i = 0;
    for (; i < elements.length; ++i) {
      if (elements[i] is SpreadElement) break;
      elements[i] = elements[i].accept(this)..parent = node;
    }

    // If there was no spread, we are done.
    if (i == elements.length) return node;

    if (isConst) {
      // We don't desugar const lists here.  Remove spread for now so that they
      // don't leak out.
      for (; i < elements.length; ++i) {
        Expression element = elements[i];
        if (element is SpreadElement) {
          elements[i] = InvalidExpression('unimplemented spread element')
            ..fileOffset = element.fileOffset
            ..parent = node;
        } else {
          elements[i] = element.accept(this)..parent = node;
        }
      }
      return node;
    }

    // Build a block expression and create an empty list or set.
    VariableDeclaration result;
    if (isSet) {
      // TODO(kmillikin): When all the back ends handle set literals we can use
      // one here.
      result = new VariableDeclaration.forValue(
          new StaticInvocation(
              setFactory, new Arguments([], types: [elementType])),
          type: new InterfaceType(coreTypes.setClass, [elementType]),
          isFinal: true);
    } else {
      result = new VariableDeclaration.forValue(
          new ListLiteral([], typeArgument: elementType),
          type: new InterfaceType(coreTypes.listClass, [elementType]),
          isFinal: true);
    }
    List<Statement> body = [result];
    // Add the elements up to the first spread.
    for (int j = 0; j < i; ++j) {
      body.add(new ExpressionStatement(new MethodInvocation(
          new VariableGet(result),
          new Name('add'),
          new Arguments([elements[j]]),
          isSet ? setAdd : listAdd)));
    }
    // Translate the elements starting with the first spread.
    for (; i < elements.length; ++i) {
      Expression element = elements[i];
      if (element is SpreadElement) {
        Expression value = element.expression.accept(this);
        // Null-aware spreads require testing the subexpression's value.
        VariableDeclaration temp;
        if (element.isNullAware) {
          temp = new VariableDeclaration.forValue(value,
              type: const DynamicType(), isFinal: true);
          body.add(temp);
          value = new VariableGet(temp);
        }

        VariableDeclaration elt =
            new VariableDeclaration(null, type: elementType, isFinal: true);
        Statement statement = new ForInStatement(
            elt,
            value,
            new ExpressionStatement(new MethodInvocation(
                new VariableGet(result),
                new Name('add'),
                new Arguments([new VariableGet(elt)]),
                isSet ? setAdd : listAdd)));

        if (element.isNullAware) {
          statement = new IfStatement(
              new Not(new MethodInvocation(
                  new VariableGet(temp),
                  new Name('=='),
                  new Arguments([new NullLiteral()]),
                  objectEquals)),
              statement,
              null);
        }
        body.add(statement);
      } else {
        body.add(new ExpressionStatement(new MethodInvocation(
            new VariableGet(result),
            new Name('add'),
            new Arguments([element.accept(this)]),
            isSet ? setAdd : listAdd)));
      }
    }

    return new BlockExpression(new Block(body), new VariableGet(result));
  }

  @override
  TreeNode visitListLiteral(ListLiteral node) {
    return _translateListOrSet(node, node.typeArgument, node.expressions,
        isConst: node.isConst, isSet: false);
  }

  @override
  TreeNode visitSetLiteral(SetLiteral node) {
    return _translateListOrSet(node, node.typeArgument, node.expressions,
        isConst: node.isConst, isSet: true);
  }

  @override
  TreeNode visitMapLiteral(MapLiteral node) {
    int i = 0;
    for (; i < node.entries.length; ++i) {
      if (node.entries[i] is SpreadMapEntry) break;
      node.entries[i] = node.entries[i].accept(this)..parent = node;
    }

    if (i == node.entries.length) return node;

    if (node.isConst) {
      // We don't desugar const maps here.  REmove spread for now so that they
      // don't leak out.
      for (; i < node.entries.length; ++i) {
        MapEntry entry = node.entries[i];
        if (entry is SpreadMapEntry) {
          entry.parent.replaceChild(
              entry,
              new MapEntry(
                  InvalidExpression('unimplemented spread element')
                    ..fileOffset = entry.fileOffset,
                  new NullLiteral()));
        }
      }
    }

    VariableDeclaration map = new VariableDeclaration.forValue(
        new MapLiteral([], keyType: node.keyType, valueType: node.valueType),
        type: new InterfaceType(
            coreTypes.mapClass, [node.keyType, node.valueType]),
        isFinal: true);
    List<Statement> body = [map];
    for (int j = 0; j < i; ++j) {
      body.add(new ExpressionStatement(new MethodInvocation(
          new VariableGet(map),
          new Name('[]='),
          new Arguments([node.entries[j].key, node.entries[j].value]),
          mapPut)));
    }
    DartType mapEntryType =
        new InterfaceType(mapEntryClass, [node.keyType, node.valueType]);
    for (; i < node.entries.length; ++i) {
      MapEntry entry = node.entries[i];
      if (entry is SpreadMapEntry) {
        Expression value = entry.expression.accept(this);
        // Null-aware spreads require testing the subexpression's value.
        VariableDeclaration temp;
        if (entry.isNullAware) {
          temp = new VariableDeclaration.forValue(value,
              type: coreTypes.mapClass.rawType);
          body.add(temp);
          value = new VariableGet(temp);
        }

        VariableDeclaration elt =
            new VariableDeclaration(null, type: mapEntryType, isFinal: true);
        Statement statement = new ForInStatement(
            elt,
            new PropertyGet(value, new Name('entries'), mapEntries),
            new ExpressionStatement(new MethodInvocation(
                new VariableGet(map),
                new Name('[]='),
                new Arguments([
                  new PropertyGet(
                      new VariableGet(elt), new Name('key'), mapEntryKey),
                  new PropertyGet(
                      new VariableGet(elt), new Name('value'), mapEntryValue)
                ]),
                mapPut)));

        if (entry.isNullAware) {
          statement = new IfStatement(
              new Not(new MethodInvocation(
                  new VariableGet(temp),
                  new Name('=='),
                  new Arguments([new NullLiteral()]),
                  objectEquals)),
              statement,
              null);
        }
        body.add(statement);
      } else {
        entry = entry.accept(this);
        body.add(new ExpressionStatement(new MethodInvocation(
            new VariableGet(map),
            new Name('[]='),
            new Arguments([entry.key, entry.value]),
            mapPut)));
      }
    }

    return new BlockExpression(new Block(body), new VariableGet(map));
  }
}
