#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# A script to generate a windows installer for the editor bundle.
# As input the script takes a zip file, a version and the location
# to store the resulting msi file in.
#
# Usage: ./tools/create_windows_installer.py --version <version>
#            --zip_file_location <zip_file> --msi_location <output>
#            [--wix_bin <wix_bin_location>]
#            [--print_wxs]
#
# This script assumes that wix is either in path or passed in as --wix_bin.
# You can get wix from http://wixtoolset.org/.

import optparse
import os
import subprocess
import sys
import utils
import zipfile

# This should _never_ change, please don't change this value.
UPGRADE_CODE = '7bacdc33-2e76-4f36-a206-ea58220c0b44'

# The content of the xml
xml_content = []

# The components we want to add to our feature.
feature_components = []

# Indentation level, each level is indented 2 spaces
current_indentation = 0

def GetOptions():
  options = optparse.OptionParser(usage='usage: %prog [options]')
  options.add_option("--zip_file_location",
      help='Where the zip file including the editor is located.')
  options.add_option("--input_directory",
      help='Directory where all the files needed is located.')
  options.add_option("--msi_location",
      help='Where to store the resulting msi.')
  options.add_option("--version",
      help='The version specified as Major.Minor.Build.Patch.')
  options.add_option("--wix_bin",
      help='The location of the wix binary files.')
  options.add_option("--print_wxs", action="store_true", dest="print_wxs",
                    default=False,
                    help="Prints the generated wxs to stdout.")
  (options, args) = options.parse_args()
  if len(args) > 0:
    raise Exception("This script takes no arguments, only options")
  ValidateOptions(options)
  return options

def ValidateOptions(options):
  if not options.version:
    raise Exception('You must supply a version')
  if options.zip_file_location and options.input_directory:
    raise Exception('Please pass either zip_file_location or input_directory')
  if not options.zip_file_location and not options.input_directory:
    raise Exception('Please pass either zip_file_location or input_directory')
  if (options.zip_file_location and
      not os.path.isfile(options.zip_file_location)):
    raise Exception('Passed in zip file not found')
  if (options.input_directory and
      not os.path.isdir(options.input_directory)):
    raise Exception('Passed in directory not found')

def GetInputDirectory(options, temp_dir):
  if options.zip_file_location:
    ExtractZipFile(options.zip_file_location, temp_dir)
    return os.path.join(temp_dir, 'dart')
  return options.input_directory

# We combine the build and patch into a single entry since
# the windows installer does _not_ consider a change in Patch
# to require a new install.
# In addition to that, the limits on the size are:
# Major: 256
# Minor: 256
# Patch: 65536
# To circumvent this we create the version like this:
#   Major.Minor.X
# from "major.minor.patch-prerelease.prerelease_patch"
# where X is "patch<<10 + prerelease<<5 + prerelease_patch"
# Example version 1.2.4-dev.2.3 will go to 1.2.4163
def GetMicrosoftProductVersion(version):
  version_parts = version.split('.')
  if len(version_parts) is not 5:
    raise Exception(
      "Version string (%s) does not follow specification" % version)
  (major, minor, patch, prerelease, prerelease_patch) = map(int, version_parts)

  if major > 255 or minor > 255:
    raise Exception('Major/Minor can not be above 256')
  if patch > 63:
    raise Exception('Patch can not be above 63')
  if prerelease > 31:
    raise Exception('Prerelease can not be above 31')
  if prerelease_patch > 31:
    raise Exception('PrereleasePatch can not be above 31')

  combined = (patch << 10) + (prerelease << 5) + prerelease_patch
  return '%s.%s.%s' % (major, minor, combined)

# Append using the current indentation level
def Append(data, new_line=True):
  str = (('  ' * current_indentation) +
         data +
         ('\n' if new_line else ''))
  xml_content.append(str)

# Append without any indentation at the current position
def AppendRaw(data, new_line=True):
  xml_content.append(data + ('\n' if new_line else ''))

def AppendComment(comment):
  Append('<!--%s-->' % comment)

def AppendBlankLine():
  Append('')

def GetContent():
  return ''.join(xml_content)

def XmlHeader():
  Append('<?xml version="1.0" encoding="UTF-8"?>')

def TagIndent(str, indentation_string):
  return ' ' * len(indentation_string) + str

def IncreaseIndentation():
  global current_indentation
  current_indentation += 1

def DecreaseIndentation():
  global current_indentation
  current_indentation -= 1

class WixAndProduct(object):
  def __init__(self, version):
    self.version = version
    self.product_name = 'Dart Editor'
    self.manufacturer = 'Google Inc.'
    self.upgrade_code = UPGRADE_CODE

  def __enter__(self):
    self.start_wix()
    self.start_product()

  def __exit__(self, *_):
    self.close_product()
    self.close_wix()

  def get_product_id(self):
    # This needs to change on every install to guarantee that
    # we get a full uninstall + reinstall
    # We let wix choose. If we need to do patch releases later on
    # we need to retain the value over several installs.
    return '*'

  def start_product(self):
    product = '<Product '
    Append(product, new_line=False)
    AppendRaw('Id="%s"' % self.get_product_id())
    Append(TagIndent('Version="%s"' % self.version, product))
    Append(TagIndent('Name="%s"' % self.product_name, product))
    Append(TagIndent('UpgradeCode="%s"' % self.upgrade_code,
                     product))
    Append(TagIndent('Language="1033"', product))
    Append(TagIndent('Manufacturer="%s"' % self.manufacturer,
                     product),
           new_line=False)
    AppendRaw('>')
    IncreaseIndentation()

  def close_product(self):
    DecreaseIndentation()
    Append('</Product>')

  def start_wix(self):
    Append('<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">')
    IncreaseIndentation()

  def close_wix(self):
    DecreaseIndentation()
    Append('</Wix>')

class Directory(object):
  def __init__(self, id, name=None):
    self.id = id
    self.name = name

  def __enter__(self):
    directory = '<Directory '
    Append(directory, new_line=False)
    AppendRaw('Id="%s"' % self.id, new_line=self.name is not None)
    if self.name:
      Append(TagIndent('Name="%s"' % self.name, directory), new_line=False)
    AppendRaw('>')
    IncreaseIndentation()

  def __exit__(self, *_):
    DecreaseIndentation()
    Append('</Directory>')

class Component(object):
  def __init__(self, id):
    self.id = 'CMP_%s' % id

  def __enter__(self):
    component = '<Component '
    Append(component, new_line=False)
    AppendRaw('Id="%s"' % self.id)
    Append(TagIndent('Guid="*">', component))
    IncreaseIndentation()

  def __exit__(self, *_):
    DecreaseIndentation()
    Append('</Component>')
    feature_components.append(self.id)

class Feature(object):
  def __enter__(self):
    feature = '<Feature '
    Append(feature, new_line=False)
    AppendRaw('Id="MainFeature"')
    Append(TagIndent('Title="Dart Editor"', feature))
    # Install by default
    Append(TagIndent('Level="1">', feature))
    IncreaseIndentation()

  def __exit__(self, *_):
    DecreaseIndentation()
    Append('</Feature>')

def Package():
  package = '<Package '
  Append(package, new_line=False)
  AppendRaw('InstallerVersion="301"')
  Append(TagIndent('Compressed="yes" />', package))

def MediaTemplate():
  Append('<MediaTemplate EmbedCab="yes" />')

def File(name, id):
  file = '<File '
  Append(file, new_line=False)
  AppendRaw('Id="FILE_%s"' % id)
  Append(TagIndent('Source="%s"' % name, file))
  Append(TagIndent('KeyPath="yes" />', file))

def Shortcut(id, name, ref):
  shortcut = '<Shortcut '
  Append(shortcut, new_line=False)
  AppendRaw('Id="%s"' % id)
  Append(TagIndent('Name="%s"' % name, shortcut))
  Append(TagIndent('Target="%s" />' % ref, shortcut))

def RemoveFolder(id):
  remove = '<RemoveFolder '
  Append(remove, new_line=False)
  AppendRaw('Id="%s"' % id)
  Append(TagIndent('On="uninstall" />', remove))

def RegistryEntry(location):
  registry = '<RegistryValue '
  Append(registry, new_line=False)
  AppendRaw('Root="HKCU"')
  Append(TagIndent('Key="Software\\Microsoft\\%s"' % location, registry))
  Append(TagIndent('Name="installed"', registry))
  Append(TagIndent('Type="integer"', registry))
  Append(TagIndent('Value="1"', registry))
  Append(TagIndent('KeyPath="yes" />', registry))


def MajorUpgrade():
  upgrade = '<MajorUpgrade '
  Append(upgrade, new_line=False)
  down_message = 'You already have a never version installed.'
  AppendRaw('DowngradeErrorMessage="%s" />' % down_message)


# This is a very simplistic id generation.
# Unfortunately there is no easy way to generate good names,
# since there is a 72 character limit, and we have way longer
# paths. We don't really have an issue with files and ids across
# releases since we do full installs.
counter = 0
def FileToId(name):
  global counter
  counter += 1
  return '%s' % counter

def ListFiles(path):
  for entry in os.listdir(path):
    full_path = os.path.join(path, entry)
    id = FileToId(full_path)
    if os.path.isdir(full_path):
      with Directory('DIR_%s' % id, entry):
        ListFiles(full_path)
    elif os.path.isfile(full_path):
      # We assume 1 file per component, a File is always a KeyPath.
      # A KeyPath on a file makes sure that we can always repair and
      # remove that file in a consistent manner. A component
      # can only have one child with a KeyPath.
      with Component(id):
        File(full_path, id)

def ComponentRefs():
  for component in feature_components:
    Append('<ComponentRef Id="%s" />' % component)

def ExtractZipFile(zip, temp_dir):
  print 'Extracting files'
  f = zipfile.ZipFile(zip)
  f.extractall(temp_dir)
  f.close()

def GenerateInstaller(wxs_content, options, temp_dir):
  wxs_file = os.path.join(temp_dir, 'installer.wxs')
  wixobj_file = os.path.join(temp_dir, 'installer.wixobj')
  print 'Saving wxs output to: %s' % wxs_file
  with open(wxs_file, 'w') as f:
    f.write(wxs_content)

  candle_bin = 'candle.exe'
  light_bin = 'light.exe'
  if options.wix_bin:
    candle_bin = os.path.join(options.wix_bin, 'candle.exe')
    light_bin = os.path.join(options.wix_bin, 'light.exe')
  print 'Calling candle on %s' % wxs_file
  subprocess.check_call('%s %s -o %s' % (candle_bin, wxs_file,
                                         wixobj_file))
  print 'Calling light on %s' % wixobj_file
  subprocess.check_call('%s %s -o %s' % (light_bin, wixobj_file,
                                         options.msi_location))
  print 'Created msi file to %s' % options.msi_location


def Main(argv):
  if sys.platform != 'win32':
    raise Exception("This script can only be run on windows")
  options = GetOptions()
  version = GetMicrosoftProductVersion(options.version)
  with utils.TempDir('installer') as temp_dir:
    input_location = GetInputDirectory(options, temp_dir)
    print "Generating wix XML"
    XmlHeader()
    with WixAndProduct(version):
      AppendBlankLine()
      Package()
      MediaTemplate()
      AppendComment('We always do a major upgrade, at least for now')
      MajorUpgrade()

      AppendComment('Directory structure')
      with Directory('TARGETDIR', 'SourceDir'):
        with Directory('ProgramFilesFolder'):
          with Directory('RootInstallDir', 'Dart Editor'):
            AppendComment("Add all files and directories")
            print 'Installing files and directories in xml'
            ListFiles(input_location)
        AppendBlankLine()
        AppendComment("Create shortcuts")
        with Directory('ProgramMenuFolder'):
          with Directory('ShortcutFolder', 'Dart Editor'):
            with Component('shortcut'):
              # When generating a shortcut we need an entry with
              # a KeyPath (RegistryEntry) below - to be able to remove
              # the shortcut again. The RemoveFolder tag is needed
              # to clean up everything
              Shortcut('editor_shortcut', 'Dart Editor',
                       '[RootInstallDir]DartEditor.exe')
              RemoveFolder('RemoveShortcuts')
              RegistryEntry('DartEditor')
      with Feature():
        # We have only one feature, and it consists of all the
        # files=components we have listed above"
        ComponentRefs()
    xml = GetContent()
    if options.print_wxs:
      print xml
    GenerateInstaller(xml, options, temp_dir)

if __name__ == '__main__':
  sys.exit(Main(sys.argv))
