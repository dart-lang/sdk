// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import org.mozilla.javascript.Context;
import org.mozilla.javascript.Function;
import org.mozilla.javascript.FunctionObject;
import org.mozilla.javascript.RhinoException;
import org.mozilla.javascript.Scriptable;
import org.mozilla.javascript.Undefined;

import java.io.PrintStream;
import java.lang.reflect.Member;

/**
 * @author floitsch@google.com (Florian Loitsch)
 *
 * Runs a given JS script.
 */
public class RhinoLauncher implements JavaScriptLauncher {

  /**
   * Rhino-callable assert() method.
   *
   * TODO(acleung): Deprecate it to just follow DartVM's test cases.
   */
  private static class AssertFunction extends SimpleFunction {
    @Override
    public Object call(Context ctx, Scriptable scope, Scriptable thisObj, Object[] args) {
      // Validate arguments (god, I hate this dynamic stuff).
      if ((args.length < 1) || (args.length > 2)) {
        Context.reportError("Invalid call to assertThat(" + args + ")");
      }
      if (!(args[0] instanceof Boolean)) {
        Context.reportError("Argument 0 must be of type boolean");
      }
      if (args.length == 2 && !(args[1] instanceof String)) {
        Context.reportError("Argument 1 must be of type String");
      }

      if (!(Boolean) args[0]) {
        Context.reportError("assert() failed" + ((args.length == 2) ? ": " + args[1] : ""));
      }
      return null;
    }
  }

  /**
   * Emulates the Expect_throwException() function.
   */
  public static class ThrowException extends FunctionObject {

    public ThrowException(String name, Member methodOrConstructor, Scriptable scope) {
      super(name, methodOrConstructor, scope);
    }

    @Override
    public Object call(Context ctx, Scriptable scope, Scriptable thisObj, Object[] args) {
      if (args.length != 1) {
        Context.reportError("Invalid call to Expect_throwException(e)");
      }
      throwException(args[0]);
      return Undefined.instance;
    }

    public void throwException(Object arg0) {
      Context.reportError(arg0.toString());
    }
  }

  /**
   * Emulates the V8 'write' function.
   */
  public static class Write extends FunctionObject {
    private PrintStream out;

    public Write(String name, Member methodOrConstructor, Scriptable scope, PrintStream out) {
      super(name, methodOrConstructor, scope);
      this.out = out;
    }

    @Override
    public Object call(Context ctx, Scriptable scope, Scriptable thisObj, Object[] args) {
      write(args[0]);
      return Undefined.instance;
    }

    public void write(Object arg0) {
      out.print(arg0);
    }
  }

  /**
   * Simple Rhino-callable function object.
   */
  private static abstract class SimpleFunction implements Function {
    @Override
    public Scriptable construct(Context cx, Scriptable scope, Object[] args) {
      return null;
    }

    @Override
    public void delete(int index) {
    }

    @Override
    public void delete(String name) {
    }

    @Override
    public Object get(int index, Scriptable start) {
      return null;
    }

    @Override
    public Object get(String name, Scriptable start) {
      return null;
    }

    @Override
    public String getClassName() {
      return "Function";
    }

    @Override
    public Object getDefaultValue(Class<?> hint) {
      return null;
    }

    @Override
    public Object[] getIds() {
      return null;
    }

    @Override
    public Scriptable getParentScope() {
      return null;
    }

    @Override
    public Scriptable getPrototype() {
      return null;
    }

    @Override
    public boolean has(int index, Scriptable start) {
      return false;
    }

    @Override
    public boolean has(String name, Scriptable start) {
      return false;
    }

    @Override
    public boolean hasInstance(Scriptable instance) {
      return false;
    }

    @Override
    public void put(int index, Scriptable start, Object value) {
    }

    @Override
    public void put(String name, Scriptable start, Object value) {
    }

    @Override
    public void setParentScope(Scriptable parent) {
    }

    @Override
    public void setPrototype(Scriptable prototype) {
    }
  }

  @Override
  public void execute(String jsScript, String sourceName, String[] args, RunnerOptions options,
                      PrintStream stdout, PrintStream stderr)
      throws RunnerError {
    try {
      Context ctx = Context.enter();
      Scriptable scope = ctx.initStandardObjects();
      scope.put("assert", scope, new AssertFunction());
      scope.put("native_Expect__throwException", scope, new ThrowException("Expect__throwException",
        ThrowException.class.getMethod("throwException", Object.class), scope));
      scope.put("write", scope, new Write("write",
        Write.class.getMethod("write", Object.class), scope, stderr));

      // The variable 'arguments' is also used in d8.
      // Rhino differentiates between Java Strings and JS Strings. If the args-array is not
      // converted the JS execution will work, but Rhino will complain.
      scope.put("arguments", scope, Context.javaToJS(args, scope));

      // Evaluate the application.
      ctx.evaluateString(scope, jsScript, sourceName, 1, null);
    } catch (NoSuchMethodException e) {
      throw new RunnerError(e);
    } catch (RhinoException e) {
      // TODO(jgw): This is a hack to dump the translated source when something goes wrong. It can
      // be removed as soon as we have a source map we can use to provide source-level errors.
      if (options.verbose()) {
        stdout.println(jsScript);
        stdout.flush();
      }

      StringBuffer msg = new StringBuffer();
      msg.append(e.sourceName());
      msg.append(" (" + e.lineNumber() + ":" + e.columnNumber() + ")");
      msg.append(" : " + e.details());
      stderr.println(msg.toString());
      throw e;
    } finally {
      Context.exit();
    }
  }

}
