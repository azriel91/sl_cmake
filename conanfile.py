from conans import *

class SlCmakeConan(ConanFile):
    name = 'sl_cmake'
    version = '0.1.0'
    generators = ['cmake']
    url = 'https://github.com/azriel91/sl_cmake.git'
    exports = ['slBundleFunctions.cmake', 'Bundle.h.in']

    def requirements(self):
        self.requires('conan_cmake/0.1.0@azriel91/stable')
        self.requires('CppMicroServices/3.0.0@azriel91/testing')

    def package(self):
        self.copy('slBundleFunctions.cmake', dst='.', src='.')
        self.copy('Bundle.h.in', dst='.', src='.')

    def build(self):
        # Nothing to do
        pass