// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Renames only top-level elements that would let to ambiguity if not renamed.
 * TODO(smok): Make sure that top-level fields are correctly renamed.
 */
class ConflictingRenamer extends Renamer {
  final Compiler compiler;
  final Map<Element, String> renamed;
  final Set<String> usedTopLevelIdentifiers;
  final Map<LibraryElement, String> imports;
  TreeElements contextElements;
  Element context;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;

  ConflictingRenamer(this.compiler) :
      renamed = new Map<Element, String>(),
      usedTopLevelIdentifiers = new Set<String>(),
      imports = new Map<LibraryElement, String>();

  void setContext(Element element) {
    this.context = element;
    contextElements = resolvedElements[element];
  }

  String getFactoryName(FunctionExpression node) =>
      node.name.asSend().selector.asIdentifier().source.slowToString();

  bool isNamedConstructor(Element element) =>
      element.isGenerativeConstructor()
          && element.asFunctionElement().cachedNode.name is Send;

  String renameSendMethod(Send send) {
    if (contextElements[send] === null) return null;
    Element element = contextElements[send];
    if (element.isTopLevel()) {
      return renameElement(element);
    } else if (isNamedConstructor(element)
        // Don't want to rename redirects to :this(args).
        && !Initializers.isConstructorRedirect(send)
        // Don't want to rename super calls.
        && !Initializers.isSuperConstructorCall(send)) {
      FunctionExpression constructor = element.asFunctionElement().cachedNode;
      return '${renameType(element.getEnclosingClass().type)}'
          '.${getFactoryName(constructor)}';
    } else {
      return null;
    }
  }

  String renameTypeName(TypeAnnotation typeAnnotation) {
    Type type;
    if (context.isClass()) {
      // This only happens if we're unparsing class declaration.
      type = new TypeResolver(compiler)
          .resolveTypeAnnotation(typeAnnotation, null, context);
    } else {
      type = compiler.resolveTypeAnnotation(context, typeAnnotation);
    }
    return renameType(type);
  }

  String renameType(Type type) => renameElement(type.element);

  String renameIdentifier(Identifier node) {
    if (context.isGenerativeConstructor()) {
      // This is either a named constructor or simple one.
      // TODO(smok): Check if resolver can help us identifying named
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
    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    if (renamed[element] !== null) return renamed[element];

    generateUniqueName(name) {
      while (usedTopLevelIdentifiers.contains(name)) {
        name = "\$$name";
      }
      usedTopLevelIdentifiers.add(name);
      return name;
    }

    String originalName = element.name.slowToString();
    // TODO(antonm): we should rename lib private names as well.
    if (!element.isTopLevel()) return originalName;
    final library = element.getLibrary();
    if (library === compiler.coreLibrary) return originalName;
    if (isDartCoreLib(compiler, library)) {
      final prefix =
          imports.putIfAbsent(library, () => generateUniqueName('p'));
      return '$prefix.$originalName';
    }
    return renamed[element] = generateUniqueName(originalName);
  }
}
