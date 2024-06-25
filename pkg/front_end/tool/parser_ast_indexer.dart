// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/util/parser_ast.dart';
import 'package:front_end/src/util/parser_ast_helper.dart';

/// Visitor indexing methods/fields, both toplevel and in classes etc.
/// It does not recurse in to children of these, and doing so will potentially
/// ruin the handling of metadata.
class AstIndexer extends IgnoreSomeForCompatibilityAstVisitor {
  Map<String, int> nameIndex = {};
  List<int> positionStartEndIndex = [];
  List<ParserAstNode> positionNodeIndex = [];
  List<String> positionNodeName = [];
  String? currentContainerName;

  String? nameOfEntitySpanning(int position) {
    int? nodeIndex =
        moveNodeIndexPastMetadata(findNodeIndexSpanningPosition(position));
    if (nodeIndex != null) {
      return positionNodeName[nodeIndex];
    }
    return null;
  }

  int? moveNodeIndexToFirstMetadataIfAny(int? nodeIndex) {
    if (nodeIndex == null) return nodeIndex;

    while (nodeIndex! > 0 && positionNodeIndex[nodeIndex - 1] is MetadataEnd) {
      nodeIndex--;
    }
    return nodeIndex;
  }

  int? moveNodeIndexPastMetadata(int? nodeIndex) {
    if (nodeIndex == null) return nodeIndex;
    while (nodeIndex! < positionNodeIndex.length &&
        positionNodeIndex[nodeIndex] is MetadataEnd) {
      nodeIndex++;
    }
    if (nodeIndex < positionNodeIndex.length &&
        positionNodeIndex[nodeIndex] is! MetadataEnd) {
      return nodeIndex;
    }
    return null;
  }

  int? findNodeIndexSpanningPosition(int position) {
    int low = 0;
    int high = positionNodeIndex.length - 1;
    while (low < high) {
      int mid = high - ((high - low) >> 1); // Get middle, rounding up.
      int start1 = positionStartEndIndex[mid * 2 + 0];
      int end1 = positionStartEndIndex[mid * 2 + 1];

      if (position > end1) {
        // After the entity --- no matter if this is a container or not
        // we're after it.
        low = mid;
      } else if (position < start1) {
        // Before the entity --- no matter if this is a container or not
        // we're before it.
        high = mid - 1;
      } else {
        // Inside this entity --- if this entity is a container
        // (i.e. the next entity is also inside this entity) try to find
        // something more specific.
        if (mid + 1 < positionNodeIndex.length) {
          int start2 = positionStartEndIndex[(mid + 1) * 2 + 0];
          if (start2 < end1 /* i.e. inside */ && start2 <= position) {
            low = mid + 1;
            continue;
          }
        }

        return mid;
      }
    }
    int start = positionStartEndIndex[low * 2 + 0];
    int end = positionStartEndIndex[low * 2 + 1];
    if (position >= start && position <= end) {
      return low;
    }

    return null;
  }

  @override
  void visitClassDeclarationEnd(ClassDeclarationEnd node) {
    currentContainerName = node.getClassIdentifier().token.lexeme;
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitClassDeclarationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitEnumEnd(EnumEnd node) {
    currentContainerName = node.getEnumIdentifier().token.lexeme;
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitEnumEnd(node);
    currentContainerName = null;
  }

  @override
  void visitExtensionDeclarationEnd(ExtensionDeclarationEnd node) {
    currentContainerName =
        node.getExtensionName()?.lexeme ?? "<unnamed extension>";
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitExtensionDeclarationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitExtensionTypeDeclarationEnd(ExtensionTypeDeclarationEnd node) {
    currentContainerName =
        node.getExtensionTypeName()?.lexeme ?? "<unnamed extension type>";
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitExtensionTypeDeclarationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitMixinDeclarationEnd(MixinDeclarationEnd node) {
    currentContainerName = node.getMixinIdentifier().token.lexeme;
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitMixinDeclarationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitNamedMixinApplicationEnd(NamedMixinApplicationEnd node) {
    currentContainerName = node.getMixinIdentifier().token.lexeme;
    positionStartEndIndex.add(node.begin.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    nameIndex[currentContainerName!] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(currentContainerName!);
    super.visitNamedMixinApplicationEnd(node);
    currentContainerName = null;
  }

  @override
  void visitTopLevelMethodEnd(TopLevelMethodEnd node) {
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    // TODO(jensj): Setters.
    String name = node.getNameIdentifier().token.lexeme;
    nameIndex[name] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(name);
  }

  @override
  void visitTopLevelFieldsEnd(TopLevelFieldsEnd node) {
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    String? firstName;
    for (IdentifierHandle identifier in node.getFieldIdentifiers()) {
      String name = identifier.token.lexeme;
      firstName ??= name;
      nameIndex[name] = positionNodeIndex.length;
    }
    positionNodeIndex.add(node);
    positionNodeName.add(firstName!);
  }

  @override
  void visitMetadataStarEnd(MetadataStarEnd node) {
    for (MetadataEnd metadata in node.getMetadataEntries()) {
      positionStartEndIndex.add(metadata.beginToken.charOffset);
      positionStartEndIndex.add(metadata.endToken.charEnd);
      positionNodeIndex.add(metadata);
      positionNodeName.add("<metadata>");
    }
  }

  void containerMethod(
      BeginAndEndTokenParserAstNode node, String nameIdentifier) {
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    // TODO(jensj): Setters.
    String name = "$currentContainerName.$nameIdentifier";
    nameIndex[name] = positionNodeIndex.length;
    positionNodeIndex.add(node);
    positionNodeName.add(name);
  }

  void containerFields(
      BeginAndEndTokenParserAstNode node, List<IdentifierHandle> names) {
    positionStartEndIndex.add(node.beginToken.charOffset);
    positionStartEndIndex.add(node.endToken.charEnd);
    String? firstName;
    for (IdentifierHandle identifier in names) {
      String name = "$currentContainerName.${identifier.token.lexeme}";
      firstName ??= name;
      nameIndex[name] = positionNodeIndex.length;
    }
    positionNodeIndex.add(node);
    positionNodeName.add(firstName!);
  }

  @override
  void visitClassConstructorEnd(ClassConstructorEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitClassFactoryMethodEnd(ClassFactoryMethodEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitClassFieldsEnd(ClassFieldsEnd node) {
    containerFields(node, node.getFieldIdentifiers());
  }

  @override
  void visitClassMethodEnd(ClassMethodEnd node) {
    containerMethod(node, node.getNameIdentifier());
  }

  @override
  void visitMixinConstructorEnd(MixinConstructorEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitMixinFactoryMethodEnd(MixinFactoryMethodEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitMixinFieldsEnd(MixinFieldsEnd node) {
    containerFields(node, node.getFieldIdentifiers());
  }

  @override
  void visitMixinMethodEnd(MixinMethodEnd node) {
    containerMethod(node, node.getNameIdentifier());
  }

  @override
  void visitEnumConstructorEnd(EnumConstructorEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitEnumFactoryMethodEnd(EnumFactoryMethodEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitEnumFieldsEnd(EnumFieldsEnd node) {
    containerFields(node, node.getFieldIdentifiers());
  }

  @override
  void visitEnumMethodEnd(EnumMethodEnd node) {
    containerMethod(node, node.getNameIdentifier());
  }

  @override
  void visitExtensionConstructorEnd(ExtensionConstructorEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitExtensionFactoryMethodEnd(ExtensionFactoryMethodEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitExtensionFieldsEnd(ExtensionFieldsEnd node) {
    containerFields(node, node.getFieldIdentifiers());
  }

  @override
  void visitExtensionMethodEnd(ExtensionMethodEnd node) {
    containerMethod(node, node.getNameIdentifier());
  }

  @override
  void visitExtensionTypeConstructorEnd(ExtensionTypeConstructorEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitExtensionTypeFactoryMethodEnd(ExtensionTypeFactoryMethodEnd node) {
    containerMethod(node, node.getIdentifiers().last.token.lexeme);
  }

  @override
  void visitExtensionTypeFieldsEnd(ExtensionTypeFieldsEnd node) {
    containerFields(node, node.getFieldIdentifiers());
  }

  @override
  void visitExtensionTypeMethodEnd(ExtensionTypeMethodEnd node) {
    containerMethod(node, node.getNameIdentifier());
  }
}
