// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mirror_renamer;

class MirrorRenamerImpl implements MirrorRenamer {
  static const String MIRROR_HELPER_GET_NAME_FUNCTION = 'helperGetName';
  static final Uri DART_MIRROR_HELPER =
      new Uri(scheme: 'dart', path: '_mirror_helper');
  static const String MIRROR_HELPER_SYMBOLS_MAP_NAME = '_SYMBOLS';

  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  final LibraryElement helperLibrary;

  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  final FunctionElement getNameFunction;

  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  final FieldElement symbolsMapVariable;

  /// Maps mangled name to original name.
  Map<String, String> symbols = new Map<String, String>();

  /// Contains all occurrencs of MirrorSystem.getName() calls in the user code.
  List<Node> mirrorSystemGetNameNodes = <Node>[];

  /**
   *  Initialized when the placeholderCollector collects the FunctionElement
   *  backend.mirrorHelperGetNameFunction which represents the helperGetName
   *  function in _mirror_helper.
   */
  FunctionExpression get getNameFunctionNode => getNameFunction.node;
  VariableDefinitions get symbolsMapNode => symbolsMapVariable.node;
  Compiler compiler;
  DartBackend backend;

  MirrorRenamerImpl(this.compiler, this.backend, LibraryElement library)
      : this.helperLibrary = library,
        getNameFunction = library.find(
            MirrorRenamerImpl.MIRROR_HELPER_GET_NAME_FUNCTION),
        symbolsMapVariable = library.find(
            MirrorRenamerImpl.MIRROR_HELPER_SYMBOLS_MAP_NAME);

  bool isMirrorHelperLibrary(LibraryElement element) {
    return element == helperLibrary;
  }

  void registerStaticSend(Element currentElement, Element target, Send node) {
    if (target == compiler.mirrorSystemGetNameFunction &&
        currentElement.library != helperLibrary) {
      // Access to `MirrorSystem.getName` that needs to be redirected to the
      // [getNameFunction].
      mirrorSystemGetNameNodes.add(node);
    }
  }

  /**
   * Adds a toplevel node to the output containing a map from the mangled
   * to the unmangled names and replaces calls to MirrorSystem.getName()
   * with calls to the corresponding wrapper from _mirror_helper which has
   * been added during resolution. [renames] is assumed to map nodes in user
   * code to mangled names appearing in output code, and [topLevelNodes] should
   * contain all the toplevel ast nodes that will be emitted in the output.
   */
  void addRenames(Map<Node, String> renames, List<Node> topLevelNodes,
                  PlaceholderCollector placeholderCollector) {
    // Right now we only support instances of MirrorSystem.getName,
    // hence if there are no occurence of these we don't do anything.
    if (mirrorSystemGetNameNodes.isEmpty) {
      return;
    }

    Node parse(String text) {
      Token tokens = compiler.scanner.tokenize(text);
      return compiler.parser.parseCompilationUnit(tokens);
    }

    // Add toplevel map containing all renames of members.
    symbols = new Map<String, String>();
    for (Set<Identifier> s in placeholderCollector.memberPlaceholders.values) {
      // All members in a set have the same name so we only need to look at one.
      Identifier sampleNode = s.first;
      symbols.putIfAbsent(renames[sampleNode], () => sampleNode.source);
    }

    Identifier symbolsMapIdentifier =
        symbolsMapNode.definitions.nodes.head.asSend().selector;
    assert(symbolsMapIdentifier != null);
    topLevelNodes.remove(symbolsMapNode);

    StringBuffer sb = new StringBuffer(
        'const ${renames[symbolsMapIdentifier]} = const<String,String>{');
    bool first = true;
    for (String mangledName in symbols.keys) {
      if (!first) {
        sb.write(',');
      } else {
        first = false;
      }
      sb.write("'$mangledName' : '");
      sb.write(symbols[mangledName]);
      sb.write("'");
    }
    sb.write('};');
    sb.writeCharCode(0); // Terminate the string with '0', see [StringScanner].
    topLevelNodes.add(parse(sb.toString()));

    // Replace calls to Mirrorsystem.getName with calls to helper function.
    mirrorSystemGetNameNodes.forEach((node) {
      renames[node.selector] = renames[getNameFunctionNode.name];
      renames[node.receiver] = '';
    });
  }
}
