# This file is automatically processed to create .DEPS.git which is the file
# that gclient uses under git.
#
# See http://code.google.com/p/chromium/wiki/UsingGit
#
# To test manually, run:
#   python tools/deps2git/deps2git.py -o .DEPS.git -w <gclientdir>
# where <gcliendir> is the absolute path to the directory containing the
# .gclient file (the parent of 'src').
#
# Then commit .DEPS.git locally (gclient doesn't like dirty trees) and run
#   gclient sync
# Verify the thing happened you wanted. Then revert your .DEPS.git change
# DO NOT CHECK IN CHANGES TO .DEPS.git upstream. It will be automatically
# updated by a bot when you modify this one.
#
# When adding a new dependency, please update the top-level .gitignore file
# to list the dependency's destination directory.

vars = {
  # Use this googlecode_url variable only if there is an internal mirror for it.
  # If you do not know, use the full path while defining your new deps entry.
  'googlecode_url': 'http://%s.googlecode.com/svn',
  'sourceforge_url': 'http://svn.code.sf.net/p/%(repo)s/code',
  'llvm_url': 'http://src.chromium.org/llvm-project',
  'llvm_git': 'https://llvm.googlesource.com',
  'libcxx_revision': '48198f9110397fff47fe7c37cbfa296be7d44d3d',
  'libcxxabi_revision': '4ad1009ab3a59fa7a6896d74d5e4de5885697f95',
  'webkit_trunk': 'http://src.chromium.org/blink/trunk',
  'webkit_revision': '889f35a63b23d86c0f318af9a65a875117811cfd', # from svn revision 182778
  'chromium_git': 'https://chromium.googlesource.com',
  'chromiumos_git': 'https://chromium.googlesource.com/chromiumos',
  'pdfium_git': 'https://pdfium.googlesource.com',
  'skia_git': 'https://skia.googlesource.com',
  'boringssl_git': 'https://boringssl.googlesource.com',
  'libvpx_revision': 'efe9712d52c2d216fb3d1ceb508b8148847a7e4b',
  'sfntly_revision': '1bdaae8fc788a5ac8936d68bf24f37d977a13dac',
  'skia_revision': 'b5fae93d72c7b6480f83fd8a7b534cd1fdfcd49a',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling Skia
  # and V8 without interference from each other.
  'v8_branch': 'trunk',
  'v8_revision': '5830436a84f7792f61451af9bccd991d923fe81c', # from svn revision 24223
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling WebRTC
  # and V8 without interference from each other.
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling swarming_client
  # and whatever else without interference from each other.
  'swarming_revision': '79940aeeec0ace78ade0fec27515850268761af5',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling ANGLE
  # and whatever else without interference from each other.
  "angle_revision": "df647a2a354d5dc9affdd6a982fccb6b95d361b0",
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling build tools
  # and whatever else without interference from each other.
  'buildtools_revision': '56bc51aff4175d3fa27dcd0faa2c345ab046c8a5',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling PDFIum
  # and whatever else without interference from each other.
  'pdfium_revision': '7a649fe262d77f93ad3213f53e973a7665d95a23',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling openmax_dl
  # and whatever else without interference from each other.
  'openmax_dl_revision': '79e64bc9243e5ff11822434cf39b9fabefff3bfb',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling BoringSSL
  # and whatever else without interference from each other.
  'boringssl_revision': '01fe820ab957514f6b83e511492de1b3c03649d5',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling nss
  # and whatever else without interference from each other.
  'nss_revision': '87b96db4268293187d7cf741907a6d5d1d8080e0',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling google-toolbox-for-mac
  # and whatever else without interference from each other.
  'google_toolbox_for_mac_revision': 'a09526298f9dd1ec49d3b3ac5608d2a257b94cef',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling lighttpd
  # and whatever else without interference from each other.
  'lighttpd_revision': '9dfa55d15937a688a92cbf2b7a8621b0927d06eb',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling lss
  # and whatever else without interference from each other.
  'lss_revision': '952107fa7cea0daaabead28c0e92d579bee517eb',
  # Three lines of non-changing comments so that
  # the commit queue can handle CLs rolling NaCl
  # and whatever else without interference from each other.
  'nacl_revision': 'c65c1ed84d500015273d5e72c6ddcebc2a23f9b8', # from svn revision r13797
}

# Only these hosts are allowed for dependencies in this DEPS file.
# If you need to add a new host, contact chrome infrastracture team.
allowed_hosts = [
  'chromium.googlesource.com',
  'boringssl.googlesource.com',
  'pdfium.googlesource.com',
]

deps = {
  'src/breakpad/src':
   Var('chromium_git') + '/external/google-breakpad/src.git' + '@' + '35189355da4b65ed5e7692f790c240a9ab347731', # from svn revision 1387

  'src/buildtools':
   Var('chromium_git') + '/chromium/buildtools.git' + '@' +  Var('buildtools_revision'),

  'src/sdch/open-vcdiff':
   Var('chromium_git') + '/external/open-vcdiff.git' + '@' + '438f2a5be6d809bc21611a94cd37bfc8c28ceb33', # from svn revision 41

  'src/testing/gtest':
   Var('chromium_git') + '/external/googletest.git' + '@' + '4650552ff637bb44ecf7784060091cbed3252211', # from svn revision 692

  'src/testing/gmock':
   Var('chromium_git') + '/external/googlemock.git' + '@' + '896ba0e03f520fb9b6ed582bde2bd00847e3c3f2', # from svn revision 485

  'src/third_party/angle':
   Var('chromium_git') + '/angle/angle.git' + '@' +  Var('angle_revision'),

  'src/third_party/colorama/src':
   Var('chromium_git') + '/external/colorama.git' + '@' + '799604a1041e9b3bc5d2789ecbd7e8db2e18e6b8',

  'src/third_party/trace-viewer':
   Var('chromium_git') + '/external/trace-viewer.git' + '@' + '76a4496033c164d8be9ee8c57f702b0859cb1911',

  'src/third_party/WebKit':
   Var('chromium_git') + '/chromium/blink.git' + '@' +  Var('webkit_revision'),

  'src/third_party/icu':
   Var('chromium_git') + '/chromium/deps/icu52.git' + '@' + 'd2abf6c1e1f986f4a8db0341b8a8c55c55ec1174', # from svn revision 292003

  'src/third_party/libexif/sources':
   Var('chromium_git') + '/chromium/deps/libexif/sources.git' + '@' + 'ed98343daabd7b4497f97fda972e132e6877c48a',

  'src/third_party/hunspell':
   Var('chromium_git') + '/chromium/deps/hunspell.git' + '@' + 'c956c0e97af00ef789afb2f64d02c9a5a50e6eb1',

  'src/third_party/hunspell_dictionaries':
   Var('chromium_git') + '/chromium/deps/hunspell_dictionaries.git' + '@' + '4560bdd463a3500e2334e85c8a0e9e5d5d6774e7',

  'src/third_party/safe_browsing/testing':
    Var('chromium_git') + '/external/google-safe-browsing/testing.git' + '@' + '9d7e8064f3ca2e45891470c9b5b1dce54af6a9d6',

  'src/third_party/cacheinvalidation/src':
    Var('chromium_git') + '/external/google-cache-invalidation-api/src.git' + '@' + 'c91bd9d9fed06bf440be64f87b94a2effdb32bc4', # from svn revision 341

  'src/third_party/leveldatabase/src':
    Var('chromium_git') + '/external/leveldb.git' + '@' + '3f77584eb3f9754bbb7079070873ece3f30a1e6b',

  'src/third_party/libc++/trunk':
   Var('chromium_git') + '/chromium/llvm-project/libcxx.git' + '@' +  Var('libcxx_revision'),

  'src/third_party/libc++abi/trunk':
   Var('chromium_git') + '/chromium/llvm-project/libcxxabi.git' + '@' +  Var('libcxxabi_revision'),

  'src/third_party/snappy/src':
    Var('chromium_git') + '/external/snappy.git' + '@' + '762bb32f0c9d2f31ba4958c7c0933d22e80c20bf',

  'src/tools/grit':
    Var('chromium_git') + '/external/grit-i18n.git' + '@' + '740badd5e3e44434a9a47b5d16749daac1e8ea80', # from svn revision 176

  'src/tools/gyp':
    Var('chromium_git') + '/external/gyp.git' + '@' + '46282cedf40ff7fe803be4af357b9d59050f02e4', # from svn revision 1977

  'src/tools/swarming_client':
   Var('chromium_git') + '/external/swarming.client.git' + '@' +  Var('swarming_revision'),

  'src/v8':
    Var('chromium_git') + '/v8/v8.git' + '@' +  Var('v8_revision'),

  'src/native_client':
   Var('chromium_git') + '/native_client/src/native_client.git' + '@' + Var('nacl_revision'),

  'src/chrome/test/data/extensions/api_test/permissions/nacl_enabled/bin':
   Var('chromium_git') + '/native_client/src/native_client/tests/prebuilt.git' + '@' + '3e17365176c94624f46cace174f61834b7f3c35d',

  'src/third_party/sfntly/cpp/src':
    Var('chromium_git') + '/external/sfntly/cpp/src.git' + '@' +  Var('sfntly_revision'),

  'src/third_party/skia':
   Var('chromium_git') + '/skia.git' + '@' +  Var('skia_revision'),

  'src/third_party/ots':
    Var('chromium_git') + '/external/ots.git' + '@' + '98897009f3ea8a5fa3e20a4a74977da7aaa8e61a',

  'src/third_party/brotli/src':
   Var('chromium_git') + '/external/font-compression-reference.git' + '@' + '6cef49677dc4c650ef6e3f56041e0a41803afa8c',

  'src/tools/page_cycler/acid3':
   Var('chromium_git') + '/chromium/deps/acid3.git' + '@' + '6be0a66a1ebd7ebc5abc1b2f405a945f6d871521',

  'src/chrome/test/data/perf/canvas_bench':
   Var('chromium_git') + '/chromium/canvas_bench.git' + '@' + 'a7b40ea5ae0239517d78845a5fc9b12976bfc732',

  'src/chrome/test/data/perf/frame_rate/content':
   Var('chromium_git') + '/chromium/frame_rate/content.git' + '@' + 'c10272c88463efeef6bb19c9ec07c42bc8fe22b9',

  'src/third_party/bidichecker':
    Var('chromium_git') + '/external/bidichecker/lib.git' + '@' + '97f2aa645b74c28c57eca56992235c79850fa9e0',

  'src/third_party/webgl/src':
   Var('chromium_git') + '/external/khronosgroup/webgl.git' + '@' + 'b1a7210dc4034793e34a2149cb571e85700a85f2',

  'src/third_party/swig/Lib':
   Var('chromium_git') + '/chromium/deps/swig/Lib.git' + '@' + 'f2a695d52e61e6a8d967731434f165ed400f0d69',

  'src/third_party/webdriver/pylib':
    Var('chromium_git') + '/external/selenium/py.git' + '@' + '5fd78261a75fe08d27ca4835fb6c5ce4b42275bd',

  'src/third_party/libvpx':
   Var('chromium_git') + '/chromium/deps/libvpx.git' + '@' +  Var('libvpx_revision'),

  'src/third_party/ffmpeg':
   Var('chromium_git') + '/chromium/third_party/ffmpeg.git' + '@' + '438ff61fe51641665f0ec3bc55e7b416d0aa251a',

  'src/third_party/libjingle/source/talk':
    Var('chromium_git') + '/external/webrtc/trunk/talk.git' + '@' + '40539b82d5a2c9bcf23d078e997ce0368160f5a3',

  'src/third_party/usrsctp/usrsctplib':
    Var('chromium_git') + '/external/usrsctplib.git' + '@' + '8975bd5397c2ec97f50e0b87b544054e0536bfe1',

  'src/third_party/libsrtp':
   Var('chromium_git') + '/chromium/deps/libsrtp.git' + '@' + '98284c8600c73812ff4716a6ea157d1e11d417dc',

  'src/third_party/speex':
   Var('chromium_git') + '/chromium/deps/speex.git' + '@' + '5260621c36c227209c7ba64ea71ca3418cf9e2b4',

  'src/third_party/yasm/source/patched-yasm':
   Var('chromium_git') + '/chromium/deps/yasm/patched-yasm.git' + '@' + 'c960eb11ccda80b10ed50be39df4f0663b371d1d',

  'src/third_party/libjpeg_turbo':
   Var('chromium_git') + '/chromium/deps/libjpeg_turbo.git' + '@' + '034e9a9747e0983bc19808ea70e469bc8342081f',

  'src/third_party/flac':
   Var('chromium_git') + '/chromium/deps/flac.git' + '@' + '0635a091379d9677f1ddde5f2eec85d0f096f219',

  'src/third_party/pyftpdlib/src':
    Var('chromium_git') + '/external/pyftpdlib.git' + '@' + '2be6d65e31c7ee6320d059f581f05ae8d89d7e45',

  'src/third_party/scons-2.0.1':
   Var('chromium_git') + '/native_client/src/third_party/scons-2.0.1.git' + '@' + '1c1550e17fc26355d08627fbdec13d8291227067',

  'src/third_party/webrtc':
    Var('chromium_git') + '/external/webrtc/trunk/webrtc.git' + '@' + '53545bbfc47f2cddb7038395369a0dcd457c8b34',

  'src/third_party/openmax_dl':
    Var('chromium_git') + '/external/webrtc/deps/third_party/openmax.git' + '@' +  Var('openmax_dl_revision'),

  'src/third_party/jsoncpp/source/include':
    Var('chromium_git') + '/external/jsoncpp/jsoncpp/include.git' + '@' + 'b0dd48e02b6e6248328db78a65b5c601f150c349',

  'src/third_party/jsoncpp/source/src/lib_json':
    Var('chromium_git') + '/external/jsoncpp/jsoncpp/src/lib_json.git' + '@' + 'a8caa51ba2f80971a45880425bf2ae864a786784',

  'src/third_party/libyuv':
    Var('chromium_git') + '/external/libyuv.git' + '@' + '455c66b4375d72984b79249616d0a708ad568894',

  'src/third_party/smhasher/src':
    Var('chromium_git') + '/external/smhasher.git' + '@' + 'e87738e57558e0ec472b2fc3a643b838e5b6e88f',

  'src/third_party/libaddressinput/src':
    Var('chromium_git') + '/external/libaddressinput.git' + '@' + '945d96387a716d0d82b195fa69a5e9a701249517', # from svn revision 334

  'src/third_party/libphonenumber/src/phonenumbers':
    Var('chromium_git') + '/external/libphonenumber/cpp/src/phonenumbers.git' + '@' + '8d8b5b3b2035197795d27573d4cf566b5d9ad689',
  'src/third_party/libphonenumber/src/test':
    Var('chromium_git') + '/external/libphonenumber/cpp/test.git' + '@' + '883b7b86541d64b2691f7c0e65facb0b08db73e8',
  'src/third_party/libphonenumber/src/resources':
    Var('chromium_git') + '/external/libphonenumber/resources.git' + '@' + 'de095548d2ae828a414e01f3951bfefba902b4e4',

  'src/tools/deps2git':
   Var('chromium_git') + '/chromium/tools/deps2git.git' + '@' + 'f04828eb0b5acd3e7ad983c024870f17f17b06d9',

  'src/third_party/webpagereplay':
   Var('chromium_git') + '/external/web-page-replay.git' + '@' + '2f7b704b8b567983c040f555d3e46f9766db8e87',

  'src/third_party/pywebsocket/src':
    Var('chromium_git') + '/external/pywebsocket/src.git' + '@' + 'cb349e87ddb30ff8d1fa1a89be39cec901f4a29c',

  'src/third_party/opus/src':
   Var('chromium_git') + '/chromium/deps/opus.git' + '@' + 'cae696156f1e60006e39821e79a1811ae1933c69',

  'src/media/cdm/ppapi/api':
   Var('chromium_git') + '/chromium/cdm.git' + '@' + '41c8183a3966a17b440dbe606cb2840e1b7ce884',

  'src/third_party/mesa/src':
   Var('chromium_git') + '/chromium/deps/mesa.git' + '@' + '457812d99a213dedf1c4cd38018ff48118d0c44f',

  'src/third_party/cld_2/src':
    Var('chromium_git') + '/external/cld2.git' + '@' + 'bb5c092e8c02dcc2319c5056aff2182199d51c2f',

  'src/chrome/browser/resources/pdf/html_office':
    Var('chromium_git') + '/chromium/html-office-public.git' + '@' + 'eeff97614f65e0578529490d44d412032c3d7359',

  'src/third_party/libwebm/source':
   Var('chromium_git') + '/webm/libwebm.git' + '@' + '0d4cb404ea4195e5e21d04db2c955615535ce62e',

  'src/third_party/pdfium':
   'https://pdfium.googlesource.com/pdfium.git' + '@' +  Var('pdfium_revision'),

  'src/third_party/boringssl/src':
   'https://boringssl.googlesource.com/boringssl.git' + '@' +  Var('boringssl_revision'),
}


deps_os = {
  'win': {
    'src/chrome/tools/test/reference_build/chrome_win':
     Var('chromium_git') + '/chromium/reference_builds/chrome_win.git' + '@' + 'f8a3a845dfc845df6b14280f04f86a61959357ef',

    'src/third_party/cygwin':
     Var('chromium_git') + '/chromium/deps/cygwin.git' + '@' + 'c89e446b273697fadf3a10ff1007a97c0b7de6df',

    'src/third_party/psyco_win32':
     Var('chromium_git') + '/chromium/deps/psyco_win32.git' + '@' + 'f5af9f6910ee5a8075bbaeed0591469f1661d868',

    'src/third_party/bison':
     Var('chromium_git') + '/chromium/deps/bison.git' + '@' + '083c9a45e4affdd5464ee2b224c2df649c6e26c3',

    'src/third_party/gperf':
     Var('chromium_git') + '/chromium/deps/gperf.git' + '@' + 'd892d79f64f9449770443fb06da49b5a1e5d33c1',

    'src/third_party/perl':
     Var('chromium_git') + '/chromium/deps/perl.git' + '@' + 'ac0d98b5cee6c024b0cffeb4f8f45b6fc5ccdb78',

    'src/third_party/lighttpd':
     Var('chromium_git') + '/chromium/deps/lighttpd.git' + '@' + Var('lighttpd_revision'),

    # Parses Windows PE/COFF executable format.
    'src/third_party/pefile':
     Var('chromium_git') + '/external/pefile.git' + '@' + '72c6ae42396cb913bcab63c15585dc3b5c3f92f1',

    # NSS, for SSLClientSocketNSS.
    'src/third_party/nss':
     Var('chromium_git') + '/chromium/deps/nss.git' + '@' + Var('nss_revision'),

    'src/third_party/swig/win':
     Var('chromium_git') + '/chromium/deps/swig/win.git' + '@' + '986f013ba518541adf5c839811efb35630a31031',

    # GNU binutils assembler for x86-32.
    'src/third_party/gnu_binutils':
      Var('chromium_git') + '/native_client/deps/third_party/gnu_binutils.git' + '@' + 'f4003433b61b25666565690caf3d7a7a1a4ec436',
    # GNU binutils assembler for x86-64.
    'src/third_party/mingw-w64/mingw/bin':
      Var('chromium_git') + '/native_client/deps/third_party/mingw-w64/mingw/bin.git' + '@' + '3cc8b140b883a9fe4986d12cfd46c16a093d3527',

    # Dependencies used by libjpeg-turbo
    'src/third_party/yasm/binaries':
     Var('chromium_git') + '/chromium/deps/yasm/binaries.git' + '@' + '52f9b3f4b0aa06da24ef8b123058bb61ee468881',

    # Binaries for nacl sdk.
    'src/third_party/nacl_sdk_binaries':
     Var('chromium_git') + '/chromium/deps/nacl_sdk_binaries.git' + '@' + '759dfca03bdc774da7ecbf974f6e2b84f43699a5',
  },
  'ios': {
    'src/third_party/google_toolbox_for_mac/src':
      Var('chromium_git') + '/external/google-toolbox-for-mac.git' + '@' + Var('google_toolbox_for_mac_revision'),

    'src/third_party/nss':
     Var('chromium_git') + '/chromium/deps/nss.git' + '@' + Var('nss_revision'),

    # class-dump utility to generate header files for undocumented SDKs
    'src/testing/iossim/third_party/class-dump':
     Var('chromium_git') + '/chromium/deps/class-dump.git' + '@' + '89bd40883c767584240b4dade8b74e6f57b9bdab',

    # Code that's not needed due to not building everything
    'src/build/util/support': None,
    'src/chrome/test/data/extensions/api_test/permissions/nacl_enabled/bin': None,
    'src/chrome/test/data/perf/canvas_bench': None,
    'src/chrome/test/data/perf/frame_rate/content': None,
    'src/media/cdm/ppapi/api': None,
    'src/native_client': None,
    'src/third_party/bidichecker': None,
    'src/third_party/brotli/src': None,
    'src/third_party/cld_2/src': None,
    'src/third_party/ffmpeg': None,
    'src/third_party/hunspell_dictionaries': None,
    'src/third_party/hunspell': None,
    'src/third_party/libc++/trunk': None,
    'src/third_party/libc++abi/trunk': None,
    'src/third_party/libexif/sources': None,
    'src/third_party/libjpeg_turbo': None,
    'src/third_party/libsrtp': None,
    'src/third_party/opus/src': None,
    'src/third_party/openmax_dl': None,
    'src/third_party/ots': None,
    'src/third_party/pymox/src': None,
    'src/third_party/safe_browsing/testing': None,
    'src/third_party/scons-2.0.1': None,
    'src/third_party/sfntly/cpp/src': None,
    'src/third_party/speex': None,
    'src/third_party/swig/Lib': None,
    'src/third_party/usrsctp/usrsctplib': None,
    'src/third_party/v8-i18n': None,
    'src/third_party/webdriver/pylib': None,
    'src/third_party/webgl': None,
    'src/third_party/webpagereplay': None,
    'src/third_party/WebKit/LayoutTests/w3c/web-platform-tests': None,
    'src/third_party/WebKit/LayoutTests/w3c/csswg-test': None,
    'src/third_party/yasm/source/patched-yasm': None,
    'src/tools/page_cycler/acid3': None,
  },
  'mac': {
    'src/chrome/tools/test/reference_build/chrome_mac':
     Var('chromium_git') + '/chromium/reference_builds/chrome_mac.git' + '@' + '8dc181329e7c5255f83b4b85dc2f71498a237955',

    'src/third_party/google_toolbox_for_mac/src':
      Var('chromium_git') + '/external/google-toolbox-for-mac.git' + '@' + Var('google_toolbox_for_mac_revision'),


    'src/third_party/pdfsqueeze':
      Var('chromium_git') + '/external/pdfsqueeze.git' + '@' + '5936b871e6a087b7e50d4cbcb122378d8a07499f',

    'src/third_party/lighttpd':
     Var('chromium_git') + '/chromium/deps/lighttpd.git' + '@' + Var('lighttpd_revision'),

    'src/third_party/swig/mac':
     Var('chromium_git') + '/chromium/deps/swig/mac.git' + '@' + '1b182eef16df2b506f1d710b34df65d55c1ac44e',

    # NSS, for SSLClientSocketNSS.
    'src/third_party/nss':
     Var('chromium_git') + '/chromium/deps/nss.git' + '@' + Var('nss_revision'),

    'src/chrome/installer/mac/third_party/xz/xz':
     Var('chromium_git') + '/chromium/deps/xz.git' + '@' + 'eecaf55632ca72e90eb2641376bce7cdbc7284f7',
  },
  'unix': {
    # Linux, really.
    'src/chrome/tools/test/reference_build/chrome_linux':
     Var('chromium_git') + '/chromium/reference_builds/chrome_linux64.git' + '@' + '033d053a528e820e1de3e2db766678d862a86b36',

    'src/third_party/xdg-utils':
     Var('chromium_git') + '/chromium/deps/xdg-utils.git' + '@' + 'd80274d5869b17b8c9067a1022e4416ee7ed5e0d',

    'src/third_party/swig/linux':
     Var('chromium_git') + '/chromium/deps/swig/linux.git' + '@' + '866b8e0e0e0cfe99ebe608260030916ca0c3f92d',

    'src/third_party/lss':
      Var('chromium_git') + '/external/linux-syscall-support/lss.git' + '@' + Var('lss_revision'),

    # For Linux and Chromium OS.
    'src/third_party/cros_system_api':
     Var('chromium_git') + '/chromiumos/platform/system_api.git' + '@' + 'f0fc55329fa536195861778a2ddc6115b4a977bc',

    # Note that this is different from Android's freetype repo.
    'src/third_party/freetype2/src':
     Var('chromium_git') + '/chromium/src/third_party/freetype2.git' + '@' + 'd699c2994ecc178c4ed05ac2086061b2034c2178',

    # Build tools for Chrome OS.
    'src/third_party/chromite':
     Var('chromium_git') + '/chromiumos/chromite.git' + '@' + '8e92d5c24da7967e27ab2498abc2d2f7ac6ec65a',

    # Dependency of chromite.git.
    'src/third_party/pyelftools':
     Var('chromium_git') + '/chromiumos/third_party/pyelftools.git' + '@' + 'bdc1d380acd88d4bfaf47265008091483b0d614e',

    'src/third_party/undoview':
     Var('chromium_git') + '/chromium/deps/undoview.git' + '@' + '3ba503e248f3cdbd81b78325a24ece0984637559',

    'src/third_party/liblouis/src':
     Var('chromium_git') + '/external/liblouis-github.git' + '@' + '5f9c03f2a3478561deb6ae4798175094be8a26c2',

    # Used for embedded builds. CrOS & Linux use the system version.
    'src/third_party/fontconfig/src':
     Var('chromium_git') + '/external/fontconfig.git' + '@' + 'f16c3118e25546c1b749f9823c51827a60aeb5c1',
  },
  'android': {
    'src/third_party/android_protobuf/src':
     Var('chromium_git') + '/external/android_protobuf.git' + '@' + '94f522f907e3f34f70d9e7816b947e62fddbb267',

    # Whenever you roll this please also change frameworks/webview in
    # src/android_webview/buildbot/aosp_manifest.xml to point to the same revision.
    'src/third_party/android_webview_glue/src':
     Var('chromium_git') + '/external/android_webview_glue.git' + '@' + 'a1b0248c80f239e2f6476b9f395b27d0ba1eb3cd',

    'src/third_party/android_tools':
     Var('chromium_git') + '/android_tools.git' + '@' + 'd2b86205ff973a3844020feacb35ca6b1d82efbe',

    'src/third_party/apache-mime4j':
     Var('chromium_git') + '/chromium/deps/apache-mime4j.git' + '@' + '28cb1108bff4b6cf0a2e86ff58b3d025934ebe3a',

    'src/third_party/findbugs':
     Var('chromium_git') + '/chromium/deps/findbugs.git' + '@' + '7f69fa78a6db6dc31866d09572a0e356e921bf12',

    'src/third_party/freetype':
     Var('chromium_git') + '/chromium/src/third_party/freetype.git' + '@' + 'a2b9955b49034a51dfbc8bf9f4e9d312149cecac',

   'src/third_party/elfutils/src':
     Var('chromium_git') + '/external/elfutils.git' + '@' + '249673729a7e5dbd5de4f3760bdcaa3d23d154d7',

    'src/third_party/httpcomponents-client':
     Var('chromium_git') + '/chromium/deps/httpcomponents-client.git' + '@' + '285c4dafc5de0e853fa845dce5773e223219601c',

    'src/third_party/httpcomponents-core':
     Var('chromium_git') + '/chromium/deps/httpcomponents-core.git' + '@' + '9f7180a96f8fa5cab23f793c14b413356d419e62',

    'src/third_party/jarjar':
     Var('chromium_git') + '/chromium/deps/jarjar.git' + '@' + '2e1ead4c68c450e0b77fe49e3f9137842b8b6920',

    'src/third_party/jsr-305/src':
      Var('chromium_git') + '/external/jsr-305.git' + '@' + '642c508235471f7220af6d5df2d3210e3bfc0919',

    'src/third_party/junit/src':
      Var('chromium_git') + '/external/junit.git' + '@' + 'c62e2df8dbecccb1b434d4ba8843b59e90b03266',

    'src/third_party/lss':
      Var('chromium_git') + '/external/linux-syscall-support/lss.git' + '@' + Var('lss_revision'),

    'src/third_party/eyesfree/src/android/java/src/com/googlecode/eyesfree/braille':
      Var('chromium_git') + '/external/eyes-free/braille/client/src/com/googlecode/eyesfree/braille.git' + '@' + '77bf6edb0138e3a38a2772248696f130dab45e34',
  },
}


include_rules = [
  # Everybody can use some things.
  '+base',
  '+build',
  '+ipc',

  # Everybody can use headers generated by tools/generate_library_loader.
  '+library_loaders',

  '+testing',
  '+third_party/icu/source/common/unicode',
  '+third_party/icu/source/i18n/unicode',
  '+url',
]


# checkdeps.py shouldn't check include paths for files in these dirs:
skip_child_includes = [
  'breakpad',
  'delegate_execute',
  'metro_driver',
  'native_client_sdk',
  'o3d',
  'sdch',
  'skia',
  'testing',
  'third_party',
  'v8',
  'win8',
]


hooks = [
  {
    # This clobbers when necessary (based on get_landmines.py). It must be the
    # first hook so that other things that get/generate into the output
    # directory will not subsequently be clobbered.
    'name': 'landmines',
    'pattern': '.',
    'action': [
        'python',
        'src/build/landmines.py',
    ],
  },
  {
    # This downloads binaries for Native Client's newlib toolchain.
    # Done in lieu of building the toolchain from scratch as it can take
    # anywhere from 30 minutes to 4 hours depending on platform to build.
    'name': 'nacltools',
    'pattern': '.',
    'action': [
        'python', 'src/build/download_nacl_toolchains.py',
        '--exclude', 'arm_trusted',
    ],
  },
  {
    # Downloads an ARM sysroot image to src/arm-sysroot. This image updates
    # at about the same rate that the chrome build deps change.
    # This script is a no-op except for linux users who have
    # target_arch=arm in their GYP_DEFINES.
    'name': 'sysroot',
    'pattern': '.',
    'action': ['python', 'src/build/linux/install-arm-sysroot.py',
               '--linux-only'],
  },
  {
    # Downloads the Debian Wheezy sysroot to chrome/installer/linux if needed.
    # This sysroot updates at about the same rate that the chrome build deps
    # change. This script is a no-op except for linux users who are doing
    # official chrome builds.
    'name': 'sysroot',
    'pattern': '.',
    'action': [
        'python',
        'src/chrome/installer/linux/sysroot_scripts/install-debian.wheezy.sysroot.py',
        '--linux-only',
        '--arch=amd64'],
  },
  {
    # Same as above, but for 32-bit Linux.
    'name': 'sysroot',
    'pattern': '.',
    'action': [
        'python',
        'src/chrome/installer/linux/sysroot_scripts/install-debian.wheezy.sysroot.py',
        '--linux-only',
        '--arch=i386'],
  },
  {
    # Update the Windows toolchain if necessary.
    'name': 'win_toolchain',
    'pattern': '.',
    'action': ['python', 'src/build/vs_toolchain.py', 'update'],
  },
  {
    # Pull clang if needed or requested via GYP_DEFINES.
    # Note: On Win, this should run after win_toolchain, as it may use it.
    'name': 'clang',
    'pattern': '.',
    'action': ['python', 'src/tools/clang/scripts/update.py', '--if-needed'],
  },
  {
    # Update LASTCHANGE. This is also run by export_tarball.py in
    # src/tools/export_tarball - please keep them in sync.
    'name': 'lastchange',
    'pattern': '.',
    'action': ['python', 'src/build/util/lastchange.py',
               '-o', 'src/build/util/LASTCHANGE'],
  },
  {
    # Update LASTCHANGE.blink. This is also run by export_tarball.py in
    # src/tools/export_tarball - please keep them in sync.
    'name': 'lastchange',
    'pattern': '.',
    'action': ['python', 'src/build/util/lastchange.py',
               '-s', 'src/third_party/WebKit',
               '-o', 'src/build/util/LASTCHANGE.blink'],
  },
  # Pull GN binaries. This needs to be before running GYP below.
  {
    'name': 'gn_win',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=win32',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/win/gn.exe.sha1',
    ],
  },
  {
    'name': 'gn_mac',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=darwin',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/mac/gn.sha1',
    ],
  },
  {
    'name': 'gn_linux32',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/linux32/gn.sha1',
    ],
  },
  {
    'name': 'gn_linux64',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-gn',
                '-s', 'src/buildtools/linux64/gn.sha1',
    ],
  },
  # Pull clang-format binaries using checked-in hashes.
  {
    'name': 'clang_format_win',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=win32',
                '--no_auth',
                '--bucket', 'chromium-clang-format',
                '-s', 'src/buildtools/win/clang-format.exe.sha1',
    ],
  },
  {
    'name': 'clang_format_mac',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=darwin',
                '--no_auth',
                '--bucket', 'chromium-clang-format',
                '-s', 'src/buildtools/mac/clang-format.sha1',
    ],
  },
  {
    'name': 'clang_format_linux',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-clang-format',
                '-s', 'src/buildtools/linux64/clang-format.sha1',
    ],
  },
  # Pull binutils for linux, enabled debug fission for faster linking /
  # debugging when used with clang on Ubuntu Precise.
  # https://code.google.com/p/chromium/issues/detail?id=352046
  {
    'name': 'binutils',
    'pattern': 'src/third_party/binutils',
    'action': [
        'python',
        'src/third_party/binutils/download.py',
    ],
  },
  # Pull eu-strip binaries using checked-in hashes.
  {
    'name': 'eu-strip',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=linux*',
                '--no_auth',
                '--bucket', 'chromium-eu-strip',
                '-s', 'src/build/linux/bin/eu-strip.sha1',
    ],
  },
  {
    'name': 'drmemory',
    'pattern': '.',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=win32',
                '--no_auth',
                '--bucket', 'chromium-drmemory',
                '-s', 'src/third_party/drmemory/drmemory-windows-sfx.exe.sha1',
              ],
  },
  # Pull the Syzygy binaries, used for optimization and instrumentation.
  {
    'name': 'syzygy-binaries',
    'pattern': '.',
    'action': ['python',
               'src/build/get_syzygy_binaries.py',
               '--output-dir=src/third_party/syzygy/binaries',
               '--revision=363bc02a09c380b6f5f397606cc0744d85d54a51',
               '--overwrite',
    ],
  },
  {
    'name': 'apache_win32',
    'pattern': '\\.sha1',
    'action': [ 'download_from_google_storage',
                '--no_resume',
                '--platform=win32',
                '--directory',
                '--recursive',
                '--no_auth',
                '--num_threads=16',
                '--bucket', 'chromium-apache-win32',
                'src/third_party/apache-win32',
    ],
  },
  {
    # A change to a .gyp, .gypi, or to GYP itself should run the generator.
    'name': 'gyp',
    'pattern': '.',
    'action': ['python', 'src/build/gyp_chromium'],
  },
  {
    # Verify committers' ~/.netc, gclient and git are properly configured for
    # write access to the git repo. To be removed sometime after Chrome to git
    # migration completes (let's say Sep 1 2014).
    'name': 'check_git_config',
    'pattern': '.',
    'action': [
        'python',
        'src/tools/check_git_config.py',
        '--running-as-hook',
    ],
  },
  {
    # Ensure that we don't accidentally reference any .pyc files whose
    # corresponding .py files have already been deleted.
    'name': 'remove_stale_pyc_files',
    'pattern': 'src/tools/.*\\.py',
    'action': [
        'python',
        'src/tools/remove_stale_pyc_files.py',
        'src/tools',
    ],
  },
]
