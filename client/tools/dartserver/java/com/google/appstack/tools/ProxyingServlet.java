// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.logging.Logger;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Simple Servlet that is used to allow clients to connect to
 * many different data sources ignoring the single origin
 * restrictions on XMLHttpRequest.  This servlet will take
 * in a cross-site request as a query string and send it along
 * to the desired URL.
 */
public class ProxyingServlet extends HttpServlet {
  private static final int BUFFER_SIZE = 4096;

  private static Logger logger =
    Logger.getLogger(ProxyingServlet.class.getName());

  @Override
  public void service(HttpServletRequest req, HttpServletResponse rsp) {
    try {
      logger.info(String.format("redirect to '%s'", req.getQueryString()));
      URL url = new URL(req.getQueryString());
      HttpURLConnection con = (HttpURLConnection) url.openConnection();
      // TODO(jimhug): Figure out which other headers to propagate.
      con.setRequestMethod(req.getMethod());
      con.connect();
      rsp.setContentType(con.getContentType());
      /*
        Map<String,List<String>> headers = con.getHeaderFields();
        for (Map.Entry<String, List<String>> entry : headers.entrySet()) {
        for (String value : entry.getValue()) {
        if (entry.getKey() == null || value == null) continue;
        rsp.addHeader(entry.getKey(), value);
        }
        }
      */

      // TODO(jimhug): Better error handling.
      // TODO(jimhug): Use com.google.common.io.ByteStreams.copy(is, os) -
      //   as soon as we get another call to justify Guava dependency.
      InputStream is = con.getInputStream();
      OutputStream os = rsp.getOutputStream();
      byte[] b = new byte[BUFFER_SIZE];
      while (true) {
        int n = is.read(b);
        if (n == -1) {
          break;
        }
        os.write(b, 0, n);
      }
      rsp.setStatus(con.getResponseCode());
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
}
