// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

import java.io.File;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.activation.MimetypesFileTypeMap;

import org.deftserver.io.IOLoop;
import org.deftserver.web.Application;
import org.deftserver.web.AsyncCallback;
import org.deftserver.web.Asynchronous;
import org.deftserver.web.HttpServer;
import org.deftserver.web.handler.NotFoundRequestHandler;
import org.deftserver.web.handler.RequestHandler;
import org.deftserver.web.http.HttpException;
import org.deftserver.web.http.HttpRequest;
import org.deftserver.web.http.HttpResponse;
import org.mozilla.javascript.BaseFunction;
import org.mozilla.javascript.Context;
import org.mozilla.javascript.Function;
import org.mozilla.javascript.NativeArray;
import org.mozilla.javascript.Scriptable;
import org.mozilla.javascript.ScriptableObject;

import com.google.dart.CompileError;
import com.google.dart.CompileResult;
import com.google.dart.CompileService;

/**
 * Implementation for DeftServer.
 */
public class Http {
  // TODO(knorton): This is a wasteful hack to work around the fact that I want
  // the HttpServer in the Dart API to work via URL prefixes and not the
  // half-assed absolute + capturing groups that Deft uses.
  public static class HackyApplication extends Application {
    private final PrefixTree<Function> paths = new PrefixTree<Function>();

    public HackyApplication() {
      // Deft creates indexes for its absolute + capturing group scheme, but I
      // want them to be empty because I'm not going to use them.
      super(new HashMap<String, RequestHandler>());
    }

    @Override
    public RequestHandler getHandler(HttpRequest request) {
      final PrefixTree.Entry<Function> entry = paths.resolve(request
          .getRequestedPath());
      if (entry == null) {
        return NotFoundRequestHandler.getInstance();
      }

      return new Handler(entry.getPrefix(), entry.getValue());
    }

    private void handle(String prefix, Function handler) {
      paths.add(prefix, handler);
    }
  }

  @SuppressWarnings("serial")
  public static class Request extends ScriptableObject {
    public static final String CLASSNAME = "HttpRequest";

    private static ScriptableObject createDartInstance(Environment env, String prefix,
        HttpRequest request) {
      final Function factory = RhinoUtil.getProperty(env.getGlobal(),
          "native_HttpRequest__create");
      final ScriptableObject instance = (ScriptableObject) factory.call(env.getContext(), env.getGlobal(), env.getGlobal(), new Object[] {});
      RhinoUtil.setProperty(instance, "$impl", create(env, prefix, request));
      return instance;
    }
    
    private static Request create(Environment environment, String prefix,
        HttpRequest request) {
      final Request req = (Request) environment.getContext().newObject(
          environment.getGlobal(), CLASSNAME);
      req.request = request;
      req.prefix = prefix;
      return req;
    }

    private HttpRequest request;

    private String prefix;

    public Request() {
    }

    @Override
    public String getClassName() {
      return CLASSNAME;
    }

    public void jsConstructor() {
    }

    public String jsGet_requestedPath() {
      return request.getRequestedPath();
    }

    public String jsGet_body() {
      return request.getBody();
    }

    public String jsGet_prefix() {
      return prefix;
    }

    public boolean jsGet_isKeepAlive() {
      return request.isKeepAlive();
    }

    public String jsGet_requestLine() {
      return request.getRequestLine();
    }

    public String jsGet_method() {
      return request.getMethod().name();
    }

    public String jsFunction_getHeader(String name) {
      return request.getHeader(name);
    }

    public String jsGet_version() {
      return request.getVersion();
    }

    public String jsFunction_getParameter(String name) {
      return request.getParameter(name);
    }
    // TODO(knorton): Implement headers property.
    // TODO(knorton): Implement parameters property.
  }

  @SuppressWarnings("serial")
  public static class Response extends ScriptableObject {
    public static final String CLASSNAME = "HttpResponse";

    private static ScriptableObject createDartInstance(Environment env, HttpResponse response) {
      final Function factory = RhinoUtil.getProperty(env.getGlobal(),
          "native_HttpResponse__create");
      final ScriptableObject instance = (ScriptableObject) factory.call(
          env.getContext(), env.getGlobal(), env.getGlobal(), new Object[] {});
      RhinoUtil.setProperty(instance, "$impl", create(env, response));
      return instance;
    }

    private static Response create(Environment environment,
        HttpResponse response) {
      final Response res = (Response) environment.getContext().newObject(
          environment.getGlobal(), CLASSNAME);
      res.response = response;
      return res;
    }

    private HttpResponse response;

    public Response() {
    }

    @Override
    public String getClassName() {
      return CLASSNAME;
    }

    public void jsConstructor() {
    }

    public void jsFunction_setStatusCode(int code) {
      response.setStatusCode(code);
    }

    public long jsFunction_flush() {
      return response.flush();
    }

    public long jsFunction_finish() {
      return response.finish();
    }

    public void jsFunction_setHeader(String name, String value) {
      response.setHeader(name, value);
    }

    public void jsFunction_write(String data) {
      response.write(data);
    }
  }

  @SuppressWarnings("serial")
  public static class Server extends ScriptableObject {
    public static final String CLASSNAME = "HttpServer";

    private final HackyApplication app;

    @Override
    public String getClassName() {
      return CLASSNAME;
    }
    
    public Server() {
      app = new HackyApplication();
    }
    
    public void jsConstructor() {
    }

    public void jsFunction_handle(String path, Function handler) {
      app.handle(path, handler);
    }
    
    public void jsFunction_listen(int port) {
      final Environment environment = Environment.get();

      // Create a proper HttpServer.
      final HttpServer server = new HttpServer(app);

      server.listen(port);

      environment.register(new Environment.Destructor() {
        @Override
        public void deallocate() {
          server.stop();
        }
      });
    }
  }

  private static class Handler extends RequestHandler {
    private final Function function;
    private final String prefix;

    Handler(String prefix, Function function) {
      this.function = function;
      this.prefix = prefix;
    }

    @Override
    @Asynchronous
    public void get(HttpRequest request, HttpResponse response) {
      handle(request, response);
    }

    @Override
    @Asynchronous
    public void head(HttpRequest request, HttpResponse response) {
      handle(request, response);
    }

    @Override
    @Asynchronous
    public void post(HttpRequest request, HttpResponse response) {
      handle(request, response);
    }

    private void handle(HttpRequest request, HttpResponse response) {
      final Environment env = Environment.get();
      function.call(
          env.getContext(),
          env.getGlobal(),
          env.getGlobal(),
          new Object[] {
            Request.createDartInstance(env, prefix, request),
            Response.createDartInstance(env, response)});
    }
  }

  @SuppressWarnings("serial")
  public static class ClientApp extends ScriptableObject {
    private static class HandlerFunction extends BaseFunction {

      private final File directory;

      private final Map<File, String> prebuilt;

      HandlerFunction(File directory, Map<File, String> prebuilt) {
        this.directory = directory;
        this.prebuilt = prebuilt;
      }

      private static File getDartAppFile(File file) {
        final String name = file.getName();
        if (name.endsWith(".dart.app.js")) {
          // Remove the app.js from the end of the file.
          return new File(file.getParent(),
              name.substring(0, name.length() - 7));
        }

        return null;
      }

      private static void checkForValidFile(File file) {
        if (!file.exists()) {
          throw new HttpException(404);
        }

        if (!file.isFile()) {
          throw new HttpException(403);
        }
      }

      private static String toJavaScriptStringLiteral(String value) {
        return "'" + value.replace("'", "\\'").replace("\n", "\\\n") + "'";
      }

      private static void emitWarningsAndErrors(StringBuilder buffer, CompileResult result) {
        for (CompileError error : result.getFatalErrors()) {
          buffer.append("console.error("
              + toJavaScriptStringLiteral(error.toString()) + ");\n");
        }
        for (CompileError error : result.getTypeErrors()) {
          buffer.append("console.warn("
              + toJavaScriptStringLiteral(error.toString()) + ");\n");
        }
        for (CompileError error : result.getWarnings()) {
          buffer.append("console.warn("
              + toJavaScriptStringLiteral(error.toString()) + ");\n");
        }
      }

      private String getStackTraceAsString(Throwable e) {
        final StringWriter buffer = new StringWriter();
        final PrintWriter writer = new PrintWriter(buffer);
        e.printStackTrace(writer);
        writer.flush();
        return buffer.toString();
      }

      private void deliverJavaScript(HttpResponse response, String code) {
        response.setHeader("Content-Type", "application/javascript");
        response.setHeader("cache-control", "no-cache");
        response.write(code);
        response.finish();
      }

      private void buildDartApp(final HttpResponse response, final File file) {
        final CompileService compileService = Environment.get().getCompileService();
        // If the requested app is one of the prebuilt apps, serve the
        // JavaScript.
        final String code = prebuilt.get(file);
        if (code != null) {
          deliverJavaScript(response, code);
          return;
        }

        defer(new Callable<CompileResult>() {
          @Override
          public CompileResult call() throws Exception {
            final CompileResult result = compileService.build(file);
            if (result.getException() != null) {
              throw new Exception(result.getException());
            }
            return result;
          }

        }, new AsyncResponse<CompileResult>() {
          @Override
          public void didRespond(CompileResult result) {
            final StringBuilder code = new StringBuilder();
            // Add any errors and warnings to the front of the buffer.
            emitWarningsAndErrors(code, result);
            if (result.didBuild()) {
              code.append(result.getJavaScript());
            }
            deliverJavaScript(response, code.toString());
          }

          @Override
          public void didThrowException(Throwable e) {
            e.printStackTrace();
            // But also error the HTTP request.
            response.setStatusCode(500);
            response.write(getStackTraceAsString(e));
            response.finish();
          }
        });
      }

      @Override
      public Object call(Context context, Scriptable scope, Scriptable self,
          Object[] args) {
        final ScriptableObject dartReq = (ScriptableObject) args[0];
        final ScriptableObject dartRes = (ScriptableObject) args[1];
        
        final Request req = RhinoUtil.getProperty(dartReq, "$impl");
        final Response res = RhinoUtil.getProperty(dartRes, "$impl");

        final HttpRequest request = req.request;
        final HttpResponse response = res.response;

        final String prefix = req.prefix;
        final String path = request.getRequestedPath();

        // TODO(knorton): Normalize path so raw ../../ are not dangerous!
        final File file = new File(directory, path.substring(prefix.length()));
        final File dartAppFile = getDartAppFile(file);

        if (dartAppFile != null) {
          checkForValidFile(dartAppFile);
          buildDartApp(response, dartAppFile);
          return null;
        }

        checkForValidFile(file);
        response.setHeader("Content-Type", getContentType(file));
        response.setHeader("cache-control", "no-cache");
        response.write(file);
        response.finish();
        return null;
      }
    }

    public static final String CLASSNAME = "ClientApp";

    private HandlerFunction handler;
    
    @Override
    public String getClassName() {
      return CLASSNAME;
    }
    
    public ClientApp() {
    }
    
    public void jsConstructor(String path, NativeArray apps) {
      final CompileService compileService = Environment.get().getCompileService();

      // param #1: path to a directory.
      final File file = new File(path);

      // param #2: a list of relative paths to apps that should be prebuilt and
      // will not change.
      final Map<File, String> prebuilt = new HashMap<File, String>();
      if (apps != null) {
        for (long i = 0, n = apps.getLength(); i < n; ++i) {
          final File appFile = new File(path, (String) apps.get(i));
          final CompileResult result = compileService.build(appFile);
          Fling.emitErrorsAndWarnings(result);
          if (!result.didBuild()) {
            throw new RuntimeException();
          }
          prebuilt.put(appFile, result.getJavaScript());
        }
      }

      handler = new HandlerFunction(file, prebuilt);
    }

    public ScriptableObject jsGet_handler() {
      return handler;
    }
  }
  
  private static final int NUMBER_OF_WORKERS = 2;

  private static ExecutorService workers;

  private static final Map<String, String> mimeTypes = createMimeTypeMap();

  private static Map<String, String> createMimeTypeMap() {
    final Map<String, String> map = new HashMap<String, String>();
    map.put(".css", "text/css; charset=utf-8");
    map.put(".gif", "image/gif");
    map.put(".htm", "text/html; charset=utf-8");
    map.put(".html", "text/html; charset=utf-8");
    map.put(".jpg", "image/jpeg");
    map.put(".js", "application/x-javascript");
    map.put(".pdf", "application/pdf");
    map.put(".png", "image/png");
    map.put(".xml", "text/xml; charset=utf-8");
    return map;
  }

  private static String getExtension(File file) {
    final String name = file.getName();
    final int index = name.lastIndexOf('.');
    return index == -1 ? null : name.substring(index);
  }

  private static String getContentType(File file) {
    final String ext = getExtension(file);
    if (ext == null) {
      return null;
    }

    final String type = mimeTypes.get(ext);
    return type != null ? type : MimetypesFileTypeMap.getDefaultFileTypeMap()
        .getContentType(file);
  }

  interface AsyncResponse<T> {
    void didRespond(T value);

    void didThrowException(Throwable e);
  }

  private static class Task<T> implements Runnable {
    private final Callable<T> runnable;
    private final AsyncResponse<T> callback;

    private Task(Callable<T> task, AsyncResponse<T> callback) {
      this.runnable = task;
      this.callback = callback;
    }

    @Override
    public void run() {
      try {
        final T value = runnable.call();
        IOLoop.INSTANCE.addCallback(new AsyncCallback() {
          @Override
          public void onCallback() {
            callback.didRespond(value);
          }
        });
      } catch (final Throwable e) {
        IOLoop.INSTANCE.addCallback(new AsyncCallback() {
          @Override
          public void onCallback() {
            callback.didThrowException(e);
          }
        });
      }
    }
  }

  private static <T> void defer(Callable<T> task, AsyncResponse<T> response) {
    if (workers == null) {
      workers = Executors.newFixedThreadPool(NUMBER_OF_WORKERS);
    }
    workers.submit(new Task<T>(task, response));
  }

  public static void setup(Environment environment)
      throws IllegalAccessException, InstantiationException,
      InvocationTargetException {
    ScriptableObject.defineClass(environment.getGlobal(), Request.class);
    ScriptableObject.defineClass(environment.getGlobal(), Response.class);
    ScriptableObject.defineClass(environment.getGlobal(), Server.class);
    ScriptableObject.defineClass(environment.getGlobal(), ClientApp.class);
  }

  private Http() {
  }
}
