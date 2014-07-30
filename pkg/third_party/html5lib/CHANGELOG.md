# changelog

This file contains highlights of what changes on each version of the html5lib
package.

#### Pub version 0.11.0+2
  * expand the version constraint for csslib.

#### Pub version 0.10.0+1
  * use a more recent source_maps version.

#### Pub version 0.10.0
  * fix how document fragments are added in NodeList.add/addAll/insertAll.

#### Pub version 0.9.2-dev
  * add Node.text, Node.append, Document.documentElement
  * add Text.data, deprecate Node.value and Text.value.
  * deprecate Node.$dom_nodeType
  * added querySelector/querySelectorAll, deprecated query/queryAll.
    This matches the current APIs in dart:html.
