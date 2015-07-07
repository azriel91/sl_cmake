set(SL_BLOCK_FUNCTIONS_DIR ${CMAKE_CURRENT_LIST_DIR})

#======================================================================================================================#
# [PUBLIC/USER]
#
# ADAPT_TARGETS_FOR_CPPMICROSERVICES()
#
# Adapt a block to a CppMicroServices module. This handles building the block as both static and shared libraries.
#
#======================================================================================================================#
function(ADAPT_TARGETS_FOR_CPPMICROSERVICES )
  set(macro_args ${ARGN})
  list(LENGTH macro_args arg_count)

  set(target_name )
  if (${arg_count} EQUAL 0)
    set(target_name ${BII_LIB_TARGET})
  else()
    list(GET macro_args 0 target_name)
  endif()
  message("Generating Block header and linking to target: ${target_name}")

  SL_GENERATE_AND_LINK_BLOCK_HEADER(${target_name})

  set_property(TARGET ${target_name} APPEND PROPERTY COMPILE_DEFINITIONS US_MODULE_NAME=${BII_BLOCK_NAME})

  # Indicate this is a static module if we aren't building shared libraries
  if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(${target_name} PRIVATE US_STATIC_MODULE)
  endif()
endfunction()

#======================================================================================================================#
# [PUBLIC/USER]
#
# SL_INCLUDE_TESTS(${BII_path_to_test1_TARGET}
#                  ${BII_path_to_test2_TARGET}
#                  ...)
#
# Includes the "test" directory if it exists
#
#======================================================================================================================#
function(SL_INCLUDE_TESTS )
  set(TEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/test")
  if(NOT ${BII_IS_DEP} AND EXISTS ${TEST_DIR} AND IS_DIRECTORY ${TEST_DIR})

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
# SL_GENERATE_AND_LINK_BLOCK_HEADER(target_name)
#
# Generates a "Block.h" header file that contains the c++ library export definition and sets 'ns' as an alias for the
# block namespace.
#
# For example, for a block called sl_core_application:
# - the export macro is SL_CORE_APPLICATION_EXPORT
# - the block namespace is sl::core::application
#
#======================================================================================================================#
function(SL_GENERATE_AND_LINK_BLOCK_HEADER target_name)
  string(TOUPPER ${BII_BLOCK_NAME} BII_BLOCK_NAME_UPPER) # used in Block.h.in
  string(REGEX MATCHALL "([^_]+)+" BII_BLOCK_NAME_SEGMENTS ${BII_BLOCK_NAME})

  # Generate the namespace <segment> {} declarations
  set(BLOCK_NAMESPACE_DECLARATION "")
  foreach(SEGMENT ${BII_BLOCK_NAME_SEGMENTS})
    string(CONCAT BLOCK_NAMESPACE_DECLARATION "${BLOCK_NAMESPACE_DECLARATION}" "namespace ${SEGMENT} {\n")
  endforeach()
  foreach(SEGMENT ${BII_BLOCK_NAME_SEGMENTS})
    string(CONCAT BLOCK_NAMESPACE_DECLARATION "${BLOCK_NAMESPACE_DECLARATION}" "}\n")
  endforeach()

  # Generate the header file
  configure_file(${SL_BLOCK_FUNCTIONS_DIR}/Block.h.in
                 ${CMAKE_CURRENT_BINARY_DIR}/${BII_BLOCK_NAME}/Block.h)
  set(SL_BLOCK_HEADER_TARGET "${BII_BLOCK_NAME}_BLOCK_HEADER")
  add_custom_target(${SL_BLOCK_HEADER_TARGET} DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BII_BLOCK_NAME}/Block.h)

  # Add the block header target as a dependency of the specified target
  add_dependencies(${target_name} ${SL_BLOCK_HEADER_TARGET})
  target_include_directories(${target_name} PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
endfunction()
