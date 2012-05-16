// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CGBlock {
  int _blockType;             // Code type of this block
  int _indent;                // Number of spaces to prefix for each statement
  bool _inEach;               // This block or any currently active blocks is a
                              // #each.  If so then any element marked with a
                              // var attribute is repeated therefore the var
                              // is a List type instead of an Element type.
  String _localName;          // optional local name for #each or #with
  List<CGStatement> _stmts;
  int localIndex;             // Local variable index (e.g., e0, e1, etc.)

  // Block Types:
  static final int CONSTRUCTOR = 0;
  static final int EACH = 1;
  static final int WITH = 2;

  CGBlock([this._indent = 4,
           this._blockType = CGBlock.CONSTRUCTOR,
           this._inEach = false,
           this._localName = null]) :
      _stmts = new List<CGStatement>(), localIndex = 0 {
    assert(_blockType >= CGBlock.CONSTRUCTOR && _blockType <= CGBlock.WITH);
  }

  bool get anyStatements() => !_stmts.isEmpty();
  bool get isConstructor() => _blockType == CGBlock.CONSTRUCTOR;
  bool get isEach() => _blockType == CGBlock.EACH;
  bool get isWith() => _blockType == CGBlock.WITH;

  bool get hasLocalName() => _localName != null;
  String get localName() => _localName;

  CGStatement push(var elem, var parentName, [bool exact = false]) {
    var varName;
    if (elem is TemplateElement && elem.hasVar) {
      varName = elem.varName;
    } else {
      varName = localIndex++;
    }

    CGStatement stmt = new CGStatement(elem, _indent, parentName, varName,
        exact, _inEach);
    _stmts.add(stmt);

    return stmt;
  }

  void pop() {
    _stmts.removeLast();
  }

  void add(String value) {
    if (_stmts.last() != null) {
      _stmts.last().add(value);
    }
  }

  CGStatement get last() => _stmts.length > 0 ? _stmts.last() : null;

  /**
   * Returns mixed list of elements marked with the var attribute.  If the
   * element is inside of a #each the name exposed is:
   *
   *      List varName;
   *
   * otherwise it's:
   *
   *      var varName;
   *
   * TODO(terry): For scalars var varName should be Element tag type e.g.,
   *
   *                   DivElement varName;
   */
  String get globalDeclarations() {
    StringBuffer buff = new StringBuffer();
    for (final CGStatement stmt in _stmts) {
      buff.add(stmt.globalDeclaration());
    }

    return buff.toString();
  }

  /**
   * List of statement constructors for each var inside a #each.
   *
   *    ${#each products}
   *      <div var=myVar>...</div>
   *    ${/each}
   *
   * returns:
   *
   *    myVar = [];
   */
  String get globalInitializers() {
    StringBuffer buff = new StringBuffer();
    for (final CGStatement stmt in _stmts) {
      buff.add(stmt.globalInitializers());
    }

    return buff.toString();
  }

  String get codeBody() {
    StringBuffer buff = new StringBuffer();

    for (final CGStatement stmt in _stmts) {
      buff.add(stmt.emitDartStatement());
    }

    return buff.toString();
  }
}

class CGStatement {
  bool _exact;                  // If True not HTML construct instead exact stmt
  bool _repeating;              // Stmt in a #each this block or nested block.
  StringBuffer _buff;
  var _elem;
  int _indent;
  var parentName;
  String varName;
  bool _globalVariable;
  bool _closed;

  CGStatement(this._elem, this._indent, this.parentName, var varNameOrIndex,
      [this._exact = false, this._repeating = false]) :
        _buff = new StringBuffer(), _closed = false {

    if (varNameOrIndex is String) {
      // We have the global variable name
      varName = varNameOrIndex;
      _globalVariable = true;
    } else {
      // local index generate local variable name.
      varName = "e${varNameOrIndex}";
      _globalVariable = false;
    }
  }

  bool get hasGlobalVariable() => _globalVariable;
  String get variableName() => varName;

  String globalDeclaration() {
    if (hasGlobalVariable) {
      String spaces = Codegen.spaces(_indent);
      return (_repeating) ?
        "  List ${varName};    // Repeated elements.\n" : "  var ${varName};\n";
    }

    return "";
  }

  String globalInitializers() {
    if (hasGlobalVariable && _repeating) {
      return "    ${varName} = [];\n";
    }

    return "";
  }

  void add(String value) {
    _buff.add(value);
  }

  bool get isClosed() => _closed;

  void close() {
    if (_elem is TemplateElement && _elem.scoped) {
      add("</${_elem.tagName}>");
    }
    _closed = true;
  }

  String emitDartStatement() {
    StringBuffer statement = new StringBuffer();

    String spaces = Codegen.spaces(_indent);

    if (_exact) {
      statement.add("${spaces}${_buff.toString()};\n");
    } else {
      String localVar = "";
      String tmpRepeat;
      if (hasGlobalVariable) {
        if (_repeating) {
          tmpRepeat = "tmp_${varName}";
          localVar = "var ";
        }
      } else {
        localVar = "var ";
      }

      /* Emiting the following code fragment where varName is the attribute
         value for var=

            varName = new Element.html('HTML GOES HERE');
            parent.elements.add(varName);

         for repeating elements in a #each:

            var tmp_nnn = new Element.html('HTML GOES HERE');
            varName.add(tmp_nnn);
            parent.elements.add(tmp_nnn);

         for elements w/o var attribute set:

            var eNNN = new Element.html('HTML GOES HERE');
            parent.elements.add(eNNN);
       */
      if (_elem is TemplateCall) {
        // Call template NameEntry2
        String cls = _elem.toCall;
        String params = _elem.params;
        statement.add("\n${spaces}// Call template ${cls}.\n");
        statement.add(
            "${spaces}${localVar}${varName} = new ${cls}${params};\n");
        statement.add(
            "${spaces}${parentName}.elements.add(${varName}.root);\n");
      } else {
        bool isTextNode = _elem is TemplateText;
        String createType = isTextNode ? "Text" : "Element.html";
        if (tmpRepeat == null) {
          statement.add("${spaces}${localVar}${varName} = new ${createType}('");
        } else {
          statement.add(
              "${spaces}${localVar}${tmpRepeat} = new ${createType}('");
        }
        statement.add(isTextNode ? _buff.toString().trim() : _buff.toString());

        if (tmpRepeat == null) {
          statement.add(
            "');\n${spaces}${parentName}.elements.add(${varName});\n");
        } else {
          statement.add(
            "');\n${spaces}${parentName}.elements.add(${tmpRepeat});\n");
          statement.add("${spaces}${varName}.add(${tmpRepeat});\n");
        }
      }
    }

    return statement.toString();
  }
}

class Codegen {
  static final String SPACES = "                                              ";
  static String spaces(int numSpaces) {
    return SPACES.substring(0, numSpaces);
  }

  // TODO(terry): Before generating Dart class need a validate phase that
  //              checks mangles all class names to be prefix with the
  //              template name to avoid any class name collisions.  Also,
  //              investigate possible runtime check mode to insure that only
  //              valid CSS class names are used (in case someone uses strings
  //              and not the generated getters to the CSS class selector.  This
  //              mode would be slower would require that every class name set
  //              (maybe jQuery too) is for a particular view (requires walking
  //              the HTML tree looking for a parent template prefix that
  //              matches the CSS prefix. (more thinking needed).
  static String generate(List<Template> templates, String filename) {
    List<String> fileParts = filename.split('.');
    assert(fileParts.length == 2);
    filename = fileParts[0];

    StringBuffer buff = new StringBuffer();
    int injectId = 0;         // Inject function id

    buff.add("// Generated Dart class from HTML template.\n");
    buff.add("// DO NOT EDIT.\n\n");

    String addStylesheetFuncName = "add_${filename}_templatesStyles";

    for (final template in templates) {
      // Emit the template class.
      TemplateSignature sig = template.signature;
      buff.add(_emitClass(sig.name, sig.params, template.content,
        addStylesheetFuncName));
    }

    // TODO(terry): Stylesheet aggregator should not be global needs to be
    //              bound to this template file not global to the app.

    // Emit the stylesheet aggregator.
    buff.add("\n\n// Inject all templates stylesheet once into the head.\n");
    buff.add("bool ${filename}_stylesheet_added = false;\n");
    buff.add("void ${addStylesheetFuncName}() {\n");
    buff.add("  if (!${filename}_stylesheet_added) {\n");
    buff.add("    StringBuffer styles = new StringBuffer();\n\n");

    buff.add("    // All templates stylesheet.\n");

    for (final template in templates) {
      TemplateSignature sig = template.signature;
      buff.add("    styles.add(${sig.name}.stylesheet);\n");
    }

    buff.add("\n    ${filename}_stylesheet_added = true;\n");

    buff.add("    document.head.elements.add(new Element.html('<style>"
             "\${styles.toString()}</style>'));\n");
    buff.add("  }\n");
    buff.add("}\n");

    return buff.toString();
  }

  static String _emitCSSSelectors(css.Stylesheet stylesheet) {
    if (stylesheet == null) {
      return "";
    }

    List<String> classes = [];

    for (final production in stylesheet.topLevels) {
      if (production is css.IncludeDirective) {
        for (final topLevel in production.styleSheet.topLevels) {
          if (topLevel is css.RuleSet) {
            classes = css.Generate.computeClassSelectors(topLevel, classes);
          }
        }
      } else if (production is css.RuleSet) {
        classes = css.Generate.computeClassSelectors(production, classes);
      }
    }

    List<String> dartNames = [];

    for (final String knownClass in classes) {
      StringBuffer dartName = new StringBuffer();
      List<String> splits = knownClass.split('-');
      if (splits.length > 0) {
        dartName.add(splits[0]);
        for (int idx = 1; idx < splits.length; idx++) {
          String part = splits[idx];
          // Character between 'a'..'z' mapped to 'A'..'Z'
          dartName.add("${part[0].toUpperCase()}${part.substring(1)}");
        }
        dartNames.add(dartName.toString());
      }
    }

    StringBuffer buff = new StringBuffer();
    if (classes.length > 0) {
      assert(classes.length == dartNames.length);
      buff.add("\n  // CSS class selectors for this template.\n");
      for (int i = 0; i < classes.length; i++) {
        buff.add(
          "  static String get ${dartNames[i]}() => \"${classes[i]}\";\n");
      }
    }

    return buff.toString();
  }

  static String _emitClass(String className,
                           List<Map<Identifier, Identifier>> params,
                           TemplateContent content,
                           String addStylesheetFuncName) {
    StringBuffer buff = new StringBuffer();

    // Emit the template class.
    buff.add("class ${className} {\n");

    buff.add("  Map<String, Object> _scopes;\n");
    buff.add("  Element _fragment;\n\n");

    bool anyParams = false;
    for (final param in params) {
      buff.add("  ${param['type']} ${param['name']};\n");
      anyParams = true;
    }
    if (anyParams) buff.add("\n");

    ElemCG ecg = new ElemCG();

    if (!ecg.pushBlock()) {
      world.error("Error at ${content}");
    }

    var root = content.html.children.length > 0 ? content.html.children[0] :
        content.html;
    bool firstTime = true;
    for (var child in root.children) {
      if (child is TemplateText) {
        if (!firstTime) {
          ecg.closeStatement();
        }

        String textNodeValue = child.value.trim();
        if (textNodeValue.length > 0) {
          CGStatement stmt = ecg.pushStatement(child, "_fragment");
        }
      }
      ecg.emitConstructHtml(child, "", "_fragment");
      firstTime = false;
    }

    // Create all element names marked with var.
    String decls = ecg.globalDeclarations;
    if (decls.length > 0) {
      buff.add("\n  // Elements bound to a variable:\n");
      buff.add("${decls}\n");
    }

    // Create the constructor.
    buff.add("  ${className}(");
    bool firstParam = true;
    for (final param in params) {
      if (!firstParam) {
        buff.add(", ");
      }
      buff.add("this.${param['name']}");
      firstParam = false;
    }
    buff.add(") : _scopes = new Map<String, Object>() {\n");

    String initializers = ecg.globalInitializers;
    if (initializers.length > 0) {
      buff.add("    //Global initializers.\n");
      buff.add("${initializers}\n");
    }

    buff.add("    // Insure stylesheet for template exist in the document.\n");
    buff.add("    ${addStylesheetFuncName}();\n\n");

    buff.add("    _fragment = new DocumentFragment();\n");

    buff.add(ecg.codeBody);     // HTML for constructor to build.

    buff.add("  }\n\n");        // End constructor

    buff.add(emitGetters(content.getters));

    buff.add("  Element get root() => _fragment;\n");

    // Emit all CSS class selectors:
    buff.add(_emitCSSSelectors(content.css));

    // Emit the injection functions.
    buff.add("\n  // Injection functions:");
    for (final expr in ecg.expressions) {
      buff.add("${expr}");
    }

    buff.add("\n  // Each functions:\n");
    for (var eachFunc in ecg.eachs) {
      buff.add("${eachFunc}\n");
    }

    buff.add("\n  // With functions:\n");
    for (var withFunc in ecg.withs) {
      buff.add("${withFunc}\n");
    }

    buff.add("\n  // CSS for this template.\n");
    buff.add("  static final String stylesheet = ");

    if (content.css != null) {
      buff.add("\'\'\'\n    ${content.css.toString()}\n");
      buff.add("  \'\'\';\n\n");

      // TODO(terry): Emit all known selectors for this template.
      buff.add("  // Stylesheet class selectors:\n");
    } else {
      buff.add("\"\";\n");
    }

    buff.add("  String safeHTML(String html) {\n");
    buff.add("    // TODO(terry): Escaping for XSS vulnerabilities TBD.\n");
    buff.add("    return html;\n");
    buff.add("  }\n");

    buff.add("}\n");              // End class

    return buff.toString();
  }

  // TODO(terry): Need to generate function to inject any TemplateExpressions
  //              to call SafeHTML wrapper.
  static String emitGetters(List<TemplateGetter> getters) {
    StringBuffer buff = new StringBuffer();
    for (final TemplateGetter getter in getters) {
      buff.add('  String ${getter.getterSignatureAsString()} {\n');
      buff.add('    return \'\'\'');
      var docFrag = getter.docFrag.children[0];
      for (final child in docFrag.children) {
        buff.add(child.toString().trim());
      }
      buff.add('\'\'\';\n');
      buff.add('  }\n\n');
    }

    return buff.toString();
  }
}

class ElemCG {
  // List of identifiers and quoted strings (single and double quoted).
  var identRe = const RegExp(
    "\s*('\"\\'\\\"[^'\"\\'\\\"]+'\"\\'\\\"|[_A-Za-z][_A-Za-z0-9]*)");

  List<CGBlock> _cgBlocks;
  StringBuffer _globalDecls;        // Global var declarations for all blocks.
  StringBuffer _globalInits;        // Global List var initializtion for all
                                    // blocks in a #each.
  String funcCall;                  // Func call after element creation?
  List<String> expressions;         // List of injection function declarations.
  List<String> eachs;               // List of each function declarations.
  List<String> withs;               // List of with function declarations.

  ElemCG() :
    expressions = [],
    eachs = [],
    withs = [],
    _cgBlocks = [],
    _globalDecls = new StringBuffer(),
    _globalInits = new StringBuffer();

  bool get isLastBlockConstructor() {
    CGBlock block = _cgBlocks.last();
    return block.isConstructor;
  }

  List<String> activeBlocksLocalNames() {
    List<String> result = [];

    for (final CGBlock block in _cgBlocks) {
      if (block.isEach || block.isWith) {
        if (block.hasLocalName) {
          result.add(block.localName);
        }
      }
    }

    return result;
  }

  /**
   * Active block with this localName.
   */
  bool matchBlocksLocalName(String name) {
    for (final CGBlock block in _cgBlocks) {
      if (block.isEach || block.isWith) {
        if (block.hasLocalName && block.localName == name) {
          return true;
        }
      }
    }

    return false;
  }

  /**
   * Any active blocks?
   */
  bool isNestedBlock() {
    for (final CGBlock block in _cgBlocks) {
      if (block.isEach || block.isWith) {
        return true;
      }
    }

    return false;
  }

  /**
   * Any active blocks with localName?
   */
  bool isNestedNamedBlock() {
    for (final CGBlock block in _cgBlocks) {
      if ((block.isEach || block.isWith) && block.hasLocalName) {
        return true;
      }
    }

    return false;
  }

  // Any current active #each blocks.
  bool anyEachBlocks(int blockToCreateType) {
    bool result = blockToCreateType == CGBlock.EACH;

    for (final CGBlock block in _cgBlocks) {
      if (block.isEach) {
        result = result || true;
      }
    }

    return result;
  }

  bool pushBlock([int indent = 4, int blockType = CGBlock.CONSTRUCTOR,
                  String itemName = null]) {
    if (itemName != null && matchBlocksLocalName(itemName)) {
      world.error("Active block already exist with local name: ${itemName}.");
      return false;
    } else if (itemName == null && this.isNestedBlock()) {
      world.error('''
Nested #each or #with must have a localName;
 \n  #each list [localName]\n  #with object [localName]''');
      return false;
    }
    _cgBlocks.add(
        new CGBlock(indent, blockType, anyEachBlocks(blockType), itemName));

    return true;
  }

  void popBlock() {
    _globalDecls.add(lastBlock.globalDeclarations);
    _globalInits.add(lastBlock.globalInitializers);
    _cgBlocks.removeLast();
  }

  CGStatement pushStatement(var elem, var parentName) {
    return lastBlock.push(elem, parentName, false);
  }

  CGStatement pushExactStatement(var elem, var parentName) {
    return lastBlock.push(elem, parentName, true);
  }

  bool get isClosedStatement() {
    return (lastBlock != null && lastBlock.last != null) ?
        lastBlock.last.isClosed : false;
  }

  void closeStatement() {
    if (lastBlock != null && lastBlock.last != null &&
        !lastBlock.last.isClosed) {
      lastBlock.last.close();
    }
  }

  String get lastVariableName() {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.variableName;
    }
  }

  String get lastParentName() {
    if (lastBlock != null && lastBlock.last != null) {
      return lastBlock.last.parentName;
    }
  }

  CGBlock get lastBlock() => _cgBlocks.length > 0 ? _cgBlocks.last() : null;

  void add(String str) {
    _cgBlocks.last().add(str);
  }

  String get globalDeclarations() {
    assert(_cgBlocks.length == 1);    // Only constructor body should be left.
    _globalDecls.add(lastBlock.globalDeclarations);
    return _globalDecls.toString();
  }

  String get globalInitializers() {
    assert(_cgBlocks.length == 1);    // Only constructor body should be left.
    _globalInits.add(lastBlock.globalInitializers);
    return _globalInits.toString();
  }

  String get codeBody() {
    closeStatement();
    return _cgBlocks.last().codeBody;
  }

  /* scopeName for expression
   * parentVarOrIndex if # it's a local variable if string it's an exposed
   * name (specified by the var attribute) for this element.
   *
   */
  emitElement(var elem,
              [String scopeName = "",
               var parentVarOrIdx = 0,
               bool immediateNestedEach = false]) {
    if (elem is TemplateElement) {
      if (!elem.isFragment) {
        add("<${elem.tagName}${elem.attributesToString()}>");
      }
      String prevParent = lastVariableName;
      for (var childElem in elem.children) {
        if (childElem is TemplateElement) {
          closeStatement();
          if (childElem.hasVar) {
            emitConstructHtml(childElem, scopeName, prevParent,
              childElem.varName);
          } else {
            emitConstructHtml(childElem, scopeName, prevParent);
          }
          closeStatement();
        } else {
          emitElement(childElem, scopeName, parentVarOrIdx);
        }
      }

      // Close this tag.
      closeStatement();
    } else if (elem is TemplateText) {
      String outputValue = elem.value.trim();
      if (outputValue.length > 0) {
        bool emitTextNode = false;
        if (isClosedStatement) {
          String prevParent = lastParentName;
          CGStatement stmt = pushStatement(elem, prevParent);
          emitTextNode = true;
        }

        // TODO(terry): Need to interpolate following:
        //      {sp}  → space
        //      {nil} → empty string
        //      {\r}  → carriage return
        //      {\n}  → new line (line feed)
        //      {\t}  → tab
        //      {lb}  → left brace
        //      {rb}  → right brace

        add("${outputValue}");            // remove leading/trailing whitespace.

        if (emitTextNode) {
          closeStatement();
        }
      }
    } else if (elem is TemplateExpression) {
      emitExpressions(elem, scopeName);
    } else if (elem is TemplateEachCommand) {
      // Signal to caller new block coming in, returns "each_" prefix
      emitEach(elem, "List", elem.listName.name, "parent", immediateNestedEach,
          elem.hasLoopItem ? elem.loopItem.name : null);
    } else if (elem is TemplateWithCommand) {
      // Signal to caller new block coming in, returns "each_" prefix
      emitWith(elem, "var", elem.objectName.name, "parent",
          elem.hasBlockItem ? elem.blockItem.name : null);
    } else if (elem is TemplateCall) {
      emitCall(elem, parentVarOrIdx);
    }
  }

  // TODO(terry): Hack prefixing all names with "${scopeName}." but don't touch
  //              quoted strings.
  String _resolveNames(String expr, String prefixPart) {
    StringBuffer newExpr = new StringBuffer();
    Iterable<Match> matches = identRe.allMatches(expr);

    int lastIdx = 0;
    for (Match m in matches) {
      if (m.start() > lastIdx) {
        newExpr.add(expr.substring(lastIdx, m.start()));
      }

      bool identifier = true;
      if (m.start() > 0)  {
        int charCode = expr.charCodeAt(m.start() - 1);
        // Starts with ' or " then it's not an identifier.
        identifier = charCode != 34 /* " */ && charCode != 39 /* ' */;
      }

      String strMatch = expr.substring(m.start(), m.end());
      if (identifier) {
        newExpr.add("${prefixPart}.${strMatch}");
      } else {
        // Quoted string don't touch.
        newExpr.add("${strMatch}");
      }
      lastIdx = m.end();
    }

    if (expr.length > lastIdx) {
      newExpr.add(expr.substring(lastIdx));
    }

    return newExpr.toString();
  }

  /**
   * Construct the HTML each top-level node get's it's own variable.
   *
   * TODO(terry): Might want to optimize if the other top-level nodes have no
   *              control structures (with, each, if, etc.). We could
   *              synthesize a root node and create all the top-level nodes
   *              under the root node with one innerHTML.
   */
  void emitConstructHtml(var elem,
                         [String scopeName = "",
                          String parentName = "parent",
                          var varIndex = 0,
                          bool immediateNestedEach = false]) {
    if (elem is TemplateElement) {
      CGStatement stmt = pushStatement(elem, parentName);
      emitElement(elem, scopeName, stmt.hasGlobalVariable ?
          stmt.variableName : varIndex);
    } else {
      emitElement(elem, scopeName, varIndex, immediateNestedEach);
    }
  }

  /* Any references to products.sales needs to be remaped to item.sales
   * for now it's a hack look for first dot and replace with item.
   */
  String eachIterNameToItem(String iterName) {
    String newName = iterName;
    var dotForIter = iterName.indexOf('.');
    if (dotForIter >= 0) {
      newName = "_item${iterName.substring(dotForIter)}";
    }

    return newName;
  }

  emitExpressions(TemplateExpression elem, String scopeName) {
    StringBuffer func = new StringBuffer();

    String newExpr = elem.expression;
    bool anyNesting = isNestedNamedBlock();
    if (scopeName.length > 0 && !anyNesting) {
      // In a block #command need the scope passed in.
      add("\$\{inject_${expressions.length}(_item)\}");
      func.add("\n  String inject_${expressions.length}(var _item) {\n");
      // Escape all single-quotes, this expression is embedded as a string
      // parameter for the call to safeHTML.
      newExpr = _resolveNames(newExpr.replaceAll("'", "\\'"), "_item");
    } else {
      // Not in a block #command item isn't passed in.
      add("\$\{inject_${expressions.length}()\}");
      func.add("\n  String inject_${expressions.length}() {\n");

      if (anyNesting) {
        func.add(defineScopes());
      }
    }

    // Construct the active scope names for name resolution.

    func.add("    return safeHTML('\$\{${newExpr}\}');\n");
    func.add("  }\n");

    expressions.add(func.toString());
  }

  emitCall(TemplateCall elem, String scopeName) {
    pushStatement(elem, scopeName);
  }

  emitEach(TemplateEachCommand elem, String iterType, String iterName,
      var parentVarOrIdx, bool nestedImmediateEach, [String itemName = null]) {
    TemplateDocument docFrag = elem.documentFragment;

    int eachIndex = eachs.length;
    eachs.add("");

    StringBuffer funcBuff = new StringBuffer();
    // Prepare function call "each_N(iterName," parent param computed later.
    String funcName = "each_${eachIndex}";

    funcBuff.add("  ${funcName}(${iterType} items, Element parent) {\n");

    String paramName = injectParamName(itemName);
    if (paramName == null) {
      world.error("Use a different local name; ${itemName} is reserved.");
    }
    funcBuff.add("    for (var ${paramName} in items) {\n");

    if (!pushBlock(6, CGBlock.EACH, itemName)) {
      world.error("Error at ${elem}");
    }

    addScope(6, funcBuff, itemName);

    TemplateElement docFragChild = docFrag.children[0];
    var children = docFragChild.isFragment ?
        docFragChild.children : docFrag.children;
    for (var child in children) {
      // If any immediate children of the parent #each is an #each then
      // so we need to pass the outer #each parent not the last statement's
      // variableName when calling the nested #each.
      bool eachChild = (child is TemplateEachCommand);
      emitConstructHtml(child, iterName, parentVarOrIdx, 0, eachChild);
    }

    funcBuff.add(codeBody);

    removeScope(6, funcBuff, itemName);

    popBlock();

    funcBuff.add("    }\n");
    funcBuff.add("  }\n");

    eachs[eachIndex] = funcBuff.toString();

    // If nested each then we want to pass the parent otherwise we'll use the
    // varName.
    var varName = nestedImmediateEach ? "parent" : lastBlockVarName;

    pushExactStatement(elem, parentVarOrIdx);

    // Setup call to each func as "each_n(xxxxx, " the parent param is filled
    // in later when we known the parent variable.
    String eachParam =
        (itemName == null) ? eachIterNameToItem(iterName) : iterName;
    add("${funcName}(${eachParam}, ${varName})");
}

  emitWith(TemplateWithCommand elem, String withType, String withName,
      var parentVarIndex, [String itemName = null]) {
    TemplateDocument docFrag = elem.documentFragment;

    int withIndex = withs.length;
    withs.add("");

    StringBuffer funcBuff = new StringBuffer();
    // Prepare function call "each_N(iterName," parent param computed later.
    String funcName = "with_${withIndex}";

    String paramName = injectParamName(itemName);
    if (paramName == null) {
      world.error("Use a different local name; ${itemName} is reserved.");
    }
    funcBuff.add("  ${funcName}(${withType} ${paramName}, Element parent) {\n");

    if (!pushBlock(4, CGBlock.WITH, itemName)) {
      world.error("Error at ${elem}");
    }

    TemplateElement docFragChild = docFrag.children[0];
    var children = docFragChild.isFragment ?
        docFragChild.children : docFrag.children;
    for (var child in children) {
      emitConstructHtml(child, withName, "parent");
    }

    addScope(4, funcBuff, itemName);
    funcBuff.add(codeBody);
    removeScope(4, funcBuff, itemName);

    popBlock();

    funcBuff.add("  }\n");

    withs[withIndex] = funcBuff.toString();

    // Compute parent node variable before pushing with statement.
    String parentVarName = lastBlockVarName;

    pushExactStatement(elem, parentVarIndex);

    // Setup call to each func as "each_n(xxxxx, " the parent param is filled
    // in later when we known the parent variable.
    add("${funcName}(${withName}, ${parentVarName})");
  }

  String get lastBlockVarName() {
    var varName;
    if (lastBlock != null && lastBlock.anyStatements) {
      varName = lastBlock.last.variableName;
    } else {
      varName = "_fragment";
    }

    return varName;
  }

  String injectParamName(String name) {
    // Local name _item is reserved.
    if (name != null && name == "_item") {
      return null;    // Local name is not valid.
    }

    return (name == null) ? "_item" : name;
  }

  addScope(int indent, StringBuffer buff, String item) {
    String spaces = Codegen.spaces(indent);

    if (item == null) {
      item = "_item";
    }
    buff.add("${spaces}_scopes[\"${item}\"] = ${item};\n");
  }

  removeScope(int indent, StringBuffer buff, String item) {
    String spaces = Codegen.spaces(indent);

    if (item == null) {
      item = "_item";
    }
    buff.add("${spaces}_scopes.remove(\"${item}\");\n");
  }

  String defineScopes() {
    StringBuffer buff = new StringBuffer();

    // Construct the active scope names for name resolution.
    List<String> names = activeBlocksLocalNames();
    if (names.length > 0) {
      buff.add("    // Local scoped block names.\n");
      for (String name in names) {
        buff.add("    var ${name} = _scopes[\"${name}\"];\n");
      }
      buff.add("\n");
    }

    return buff.toString();
  }

}
