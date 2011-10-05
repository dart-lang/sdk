// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.net.JarURLConnection;
import java.net.URL;
import java.util.HashSet;
import java.util.Set;

import org.deftserver.io.IOLoop;
import org.deftserver.io.timeout.Timeout;
import org.deftserver.web.AsyncCallback;
import org.mozilla.javascript.Context;
import org.mozilla.javascript.ScriptableObject;

import com.google.dart.CompileService;

public class Environment {

  private static URL getEnvironmentJavaScriptResource() {
    return Environment.class.getResource("environment.js");
  }

  public interface Destructor {
    void deallocate();
  }

  public enum Status {
    Exit, Refresh
  }

  private static ThreadLocal<Environment> instance = new ThreadLocal<Environment>();

  private Set<Destructor> destructors = new HashSet<Destructor>();

  public static Environment create(CompileService compileService) throws IOException,
      IllegalAccessException, InstantiationException, InvocationTargetException {
    final Environment env = newEnvironment(compileService);
    instance.set(env);
    return env;
  }

  public static Environment get() {
    assert instance.get() != null;
    return instance.get();
  }

  public static void goForth() {
    IOLoop.INSTANCE.start();
  }

  public static String getInstallPath() throws IOException {
    final File jarFile = new File(
        ((JarURLConnection) getEnvironmentJavaScriptResource().openConnection())
            .getJarFileURL().getFile());
    // fling.jar is in $root/runtime/fling.jar
    return jarFile.getParentFile().getParent();
  }

  private static Environment newEnvironment(CompileService compileService) throws IOException,
      IllegalAccessException, InstantiationException, InvocationTargetException {
    final Context context = Context.enter();
    // TODO(knorton): Run interpreted for now to avoid exceeding 64k bytecode
    // limit.
    context.setOptimizationLevel(-1);
    final ScriptableObject global = context.initStandardObjects();

    global.defineFunctionProperties(
        new String[] {
          "print",
          "goForth",
          "refresh",
          "getInstallPath" },
        Environment.class,
        ScriptableObject.DONTENUM);

    final Environment env = new Environment(context, global, compileService);

    // Setup modules.
    Http.setup(env);

    return env;
  }

  public static void print(String message) {
    System.out.print(message);
  }

  public static void refresh() {
    IOLoop.INSTANCE.addTimeout(new Timeout(0, new AsyncCallback() {
      @Override
      public void onCallback() {
        final Environment env = Environment.get();
        env.status = Status.Refresh;
        for (Destructor destructor : env.destructors) {
          destructor.deallocate();
        }
        IOLoop.INSTANCE.stop();
      }
    }));
  }

  private Status status = Status.Exit;

  private final Context context;

  private final ScriptableObject global;
  
  private final CompileService compileService;

  private Environment(Context context, ScriptableObject global, CompileService compileService) {
    this.context = context;
    this.global = global;
    this.compileService = compileService;
  }

  public Status execute(String javaScript) {
    // TODO(knorton): Give the source a name.
    context.evaluateString(global, javaScript, "<app>", 0, null);
    return status;
  }

  public CompileService getCompileService() {
    return compileService;
  }

  public Context getContext() {
    return context;
  }

  public ScriptableObject getGlobal() {
    return global;
  }

  public void register(Destructor destructor) {
    destructors.add(destructor);
  }

  public void destroy() {
    Context.exit();
  }
}
