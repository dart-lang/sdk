# Content-shell resources

The layout tests of content_shell (formerly called DumpRenderTree, drt)
require a font called AHEM____.TTF on Windows. This resource is downloaded
from cloud storage, using the hash in AHEM____.TTF.sha1, by a hook
in the DEPS file, that is run by gclient sync or gclient runhooks.
