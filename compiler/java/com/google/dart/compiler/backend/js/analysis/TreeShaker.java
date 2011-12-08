// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js.analysis;

import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.LibrarySource;

import org.mozilla.javascript.EvaluatorException;
import org.mozilla.javascript.Parser;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.AstRoot;
import org.mozilla.javascript.ast.NodeVisitor;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * A JavaScript tree shaker that is specialized for the output produced by
 * dartc.
 */
public class TreeShaker {
  private static class VisitorIOException extends RuntimeException {
    public VisitorIOException(IOException e) {
      super(e);
    }

    @Override
    public IOException getCause() {
      return (IOException) super.getCause();
    }
  }

  private static final class OutputFileWriter implements NodeVisitor {
    private final Set<AstNode> nodesToEmit;
    private final Writer outputFile;
    private final Reader inputFile;
    private long lastReadPosition = 0;
    private long outputSize = 0;

    private OutputFileWriter(Set<AstNode> nodesToEmit, Writer outputFile, Reader inputFile) {
      this.nodesToEmit = nodesToEmit;
      this.outputFile = outputFile;
      this.inputFile = inputFile;
    }

    @Override
    public boolean visit(AstNode node) {
      if (node.getAstRoot() == node) {
        return true;
      }

      try {
        if (nodesToEmit.contains(node)) {
          int nodePosition = node.getAbsolutePosition();
          inputFile.skip(nodePosition - lastReadPosition);

          char[] buffer = new char[node.getLength()];
          int charsRead = inputFile.read(buffer);
          assert (charsRead == buffer.length);
          outputFile.write(buffer);
          outputFile.write("\n");
          outputSize += charsRead + 1;
          lastReadPosition = nodePosition + node.getLength();
        }
      } catch (IOException e) {
        throw new VisitorIOException(e);
      }

      return false;
    }

    public long getOutputSize() {
      return outputSize;
    }
  }

  private static final boolean DEBUG = false;

  /**
   * Returns the set of {@link AstNode}s that should be emitted into the final
   * JS code.
   */
  private static Set<AstNode> computeNodesToEmit(AstRoot root) {
    List<AstNode> globals = new ArrayList<AstNode>();
    Map<String, List<JavascriptElement>> namesToElements =
        new HashMap<String, List<JavascriptElement>>();
    TopLevelElementIndexer declVisitor = new TopLevelElementIndexer(namesToElements, globals);
    root.visit(declVisitor);

    if (DEBUG) {
      TopLevelElementIndexer.printNamesToElements(namesToElements);
      TopLevelElementIndexer.printGlobals(globals);
    }

    List<AstNode> worklist = new ArrayList<AstNode>();
    for (AstNode global : globals) {
      worklist.add(global);
    }

    worklist.addAll(declVisitor.getEntryPoints());
    DependencyComputer dependencyComputer = new DependencyComputer(namesToElements);
    final Set<AstNode> nodesProcessed = new LinkedHashSet<AstNode>();
    while (!worklist.isEmpty()) {
      AstNode node = worklist.remove(worklist.size() - 1);
      if (!nodesProcessed.add(node)) {
        continue;
      }

      if (DEBUG) {
        try {
          System.out.println(node.toSource());
          System.out.println("Dependencies:");
        } catch (Exception e) {
          // Ignore exceptions thrown by rhino's toSource method...
        }
      }

      List<JavascriptElement> dependencies = dependencyComputer.computeDependencies(node);
      for (JavascriptElement dependency : dependencies) {
        if (dependency.isNative() || nodesProcessed.contains(dependency.getNode())) {
          // Skip natives since they don't have a node in the AST
          continue;
        }

        if (DEBUG) {
          System.out.println("\t" + dependency.getQualifiedName());
        }

        worklist.add(dependency.getNode());
      }
    }
    return nodesProcessed;
  }

  /**
   * Reduce the input JS file by following the conservative "call graph" and
   * pruning dead code.
   */
  public static long reduce(LibrarySource app, DartCompilerContext context,
      String completeArtifactName, Writer outputFile) throws IOException {
    Reader inputFile = context.getArtifactReader(app, "", completeArtifactName);
    // Mark beyond the expected length so we can reset back to zero
    AstRoot root = null;
    boolean failed = true;
    try {
      Parser parser = new Parser();
      root = parser.parse(inputFile, "", 1);
      failed = false;
    } catch (EvaluatorException e) {
      /*
       * This can happen if we generate bad JS code. For example, the negative
       * tests may cause invalid control flow constructs to be generated. In
       * this case we will swallow the exception and simply copy the input file
       * to the output file.
       */
      Closeables.close(inputFile, failed);
      inputFile = context.getArtifactReader(app, "", completeArtifactName);
      return CharStreams.copy(inputFile, outputFile);
    } finally {
      Closeables.close(inputFile, failed);
    }

    final Set<AstNode> nodesProcessed = computeNodesToEmit(root);

    // Need to get a new reader since we don't cache the stream
    failed = true;
    inputFile = context.getArtifactReader(app, "", completeArtifactName);
    OutputFileWriter outputFileWriter =
        new OutputFileWriter(nodesProcessed, outputFile, inputFile);
    try {
      root.visit(outputFileWriter);
      failed = false;
      return outputFileWriter.getOutputSize();
    } catch (VisitorIOException e) {
      throw e.getCause();
    } finally {
      Closeables.close(inputFile, failed);
    }
  }
}
