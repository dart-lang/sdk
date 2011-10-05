// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools.dartserver;

import com.google.appstack.tools.AwtThumbnailServlet;
import com.google.appstack.tools.ProxyingServlet;
import com.google.appstack.tools.OAuthServlet;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.eclipse.jetty.server.Handler;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.server.Request;
import org.eclipse.jetty.server.handler.AbstractHandler;
import org.eclipse.jetty.server.handler.DefaultHandler;
import org.eclipse.jetty.server.handler.HandlerList;
import org.eclipse.jetty.server.handler.ResourceHandler;
import org.eclipse.jetty.servlet.ServletContextHandler;

import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * A simple HTTP server that automatically trasnlates .dart files into
 * Javascript as they're requested.
 *
 * Should be run from your google3 directory.
 *
 * Example usage:
 *
 * 1. build client @{code [your-client]/client/$ ../tools/build.py}
 *
 * 2. start dartserver @{code [your-client]/client$ tools/dartserver/bin/dartserver}
 * 8007
 *
 * 3. Now, point your browser to this url to verify it's working
 * http://localhost:8007/samples/hello/hello.html
 *
 */
public class DartServer {
  // TODO(jimhug): Merge this with DartCompilerServer under dart project.

  private static Logger logger = Logger.getLogger(DartServer.class.getName());

  public static void main(String[] args) throws Exception {
    if (args.length < 1) {
      throw new RuntimeException("Expected >=1 command line arguments");
    }
    String sourceDir = args[0];
    logger.log(Level.INFO, "Source directory: " + sourceDir);

    int port = args.length > 1 ? Integer.parseInt(args[1]) : 8080;
    Server server = new Server(port);

    ServletContextHandler servletHandler = new ServletContextHandler(
        ServletContextHandler.SESSIONS);
    servletHandler.setContextPath("/");
    servletHandler.addServlet(ProxyingServlet.class, "/mirror");
    servletHandler.addServlet(AwtThumbnailServlet.class, "/thumb");
    servletHandler.addServlet(OAuthServlet.class, "/oauth");

    final ResourceHandler fileServlet = new ResourceHandler();
    fileServlet.setResourceBase(sourceDir);
    fileServlet.setDirectoriesListed(true);
    // Don't let the corp proxy cache content served out of the filesystem,
    // since we expect this may be used by a developer who's modifying it.
    fileServlet.setCacheControl("no-cache");

    HandlerList handlers = new HandlerList();
    handlers.setHandlers(new Handler[] { fileServlet, servletHandler,
        new DartHandler(sourceDir), new DefaultHandler() });
    server.setHandler(handlers);

    System.out.println("Sample dart apps served at:\n" +
                       "http://localhost:" + port + "/samples/");
    server.start();
    server.join();
  }

  /**
   * A handler that uses the dart compiler (dartc) to translate .dart files into
   * Javascript if the uri is a .js or .app file.
   */
  public static class DartHandler extends AbstractHandler {
    String sourceDir;

    public DartHandler(String sourceDir) {
      this.sourceDir = sourceDir;
    }

    @Override
    public void handle(String target, Request baseRequest,
                       HttpServletRequest req, HttpServletResponse rsp) {
      try {
        String uri = req.getRequestURI();
        AppMaker appMaker = AppMaker.create(sourceDir, uri);
        if (appMaker == null) {
          return;
        }
        baseRequest.setHandled(true);
        rsp.setHeader("cache-control", "no-cache");
        logger.info(String.format("generating javascript for '%s'", uri));
        rsp.setContentType("application/javascript");
        rsp.getWriter().write(appMaker.getJavascript());
        rsp.setStatus(HttpServletResponse.SC_OK);
      } catch (Exception e) {
        throw new RuntimeException(e);
      }
    }
  }
}
