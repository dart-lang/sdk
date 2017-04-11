// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.summary.public_namespace_visitor;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Compute the public namespace portion of the summary for the given [unit],
 * which is presumed to be an unresolved AST.
 */
UnlinkedPublicNamespaceBuilder computePublicNamespace(CompilationUnit unit) {
  _PublicNamespaceVisitor visitor = new _PublicNamespaceVisitor();
  unit.accept(visitor);
  return new UnlinkedPublicNamespaceBuilder(
      names: visitor.names, exports: visitor.exports, parts: visitor.parts);
}

/**
 * Serialize a [Configuration] into a [UnlinkedConfigurationBuilder].
 */
UnlinkedConfigurationBuilder serializeConfiguration(
    Configuration configuration) {
  return new UnlinkedConfigurationBuilder(
      name: configuration.name.components.map((i) => i.name).join('.'),
      value: configuration.value?.stringValue ?? 'true',
      uri: configuration.uri.stringValue);
}

class _CombinatorEncoder extends SimpleAstVisitor<UnlinkedCombinatorBuilder> {
  _CombinatorEncoder();

  List<String> encodeNames(NodeList<SimpleIdentifier> names) =>
      names.map((SimpleIdentifier id) => id.name).toList();

  @override
  UnlinkedCombinatorBuilder visitHideCombinator(HideCombinator node) {
    return new UnlinkedCombinatorBuilder(hides: encodeNames(node.hiddenNames));
  }

  @override
  UnlinkedCombinatorBuilder visitShowCombinator(ShowCombinator node) {
    return new UnlinkedCombinatorBuilder(
        shows: encodeNames(node.shownNames),
        offset: node.offset,
        end: node.end);
  }
}

class _PublicNamespaceVisitor extends RecursiveAstVisitor {
  final List<UnlinkedPublicNameBuilder> names = <UnlinkedPublicNameBuilder>[];
  final List<UnlinkedExportPublicBuilder> exports =
      <UnlinkedExportPublicBuilder>[];
  final List<String> parts = <String>[];

  _PublicNamespaceVisitor();

  UnlinkedPublicNameBuilder addNameIfPublic(
      String name, ReferenceKind kind, int numTypeParameters) {
    if (isPublic(name)) {
      UnlinkedPublicNameBuilder b = new UnlinkedPublicNameBuilder(
          name: name, kind: kind, numTypeParameters: numTypeParameters);
      names.add(b);
      return b;
    }
    return null;
  }

  bool isPublic(String name) => !name.startsWith('_');

  @override
  visitClassDeclaration(ClassDeclaration node) {
    UnlinkedPublicNameBuilder cls = addNameIfPublic(
        node.name.name,
        ReferenceKind.classOrEnum,
        node.typeParameters?.typeParameters?.length ?? 0);
    if (cls != null) {
      for (ClassMember member in node.members) {
        if (member is FieldDeclaration && member.isStatic) {
          for (VariableDeclaration field in member.fields.variables) {
            String name = field.name.name;
            if (isPublic(name)) {
              cls.members.add(new UnlinkedPublicNameBuilder(
                  name: name,
                  kind: ReferenceKind.propertyAccessor,
                  numTypeParameters: 0));
            }
          }
        }
        if (member is MethodDeclaration &&
            member.isStatic &&
            !member.isSetter &&
            !member.isOperator) {
          String name = member.name.name;
          if (isPublic(name)) {
            cls.members.add(new UnlinkedPublicNameBuilder(
                name: name,
                kind: member.isGetter
                    ? ReferenceKind.propertyAccessor
                    : ReferenceKind.method,
                numTypeParameters:
                    member.typeParameters?.typeParameters?.length ?? 0));
          }
        }
        if (member is ConstructorDeclaration && member.name != null) {
          String name = member.name.name;
          if (isPublic(name)) {
            cls.members.add(new UnlinkedPublicNameBuilder(
                name: name,
                kind: ReferenceKind.constructor,
                numTypeParameters: 0));
          }
        }
      }
    }
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    addNameIfPublic(node.name.name, ReferenceKind.classOrEnum,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    UnlinkedPublicNameBuilder enm =
        addNameIfPublic(node.name.name, ReferenceKind.classOrEnum, 0);
    if (enm != null) {
      enm.members.add(new UnlinkedPublicNameBuilder(
          name: 'values',
          kind: ReferenceKind.propertyAccessor,
          numTypeParameters: 0));
      for (EnumConstantDeclaration enumConstant in node.constants) {
        String name = enumConstant.name.name;
        if (isPublic(name)) {
          enm.members.add(new UnlinkedPublicNameBuilder(
              name: name,
              kind: ReferenceKind.propertyAccessor,
              numTypeParameters: 0));
        }
      }
    }
  }

  @override
  visitExportDirective(ExportDirective node) {
    exports.add(new UnlinkedExportPublicBuilder(
        uri: node.uri.stringValue,
        combinators: node.combinators
            .map((Combinator c) => c.accept(new _CombinatorEncoder()))
            .toList(),
        configurations:
            node.configurations.map(serializeConfiguration).toList()));
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    String name = node.name.name;
    if (node.isSetter) {
      name += '=';
    }
    addNameIfPublic(
        name,
        node.isGetter || node.isSetter
            ? ReferenceKind.topLevelPropertyAccessor
            : ReferenceKind.topLevelFunction,
        node.functionExpression.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    addNameIfPublic(node.name.name, ReferenceKind.typedef,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitGenericTypeAlias(GenericTypeAlias node) {
    addNameIfPublic(node.name.name, ReferenceKind.genericFunctionTypedef,
        node.typeParameters?.typeParameters?.length ?? 0);
  }

  @override
  visitPartDirective(PartDirective node) {
    parts.add(node.uri.stringValue ?? '');
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    String name = node.name.name;
    addNameIfPublic(name, ReferenceKind.topLevelPropertyAccessor, 0);
    if (!node.isFinal && !node.isConst) {
      addNameIfPublic('$name=', ReferenceKind.topLevelPropertyAccessor, 0);
    }
  }
}
