// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.HashMultiset;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Multimap;
import com.google.common.collect.Multimaps;
import com.google.common.collect.Multiset;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.common.io.Closeables;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.common.AbstractBackend;
import com.google.dart.compiler.backend.js.ast.JsBlock;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.metrics.DartEventType;
import com.google.dart.compiler.metrics.Tracer;
import com.google.dart.compiler.metrics.Tracer.TraceEvent;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.util.DefaultTextOutput;
import com.google.dart.compiler.util.TextOutput;

import java.io.IOException;
import java.io.Writer;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.PriorityQueue;
import java.util.Set;

/**
 * Methods common to the ClosureJsBackend and JavascriptBackend.
 * @author johnlenz@google.com (John Lenz)
 */
public abstract class AbstractJsBackend extends AbstractBackend {

  public static final String EXTENSION_JS = "js";
  public static final String EXTENSION_APP_JS = "app.js";
  public static final String EXTENSION_JS_SRC_MAP = "js.map";
  public static final String EXTENSION_APP_JS_SRC_MAP = "app.js.map";

  private static final String ROOT_PART_NAME = "";
  private static final String STATICS_PART_NAME = "$statics$";
  private static final String SEPARATOR_PART_NAME = "$seperator$";

  protected final DartMangler mangler = new DollarMangler();

  protected static class Part {
    final LibraryUnit lib;
    final DartUnit unit;
    final String part;
    final ClassElement element;
    final ClassElement superElement;

    public Part(LibraryUnit lib, DartUnit unit, String part,
                ClassElement element, ClassElement superElement) {
      this.lib = lib;
      this.unit = unit;
      this.element = element;
      this.part = part;
      this.superElement = superElement;
    }

    @Override
    public int hashCode() {
      if (element != null) {
        return element.hashCode();
      }
      final int prime = 31;
      int result = 1;
      result = prime * result + ((part == null) ? 0 : part.hashCode());
      result = prime * result + ((unit == null) ? 0 : unit.hashCode());
      return result;
    }

    @Override
    public boolean equals(Object obj) {
      if (this == obj) {
        return true;
      }
      if (obj == null) {
        return false;
      }
      if (getClass() != obj.getClass()) {
        return false;
      }
      Part other = (Part) obj;
      if (element != null) {
        return element.equals(other.element);
      }
      return unit.equals(other.unit) && part.equals(other.part);
    }
  }

  protected static interface DepsCallback {
    void visitNative(LibraryUnit libUnit, LibraryNode node) throws IOException;
    void visitPart(Part part) throws IOException;
  }

  protected static class DependencyBuilder {
    private final List<Part> parts;
    private final Part staticSeparator = new Part(null, null, SEPARATOR_PART_NAME, null, null);

    static void build(LibraryUnit libUnit, DepsCallback callback) throws IOException {
      DependencyBuilder builder = new DependencyBuilder();
      builder.gatherParts(libUnit);
      builder.sortParts();
      builder.writeParts(callback);
    }

    private DependencyBuilder() {
      this.parts = new ArrayList<Part>();
    }

    private void gatherParts(LibraryUnit libUnit) {
      gatherParts(libUnit, new HashSet<LibraryUnit>());
    }

    private void gatherParts(LibraryUnit libUnit, Set<LibraryUnit> seenLibs) {
      // Avoid cycles.
      if (seenLibs.contains(libUnit)) {
        return;
      }
      seenLibs.add(libUnit);

      // Visit dependencies first.
      for (LibraryUnit importUnit : libUnit.getImports()) {
        gatherParts(importUnit, seenLibs);
      }

      for (DartUnit unit : libUnit.getUnits()) {
        DartSource src = unit.getSource();
        if (src != null) {
          // get the list of source source parts
          gatherUnitParts(libUnit, unit);
        }
      }
    }

    private void gatherUnitParts(LibraryUnit libUnit, DartUnit unit) {
      List<DartNode> nodes = ((DartUnit)unit.getNormalizedNode()).getTopLevelNodes();
      for (DartNode node : nodes) {
        DartNode norm = node.getNormalizedNode();
        if (norm instanceof DartClass) {
          DartClass clasz = (DartClass)norm;
          ClassElement selfElement = clasz.getSymbol();
          InterfaceType superType = selfElement.getSupertype();
          ClassElement superElement = null;
          if (superType != null) {
            superElement = superType.getElement();
            assert(superElement != null);
          }

          parts.add(new Part(libUnit, unit,
                             clasz.getClassName(), selfElement, superElement));
        }
      }

      parts.add(new Part(libUnit, unit, ROOT_PART_NAME, null, null)); // top-level bits
      parts.add(new Part(libUnit, unit, STATICS_PART_NAME, null, null)); // static initializer bits
    }

    /**
     * @param items The list of items to sort.
     * @param deps A map of dependencies between items.
     * @return A list of items in dependency order.
     */
    private static <T> List<T> topologicalStableSort(
        List<T> items, Multimap<T, T> deps) {
      final Map<T, Integer> originalIndex = Maps.newHashMap();
      for (int i = 0; i < items.size(); i++) {
        originalIndex.put(items.get(i), i);
      }

      PriorityQueue<T> inDegreeZero = new PriorityQueue<T>(items.size(),
          new Comparator<T>() {
        @Override
        public int compare(T a, T b) {
          return originalIndex.get(a).intValue() -
              originalIndex.get(b).intValue();
        }
      });
      List<T> result = Lists.newArrayList();

      Multiset<T> inDegree = HashMultiset.create();
      Multimap<T, T> reverseDeps = ArrayListMultimap.create();
      Multimaps.invertFrom(deps, reverseDeps);

      // First, add all the inputs with in-degree 0.
      for (T item : items) {
        Collection<T> itemDeps = deps.get(item);
        inDegree.add(item, itemDeps.size());
        if (itemDeps.isEmpty()) {
          inDegreeZero.add(item);
        }
      }

      // Then, iterate to a fixed point over the reverse dependency graph.
      while (!inDegreeZero.isEmpty()) {
        T item = inDegreeZero.remove();
        result.add(item);
        for (T inWaiting : reverseDeps.get(item)) {
          inDegree.remove(inWaiting, 1);
          if (inDegree.count(inWaiting) == 0) {
            inDegreeZero.add(inWaiting);
          }
        }
      }

      return result;
    }

    /**
     * Build a map of dependencies between Parts.
     * @param parts The parts to build dependencies from.
     */
    private Multimap<Part, Part> buildDependencyMap(List<Part> parts) {
      // Add a Part to act as separator between class initialization
      // and static initialization. Statics may depend on the classes
      // being properly setup.
      parts.add(staticSeparator);

      final Map<ClassElement, Part> elementToPartMap = Maps.newHashMap();
      for (Part part : parts) {
        if (part.element != null) {
          Part previous = elementToPartMap.put(part.element, part);
          assert(previous == null);
        }
      }

      // Get the direct dependencies.
      final Multimap<Part, Part> deps = HashMultimap.create();
      for (Part part : parts) {
        if (part.superElement != null) {
          Part superPart = elementToPartMap.get(part.superElement);
          assert(superPart != null);
          deps.put(part, superPart);
        }

        // Don't add a dependency on itself.
        if (part != staticSeparator) {
          if (part.part.equals(STATICS_PART_NAME)) {
            // Push all statics after classes.
            deps.put(part, staticSeparator);
          } else {
            // All classes before statics.
            deps.put(staticSeparator, part);
          }
        }
      }
      return deps;
    }

    /**
     * Sort the parts based on their dependencies.
     */
    private void sortParts() {
      List<Part> unsortedParts = parts;

      Multimap<Part, Part> deps = buildDependencyMap(unsortedParts);
      List<Part> sortParts = topologicalStableSort(unsortedParts, deps);

      parts.clear();
      parts.addAll(sortParts);
    }

    private long writeParts(DepsCallback callback)
        throws IOException {
      long charsWritten = 0;
      Set<LibraryUnit> seenLibs = new HashSet<LibraryUnit>();
      for (Part part : parts) {
        writePart(part, callback, seenLibs);
      }
      return charsWritten;
    }

    private void writePart(Part part, DepsCallback callback, Set<LibraryUnit> seenLibs)
        throws IOException {

      // Don't try to do anything with the fake separator part.
      if (part == staticSeparator) {
        return;
      }

      // Avoid cycles.
      if (!seenLibs.contains(part.lib)) {
        seenLibs.add(part.lib);
        // Prepend all native JS for this library.
        for (LibraryNode node : part.lib.getNativePaths()) {
          callback.visitNative(part.lib, node);
        }
      }

      callback.visitPart(part);
    }
  }

  protected Map<String, JsProgram> translateToJS(DartUnit unit, DartCompilerContext context,
      CoreTypeProvider typeProvider) {
    TraceEvent logEvent =
        Tracer.canTrace() ? Tracer.start(DartEventType.TRANSLATE_TO_JS, "unit",
            unit.getSourceName()) : null;

    CompilerOptions options = context.getCompilerConfiguration().getCompilerOptions();
    OptimizationStrategy optimizationStrategy;
    if (shouldOptimize() && !options.disableTypeOptimizations()) {
      optimizationStrategy = new BasicOptimizationStrategy(unit, typeProvider);
    } else {
      optimizationStrategy = new NoOptimizationStrategy(unit, typeProvider);
    }

     try {
      TraceEvent normalizeEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.JS_NORMALIZE, "unit",
              unit.getSourceName()) : null;
      try {
        // Normalize front-end AST for back-end consumption.
        unit = (DartUnit) (new Normalizer()).exec(unit, typeProvider,
            optimizationStrategy).getNormalizedNode();
      } finally {
        Tracer.end(normalizeEvent);
      }

      // TODO(floitsch.: Make namer configurable.
      JsNamer namer = new JsPrettyNamer();

      Map<String, JsProgram> parts = new LinkedHashMap<String, JsProgram>();

      List<DartNode> topNodes = unit.getTopLevelNodes();

      // Generate an id for this unit that can be used to make globally unique
      // identifiers.
      String baseUnitId = generateBaseUnitId(unit);
      int partIndex = 0;

      // Translate the AST to JS.
      JsProgram nonClassStatements = new JsProgram(baseUnitId + partIndex++);
      GenerateJavascriptAST nonClassGenerator = null;
      TranslationContext nonClassTranslationContext = null;


      JsProgram staticInitStatements = new JsProgram(baseUnitId + partIndex++);
      JsBlock staticInitBlock = staticInitStatements.getGlobalBlock();

      for (DartNode node : topNodes) {
        node = node.getNormalizedNode();
        if (node instanceof DartClass) {
          // TODO: Don't write out *.js for interfaces -- there are a lot of them
          TraceEvent nodeEvent =
              Tracer.canTrace() ? Tracer.start(DartEventType.TRANSLATE_NODE, "unit",
                  unit.getSourceName(), "node", node.getSymbol().getOriginalSymbolName()) : null;
          try {
            // Translate the AST to JS.
            JsProgram program = new JsProgram(baseUnitId + partIndex++);
            TranslationContext translationContext = TranslationContext.createContext(unit, program,
                mangler);

            // Generate the Javascript AST.
            GenerateJavascriptAST generator =
                new GenerateJavascriptAST(unit, typeProvider, context, optimizationStrategy,
                                          generateClosureCompatibleCode());
            generator.translateNode(translationContext, node, staticInitBlock);

            TraceEvent namerEvent =
                Tracer.canTrace() ? Tracer.start(DartEventType.NAMER, "unit",
                    unit.getSourceName()) : null;
            try {
              namer.exec(program);
            } finally {
              Tracer.end(namerEvent);
            }

            parts.put(((DartClass) node).getClassName(), program);
          } finally {
            Tracer.end(nodeEvent);
          }
        } else {
          if (nonClassGenerator == null) {
            TraceEvent genInitEvent =
                Tracer.canTrace() ? Tracer.start(DartEventType.GEN_AST_INIT, "unit",
                    unit.getSourceName()) : null;
            try {
              nonClassTranslationContext = TranslationContext.createContext(unit,
                  nonClassStatements, mangler);
              nonClassGenerator = new GenerateJavascriptAST(unit, typeProvider, context,
                  optimizationStrategy, generateClosureCompatibleCode());
            } finally {
              Tracer.end(genInitEvent);
            }
          }

          nonClassGenerator.translateNode(nonClassTranslationContext, node, staticInitBlock);
        }
      }

      TraceEvent namerEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.NAMER, "unit", unit.getSourceName())
              : null;
      try {
        namer.exec(nonClassStatements);
      } finally {
        Tracer.end(namerEvent);
      }

      // Out-of-date checks rely on the root JS file existing, even if it is empty
      parts.put(ROOT_PART_NAME, nonClassStatements);

      // Only add static parts if they are not empty
      for (int i = 0; i < staticInitStatements.getFragmentCount(); ++i) {
        if (!staticInitStatements.getFragmentBlock(i).getStatements().isEmpty()) {
          parts.put(STATICS_PART_NAME, staticInitStatements);
          break;
        }
      }

      return parts;
    } finally {
      Tracer.end(logEvent);
    }
  }

  private static String generateBaseUnitId(DartUnit unit) {
    MessageDigest md;
    try {
      md = MessageDigest.getInstance("MD5");
    } catch (NoSuchAlgorithmException e) {
      throw new AssertionError("Could not find MD5 digest");
    }
    StringBuilder sb = new StringBuilder();
    byte[] md5 = md.digest(unit.getSource().getUri().toString().getBytes());
    // Only use the first 6 hex characters of the md5.
    for (int i = 0; i < 3; i++) {
      sb.append(Integer.toHexString((md5[i] & 0xf0) >> 4));
      sb.append(Integer.toHexString(md5[i] & 0xf));
    }

    return sb.toString();
  }

  protected void writeEntryPointCall(String entry, Writer out) throws IOException {
    // Emit entry point call.
    // TODO: Actually validate that this method exists.
    // Small hack: the V8 arguments object is not an instance of Array. [].concat(arguments)
    // copies the elements of the arguments and returns a proper array.
    // However in Rhino this operation simply creates an array with 'arguments' as the first (and
    // only) element. By calling "arguments.slice()" on it, a new array is returned, and the
    // concatenation works again.
    // TODO: Use a more robust check to test that the argument is
    // array.
    out.write("RunEntry(" + entry + ", this.arguments ?" +
              " (this.arguments.slice ? [].concat(this.arguments.slice())" +
              " : this.arguments) : []);");
  }

  protected String getMangledEntryPoint(DartCompilerContext context) {
    MethodElement entry = context.getApplicationUnit().getElement().getEntryPoint();
    if (entry == null) {
      return null;
    }

    return mangler.mangleEntryPoint(entry, context.getApplicationUnit().getElement());
  }

  @Override
  public boolean isOutOfDate(DartSource src, DartCompilerContext context) {
    return context.isOutOfDate(src, src, EXTENSION_JS);
  }

  @Override
  public void compileUnit(DartUnit unit, DartSource src, DartCompilerContext context,
      CoreTypeProvider typeProvider) throws IOException {
    // Translate the AST to JS.
    Map<String, JsProgram> parts = translateToJS(unit, context, typeProvider);
    String srcName = src.getName();

    for (Map.Entry<String, JsProgram> entry : parts.entrySet()) {
      // Generate Javascript output.
      TextOutput out = new DefaultTextOutput(false);
      JsToStringGenerationVisitor srcGenerator;
      String name = entry.getKey();
      boolean failed = true;
      Writer w;

      JsProgram program = entry.getValue();
      JsBlock globalBlock = program.getGlobalBlock();

      TraceEvent srcEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.JS_SOURCE_GEN, "src", srcName, "name",
              name) : null;
      try {
        srcGenerator = new JsSourceGenerationVisitor(out);

        // TODO(johnlenz): Make source maps optional.
        srcGenerator.generateSourceMap(true);

        srcGenerator.accept(globalBlock);
        w = context.getArtifactWriter(src, name, EXTENSION_JS);
        try {
          w.write(out.toString());
          failed = false;
        } finally {
          Closeables.close(w, failed);
        }
      } finally {
        Tracer.end(srcEvent);
      }

      /*
       * Currently, out of date checks require that we write a JS file even if it is empty.
       * However, we should not write a map file if it is.
       */
      if (!globalBlock.getStatements().isEmpty() && generateSourceMap(context)) {
        TraceEvent sourcemapEvent =
            Tracer.canTrace() ? Tracer.start(DartEventType.WRITE_SOURCE_MAP, "src", srcName,
                "name", name) : null;
        try {
          // Write out the source map.
          w = context.getArtifactWriter(src, name, EXTENSION_JS_SRC_MAP);
          failed = true;
          try {
            srcGenerator.writeSourceMap(w, src.getName());
            failed = false;
          } finally {
            Closeables.close(w, failed);
          }
        } finally {
          Tracer.end(sourcemapEvent);
        }
      }
    }
  }

  protected abstract boolean shouldOptimize();

  protected boolean generateClosureCompatibleCode() {
    return false;
  }

  protected boolean generateSourceMap(DartCompilerContext context) {
    return context.getCompilerConfiguration().getCompilerOptions().generateSourceMaps();
  }
}
