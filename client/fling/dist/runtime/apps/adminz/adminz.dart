// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void XhrCallback(XMLHttpRequest xhr);

class Xhr {
  static void post(Window window, String url, String data, String contentType,
      XhrCallback onSuccess, XhrCallback onFailure) {
    _request(window, 'POST', url, data, contentType, onSuccess, onFailure);
  }

  static void _request(Window window, String method, String url, String data,
      String contentType, XhrCallback onSuccess, XhrCallback onFailure) {
    // TODO(knorton): Catch exceptions.
    final xhr = new XMLHttpRequest();
    xhr.onreadystatechange = () {
      if (xhr.readyState != 4)
        return;

      xhr.onreadystatechange = null;
      if (xhr.status == 200) {
        if (onSuccess != null)
          onSuccess(xhr);
      } else {
        if (onFailure != null)
          onFailure(xhr);
      }
    };
    xhr.open(method, url, true);
    if (contentType == null) {
      xhr.setRequestHeader('Content-Type', contentType);
    }
    // TODO(knorton): This is a problem with dart_dom bindings. A fix will arrive
    // soon.
    // xhr.send(data);
    xhr.send(null);
  }
}

typedef void Callback();
class Poller {
  Window window;
  String prefix;
  Callback onSuccess;

  Poller(Window this.window, String this.prefix, Callback this.onSuccess) { }

  void schedule() {
    window.setTimeout(() {
      print('Pinging...');
      Xhr.post(window, prefix.concat('/ping'), null, null,
        (XMLHttpRequest xhr) {
          if (xhr.responseText == '{"status" : "si"}') {
            onSuccess();
            return;
          }
          schedule();
        },
        (XMLHttpRequest xhr) {
          schedule();
        });
    }, 1000 /* ms */);
  }

  static void wait(Window window, String prefix, Callback onSuccess) {
    new Poller(window, prefix, onSuccess).schedule();
  }
}

class Adminz {
  Window window;
  Document document;

  Element notify;
  Element status;
  String prefix;

  Adminz(Window this.window, Document this.document, String this.prefix) { }

  void refresh() {
    if (notify != null)
      return;

    // Put up refresh UI.
    notify = document.createElement('div');
    status = document.createElement('div');

    notify.style.cssText = 'position:absolute;left:0;right:0;bottom:0;z-index:10000;background:#000;opacity:0.8;height:0;-webkit-transition:height 300ms ease-in-out;';
    status.style.cssText = 'padding:20px 40px;color:#fff;font-family:Helvetica,Arial;font-size:24pt;';
    status.text = 'server is restarting';
    notify.nodes.add(status);
    document.body.nodes.add(notify);

    notify.style.setProperty('height', status.offsetHeight.toString().concat('px'));

    print(prefix);
    Xhr.post(window, prefix.concat('/refresh'), null, null,
      (XMLHttpRequest xhr) {
        print(xhr);
      }, null);

    print('Beging polling...');
    Poller.wait(window, prefix, () {
      status.text = 'done';
      window.location.reload(true);
    });
  }

  static void attach(Window window, Document document) {
    String prefix = _getPrefix(window);
    if (prefix == null)
      return;

    Adminz a = new Adminz(window, document, prefix);
    document.on.keyDown.add((MouseEvent event) {
      if (event.ctrlKey && event.keyCode == 88 /* x */) {
        a.refresh();
        return;
      }
      print(event);
    }, true);
  }

  static String _getPrefix(Window window) {
    Document document = window.document;
    String name = '/Adminz.app';
    NodeList items = document.queryAll('script');
    for (int i = 0, n = items.length; i < n; ++i) {
      ScriptElement s = items[i];
      String src = s.src;
      if (src.endsWith(name))
        return src.substring(0, src.length - name.length);
    }
    window.console.warn('Adminz was unable find itself in the DOM :-(');
    return null;
  }

  static void main() {
    Adminz.attach(window, window.document);
  }
}
