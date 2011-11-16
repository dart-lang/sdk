// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import com.google.common.io.Closeables;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;

/**
 * Write the AST in Dot format. Output file is placed next to the JS file in the output directory
 */
public class DotWriter extends BaseASTWriter {

  private Map<DartNode, String> nodeMap;
  private FileWriter out;
  private StringBuffer edges, nodes;
  private DartUnit currentUnit;
  private Set<String> printDataNodes;
  private static final String[] dataLabels = {
      "DartIdentifier", "DartVariable", "DartField", "DartParameter", "DartClass",
      "DartMethodDefinition"};

  public DotWriter(String outputDir) {
    super(outputDir);
    printDataNodes = new HashSet<String>(Arrays.asList(dataLabels));
  }

  @Override
  protected void startHook(DartUnit unit) {
    String nodeData = String.format("%s", unit.getSourceName());
    nodeMap = new HashMap<DartNode, String>();
    nodeMap.put(unit, nodeData);
    edges = new StringBuffer();
    nodes = new StringBuffer();
    currentUnit = unit;
    if (!isIgnored(unit)) {
      String dotFilePath = outputDir + File.separator + unit.getSource().getUri() + ".ast.dot";
      makeParentDirs(dotFilePath);
      try {
        out = new FileWriter(new File(dotFilePath));
      } catch (IOException e) {
        e.printStackTrace();
      }
    }

  }

  @Override
  protected void endHook(DartUnit unit) {
    if (!isIgnored(unit)) {
      String dotGraph = "digraph G{\n" + nodes.toString() + edges.toString() + "}";
      try {
        out.append(dotGraph);
        Closeables.close(out, true);
      } catch (IOException e) {
        System.err.println("Error while writing AST to dot file");
        e.printStackTrace();
      }
    }
  }

  protected void write(String nodeType, DartNode node, String data) {
    String nodeData = node.getSourceLine() + ":" + node.getSourceStart() + ":"
        + node.getSourceLength() + "_" + nodeType;
    nodeMap.put(node, nodeData);
    DartNode parent = node.getParent();
    if (parent == null) {
      parent = currentUnit;
    }
    String styleAttr = getStyleAttr(nodeType, node);
    String label = getLabel(nodeType, node, data);
    nodes.append(String.format("\t\"%s\" [label=\"%s\"%s];\n", nodeData, label, styleAttr));
    edges.append(String.format("\t\"%s\" -> \"%s\";\n", nodeMap.get(parent), nodeData));
  }

  private String getLabel(String nodeType, DartNode node, String data) {
    StringBuffer label = new StringBuffer(nodeType);
    if (printDataNodes.contains(nodeType) || node instanceof DartExpression) {
      label.append(String.format("\\n%s", data.replaceAll("\"", "'")));
    }
    return label.toString();
  }

  private String getStyleAttr(String nodeType, DartNode node) {
    StringBuffer style = new StringBuffer();
    if (nodeType.endsWith("Literal") || "DartIdentifier".equals(nodeType)) {
      style.append(", shape=box"); // OR style=filled, color=yellow
    } else if ("DartClass".equals(nodeType)) {
      style.append(", shape=doubleoctagon");
    } else if ("DartMethodDefinition".equals(nodeType)) {
      style.append(", color=blue");
    }
    return style.toString();
  }

}
