// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools;

import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Delegate all Google API requests.  The query paramter api has the complete
 * API url and form data to forward the request.  The first parameter of the
 * encoded URI (api parameter) must have the ?oauth_token= for the API request
 * to work.  Tested with OAuth2.
 */
public class OAuthServlet extends HttpServlet {
  private static final int BUFFER_SIZE = 8192;

  private static Logger logger =
    Logger.getLogger(OAuthServlet.class.getName());

  @Override
  public void service(HttpServletRequest req, HttpServletResponse resp) {
    String api = req.getParameter("api");
    if (api == null) {
      // TODO(terry): Better error handling.
      throw new RuntimeException("Missing api parameter.");
    }

    HttpURLConnection con = null;
    InputStream is = null;
    OutputStream os = null;

    try {
      // Decode the URI passed in the query parameter.
      URL url = new URI(api).toURL();

      logger.info(String.format("api URL = %s", url.toString()));

      con = (HttpURLConnection) url.openConnection();

      con.setRequestMethod(req.getMethod());
      if (req.getMethod().equals("POST")) {

        con.setRequestProperty("Content-Type",
            "application/x-www-form-urlencoded");
        con.setRequestProperty("Content-Language", "en-US");  

      }

      con.connect();

      resp.setContentType(con.getContentType());

      is = con.getInputStream();
      os = resp.getOutputStream();
      byte[] b = new byte[BUFFER_SIZE];
      while (true) {
        int n = is.read(b);
        if (n == -1) {
          break;
        }
        os.write(b, 0, n);
      }

      resp.setStatus(con.getResponseCode());
    }  catch (Exception e) {
      // TODO(terry): Better error handling.
      logger.log(Level.SEVERE, "Unexpected error", e);
    } finally {
      try {
        if (os != null) {
          os.close();
        }
        if (is != null) {
          is.close();
        }

        if (con != null) {
          con.disconnect();
        }
      } catch (java.io.IOException ioe) {
        // TODO(terry): Better error handling.
        logger.log(Level.SEVERE, "Close/Disconnect error", ioe);
      }
    }
  }
}

