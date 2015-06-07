## CMake Functions To Develop CppMicroServices Modules with Biicode

You can include this file in your CmakeLists.txt file for your biicode project:

    include(azriel/sl_cmake/slBlockFunctions)

Then use "bii find" command to download it:

    > bii find

Now you can use directly the functions defined in slBlockFunctions.cmake:

    ADAPT_TARGETS_FOR_CPPMICROSERVICES()
    SL_INCLUDE_TESTS(${BII_test_main_TARGET})
