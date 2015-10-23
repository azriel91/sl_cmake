set(SL_BUNDLE_FUNCTIONS_DIR ${CMAKE_CURRENT_LIST_DIR})

#======================================================================================================================#
# [PUBLIC/USER]
#
# adapt_for_cppmicroservices()
# adapt_for_cppmicroservices(target_name)
#
# Adapt a bundle to a CppMicroServices module. This handles building the bundle as both static and shared libraries.
#
#======================================================================================================================#
function(ADAPT_FOR_CPPMICROSERVICES )
  set(macro_args ${ARGN})
  list(LENGTH macro_args arg_count)

  set(target_name )
  if (${arg_count} EQUAL 0)
    set(target_name ${PROJECT_NAME})
  else()
    list(GET macro_args 0 target_name)
  endif()
  message("Generating Bundle header and linking to target: ${target_name}")

  sl_generate_and_link_bundle_header(${target_name})

  set_property(TARGET ${target_name} APPEND PROPERTY COMPILE_DEFINITIONS US_MODULE_NAME=${PROJECT_NAME})

  # Indicate this is a static module if we aren't building shared libraries
  if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(${target_name} PRIVATE US_STATIC_MODULE)
  endif()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# sl_include_tests(testTarget1
#                  testTarget2
#                  ...)
#
# Includes the "test" directory if it exists
#
#======================================================================================================================#
function(SL_INCLUDE_TESTS )
  set(TEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/test")
  if(EXISTS ${TEST_DIR} AND IS_DIRECTORY ${TEST_DIR})

    foreach(TEST_TARGET ${ARGN})
      # Need to tell GTest not to use std::tuple because CppMicroServices uses its own definition, and it causes a
      # redefinition error
      target_compile_definitions(${TEST_TARGET} PRIVATE GTEST_HAS_TR1_TUPLE=1 GTEST_USE_OWN_TR1_TUPLE=0)
    endforeach()

    add_subdirectory(test)
  endif()
endfunction()

#======================================================================================================================#
# [PRIVATE/INTERNAL]
#
# sl_generate_and_link_bundle_header(target_name)
#
# Generates a "Bundle.h" header file that contains the c++ library export definition.
#
# For example, for a bundle called sl_core_application:
# - the export macro is SL_CORE_APPLICATION_EXPORT
# - the bundle namespace is sl::core::application
#
#======================================================================================================================#
function(SL_GENERATE_AND_LINK_BUNDLE_HEADER target_name)
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

  # Add the bundle header target as a dependency of the specified target
  add_dependencies(${target_name} ${SL_BUNDLE_HEADER_TARGET})
  target_include_directories(${target_name} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
endfunction()
