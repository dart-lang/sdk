// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Renames only top-level elements that would let to ambiguity if not renamed.
 * TODO(smok): Make sure that top-level fields and methods correctly renamed.
 */
class ConflictingRenamer extends Renamer {
  final Compiler compiler;
  final Map<Element, String> renamed;
  final Set<String> usedTopLevelIdentifiers;
  TreeElements contextElements;
  Element context;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;

  ConflictingRenamer(this.compiler) :
      renamed = new Map<Element, String>(),
      usedTopLevelIdentifiers = new Set<String>();

  void setContext(Element element) {
    this.context = element;
    contextElements = resolvedElements[element];
  }

  String renameSendMethod(Send send) {
    // Rename only if this Send is a function call.
    if (contextElements[send] !== null && contextElements[send].isFunction()) {
      return renameElement(contextElements[send]);
    } else {
      return null;
    }
  }

  String renameTypeName(TypeAnnotation typeAnnotation) {
    if (contextElements === null
        || contextElements.getType(typeAnnotation) === null) {
      // We have no info about this type from resolver.
      // This happens for class member fields.
      // TODO(smok): Maybe resolver should have this information, fix if so.
      if (context.isField()
          && context.variables.computeType(compiler) !== null) {
        // A field.
        return renameType(context.variables.type);
      } else {
        return typeAnnotation.typeName.unparse();
      }
    }

    // TODO(smok): Check if resolver can help us identifying factory
    // constructors.
    Type type = contextElements.getType(typeAnnotation);
    if (typeAnnotation.typeName is Send
        && typeAnnotation.typeName.receiver.source.slowToString() 
            == type.name.slowToString()) {
      // Got factory invocation. Need to rename first part.
      return "${renameType(type)}."
          "${typeAnnotation.typeName.selector.source.slowToString()}";
    }
    return renameType(type);
  }

  String renameType(Type type) => renameElement(type.element);

  String renameIdentifier(Identifier node) {
    if (context.isGenerativeConstructor()) {
      // This is either a factory constructor or simple one.
      // TODO(smok): Check if resolver can help us identifying factory
      // constructors.
      var enclosingClass = context.getEnclosingClass();
      if (node.token.slowToString() == context.name.slowToString()
          || enclosingClass.name.slowToString() == node.token.slowToString()) {
        return renameElement(enclosingClass);
      }
    }
    if (context.isFunction() && context.cachedNode.name == node) {
      return renameElement(context);
    }
    return null;
  }

  String renameElement(Element element) {
    String originalName = element.name.slowToString();
    if (element.getLibrary() == compiler.coreLibrary || !element.isTopLevel()) {
      return originalName;
    }
    if (renamed[element] !== null) {
      return renamed[element];
    }

    // Not renamed and top element.
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    String name = originalName;
    while (usedTopLevelIdentifiers.contains(name)) {
      name = "_$name";
    }
    usedTopLevelIdentifiers.add(name);
    renamed[element] = name;
    return name;
  }
}
