// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.common.io.LimitInputStream;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.backend.js.ast.JsProgram;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.javascript.jscomp.CheckLevel;
import com.google.javascript.jscomp.CompilationLevel;
import com.google.javascript.jscomp.Compiler;
import com.google.javascript.jscomp.CompilerInput;
import com.google.javascript.jscomp.CompilerOptions;
import com.google.javascript.jscomp.DiagnosticGroups;
import com.google.javascript.jscomp.JSError;
import com.google.javascript.jscomp.JSModule;
import com.google.javascript.jscomp.JSSourceFile;
import com.google.javascript.jscomp.PropertyRenamingPolicy;
import com.google.javascript.jscomp.Result;
import com.google.javascript.jscomp.SourceAst;
import com.google.javascript.jscomp.SourceMap.DetailLevel;
import com.google.javascript.jscomp.SourceMap.Format;
import com.google.javascript.jscomp.VariableRenamingPolicy;
import com.google.javascript.jscomp.WarningLevel;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * A compiler backend that produces raw Javascript.
 * @author johnlenz@google.com (John Lenz)
 */
public class ClosureJsBackend extends AbstractJsBackend {
  private static final String EXTENSION_OPT_JS = "opt.js";
  private static final String EXTENSION_OPT_JS_SRC_MAP = "opt.js.map";

  // A map of possible input sources to use when building the optimized output.
  private Map<String, DartUnit> dartSrcToUnitMap = Maps.newHashMap();
  private long totalJsOutputCharCount;

  // Generate "readable" output for debugging
  private final boolean generateHumanReadableOutput;
  // Generate "good" instead of "best" output.
  private final boolean fastOutput;
  // TODO(johnlenz): Currently we can only support incremential builds
  // if we aren't building source maps.
  private final boolean incremental;

  // Validate the generated JavaScript
  private final boolean validate;

  // Whether the generated code is "checked".
  private final boolean checkedMode;

  public ClosureJsBackend() {
    this(false, false);
  }

  /**
   * @param generateHumanReadableOutput - generates human readable javascript output.
   */
  public ClosureJsBackend(boolean checkedMode, boolean generateHumanReadableOutput) {
    // Current default settings
    this(false, false, true, checkedMode, generateHumanReadableOutput);
  }

  public ClosureJsBackend(boolean fastOutput,
                          boolean incremental,
                          boolean validate,
                          boolean checkedMode,
                          boolean generateHumanReadableOutput) {
    this.fastOutput = fastOutput;
    // can't currently produce a valid source map incrementally
    this.incremental = incremental;
    this.validate = validate;
    this.checkedMode = checkedMode;
    this.generateHumanReadableOutput = generateHumanReadableOutput;
  }

  @Override
  public boolean isOutOfDate(DartSource src, DartCompilerContext context) {
    if (!incremental) {
      return true;
    } else {
      return super.isOutOfDate(src, context);
    }
  }

  @Override
  public void compileUnit(DartUnit unit, DartSource src,
      DartCompilerContext context, CoreTypeProvider typeProvider) throws IOException {
    if (!incremental) {
      dartSrcToUnitMap.put(src.getName(), unit);
    } else {
      super.compileUnit(unit, src, context, typeProvider);
    }
  }

  private Map<String, CompilerInput> createClosureJsAst(Map<String,JsProgram> parts, Source source) {
    String name = source.getName();
    Preconditions.checkState(name != null && !name.isEmpty(), "A source name is required");

    Map<String, CompilerInput> translatedParts = new HashMap<String, CompilerInput>();
    for (Map.Entry<String,JsProgram> part : parts.entrySet()) {
      String partName = part.getKey();
      String inputName = name + ':' + partName;
      SourceAst sourceAst = new ClosureJsAst(part.getValue(), inputName, source, validate);
      CompilerInput input = new CompilerInput(sourceAst, false);
      translatedParts.put(part.getKey(), input);
    }
    return translatedParts;
  }

  private class DepsWritingCallback implements DepsCallback {
    private final DartCompilerContext context;
    private final CoreTypeProvider typeProvider;
    private final List<CompilerInput> inputs;
    private final Map<String, Source> sourcesByName;
    private final Map<DartUnit, Map<String, CompilerInput>> translatedUnits = Maps.newHashMap();

    DepsWritingCallback(
        DartCompilerContext context,
        CoreTypeProvider typeProvider,
        List<CompilerInput> inputs,
        Map<String, Source> sourcesByName) {
      this.context = context;
      this.typeProvider = typeProvider;
      this.inputs = inputs;
      this.sourcesByName = sourcesByName;
    }

    @Override
    public void visitNative(LibraryUnit libUnit, LibraryNode node)
        throws IOException {
      String name = node.getText();
      DartSource nativeSrc = libUnit.getSource().getSourceFor(name);
      StringWriter w = new StringWriter();
      Reader r = nativeSrc.getSourceReader();
      CharStreams.copy(r, w);
      inputs.add(new CompilerInput(createSource(name, w), false));
    }

    @Override
    public void visitPart(Part part) throws IOException {
      DartSource src = part.unit.getSource();
      if (!incremental) {
        Map<String, CompilerInput> translatedParts = translatedUnits.get(part.unit);
        if (translatedParts == null) {
          assert !sourcesByName.containsKey(src.getName());
          sourcesByName.put(src.getName(), src);
          Preconditions.checkNotNull(part.unit, "src: " + src.getName());
          translatedParts = translateUnit(part.unit, src, context, typeProvider);
          Preconditions.checkState(!translatedUnits.containsKey(part.unit));
          translatedUnits.put(part.unit, translatedParts);
        }
        inputs.add(translatedParts.get(part.part));
        return;
      }

      Reader r = context.getArtifactReader(src, part.part, EXTENSION_JS);
      if (r == null) {
        return;
      }
      StringWriter w = new StringWriter();
      CharStreams.copy(r, w);
      String inputName = src.getName() + ':' + part.part;
      inputs.add(new CompilerInput(createSource(inputName, w), false));
    }

    private JSSourceFile createSource(String name, Writer w) {
      return JSSourceFile.fromCode(name, w.toString());
    }
  }

  private void packageAppOptimized(LibrarySource app,
                                   Collection<LibraryUnit> libraries,
                                   DartCompilerContext context,
                                   CoreTypeProvider typeProvider)
      throws IOException {

    List<CompilerInput> inputs = Lists.newLinkedList();
    Map<String, Source> sourcesByName = Maps.newHashMap();
    DepsWritingCallback callback = new DepsWritingCallback(
        context, typeProvider, inputs, sourcesByName);
    DependencyBuilder.build(context.getAppLibraryUnit(), callback);

    // Lastly, add the entry point.
    inputs.add(getCompilerInputForEntry(context));

    // Currently, there is only a single module, add all the sources to it.
    JSModule mainModule = new JSModule("main");
    for (CompilerInput input : inputs) {
      if (input != null) {
        mainModule.add(input);
      }
    }

    Writer out = context.getArtifactWriter(app, "", getAppExtension());
    boolean failed = true;
    try {
      compileModule(app, context, mainModule, sourcesByName, out);
      failed = false;
    } finally {
      Closeables.close(out, failed);
    }
  }

  private Map<String, CompilerInput> translateUnit(
      DartUnit unit, DartSource src, DartCompilerContext context, CoreTypeProvider typeProvider) {
    Map<String, JsProgram> parts = translateToJS(unit, context, typeProvider);

    // Translate the AST and cache it for later use.
    return createClosureJsAst(parts, src);
  }

  private CompilerInput getCompilerInputForEntry(DartCompilerContext context)
      throws IOException {
    StringWriter entry = new StringWriter();
    writeEntryPointCall(getMangledEntryPoint(context), entry);
    return new CompilerInput(
        JSSourceFile.fromCode("entry", entry.toString()), false);
  }

  class MockSource implements Source {
    private String sourceName;

    MockSource(String sourceName) {
      this.sourceName = sourceName;
    }

    @Override
    public boolean exists() {
      return true;
    }

    @Override
    public long getLastModified() {
      return 0;
    }

    @Override
    public String getName() {
      return sourceName;
    }

    @Override
    public Reader getSourceReader() {
      return new StringReader("");
    }

    @Override
    public URI getUri() {
      return null;
    }
  }

  // Stub source info object for reporting errors coming from the Closure Compiler
  static class JSErrorSourceInfo implements SourceInfo {
    final JSError error;
    final Source source;

    JSErrorSourceInfo(JSError error, Source source) {
      this.error = error;
      this.source = source;
    }

    @Override
    public Source getSource() {
      return source;
    }

    @Override
    public int getSourceColumn() {
      return error.getCharno();
    }

    @Override
    public int getSourceLength() {
      return -1;
    }

    @Override
    public int getSourceLine() {
      return error.lineNumber;
    }

    @Override
    public int getSourceStart() {
      return -1;
    }
  }

  private void compileModule(
      LibrarySource src, DartCompilerContext context,
      JSModule module,
      Map<String, Source> sourcesByName,
      Writer out) throws IOException {
    // Turn off Closure Compiler logging
    CompilerOptions options = getClosureCompilerOptions(context);
    Logger.getLogger("com.google.javascript.jscomp").setLevel(Level.OFF);

    Compiler compiler = new Compiler();

    List<JSSourceFile> externs = getDefaultExterns();
    List<JSModule> modules = Lists.newLinkedList();
    modules.add(module);
    Result result = compiler.compileModules(externs, modules, options);

    if (processResults(src, context, compiler, result, module, out) != 0) {
      for (JSError error : result.errors) {
        // Use the real dart source object when we can.
        Source source = sourcesByName.get(error.sourceName);
        if (source == null) {
          // This might be a compiler generate source, whatever it is
          // report it.
          source = new MockSource(error.sourceName);
        }
        System.err.println("error optimizing:" + error.toString());
        @SuppressWarnings("deprecation")
        DartCompilationError event = new DartCompilationError(
            new JSErrorSourceInfo(error, source), error.description);
        context.compilationError(event);
      }
    }

    out.close();
  }

  /**
   * Processes the results of the compile job, and returns an error code.
   */
  private int processResults(LibrarySource src, DartCompilerContext context, Compiler compiler,
      Result result, JSModule module, Writer out)
      throws IOException {
    if (result.success) {
      // TODO(johnlenz): Append directly to the writer.
      String output = compiler.toSource(module);
      out.append(output);
      out.append('\n');

      if (generateSourceMap(context)) {
        Writer srcMapOut = context.getArtifactWriter(src, "", getSourceMapExtension());
        boolean failed = true;
        try {
          compiler.getSourceMap().appendTo(srcMapOut, module.getName());
          failed = false;
        } finally {
          Closeables.close(srcMapOut, failed);
        }
      }
      totalJsOutputCharCount = output.length();
    }

    // return 0 if no errors, the error count otherwise
    return Math.min(result.errors.length, 0x7f);
  }

  private CompilerOptions getClosureCompilerOptions(DartCompilerContext context) {
    CompilerOptions options = new CompilerOptions();
    options.setCodingConvention(new ClosureJsCodingConvention());

    // Set the optimization passes that we want.
    if (fastOutput) {
      options.smartNameRemoval = true;
      options.collapseProperties = true;
      options.removeUnusedPrototypeProperties = true;
      options.removeUnusedVars = true;
      options.setRenamingPolicy(VariableRenamingPolicy.ALL, PropertyRenamingPolicy.ALL_UNQUOTED);
      // On by default
      options.setReplaceIdGenerators(false);
   } else {
      CompilationLevel.ADVANCED_OPTIMIZATIONS.setOptionsForCompilationLevel(options);
      options.setAssumeStrictThis(true);
      // TODO(johnlenz): try out experimential inlining
      // options.setAssumeClosuresOnlyCaptureReferences(true);

      // TODO(johnlenz): rewriteFunctionExpressions kills the Richards benchmark,
      // it needs some better heuristics.
      options.rewriteFunctionExpressions = false;

      // AliasKeywords has a runtime performance hit, disable it.
      options.aliasKeywords = false;

      // slow for little value
      options.setPropertyAffinity(false);

      // TODO(johnlenz): These passes use SimpleDefinitionFinder or equivalent, and operate
      // based on property name, not object type. DisambiguateProperties helps but is not
      // a complete fix even with complete type information.
      // See http://code.google.com/p/closure-compiler/issues/detail?id=437.
      // We need to develop a plan for how to deal with them.

      options.computeFunctionSideEffects = false;
      options.devirtualizePrototypeMethods = true;
      options.inlineGetters = true;

      // TODO(johnlenz): Some DOM definitions look like unused prototype property
      // definitions because they are only referenced using dynamically generated
      // names.
      options.removeUnusedPrototypePropertiesInExterns = false;
    }

    if (generateSourceMap(context)) {
      options.sourceMapOutputPath = "placeholder"; // anything will do
      options.sourceMapDetailLevel = DetailLevel.SYMBOLS;
      options.sourceMapFormat = Format.V3;
    }

    // Turn off the default checks.

    // Dart doesn't currently need the Closure Library checks
    // or optimizations.
    options.closurePass = false;

    // Disable type warnings as we don't provide any type information.
    options.setInferTypes(false);
    options.checkTypes = false;
    options.setWarningLevel(DiagnosticGroups.CHECK_TYPES, CheckLevel.OFF);

    // Disable other checks, that don't make sense for generated code
    options.setWarningLevel(DiagnosticGroups.GLOBAL_THIS, CheckLevel.OFF);
    options.checkSuspiciousCode = false;
    options.checkGlobalThisLevel = CheckLevel.OFF;
    options.checkMissingReturn = CheckLevel.OFF;
    options.checkGlobalNamesLevel = CheckLevel.OFF;
    options.aggressiveVarCheck = CheckLevel.OFF;
    options.setWarningLevel(DiagnosticGroups.DEPRECATED, CheckLevel.OFF);

    // Optionally turn on the checks that are useful to Dart
    if (validate) {
      options.checkSymbols = true;
      options.setWarningLevel(DiagnosticGroups.ES5_STRICT, CheckLevel.ERROR);
      // options.setAggressiveVarCheck(CheckLevel.ERROR);
    } else {
      // A lot of warnings don't make sense for generated code, or require type
      // information. Turn them all off by default and make the ones we care
      // about errors.
      WarningLevel.QUIET.setOptionsForWarningLevel(options);

      options.checkSymbols = false;
      options.setWarningLevel(DiagnosticGroups.ES5_STRICT, CheckLevel.OFF);
    }

    // To ease debugging, try enabling these options:
    if (generateHumanReadableOutput) {
      options.prettyPrint = true;
      options.generatePseudoNames = true;
      options.printInputDelimiter = true;
      options.inputDelimiter = "// Input %name%";
    }
    // If those aren't enough, try disabling these:
    // options.setRenamingPolicy(VariableRenamingPolicy.OFF, PropertyRenamingPolicy.OFF);
    // options.coalesceVariableNames = false;
    // options.setShadowVariables(false);
    // options.inlineFunctions = false;

    /*
     * NOTE: We turn this off because TypeErrors or anything that relies on a type name will fail
     * due to the class renaming.
     */
    if (checkedMode) {
      options.setReplaceIdGenerators(false);
    }

    return options;
  }

  // The externs expected in externs.zip, in sorted order.
  private static final List<String> DEFAULT_EXTERNS_NAMES = ImmutableList.of(
    // JS externs
    "es3.js",
    "es5.js",
    // "json.js", // TODO(johnlenz): add this.

    // Event APIs
    "w3c_event.js",
    "w3c_event3.js",
    "gecko_event.js",
    "ie_event.js",
    "webkit_event.js",

    // DOM apis
    "w3c_dom1.js",
    "w3c_dom2.js",
    "w3c_dom3.js",
    "gecko_dom.js",
    "ie_dom.js",
    "webkit_dom.js",

    // CSS apis
    "w3c_css.js",
    "gecko_css.js",
    "ie_css.js",
    "webkit_css.js",

    // Top-level namespaces
    "google.js",

    "deprecated.js",
    "fileapi.js",
    "flash.js",
    "gears_symbols.js",
    "gears_types.js",
    "gecko_xml.js",
    "html5.js",
    "ie_vml.js",
    "iphone.js",
    "webstorage.js",
    "w3c_anim_timing.js",
    "w3c_css3d.js",
    "w3c_elementtraversal.js",
    "w3c_geolocation.js",
    "w3c_indexeddb.js",
    "w3c_navigation_timing.js",
    "w3c_range.js",
    "w3c_selectors.js",
    "w3c_xml.js",
    "window.js",
    "webkit_notifications.js",
    "webgl.js");

  // Add a declarations for the V8 logging function.
  private static final String UNIT_TEST_EXTERN_STUBS = "var write;";

  private static final String CLOSURE_PRIMITIVES = "function JSCompiler_renameProperty() {};";

  // TODO(johnlenz): include json.js in the default set of externs.
  private static final String MISSING_EXTERNS =
      "var JSON = {};\n" +
      "/**\n" +
      " * @param {string} jsonStr The string to parse.\n" +
      " * @param {(function(string, *) : *)=} opt_reviver\n" +
      " * @return {*} The JSON object.\n" +
      " */\n" +
      "JSON.parse = function(jsonStr, opt_reviver) {};\n" +
      "\n" +
      "/**\n" +
      " * @param {*} jsonObj Input object.\n" +
      " * @param {(Array.<string>|(function(string, *) : *)|null)=} opt_replacer\n" +
      " * @param {(number|string)=} opt_space\n" +
      " * @return {string} json string which represents jsonObj.\n" +
      " */\n" +
      "JSON.stringify = function(jsonObj, opt_replacer, opt_space) {};" +
      "\n";

  /**
   * @return a mutable list
   * @throws IOException
   */
  private static List<JSSourceFile> getDefaultExterns() throws IOException {
    Class<ClosureJsBackend> clazz = ClosureJsBackend.class;
    InputStream input = clazz.getResourceAsStream(
        "/com/google/javascript/jscomp/externs.zip");
    if (input == null) {
      /*
       * HACK - the open source version of the closure compiler maps the
       * resource into a different location.
       */
      input = clazz.getResourceAsStream("/externs.zip");
    }
    ZipInputStream zip = new ZipInputStream(input);
    Map<String, JSSourceFile> externsMap = Maps.newHashMap();
    for (ZipEntry entry = null; (entry = zip.getNextEntry()) != null; ) {
      InputStream entryStream = new BufferedInputStream(
          new LimitInputStream(zip, entry.getSize()));
      externsMap.put(entry.getName(),
          JSSourceFile.fromInputStream(
              // Give the files an odd prefix, so that they do not conflict
              // with the user's files.
              "externs.zip//" + entry.getName(),
              entryStream));
    }

    Preconditions.checkState(
        externsMap.keySet().equals(Sets.newHashSet(DEFAULT_EXTERNS_NAMES)),
        "Externs zip must match our hard-coded list of externs.");

    // Order matters, so the resources must be added to the result list
    // in the expected order.
    List<JSSourceFile> externs = Lists.newArrayList();
    for (String key : DEFAULT_EXTERNS_NAMES) {
      externs.add(externsMap.get(key));
    }

    // Add methods used when running the unit tests.
    externs.add(JSSourceFile.fromCode("missingExterns", MISSING_EXTERNS));

    // Add methods used when running the unit tests.
    externs.add(JSSourceFile.fromCode("unitTestStubs", UNIT_TEST_EXTERN_STUBS));

    // Add methods used by Closure Compiler itself.
    externs.add(JSSourceFile.fromCode("closureCompilerPrimitives", CLOSURE_PRIMITIVES));

    return externs;
  }

  @Override
  public void packageApp(LibrarySource app,
                         Collection<LibraryUnit> libraries,
                         DartCompilerContext context,
                         CoreTypeProvider typeProvider)
      throws IOException {
    totalJsOutputCharCount = 0;
    packageAppOptimized(app, libraries, context, typeProvider);
    CompilerMetrics compilerMetrics = context.getCompilerMetrics();
    if (compilerMetrics != null) {
      compilerMetrics.packagedJsApplication(totalJsOutputCharCount, -1);
    }
  }

  @Override
  public String getAppExtension() {
    return (incremental) ? EXTENSION_APP_JS : EXTENSION_OPT_JS;
  }

  @Override
  public String getSourceMapExtension() {
    return (incremental) ? EXTENSION_APP_JS_SRC_MAP : EXTENSION_OPT_JS_SRC_MAP;
  }

  @Override
  protected boolean shouldOptimize() {
    return (fastOutput) ? false : true;
  }

  @Override
  protected boolean generateClosureCompatibleCode() {
    return true;
  }
}
