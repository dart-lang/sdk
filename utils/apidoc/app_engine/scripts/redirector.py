# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import webapp2

class DomRedirectPage(webapp2.RequestHandler):
  def get(self):
    if self.request.path == '/dom.html':
      self.redirect('/html.html', permanent=True)
      return

    url = self.request.path[4:len(self.request.path)]
    self.redirect('/html' + url, permanent=True)

application = webapp2.WSGIApplication(
                                     [('/dom.*', DomRedirectPage)],
                                     debug=True)

