// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';

class CustomUriResolver extends UriResolver {
  final ResourceProvider resourceProvider;
  final Map<String, String> _urlMappings;

  CustomUriResolver(this.resourceProvider, this._urlMappings);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    String mapping = _urlMappings[uri.toString()];
    if (mapping == null) {
      return null;
    }
    Uri fileUri = new Uri.file(mapping);
    if (!fileUri.isAbsolute) {
      return null;
    }
    return resourceProvider
        .getFile(resourceProvider.pathContext.fromUri(fileUri))
        .createSource(actualUri ?? uri);
  }
}
