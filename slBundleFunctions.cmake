set(SL_BUNDLE_FUNCTIONS_DIR ${CMAKE_CURRENT_LIST_DIR})

# === Dependency discovery === #

include(conanbuildinfo.cmake)
conan_basic_setup()

include(conanTools)
find_package(CppMicroServices 3.0.0 CONFIG PATHS ${CONAN_CPPMICROSERVICES_ROOT})

#======================================================================================================================#
# [PUBLIC/USER]
#
# Minimum signature:
# sl_create_bundle(my_target
#                  SOURCES MyService.cpp Activator.cpp
#                  RESOURCES manifest.json)
#
# Full signature example:
# sl_create_bundle(my_target
#                  LIBRARY
#                  BUNDLE_NAME my_target
#                  SOURCES MyService.cpp Activator.cpp
#                  RESOURCES manifest.json
#                  BINARY_RESOURCES generated.txt
#                  ZIP_ARCHIVES ${static_bundle_deps}
#                  COMPRESSION_LEVEL 9)
#
# Calls usFunctionGenerateBundleInit and usFunctionGetResourceSource.
# Sets the compile definitions to identify the target(s) as CppMicroServices bundles.
# Sets the c++11 flag for the compiler.
#
#======================================================================================================================#
function(SL_CREATE_BUNDLE TARGET_NAME)
  cmake_parse_arguments(BUNDLE "LIBRARY;EXECUTABLE" # options
                               "BUNDLE_NAME;COMPRESSION_LEVEL" # single-value args
                               "SOURCES;RESOURCES;BINARY_RESOURCES;ZIP_ARCHIVES" # multi-value args
                               ${ARGN})

  # === Argument validation === #
  if(NOT TARGET_NAME)
    message(SEND_ERROR "TARGET_NAME not specified for sl_create_bundle.")
  endif()

  if(NOT BUNDLE_BUNDLE_NAME)
    message(STATUS "BUNDLE_NAME not specified for target [" ${TARGET_NAME} "], defaulting to target name.")
    set(BUNDLE_BUNDLE_NAME ${TARGET_NAME})
  endif()

  if(BUNDLE_LIBRARY AND BUNDLE_EXECUTABLE)
    message(SEND_ERROR "Both LIBRARY and EXECUTABLE options specified for [" ${TARGET_NAME} "].")
  endif()
  if(NOT BUNDLE_LIBRARY AND NOT BUNDLE_EXECUTABLE)
    # Default to library
    set(BUNDLE_LIBRARY 1)
  endif()
  if(BUNDLE_EXECUTABLE AND NOT BUNDLE_BUNDLE_NAME STREQUAL "main")
    message(SEND_ERROR "CppMicroServices EXECUTABLE bundles must use 'main' for their BUNDLE_NAME. Currently ["
                       ${BUNDLE_BUNDLE_NAME} "] is specified.")
  endif()

  # === Set target properties and compile definitions === #
  set(srcs ${BUNDLE_SOURCES})
  usFunctionGenerateBundleInit(srcs)
  usFunctionGetResourceSource(TARGET ${TARGET_NAME} OUT srcs)

  if(BUNDLE_LIBRARY)
    add_library(${TARGET_NAME} ${srcs})
  else()
    add_executable(${TARGET_NAME} ${srcs})
  endif()

  # necessary for adding / embedding resources
  set_property(TARGET ${TARGET_NAME} PROPERTY US_BUNDLE_NAME ${BUNDLE_BUNDLE_NAME})
  set_property(TARGET ${TARGET_NAME} APPEND PROPERTY COMPILE_DEFINITIONS US_BUNDLE_NAME=${BUNDLE_BUNDLE_NAME})

  activate_cpp11(${TARGET_NAME})

  # Add bundle resources
  usFunctionAddResources(TARGET ${TARGET_NAME}
                         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/resources
                         FILES ${BUNDLE_RESOURCES} ${BUNDLE_BINARY_RESOURCES}
                         ZIP_ARCHIVES ${BUNDLE_ZIP_ARCHIVES}
                         COMPRESSION_LEVEL ${BUNDLE_COMPRESSION_LEVEL})
  usFunctionEmbedResources(TARGET ${TARGET_NAME} COMPRESSION_LEVEL ${BUNDLE_COMPRESSION_LEVEL})

  # Indicate this is a static module if we aren't building shared libraries
  if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(${TARGET_NAME} PRIVATE US_STATIC_BUNDLE)
  endif()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_find_static_lib_paths(static_lib_paths lib1 lib2)
#
# Searches the CMAKE_RUNTIME_OUTPUT_DIRECTORY and CONAN_LIB_DIRS for the specified static libraries.
#
#======================================================================================================================#
function(SL_FIND_STATIC_LIB_PATHS out_var)
  set(lib_paths)
  foreach(library_name ${ARGN})
    set(library_file_name ${CMAKE_STATIC_LIBRARY_PREFIX}${library_name}${CMAKE_STATIC_LIBRARY_SUFFIX})

    # find_path finds the path of the directory that the file exists in
    find_path(${library_file_name}_dir ${library_file_name}
              PATHS ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} ${CONAN_LIB_DIRS}
              PATH_SUFFIXES "lib" "bin")
    if(NOT ${library_file_name}_dir)
      message(SEND_ERROR "Could not find " ${library_file_name})
    endif()

    list(APPEND lib_paths "${${library_file_name}_dir}/${library_file_name}")
  endforeach()

  set(${out_var} ${lib_paths} PARENT_SCOPE)
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_include_test_dir()
#
# Includes the "test" directory if it exists
#
# The enable_testing() call must be done in the project's root directory rather than through a function otherwise the
# 'test' target doesn't get generated. This is a quirk of CMake.
#
#======================================================================================================================#
function(SL_INCLUDE_TEST_DIR)
  set(TEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/test")
  if(EXISTS ${TEST_DIR} AND IS_DIRECTORY ${TEST_DIR})
    add_subdirectory(test)
  endif()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_include_tests(target1 target2 ...)
#
# Calls add_test for each of the specified targets.
#
#======================================================================================================================#
function(SL_INCLUDE_TESTS )
  foreach(TARGET_NAME ${ARGN})
    add_test(NAME ${TARGET_NAME}
             COMMAND ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${TARGET_NAME})
  endforeach()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_generate_and_include_test_header(infile target1 target2 ...)
#
# Generates the test configuration header, and adds a dependency on the generated header to the specified targets.
#
#======================================================================================================================#
function(SL_GENERATE_AND_INCLUDE_TEST_HEADER TEST_HEADER_IN)
  # Strip off the ".in" from the infile
  string(REGEX REPLACE
         "(.+)[.]in$"          # regular_expression
         "\\1"                 # replace_expression
         GENERATED_TEST_HEADER # output variable
         "${TEST_HEADER_IN}")

  # Generate the header file
  set(GENERATED_TEST_HEADER_TARGET "${TEST_HEADER_IN}_TARGET")
  add_custom_target(${GENERATED_TEST_HEADER_TARGET} DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${GENERATED_TEST_HEADER}")
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/${TEST_HEADER_IN}"
                 "${CMAKE_CURRENT_BINARY_DIR}/${GENERATED_TEST_HEADER}")

  # Add the test header target as a dependency of the specified targets
  foreach(TARGET_NAME ${ARGN})
    add_dependencies(${TARGET_NAME} ${GENERATED_TEST_HEADER_TARGET})
    target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
  endforeach()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_disable_gtest_tuple(testTarget1 testTarget2 ...)
#
# Tell GTest not to use std::tuple because CppMicroServices uses its own definition, and it causes a redefinition error
#
#======================================================================================================================#
function(SL_DISABLE_GTEST_TUPLE)
  foreach(TEST_TARGET ${ARGN})
    target_compile_definitions(${TEST_TARGET} PRIVATE GTEST_HAS_TR1_TUPLE=1 GTEST_USE_OWN_TR1_TUPLE=0)
  endforeach()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_generate_and_include_bundle_header(target1 target2 ...)
#
# Generates a "Bundle.h" header file that contains the c++ library export definition.
#
# For example, for a bundle called sl_core_application:
# - the export macro is SL_CORE_APPLICATION_EXPORT
# - the bundle namespace is sl::core::application
#
#======================================================================================================================#
function(SL_GENERATE_AND_INCLUDE_BUNDLE_HEADER)
  string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER) # used in Bundle.h.in
  string(REGEX MATCHALL "([^_]+)+" PROJECT_NAME_SEGMENTS ${PROJECT_NAME})

  # Generate the namespace <segment> {} declarations
  set(BUNDLE_NAMESPACE_DECLARATION "")
  foreach(SEGMENT ${PROJECT_NAME_SEGMENTS})
    string(CONCAT BUNDLE_NAMESPACE_DECLARATION "${BUNDLE_NAMESPACE_DECLARATION}" "namespace ${SEGMENT} {\n")
  endforeach()
  foreach(SEGMENT ${PROJECT_NAME_SEGMENTS})
    string(CONCAT BUNDLE_NAMESPACE_DECLARATION "${BUNDLE_NAMESPACE_DECLARATION}" "}\n")
  endforeach()

  # Generate the header file
  configure_file(${SL_BUNDLE_FUNCTIONS_DIR}/Bundle.h.in
                 ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/Bundle.h)
  set(SL_BUNDLE_HEADER_TARGET "${PROJECT_NAME}_BUNDLE_HEADER")
  add_custom_target(${SL_BUNDLE_HEADER_TARGET} DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}/Bundle.h)

  # Add the bundle header target as a dependency of the specified targets
  foreach(TARGET_NAME ${ARGN})
    add_dependencies(${TARGET_NAME} ${SL_BUNDLE_HEADER_TARGET})
    target_include_directories(${TARGET_NAME} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
  endforeach()
endfunction()
