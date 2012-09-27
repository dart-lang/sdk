// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.ImmutableSet;
import com.google.common.io.CharStreams;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.PackageLibraryManager;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartAnnotation;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartArrayLiteral;
import com.google.dart.compiler.ast.DartAssertStatement;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartBooleanLiteral;
import com.google.dart.compiler.ast.DartBreakStatement;
import com.google.dart.compiler.ast.DartCase;
import com.google.dart.compiler.ast.DartCatchBlock;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartConditional;
import com.google.dart.compiler.ast.DartContinueStatement;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartDefault;
import com.google.dart.compiler.ast.DartDirective;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartDoubleLiteral;
import com.google.dart.compiler.ast.DartEmptyStatement;
import com.google.dart.compiler.ast.DartExportDirective;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartImportDirective;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartMapLiteral;
import com.google.dart.compiler.ast.DartMapLiteralEntry;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartNamedExpression;
import com.google.dart.compiler.ast.DartNativeBlock;
import com.google.dart.compiler.ast.DartNativeDirective;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeWithMetadata;
import com.google.dart.compiler.ast.DartNullLiteral;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParameterizedTypeNode;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPartOfDirective;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartReturnBlock;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartSourceDirective;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartStringInterpolation;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSuperExpression;
import com.google.dart.compiler.ast.DartSwitchMember;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartSyntheticErrorExpression;
import com.google.dart.compiler.ast.DartSyntheticErrorIdentifier;
import com.google.dart.compiler.ast.DartSyntheticErrorStatement;
import com.google.dart.compiler.ast.DartThisExpression;
import com.google.dart.compiler.ast.DartThrowExpression;
import com.google.dart.compiler.ast.DartTryStatement;
import com.google.dart.compiler.ast.DartTypeExpression;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartUnqualifiedInvocation;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;
import com.google.dart.compiler.ast.ImportCombinator;
import com.google.dart.compiler.ast.ImportHideCombinator;
import com.google.dart.compiler.ast.ImportShowCombinator;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.util.Lists;

import java.io.IOException;
import java.io.Reader;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * The Dart parser. Parses a single compilation unit and produces a {@link DartUnit}.
 * The grammar rules are taken from Dart.g revision 557.
 */
public class DartParser extends CompletionHooksParserBase {

  private final Source source;
  private final String sourceCode;
  private final boolean isDietParse;
  private final Set<String> prefixes;
  private final boolean corelibParse;
  private final Set<Integer> errorHistory = new HashSet<Integer>();
  private boolean isParsingInterface;
  private boolean isTopLevelAbstract;
  private int topLevelAbstractModifierPosition;
  private boolean isParsingClass;
  private int errorCount = 0;
  
  /**
   * Determines the maximum number of errors before terminating the parser. See
   * {@link #reportError(int, ErrorCode, Object...)}.
   */
  final int MAX_DEFAULT_ERRORS = Short.MAX_VALUE;

  // Pseudo-keywords that should also be valid identifiers.
  private static final String ABSTRACT_KEYWORD = "abstract";
  private static final String AS_KEYWORD = "as";
  private static final String CALL_KEYWORD = "call";
  public static final String DYNAMIC_KEYWORD = "dynamic";
  // TODO(scheglov) remove "Dynamic" support after
  // http://code.google.com/p/dart/issues/detail?id=5117
  // http://code.google.com/p/dart/issues/detail?id=5118
  public static final String DYNAMIC_KEYWORD_DEPRECATED = "Dynamic";
  private static final String EXPORT_KEYWORD = "export";
  private static final String EXTERNAL_KEYWORD = "external";
  private static final String FACTORY_KEYWORD = "factory";
  private static final String GETTER_KEYWORD = "get";
  private static final String HIDE_KEYWORD = "hide";
  private static final String IMPLEMENTS_KEYWORD = "implements";
  private static final String IMPORT_KEYWORD = "import";
  private static final String INTERFACE_KEYWORD = "interface";
  private static final String LIBRARY_KEYWORD = "library";
  private static final String NATIVE_KEYWORD = "native";
  private static final String OF_KEYWORD = "of";
  private static final String ON_KEYWORD = "on";
  private static final String OPERATOR_KEYWORD = "operator";
  private static final String PART_KEYWORD = "part";
  private static final String PREFIX_KEYWORD = "prefix";
  private static final String SETTER_KEYWORD = "set";
  private static final String SHOW_KEYWORD = "show";
  private static final String STATIC_KEYWORD = "static";
  private static final String TYPEDEF_KEYWORD = "typedef";


  public static final String[] PSEUDO_KEYWORDS = {
    ABSTRACT_KEYWORD,
    AS_KEYWORD,
    DYNAMIC_KEYWORD,
    DYNAMIC_KEYWORD_DEPRECATED,
    EXPORT_KEYWORD,
    EXTERNAL_KEYWORD,
    FACTORY_KEYWORD,
    GETTER_KEYWORD,
    IMPLEMENTS_KEYWORD,
    IMPORT_KEYWORD,
    LIBRARY_KEYWORD,
    OPERATOR_KEYWORD,
    PART_KEYWORD,
    SETTER_KEYWORD,
    STATIC_KEYWORD,
    TYPEDEF_KEYWORD
  };
  public static final Set<String> PSEUDO_KEYWORDS_SET = ImmutableSet.copyOf(PSEUDO_KEYWORDS);

  public static final String[] RESERVED_WORDS = {
      "break",
      "case",
      "catch",
      "class",
      "const",
      "continue",
      "default",
      "do",
      "else",
      "extends",
      "false",
      "final",
      "finally",
      "for",
      "if",
      "in",
      "is",
      "new",
      "null",
      "return",
      "super",
      "switch",
      "this",
      "throw",
      "true",
      "try",
      "var",
      "void",
      "while"};
  public static final Set<String> RESERVED_WORDS_SET = ImmutableSet.copyOf(RESERVED_WORDS);

  public DartParser(Source source,
                    String sourceCode,
                    boolean isDietParse,
                    Set<String> prefixes,
                    DartCompilerListener listener,
                    CompilerMetrics compilerMetrics) {
    super(new DartParserCommentsHelper.CommentParserContext(source, sourceCode, listener, compilerMetrics));
    this.source = source;
    this.sourceCode = sourceCode;
    this.isDietParse = isDietParse;
    this.prefixes = prefixes;
    this.corelibParse = source != null && PackageLibraryManager.isDartUri(source.getUri());
  }

  public static String read(Source source) throws IOException {
    return read(source.getSourceReader());
  }

  public static String read(Reader reader) throws IOException {
    try {
      return CharStreams.toString(reader);
    } finally {
      reader.close();
    }
  }

  /**
   * A flag indicating whether function expressions are allowed.  See
   * {@link #setAllowFunctionExpression(boolean)}.
   */
  private boolean allowFunctionExpression = true;

  /**
   * 'break' (with no labels) and 'continue' stmts are not valid
   * just anywhere, they must be inside a loop or a case stmt.
   *
   * A break with a label may be valid and is allowed through and
   * checked in the resolver.
   */
  private boolean inLoopStatement = false;
  private boolean inCaseStatement = false;

  /**
   * Set the {@link #allowFunctionExpression} flag indicating whether function expressions are
   * allowed, returning the old value. This is required to avoid ambiguity in a few places in the
   * grammar.
   *
   * @param allow true if function expressions are allowed, false if not
   * @return previous value of the flag, which should be restored
   */
  private boolean setAllowFunctionExpression(boolean allow) {
    boolean old = allowFunctionExpression;
    allowFunctionExpression = allow;
    return old;
  }

  /**
   * <pre>
   * compilationUnit
   *     : libraryDeclaration? topLevelDefinition* EOF
   *     ;
   *
   * libraryDeclaration
   *     : libraryDirective? importDirective* sourceDirective* resourceDirective* nativeDirective*
   *
   * topLevelDefinition
   *     : classDefinition
   *     | interfaceDefinition
   *     | functionTypeAlias
   *     | methodOrConstructorDeclaration functionStatementBody
   *     | type? getOrSet identifier formalParameterList functionStatementBody
   *     | CONST type? staticConstDeclarationList ';'
   *     | variableDeclaration ';'
   *     ;
   * </pre>
   */
  @Terminals(tokens={Token.EOS, Token.CLASS, Token.LIBRARY, Token.IMPORT, Token.SOURCE,
      Token.RESOURCE, Token.NATIVE})
  public DartUnit parseUnit() {
    DartSource dartSource = (DartSource) source;
    
    errorCount = 0;
    
    try {
      beginCompilationUnit();
      ctx.unitAboutToCompile(dartSource, isDietParse);
      DartUnit unit = new DartUnit(dartSource, isDietParse);

      // parse any directives at the beginning of the source
      parseDirectives(unit);

      while (!EOS()) {
        DartNodeWithMetadata node = null;
        beginTopLevelElement();
        List<DartAnnotation> metadata = parseMetadata();
        isParsingClass = isParsingInterface = false;
        // Check for ABSTRACT_KEYWORD.
        isTopLevelAbstract = false;
        topLevelAbstractModifierPosition = 0;
        if (optionalPseudoKeyword(ABSTRACT_KEYWORD)) {
          isTopLevelAbstract = true;
          topLevelAbstractModifierPosition = position();
        }
        // Parse top level element.
        if (optional(Token.CLASS)) {
          isParsingClass = true;
          node = done(parseClass());
        } else if (peekPseudoKeyword(0, INTERFACE_KEYWORD) && peek(1).equals(Token.IDENTIFIER)) {
          consume(Token.IDENTIFIER);
          isParsingInterface = true;
          node = done(parseClass());
        } else if (peekPseudoKeyword(0, TYPEDEF_KEYWORD)
            && (peek(1).equals(Token.IDENTIFIER) || peek(1).equals(Token.VOID) || peek(1).equals(Token.AS))) {
          consume(Token.IDENTIFIER);
          node = done(parseFunctionTypeAlias());
        } else if (looksLikeDirective()) {
          reportErrorWithoutAdvancing(ParserErrorCode.DIRECTIVE_OUT_OF_ORDER);
          parseDirectives(unit);
        } else {
          node = done(parseFieldOrMethod(false));
        }
        // Parsing was successful, add node.
        if (node != null) {
          setMetadata(node, metadata);
          unit.getTopLevelNodes().add(node);
          // Only "class" can be top-level abstract element.
          if (isTopLevelAbstract && !isParsingClass) {
            int abstractPositionEnd = topLevelAbstractModifierPosition + ABSTRACT_KEYWORD.length();
            Location location = new Location(topLevelAbstractModifierPosition, abstractPositionEnd);
            reportError(new DartCompilationError(source, location,
                ParserErrorCode.ABSTRACT_TOP_LEVEL_ELEMENT));
          }
        }
      }
      expect(Token.EOS);
      // add comments
      {
        List<int[]> commentLocs = ((DartParserCommentsHelper.CommentParserContext) ctx).getCommentLocs();
        DartParserCommentsHelper.addComments(unit, source, sourceCode, commentLocs);
      }
      // done
      return done(unit);
    } catch (StringInterpolationParseError exception) {
      throw new InternalCompilerException("Failed to parse " + source.getUri(), exception);
    }
  }

  /**
   * Set the metadata associated with the given node to the given annotations.
   * 
   * @param node the node with which the metadata is to be associated
   * @param metadata the metadata to be associated with the node
   */
  private void setMetadata(DartNodeWithMetadata node, List<DartAnnotation> metadata) {
    node.setMetadata(metadata);
    if (node instanceof DartDeclaration<?>) {
      for (DartAnnotation annotation : metadata) {
        DartExpression nameNode = annotation.getName();
        if (nameNode instanceof DartIdentifier) {
          String name = ((DartIdentifier) nameNode).getName();
          if (name.equals("deprecated")) {
            DartDeclaration<?> declaration = (DartDeclaration<?>) node;
            declaration.setObsoleteMetadata(declaration.getObsoleteMetadata().makeDeprecated());
          } else if (name.equals("override")) {
            DartDeclaration<?> declaration = (DartDeclaration<?>) node;
            declaration.setObsoleteMetadata(declaration.getObsoleteMetadata().makeOverride());
          }
        }
      }
    }
  }

  private boolean looksLikeDirective() {
    switch(peek(0)) {
      case LIBRARY:
      case IMPORT:
      case SOURCE:
      case RESOURCE:
      case NATIVE:
        return true;
    }
    return peekPseudoKeyword(0, LIBRARY_KEYWORD) || peekPseudoKeyword(0, IMPORT_KEYWORD) || peekPseudoKeyword(0, PART_KEYWORD);
  }

  /**
   * 'interface' and 'typedef' are valid to use as names of fields and methods, so you can't
   * just blindly recover when you see them in any context.  This does a further test to make
   * sure they are followed by another identifier.  This would be illegal as a field or method
   * definition, as you cannot use 'interface' or 'typedef' as a type name.
   */
  private boolean looksLikeTopLevelKeyword() {
    if (peek(0).equals(Token.CLASS)) {
      return true;
    }
    if (peekPseudoKeyword(0, INTERFACE_KEYWORD)
        && peek(1).equals(Token.IDENTIFIER)) {
      return true;
    } else if (peekPseudoKeyword(0, TYPEDEF_KEYWORD)
        && (peek(1).equals(Token.IDENTIFIER) || peek(1).equals(Token.VOID))) {
      return true;
    }
    return false;
  }

  /**
   * A version of the parser which only parses the directives of a library.
   *
   * TODO(jbrosenberg): consider parsing the whole file here, in order to avoid
   * duplicate work.  Probably requires removing use of LibraryUnit's, etc.
   * Also, this minimal parse does have benefit in the incremental compilation
   * case.
   */
  @SuppressWarnings("deprecation")
  public LibraryUnit preProcessLibraryDirectives(LibrarySource source) {
    beginCompilationUnit();
    LibraryUnit libUnit = new LibraryUnit(source);
    if (peekPseudoKeyword(0, LIBRARY_KEYWORD)) {
      DartLibraryDirective libraryDirective = parseLibraryDirective();
      libUnit.setName(libraryDirective.getLibraryName());
    }
    while (peekPseudoKeyword(0, IMPORT_KEYWORD) || peekPseudoKeyword(0, EXPORT_KEYWORD)) {
      if (peekPseudoKeyword(0, IMPORT_KEYWORD)) {
        DartImportDirective importDirective = parseImportDirective();
        LibraryNode importPath = new LibraryNode(importDirective);
        importPath.setSourceInfo(importDirective.getSourceInfo());
        libUnit.addImportPath(importPath);
      }
      if (peekPseudoKeyword(0, EXPORT_KEYWORD)) {
        DartExportDirective exportDirective = parseExportDirective();
        LibraryNode importPath = new LibraryNode(exportDirective);
        importPath.setSourceInfo(exportDirective.getSourceInfo());
        libUnit.addExportPath(importPath);
      }
    }
    while (peekPseudoKeyword(0, PART_KEYWORD)) {
      if (peekPseudoKeyword(1, OF_KEYWORD)) {
        parsePartOfDirective();
      } else {
        DartSourceDirective sourceDirective = parsePartDirective();
        LibraryNode sourcePath = new LibraryNode(sourceDirective.getSourceUri().getValue());
        sourcePath.setSourceInfo(sourceDirective.getSourceInfo());
        libUnit.addSourcePath(sourcePath);
      }
    }
    //
    // The code below is obsolete. We do not make any effort to find duplications between the old
    // and the new syntax because support for the old syntax will be removed very soon.
    //
    if (peek(0) == Token.LIBRARY) {
      beginLibraryDirective();
      DartLibraryDirective libDirective = done(parseObsoleteLibraryDirective());
      libUnit.setName(libDirective.getLibraryName());
    }
    while (peek(0) == Token.IMPORT) {
      beginImportDirective();
      DartImportDirective importDirective = done(parseObsoleteImportDirective());
      LibraryNode importPath;
      if (importDirective.getOldPrefix() != null) {
        importPath =
            new LibraryNode(importDirective);
      } else {
        importPath = new LibraryNode(importDirective.getLibraryUri().getValue());
      }
      importPath.setSourceInfo(importDirective.getSourceInfo());
      libUnit.addImportPath(importPath);
    }
    while (peek(0) == Token.SOURCE) {
      beginSourceDirective();
      DartSourceDirective sourceDirective = done(parseSourceDirective());
      LibraryNode sourcePath = new LibraryNode(sourceDirective.getSourceUri().getValue());
      sourcePath.setSourceInfo(sourceDirective.getSourceInfo());
      libUnit.addSourcePath(sourcePath);
    }
    while (peek(0) == Token.RESOURCE) {
      parseResourceDirective();
    }
    while (peek(0) == Token.NATIVE) {
      beginNativeDirective();
      DartNativeDirective nativeDirective = done(parseNativeDirective());
      LibraryNode nativePath = new LibraryNode(nativeDirective.getNativeUri().getValue());
      nativePath.setSourceInfo(nativeDirective.getSourceInfo());
      libUnit.addNativePath(nativePath);
    }

    // add ourselves to the list of sources, so inline dart code will be parsed
    libUnit.addSourcePath(libUnit.getSelfSourcePath());
    return done(libUnit);
  }

  private void parseDirectives(DartUnit unit) {
    List<DartAnnotation> metadata = parseMetadata();
    if (peekPseudoKeyword(0, LIBRARY_KEYWORD)) {
      DartLibraryDirective libraryDirective = parseLibraryDirective();
      for (DartDirective directive : unit.getDirectives()) {
        if (directive instanceof DartLibraryDirective) {
          reportError(position(), ParserErrorCode.ONLY_ONE_LIBRARY_DIRECTIVE);
          break;
        }
      }
      setMetadata(libraryDirective, metadata);
      unit.getDirectives().add(libraryDirective);
    }
    while (peekPseudoKeyword(0, IMPORT_KEYWORD) || peekPseudoKeyword(0, EXPORT_KEYWORD)) {
      if (peekPseudoKeyword(0, IMPORT_KEYWORD)) {
        DartImportDirective importDirective = parseImportDirective();
        setMetadata(importDirective, metadata);
        unit.getDirectives().add(importDirective);
      } else {
        DartExportDirective exportDirective = parseExportDirective();
        setMetadata(exportDirective, metadata);
        unit.getDirectives().add(exportDirective);
      }
    }
    while (peekPseudoKeyword(0, PART_KEYWORD)) {
      if (peekPseudoKeyword(1, OF_KEYWORD)) {
        DartPartOfDirective partOfDirective = parsePartOfDirective();
        setMetadata(partOfDirective, metadata);
        unit.getDirectives().add(partOfDirective);
      } else {
        DartSourceDirective partDirective = parsePartDirective();
        setMetadata(partDirective, metadata);
        unit.getDirectives().add(partDirective);
      }
    }
    //
    // The code below is obsolete. We do not make any effort to find duplications between the old
    // and the new syntax because support for the old syntax will be removed very soon.
    //
    if (peek(0) == Token.LIBRARY) {
      beginLibraryDirective();
      DartLibraryDirective libraryDirective = parseObsoleteLibraryDirective();
      for (DartDirective directive : unit.getDirectives()) {
        if (directive instanceof DartLibraryDirective) {
          reportError(position(), ParserErrorCode.ONLY_ONE_LIBRARY_DIRECTIVE);
          break;
        }
      }
      setMetadata(libraryDirective, metadata);
      unit.getDirectives().add(libraryDirective);
      done(libraryDirective);
    }
    while (peek(0) == Token.IMPORT) {
      beginImportDirective();
      DartImportDirective importDirective = parseObsoleteImportDirective();
      setMetadata(importDirective, metadata);
      unit.getDirectives().add(done(importDirective));
    }
    while (peek(0) == Token.SOURCE) {
      beginSourceDirective();
      DartSourceDirective sourceDirective = parseSourceDirective();
      setMetadata(sourceDirective, metadata);
      unit.getDirectives().add(done(sourceDirective));
    }
    while (peek(0) == Token.RESOURCE) {
      parseResourceDirective();
    }
    while (peek(0) == Token.NATIVE) {
      beginNativeDirective();
      DartNativeDirective nativeDirective = parseNativeDirective();
      setMetadata(nativeDirective, metadata);
      unit.getDirectives().add(done(nativeDirective));
    }
  }

  private DartLibraryDirective parseLibraryDirective() {
    beginLibraryDirective();
    next(); // "library"
    DartExpression libraryName = parseLibraryName();
    expect(Token.SEMICOLON);
    return done(new DartLibraryDirective(libraryName));
  }

  private DartExpression parseLibraryName() {
    beginQualifiedIdentifier();
    DartExpression libraryName = parseIdentifier();
    while (optional(Token.PERIOD)) {
      beginQualifiedIdentifier();
      DartIdentifier identifier = parseIdentifier();
      libraryName = done(new DartPropertyAccess(libraryName, identifier));
    }
    return done(libraryName);
  }

  private DartLibraryDirective parseObsoleteLibraryDirective() {
    expect(Token.LIBRARY);
    expect(Token.LPAREN);
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral libname = done(DartStringLiteral.get(ctx.getTokenString()));
    expectCloseParen();
    expect(Token.SEMICOLON);
    return new DartLibraryDirective(libname);
  }

  protected DartExportDirective parseExportDirective() {
    beginExportDirective();
    next(); // "export"
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral libUri = done(DartStringLiteral.get(ctx.getTokenString()));

    List<ImportCombinator> combinators = new ArrayList<ImportCombinator>();
    while (peekPseudoKeyword(0, HIDE_KEYWORD) || peekPseudoKeyword(0, SHOW_KEYWORD)) {
      if (optionalPseudoKeyword(HIDE_KEYWORD)) {
        List<DartIdentifier> hiddenNames = parseIdentifierList();
        combinators.add(new ImportHideCombinator(hiddenNames));
      } else if (optionalPseudoKeyword(SHOW_KEYWORD)) {
        List<DartIdentifier> shownNames = parseIdentifierList();
        combinators.add(new ImportShowCombinator(shownNames));
      }
    }

    if (!optional(Token.SEMICOLON)) {
      // If there is no semicolon, then we probably don't want to consume the next token. It might
      // make sense to advance to the next valid token for a directive or top-level declaration, but
      // our recovery mechanism isn't quite sophisticated enough for that.
      reportUnexpectedToken(position(), Token.SEMICOLON, peek(0));
    }
    return done(new DartExportDirective(libUri, combinators));
  }

  protected DartImportDirective parseImportDirective() {
    beginImportDirective();
    next(); // "import"
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral libUri = done(DartStringLiteral.get(ctx.getTokenString()));

    DartIdentifier prefix = null;
    if (optional(Token.AS)) {
      prefix = parseIdentifier();
      if (prefix instanceof DartSyntheticErrorIdentifier) {
        if (peekPseudoKeyword(1, HIDE_KEYWORD) || peekPseudoKeyword(1, SHOW_KEYWORD)
            || peek(1) == Token.BIT_AND || peek(1) == Token.COLON) {
          next();
        }
      }
    }

    List<ImportCombinator> combinators = new ArrayList<ImportCombinator>();
    while (peekPseudoKeyword(0, HIDE_KEYWORD) || peekPseudoKeyword(0, SHOW_KEYWORD)) {
      if (optionalPseudoKeyword(HIDE_KEYWORD)) {
        List<DartIdentifier> hiddenNames = parseIdentifierList();
        combinators.add(new ImportHideCombinator(hiddenNames));
      } else if (optionalPseudoKeyword(SHOW_KEYWORD)) {
        List<DartIdentifier> shownNames = parseIdentifierList();
        combinators.add(new ImportShowCombinator(shownNames));
      }
    }

    if (!optional(Token.SEMICOLON)) {
      // If there is no semicolon, then we probably don't want to consume the next token. It might
      // make sense to advance to the next valid token for a directive or top-level declaration, but
      // our recovery mechanism isn't quite sophisticated enough for that.
      reportUnexpectedToken(position(), Token.SEMICOLON, peek(0));
    }
    return done(new DartImportDirective(libUri, prefix, combinators));
  }

  /**
   * Parse a comma-separated list of identifiers.
   *
   * @return the identifiers that were parsed
   */
  private List<DartIdentifier> parseIdentifierList() {
    ArrayList<DartIdentifier> identifiers = new ArrayList<DartIdentifier>();
    identifiers.add(parseIdentifier());
    while (optional(Token.COMMA)) {
      identifiers.add(parseIdentifier());
    }
    return identifiers;
  }

  protected DartImportDirective parseObsoleteImportDirective() {
    expect(Token.IMPORT);
    expect(Token.LPAREN);
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral libUri = done(DartStringLiteral.get(ctx.getTokenString()));
    DartBooleanLiteral export = null;
    List<ImportCombinator> combinators = new ArrayList<ImportCombinator>();
    DartStringLiteral prefix = null;
    if (optional(Token.COMMA)) {
      if (optionalPseudoKeyword(PREFIX_KEYWORD)) {
        expect(Token.COLON);
        beginLiteral();
        expect(Token.STRING);
        String id = ctx.getTokenString();
        // The specification requires the value of this string be a valid identifier
        if(id == null || !id.matches("[_a-zA-Z]([_A-Za-z0-9]*)")) {
          reportError(position(), ParserErrorCode.EXPECTED_PREFIX_IDENTIFIER);
        }
        prefix = done(DartStringLiteral.get(ctx.getTokenString()));
      } else {
        reportError(position(), ParserErrorCode.EXPECTED_PREFIX_KEYWORD);
      }
    }
    expectCloseParen();
    expect(Token.SEMICOLON);
    return new DartImportDirective(libUri, export, combinators, prefix);
  }

  private DartSourceDirective parsePartDirective() {
    beginPartDirective();
    next(); // "part"
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral partUri = done(DartStringLiteral.get(ctx.getTokenString()));
    expect(Token.SEMICOLON);
    return done(new DartSourceDirective(partUri));
  }

  private DartSourceDirective parseSourceDirective() {
    expect(Token.SOURCE);
    expect(Token.LPAREN);
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral sourceUri = done(DartStringLiteral.get(ctx.getTokenString()));
    expectCloseParen();
    expect(Token.SEMICOLON);
    return new DartSourceDirective(sourceUri);
  }

  private DartPartOfDirective parsePartOfDirective() {
    beginPartOfDirective();
    next(); // "part"
    next(); // "of"
    DartExpression libraryName = parseLibraryName();
    expect(Token.SEMICOLON);
    return done(new DartPartOfDirective(libraryName));
  }

  private void parseResourceDirective() {
    expect(Token.RESOURCE);
    reportError(position(), ParserErrorCode.DEPRECATED_RESOURCE_DIRECTIVE);
    expect(Token.LPAREN);
    beginLiteral();
    expect(Token.STRING);
    @SuppressWarnings("unused")
    DartStringLiteral resourceUri = done(DartStringLiteral.get(ctx.getTokenString()));
    expectCloseParen();
    expect(Token.SEMICOLON);
  }

  private DartNativeDirective parseNativeDirective() {
    expect(Token.NATIVE);
    expect(Token.LPAREN);
    beginLiteral();
    expect(Token.STRING);
    DartStringLiteral nativeUri = done(DartStringLiteral.get(ctx.getTokenString()));
    expect(Token.RPAREN);
    expect(Token.SEMICOLON);
    return new DartNativeDirective(nativeUri);
  }

  private List<DartAnnotation> parseMetadata() {
    List<DartAnnotation> metadata = new ArrayList<DartAnnotation>();
    while (match(Token.AT)) {
      beginMetadata();
      next();
      beginQualifiedIdentifier();
      DartExpression name = parseQualified(true);
      if (optional(Token.PERIOD)) {
        name = new DartPropertyAccess(name, parseIdentifier());
      }
      done(name);
      List<DartExpression> arguments = null;
      if (match(Token.LPAREN)) {
        arguments = parseArguments();
      }
      metadata.add(done(new DartAnnotation(name, arguments)));
    }
    return metadata;
  }

  /**
   * <pre>
   * typeParameter
   *     : identifier (EXTENDS type)?
   *     ;
   *
   * typeParameters
   *     : '<' typeParameter (',' typeParameter)* '>'
   *     ;
   * </pre>
   */
  @Terminals(tokens={Token.GT, Token.COMMA})
  private List<DartTypeParameter> parseTypeParameters() {
    List<DartTypeParameter> types = new ArrayList<DartTypeParameter>();
    expect(Token.LT);
    do {
      DartTypeParameter typeParameter = parseTypeParameter();
      types.add(typeParameter);

    } while (optional(Token.COMMA));
    expect(Token.GT);
    return types;
  }

  /**
   * Parses single {@link DartTypeParameter} for {@link #parseTypeParameters()}.
   */
  private DartTypeParameter parseTypeParameter() {
    beginTypeParameter();
    List<DartAnnotation> metadata = parseMetadata();
    DartIdentifier name = parseIdentifier();
    if (PSEUDO_KEYWORDS_SET.contains(name.getName())) {
      reportError(name, ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_VARIABLE_NAME);
    }
    // Try to parse bound.
    DartTypeNode bound = null;
    if (peek(0) != Token.EOS && peek(0) != Token.COMMA && peek(0) != Token.GT) {
      if (optional(Token.EXTENDS)) {
        // OK, this is EXTENDS, parse type.
        bound = parseTypeAnnotation();
      } else if (looksLikeTopLevelKeyword()) {
        return done(new DartTypeParameter(name, bound));
      } else if (peek(0) == Token.IDENTIFIER && (peek(1) == Token.COMMA || peek(1) == Token.GT)) {
        // <X exte{cursor}>
        // User tries to type "extends", but it is not finished yet.
        // Report problem and try to continue.
        next();
        reportError(position(), ParserErrorCode.EXPECTED_EXTENDS);
      } else if (peek(0) == Token.IDENTIFIER
          && peek(1) == Token.IDENTIFIER
          && (peek(2) == Token.COMMA || peek(2) == Token.GT)) {
        // <X somethingLikeExtends Type>
        // User mistyped word "extends" or it is not finished yet.
        // Report problem and try to continue.
        next();
        reportError(position(), ParserErrorCode.EXPECTED_EXTENDS);
        bound = parseTypeAnnotation();
      } else {
        // Something else, restart parsing from next top level element.
        next();
        reportError(position(), ParserErrorCode.EXPECTED_EXTENDS);
      }
    }
    // Ready to create DartTypeParameter.
    DartTypeParameter parameter = new DartTypeParameter(name, bound);
    parameter.setMetadata(metadata);
    return done(parameter);
  }

  private List<DartTypeParameter> parseTypeParametersOpt() {
    return (peek(0) == Token.LT)
        ? parseTypeParameters()
        : Collections.<DartTypeParameter>emptyList();
  }

  /**
   * <pre>
   * classDefinition
   *     : CLASS identifier typeParameters? superclass? interfaces?
   *       '{' classMemberDefinition* '}'
   *     ;
   *
   * superclass
   *     : EXTENDS type
   *     ;
   *
   * interfaces
   *     : IMPLEMENTS typeList
   *     ;
   *
   * superinterfaces
   *     : EXTENDS typeList
   *     ;
   *
   * classMemberDefinition
   *     : declaration ';'
   *     | methodDeclaration blockOrNative
   *
   * interfaceDefinition
   *     : INTERFACE identifier typeParameters? superinterfaces?
   *       (DEFAULT type)? '{' (interfaceMemberDefinition)* '}'
   *     ;
   * </pre>
   */
  private DartDeclaration<?> parseClass() {
    beginClassBody();

    // Parse modifiers.
    Modifiers modifiers = Modifiers.NONE;
    if (isTopLevelAbstract) {
      modifiers = modifiers.makeAbstract();
    }

    DartIdentifier name = parseIdentifier();
    if (name.getName().equals("")) {
      // something went horribly wrong.
      if (peek(0).equals(Token.LBRACE)) {
        parseBlock();
      }
      return done(null);
    }
    if (PSEUDO_KEYWORDS_SET.contains(name.getName())) {
      reportError(name, ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME);
    }
    List<DartTypeParameter> typeParameters = parseTypeParametersOpt();

    // Parse the extends and implements clauses.
    DartTypeNode superType = null;
    List<DartTypeNode> interfaces = null;
    if (isParsingInterface) {
      if (optional(Token.EXTENDS)) {
        interfaces = parseTypeAnnotationList();
      }
    } else {
      if (optional(Token.EXTENDS)) {
        superType = parseTypeAnnotation();
      }
      if (optionalPseudoKeyword(IMPLEMENTS_KEYWORD)) {
        interfaces = parseTypeAnnotationList();
      }
    }

    // Deal with factory clause for interfaces.
    DartParameterizedTypeNode defaultClass = null;
    if (isParsingInterface &&
        (optionalDeprecatedFactory() || optional(Token.DEFAULT))) {
      DartExpression qualified = parseQualified(false);
      List<DartTypeParameter> defaultTypeParameters = parseTypeParametersOpt();
      defaultClass = doneWithoutConsuming(new DartParameterizedTypeNode(qualified,
                                                                        defaultTypeParameters));
    }

    // Deal with native clause for classes.
    DartStringLiteral nativeName = null;
    if (optionalPseudoKeyword(NATIVE_KEYWORD)) {
      if (isParsingInterface) {
        reportError(position(), ParserErrorCode.NATIVE_ONLY_CLASS);
      }
      if (!corelibParse) {
        reportError(position(), ParserErrorCode.NATIVE_ONLY_CORE_LIB);
      }
      beginLiteral();
      if (expect(Token.STRING)) {
        nativeName = done(DartStringLiteral.get(ctx.getTokenString()));
      }
      modifiers = modifiers.makeNative();
    }

    // Parse the members.
    int openBraceOffset = -1;
    int closeBraceOffset = -1;
    List<DartNode> members = new ArrayList<DartNode>();
    if (optional(Token.LBRACE)) {
      openBraceOffset = ctx.getTokenLocation().getBegin();
      parseClassOrInterfaceBody(members);
      expectCloseBrace(true);
      closeBraceOffset = ctx.getTokenLocation().getBegin();
    } else {
      reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_CLASS_DECLARATION_LBRACE);
    }

    if (isParsingInterface) {
      return done(new DartClass(name, superType, interfaces, openBraceOffset, closeBraceOffset,
          members, typeParameters, defaultClass));
    } else {
      return done(new DartClass(name,
          nativeName,
          superType,
          interfaces,
          openBraceOffset,
          closeBraceOffset,
          members,
          typeParameters,
          modifiers));
    }
  }

  /**
   * Helper for {@link #parseClass()}.
   *
   * classMemberDefinition*
   */
  @Terminals(tokens={Token.RBRACE, Token.SEMICOLON})
  private void parseClassOrInterfaceBody(List<DartNode> members) {
    while (!match(Token.RBRACE) && !EOS() && !looksLikeTopLevelKeyword()) {
      List<DartAnnotation> metadata = parseMetadata();
      DartNodeWithMetadata member = parseFieldOrMethod(true);
      if (member != null) {
        setMetadata(member, metadata);
        members.add(member);
      }
      // Recover at a semicolon
      if (optional(Token.SEMICOLON)) {
        reportUnexpectedToken(position(), null, Token.SEMICOLON);
      }
    }
  }

  private boolean optionalDeprecatedFactory() {
    if (optionalPseudoKeyword(FACTORY_KEYWORD)) {
      reportError(position(), ParserErrorCode.DEPRECATED_USE_OF_FACTORY_KEYWORD);
      return true;
    }
    return false;
  }

  private List<DartTypeNode> parseTypeAnnotationList() {
    List<DartTypeNode> result = new ArrayList<DartTypeNode>();
    do {
      result.add(parseTypeAnnotation());
    } while (optional(Token.COMMA));
    return result;
  }

  /**
   * Look ahead to detect if we are seeing ident [ TypeParameters ] "(".
   * We need this lookahead to distinguish between the optional return type
   * and the alias name of a function type alias.
   * Token position remains unchanged.
   *
   * @return true if the next tokens should be parsed as a type
   */
  private boolean isFunctionTypeAliasName() {
    beginFunctionTypeInterface();
    try {
      if ((peek(0) == Token.IDENTIFIER || peek(0) == Token.AS) && peek(1) == Token.LPAREN) {
        return true;
      }
      if ((peek(0) == Token.IDENTIFIER || peek(0) == Token.AS) && peek(1) == Token.LT) {
        consume(Token.IDENTIFIER);
        // isTypeParameter leaves the position advanced if it matches
        if (isTypeParameter() && peek(0) == Token.LPAREN) {
          return true;
        }
      }
      return false;
    } finally {
      rollback();
    }
  }

  /**
   * Returns true if the current and next tokens can be parsed as type
   * parameters. Current token position is not saved and restored.
   */
  private boolean isTypeParameter() {
    if (peek(0) == Token.LT) {
      // We are possibly looking at type parameters. Find closing ">".
      consume(Token.LT);
      int nestingLevel = 1;
      while (nestingLevel > 0) {
        switch (peek(0)) {
          case LT:
            nestingLevel++;
            break;
          case GT:
            nestingLevel--;
            break;
          case SAR:   // >>
            nestingLevel -= 2;
            break;
          case COMMA:
          case EXTENDS:
          case IDENTIFIER:
            break;
          default:
            // We are looking at something other than type parameters.
            return false;
        }
        next();
        if (nestingLevel < 0) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * <pre>
   * functionTypeAlias
   *     : TYPEDEF functionPrefix typeParameters?
   *       formalParameterList ';'
   *
   * functionPrefix
   *     : returnType? identifier
   * </pre>
   */
  private DartFunctionTypeAlias parseFunctionTypeAlias() {
    beginFunctionTypeInterface();

    DartTypeNode returnType = null;
    if (peek(0) == Token.VOID) {
      returnType = parseVoidType();
    } else if (!isFunctionTypeAliasName()) {
      returnType = parseTypeAnnotation();
    }

    DartIdentifier name = parseIdentifier();
    if (PSEUDO_KEYWORDS_SET.contains(name.getName())) {
      reportError(name, ParserErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME);
    }

    List<DartTypeParameter> typeParameters = parseTypeParametersOpt();
    FormalParameters params = parseFormalParameterList();
    expect(Token.SEMICOLON);
    validateNoDefaultParameterValues(
        params.val,
        ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_TYPEDEF);

    return done(new DartFunctionTypeAlias(name, returnType, params.val, typeParameters));
  }

  /**
   * Parse a field or method, which may be inside a class or at the top level.
   *
   * <pre>
   * // This rule is organized in a way that may not be most readable, but
   * // gives the best error messages.
   * classMemberDefinition
   *     : declaration ';'
   *     | methodDeclaration bodyOrNative
   *     ;
   *
   * // Note: this syntax is not official, but used in dart_interpreter. It
   * // is unlikely that Dart will support numbered natives.
   * bodyOrNative
   *     : error=NATIVE (':' (STRING | RATIONAL_NUMBER))? ';'
   *       { legacy($error, "native not supported (yet)"); }
   *     | functionStatementBody
   *     ;
   *
   * // A method, operator, or constructor (which all should be followed by
   * // a function body).
   * methodDeclaration
   *     : factoryConstructorDeclaration
   *     | STATIC methodOrConstructorDeclaration
   *     | specialSignatureDefinition
   *     | methodOrConstructorDeclaration initializers?
   *     | namedConstructorDeclaration initializers?
   *     ;
   *
   *
   * // An abstract method/operator, a field, or const constructor (which
   * // all should be followed by a semicolon).
   * declaration
   *     : constantConstructorDeclaration initializers?
   *     | ABSTRACT specialSignatureDefinition
   *     | ABSTRACT methodOrConstructorDeclaration
   *     | STATIC CONST type? staticConstDeclarationList
   *     | STATIC? variableDeclaration
   *     ;
   *
   * interfaceMemberDefinition
   *     : STATIC CONST type? initializedIdentifierList ';'
   *     | methodOrConstructorDeclaration ';'
   *     | constantConstructorDeclaration ';'
   *     | namedConstructorDeclaration ';'
   *     | specialSignatureDefinition ';'
   *     | variableDeclaration ';'
   *     ;
   *
   * variableDeclaration
   *     : constVarOrType identifierList
   *     ;
   *
   * methodOrConstructorDeclaration
   *     : typeOrFunction? identifier formalParameterList
   *     ;
   *
   * factoryConstructorDeclaration
   *     : FACTORY qualified ('.' identifier)? formalParameterList
   *     ;
   *
   * namedConstructorDeclaration
   *     : identifier typeArguments? '.' identifier formalParameterList
   *     ;
   *
   * constructorDeclaration
   *     : identifier typeArguments? formalParameterList
   *     | namedConstructorDeclaration
   *     ;
   *
   * constantConstructorDeclaration
   *     : CONST qualified formalParameterList
   *     ;
   *
   * specialSignatureDefinition
   *     : STATIC? type? getOrSet identifier formalParameterList
   *     | type? OPERATOR operator formalParameterList
   *     ;
   *
   * getOrSet
   *     : GET
   *     | SET
   *     ;
   *
   * operator
   *     : unaryOperator
   *     | binaryOperator
   *     | '[' ']' { "[]".equals($text) }?
   *     | '[' ']' '=' { "[]=".equals($text) }?
   *     | NEGATE
   *     | CALL
   *     ;
   * </pre>
   *
   * @param allowStatic true if the static modifier is allowed
   * @return a {@link DartNode} representing the grammar fragment above
   */
  @Terminals(tokens={Token.SEMICOLON})
  private DartNodeWithMetadata parseFieldOrMethod(boolean allowStatic) {
    beginClassMember();
    Modifiers modifiers = Modifiers.NONE;
    if (peek(1) != Token.LPAREN && optionalPseudoKeyword(EXTERNAL_KEYWORD)) {
      modifiers = modifiers.makeExternal();
    }
    if (peek(1) != Token.LPAREN && optionalPseudoKeyword(STATIC_KEYWORD)) {
      if (!allowStatic) {
        reportError(position(), ParserErrorCode.TOP_LEVEL_CANNOT_BE_STATIC);
      } else {
        if (isParsingInterface
            && peek(0) != Token.FINAL && peek(0) != Token.CONST) {
          reportError(position(), ParserErrorCode.NON_FINAL_STATIC_MEMBER_IN_INTERFACE);
        }
        modifiers = modifiers.makeStatic();
      }
    }
    if (optionalPseudoKeyword(ABSTRACT_KEYWORD)) {
      if (isParsingInterface) {
        reportError(position(), ParserErrorCode.ABSTRACT_MEMBER_IN_INTERFACE);
      }
      if (modifiers.isStatic()) {
        reportError(position(), ParserErrorCode.STATIC_MEMBERS_CANNOT_BE_ABSTRACT);
      }
      if (modifiers.isExternal()) {
        reportError(position(), ParserErrorCode.EXTERNAL_ABSTRACT);
      }
      modifiers = modifiers.makeAbstract();
    }
    if (optionalPseudoKeyword(FACTORY_KEYWORD)) {
      if (isParsingInterface) {
        reportError(position(), ParserErrorCode.FACTORY_MEMBER_IN_INTERFACE);
      }
      if (modifiers.isStatic()) {
        reportError(position(), ParserErrorCode.FACTORY_CANNOT_BE_STATIC);
      }
      if (modifiers.isAbstract()) {
        reportError(position(), ParserErrorCode.FACTORY_CANNOT_BE_ABSTRACT);
      }

      modifiers = modifiers.makeFactory();
    }

    if (match(Token.VAR) || match(Token.FINAL)) {
      if (modifiers.isAbstract()) {
        reportError(position(), ParserErrorCode.DISALLOWED_ABSTRACT_KEYWORD);
      }
      if (modifiers.isFactory()) {
        reportError(position(), ParserErrorCode.DISALLOWED_FACTORY_KEYWORD);
      }
    }

    if (modifiers.isFactory()) {
      if (!isParsingClass) {
        reportError(position(), ParserErrorCode.FACTORY_CANNOT_BE_TOP_LEVEL);
      }
      // Do parse factory.
      DartMethodDefinition factoryNode = parseFactory(modifiers);
      // If factory is not allowed, ensure that it is valid as method.
      DartExpression actualName = factoryNode.getName();
      if (!allowStatic && !(actualName instanceof DartIdentifier)) {
        DartExpression replacementName = new DartIdentifier(actualName.toString());
        factoryNode.setName(replacementName);
      }
      // Done.
      return done(factoryNode);
    }

    final DartNodeWithMetadata member;

    switch (peek(0)) {
      case VAR: {
        consume(Token.VAR);
        // Check for malformed method starting with 'var' : var ^ foo() { }
        if (peek(0).equals(Token.IDENTIFIER) && looksLikeMethodOrAccessorDefinition()) {
          reportError(position(), ParserErrorCode.VAR_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION);
          member = parseMethodOrAccessor(modifiers, null);
          break;
        }

        member = parseFieldDeclaration(modifiers, null);
        expectStatmentTerminator();
        break;
      }

      case CONST: {
        consume(Token.CONST);
        modifiers = modifiers.makeConstant();
        // Allow "const factory ... native" constructors for core libraries only
        if (optionalPseudoKeyword(FACTORY_KEYWORD)) {
          modifiers = modifiers.makeFactory();
        }
        if (peek(0).equals(Token.IDENTIFIER) && looksLikeMethodOrAccessorDefinition()) {
          return done(parseMethod(modifiers, null));
        }
        // Try to find type, may be "const ^ Type field".
        DartTypeNode type = null;
        if (peek(1) != Token.COMMA
            && peek(1) != Token.ASSIGN
            && peek(1) != Token.SEMICOLON) {
          type = parseTypeAnnotation();
        }
        // Parse field.
        modifiers = modifiers.makeFinal();
        member = parseFieldDeclaration(modifiers, type);
        expectStatmentTerminator();
        break;
      }

      case FINAL: {
        consume(Token.FINAL);
        modifiers = modifiers.makeFinal();

        // Check for malformed method starting with 'final':   final ^ foo() { }
        if (peek(0).equals(Token.IDENTIFIER) && looksLikeMethodOrAccessorDefinition()) {
          reportError(position(), ParserErrorCode.FINAL_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION);
          member = parseMethodOrAccessor(modifiers, null);
          break;
        }
        DartTypeNode type = null;
        if (peek(1) != Token.COMMA
            && peek(1) != Token.ASSIGN
            && peek(1) != Token.SEMICOLON) {
          type = parseTypeAnnotation();

          // Check again for malformed method starting with 'final':   final String ^ foo() { }
          if (peek(0).equals(Token.IDENTIFIER) && looksLikeMethodOrAccessorDefinition()) {
            reportError(position(), ParserErrorCode.FINAL_IS_NOT_ALLOWED_ON_A_METHOD_DEFINITION);
            member = parseMethodOrAccessor(modifiers, null);
            break;
          }
        }
        member = parseFieldDeclaration(modifiers, type);
        expectStatmentTerminator();
        break;
      }

      case IDENTIFIER: {

        // Check to see if it looks like the start of a method definition (sans type).
        if (looksLikeMethodOrAccessorDefinition()) {
          member = parseMethodOrAccessor(modifiers, null);
          break;
        }
      }
      //$FALL-THROUGH$

      case VOID: {

        // The next token may be a type specification or parameterized constructor: either a method or field.
        boolean isVoidType = peek(0) == Token.VOID;
        DartTypeNode type;
        if (isVoidType) {
          type = parseVoidType();
        } else {
          int nameIndex = skipTypeName(0);
          if (nameIndex < 0 || (peek(nameIndex) != Token.IDENTIFIER && peek(nameIndex) != Token.AS)) {
            // There was no type name.
            type = null;
          } else {
            type = parseTypeAnnotation();
          }
        }
        if (peek(1) == Token.SEMICOLON
            || peek(1) == Token.COMMA
            || peek(1) == Token.ASSIGN) {
          if (modifiers.isAbstract()) {
            reportError(position(), ParserErrorCode.INVALID_FIELD_DECLARATION);
          }
          member = parseFieldDeclaration(modifiers, type);
          if (isVoidType) {
            reportError(type, ParserErrorCode.VOID_FIELD);
          } else if (!modifiers.isFinal() && type == null) {
            reportError(position(), ParserErrorCode.INVALID_FIELD_DECLARATION);
          }
          expectStatmentTerminator();
        } else {
          member = parseMethodOrAccessor(modifiers, type);
        }
        break;
      }

      case SEMICOLON:
      default: {
        done(null);
        reportUnexpectedToken(position(), null, next());
        member = null;
        break;
      }
    }
    return member;
  }

  /**
   * Returns true if the beginning of a method definition follows.
   *
   * This test is needed to disambiguate between a method that returns a type
   * and a plain method.
   *
   * Assumes the next token has already been determined to be an identifier.
   *
   * The following constructs will match:
   *
   *      : get (
   *      | get identifier (
   *      | set (
   *      | set identifier (
   *      | operator (
   *      | operator <op> (
   *      | identifier (
   *      | identifier DOT identifier  (
   *      | identifier DOT identifier DOT identifier (
   *
   * @return <code>true</code> if the signature of a method has been found.  No tokens are consumed.
   */
  private boolean looksLikeMethodOrAccessorDefinition() {
    assert (peek(0).equals(Token.IDENTIFIER));
    beginMethodName(); // begin() equivalent
    try {
      if (peekPseudoKeyword(0, OPERATOR_KEYWORD)) {
        next();
        // Using 'operator' as a field name is valid
        if (peek(0).equals(Token.SEMICOLON) || peek(0).equals(Token.ASSIGN)) {
          return false;
        }
        // Using 'operator' as a method name is valid (but discouraged)
        if (peek(0).equals(Token.LPAREN)) {
          return true;
        }
        // operator call (
        if (peekPseudoKeyword(0, CALL_KEYWORD) && peek(1).equals(Token.LPAREN)) {
          return true;
        }
        // TODO(zundel): Look for valid operator overload tokens.  For now just assuming
        // non-idents are good enough
        // operator ??? (
        if (!(peek(0).equals(Token.IDENTIFIER) &&  peek(1).equals(Token.LPAREN))) {
          return true;
        }
        if (peek(0).equals(Token.LBRACK) && peek(1).equals(Token.RBRACK)) {
          // operator [] (
          if (peek(2).equals(Token.LPAREN)) {
            return true;
          }
          // operator []= (
          if (peek(2).equals(Token.ASSIGN) && peek(3).equals(Token.LPAREN)) {
            return true;
          }
        }
        return false;
      }

      if (peekPseudoKeyword(0, GETTER_KEYWORD)
          || peekPseudoKeyword(0, SETTER_KEYWORD)) {
        boolean isGetter = peekPseudoKeyword(0, GETTER_KEYWORD);
        next();
        // Using 'get' or 'set' as a field name is valid
        if (peek(0).equals(Token.SEMICOLON) || peek(0).equals(Token.ASSIGN)) {
          return false;
        }
        // Using 'get' or 'set' as a method name is valid (but discouraged)
        if (peek(0).equals(Token.LPAREN)) {
          return true;
        }
        // normal case:  get foo (
        if (peek(0).equals(Token.IDENTIFIER) && (isGetter || peek(1).equals(Token.LPAREN))) {
          return true;
        }
        return false;
      }

      consume(Token.IDENTIFIER);

      if (peek(0).equals(Token.PERIOD) && peek(1).equals(Token.IDENTIFIER)) {
        consume(Token.PERIOD);
        consume(Token.IDENTIFIER);

        if (peek(0).equals(Token.PERIOD) && peek(1).equals(Token.IDENTIFIER)) {
          consume(Token.PERIOD);
          consume(Token.IDENTIFIER);
        }
      }

      // next token should be LPAREN
      return (peek(0).equals(Token.LPAREN));
    } finally {
      rollback();
    }
  }

  /**
   * <pre>
   * factoryConstructorDeclaration
   *     : FACTORY qualified ('.' identifier)? formalParameterList
   *     ;
   * </pre>
   */
  private DartMethodDefinition parseFactory(Modifiers modifiers) {
    beginMethodName();
    DartExpression name = parseQualified(true);
    if (optional(Token.PERIOD)) {
      name = doneWithoutConsuming(new DartPropertyAccess(name, parseIdentifier()));
    }
    done(name);
    FormalParameters formals = parseFormalParameterList();
    int parametersCloseParen = ctx.getTokenLocation().getBegin();

    // Parse redirecting factory
    if (match(Token.ASSIGN)) {
      next();
      if (!modifiers.isFactory()) {
        reportError(position(), ParserErrorCode.ONLY_FACTORIES_CAN_REDIRECT);
      }
      modifiers = modifiers.makeRedirectedConstructor();
      DartTypeNode redirectedTypeName = parseTypeAnnotationPossiblyFollowedByName();
      DartIdentifier redirectedConstructorName = null;
      if (optional(Token.PERIOD)) {
        redirectedConstructorName = parseIdentifier();
      }
      expect(Token.SEMICOLON);
      DartFunction function = doneWithoutConsuming(new DartFunction(formals.val,
          formals.optionalOpenOffset, formals.optionalCloseOffset, parametersCloseParen, null, null));
      return DartMethodDefinition.create(name, function, modifiers, redirectedTypeName, 
                                         redirectedConstructorName);
    }

    DartFunction function;
    if (peekPseudoKeyword(0, NATIVE_KEYWORD)) {
      modifiers = modifiers.makeNative();
      function = new DartFunction(formals.val, formals.optionalOpenOffset,
          formals.optionalCloseOffset, parametersCloseParen, parseNativeBlock(modifiers), null);
    } else {
      function = new DartFunction(formals.val, formals.optionalOpenOffset,
          formals.optionalCloseOffset, parametersCloseParen, parseFunctionStatementBody(
              !modifiers.isExternal(), true), null);
    }
    doneWithoutConsuming(function);
    return DartMethodDefinition.create(name, function, modifiers, null);
  }

  private DartIdentifier parseVoidIdentifier() {
    beginIdentifier();
    expect(Token.VOID);
    return done(new DartIdentifier(Token.VOID.getSyntax()));
  }

  private DartTypeNode parseVoidType() {
    beginTypeAnnotation();
    return done(new DartTypeNode(parseVoidIdentifier()));
  }

  private DartMethodDefinition parseMethod(Modifiers modifiers, DartTypeNode returnType) {
    DartExpression name = new DartIdentifier("");

    if (modifiers.isFactory()) {
      if (modifiers.isAbstract()) {
        reportError(position(), ParserErrorCode.FACTORY_CANNOT_BE_ABSTRACT);
      }
      if (modifiers.isStatic()) {
        reportError(position(), ParserErrorCode.FACTORY_CANNOT_BE_STATIC);
      }
    }

    int arity = -1;
    Token operation = null;
    if (peek(1) != Token.LPAREN && optionalPseudoKeyword(OPERATOR_KEYWORD)) {
      // Overloaded operator.
      if (modifiers.isStatic()) {
        reportError(position(), ParserErrorCode.OPERATOR_CANNOT_BE_STATIC);
      }
      modifiers = modifiers.makeOperator();

      beginOperatorName();
      operation = next();
      if (operation.isUserDefinableOperator()) {
        name = done(new DartIdentifier(operation.getSyntax()));
        if (operation == Token.ASSIGN_INDEX) {
          arity = 2;
        } else if (operation == Token.SUB) {
          arity = -1;
        } else if (operation.isBinaryOperator()) {
          arity = 1;
        } else if (operation == Token.INDEX) {
          arity = 1;
        } else {
          assert operation.isUnaryOperator();
          arity = 0;
        }
      } else if (operation == Token.IDENTIFIER
                 && ctx.getTokenString().equals(CALL_KEYWORD)) {
        name = done(new DartIdentifier(CALL_KEYWORD));
        arity = -1;
      } else if (operation == Token.IDENTIFIER
          && ctx.getTokenString().equals(CALL_KEYWORD)) {
        name = done(new DartIdentifier(CALL_KEYWORD));
      } else {
        // Not a valid operator.  Try to recover.
        boolean found = false;
        for (int i = 0; i < 4; ++i) {
          if (peek(i).equals(Token.LPAREN)) {
            found = true;
            break;
          }
        }
        StringBuilder buf = new StringBuilder();
        buf.append(operation.getSyntax());
        if (found) {
          reportError(position(), ParserErrorCode.OPERATOR_IS_NOT_USER_DEFINABLE);
          while(true) {
            Token token = peek(0);
            if (token.equals(Token.LPAREN)) {
              break;
            }
            buf.append(next().getSyntax());
          }
          name = done(new DartIdentifier(buf.toString()));
        } else {
          reportUnexpectedToken(position(), Token.COMMENT, operation);
          done(null);
        }
      }
    } else {
      beginMethodName();
      // Check for getters and setters.
      if (peek(1) != Token.LPAREN && optionalPseudoKeyword(GETTER_KEYWORD)) {
        name = parseIdentifier();
        modifiers = modifiers.makeGetter();
        arity = 0;
      } else if (peek(1) != Token.LPAREN && optionalPseudoKeyword(SETTER_KEYWORD)) {
        name = parseIdentifier();
        modifiers = modifiers.makeSetter();
        arity = 1;
      } else {
        // Normal method or property.
        name = parseIdentifier();
      }

      // Check for named constructor.
      if (optional(Token.PERIOD)) {
        name = doneWithoutConsuming(new DartPropertyAccess(name, parseIdentifier()));
        if(currentlyParsingToplevel()) {
          // TODO: Error recovery could find a missing brace and treat this as an expression
          reportError(name,  ParserErrorCode.FUNCTION_NAME_EXPECTED_IDENTIFIER);
        }
        if (optional(Token.PERIOD)) {
          name = doneWithoutConsuming(new DartPropertyAccess(name, parseIdentifier()));
        }
      }
      done(null);
    }

    // Parse the parameters definitions.
    FormalParameters parametersInfo;
    if (modifiers.isGetter() && peek(0) != Token.LPAREN) {
      // TODO: For now the parameters are optional so that both the old and new style will be
      // accepted, but eventually parameters should be disallowed.
      parametersInfo = new FormalParameters(new ArrayList<DartParameter>(), -1, -1);
    } else {
      //reportError(position(), ParserErrorCode.DEPRECATED_GETTER);
      parametersInfo = parseFormalParameterList();
    }
    List<DartParameter> parameters = parametersInfo.val;
    int parametersCloseParen = ctx.getTokenLocation().getBegin();

    if (arity != -1) {
      if (parameters.size() != arity) {
        reportError(position(), ParserErrorCode.ILLEGAL_NUMBER_OF_PARAMETERS);
      }
      // In methods with required arity each parameter is required.
      for (DartParameter parameter : parameters) {
        if (parameter.getModifiers().isNamed()) {
          reportError(parameter, ParserErrorCode.NAMED_PARAMETER_NOT_ALLOWED);
        }
      }
    } else if (operation == Token.SUB) {
      if (parameters.size() != 0 && parameters.size() != 1) {
        reportError(position(), ParserErrorCode.ILLEGAL_NUMBER_OF_PARAMETERS);
      }
      // In methods with required arity each parameter is required.
      for (DartParameter parameter : parameters) {
        if (parameter.getModifiers().isNamed()) {
          reportError(parameter, ParserErrorCode.NAMED_PARAMETER_NOT_ALLOWED);
        }
      }
    }

    // Parse redirecting factory
    DartTypeNode redirectedTypeName = null;
    DartIdentifier redirectedConstructorName = null;
    if (match(Token.ASSIGN)) {
      next();
      if (!modifiers.isFactory()) {
        reportError(position(), ParserErrorCode.ONLY_FACTORIES_CAN_REDIRECT);
      }
      modifiers = modifiers.makeRedirectedConstructor();
      redirectedTypeName = parseTypeAnnotationPossiblyFollowedByName();
      if (optional(Token.PERIOD)) {
        redirectedConstructorName = parseIdentifier();
      }
      expect(Token.SEMICOLON);
      DartFunction function = doneWithoutConsuming(new DartFunction(parameters,
          parametersInfo.optionalOpenOffset, parametersInfo.optionalCloseOffset,
          parametersCloseParen, null, returnType));
      return DartMethodDefinition.create(name, function, modifiers, redirectedTypeName, 
                                         redirectedConstructorName);
    }

    // Parse initializer expressions for constructors.
    List<DartInitializer> initializers = new ArrayList<DartInitializer>();
    if (match(Token.COLON) && !(isParsingInterface || modifiers.isFactory())) {
      parseInitializers(initializers);
      boolean isRedirectedConstructor = validateInitializers(parameters, initializers);
      if (isRedirectedConstructor) {
        modifiers = modifiers.makeRedirectedConstructor();
      }
    }

    // Parse the body.
    DartBlock body = null;
    if (!optional(Token.SEMICOLON)) {
      if (peekPseudoKeyword(0, NATIVE_KEYWORD)) {
        modifiers = modifiers.makeNative();
        body = parseNativeBlock(modifiers);
      } else {
        body = parseFunctionStatementBody(!modifiers.isExternal(), true);
      }
      if (body != null && modifiers.isRedirectedConstructor()) {
        reportError(position(), ParserErrorCode.REDIRECTING_CONSTRUCTOR_CANNOT_HAVE_A_BODY);
      }
    }

    DartFunction function = doneWithoutConsuming(new DartFunction(parameters,
        parametersInfo.optionalOpenOffset, parametersInfo.optionalCloseOffset,
        parametersCloseParen, body, returnType));
    return DartMethodDefinition.create(name, function, modifiers, initializers);
  }

  private DartBlock parseNativeBlock(Modifiers modifiers) {
    beginNativeBody();
    if (!optionalPseudoKeyword(NATIVE_KEYWORD)) {
      throw new AssertionError();
    }
    if (!corelibParse) {
      reportError(position(), ParserErrorCode.NATIVE_ONLY_CORE_LIB);
    }
    DartExpression body = null;
    if (match(Token.STRING)) {
      body = parseStringWithPasting();
    }
    if (match(Token.LBRACE) || match(Token.ARROW)) {
      return done(parseFunctionStatementBody(!modifiers.isExternal(), true));
    } else {
      expect(Token.SEMICOLON);
      return done(new DartNativeBlock(body));
    }
  }

  private DartNodeWithMetadata parseMethodOrAccessor(Modifiers modifiers, DartTypeNode returnType) {
    DartMethodDefinition method = done(parseMethod(modifiers, returnType));
    // Abstract method can not have a body.
    if (method.getFunction().getBody() != null) {
      if (isParsingInterface) {
        reportError(method.getName(), ParserErrorCode.INTERFACE_METHOD_WITH_BODY);
      }
      if (method.getModifiers().isAbstract()) {
        reportError(method.getName(), ParserErrorCode.ABSTRACT_METHOD_WITH_BODY);
      }
    }
    // If getter or setter, generate DartFieldDefinition instead.
    if (method.getModifiers().isGetter() || method.getModifiers().isSetter()) {
      DartField field = new DartField((DartIdentifier) method.getName(),
                                      method.getModifiers().makeAbstractField(), method, null);
      field.setSourceInfo(method.getSourceInfo());
      DartFieldDefinition fieldDefinition =
        new DartFieldDefinition(null, Lists.<DartField>create(field));
      fieldDefinition.setSourceInfo(field.getSourceInfo());
      return fieldDefinition;
    }
    // OK, use method as method.
    return method;
  }

  /**
   * <pre>
   * initializers
   *            : ':' superCallOrFirstFieldInitializer (',' fieldInitializer)*
   *            | THIS ('.' identifier) formalParameterList
   *            ;
   *
   * fieldInitializer
   *            : (THIS '.')? identifier '=' conditionalExpression
   *            ;
   *
   * superCallOrFirstFieldInitializer
   *            : SUPER arguments | SUPER '.' identifier arguments
   *            | fieldInitializer
   *            ;
   *
   * fieldInitializer
   *            : (THIS '.')? identifier '=' conditionalExpression
   *            | THIS ('.' identifier)? arguments
   *            ;
   * </pre>
   */
  private void parseInitializers(List<DartInitializer> initializers) {
    expect(Token.COLON);
    do {
      beginInitializer();
      if (match(Token.SUPER)) {
        beginSuperInitializer();
        expect(Token.SUPER);
        DartIdentifier constructor = null;
        if (optional(Token.PERIOD)) {
          constructor = parseIdentifier();
        }
        DartSuperConstructorInvocation superInvocation =
          new DartSuperConstructorInvocation(constructor, parseArguments());
        initializers.add(done(new DartInitializer(null, done(superInvocation))));
      } else {
        boolean hasThisPrefix = optional(Token.THIS);
        if (hasThisPrefix) {
          if (match(Token.LPAREN)) {
            parseRedirectedConstructorInvocation(null, initializers);
            continue;
          }
          expect(Token.PERIOD);
        }
        DartIdentifier name = parseIdentifier();
        if (hasThisPrefix && match(Token.LPAREN)) {
          parseRedirectedConstructorInvocation(name, initializers);
          continue;
        } else {
          expect(Token.ASSIGN);
          boolean save = setAllowFunctionExpression(false);
          DartExpression initExpr = parseExpression();
          setAllowFunctionExpression(save);
          initializers.add(done(new DartInitializer(name, initExpr)));
        }
      }
    } while (optional(Token.COMMA));
  }

  private void parseRedirectedConstructorInvocation(DartIdentifier name,
      List<DartInitializer> initializers) {
    DartRedirectConstructorInvocation redirConstructor =
        new DartRedirectConstructorInvocation(name, parseArguments());
    initializers.add(done(new DartInitializer(null, doneWithoutConsuming(redirConstructor))));
  }

  private boolean validateInitializers(List<DartParameter> parameters,
      List<DartInitializer> initializers) {
    // Try to find DartRedirectConstructorInvocation, check for multiple invocations.
    // Check for DartSuperConstructorInvocation multiple invocations.
    DartInitializer redirectInitializer = null;
    boolean firstMultipleRedirectReported = false;
    {
      DartInitializer superInitializer = null;
      boolean firstMultipleSuperReported = false;
      for (DartInitializer initializer : initializers) {
        if (initializer.isInvocation()) {
          // DartSuperConstructorInvocation
          DartExpression initializerInvocation = initializer.getValue();
          if (initializerInvocation instanceof DartSuperConstructorInvocation) {
            if (superInitializer != null) {
              if (!firstMultipleSuperReported) {
                reportError(superInitializer, ParserErrorCode.SUPER_CONSTRUCTOR_MULTIPLE);
                firstMultipleSuperReported = true;
              }
              reportError(initializer, ParserErrorCode.SUPER_CONSTRUCTOR_MULTIPLE);
            } else {
              superInitializer = initializer;
            }
          }
          // DartRedirectConstructorInvocation
          if (initializerInvocation instanceof DartRedirectConstructorInvocation) {
            if (redirectInitializer != null) {
              if (!firstMultipleRedirectReported) {
                reportError(redirectInitializer, ParserErrorCode.REDIRECTING_CONSTRUCTOR_MULTIPLE);
                firstMultipleRedirectReported = true;
              }
              reportError(initializer, ParserErrorCode.REDIRECTING_CONSTRUCTOR_MULTIPLE);
            } else {
              redirectInitializer = initializer;
            }
          }
        }
      }
    }
    // If there is redirecting constructor, then there should be no other initializers.
    if (redirectInitializer != null) {
      boolean shouldRedirectInvocationReported = false;
      // Implicit initializer in form of "this.id" parameter.
      for (DartParameter parameter : parameters) {
        if (parameter.getName() instanceof DartPropertyAccess) {
          DartPropertyAccess propertyAccess = (DartPropertyAccess) parameter.getName();
          if (propertyAccess.getQualifier() instanceof DartThisExpression) {
            shouldRedirectInvocationReported = true;
            reportError(
                parameter,
                ParserErrorCode.REDIRECTING_CONSTRUCTOR_PARAM);
          }
        }
      }
      // Iterate all initializers and mark all except of DartRedirectConstructorInvocation
      for (DartInitializer initializer : initializers) {
        if (!(initializer.getValue() instanceof DartRedirectConstructorInvocation)) {
          shouldRedirectInvocationReported = true;
          reportError(
              initializer,
              ParserErrorCode.REDIRECTING_CONSTRUCTOR_OTHER);
        }
      }
      // Mark DartRedirectConstructorInvocation if needed.
      if (shouldRedirectInvocationReported) {
        reportError(
            redirectInitializer,
            ParserErrorCode.REDIRECTING_CONSTRUCTOR_ITSELF);
      }
    }
    // Done.
    return redirectInitializer != null;
  }

  /**
   * <pre>
   * variableDeclaration
   *    : constVarOrType identifierList
   *    ;
   * identifierList
   *    : identifier (',' identifier)*
   *    ;
   *
   * staticConstDeclarationList
   *    : staticConstDeclaration (',' staticConstDeclaration)*
   *    ;
   *
   * staticConstDeclaration
   *    : identifier '=' constantExpression
   *    ;
   *
   * // The compile-time expression production is used to mark certain expressions
   * // as only being allowed to hold a compile-time constant. The grammar cannot
   * // express these restrictions, so this will have to be enforced by a separate
   * // analysis phase.
   * constantExpression
   *    : expression
   *    ;
   * </pre>
   */
  private DartFieldDefinition parseFieldDeclaration(Modifiers modifiers, DartTypeNode type) {
    List<DartField> fields = new ArrayList<DartField>();
    List<DartAnnotation> metadata = parseMetadata();
    do {
      beginVariableDeclaration();
      List<DartAnnotation> fieldMetadata = parseMetadata();
      DartIdentifier name = parseIdentifier();
      DartExpression value = null;
      if (optional(Token.ASSIGN)) {
        value = parseExpression();
        if (value != null) {
          modifiers = modifiers.makeInitialized();
        }
      }
      if (modifiers.isExternal()) {
        reportError(name, ParserErrorCode.EXTERNAL_ONLY_METHOD);
      }
      DartField field = done(new DartField(name, modifiers, null, value));
      setMetadata(field, fieldMetadata);
      fields.add(field);
    } while (optional(Token.COMMA));
    DartFieldDefinition definition = new DartFieldDefinition(type, fields);
    setMetadata(definition, metadata);
    return done(definition);
  }
  
  private static class FormalParameters {
    private final List<DartParameter> val;
    private final int optionalOpenOffset;
    private final int optionalCloseOffset;
    public FormalParameters(List<DartParameter> parameters, int optionalOpenOffset,
        int optionalCloseOffset) {
      this.val = parameters;
      this.optionalOpenOffset = optionalOpenOffset;
      this.optionalCloseOffset = optionalCloseOffset;
    }
  }

  /**
   * <pre>
   * formalParameterList
   *     : '(' ')'
   *     | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *     | '(' optionalFormalParameters ')'
   *     ;
   *
   * normalFormalParameters
   *     : normalFormalParameter (',' normalFormalParameter)*
   *     ;
   *
   * optionalFormalParameters
   *     : optionalPositionalFormalParameters
   *     | namedFormalParameters
   *     ;
   *
   * optionalPositionalFormalParameters
   *     : '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *     ;
   *
   * namedFormalParameters
   *     : '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   *     ;
   * </pre>
   */
  @Terminals(tokens = {Token.COMMA, Token.RPAREN})
  private FormalParameters parseFormalParameterList() {
    beginFormalParameterList();
    List<DartParameter> params = new ArrayList<DartParameter>();
    int optionalOpenOffset = -1;
    int optionalCloseOffset = -1;
    expect(Token.LPAREN);
    boolean done = optional(Token.RPAREN);
    boolean isOptional = false;
    boolean isNamed = false;
    while (!done) {
      if (!isOptional && optional(Token.LBRACK)) {
        if (isNamed) {
          reportErrorWithoutAdvancing(ParserErrorCode.CANNOT_MIX_OPTIONAL_AND_NAMED_PARAMETERS);
        }
        isOptional = true;
        optionalOpenOffset = ctx.getTokenLocation().getBegin();
      }
      if (!isNamed && optional(Token.LBRACE)) {
        if (isOptional) {
          reportErrorWithoutAdvancing(ParserErrorCode.CANNOT_MIX_OPTIONAL_AND_NAMED_PARAMETERS);
        }
        isNamed = true;
        optionalOpenOffset = ctx.getTokenLocation().getBegin();
      }

      DartParameter param = parseFormalParameter(isOptional, isNamed);
      params.add(param);

      if (isOptional && optional(Token.RBRACK)) {
        optionalCloseOffset = ctx.getTokenLocation().getBegin();
        expectCloseParen();
        break;
      }
      if (isNamed && optional(Token.RBRACE)) {
        optionalCloseOffset = ctx.getTokenLocation().getBegin();
        expectCloseParen();
        break;
      }

      // Ensure termination if token is anything other than COMMA.
      // Must keep Token.COMMA in sync with @Terminals above
      if (!optional(Token.COMMA)) {
        if (isOptional && !optional(Token.RBRACE)) {
          reportErrorWithoutAdvancing(ParserErrorCode.MISSING_OPTIONAL_PARAMETER_END);
        }
        if (isNamed && !optional(Token.RBRACK)) {
          reportErrorWithoutAdvancing(ParserErrorCode.MISSING_NAMED_PARAMETER_END);
        }
        // Must keep Token.RPAREN in sync with @Terminals above
        expectCloseParen();
        done = true;
      }
    }

    return new FormalParameters(done(params), optionalOpenOffset, optionalCloseOffset);
  }

  /**
   * <pre>
   * normalFormalParameter
   *     : functionDeclaration
   *     | fieldFormalParameter
   *     | simpleFormalParameter
   *     ;
   *
   * defaultFormalParameter
   *     : normalFormalParameter ('=' constantExpression)?
   *     ;
   * 
   * defaultNamedParameter
   *     : normalFormalParameter (':' constantExpression)?
   *     ;
   * </pre>
   */
  private DartParameter parseFormalParameter(boolean isOptional, boolean isNamed) {
    beginFormalParameter();
    List<DartAnnotation> metadata = parseMetadata();
    DartExpression paramName = null;
    DartTypeNode type = null;
    DartExpression defaultExpr = null;
    List<DartParameter> functionParams = null;
    boolean hasVar = false;
    Modifiers modifiers = Modifiers.NONE;

    if (isOptional) {
      modifiers = modifiers.makeOptional();
      // TODO(brianwilkerson) Remove the line below when we no longer need to support the old syntax.
      modifiers = modifiers.makeNamed();
    }
    if (isNamed) {
      modifiers = modifiers.makeNamed();
    }

    if (optional(Token.FINAL)) {
      modifiers = modifiers.makeFinal();
    } else if (optional(Token.VAR)) {
      hasVar = true;
    }

    boolean isVoidType = false;
    if (!hasVar) {
      isVoidType = (peek(0) == Token.VOID);
      if (isVoidType) {
        type = parseVoidType();
      } else if ((peek(0) != Token.ELLIPSIS)
                 && (peek(1) != Token.COMMA)
                 && (peek(1) != Token.RPAREN)
                 && (peek(1) != Token.RBRACE)
                 && (peek(1) != Token.RBRACK)
                 && (peek(1) != Token.ASSIGN)
                 && (peek(1) != Token.COLON)
                 && (peek(1) != Token.LPAREN)
                 && (peek(0) != Token.THIS)) {
        // Must be a type specification.
        type = parseTypeAnnotation();
      }
    }

    paramName = parseParameterName();

    if (peek(0) == Token.LPAREN) {
      // Function parameter.
      if (modifiers.isFinal()) {
        reportError(position(), ParserErrorCode.FUNCTION_TYPED_PARAMETER_IS_FINAL);
      }
      if (hasVar) {
        reportError(position(), ParserErrorCode.FUNCTION_TYPED_PARAMETER_IS_VAR);
      }
      functionParams = parseFormalParameterList().val;
      validateNoDefaultParameterValues(
          functionParams,
          ParserErrorCode.DEFAULT_VALUE_CAN_NOT_BE_SPECIFIED_IN_CLOSURE);
    } else {
      // Not a function parameter.
      if (isVoidType) {
        reportError(type, ParserErrorCode.VOID_PARAMETER);
      }
    }

    // Look for an initialization expression
    switch (peek(0)) {
      case COMMA:
      case RPAREN:
      case RBRACE:
      case RBRACK:
        // It is a simple parameter.
        break;

      case ASSIGN:
        // Default parameter -- only allowed for optional parameters.
        if (isOptional) {
          consume(Token.ASSIGN);
          defaultExpr = parseExpression();
        } else if (isNamed) {
          reportError(position(), ParserErrorCode.INVALID_SEPARATOR_FOR_NAMED);
          consume(Token.ASSIGN);
          defaultExpr = parseExpression();
        } else {
          reportError(position(), ParserErrorCode.DEFAULT_POSITIONAL_PARAMETER);
        }
        break;

      case COLON:
        // Default parameter -- only allowed for named parameters.
        if (isNamed) {
          consume(Token.COLON);
          defaultExpr = parseExpression();
        } else if (isOptional) {
          reportError(position(), ParserErrorCode.INVALID_SEPARATOR_FOR_OPTIONAL);
          consume(Token.COLON);
          defaultExpr = parseExpression();
        } else {
          reportError(position(), ParserErrorCode.DEFAULT_POSITIONAL_PARAMETER);
        }
        break;

      default:
        reportUnexpectedToken(position(), null, peek(0));
        break;
    }

    DartParameter parameter = new DartParameter(paramName, type, functionParams, defaultExpr,
        modifiers);
    setMetadata(parameter, metadata);
    return done(parameter);
  }

  /**
   * <pre>
   * simpleFormalParameter
   *     : declaredIdentifier
   *     | identifier
   *     ;
   *
   * fieldFormalParameter
   *    : finalVarOrType? THIS '.' identifier
   *    ;
   * </pre>
   */
  private DartExpression parseParameterName() {
    beginParameterName();
    if (match(Token.THIS)) {
      beginThisExpression();
      expect(Token.THIS);
      DartThisExpression thisExpression = done(DartThisExpression.get());
      expect(Token.PERIOD);
      return done(new DartPropertyAccess(thisExpression, parseIdentifier()));
    }
    return done(parseIdentifier());
  }

  /**
   * Validates that given {@link DartParameter}s have no default values, or marks existing default
   * values with given {@link ErrorCode}.
   */
  private void validateNoDefaultParameterValues(List<DartParameter> parameters,
      ErrorCode errorCode) {
    for (DartParameter parameter : parameters) {
      DartExpression defaultExpr = parameter.getDefaultExpr();
      if (defaultExpr != null) {
        reportError(defaultExpr,  errorCode);
      }
    }
  }

  /**
   * Parse an expression.
   *
   * <pre>
   * expression
   *     : assignableExpression assignmentOperator expression
   *     | conditionalExpression cascadeSection*
   *     | throwExpression
   *     ;
   *
   * assignableExpression
   *     : primary (arguments* assignableSelector)+
   *     | SUPER assignableSelector
   *     | identifier
   *     ;
   * </pre>
   *
   * @return an expression matching the {@code expression} production above
   */
  @VisibleForTesting
  public DartExpression parseExpression() {
    if (peek(0) == Token.THROW) {
      return parseThrowExpression(true);
    }
    beginExpression();
    if (looksLikeTopLevelKeyword() || peek(0).equals(Token.RBRACE)) {
      // Allow recovery back to the top level.
      reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
      return done(null);
    }
    DartExpression result = parseConditionalExpression();
    Token token = peek(0);
    if (token == Token.CASCADE) {
      while (token == Token.CASCADE) {
        result = parseCascadeSection(result);
        token = peek(0);
      }
      done(result);
    } else if (token.isAssignmentOperator()) {
      ensureAssignable(result);
      consume(token);
      int tokenOffset = ctx.getTokenLocation().getBegin();
      result = done(new DartBinaryExpression(token, tokenOffset, result, parseExpression()));
    } else {
      done(null);
    }
    return result;
  }

  /**
   * Parse an expression without a cascade.
   *
   * <pre>
   * expressionWithoutCascade
   *     : assignableExpression assignmentOperator expressionWithoutCascade
   *     | conditionalExpression
   *     ;
   * </pre>
   *
   * @return an expression matching the {@code expression} production above
   */
  private DartExpression parseExpressionWithoutCascade() {
    if (peek(0) == Token.THROW) {
      return parseThrowExpression(false);
    }
    beginExpression();
    if (looksLikeTopLevelKeyword() || peek(0).equals(Token.RBRACE)) {
      // Allow recovery back to the top level.
      reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
      return done(null);
    }
    DartExpression result = parseConditionalExpression();
    Token token = peek(0);
   if (token.isAssignmentOperator()) {
      ensureAssignable(result);
      consume(token);
      int tokenOffset = ctx.getTokenLocation().getBegin();
      result = done(new DartBinaryExpression(token, tokenOffset, result, parseExpressionWithoutCascade()));
    } else {
      done(null);
    }
    return result;
  }

  /**
   * Parse a cascade section.
   * <pre>
   * cascadeSection
   *     : CASCADE (cascadeSelector arguments*) (assignableSelector arguments*)* (assignmentOperator
   * expressionWithoutCascade)?
   *     ;
   *
   * cascadeSelector
   *     : LBRACK expression RBRACK
   *     | identifier
   *     ;
   * </pre>
   *
   * @param target the target of the method invocation
   * @return the expression representing the cascaded method invocation
   */
  private DartExpression parseCascadeSection(DartExpression target) {
    expect(Token.CASCADE);
    DartExpression result = target;
    DartIdentifier functionName = null;
    if (peek(0) == Token.IDENTIFIER) {
      functionName = parseIdentifier();
    } else if (peek(0) == Token.LBRACK) {
      consume(Token.LBRACK);
      result = doneWithoutConsuming(new DartArrayAccess(result, parseExpression()));
      expect(Token.RBRACK);
    } else {
      reportUnexpectedToken(position(), null, next());
      return result;
    }
    if (peek(0) == Token.LPAREN) {
      while (peek(0) == Token.LPAREN) {
        if (functionName != null) {
          result = doneWithoutConsuming(new DartMethodInvocation(result, true, functionName, parseArguments()));
          functionName = null;
        } else {
          result = doneWithoutConsuming(new DartFunctionObjectInvocation(result, parseArguments()));
        }
      }
    } else if (functionName != null) {
      result = doneWithoutConsuming(new DartPropertyAccess(result, true, functionName));
    }
    boolean progress = true;
    while (progress) {
      progress = false;
      DartExpression selector = tryParseAssignableSelector(result);
      if (selector != null) {
        result = selector;
        progress = true;
        while (peek(0) == Token.LPAREN) {
          result = doneWithoutConsuming(new DartFunctionObjectInvocation(result, parseArguments()));
        }
      }
    }
    Token token = peek(0);
    if (token.isAssignmentOperator()) {
      ensureAssignable(result);
      consume(token);
      int tokenOffset = ctx.getTokenLocation().getBegin();
      result = doneWithoutConsuming(new DartBinaryExpression(token, tokenOffset, result, parseExpressionWithoutCascade()));
    }
    return result;
  }

  /**
   * expressionList
   *     : expression (',' expression)*
   *     ;
   */
  @Terminals(tokens={Token.COMMA})
  private DartExpression parseExpressionList() {
    beginExpressionList();
    DartExpression result = parseExpression();
    // Must keep in sync with @Terminals above
    while (optional(Token.COMMA)) {
      int tokenOffset = ctx.getTokenLocation().getBegin();
      result = new DartBinaryExpression(Token.COMMA, tokenOffset, result, parseExpression());
      if (match(Token.COMMA)) {
        result = doneWithoutConsuming(result);
      }
    }
    return done(result);
  }


  /**
   * Parse a binary expression.
   *
   * <pre>
   * logicalOrExpression
   *     : logicalAndExpression ('||' logicalAndExpression)*
   *     ;
   *
   * logicalAndExpression
   *     : bitwiseOrExpression ('&&' bitwiseOrExpression)*
   *     ;
   *
   * bitwiseOrExpression
   *     : bitwiseXorExpression ('|' bitwiseXorExpression)*
   *     ;
   *
   * bitwiseXorExpression
   *     : bitwiseAndExpression ('^' bitwiseAndExpression)*
   *     ;
   *
   * bitwiseAndExpression
   *     : equalityExpression ('&' equalityExpression)*
   *     ;
   *
   * equalityExpression
   *     : relationalExpression (equalityOperator relationalExpression)?
   *     ;
   *
   * relationalExpression
   *     : shiftExpression (isOperator type | relationalOperator shiftExpression)?
   *     ;
   *
   * shiftExpression
   *     : additiveExpression (shiftOperator additiveExpression)*
   *     ;
   *
   * additiveExpression
   *     : multiplicativeExpression (additiveOperator multiplicativeExpression)*
   *     ;
   *
   * multiplicativeExpression
   *     : unaryExpression (multiplicativeOperator unaryExpression)*
   *     ;
   * </pre>
   *
   * @return an expression matching one of the productions above
   */
  private DartExpression parseBinaryExpression(int precedence) {
    assert (precedence >= 4);
    beginBinaryExpression();
    DartExpression lastResult = parseUnaryExpression();
    DartExpression result = lastResult;
    for (int level = peek(0).getPrecedence(); level >= precedence; level--) {
      while (peek(0).getPrecedence() == level) {
        int prevPositionStart = ctx.getTokenLocation().getBegin();
        int prevPositionEnd = ctx.getTokenLocation().getEnd();
        Token token = next();
        int tokenOffset = ctx.getTokenLocation().getBegin();
        if (lastResult instanceof DartSuperExpression
            && (token == Token.AND || token == Token.OR)) {
          reportErrorAtPosition(prevPositionStart, prevPositionEnd,
                                ParserErrorCode.SUPER_IS_NOT_VALID_AS_A_BOOLEAN_OPERAND);
        }
        DartExpression right;
        if (token == Token.IS) {
          beginTypeExpression();
          if (optional(Token.NOT)) {
            int notOffset = ctx.getTokenLocation().getBegin();
            beginTypeExpression();
            DartTypeExpression typeExpression = done(new DartTypeExpression(parseTypeAnnotation()));
            right = done(new DartUnaryExpression(Token.NOT, notOffset, typeExpression, true));
          } else {
            right = done(new DartTypeExpression(parseTypeAnnotation()));
          }
        } else if (token == Token.AS) {
          beginTypeExpression();
          right = done(new DartTypeExpression(parseTypeAnnotation()));
        } else {
          right = parseBinaryExpression(level + 1);
        }
        if (right instanceof DartSuperExpression) {
          reportError(position(), ParserErrorCode.SUPER_CANNOT_BE_USED_AS_THE_SECOND_OPERAND);
        }

        lastResult = right;
        result = doneWithoutConsuming(new DartBinaryExpression(token, tokenOffset, result, right));
        if (token == Token.IS
            || token == Token.AS
            || token.isRelationalOperator()
            || token.isEqualityOperator()) {
          // The operations cannot be chained.
          if (match(token)) {
            reportError(position(), ParserErrorCode.INVALID_OPERATOR_CHAINING,
              token.toString().toLowerCase());
          }
          break;
        }
      }
    }
    done(null);
    return result;
  }

  /**
   * Parse the arguments passed to a function or method invocation.
   *
   * <pre>
   * arguments
   *    : '(' argumentList? ')'
   *    ;
   *
   * argumentList
   *    : expression (',' expression)* (',' spreadArgument)?
   *    | spreadArgument
   *    ;
   *
   * spreadArgument
   *    : '...' expression
   *    ;
   * </pre>
   *
   * @return a list of expressions containing the arguments to be passed
   */
  @Terminals(tokens={Token.RPAREN, Token.COMMA})
  public List<DartExpression> parseArguments() {
    List<DartExpression> arguments = new ArrayList<DartExpression>();
    expect(Token.LPAREN);
    // SEMICOLON is for error recovery
    boolean namedArgumentParsed = false;
    outer: while (!match(Token.RPAREN) && !match(Token.EOS) && !match(Token.SEMICOLON)) {
      beginParameter();
      // parse argument, may be named
      DartExpression expression;
      if (peek(1) == Token.COLON) {
        DartIdentifier name = parseIdentifier();
        expect(Token.COLON);
        expression = new DartNamedExpression(name, parseExpression());
        namedArgumentParsed = true;
      } else {
        expression = parseExpression();
        if (namedArgumentParsed) {
          reportError(expression, ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT);
        }
      }
      done(expression);
      // add argument, if parsed successfully
      if (expression != null) {
        arguments.add(expression);
      }
      // do we have more arguments?
      switch(peek(0)) {
        // Must keep in sync with @Terminals above
        case COMMA:
          if (peek(-1) == Token.COMMA) {
            reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_EXPRESSION_AFTER_COMMA);
          }
          consume(Token.COMMA);
          break;
          // Must keep in sync with @Terminals above
        case RPAREN:
          break;
        default:
          Token actual = peek(0);
          Set<Token> terminals = collectTerminalAnnotations();
          if (terminals.contains(actual) || looksLikeTopLevelKeyword()) {
            // Looks like a method already on the stack could use this token.
            reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_COMMA_OR_RIGHT_PAREN);
            break outer;
          } else {
            // Advance the parser state if no other method on the stack can use this token.
            ctx.advance();
          }
          reportError(ctx.getTokenLocation().getEnd(),
              ParserErrorCode.EXPECTED_COMMA_OR_RIGHT_PAREN, actual);
          break;
      }
    }
    if (peek(-1) == Token.COMMA) {
      reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_EXPRESSION_AFTER_COMMA);
    }
    expectCloseParen();
    return arguments;
  }

  /**
   * Parse a conditional expression.
   *
   * <pre>
   * conditionalExpression
   *     : logicalOrExpression ('?' expression ':' expression)?
   *     ;
   * </pre>
   *
   * @return an expression matching the {@code conditionalExpression} production
   */
  private DartExpression parseConditionalExpression() {
    beginConditionalExpression();
    DartExpression result = parseBinaryExpression(4);
    if (result instanceof DartSuperExpression) {
      reportError(position(), ParserErrorCode.SUPER_IS_NOT_VALID_ALONE_OR_AS_A_BOOLEAN_OPERAND);
    }
    if (peek(0) != Token.CONDITIONAL) {
      return done(result);
    }
    consume(Token.CONDITIONAL);
    DartExpression yes = parseExpression();
    expect(Token.COLON);
    DartExpression no = parseExpression();
    return done(new DartConditional(result, yes, no));
  }

  private boolean looksLikeStringInterpolation() {
    int peekAhead = 0;
    while (true) {
      switch (peek(peekAhead++)) {
        case STRING:
          break;
        case STRING_SEGMENT:
        case STRING_LAST_SEGMENT:
        case STRING_EMBED_EXP_START:
        case STRING_EMBED_EXP_END:
          return true;
        default:
          return false;
      }
    }
  }
  /**
   * Pastes together adjacent strings.  Re-uses the StringInterpolation
   * node if there is more than one adjacent string.
   */
  private DartExpression parseStringWithPasting() {
    List<DartExpression> expressions = new ArrayList<DartExpression>();
    if (looksLikeStringInterpolation()) {
      beginStringInterpolation();
    } else {
      beginLiteral();
    }
    DartExpression result = null;
    boolean foundStringInterpolation = false;
    do {
      result = null;
      switch(peek(0)) {
        case STRING:
        case STRING_SEGMENT:
        case STRING_EMBED_EXP_START:
          // another string is coming, glue it together.
          result = parseString();
          if (result != null) {
            expressions.add(result);
          }
          if (result instanceof DartStringInterpolation) {
            foundStringInterpolation = true;
          }
          break;
      }
    } while (result != null);

    if (expressions.size() == 0) {
      return doneWithoutConsuming(null);
    } else if (expressions.size() == 1) {
      return done(expressions.get(0));
    }

    if (foundStringInterpolation) {
      DartStringInterpolationBuilder builder = new DartStringInterpolationBuilder();
      // Create a new DartStringInterpolation object from the expressions.
      boolean first = true;
      for (DartExpression expr : expressions) {
        if (!first) {
          // pad between interpolations with a dummy expression
          builder.addExpression(DartStringLiteral.get(""));
        }
        if (expr instanceof DartStringInterpolation) {
          builder.addInterpolation((DartStringInterpolation)expr);
        } else if (expr instanceof DartStringLiteral) {
          builder.addString((DartStringLiteral)expr);
        } else {
          throw new InternalCompilerException("Expected String or StringInterpolation");
        }
        first = false;
      }
      return done(builder.buildInterpolation());
    }

    // Synthesize a single String literal
    List<DartStringLiteral> stringParts = new ArrayList<DartStringLiteral>();
    StringBuilder builder = new StringBuilder();
    for (DartExpression expr : expressions) {
      DartStringLiteral stringPart = (DartStringLiteral)expr;
      stringParts.add(stringPart);
      builder.append(stringPart.getValue());
    }
    return done(DartStringLiteral.get(builder.toString(), stringParts));
  }

  private DartExpression parseString() {
    switch(peek(0)) {
      case STRING: {
        beginLiteral();
        consume(Token.STRING);
        return done(DartStringLiteral.get(ctx.getTokenString()));
      }

      case STRING_SEGMENT:
      case STRING_EMBED_EXP_START:
        return parseStringInterpolation();

      default:
        DartExpression expression = parseExpression();
        reportError(position(), ParserErrorCode.EXPECTED_STRING_LITERAL);
        return expression;
    }
  }

  private int skipStringLiteral(int offset) {
    Token token = peek(offset);
    while (token == Token.STRING || token == Token.STRING_SEGMENT || token == Token.STRING_EMBED_EXP_START) {
      switch(token) {
        case STRING:
          offset = offset + 1;
  
        case STRING_SEGMENT:
        case STRING_EMBED_EXP_START:
          offset = skipStringInterpolation(offset);
      }
      token = peek(offset);
    }
    return offset;
  }

  private int skipStringInterpolation(int offset) {
    Token token = peek(offset);
    if (token == Token.STRING_LAST_SEGMENT) {
      return -1;
    }
    boolean inString = true;
    while (inString) { // Iterate until we find the last string segment.
      switch (token) {
        case STRING_SEGMENT:
          offset = offset + 1;
          token = peek(offset);
          break;
        case STRING_LAST_SEGMENT:
          offset = offset + 1;
          token = peek(offset);
          inString = false;
          break;
        case STRING_EMBED_EXP_START: {
          offset = offset + 1;
          token = peek(offset);
          while (token != Token.EOS && token != Token.STRING_EMBED_EXP_END && token != Token.STRING_LAST_SEGMENT) {
            if (token == Token.STRING || token == Token.STRING_SEGMENT || token == Token.STRING_EMBED_EXP_START) {
              offset = skipStringLiteral(offset);
            } else {
              offset = offset + 1;
            }
            token = peek(offset);
          }
          if (token != Token.STRING_EMBED_EXP_END) {
            inString = Token.STRING_LAST_SEGMENT != token;
          }
          break;
        }
        default:
          inString = false;
          break;
      }
    }
    return offset;
  }

  /**
   * Instances of the class {@code DepthCounter} represent the number of less than tokens that have
   * not yet been matched.
   */
  private static class DepthCounter {
    /**
     * The number of less than tokens that have not yet been matched.
     */
    private int count = 0;

    /**
     * Increment the number of less than tokens that have not yet been matched by the given amount
     * (or decrement the count if the argument is negative).
     * 
     * @param value the amount by which the count should be changed
     * @return the count after it has been modified
     */
    public int add(int value) {
      count += value;
      return count;
    }

    /**
     * Return the number of less than tokens that have not yet been matched.
     * 
     * @return the number of less than tokens that have not yet been matched
     */
    public int getCount() {
      return count;
    }
  }

  /**
   * Return the offset of the first token after a type name, or {@code -1} if the token at the given
   * offset is not the start of a type name.
   * 
   * @param offset the offset of the first token of the type name
   * @return the offset of the first token after a type name
   */
  private int skipTypeName(int offset) {
    return skipTypeName(offset, new DepthCounter());
  }

  /**
   * Return the offset of the first token after a type name, or {@code -1} if the token at the given
   * offset is not the start of a type name.
   * 
   * @param offset the offset of the first token of the type name
   * @param depth the number of less-thans that have been encountered since the outer-most type name
   * @return the offset of the first token after a type name
   */
  private int skipTypeArguments(int offset, DepthCounter depth) {
    if (peek(offset) != Token.LT) {
      return -1;
    }
    int oldDepth = depth.add(1);
    offset = skipTypeName(offset + 1, depth);
    if (offset < 0) {
      return offset;
    }
    while (peek(offset) == Token.COMMA) {
      offset = skipTypeName(offset + 1, depth);
      if (offset < 0) {
        return offset;
      }
    }
    if (depth.getCount() < oldDepth) {
      // We already passed the closing '>' for this list of type arguments
      return offset;
    }
    if (peek(offset) == Token.GT) {
      depth.add(-1);
      return offset + 1;
    } else if (peek(offset) == Token.SAR) {
      depth.add(-2);
      return offset + 1;
    }
    return -1;
  }

  /**
   * Return the offset of the first token after a type name, or {@code -1} if the token at the given
   * offset is not the start of a type name.
   * 
   * @param offset the offset of the first token of the type name
   * @param depth the number of less-thans that have been encountered since the outer-most type name
   * @return the offset of the first token after a type name
   */
  private int skipTypeName(int offset, DepthCounter depth) {
    if (peek(offset) != Token.IDENTIFIER) {
      return -1;
    }
    offset++;
    if (peek(offset) == Token.PERIOD) {
      offset++;
      if (peek(offset) == Token.IDENTIFIER) {
        // We tolerate a missing identifier in order to recover better
        offset++;
      }
    }
    if (peek(offset) == Token.LT) {
      offset = skipTypeArguments(offset, depth);
    }
    return offset;
  }

  /**
   * Parse any literal that is not a function literal (those have already been
   * handled before this method is called, so we don't need to handle them
   * here).
   *
   * <pre>
   * nonFunctionLiteral
   *   : NULL
   *   | TRUE
   *   | FALSE
   *   | HEX_NUMBER
   *   | RATIONAL_NUMBER
   *   | DOUBLE_NUMBER
   *   | STRING
   *   | mapLiteral
   *   | arrayLiteral
   *   ;
   * </pre>
   *
   * @return an expression matching the {@code literal} production above
   */
  private DartExpression parseLiteral() {
    beginLiteral();
    if (PSEUDO_KEYWORDS_SET.contains(peek(0).getSyntax())) {
      return done(parseIdentifier());
    }
    switch (peek(0)) {
      case NULL_LITERAL: {
        consume(Token.NULL_LITERAL);
        return done(DartNullLiteral.get());
      }

      case TRUE_LITERAL: {
        consume(Token.TRUE_LITERAL);
        return done(DartBooleanLiteral.get(true));
      }

      case FALSE_LITERAL: {
        consume(Token.FALSE_LITERAL);
        return done(DartBooleanLiteral.get(false));
      }

      case INTEGER_LITERAL: {
        consume(Token.INTEGER_LITERAL);
        String number = ctx.getTokenString();
        return done(DartIntegerLiteral.get(new BigInteger(number)));
      }

      case DOUBLE_LITERAL: {
        consume(Token.DOUBLE_LITERAL);
        String number = ctx.getTokenString();
        return done(DartDoubleLiteral.get(Double.parseDouble(number)));
      }

      case HEX_LITERAL: {
        consume(Token.HEX_LITERAL);
        String number = ctx.getTokenString();
        return done(DartIntegerLiteral.get(new BigInteger(number, 16)));
      }

      case LBRACE: {
        return done(parseMapLiteral(false, null));
      }

      case INDEX: {
        expect(peek(0));
        return done(new DartArrayLiteral(false, null, new ArrayList<DartExpression>()));
      }

      case LBRACK: {
        return done(parseArrayLiteral(false, null));
      }

      case VOID:
        // For better error recovery / code completion in the IDE, treat "void" as an identifier
        // here and let it get reported as a resolution error.
      case IDENTIFIER: {
        return done(parseIdentifier());
      }

      case SEMICOLON: {
        // this is separate from the default case for better error recovery,
        // leaving the semicolon for the caller to use for a statement boundary

        // we have to advance to get the proper position, but we want to leave
        // the semicolon
        startLookahead();
        next();
        reportUnexpectedToken(position(), null, Token.SEMICOLON);
        rollback();
        return done(new DartSyntheticErrorExpression(""));
      }

      default: {
        Token unexpected = peek(0);
        String unexpectedString = ctx.getTokenString();
        if (unexpectedString == null && unexpected != Token.EOS) {
          unexpectedString = unexpected.getSyntax();
        }

        // Don't eat tokens that could be used to successfully terminate a non-terminal
        // further up the stack.
        Set<Token> terminals = collectTerminalAnnotations();
        if (!looksLikeTopLevelKeyword() && !terminals.contains(unexpected)) {
          next();
        }
        reportUnexpectedToken(position(), null, unexpected);
        StringBuilder tokenStr = new StringBuilder();
        if (unexpectedString != null) {
          tokenStr.append(unexpectedString);
        }
        // TODO(jat): should we eat additional tokens here for error recovery?
        return done(new DartSyntheticErrorExpression(tokenStr.toString()));
      }
    }
  }

  /**
   * mapLiteralEntry
   *     : STRING ':' expression
   *     ;
   */
  private DartMapLiteralEntry parseMapLiteralEntry() {
    beginMapLiteralEntry();
    // Parse the key.
    DartExpression keyExpr = parseStringWithPasting();
    if (keyExpr == null) {
      return done(null);
    }
    // Parse the value.
    DartExpression value;
    if (expect(Token.COLON)) {
      value = parseExpression();
    } else {
      value = doneWithoutConsuming(new DartSyntheticErrorExpression());
    }
    return done(new DartMapLiteralEntry(keyExpr, value));
  }
  private boolean looksLikeString() {
    switch(peek(0)) {
      case STRING:
      case STRING_SEGMENT:
      case STRING_EMBED_EXP_START:
        return true;
    }
    return false;
  }

  /**
   * <pre> mapLiteral : '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}' ;
   * </pre>
   */
  @Terminals(tokens={Token.RBRACE, Token.COMMA})
  private DartExpression parseMapLiteral(boolean isConst, List<DartTypeNode> typeArguments) {
    beginMapLiteral();
    boolean foundOpenBrace = expect(Token.LBRACE);
    boolean save = setAllowFunctionExpression(true);
    List<DartMapLiteralEntry> entries = new ArrayList<DartMapLiteralEntry>();

    while (!match(Token.RBRACE) && !match(Token.EOS)) {
      if (!looksLikeString()) {
        ctx.advance();
        reportError(position(), ParserErrorCode.EXPECTED_STRING_LITERAL_MAP_ENTRY_KEY);
        if (peek(0) == Token.COMMA) {
          // a common error is to put an empty entry in the list, allow it to
          // recover.
          continue;
        } else {
          break;
        }
      }
      DartMapLiteralEntry entry = parseMapLiteralEntry();
      if (entry != null) {
        entries.add(entry);
      }
      Token nextToken = peek(0);
      switch (nextToken) {
        // Must keep in sync with @Terminals above
        case COMMA:
          consume(Token.COMMA);
          break;
        // Must keep in sync with @Terminals above
        case RBRACE:
          break;
        default:
          if (entry == null) {
            Set<Token> terminals = collectTerminalAnnotations();
            if (!terminals.contains(nextToken) && !looksLikeTopLevelKeyword()) {
              if (entry == null) {
                // Ensure the parser makes progress.
                ctx.advance();
              }
            }
          }
          reportError(position(), ParserErrorCode.EXPECTED_COMMA_OR_RIGHT_BRACE);
          break;
      }
    }

    expectCloseBrace(foundOpenBrace);
    setAllowFunctionExpression(save);
    return done(new DartMapLiteral(isConst, typeArguments, entries));
  }

  /**
   * // The array literal syntax doesn't allow elided elements, unlike
   * // in ECMAScript.
   *
   * <pre>
   * arrayLiteral
   *     : '[' expressionList? ']'
   *     ;
   * </pre>
   */
  @Terminals(tokens={Token.RBRACK, Token.COMMA})
  private DartExpression parseArrayLiteral(boolean isConst, List<DartTypeNode> typeArguments) {
    beginArrayLiteral();
    expect(Token.LBRACK);
    boolean save = setAllowFunctionExpression(true);
    List<DartExpression> exprs = new ArrayList<DartExpression>();
    while (!match(Token.RBRACK) && !EOS()) {
      exprs.add(parseExpression());
      // Must keep in sync with @Terminals above
      if (!optional(Token.COMMA)) {
        break;
      }
    }
    // Must keep in sync with @Terminals above
    expect(Token.RBRACK);
    setAllowFunctionExpression(save);
    return done(new DartArrayLiteral(isConst, typeArguments, exprs));
  }

  /**
   * Parse a postfix expression.
   *
   * <pre>
   * postfixExpression
   *     | assignableExpression postfixOperator
   *     : primary selector*
   *     ;
   * </pre>
   *
   * @return an expression matching the {@code postfixExpression} production above
   */
  private DartExpression parsePostfixExpression() {
    beginPostfixExpression();
    DartExpression receiver = doneWithoutConsuming(parsePrimaryExpression());
    DartExpression result = receiver;
    do {
      receiver = result;
      result = doneWithoutConsuming(parseSelectorExpression(receiver));
    } while (receiver != result);

    Token token = peek(0);
    if (token.isCountOperator()) {
      ensureAssignable(result);
      consume(token);
      int tokenOffset = ctx.getTokenLocation().getBegin();
      result = doneWithoutConsuming(new DartUnaryExpression(token, tokenOffset, result, false));
    }

    return done(result);
  }

  /**
   * <pre>
   * typeParameters? (arrayLiteral | mapLiteral)
   * </pre>
   *
   * @param isConst <code>true</code> if a CONST expression
   *
   */
  private DartExpression tryParseTypedCompoundLiteral(boolean isConst) {
    beginLiteral();
    List<DartTypeNode> typeArguments = parseTypeArgumentsOpt();
    switch (peek(0)) {
      case INDEX:
        beginArrayLiteral();
        consume(Token.INDEX);
        return done(done(new DartArrayLiteral(isConst, typeArguments, new ArrayList<DartExpression>())));
      case LBRACK:
        return done(parseArrayLiteral(isConst, typeArguments));
      case LBRACE:
        return done(parseMapLiteral(isConst, typeArguments));
      default:
        if (typeArguments != null) {
          rollback();
          return null;
        }

    }
    // Doesn't look like a typed compound literal and no tokens consumed.
    return done(null);
  }

  private enum LastSeenNode {
    NONE,
    STRING,
    EXPRESSION;
  }

  private class DartStringInterpolationBuilder {

    private final List<DartStringLiteral> strings = new ArrayList<DartStringLiteral>();
    private final List<DartExpression> expressions = new ArrayList<DartExpression>();
    private LastSeenNode lastSeen = LastSeenNode.NONE;

    DartStringInterpolationBuilder() {
    }

    void addString(DartStringLiteral string) {
      if (lastSeen == LastSeenNode.STRING) {
        expressions.add(new DartSyntheticErrorExpression());
      }
      strings.add(string);
      lastSeen = LastSeenNode.STRING;
    }

    void addExpression(DartExpression expression) {
      switch (lastSeen) {
        case EXPRESSION:
        case NONE:
          strings.add(DartStringLiteral.get(""));
          break;
        default:
          break;
      }
      expressions.add(expression);
      lastSeen = LastSeenNode.EXPRESSION;
    }

    void addInterpolation(DartStringInterpolation interpolation) {
      strings.addAll(interpolation.getStrings());
      expressions.addAll(interpolation.getExpressions());
      lastSeen = LastSeenNode.STRING;
    }

    DartStringInterpolation buildInterpolation() {
      if (strings.size() == expressions.size()) {
        strings.add(DartStringLiteral.get(""));
      }
      return new DartStringInterpolation(strings, expressions);
    }
  }

  /**
   * Instances of the class {@code StringInterpolationParseError} represent the detection of an
   * error that needs to be handled in an enclosing context.
   */
  private static class StringInterpolationParseError extends RuntimeException {
    private static final long serialVersionUID = 1L;

    public StringInterpolationParseError() {
      super();
    }
  }

  /**
   * <pre>
   * string-interpolation
   *   : (STRING_SEGMENT? embedded-exp?)* STRING_LAST_SEGMENT
   *
   * embedded-exp
   *   : STRING_EMBED_EXP_START expression STRING_EMBED_EXP_END
   * </pre>
   */
  private DartExpression parseStringInterpolation() {
    // TODO(sigmund): generalize to parse string templates as well.
    if (peek(0) == Token.STRING_LAST_SEGMENT) {
      throw new InternalCompilerException("Invariant broken");
    }
    beginStringInterpolation();
    DartStringInterpolationBuilder builder = new DartStringInterpolationBuilder();
    boolean inString = true;
    while (inString) { // Iterate until we find the last string segment.
      switch (peek(0)) {
        case STRING_SEGMENT: {
          beginStringSegment();
          consume(Token.STRING_SEGMENT);
          builder.addString(done(DartStringLiteral.get(ctx.getTokenString())));
          break;
        }
        case STRING_LAST_SEGMENT: {
          beginStringSegment();
          consume(Token.STRING_LAST_SEGMENT);
          builder.addString(done(DartStringLiteral.get(ctx.getTokenString())));
          inString = false;
          break;
        }
        case STRING_EMBED_EXP_START: {
          consume(Token.STRING_EMBED_EXP_START);
          /*
           * We check for ILLEGAL specifically here to give nicer error
           * messages, and because the scanner doesn't generate a
           * STRING_EMBED_EXP_END to match the START in the case of an ILLEGAL
           * token.
           */
          if (peek(0) == Token.ILLEGAL) {
            reportError(position(), ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION,
                next());
            builder.addExpression(new DartSyntheticErrorExpression(""));
            break;
          } else {
            try {
              builder.addExpression(parseExpression());
            } catch (StringInterpolationParseError exception) {
              if (peek(0) == Token.STRING_LAST_SEGMENT) {
                break;
              }
              throw new InternalCompilerException("Invalid expression found in string interpolation");
            }
          }
          Token lookAhead = peek(0);
          String lookAheadString = getPeekTokenValue(0);
          if (!expect(Token.STRING_EMBED_EXP_END)) {
            String errorText = null;
            if (lookAheadString != null && lookAheadString.length() > 0) {
              errorText = lookAheadString;
            } else if (lookAhead.getSyntax() != null && lookAhead.getSyntax().length() > 0) {
              errorText = lookAhead.getSyntax();
            }
            if (errorText != null) {
              builder.addExpression(new DartSyntheticErrorExpression(errorText));
            }
            inString = !(Token.STRING_LAST_SEGMENT == lookAhead);
          }
          break;
        }
        case EOS: {
          reportError(position(), ParserErrorCode.INCOMPLETE_STRING_LITERAL);
          inString = false;
          break;
        }
        default: {
          String errorText = getPeekTokenValue(0) != null && getPeekTokenValue(0).length() > 0
              ? getPeekTokenValue(0) : null;
          if(errorText != null) {
            builder.addExpression(new DartSyntheticErrorExpression(getPeekTokenValue(0)));
          }
          reportError(position(), ParserErrorCode.UNEXPECTED_TOKEN_IN_STRING_INTERPOLATION,
              next());
          break;
        }
      }
    }
    return done(builder.buildInterpolation());
  }

  /**
   * Parse a return type, giving an error if the .
   *
   * @return a return type or null if the current text is not a return type
   */
  private DartTypeNode parseReturnType() {
    if (peek(0) == Token.VOID) {
      return parseVoidType();
    } else {
      return parseTypeAnnotation();
    }
  }

  /**
   * Check if the current text could be a return type, and advance past it if so.  The current
   * position is unchanged if it is not a return type.
   *
   * NOTE: if the grammar is changed for what constitutes an acceptable return type, this method
   * must be updated to match {@link #parseReturnType()}/etc.
   *
   * @return true if current text could be a return type, false otherwise
   */
  private boolean isReturnType() {
    beginReturnType();
    if (optional(Token.VOID)) {
      done(null);
      return true;
    }
    if (!optional(Token.IDENTIFIER)) {
      rollback();
      return false;
    }
    // handle prefixed identifiers
    if (optional(Token.PERIOD)) {
      if (!optional(Token.IDENTIFIER)) {
        rollback();
        return false;
      }
    }
    // skip over type arguments if they are present
    if (optional(Token.LT)) {
      int count = 1;
      while (count > 0) {
        switch (next()) {
          case EOS:
            rollback();
            return false;
          case LT:
            count++;
            break;
          case GT:
            count--;
            break;
          case SHL:
            count += 2;
            break;
          case SAR:  // >>
            count -= 2;
            break;
          case COMMA:
          case IDENTIFIER:
            // extends is a pseudokeyword, so shows up as IDENTIFIER
            break;
          default:
            rollback();
            return false;
        }
      }
      if (count < 0) {
        // if we had too many > (which can only be >> or >>>), can't be a return type
        rollback();
        return false;
      }
    }
    done(null);
    return true;
  }

  /**
   * Checks to see if the current text looks like a function expression:
   *
   * <pre>
   *   FUNCTION name? ( args ) < => | { >
   *   returnType name? ( args ) < => | { >
   *   name? ( args ) < => | { >
   * </pre>
   *
   * The current position is unchanged on return.
   *
   * NOTE: if the grammar for function expressions changes, this method must be
   * adapted to match the actual parsing code. It is acceptable for this method
   * to return true when the source text does not actually represent a function
   * expression (which would result in error messages assuming it was a function
   * expression, but it must not do so when the source text would be correct if
   * parsed as a non-function expression.
   *
   * @return true if the current text looks like a function expression, false
   *         otherwise
   */
  @VisibleForTesting
  boolean looksLikeFunctionExpression() {
    if (!allowFunctionExpression) {
      return false;
    }
    return looksLikeFunctionDeclarationOrExpression();
  }

  /**
   * Check to see if the following tokens could be a function expression, and if so try and parse
   * it as one.
   *
   * @return a function expression if found, or null (with no tokens consumed) if not
   */
  private DartExpression parseFunctionExpressionWithReturnType() {
    beginFunctionLiteral();
    DartIdentifier[] namePtr = new DartIdentifier[1];
    DartFunction function = parseFunctionDeclarationOrExpression(namePtr, false);
    if (function == null) {
      rollback();
      return null;
    }
    return done(new DartFunctionExpression(namePtr[0], doneWithoutConsuming(function), false));
  }

  /**
   * Parse a function declaration or expression, including the body.
   * <pre>
   *     ... | functionDeclaration functionBody
   *
   * functionDeclaration
   *    : returnType? identifier formalParameterList
   *    ;
   *
   * functionExpression
   *    : (returnType? identifier)? formalParameterList functionExpressionBody
   *    ;
   *
   * functionBody
   *    : '=>' expression ';'
   *    | block
   *    ;
   *
   * functionExpressionBody
   *    : '=>' expression
   *    | block
   *    ;
   * </pre>
   *
   * @param namePtr out parameter - parsed function name stored in namePtr[0]
   * @param isDeclaration true if this is a declaration (i.e. a name is required and a trailing
   *     semicolon is needed for arrow syntax
   * @return a {@link DartFunction} containing the body of the function, or null
   *     if the next tokens cannot be parsed as a function declaration or expression
   */
  private DartFunction parseFunctionDeclarationOrExpression(DartIdentifier[] namePtr,
      boolean isDeclaration) {
    DartTypeNode returnType = null;
    namePtr[0] = null;
    if (optionalPseudoKeyword(STATIC_KEYWORD)) {
      reportError(position(), ParserErrorCode.LOCAL_CANNOT_BE_STATIC);
    }
    switch (peek(0)) {
      case LPAREN:
        // no type or name, just the formal parameter list
        break;
      case IDENTIFIER:
        if (peek(1) == Token.LPAREN) {
          // if there is only one identifier, it must be the name
          namePtr[0] = parseIdentifier();
          break;
        }
        //$FALL-THROUGH$
      case VOID:
        returnType = parseReturnType();
        if (peek(0) == Token.IDENTIFIER) {
          namePtr[0] = parseIdentifier();
        }
        break;
      default:
        return null;
    }
    FormalParameters params = parseFormalParameterList();
    int parametersCloseParen = ctx.getTokenLocation().getBegin();
    DartBlock body = parseFunctionStatementBody(true, isDeclaration);
    DartFunction function = new DartFunction(params.val, params.optionalOpenOffset,
        params.optionalCloseOffset, parametersCloseParen, body, returnType);
    doneWithoutConsuming(function);
    return function;
  }

  /**
   * Parse a primary expression.
   *
   * <pre>
   * primary
   *   : THIS
   *   | SUPER assignableSelector
   *   | literal
   *   | identifier
   *   | NEW type ('.' identifier)? arguments
   *   | typeArguments? (arrayLiteral | mapLiteral)
   *   | CONST typeArguments? (arrayLiteral | mapLiteral)
   *   | CONST typeArguments? (arrayLiteral | mapLiteral)
   *   | CONST type ('.' identifier)? arguments
   *   | '(' expression ')'
   *   | string-interpolation
   *   | functionExpression
   *   ;
   * </pre>
   *
   * @return an expression matching the {@code primary} production above
   */
  private DartExpression parsePrimaryExpression() {
    if (looksLikeFunctionExpression()) {
      return parseFunctionExpressionWithReturnType();
    }
    switch (peek(0)) {
      case THIS: {
        beginThisExpression();
        consume(Token.THIS);
        return done(DartThisExpression.get());
      }

      case SUPER: {
        beginSuperExpression();
        consume(Token.SUPER);
        return done(DartSuperExpression.get());
      }

      case NEW: {
        beginNewExpression(); // DartNewExpression
        consume(Token.NEW);
        return done(parseConstructorInvocation(false));
      }

      case CONST: {
        beginConstExpression();
        consume(Token.CONST);

        DartExpression literal = tryParseTypedCompoundLiteral(true);
        if (literal != null) {
          return done(literal);
        }
        return done(parseConstructorInvocation(true));
      }

      case LPAREN: {
        beginParenthesizedExpression();
        consume(Token.LPAREN);
        beginExpression();
        // inside parens, function blocks are allowed again
        boolean save = setAllowFunctionExpression(true);
        DartExpression expression = done(parseExpression());
        setAllowFunctionExpression(save);
        expectCloseParen();
        return done(new DartParenthesizedExpression(expression));
      }

      case LT: {
        beginLiteral();
        DartExpression literal = tryParseTypedCompoundLiteral(false);
        if (literal == null) {
          reportError(position(), ParserErrorCode.EXPECTED_ARRAY_OR_MAP_LITERAL);
        }
        return done(literal);
      }

      case STRING:
      case STRING_SEGMENT:
      case STRING_EMBED_EXP_START: {
        return parseStringWithPasting();
      }

      case STRING_LAST_SEGMENT:
        throw new StringInterpolationParseError();

      case CONDITIONAL:
        return parseArgumentDefinitionTest();

      default: {
        return parseLiteral();
      }
    }
  }

  private DartExpression parseArgumentDefinitionTest() {
    beginArgumentDefinitionTest();
    int operatorOffset = position();
    expect(Token.CONDITIONAL);
    return done(new DartUnaryExpression(Token.CONDITIONAL, operatorOffset, parseIdentifier(), true));
  }

  private DartExpression parseConstructorInvocation(boolean isConst) {
    List<DartTypeNode> parts = new ArrayList<DartTypeNode>();
    beginConstructor();
    do {
      beginConstructorNamePart();
      parts.add(done(new DartTypeNode(parseIdentifier(), parseTypeArgumentsOpt())));
    } while (optional(Token.PERIOD));
    assert parts.size() > 0;

    DartNode constructor;
    switch (parts.size()) {
      case 1:
        constructor = doneWithoutConsuming(parts.get(0));
        break;

      case 2: {
        // This case is ambiguous. It can either be prefix.Type or
        // Type.namedConstructor.
        boolean hasPrefix = false;
        DartTypeNode part1 = parts.get(0);
        DartTypeNode part2 = parts.get(1);
        if (prefixes.contains(((DartIdentifier) part1.getIdentifier()).getName())) {
          hasPrefix = true;
        }
        if (!part2.getTypeArguments().isEmpty()) {
          // If the second part has type arguments, the first part must be a prefix.
          // If it isn't a prefix, the resolver will complain.
          hasPrefix = true;
        }
        if (hasPrefix) {
          constructor = doneWithoutConsuming(toPrefixedType(parts));
        } else {
          // Named constructor.
          DartIdentifier identifier = (DartIdentifier)part2.getIdentifier();
          constructor = doneWithoutConsuming(new DartPropertyAccess(doneWithoutConsuming(part1),
                                                                    identifier));
        }
        break;
      }
      default: {
        // This case is unambiguous. It must be prefix.Type.namedConstructor.
        if (parts.size() > 3) {
          reportError(parts.get(3), ParserErrorCode.EXPECTED_LEFT_PAREN);
        }
        DartTypeNode typeNode = doneWithoutConsuming(toPrefixedType(parts));
        DartIdentifier identifier = (DartIdentifier)parts.get(2).getIdentifier();
        constructor = doneWithoutConsuming(new DartPropertyAccess(typeNode, identifier));
        break;
      }
    }

    boolean save = setAllowFunctionExpression(true);
    try {
      List<DartExpression> args = parseArguments();
      return done(new DartNewExpression(constructor, args, isConst));
    } finally {
      setAllowFunctionExpression(save);
    }
  }

  private DartTypeNode toPrefixedType(List<DartTypeNode> parts) {
    DartIdentifier part1 = (DartIdentifier)parts.get(0).getIdentifier();
    DartTypeNode part2 = parts.get(1);
    DartIdentifier identifier = (DartIdentifier) part2.getIdentifier();
    DartPropertyAccess access = doneWithoutConsuming(new DartPropertyAccess(part1, identifier));
    return new DartTypeNode(access, part2.getTypeArguments());
  }

  /**
   * Parse a selector expression.
   *
   * <pre>
   * selector
   *    : assignableSelector
   *    | arguments
   *    ;
   * </pre>
   *
   * @return an expression matching the {@code selector} production above
   */
  private DartExpression parseSelectorExpression(DartExpression receiver) {
    DartExpression expression = tryParseAssignableSelector(receiver);
    if (expression != null) {
      return expression;
    }

    if (peek(0) == Token.LPAREN) {
      beginSelectorExpression();
      boolean save = setAllowFunctionExpression(true);
      List<DartExpression> args = parseArguments();
      setAllowFunctionExpression(save);
      if (receiver instanceof DartIdentifier) {
        return(done(new DartUnqualifiedInvocation((DartIdentifier) receiver, args)));
      } else {
        return(done(new DartFunctionObjectInvocation(receiver, args)));
      }
    }

    return receiver;
  }

  /**
   * <pre>
   * assignableSelector
   *    : '[' expression ']'
   *    | '.' identifier
   *    ;
   * </pre>
   */
  private DartExpression tryParseAssignableSelector(DartExpression receiver) {
    switch (peek(0)) {
      case PERIOD:
        consume(Token.PERIOD);
        switch (peek(0)) {
          case SEMICOLON:
          case RBRACE:
            reportError(position(), ParserErrorCode.EXPECTED_IDENTIFIER);
            DartIdentifier error = doneWithoutConsuming(new DartIdentifier(""));
            return doneWithoutConsuming(new DartPropertyAccess(receiver, error));
        }
        DartIdentifier name = parseIdentifier();
        if (peek(0) == Token.LPAREN) {
          boolean save = setAllowFunctionExpression(true);
          DartMethodInvocation expr = doneWithoutConsuming(new DartMethodInvocation(receiver, false,
              name, parseArguments()));
          setAllowFunctionExpression(save);
          return expr;
        } else {
          return doneWithoutConsuming(new DartPropertyAccess(receiver, name));
        }

      case LBRACK:
        consume(Token.LBRACK);
        DartExpression key = parseExpression();
        expect(Token.RBRACK);
        return doneWithoutConsuming(new DartArrayAccess(receiver, key));

      default:
        return null;
    }
  }

  /**
   * <pre>
   * block
   *     : '{' statements deadCode* '}'
   *     ;
   *
   * statements
   *     : statement*
   *     ;
   *
   * deadCode
   *     : (normalCompletingStatement | abruptCompletingStatement)
   *     ;
   * </pre>
   */
  @Terminals(tokens={Token.RBRACE})
  private DartBlock parseBlock() {
    if (isDietParse) {
      expect(Token.LBRACE);
      DartBlock emptyBlock = new DartBlock(new ArrayList<DartStatement>());
      int nesting = 1;
      while (nesting > 0) {
        Token token = next();
        switch (token) {
          case LBRACE:
            ++nesting;
            break;
          case RBRACE:
            --nesting;
            break;
          case EOS:
            return emptyBlock;
        }
      }
      // Return an empty block so we don't generate unparseable code.
      return emptyBlock;
    } else {
      Token nextToken = peek(0);
      if (!nextToken.equals(Token.LBRACE)
          && (looksLikeTopLevelKeyword() || nextToken.equals(Token.RBRACE))) {
        beginBlock();
        // Allow recovery back to the top level.
        reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
        return done(new DartBlock(new ArrayList<DartStatement>()));
      }
      beginBlock();
      List<DartStatement> statements = new ArrayList<DartStatement>();
      boolean foundOpenBrace = expect(Token.LBRACE);

      while (!match(Token.RBRACE) && !EOS()) {
        if (looksLikeTopLevelKeyword()) {
          reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
          break;
        }
        int startPosition = position();
        DartStatement newStatement = parseStatement();
        if (newStatement == null) {
          break;
        }
        if (startPosition == position()) {
          // The parser is not making progress.
          Set<Token> terminals = this.collectTerminalAnnotations();
          if (terminals.contains(peek(0))) {
            // bail out of the block
            break;
          }
          reportUnexpectedToken(position(), null, next());
        }
        statements.add(newStatement);
      }
      expectCloseBrace(foundOpenBrace);
      return done(new DartBlock(statements));
    }
  }

  /**
   * Parse a function statement body.
   *
   * <pre>
   * functionStatementBody
   *    : '=>' expression ';'
   *    | block
   * </pre>
   *
   * @param requireSemicolonForArrow true if a semicolon is required after an arrow expression
   * @return {@link DartBlock} instance containing function body
   */
  private DartBlock parseFunctionStatementBody(boolean allowBody, boolean requireSemicolonForArrow) {
    // A break inside a function body should have nothing to do with a loop in
    // the code surrounding the definition.
    boolean oldInLoopStatement = inLoopStatement;
    boolean oldInCaseStatement = inCaseStatement;
    inLoopStatement = inCaseStatement = false;
    try {
      DartBlock result;
      if (isDietParse) {
        result = dietParseFunctionStatementBody();
      } else {
        beginFunctionStatementBody();
        if (optional(Token.SEMICOLON)) {
          if (allowBody) {
            reportError(position(), ParserErrorCode.EXPECTED_FUNCTION_STATEMENT_BODY);
          }
          result = done(null);
        } else if (optional(Token.ARROW)) {
          DartExpression expr = parseExpression();
          if (expr == null) {
            expr = new DartSyntheticErrorExpression();
          }
          if (requireSemicolonForArrow) {
            expect(Token.SEMICOLON);
          }
          result = done(makeReturnBlock(expr));
        } else {
          result = done(parseBlock());
        }
      }
      if (!allowBody && result != null) {
        reportError(result, ParserErrorCode.EXTERNAL_METHOD_BODY);
      }
      return result;
    } finally {
      inLoopStatement = oldInLoopStatement;
      inCaseStatement = oldInCaseStatement;
    }
  }

  private DartBlock dietParseFunctionStatementBody() {
    DartBlock emptyBlock = new DartBlock(new ArrayList<DartStatement>());
    if (optional(Token.ARROW)) {
      while (true) {
        Token token = next();
        if (token == Token.SEMICOLON) {
          break;
        }
      }
    } else {
      if (!peek(0).equals(Token.LBRACE) && looksLikeTopLevelKeyword()) {
        // Allow recovery back to the top level.
        reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
        return done(emptyBlock);
      }
      expect(Token.LBRACE);
      int nesting = 1;
      while (nesting > 0) {
        Token token = next();
        switch (token) {
          case LBRACE:
            ++nesting;
            break;
          case RBRACE:
            --nesting;
            break;
          case EOS:
            return emptyBlock;
        }
      }
    }
    // Return an empty block so we don't generate unparseable code.
    return emptyBlock;
  }

  /**
   * Create a block containing a single return statement.
   *
   * @param returnVal return value expression
   * @return block containing a single return statement
   */
  private DartBlock makeReturnBlock(DartExpression returnVal) {
    return new DartReturnBlock(returnVal);
  }

  /**
   * <pre>
   * initializedVariableDeclaration
   *     : constVarOrType initializedIdentifierList
   *     ;
   *
   * initializedIdentifierList
   *     : initializedIdentifier (',' initializedIdentifier)*
   *     ;
   *
   * initializedIdentifier
   *     : IDENTIFIER ('=' assignmentExpression)?
   *     ;
   *  </pre>
   */
  private List<DartVariable> parseInitializedVariableList() {
    List<DartVariable> idents = new ArrayList<DartVariable>();
    do {
      beginVariableDeclaration();
      List<DartAnnotation> metadata = parseMetadata();
      DartIdentifier name = parseIdentifier();
      DartExpression value = null;
      if (isParsingInterface) {
        expect(Token.ASSIGN);
        value = parseExpression();
      } else if (optional(Token.ASSIGN)) {
        value = parseExpression();
      }
      DartVariable variable = done(new DartVariable(name, value));
      setMetadata(variable, metadata);
      idents.add(variable);
    } while (optional(Token.COMMA));

    return idents;
  }

  private DartAssertStatement parseAssertStatement() {
    beginAssertStatement();
    expect(Token.ASSERT);
    expect(Token.LPAREN);
    DartExpression condition = parseExpression();
    expectCloseParen();
    expectStatmentTerminator();
    return done(new DartAssertStatement(condition));
  }

  /**
   * <pre>
   * abruptCompletingStatement
   *     : BREAK identifier? ';'
   *     | CONTINUE identifier? ';'
   *     | RETURN expression? ';'
   *     | THROW expression? ';'
   *     ;
   *  </pre>
   */
  private DartBreakStatement parseBreakStatement() {
    beginBreakStatement();
    expect(Token.BREAK);
    DartIdentifier label = null;
    if (match(Token.IDENTIFIER)) {
      label = parseIdentifier();
    } else if (!inLoopStatement && !inCaseStatement) {
      // The validation of matching of labels to break statements is done later.
      reportErrorWithoutAdvancing(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP);
    }
    expectStatmentTerminator();
    return done(new DartBreakStatement(label));
  }

  private DartContinueStatement parseContinueStatement() {
    beginContinueStatement();
    expect(Token.CONTINUE);
    DartIdentifier label = null;
    if (!inLoopStatement && !inCaseStatement) {
      reportErrorWithoutAdvancing(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP);
    }
    if (peek(0) == Token.IDENTIFIER) {
      label = parseIdentifier();
    } else if (!inLoopStatement && inCaseStatement) {
      reportErrorWithoutAdvancing(ParserErrorCode.CONTINUE_IN_CASE_MUST_HAVE_LABEL);
    }
    expectStatmentTerminator();
    return done(new DartContinueStatement(label));
  }

  private DartReturnStatement parseReturnStatement() {
    beginReturnStatement();
    expect(Token.RETURN);
    DartExpression value = null;
    if (peek(0) != Token.SEMICOLON) {
      value = parseExpression();
    }
    expectStatmentTerminator();
    return done(new DartReturnStatement(value));
  }

  private DartThrowExpression parseThrowExpression(boolean allowCascade) {
    beginThrowExpression();
    expect(Token.THROW);
    DartExpression exception = null;
    if (peek(0) != Token.SEMICOLON && peek(0) != Token.RPAREN) {
      if (allowCascade) {
        exception = parseExpression();
      } else {
        exception = parseExpressionWithoutCascade();
      }
    }
    return done(new DartThrowExpression(exception));
  }

  /**
   * <pre>
   * statement
   *     : label* nonLabelledStatement
   *     ;
   *
   * label
   *     : identifier ':'
   *     ;
   * </pre>
   *
   * @return a {@link DartStatement}
   */
  @VisibleForTesting
  public DartStatement parseStatement() {
    List<DartIdentifier> labels = new ArrayList<DartIdentifier>();
    while (peek(0) == Token.IDENTIFIER && peek(1) == Token.COLON) {
      beginLabel();
      labels.add(parseIdentifier());
      expect(Token.COLON);
    }
    List<DartAnnotation> metadata = parseMetadata();
    DartStatement statement = parseNonLabelledStatement();
    if (!metadata.isEmpty() && statement instanceof DartVariableStatement) {
      DartVariableStatement variableStatement = (DartVariableStatement) statement;
      if (!variableStatement.getVariables().isEmpty()) {
        setMetadata(variableStatement.getVariables().get(0), metadata);
      }
    }
    for (int i = labels.size() - 1; i >= 0; i--) {
      statement = done(new DartLabel(labels.get(i), statement));
    }
    return statement;
  }

  private boolean isFunctionExpression(DartStatement statement) {
    if (!(statement instanceof DartExprStmt)) {
      return false;
    }
    DartExpression expression = ((DartExprStmt) statement).getExpression();
    if (!(expression instanceof DartFunctionExpression)) {
      return false;
    }
    return ((DartFunctionExpression) expression).getName() == null;
  }

  /**
   * <pre>
   * normalCompletingStatement
   *     : functionStatement
   *     | initializedVariableDeclaration ';'
   *     | simpleStatement
   *     ;
   *
   * functionStatement
   *     : typeOrFunction identifier formalParameterList block
   *     ;
   *     ;
   *
   * simpleStatement
   *     : ('{')=> block // Guard to break tie with map literal.
   *     | expression? ';'
   *     | tryStatement
   *     | ASSERT '(' conditionalExpression ')' ';'
   *     | abruptCompletingStatement
   *     ;
   * </pre>
   */
  // TODO(zundel):  Possibly  we could use Token.IDENTIFIER too, but it is used
  // in so many places, it might make recovery worse rather than better.
  @Terminals(tokens={Token.IF, Token.SWITCH, Token.WHILE, Token.DO, Token.FOR,
      Token.VAR, Token.FINAL, Token.CONTINUE, Token.BREAK, Token.RETURN, Token.THROW,
      Token.TRY, Token.SEMICOLON })
  private DartStatement parseNonLabelledStatement() {
    // Try to parse as function declaration.
    if (looksLikeFunctionDeclarationOrExpression()) {
      ctx.begin();
      DartStatement functionDeclaration = parseFunctionDeclaration();
      // If "null", then we tried to parse, but found that this is not function declaration.
      // So, parsing was rolled back and we can try to parse it as expression.
      if (functionDeclaration != null) {
        if (!isFunctionExpression(functionDeclaration)) {
          ctx.done(null);
          return functionDeclaration;
        }
        ctx.rollback();
      } else {
        ctx.done(null);
      }
    }
    // Check possible statement kind.
    switch (peek(0)) {
      case ASSERT:
        return parseAssertStatement();

      case IF:
        return parseIfStatement();
        
      case SWITCH:
        return parseSwitchStatement();

      case WHILE:
        return parseWhileStatement();

      case DO:
        return parseDoWhileStatement();

      case FOR:
        return parseForStatement();

      case VAR: {
        beginVarDeclaration();
        consume(Token.VAR);
        List<DartVariable> vars = parseInitializedVariableList();
        expectStatmentTerminator();
        return done(new DartVariableStatement(vars, null));
      }

      case FINAL: {
        beginFinalDeclaration();
        consume(peek(0));
        DartTypeNode type = null;
        if (peek(1) == Token.IDENTIFIER || peek(1) == Token.LT || peek(1) == Token.PERIOD) {
          // We know we have a type.
          type = parseTypeAnnotation();
        }
        List<DartVariable> vars = parseInitializedVariableList();
        expectStatmentTerminator();
        return done(new DartVariableStatement(vars, type, Modifiers.NONE.makeFinal()));
      }

      case LBRACE:
        Token token = peek(1);
        if (token == Token.STRING || token == Token.STRING_SEGMENT || token == Token.STRING_EMBED_EXP_START) {
          int offset = skipStringLiteral(1);
          if (peek(offset) == Token.COLON) {
            return parseExpressionStatement();
          }
        }
        return parseBlock();

      case CONTINUE:
        return parseContinueStatement();

      case BREAK:
        return parseBreakStatement();

      case RETURN:
        return parseReturnStatement();

      case THROW:
       return parseExpressionStatement();

      case TRY:
        return parseTryStatement();

      case SEMICOLON:
        beginEmptyStatement();
        consume(Token.SEMICOLON);
        return done(new DartEmptyStatement());

      case CONST:
        // Check to see whether this is a variable declaration. If not, then default to parsing an
        // expression statement.
        int offset = skipTypeName(1);
        if (offset > 1 && (peek(offset) == Token.IDENTIFIER || (offset == 2
            && (peek(offset) == Token.ASSIGN || peek(offset) == Token.COMMA || peek(offset) == Token.SEMICOLON)))) {
          boolean hasType = peek(offset) == Token.IDENTIFIER;
          beginVariableDeclaration();
          next();
          DartTypeNode type = null;
          if (hasType) {
            type = parseTypeAnnotation();
          }
          List<DartVariable> vars = parseInitializedVariableList();
          expect(Token.SEMICOLON);
          return done(new DartVariableStatement(vars, type, Modifiers.NONE.makeConstant().makeFinal()));
        }
        break;

      case AS:
      case IDENTIFIER:
        // We have already eliminated function declarations earlier, so check for:
        // a) variable declarations;
        // b) beginning of function literal invocation.
        if (peek(1) == Token.LT || peek(1) == Token.IDENTIFIER
            || (peek(1) == Token.PERIOD && peek(2) == Token.IDENTIFIER)) {
          beginTypeFunctionOrVariable();
          DartTypeNode type = tryTypeAnnotation();
          if (type != null && peek(0) == Token.IDENTIFIER) {
            List<DartVariable> vars = parseInitializedVariableList();
            if (optional(Token.SEMICOLON)) {
              return done(new DartVariableStatement(vars, type));
            } else if (peek(0) == Token.LPAREN) {
              // Probably a function object invocation.
              rollback();
            } else {
              //reportError(position(), ParserErrorCode.EXPECTED_SEMICOLON);
              expectStatmentTerminator();
              return done(new DartVariableStatement(vars, type));
            }
          } else {
            rollback();
          }
        }
        break;
    }
    return parseExpressionStatement();
  }

  /**
   * Check if succeeding tokens look like a function declaration - the parser state is unchanged
   * upon return.
   *
   * See {@link #parseFunctionDeclaration()}.
   *
   * @return true if the following tokens should be parsed as a function definition
   */
  private boolean looksLikeFunctionDeclarationOrExpression() {
    beginMethodName();
    try {
      optionalPseudoKeyword(STATIC_KEYWORD);
      if (peek(0) == Token.IDENTIFIER && peek(1) == Token.LPAREN) {
        // just a name, no return type
        consume(Token.IDENTIFIER);
      } else if (isReturnType()) {
        if (!optional(Token.IDENTIFIER)) {
          // return types must be followed by a function name
          return false;
        }
      }
      // start of parameter list
      if (!optional(Token.LPAREN)) {
        return false;
      }
      // find matching parenthesis
      int count = 1;
      while (count != 0) {
        switch (next()) {
          case EOS:
            return false;
          case LPAREN:
            count++;
            break;
          case RPAREN:
            count--;
            break;
        }
      }
      return (peek(0) == Token.ARROW || peek(0) == Token.LBRACE);
    } finally {
      rollback();
    }
  }

  /**
   * Parse a function declaration.
   *
   * <pre>
   * nonLabelledStatement : ...
   *     | functionDeclaration functionBody
   *
   * functionDeclaration
   *    : FUNCTION identifier formalParameterList
   *      { legacy($start, "deprecated 'function' keyword"); }
   *    | returnType error=FUNCTION identifier? formalParameterList
   *      { legacy($error, "deprecated 'function' keyword"); }
   *    | returnType? identifier formalParameterList
   *    ;
   * </pre>
   *
   * @return a {@link DartStatement} representing the function declaration or <code>null</code> if
   *         code ends with function invocation, so this is not function declaration.
   */
  private DartStatement parseFunctionDeclaration() {
    beginFunctionDeclaration();
    DartIdentifier[] namePtr = new DartIdentifier[1];
    DartFunction function = parseFunctionDeclarationOrExpression(namePtr, true);
    if (function.getBody() instanceof DartReturnBlock || peek(0) != Token.LPAREN) {
      return done(new DartExprStmt(doneWithoutConsuming(new DartFunctionExpression(namePtr[0],
          doneWithoutConsuming(function),
          true))));
    } else {
      rollback();
      return null;
    }
  }

  private DartStatement parseExpressionStatement() {
    beginExpressionStatement();
    DartExpression expression = parseExpression();
    expectStatmentTerminator();

    return done(new DartExprStmt(expression));
  }

  /**
   * Expect a close paren, reporting an error and consuming tokens until a
   * plausible continuation is found if it isn't present.
   */
  private void expectCloseParen() {
    int parenCount = 1;
    Token nextToken = peek(0);
    switch (nextToken) {
      case RPAREN:
        expect(Token.RPAREN);
        return;

      case EOS:
      case LBRACE:
      case SEMICOLON:
        reportError(position(), ParserErrorCode.EXPECTED_TOKEN, Token.RPAREN.getSyntax(),
            nextToken.getSyntax());
        return;

      case LPAREN:
        ++parenCount;
        //$FALL-THROUGH$
      default:
        reportError(position(), ParserErrorCode.EXPECTED_TOKEN, Token.RPAREN.getSyntax(),
            nextToken.getSyntax());
        Set<Token> terminals = this.collectTerminalAnnotations();
        if (terminals.contains(nextToken) || looksLikeTopLevelKeyword()) {
          return;
        }
        break;
    }

    // eat tokens until we get a close paren or a plausible terminator (which
    // is not consumed)
    while (parenCount > 0) {
      switch (peek(0)) {
        case RPAREN:
          expect(Token.RPAREN);
          --parenCount;
          break;

        case LPAREN:
          expect(Token.LPAREN);
          ++parenCount;
          break;

        case EOS:
          reportErrorWithoutAdvancing(ParserErrorCode.UNEXPECTED_TOKEN);
          return;

        case LBRACE:
        case SEMICOLON:
          return;

        default:
          next();
          break;
      }
    }
  }

  /**
   * Expect a close brace, reporting an error and consuming tokens until a
   * plausible continuation is found if it isn't present.
   */
  private void expectCloseBrace(boolean foundOpenBrace) {
    // If a top level keyword is seen, bail out to recover.
    if (looksLikeTopLevelKeyword()) {
      reportUnexpectedToken(position(), Token.RBRACE, peek(0));
      return;
    }

    int braceCount = 0;
    if (foundOpenBrace) {
      braceCount++;
    }
    Token nextToken = peek(0);
    if (expect(Token.RBRACE)) {
      return;
    }
    if (nextToken == Token.LBRACE) {
      braceCount++;
    }

    // eat tokens until we get a matching close brace or end of stream
    while (braceCount > 0) {
      if (looksLikeTopLevelKeyword()) {
        return;
      }
      switch (next()) {
        case RBRACE:
          braceCount--;
          break;

        case LBRACE:
          braceCount++;
          break;

        case EOS:
          return;
      }
    }
  }

  /**
   * Collect plausible statement tokens and return a synthetic error statement
   * containing them.
   * <p>
   * Note that this is a crude heuristic that needs to be improved for better
   * error recovery.
   *
   * @return a {@link DartSyntheticErrorStatement}
   */
  private DartStatement parseErrorStatement() {
    StringBuilder buf = new StringBuilder();
    boolean done = false;
    int braceCount = 1;
    while (!done) {
      buf.append(getPeekTokenValue(0));
      next();
      switch (peek(0)) {
        case RBRACE:
          if (--braceCount == 0) {
            done = true;
          }
          break;
        case LBRACE:
          braceCount++;
          break;
        case EOS:
        case SEMICOLON:
          done = true;
          break;
      }
    }
    return new DartSyntheticErrorStatement(buf.toString());
  }


  /**
   * Look for a statement terminator, giving error messages and consuming tokens
   * for error recovery.
   */
  protected void expectStatmentTerminator() {
    Token token = peek(0);
    if (expect(Token.SEMICOLON)) {
      return;
    }
    Set<Token> terminals = collectTerminalAnnotations();
    assert(terminals.contains(Token.SEMICOLON));

    if (peek(0) == token) {
      reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_SEMICOLON);
    } else {
      reportError(position(), ParserErrorCode.EXPECTED_SEMICOLON);
      token = peek(0);
    }

    // Consume tokens until we see something that could terminate or start a new statement
    while (token != Token.SEMICOLON) {
      if (looksLikeTopLevelKeyword() || terminals.contains(token)) {
        return;
      }
      token = next();
    }
  }

  /**
   * Report an error without advancing past the next token.
   *
   * @param errCode the error code to report, which may take a string parameter
   *     containing the actual token found
   */
  private void reportErrorWithoutAdvancing(ErrorCode errCode) {
    startLookahead();
    Token actual = peek(0);
    next();
    reportError(position(), errCode, actual);
    rollback();
  }

  /**
   * <pre>
   * iterationStatement
   *     : WHILE '(' expression ')' statement
   *     | DO statement WHILE '(' expression ')' ';'
   *     | FOR '(' forLoopParts ')' statement
   *     ;
   *  </pre>
   */
  private DartWhileStatement parseWhileStatement() {
    beginWhileStatement();
    expect(Token.WHILE);
    expect(Token.LPAREN);
    DartExpression condition = parseExpression();
    expectCloseParen();
    int closeParenOffset = ctx.getTokenLocation().getBegin();
    DartStatement body = parseLoopStatement();
    return done(new DartWhileStatement(condition, closeParenOffset, body));
  }

  /**
   * <pre>
   * iterationStatement
   *     : WHILE '(' expression ')' statement
   *     | DO statement WHILE '(' expression ')' ';'
   *     | FOR '(' forLoopParts ')' statement
   *     ;
   *  </pre>
   */
  private DartDoWhileStatement parseDoWhileStatement() {
    beginDoStatement();
    expect(Token.DO);
    DartStatement body = parseLoopStatement();
    expect(Token.WHILE);
    expect(Token.LPAREN);
    DartExpression condition = parseExpression();
    expectCloseParen();
    expectStatmentTerminator();
    return done(new DartDoWhileStatement(condition, body));
  }

  /**
   * Use this wrapper to parse the body of a loop
   *
   * Sets up flag variables to make sure continue and break are properly
   * marked as errors when in wrong context.
   */
  private DartStatement parseLoopStatement() {
    boolean oldInLoop = inLoopStatement;
    inLoopStatement = true;
    try {
      return parseStatement();
    } finally {
      inLoopStatement = oldInLoop;
    }
  }

  /**
   * <pre>
   * iterationStatement
   *     : WHILE '(' expression ')' statement
   *     | DO statement WHILE '(' expression ')' ';'
   *     | FOR '(' forLoopParts ')' statement
   *     ;
   *
   * forLoopParts
   *     : forInitializerStatement expression? ';' expressionList?
   *     | constVarOrType? identifier IN expression
   *     ;
   *
   * forInitializerStatement
   *     : initializedVariableDeclaration ';'
   *     | expression? ';'
   *     ;
   * </pre>
   */
  private DartStatement parseForStatement() {
    beginForStatement();
    expect(Token.FOR);
    expect(Token.LPAREN);

    // Setup
    DartStatement setup = null;
    if (peek(0) != Token.SEMICOLON) {
      // Found a setup expression/statement
      beginForInitialization();
      Modifiers modifiers = Modifiers.NONE;
      if (optional(Token.VAR)) {
        setup = done(new DartVariableStatement(parseInitializedVariableList(), null, modifiers));
      } else {
        if (optional(Token.FINAL)) {
          modifiers = modifiers.makeFinal();
        }
        DartTypeNode type = (peek(1) == Token.IDENTIFIER || peek(1) == Token.LT || peek(1) == Token.PERIOD)
            ? tryTypeAnnotation() : null;
        if (modifiers.isFinal() || type != null) {
          setup = done(new DartVariableStatement(parseInitializedVariableList(), type, modifiers));
        } else {
          setup = done(new DartExprStmt(parseExpression()));
        }
      }
    }

    if (optional(Token.IN)) {
      if (setup instanceof DartVariableStatement) {
        DartVariableStatement variableStatement = (DartVariableStatement) setup;
        List<DartVariable> variables = variableStatement.getVariables();
        if (variables.size() != 1) {
          reportError(variables.get(1), ParserErrorCode.FOR_IN_WITH_MULTIPLE_VARIABLES);
        }
        DartExpression initializer = variables.get(0).getValue();
        if (initializer != null) {
          reportError(initializer, ParserErrorCode.FOR_IN_WITH_VARIABLE_INITIALIZER);
        }
      } else {
        DartExpression expression = ((DartExprStmt) setup).getExpression();
        if (!(expression instanceof DartIdentifier)) {
          reportError(setup, ParserErrorCode.FOR_IN_WITH_COMPLEX_VARIABLE);
        }
      }

      DartExpression iterable = parseExpression();
      expectCloseParen();
      int closeParenOffset = ctx.getTokenLocation().getBegin();

      DartStatement body = parseLoopStatement();
      return done(new DartForInStatement(setup, iterable, closeParenOffset, body));

    } else if (optional(Token.SEMICOLON)) {

      // Condition
      DartExpression condition = null;
      if (peek(0) != Token.SEMICOLON) {
        condition = parseExpression();
      }
      expect(Token.SEMICOLON);

      // Next
      DartExpression next = null;
      if (peek(0) != Token.RPAREN) {
        next = parseExpressionList();
      }
      expectCloseParen();
      int closeParenOffset = ctx.getTokenLocation().getBegin();

      DartStatement body = parseLoopStatement();
      return done(new DartForStatement(setup, condition, next, closeParenOffset, body));
    } else {
      reportUnexpectedToken(position(), null, peek(0));
      return done(parseErrorStatement());
    }
  }

  /**
   * <pre>
   * selectionStatement
   *    : IF '(' expression ')' statement ((ELSE)=> ELSE statement)?
   *    | SWITCH '(' expression ')' '{' switchCase* defaultCase? '}'
   *    ;
   * </pre>
   */
  private DartIfStatement parseIfStatement() {
    beginIfStatement();
    expect(Token.IF);
    expect(Token.LPAREN);
    DartExpression condition = parseExpression();
    expectCloseParen();
    int closeParenOffset = ctx.getTokenLocation().getBegin();
    DartStatement yes = parseStatement();
    DartStatement no = null;
    int elseTokenOffset = 0;
    if (optional(Token.ELSE)) {
      elseTokenOffset = ctx.getTokenLocation().getBegin();
      no = parseStatement();
    }
    return done(new DartIfStatement(condition, closeParenOffset, yes, elseTokenOffset, no));
  }

  /**
   * <pre>
   * caseStatements
   *    : normalCompletingStatement* abruptCompletingStatement
   *    ;
   * </pre>
   */
  private List<DartStatement> parseCaseStatements() {
    List<DartStatement> statements = new ArrayList<DartStatement>();
    DartStatement statement = null;
    boolean endOfCaseFound = false;
    boolean warnedUnreachable = false;
    while (true) {
      switch (peek(0)) {
        case CASE:
        case DEFAULT:
        case RBRACE:
        case EOS:
          return statements;
        case IDENTIFIER:
          // Handle consecutively labeled case statements
          if (isCaseOrDefault()) {
            return statements;
          }
        default:
          boolean oldInCaseStatement = inCaseStatement;
          inCaseStatement = true;
          try {
            if (endOfCaseFound && !warnedUnreachable) {
              reportErrorWithoutAdvancing(ParserErrorCode.UNREACHABLE_CODE_IN_CASE);
              warnedUnreachable = true;
            }
            statement = parseStatement();
          } finally {
            inCaseStatement = oldInCaseStatement;
          }
          if (statement == null) {
            return statements;
          }

          // Don't add unreachable code to the list of statements.
          if (!endOfCaseFound) {
            statements.add(statement);
            if (statement.isAbruptCompletingStatement()) {
              endOfCaseFound = true;
            }
          }
      }
    }
  }

  private boolean isCaseOrDefault() {
    int index = 0;
    while (peek(index) == Token.IDENTIFIER && peek(index + 1) == Token.COLON) {
      index += 2;
    }
    Token next = peek(index);
    return next == Token.CASE || next == Token.DEFAULT;
  }

  /**
   * <pre>
   * switchCase
   *    : label? (CASE expression ':')+ caseStatements
   *    ;
   * </pre>
   */
  private DartSwitchMember parseCaseMember(List<DartLabel> labels) {
    // The begin() associated with the done() in this method is in the method
    // parseSwitchStatement(), called by beginSwitchMember().
    expect(Token.CASE);
    DartExpression caseExpr = parseExpression();
    expect(Token.COLON);
    return done(new DartCase(caseExpr, labels, parseCaseStatements()));
  }

  /**
   * <pre>
   * defaultCase
   *    : label? (CASE expression ':')* DEFAULT ':' caseStatements
   *    ;
   * </pre>
   */
  private DartSwitchMember parseDefaultMember(List<DartLabel> labels) {
    // The begin() associated with the done() in this method is in the method
    // parseSwitchStatement(), called by beginSwitchMember().
    expect(Token.DEFAULT);
    expect(Token.COLON);
    return done(new DartDefault(labels, parseCaseStatements()));
  }


  /**
   * <pre>
   * selectionStatement
   *    : IF '(' expression ')' statement ((ELSE)=> ELSE statement)?
   *    | SWITCH '(' expression ')' '{' switchCase* defaultCase? '}'
   *    ;
   * </pre>
   */
  private DartStatement parseSwitchStatement() {
    beginSwitchStatement();
    expect(Token.SWITCH);

    expect(Token.LPAREN);
    DartExpression expr = parseExpression();
    expectCloseParen();

    List<DartSwitchMember> members = new ArrayList<DartSwitchMember>();
    boolean foundOpenBrace = expect(Token.LBRACE);

    boolean done = optional(Token.RBRACE);
    while (!done) {
      List<DartLabel> labels = new ArrayList<DartLabel>();
      beginSwitchMember(); // switch member
      while (peek(0) == Token.IDENTIFIER) {
        beginLabel();
        DartIdentifier identifier = parseIdentifier();
        expect(Token.COLON);
        labels.add(done(new DartLabel(identifier, null)));
        if (peek(0) == Token.RBRACE) {
          reportError(position(), ParserErrorCode.LABEL_NOT_FOLLOWED_BY_CASE_OR_DEFAULT);
          expectCloseBrace(foundOpenBrace);
          return done(new DartSwitchStatement(expr, members));
        }
      }
      if (peek(0) == Token.CASE) {
        members.add(parseCaseMember(labels));
      } else if (optional(Token.RBRACE)) {
        if (!labels.isEmpty()) {
          reportError(position(), ParserErrorCode.EXPECTED_CASE_OR_DEFAULT);
        }
        done = true;
        done(null);
      } else {
        if (peek(0) != Token.EOS) {
          members.add(parseDefaultMember(labels));
        }
        expectCloseBrace(foundOpenBrace);
        done = true; // Ensure termination.
      }
    }
    return done(new DartSwitchStatement(expr, members));
  }

  /**
   * <pre>
   * catchParameter
   *    : FINAL type? identifier
   *    | VAR identifier
   *    | type identifier
   *    ;
   *  </pre>
   */
  private DartParameter parseCatchParameter() {
    beginCatchParameter();
    List<DartAnnotation> metadata = parseMetadata();
    DartTypeNode type = null;
    Modifiers modifiers = Modifiers.NONE;
    boolean isDeclared = false;
    if (optional(Token.VAR)) {
      isDeclared = true;
    } else {
      if (optional(Token.FINAL)) {
        modifiers = modifiers.makeFinal();
        isDeclared = true;
      }
      if (peek(1) != Token.COMMA && peek(1) != Token.RPAREN) {
        type = parseTypeAnnotation();
        isDeclared = true;
      }
    }
    DartIdentifier name = parseIdentifier();
    if (!isDeclared) {
      reportError(name, ParserErrorCode.EXPECTED_VAR_FINAL_OR_TYPE);
    }
    DartParameter parameter = done(new DartParameter(name, type, null, null, modifiers));
    setMetadata(parameter, metadata);
    return parameter;
  }

  /**
   * Parse either the old try statement syntax:
   * <pre>
   * tryStatement
   *     : TRY block (catchPart+ finallyPart? | finallyPart)
   *     ;
   *
   * catchPart
   *     : CATCH '(' declaredIdentifier (',' declaredIdentifier)? ')' block
   *     ;
   *
   * finallyPart
   *     : FINALLY block
   *     ;
   * </pre>
   * or the new syntax:
   * <pre>
   * tryStatement
   *     : TRY block (onPart+ finallyPart? | finallyPart)
   *     ;
   *
   * onPart
   *     : catchPart block
   *     | ON qualified catchPart? block
   *
   * catchPart
   *     : CATCH '(' identifier (',' identifier)? ')'
   *     ;
   *
   * finallyPart
   *     : FINALLY block
   *     ;
   * </pre>
   */
  private DartTryStatement parseTryStatement() {
    beginTryStatement();
    // Try.
    expect(Token.TRY);
    // TODO(zundel): It would be nice here to setup 'ON', 'CATCH' and 'FINALLY' as tokens for recovery
    DartBlock tryBlock = parseBlock();

    List<DartCatchBlock> catches = new ArrayList<DartCatchBlock>();
    while (peekPseudoKeyword(0, ON_KEYWORD) || match(Token.CATCH)) {
      // TODO(zundel): It would be nice here to setup 'FINALLY' as token for recovery
      if (peekPseudoKeyword(0, ON_KEYWORD)) {
        beginCatchClause();
        next();
        DartTypeNode exceptionType = parseTypeAnnotation();
        DartParameter exception = null;
        DartParameter stackTrace = null;
        if (optional(Token.CATCH)) {
          expect(Token.LPAREN);
          beginCatchParameter();
          List<DartAnnotation> metadata = parseMetadata();
          DartIdentifier exceptionName = parseIdentifier();
          exception = done(new DartParameter(exceptionName, exceptionType, null, null, Modifiers.NONE));
          setMetadata(exception, metadata);
          if (optional(Token.COMMA)) {
            beginCatchParameter();
            DartIdentifier stackName = parseIdentifier();
            stackTrace = done(new DartParameter(stackName, null, null, null, Modifiers.NONE));
          }
          expectCloseParen();
        } else {
          // Create a dummy identifier that the user cannot reliably reference.
          beginCatchParameter();
          List<DartAnnotation> metadata = parseMetadata();
          beginIdentifier();
          DartIdentifier exceptionName = done(new DartIdentifier("e" + Long.toHexString(System.currentTimeMillis())));
          exception = done(new DartParameter(exceptionName, exceptionType, null, null, Modifiers.NONE));
          setMetadata(exception, metadata);
        }
        DartBlock block = parseBlock();
        catches.add(done(new DartCatchBlock(block, exception, stackTrace)));
      } else {
        beginCatchClause();
        next();
        expect(Token.LPAREN);
        DartParameter exception;
        if (match(Token.IDENTIFIER) && (peek(1) == Token.COMMA || peek(1) == Token.RPAREN)) {
          beginCatchParameter();
          List<DartAnnotation> metadata = parseMetadata();
          DartIdentifier exceptionName = parseIdentifier();
          exception = done(new DartParameter(exceptionName, null , null, null, Modifiers.NONE));
          setMetadata(exception, metadata);
        } else {
          // Old-style parameter
          reportError(position(), ParserErrorCode.DEPRECATED_CATCH);
          exception = parseCatchParameter();
        }
        DartParameter stackTrace = null;
        if (optional(Token.COMMA)) {
          if (match(Token.IDENTIFIER) && peek(1) == Token.RPAREN) {
            beginCatchParameter();
            List<DartAnnotation> metadata = parseMetadata();
            DartIdentifier stackName = parseIdentifier();
            stackTrace = done(new DartParameter(stackName, null, null, null, Modifiers.NONE));
            setMetadata(stackTrace, metadata);
          } else {
            // Old-style parameter
            reportError(position(), ParserErrorCode.DEPRECATED_CATCH);
            stackTrace = parseCatchParameter();
          }
        }
        expectCloseParen();
        DartBlock block = parseBlock();
        catches.add(done(new DartCatchBlock(block, exception, stackTrace)));
      }
    }

    // Finally.
    DartBlock finallyBlock = null;
    if (optional(Token.FINALLY)) {
      finallyBlock = parseBlock();
    }

    if ( catches.size() == 0 && finallyBlock == null) {
      reportError(new DartCompilationError(tryBlock.getSourceInfo().getSource(), new Location(position()),
        ParserErrorCode.CATCH_OR_FINALLY_EXPECTED));
    }

    return done(new DartTryStatement(tryBlock, catches, finallyBlock));
  }

  /**
   * <pre>
   * unaryExpression
   *     : postfixExpression
   *     | prefixOperator unaryExpression
   *     | incrementOperator assignableExpression
   *     ;
   *
   *  @return an expression or null if noFail is true and the next tokens could not be parsed as an
   *      expression, leaving the state unchanged.
   *  </pre>
   */
  private DartExpression parseUnaryExpression() {
    // There is no unary plus operator in Dart.
    // However, we allow a leading plus in decimal numeric literals.
    if (optional(Token.ADD)) {
      if (peek(0) != Token.INTEGER_LITERAL && peek(0) != Token.DOUBLE_LITERAL) {
        reportError(position(), ParserErrorCode.NO_UNARY_PLUS_OPERATOR);
      } else if (position() + 1 != peekTokenLocation(0).getBegin()) {
        reportError(position(), ParserErrorCode.NO_SPACE_AFTER_PLUS);
      }
    }
    // Check for unary minus operator.
    Token token = peek(0);
    if (token.isUnaryOperator() || token == Token.SUB) {
      if (token == Token.DEC && peek(1) == Token.SUPER) {
        beginUnaryExpression();
        beginUnaryExpression();
        consume(token);
        int tokenOffset = ctx.getTokenLocation().getBegin();
        DartExpression unary = parseUnaryExpression();
        DartUnaryExpression unary2 = new DartUnaryExpression(Token.SUB, tokenOffset, unary, true);
        return done(new DartUnaryExpression(Token.SUB, tokenOffset, done(unary2), true));
      } else {
        beginUnaryExpression();
        consume(token);
        int tokenOffset = ctx.getTokenLocation().getBegin();
        DartExpression unary = parseUnaryExpression();
        if (token.isCountOperator()) {
          ensureAssignable(unary);
        }
        return done(new DartUnaryExpression(token, tokenOffset, unary, true));
      }
    } else {
      return parsePostfixExpression();
    }
  }

  /**
   * <pre>
   * type
   *     : qualified typeArguments?
   *     ;
   * </pre>
   */
  private DartTypeNode parseTypeAnnotation() {
    beginTypeAnnotation();
    return done(new DartTypeNode(parseQualified(false), parseTypeArgumentsOpt()));
  }

  /**
   * <pre>
   * type
   *     : qualified typeArguments? ('.' identifier)?
   *     ;
   * </pre>
   */
  private DartTypeNode parseTypeAnnotationPossiblyFollowedByName() {
    beginTypeAnnotation();
    boolean canBeFollowedByPeriod = true;
    if (peek(Token.IDENTIFIER, Token.LT) || peek(Token.IDENTIFIER, Token.PERIOD, Token.IDENTIFIER, Token.LT)) {
      canBeFollowedByPeriod = false;
    }
    return done(new DartTypeNode(parseQualified(canBeFollowedByPeriod), parseTypeArgumentsOpt()));
  }

  private boolean peek(Token... tokens) {
    int index = 0;
    for (Token token : tokens) {
      if (peek(index++) != token) {
        return false;
      }
    }
    return true;
  }

  /**
   * <pre>
   * typeArguments
   *     : '<' typeList '>'
   *     ;
   *
   * typeList
   *     : type (',' type)*
   *     ;
   * </pre>
   */
  @Terminals(tokens={Token.GT, Token.COMMA})
  private List<DartTypeNode> parseTypeArguments() {
    consume(Token.LT);
    List<DartTypeNode> arguments = new ArrayList<DartTypeNode>();
    do {
      arguments.add(parseTypeAnnotation());
    } while (optional(Token.COMMA));
    if (!tryParameterizedTypeEnd()) {
      expect(Token.GT);
    }
    return arguments;
  }

  /**
   * <pre>
   * typeArguments?
   * </pre>
   */
  private List<DartTypeNode> parseTypeArgumentsOpt() {
    return (peek(0) == Token.LT)
        ? parseTypeArguments()
        : Collections.<DartTypeNode>emptyList();
  }

  /**
   * <pre>
   * qualified
   *     : identifier ('.' identifier)?
   *     ;
   * </pre>
   */
  private DartExpression parseQualified(boolean canBeFollowedByPeriod) {
    beginQualifiedIdentifier();
    DartIdentifier identifier = parseIdentifier();
    if (!prefixes.contains(identifier.getName())) {
      if (canBeFollowedByPeriod && !(peek(0) == Token.PERIOD && peek(1) == Token.IDENTIFIER && peek(2) == Token.PERIOD)) {
        return done(identifier);
      }
    }
    DartExpression qualified = identifier;
    if (optional(Token.PERIOD)) {
      // The previous identifier was a prefix.
      qualified = new DartPropertyAccess(qualified, parseIdentifier());
    }
    return done(qualified);
  }

  private boolean tryParameterizedTypeEnd() {
    switch (peek(0)) {
      case GT:
        consume(Token.GT);
        return true;
      case SAR:
        setPeek(0, Token.GT);
        return true;
      default:
        return false;
    }
  }

  private DartTypeNode tryTypeAnnotation() {
    if (peek(0) != Token.IDENTIFIER && peek(0) != Token.AS) {
      return null;
    }
    List<DartTypeNode> typeArguments = new ArrayList<DartTypeNode>();
    beginTypeAnnotation(); // to allow roll-back in case we're not at a type

    DartNode qualified = parseQualified(false);

    if (optional(Token.LT)) {
      if (peek(0) != Token.IDENTIFIER && peek(0) != Token.AS) {
        rollback();
        return null;
      }
      beginTypeArguments();
      DartNode qualified2 = parseQualified(false);
      DartTypeNode argument;
      switch (peek(0)) {
        case LT:
          // qualified < qualified2 <
          argument = done(new DartTypeNode(qualified2, parseTypeArguments()));
          break;

        case GT:
        case SAR:
          // qualified < qualified2 >
        case COMMA:
          // qualified < qualified2 ,
          argument = done(new DartTypeNode(qualified2, Collections.<DartTypeNode>emptyList()));
          break;

        default:
          done(null);
          rollback();
          return null;
      }
      typeArguments.add(argument);

      while (optional(Token.COMMA)) {
        typeArguments.add(parseTypeAnnotation());
      }
      if (!tryParameterizedTypeEnd()) {
        expect(Token.GT);
      }
    }

    return done(new DartTypeNode(qualified, typeArguments));
  }

  private DartIdentifier parseIdentifier() {
    beginIdentifier();
    if (peek(0) == Token.AS) {
      next();
      return done(new DartIdentifier("as"));
    }
    if (looksLikeTopLevelKeyword()) {
      reportErrorWithoutAdvancing(ParserErrorCode.EXPECTED_IDENTIFIER);
      return done(new DartSyntheticErrorIdentifier());
    }
    DartIdentifier identifier;
    if (expect(Token.IDENTIFIER) && ctx.getTokenString() != null) {
      identifier = new DartIdentifier(new String(ctx.getTokenString()));
    } else {
      identifier = new DartSyntheticErrorIdentifier();
    }
    return done(identifier);
  }

  public DartExpression parseEntryPoint() {
    beginEntryPoint();
    DartExpression entry = parseIdentifier();
    while (!EOS()) {
      expect(Token.PERIOD);
      entry = doneWithoutConsuming(new DartPropertyAccess(entry, parseIdentifier()));
    }
    return done(entry);
  }

  private void ensureAssignable(DartExpression expression) {
    if (expression != null && !expression.isAssignable()) {
      reportError(position(), ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE);
    }
  }

  /**
   * Increment the number of errors encountered while parsing this compilation unit. Returns whether
   * the current error should be reported.
   * 
   * @return whether the current error should be reported
   */
  private boolean incErrorCount() {
    errorCount++;
    
    if (errorCount >= MAX_DEFAULT_ERRORS) {
      if (errorCount == MAX_DEFAULT_ERRORS) {
        // Create a 'too many errors' error.
        DartCompilationError dartError = new DartCompilationError(ctx.getSource(),
            ctx.getTokenLocation(), ParserErrorCode.NO_SOUP_FOR_YOU);
        ctx.error(dartError);
      }
      
      // Consume the rest of the input stream. Throwing an exception - as suggested elsewhere in
      // this file - is not ideal.
      Token next = next();
      
      while (next != null && next != Token.EOS) {
        next = next();
      }
    }
    
    return errorCount < MAX_DEFAULT_ERRORS;
  }
  
  @Override
  protected void reportError(int position, ErrorCode errorCode, Object... arguments) {
    // TODO(devoncarew): we're not correctly identifying dart:html as a core library
    if (incErrorCount()) {
      super.reportError(position, errorCode, arguments);
    }
  }

  @Override
  protected void reportErrorAtPosition(int startPosition, int endPosition,
      ErrorCode errorCode, Object... arguments) {
    if (incErrorCount()) {
      super.reportErrorAtPosition(startPosition, endPosition, errorCode, arguments);
    }
  }

  private void reportError(DartCompilationError dartError) {
    if (incErrorCount()) {
      ctx.error(dartError);
      errorHistory.add(dartError.hashCode());
    }
  }

  private void reportError(DartNode node, ErrorCode errorCode, Object... arguments) {
    if (node != null) {
      reportError(new DartCompilationError(node, errorCode, arguments));
    }
  }

  private boolean currentlyParsingToplevel() {
    return   !(isParsingInterface || isTopLevelAbstract || isParsingClass);
  }
}
