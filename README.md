# sl_cmake

[![Build Status](https://travis-ci.org/azriel91/sl_cmake.svg?branch=master)](https://travis-ci.org/azriel91/sl_cmake)

CMake Functions To Develop CppMicroServices Bundles with Conan

## Usage

1. Declare the dependency.

    If you are using `conanfile.txt`:
    ```
    [requires]
    sl_cmake/0.1.0@azriel91/testing
    ```

    If you are using `conanfile.py`:

    ```python
    from conans import *

    class MyProjectConan(ConanFile):
        # Either:
        requires = 'sl_cmake/0.1.0@azriel91/testing'
        # Or:
        def requirements(self):
            self.requires('sl_cmake/0.1.0@azriel91/testing')

        # ...
    ```

2. In your project's `CMakeLists.txt`, include conan definitions, slBundleFunctions, and start working:

    ```cmake
    include(conanbuildinfo.cmake)
    conan_basic_setup()

    include(slBundleFunctions)
    ```

    Now you can use directly the functions defined in slBlockFunctions.cmake:

    ```cmake
    sl_include_test_dir() # includes the `test` subdirectory if it exists
    ```
