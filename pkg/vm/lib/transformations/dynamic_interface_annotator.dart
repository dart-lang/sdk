// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:yaml/yaml.dart';

import 'pragma.dart'
    show
        kDynModuleExtendablePragmaName,
        kDynModuleCanBeOverriddenPragmaName,
        kDynModuleCallablePragmaName;

void annotateComponent(String dynamicInterfaceSpecification, Uri baseUri,
    Component component, CoreTypes coreTypes) {
  final spec = loadYamlNode(dynamicInterfaceSpecification) as YamlMap;
  verifyKeys(spec, const {'extendable', 'can-be-overridden', 'callable'});
  final LibraryIndex libraryIndex = LibraryIndex.all(component);

  parseAndAnnotate(spec['extendable'], kDynModuleExtendablePragmaName, baseUri,
      component, coreTypes, libraryIndex,
      allowMembers: false);
  parseAndAnnotate(
      spec['can-be-overridden'],
      kDynModuleCanBeOverriddenPragmaName,
      baseUri,
      component,
      coreTypes,
      libraryIndex,
      allowMembers: true,
      onlyInstanceMembers: true);
  parseAndAnnotate(spec['callable'], kDynModuleCallablePragmaName, baseUri,
      component, coreTypes, libraryIndex,
      allowMembers: true);
}

InstanceConstant pragmaConstant(CoreTypes coreTypes, String pragmaName) {
  return InstanceConstant(coreTypes.pragmaClass.reference, [], {
    coreTypes.pragmaName.fieldReference: StringConstant(pragmaName),
    coreTypes.pragmaOptions.fieldReference: NullConstant()
  });
}

void parseAndAnnotate(YamlList items, String pragmaName, Uri baseUri,
    Component component, CoreTypes coreTypes, LibraryIndex libraryIndex,
    {required bool allowMembers, bool onlyInstanceMembers = false}) {
  final pragma = pragmaConstant(coreTypes, pragmaName);

  for (final item in items) {
    final nodes = findNodes(item, baseUri, libraryIndex, component,
        allowMembers: allowMembers, onlyInstanceMembers: onlyInstanceMembers);
    annotateNodes(nodes, pragma,
        allowMembers: allowMembers, onlyInstanceMembers: onlyInstanceMembers);
  }
}

void verifyKeys(YamlMap map, Set<String> allowedKeys) {
  for (final k in map.keys) {
    if (!allowedKeys.contains(k.toString())) {
      throw 'Unexpected key "$k" in dynamic interface specification';
    }
  }
}

List<TreeNode> findNodes(YamlNode yamlNode, Uri baseUri,
    LibraryIndex libraryIndex, Component component,
    {required bool allowMembers, required bool onlyInstanceMembers}) {
  final yamlMap = yamlNode as YamlMap;
  if (allowMembers) {
    verifyKeys(yamlMap, const {'library', 'class', 'member'});
  } else {
    verifyKeys(yamlMap, const {'library', 'class'});
  }

  final librarySpec = yamlMap['library'] as String;
  if (librarySpec.endsWith('*')) {
    verifyKeys(yamlMap, const {'library'});
    final prefix = baseUri
        .resolve(librarySpec.substring(0, librarySpec.length - 1))
        .toString();
    final libs = component.libraries
        .where((lib) => lib.importUri.toString().startsWith(prefix))
        .toList();
    if (libs.isEmpty) {
      throw 'No libraries found for pattern "$librarySpec"';
    }
    return libs;
  }
  final libraryUri = baseUri.resolve(librarySpec).toString();

  if (yamlMap.containsKey('class')) {
    final yamlClassNode = yamlMap['class'];
    if (yamlClassNode is YamlList) {
      verifyKeys(yamlMap, const {'library', 'class'});
      return [
        for (final c in yamlClassNode)
          libraryIndex.getClass(libraryUri, c as String)
      ];
    }

    final classSpec = yamlClassNode as String;

    if (allowMembers && yamlMap.containsKey('member')) {
      final memberSpec = yamlMap['member'] as String;
      final member = libraryIndex.getMember(libraryUri, classSpec, memberSpec);
      if (onlyInstanceMembers && !member.isInstanceMember) {
        throw 'Expected instance member $member';
      }
      return [member];
    }

    return [libraryIndex.getClass(libraryUri, classSpec)];
  }

  if (allowMembers && yamlMap.containsKey('member')) {
    final memberSpec = yamlMap['member'] as String;
    final member = libraryIndex.getMember(libraryUri, '::', memberSpec);
    if (onlyInstanceMembers && !member.isInstanceMember) {
      throw 'Expected instance member $member';
    }
    return [member];
  }

  return [libraryIndex.getLibrary(libraryUri)];
}

void annotateNodes(List<TreeNode> nodes, Constant pragma,
    {required bool allowMembers, required bool onlyInstanceMembers}) {
  for (final node in nodes) {
    if (node is Library) {
      annotateNodes(node.classes, pragma,
          allowMembers: allowMembers, onlyInstanceMembers: onlyInstanceMembers);
      final exportedNodes = <TreeNode>[];
      for (final exportRef in node.additionalExports) {
        final exportedNode = exportRef.node;
        if (exportedNode is Class) {
          exportedNodes.add(exportedNode);
        } else if (allowMembers &&
            !onlyInstanceMembers &&
            exportedNode is Member) {
          exportedNodes.add(exportedNode);
        }
      }
      annotateNodes(exportedNodes, pragma,
          allowMembers: allowMembers, onlyInstanceMembers: onlyInstanceMembers);
      if (allowMembers) {
        annotateNodes(node.procedures, pragma,
            allowMembers: allowMembers,
            onlyInstanceMembers: onlyInstanceMembers);
        annotateNodes(node.fields, pragma,
            allowMembers: allowMembers,
            onlyInstanceMembers: onlyInstanceMembers);
      }
    } else if (node is Class && node.name[0] != '_') {
      if (!onlyInstanceMembers) {
        print("Annotated $node with $pragma");
        node.addAnnotation(ConstantExpression(pragma));
      }
      if (allowMembers) {
        annotateNodes(node.constructors, pragma,
            allowMembers: allowMembers,
            onlyInstanceMembers: onlyInstanceMembers);
        annotateNodes(node.procedures, pragma,
            allowMembers: allowMembers,
            onlyInstanceMembers: onlyInstanceMembers);
        annotateNodes(node.fields, pragma,
            allowMembers: allowMembers,
            onlyInstanceMembers: onlyInstanceMembers);
      }
    } else if (allowMembers &&
        node is Member &&
        (!onlyInstanceMembers || node.isInstanceMember) &&
        !node.name.isPrivate) {
      print("Annotated $node with $pragma");
      node.addAnnotation(ConstantExpression(pragma));
    }
  }
}
