// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Resource {
  /* patch */ const factory Resource(String uri) = _Resource;
}

class _Resource implements Resource {
  final String _location;

  const _Resource(this._location);

  Uri get uri => Uri.base.resolve(_location);

  Stream<List<int>> openRead() {
    if (VMLibraryHooks.resourceReadAsBytes == null) {
      throw new UnimplementedError("openRead");
    }

    var controller = new StreamController<List<int>>();
    // We only need to implement the listener as there is no way to provide
    // back pressure into the channel.
    controller.onListen = () {
      // Once there is a listener, we kick off the loading of the resource.
      readAsBytes().then((value) {
        // The resource loading implementation sends all of the data in a
        // single message. So the stream will only get a single value posted.
        controller.add(value);
        controller.close();
      },
      onError: (e, s) {
        // In case the future terminates with an error we propagate it to the
        // stream.
        controller.addError(e, s);
        controller.close();
      });
    };

    return controller.stream;
  }

  Future<List<int>> readAsBytes() {
    if (VMLibraryHooks.resourceReadAsBytes == null) {
      throw new UnimplementedError("readAsBytes");
    }

    return VMLibraryHooks.resourceReadAsBytes(this.uri);
  }

  Future<String> readAsString({Encoding encoding : UTF8}) {
    if (VMLibraryHooks.resourceReadAsBytes == null) {
      throw new UnimplementedError("readAsString");
    }

    var completer = new Completer<String>();

    readAsBytes().then((bytes) {
      var str = encoding.decode(bytes);
      completer.complete(str);
    },
    onError: (e, s) {
      completer.completeError(e,s);
    });

    return completer.future;
  }
}
