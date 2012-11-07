// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import com.google.common.collect.Lists;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartComment;
import com.google.dart.compiler.ast.DartCommentNewName;
import com.google.dart.compiler.ast.DartCommentRefName;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.util.apache.StringUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * A parser for Dart that records comment positions.
 */
public class DartParserCommentsHelper {

  static class CommentParserContext extends DartScannerParserContext {

    private List<int[]> commentLocs;

    CommentParserContext(Source source, String code, DartCompilerListener listener,
        CompilerMetrics metrics) {
      super(source, code, listener, metrics);
    }

    List<int[]> getCommentLocs() {
      return commentLocs;
    }

    @Override
    protected DartScanner createScanner(String sourceCode, Source source,
        DartCompilerListener listener) {
      commentLocs = Lists.newArrayList();
      return new CommentScanner(sourceCode, 0, source, listener);
    }

    private class CommentScanner extends DartScanner {

      CommentScanner(String sourceCode, int start, Source sourceReference,
          DartCompilerListener listener) {
        super(sourceCode, start, sourceReference, listener);
      }

      @Override
      protected void recordCommentLocation(int start, int stop) {
        int size = commentLocs.size();
        if (size > 0) {
          // the parser may re-scan lookahead tokens
          // fortunately, comments are always scanned as comments
          int[] loc = commentLocs.get(size - 1);
          if (start <= loc[0] && stop <= loc[1]) {
            return;
          }
        }
        commentLocs.add(new int[] {start, stop});
      }
    }
  }

  static void addComments(DartUnit unit, Source source, String sourceCode, List<int[]> commentLocs) {
    for (int[] loc : commentLocs) {
      int start = loc[0];
      int length = loc[1] - start;
      DartComment.Style style = getCommentStyle(sourceCode, start);
      unit.getComments().add(new DartComment(source, start, length, style));
    }
    List<DartComment> comments = unit.getComments();
    if (comments != null) {
      assignDartComments(unit, sourceCode, comments);
    }
  }

  private static void assignDartComments(DartUnit unit, String sourceCode,
      List<DartComment> comments) {
    // Collect the AST nodes in a list.
    final List<DartNode> astNodes = new ArrayList<DartNode>();
    unit.accept(new ASTVisitor<DartNode>() {
      @Override
      public DartNode visitDeclaration(DartDeclaration<?> node) {
        astNodes.add(node);
        // Avoid NPE in visitors because of missing part. 
        try {
          super.visitDeclaration(node);
        } catch (NullPointerException e) {
        }
        // No result.
        return null;
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
        DartComment comment = (DartComment) node;
        // prepare next declaration
        DartDeclaration<?> decl = null;
        {
          int delta = 1;
          while (i + delta < nodes.size()) {
            DartNode next = nodes.get(i + delta);
            // skip all comments
            if (next instanceof DartComment) {
              delta++;
              continue;
            }
            // declaration found
            if (next instanceof DartDeclaration) {
              decl = (DartDeclaration<?>) next;
              if (!commentContainedBySibling(comment, decl)) {
                if (i + 2 < nodes.size()) {
                  decl = adjustDartdocTarget(next, nodes.get(i + 2));
                }
              }
              break;
            }
            // something other than declaration
            break;
          }
        }
        // apply comment to declaration
        if (decl != null) {
          String commentStr = sourceCode.substring(comment.getSourceInfo().getOffset(),
              comment.getSourceInfo().getEnd());
          tokenizeComment(comment, commentStr);
          // may be @Metadata
          if (commentStr.contains("@deprecated")) {
            decl.setObsoleteMetadata(decl.getObsoleteMetadata().makeDeprecated());
          }
          if (commentStr.contains("@override")) {
            decl.setObsoleteMetadata(decl.getObsoleteMetadata().makeOverride());
          }
          // DartDoc
          if (comment.isDartDoc()) {
            decl.setDartDoc(comment);
          }
        }
      }
    }
  }

  private static void tokenizeComment(DartComment comment, String src) {
    int lastIndex = 0;
    while (true) {
      int openIndex = src.indexOf('[', lastIndex);
      if (openIndex == -1) {
        break;
      }
      int closeIndex = src.indexOf(']', openIndex);
      if (closeIndex == -1) {
        break;
      }
      lastIndex = closeIndex;
      String tokenSrc = src.substring(openIndex + 1, closeIndex);
      if (tokenSrc.startsWith(":") && tokenSrc.endsWith(":")) {
        // TODO(scheglov) [:code:] and 'code'
      } else if (tokenSrc.startsWith("new ")) {
        SourceInfo sourceInfo = comment.getSourceInfo();
        int offset = sourceInfo.getOffset() + openIndex;
        int classOffset = offset + "[".length();
        // remove leading "new "
        String name = StringUtils.remove(tokenSrc, "new ");
        classOffset += "new ".length();
        // remove spaces
        {
          String stripName = StringUtils.stripStart(name, null);
          classOffset += name.length() - stripName.length();
          name = stripName;
        }
        name = name.trim();
        //
        String className = StringUtils.substringBefore(name, ".");
        String constructorName = StringUtils.substringAfter(name, ".");
        int constructorOffset = classOffset + className.length() + ".".length();
        DartCommentNewName newNode = new DartCommentNewName(className, classOffset,
            constructorName, constructorOffset);
        {
          Source source = sourceInfo.getSource();
          int length = tokenSrc.length() + "[]".length();
          newNode.setSourceInfo(new SourceInfo(source, offset, length));
        }
        // add node
        comment.addNewName(newNode);
      } else {
        String name = tokenSrc.trim();
        DartCommentRefName refNode = new DartCommentRefName(name);
        {
          SourceInfo sourceInfo = comment.getSourceInfo();
          Source source = sourceInfo.getSource();
          int offset = sourceInfo.getOffset() + openIndex;
          int length = name.length() + "[]".length();
          refNode.setSourceInfo(new SourceInfo(source, offset, length));
        }
        comment.addRefName(refNode);
      }
    }
  }

  private static DartDeclaration<?> adjustDartdocTarget(DartNode currentNode, DartNode nextNode) {
    if (currentNode instanceof DartField && nextNode instanceof DartMethodDefinition) {
      if (currentNode.getSourceInfo().equals(nextNode.getSourceInfo())) {
        return (DartDeclaration<?>) nextNode;
      }
    }

    return (DartDeclaration<?>) currentNode;
  }

  /**
   * DartC creates both a {@link DartField} and a {@link DartMethodDefinition} for getters and
   * setters. They have the same source location; we want to assign the DartDoc to the method
   * definition and not the field.
   */
  private static boolean commentContainedBySibling(DartComment comment, DartDeclaration<?> node) {
    if (node instanceof DartField) {
      for (DartNode child : getChildren(node.getParent())) {
        if (child != node && !(child instanceof DartComment)) {
          if (isContainedBy(comment, child)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  private static List<DartNode> getChildren(DartNode parent) {
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
    return nodeSource.getOffset() >= containedBySource.getOffset() && nodeEnd <= containedByEnd;
  }

  /**
   * Return the style of the comment in the given string.
   * 
   * @param sourceString the source containing the comment
   * @param commentStart the location of the comment in the source
   * @return the style of the comment in the given string
   */
  private static DartComment.Style getCommentStyle(String sourceString, int commentStart) {
    boolean hasMore1 = commentStart + 1 < sourceString.length();
    boolean hasMore2 = commentStart + 2 < sourceString.length();
    if (hasMore1 && sourceString.charAt(commentStart + 1) == '/') {
      return DartComment.Style.END_OF_LINE;
    } else if (hasMore2 && sourceString.charAt(commentStart + 2) == '*') {
      return DartComment.Style.DART_DOC;
    }
    return DartComment.Style.BLOCK;
  }
}
