from conans import *

class SlCmakeConan(ConanFile):
    name = 'sl_cmake'
    version = '0.1.0'
    exports = ['slBundleFunctions.cmake']

    def package(self):
        self.copy('slBundleFunctions.cmake', dst='.', src='.')
        self.copy('Bundle.h.in', dst='.', src='.')

    def package_info(self):
        # HACK: This is not the right way to get macros defined by other projects into cmake
        self.cpp_info.includedirs += ['.']
