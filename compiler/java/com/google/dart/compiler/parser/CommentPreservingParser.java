// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.util.DartSourceString;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * A parser for Dart that records comment positions.
 */
public class CommentPreservingParser extends DartParser {

  private static class CommentParserContext extends DartScannerParserContext {

    private List<int[]> commentLocs;
    private String source;

    CommentParserContext(Source source, String code,
        DartCompilerListener listener) {
      super(source, code, listener);
      this.source = code;
    }

    CommentParserContext(Source source, String code,
        DartCompilerListener listener, CompilerMetrics metrics) {
      super(source, code, listener, metrics);
      this.source = code;
    }

    List<int[]> getCommentLocs() {
      return commentLocs;
    }

    @Override
    protected DartScanner createScanner(String sourceCode) {
      commentLocs = new ArrayList<int[]>();
      return this.new CommentScanner(sourceCode);
    }

    private class CommentScanner extends DartScanner {

      CommentScanner(String sourceCode) {
        super(sourceCode);
      }

      @Override
      protected void recordCommentLocation(int start, int stop, int line, int col) {
        int size = commentLocs.size();
        if (size > 0) {
          // the parser may re-scan lookahead tokens
          // fortunately, comments are always scanned as comments
          int[] loc = commentLocs.get(size - 1);
          if (start <= loc[0] && stop <= loc[1]) {
            return;
          }
        }
        commentLocs.add(new int[]{start, stop, line, col});
      }
    }
  }

  /**
   * Create a parsing context for the comment-recording parser.
   */
  public static CommentParserContext createContext(Source source, String code,
      DartCompilerListener listener) {
    return new CommentParserContext(source, code, listener);
  }

  /**
   * Create a parsing context for the comment-recording parser.
   */
  public static CommentParserContext createContext(Source source, String code,
      DartCompilerListener listener, CompilerMetrics metrics) {
    return new CommentParserContext(source, code, listener, metrics);
  }

  private CommentParserContext context;
  private boolean onlyDartDoc;

  /**
   * Create a parser on the given <code>code</code> that records comment locations.
   */
  public CommentPreservingParser(String code) {
    this(code, null, false);
  }

  /**
   * Create a parser on the given <code>code</code> that records some comment
   * locations. If <code>onlyDartDoc</code> is <code>true</code> then only
   * DartDoc comments will be recorded, otherwise all comments will be recorded.
   * The given <code>listener</code> will be used to inform clients of errors.
   */
  public CommentPreservingParser(String code, DartCompilerListener listener,
      boolean onlyDartDoc) {
    this(createContext(null, code, listener), onlyDartDoc);
  }

  /**
   * Create a parser with the given parsing context <code>context</code>.
   * If <code>onlyDartDoc</code> is <code>true</code> then only
   * DartDoc comments will be recorded, otherwise all comments will be recorded.
   */
  public CommentPreservingParser(ParserContext context,
      boolean onlyDartDoc) {
    super(context, onlyDartDoc);
    this.context = (CommentParserContext) context;
    this.onlyDartDoc = onlyDartDoc;
  }

  @Override
  public DartUnit parseUnit(DartSource input) {
    DartUnit unit = super.parseUnit(input);

    String sourceString = context.source;
    Source source = new DartSourceString(null, sourceString);

    for (int[] loc : context.getCommentLocs()) {
      DartComment.Style style = getCommentStyle(sourceString, loc[0]);
      if (!onlyDartDoc || style == DartComment.Style.DART_DOC) {
        unit.getComments().add(new DartComment(source, loc[0], loc[1] - loc[0], loc[2], loc[3], style));
      }
    }

    List<DartComment> comments = unit.getComments();

    if (comments != null) {
      assignDartComments(unit, comments);
    }

    return unit;
  }

  private void assignDartComments(DartUnit unit, List<DartComment> comments) {
    // Collect the AST nodes in a list.
    final List<DartNode> astNodes = new ArrayList<DartNode>();
    unit.accept(new ASTVisitor<DartNode>() {
      @Override
      public DartNode visitDeclaration(DartDeclaration<?> node) {
        astNodes.add(node);
        return super.visitNode(node);
      }
    });

    // Collect all the nodes in one list.
    List<DartNode> nodes = new ArrayList<DartNode>();

    nodes.addAll(comments);
    nodes.addAll(astNodes);

    // Sort the nodes by their position in the source file.
    Collections.sort(nodes, new Comparator<DartNode>() {
      @Override
      public int compare(DartNode node1, DartNode node2) {
        return node1.getSourceInfo().getOffset() - node2.getSourceInfo().getOffset();
      }
    });

    // Assign dart docs to their associated DartDeclarations.
    for (int i = 0; i < nodes.size(); i++) {
      DartNode node = nodes.get(i);

      if (node instanceof DartComment) {
        DartComment comment = (DartComment)node;

        if (comment.isDartDoc() && (i + 1 < nodes.size())) {
          DartNode next = nodes.get(i + 1);

          if (next instanceof DartDeclaration) {
            DartDeclaration<?> decl = (DartDeclaration<?>)next;

            if (!commentContainedBySibling(comment, decl)) {
              // Dartc creates both a DartField and a DartMethodDefinition for getters and setters.
              // They have the same source location; we want to assign the dartdoc to the method
              // definition and not the field.
              if (i + 2 < nodes.size()) {
                decl = adjustDartdocTarget(next, nodes.get(i + 2));
              }
              
              decl.setDartDoc(comment);
            }
          }
        }
      }
    }
  }

  private DartDeclaration<?> adjustDartdocTarget(DartNode currentNode, DartNode nextNode) {
    if (currentNode instanceof DartField && nextNode instanceof DartMethodDefinition) {
      if (currentNode.getSourceInfo().equals(nextNode.getSourceInfo())) {
        return (DartDeclaration<?>)nextNode;
      }
    }
    
    return (DartDeclaration<?>)currentNode;
  }

  private boolean commentContainedBySibling(DartComment comment, DartDeclaration<?> node) {
    for (DartNode child : getChildren(node.getParent())) {
      if (child != node && !(child instanceof DartComment)) {
        if (isContainedBy(comment, child)) {
          return true;
        }
      }
    }

    return false;
  }

  private List<DartNode> getChildren(DartNode parent) {
    final List<DartNode> children = new ArrayList<DartNode>();

    parent.visitChildren(new ASTVisitor<DartNode>() {
      @Override
      public DartNode visitNode(DartNode node) {
        children.add(node);
        return null;
      }
    });

    return children;
  }

  private static boolean isContainedBy(DartNode node, DartNode containedByNode) {
    SourceInfo nodeSource = node.getSourceInfo();
    SourceInfo containedBySource = containedByNode.getSourceInfo();
    int nodeEnd = nodeSource.getOffset() + nodeSource.getLength();
    int containedByEnd = containedBySource.getOffset() + containedBySource.getLength();
    return nodeSource.getOffset() >= containedBySource.getOffset()
        && nodeEnd <= containedByEnd;
  }

  /**
   * Return the style of the comment in the given string.
   *
   * @param sourceString the source containing the comment
   * @param commentStart the location of the comment in the source
   *
   * @return the style of the comment in the given string
   */
  private DartComment.Style getCommentStyle(String sourceString, int commentStart) {
    if (sourceString.charAt(commentStart + 1) == '/') {
      return DartComment.Style.END_OF_LINE;
    } else if (sourceString.charAt(commentStart + 2) == '*') {
      return DartComment.Style.DART_DOC;
    }
    return DartComment.Style.BLOCK;
  }
}
