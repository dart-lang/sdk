// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SendRenamer extends ResolvedVisitor<String> {
  final ConflictingRenamer renamer;

  SendRenamer(this.renamer, elements) : super(elements);

  String visitSuperSend(Send node) => null;
  String visitOperatorSend(Send node) => null;
  String visitClosureSend(Send node) => null;
  String visitForeignSend(Send node) => null;

  String tryRenamePrivateId(Send node) {
    Identifier selector = node.selector.asIdentifier();
    assert(selector !== null);
    String originalName = selector.source.slowToString();
    if (originalName.startsWith('_')) {
      String newName = renamer.renamePrivateId(
          renamer.context.getLibrary(), originalName);
      if (node.receiver !== null) {
        // TODO: ugly, should be fixed with new renamer infrastructure.
        String receiver = new Unparser(renamer).unparse(node.receiver);
        newName = '$receiver.$newName';
      }
      return newName;
    }

    return null;
  }

  String visitDynamicSend(Send node) => tryRenamePrivateId(node);

  String visitGetterSend(Send node) {
    final element = elements[node];
    if (element === null || !element.isTopLevel()) {
      return tryRenamePrivateId(node);
    }
    return renamer.renameElement(element);
  }

  String visitStaticSend(Send node) {
    final element = elements[node];

    if (element.isTopLevel()) return renamer.renameElement(element);

    if (element.isGenerativeConstructor() || element.isFactoryConstructor()) {
      // Don't want to rename redirects to :this(args) or super calls.
      if (Initializers.isConstructorRedirect(node)) return null;
      if (Initializers.isSuperConstructorCall(node)) return null;

      TypeAnnotation typeAnnotation;
      if (node.selector is TypeAnnotation) {
        // <simple class name> case.
        typeAnnotation = node.selector;
      } else if (node.selector.receiver is TypeAnnotation) {
        // <complex generic type> case.
        typeAnnotation = node.selector.receiver;
      } else {
        internalError("Don't know how to deduce type", node: node);
      }
      final type = new Unparser(renamer).unparse(typeAnnotation);

      final constructor = element.asFunctionElement().cachedNode;
      final nameAsSend = constructor.name.asSend();
      if (nameAsSend !== null) {
        final name = nameAsSend.selector.asIdentifier().source.slowToString();
        return '$type.$name';
      }
      return '$type';
    }

    return null;
  }

  void internalError(String reason, [Node node]) {
    renamer.compiler.cancel(reason: reason, node: node);
  }
}

/**
 * Renames only top-level elements that would let to ambiguity if not renamed.
 * TODO(smok): Make sure that top-level fields are correctly renamed.
 */
class ConflictingRenamer extends Renamer {
  final Compiler compiler;
  final Map<LibraryElement, Map<String, String>> renamed;
  final Set<String> usedTopLevelIdentifiers;
  final Map<LibraryElement, String> imports;
  int privateNameCounter = 0;
  TreeElements contextElements;
  Element context;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;

  ConflictingRenamer(this.compiler) :
      renamed = new Map<LibraryElement, Map<String, String>>(),
      usedTopLevelIdentifiers = new Set<String>(),
      imports = new Map<LibraryElement, String>();

  void setContext(Element element) {
    this.context = element;
    contextElements = resolvedElements[element];
  }

  String renameSendMethod(Send send) =>
      new SendRenamer(this, contextElements).visitSend(send);

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
    if (context.isGenerativeConstructor() || context.isFactoryConstructor()) {
      // Two complicated cases for class/interface renaming:
      // 1) class which implements constructors of other interfaces, but not
      //    implements interfaces themselves:
      //      0.dart: class C { I(); }
      //      1.dart and 2.dart: interface I default C { I(); }
      //    now we have to duplicate our I() constructor in C class with
      //    proper names.
      // 2) (even worse for us):
      //      0.dart: class C { C(); }
      //      1.dart: interface C default p0.C { C(); }
      //    the second case is just a bug now.
      final enclosingClass = context.getEnclosingClass();
      if (node.token.slowToString() == enclosingClass.name.slowToString()) {
        // TODO: distinguish the case of constructor vs. nested named closure
        // (see function_syntax_test).
        // TODO: fix the bugs above and turn if into the assert.
        return renameElement(enclosingClass);
      }
    }
    if (context.isFunction() && context.isTopLevel() &&
        context.cachedNode.name == node) {
      return renameElement(context);
    }
    // TODO: as the rest of renameIdentifier should go closer to
    // Emitter.outputElement.
    // Note: this code should only rename private identifiers for class'
    // fields/getters/setters/methods.  Top-level identifiers are renamed
    // just to escape conflicts and that should be enough as we shouldn't
    // be able to resolve private identifiers for other libraries.
    final originalName = node.source.slowToString();
    if (originalName.startsWith('_')) {
      return '${renamePrivateId(context.getLibrary(), originalName)}';
    }
    return null;
  }

  String getName(LibraryElement library, String originalName, renamer) =>
      renamed.putIfAbsent(library, () => <String>{})
          .putIfAbsent(originalName, renamer);

  String renamePrivateId(LibraryElement library, String originalName) =>
      getName(library, originalName,
              () => '_${privateNameCounter++}${originalName}');

  String renameElement(Element element) {
    // TODO: investigate what went wrong here.
    if (!element.isTopLevel()) return null;

    // This comes from currently buggy TypeAnnotation renamer.
    // It should be solved in there and it will be solved with
    // new fancy renamer. TODO: remove this cruft.
    if (element === compiler.types.voidType.element) return null;

    // TODO(smok): Make sure that the new name does not conflict with existing
    // local identifiers.
    generateUniqueName(name) {
      while (usedTopLevelIdentifiers.contains(name)) name = 'p_$name';
      usedTopLevelIdentifiers.add(name);
      return name;
    }

    String originalName = element.name.slowToString();
    LibraryElement library = element.getLibrary();
    if (library === compiler.coreLibrary) return originalName;
    if (isDartCoreLib(compiler, library)) {
      final prefix =
          imports.putIfAbsent(library, () => generateUniqueName('p'));
      return '$prefix.$originalName';
    }

    return getName(library, originalName,
                   () => generateUniqueName(originalName));
  }
}
