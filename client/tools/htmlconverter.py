# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/env python
#

"""Rewrites HTML files, converting Dart script sections into JavaScript.

Process HTML files, and internally changes script sections that use Dart code
into JavaScript sections. It also can optimize the HTML to inline code.
"""

from HTMLParser import HTMLParser
import os.path
from os.path import abspath, basename, dirname, exists, isabs, join
import base64, re, optparse, os, shutil, subprocess, sys, tempfile, codecs
import urllib2

CLIENT_PATH = dirname(dirname(abspath(__file__)))
DART_PATH = dirname(CLIENT_PATH)
TOOLS_PATH = join(DART_PATH, 'tools')

sys.path.append(TOOLS_PATH)
import utils

DART_MIME_TYPE = "application/dart"
LIBRARY_PATTERN = "^#library\(.*\);"
IMPORT_SOURCE_MATCHER = re.compile(
    r"^ *(#import|#source)(\(['\"])([^'\"]*)(.*\);)", re.MULTILINE)
DOM_IMPORT_MATCHER = re.compile(
    r"^#import\(['\"]dart\:dom['\"].*\);", re.MULTILINE)
HTML_IMPORT_MATCHER = re.compile(
    r"^#import\(['\"]dart\:html['\"].*\);", re.MULTILINE)

FROG_NOT_FOUND_ERROR = (
"""Couldn't find compiler: please run the following commands:
   $ cd %s/frog
   $ ./tools/build.py -m release""")

ENTRY_POINT = """
#library('entry');
#import('%s', prefix: 'original');
main() => original.main();
"""

CSS_TEMPLATE = '<style type="text/css">%s</style>'
CHROMIUM_SCRIPT_TEMPLATE = '<script type="application/javascript">%s</script>'

DARTIUM_TO_JS_SCRIPT = """
<script type="text/javascript">
 (function() {
   // Let the user know that Dart is required.
   if (!window.navigator.webkitStartDart) {
     if (confirm(
         "You are trying to run Dart code on a browser " +
         "that doesn't support Dart. Do you want to redirect to " +
         "a version compiled to JavaScript instead?")) {
       var addr = window.location;
       window.location = addr.toString().replace('-dart.html', '-js.html');
     }
  } else {
    window.navigator.webkitStartDart();
  }
})();
</script>
"""

def adjustImports(contents):
  def repl(matchobj):
    path = matchobj.group(3)
    if not path.startswith('dart:'):
      path = abspath(path)
    return (matchobj.group(1) + matchobj.group(2) + path + matchobj.group(4))
  return IMPORT_SOURCE_MATCHER.sub(repl, contents)

class DartCompiler(object):
  """ Common code for compiling Dart script tags in an HTML file. """

  def __init__(self, verbose=False,
      extra_flags=""):
    self.verbose = verbose
    self.extra_flags = extra_flags

  def compileCode(self, src=None, body=None):
    """ Compile the given source code.

      Either the script tag has a src attribute or a non-empty body (one of the
      arguments will be none, the other is not).

      Args:
        src: a string pointing to a Dart script file.
        body: a string containing Dart code.
    """

    outdir = tempfile.mkdtemp()
    indir = None
    useDartHtml = False
    if src is not None:
      if body is not None and body.strip() != '':
        raise ConverterException(
            "The script body should be empty if src is specified")
      elif src.endswith('.dart'):
        indir = tempfile.mkdtemp()
        inputfile = abspath(src)
        with open(inputfile, 'r') as f:
          contents = f.read();

        if HTML_IMPORT_MATCHER.search(contents):
          useDartHtml = True

        # We will import the source file to emulate in JS that code is run after
        # DOMContentLoaded. We need a #library to ensure #import won't fail:
        if not re.search(LIBRARY_PATTERN, contents, re.MULTILINE):
          inputfile = join(indir, 'code.dart')
          with open(inputfile, 'w') as f:
            f.write("#library('code');")
            f.write(adjustImports(contents))

      else:
        raise ConverterException("invalid file type:" + src)
    else:
      if body is None or body.strip() == '':
        # nothing to do
        print 'Warning: empty script tag with no src attribute'
        return ''

      indir = tempfile.mkdtemp()
      # eliminate leading spaces in front of directives
      body = adjustImports(body)

      if HTML_IMPORT_MATCHER.search(body):
        useDartHtml = True

      inputfile = join(indir, 'code.dart')
      with open(inputfile, 'w') as f:
        f.write("#library('inlinedcode');\n")
        f.write(body)

    wrappedfile = join(indir, 'entry.dart')
    with open(wrappedfile, 'w') as f:
      f.write(ENTRY_POINT % inputfile)

    status, out, err = execute(self.compileCommand(wrappedfile, outdir),
                               self.verbose)
    if status:
      raise ConverterException('compilation errors')

    # Inline the compiled code in the page
    with open(self.outputFileName(wrappedfile, outdir), 'r') as f:
      res = f.read()

    # Cleanup
    if indir is not None:
      shutil.rmtree(indir)
    shutil.rmtree(outdir)
    return CHROMIUM_SCRIPT_TEMPLATE % res

  def compileCommand(self, inputfile, outdir):
    binary = abspath(join(DART_PATH,
                          utils.GetBuildRoot(utils.GuessOS(),
                                             'release', 'ia32'),
                          'frog', 'bin', 'frogsh'))
    if not exists(binary):
      raise ConverterException(FROG_NOT_FOUND_ERROR % DART_PATH)

    cmd = [binary, '--compile-only',
           '--libdir=' + join(DART_PATH, 'frog', 'lib'),
           '--out=' + self.outputFileName(inputfile, outdir)]
    if self.extra_flags != "":
      cmd.append(self.extra_flags);
    cmd.append(inputfile)
    return cmd

  def outputFileName(self, inputfile, outdir):
    return join(outdir, basename(inputfile) + '.js')

def execute(cmd, verbose=False):
  """Execute a command in a subprocess. """
  if verbose: print 'Executing: ' + ' '.join(cmd)
  try:
    pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = pipe.communicate()
    if pipe.returncode != 0:
      print 'Execution failed: ' + output + '\n' + err
    if verbose or pipe.returncode != 0:
      print output
      print err
    return pipe.returncode, output, err
  except Exception as e:
    print 'Exception when executing: ' + ' '.join(cmd)
    print e
    return 1, None, None


def convertPath(project_path, prefix_path):
  """ Convert a project path (whose root corresponds to the current working
      directory) to a system path.
      Args:
        - project_path: path in the project context.
        - prefix_path: prefix for relative paths.
  """
  if isabs(project_path):
    # TODO(sigmund): add a flag to pass in the root-level for absolute paths.
    return project_path[1:]
  elif not (project_path.startswith('http://') or
            project_path.startswith('https://')):
    return join(prefix_path, project_path)
  else:
    return project_path

def encodeImage(rootDir, filename):
  """ Returns a base64 url encoding for an image """
  filetype = filename[-3:]
  if filetype == 'svg': filetype = 'svg+xml'
  with open(join(rootDir, filename), 'r') as f:
    return 'url(data:image/%s;charset=utf-8;base64,%s)' % (
            filetype,
            base64.b64encode(f.read()))

def processCss(filename):
  """ Reads and converts a css file by replacing all image refernces into
      base64 encoded images.
  """
  css = open(filename, 'r').read()
  cssDir = os.path.split(filename)[0]
  def transformUrl(match):
    imagefile = match.group(1)
    # if the image is not local or can't be found, leave the url alone:
    if (imagefile.startswith('http://')
        or imagefile.startswith('https://')
        or not exists(join(cssDir, imagefile))):
      return match.group(0)
    return encodeImage(cssDir, imagefile)

  pattern = 'url\((.*\.(svg|png|jpg|gif))\)'
  return re.sub(pattern, transformUrl, css)

class DartHTMLConverter(HTMLParser):
  """ An HTML processor that inlines css and compiled dart code.

    Args:
    - compiler: an implementation of DartAnyCompiler
    - prefix_path: prefix for relative paths encountered in the HTML.
  """
  def __init__(self, compiler, prefix_path):
    HTMLParser.__init__(self)
    self.in_dart_tag = False
    self.output = []
    self.dart_inline_code = []
    self.contains_dart = False
    self.compiler = compiler
    self.prefix_path = prefix_path

  def inlineCss(self, attrDic):
      path = convertPath(attrDic['href'], self.prefix_path)
      self.output.append(CSS_TEMPLATE % processCss(path))

  def compileScript(self, attrDic):
    if 'src' in attrDic:
      self.output.append(self.compiler.compileCode(
          src=convertPath(attrDic.pop('src'), self.prefix_path),
          body=None))
    else:
      self.in_dart_tag = True
      # no tag is generated until we parse the body of the tag
      self.dart_inline_code = []
    return True

  def convertImage(self, attrDic):
    pass

  def starttagHelper(self, tag, attrs, isEnd):
    attrDic = dict(attrs)

    # collect all script files, and generate a single script before </body>
    if (tag == 'script' and 'type' in attrDic
        and (attrDic['type'] == DART_MIME_TYPE)):
      if self.compileScript(attrDic):
        return

    # convert css imports into inlined css
    elif (tag == 'link' and
          'rel' in attrDic and attrDic['rel'] == 'stylesheet' and
          'type' in attrDic and attrDic['type'] == 'text/css' and
          'href' in attrDic):
      self.inlineCss(attrDic)
      return

    elif tag == 'img' and 'src' in attrDic:
      self.convertImage(attrDic)

    # emit everything else as in the input
    self.output.append('<%s%s%s>' % (
        tag + (' ' if len(attrDic) else ''),
        ' '.join(['%s="%s"' % (k, attrDic[k]) for k in attrDic]),
        '/' if isEnd else ''))

  def handle_starttag(self, tag, attrs):
    self.starttagHelper(tag, attrs, False)

  def handle_startendtag(self, tag, attrs):
    self.starttagHelper(tag, attrs, True)

  def handle_data(self, data):
    if self.in_dart_tag:
      # collect the dart source code and compile it all at once when no more
      # script tags can be included. Note: the code will anyways start on
      # DOMContentLoaded, so moving the script is OK.
      self.dart_inline_code.append(data)
    else:
      self.output.append(data),

  def handle_endtag(self, tag):
    if tag == 'script' and self.in_dart_tag:
      self.in_dart_tag = False
      self.output.append(self.compiler.compileCode(
          src=None, body='\n'.join(self.dart_inline_code)))
    else:
      self.output.append('</%s>' % tag)

  def handle_charref(self, ref):
    self.output.append('&#%s;' % ref)

  def handle_entityref(self, name):
    self.output.append('&%s;' % name)

  def handle_comment(self, data):
    self.output.append('<!--%s-->' % data)

  def handle_decl(self, decl):
    self.output.append('<!%s>' % decl)

  def unknown_decl(self, data):
    self.output.append('<!%s>' % data)

  def handle_pi(self, data):
    self.output.append('<?%s>' % data)

  def getResult(self):
    return ''.join(self.output)


class DartToDartHTMLConverter(DartHTMLConverter):
  def __init__(self, prefix_path, outdir, verbose):
    # Note: can't use super calls because HTMLParser is not a subclass of object
    DartHTMLConverter.__init__(self, None, prefix_path)
    self.outdir = outdir
    self.verbose = verbose

  def compileScript(self, attrDic):
    self.contains_dart = True
    if 'src' in attrDic:
      status, out, err = execute([
          sys.executable,
          join(DART_PATH, 'tools', 'copy_dart.py'),
          self.outdir,
          convertPath(attrDic['src'], self.prefix_path)],
          self.verbose)

      if status:
        raise ConverterException('exception calling copy_dart.py')

    # do not rewrite the script tag
    return False

  def handle_endtag(self, tag):
    if tag == 'body' and self.contains_dart:
      self.output.append(DARTIUM_TO_JS_SCRIPT)
    DartHTMLConverter.handle_endtag(self, tag)

# A data URL for a blank 1x1 PNG.  The PNG's data is from
#   convert -size 1x1 +set date:create +set date:modify \
#     xc:'rgba(0,0,0,0)' 1x1.png
#   base64.b64encode(open('1x1.png').read())
# (The +set stuff is because just doing "-strip" apparently doesn't work;
# it leaves several info chunks resulting in a 224-byte PNG.)
BLANK_IMAGE_BASE64_URL = 'data:image/png;charset=utf-8;base64,%s' % (
    ('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABEAQAAADljNBBAAAAAmJLR0T//xSrMc0AAAAJc'
     'EhZcwAAAEgAAABIAEbJaz4AAAAJdnBBZwAAAAEAAAABAMeVX+0AAAANSURBVAjXY2BgYG'
     'AAAAAFAAFe8yo6AAAAAElFTkSuQmCC'))

class OfflineHTMLConverter(DartHTMLConverter):
  def __init__(self, prefix_path, outdir, verbose, inline_images):
    # Note: can't use super calls because HTMLParser is not a subclass of object
    DartHTMLConverter.__init__(self, None, prefix_path)
    self.outdir = outdir
    self.verbose = verbose
    self.inline_images = inline_images  # Inline as data://, vs. use local file.

  def compileScript(self, attrDic):
    # do not rewrite the script tag
    return False

  def downloadImageUrlToEncode(self, url):
    """ Downloads an image and returns a base64 url encoding for it.
    May throw if the download fails.
    """
    # Don't try to re-encode an image that's already data://.
    filetype = url[-3:]
    if filetype == 'svg': filetype = 'svg+xml'
    if self.verbose:
      print 'Downloading ' + url
    f = urllib2.urlopen(url)

    return 'data:image/%s;charset=utf-8;base64,%s' % (
        filetype,
        base64.b64encode(f.read()))

  def downloadImageUrlToFile(self, url):
    """Downloads an image and returns the filename.  May throw if the
    download fails.
    """
    extension = os.path.splitext(url)[1]
    # mkstemp() happens to work to create a non-temporary, so we use it.
    filename = tempfile.mkstemp(extension, 'img_', self.prefix_path)[1]
    if self.verbose:
      print 'Downloading %s to %s' % (url, filename)
    writeOut(urllib2.urlopen(url).read(), filename)
    return os.path.join(self.prefix_path, os.path.basename(filename))

  def downloadImage(self, url):
    """Downloads an image either to file or to data://, and return the URL."""
    if url.startswith('data:image/'):
      return url
    try:
      if self.inline_images:
        return self.downloadImageUrlToEncode(url)
      else:
        return self.downloadImageUrlToFile(url)
    except:
      print '*** Image download failed: %s' % url
      return BLANK_IMAGE_BASE64_URL

  def convertImage(self, attrDic):
    attrDic['src'] = self.downloadImage(attrDic['src'])

def safeMakeDirs(dirname):
  """ Creates a directory and, if necessary its parent directories.

  This function will safely return if other concurrent jobs try to create the
  same directory.
  """
  if not exists(dirname):
    try:
      os.makedirs(dirname)
    except Exception:
      # this check allows invoking this script concurrently in many jobs
      if not exists(dirname):
        raise

class ConverterException(Exception):
  """ An exception encountered during the convertion process """
  pass

def Flags():
  """ Constructs a parser for extracting flags from the command line. """
  result = optparse.OptionParser()
  result.add_option("--verbose",
      help="Print verbose output",
      default=False,
      action="store_true")
  result.add_option("-o", "--out",
      help="Output directory",
      type="string",
      default=None,
      action="store")
  result.add_option("-t", "--target",
      help="The target html to generate",
      metavar="[js,chromium,dartium]",
      default='chromium')
  result.add_option("--extra-flags",
      help="Extra flags for dartc",
      type="string",
      default="")
  result.set_usage("htmlconverter.py input.html -o OUTDIR")
  return result

def writeOut(contents, filepath):
  """ Writes contents to a file, ensuring that the output directory exists. """
  safeMakeDirs(dirname(filepath))
  with open(filepath, 'w') as f:
    f.write(contents)
  print "Generated output in: " + abspath(filepath)

def convertForDartium(filename, outdirBase, outfile, verbose):
  """ Converts a file for a dartium target. """
  with open(filename, 'r') as f:
    contents = f.read()
  prefix_path = dirname(filename)

  # outdirBase is the directory to place all subdirectories for other dart files
  # and resources.
  converter = DartToDartHTMLConverter(prefix_path, outdirBase, verbose)
  converter.feed(contents)
  converter.close()
  writeOut(converter.getResult(), outfile)

def convertForChromium(
    filename, extra_flags, outfile, verbose):
  """ Converts a file for a chromium target. """
  with open(filename, 'r') as f:
    contents = f.read()
  prefix_path = dirname(filename)
  converter = DartHTMLConverter(
      DartCompiler(verbose, extra_flags), prefix_path)
  converter.feed(contents)
  converter.close()
  writeOut(converter.getResult(), outfile)

def convertForOffline(filename, outfile, verbose, encode_images):
  """ Converts a file for offline use. """
  with codecs.open(filename, 'r', 'utf-8') as f:
    contents = f.read()
  converter = OfflineHTMLConverter(dirname(filename),
                                   dirname(outfile),
                                   verbose,
                                   encode_images)
  converter.feed(contents)
  converter.close()

  contents = converter.getResult()
  safeMakeDirs(dirname(outfile))
  with codecs.open(outfile, 'w', 'utf-8') as f:
    f.write(contents)
  print "Generated output in: " + abspath(outfile)

RED_COLOR = "\033[31m"
NO_COLOR = "\033[0m"

def main():
  parser = Flags()
  options, args = parser.parse_args()
  if len(args) < 1 or not options.out or not options.target:
    parser.print_help()
    return 1

  try:
    filename = args[0]
    extension = filename[filename.rfind('.'):]
    if extension != '.html' and extension != '.htm':
      print "Invalid input file extension: %s" % extension
      return 1
    outfile = join(options.out, filename)
    if 'chromium' in options.target or 'js' in options.target:
      convertForChromium(filename,
          options.extra_flags,
          outfile.replace(extension, '-js' + extension), options.verbose)
    if 'dartium' in options.target:
      convertForDartium(filename, options.out,
          outfile.replace(extension, '-dart' + extension), options.verbose)
  except Exception as e:
    print "%sERROR%s: %s" % (RED_COLOR, NO_COLOR, str(e))
    return 1
  return 0

if __name__ == '__main__':
  sys.exit(main())
