function(parallel_check_include_file)
    cmake_parse_arguments(ARG "" "" "CHECKS" ${ARGN})

    set(c_ifdefs "")
    set(c_main_body "")
    set(i 0)

    set(header_var_list )

    list(LENGTH ARG_CHECKS arg_checks_length)

    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")

        if(DEFINED CACHE{${var}})
            continue()
        endif()

        list(APPEND header_var_list "${header}" "${var}")

        message(STATUS "Performing Parallel Test ${var}")

        string(APPEND c_ifdefs "#if __has_include(<${header}>)\n#define M${i} \"1\"\n#else\n#define M${i} \"0\"\n#endif\nconst char *V${i} = \"INFO[${var}=\" M${i} \"]\";\n")
        string(APPEND c_main_body "  result += V${i}[argc];\n")
    endwhile()

    list(LENGTH header_var_list length_header_var_list)
    if(length_header_var_list EQUAL 0)
        return()
    endif()
    string(MD5 md5_list "${header_var_list}")

    set(src "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks.c")
    set(bin "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks_bin")

    file(WRITE "${src}" "${c_ifdefs}int main(int argc, char *argv[]) {\n  int result = 0;  \n  (void)argv;\n${c_main_body}  return result;\n}\n")
    try_compile(COMPILED "${CMAKE_CURRENT_BINARY_DIR}/tt" SOURCES "${src}"
        COPY_FILE "${bin}"
    )
    if(NOT COMPILED)
        message(FATAL_ERROR "FIXME: Failure to build -> fall back")
    endif()

    set(i 0)
    while (i LESS length_header_var_list)
        list(GET header_var_list "${i}" header)
        math(EXPR i "${i} + 1")
        list(GET header_var_list "${i}" var)
        math(EXPR i "${i} + 1")

        set(re "INFO\\[${var}=(1|0)\\]")
        file(STRINGS "${bin}" has_include REGEX "${re}")

        if(NOT has_include)
            continue()
        endif()

        string(REGEX MATCH "${re}" yes_no "${has_include}")
        if(CMAKE_MATCH_1)
            message(STATUS "Performing Parallel Test ${var} - Success")
            set(v "1")
        else()
            message(STATUS "Performing Parallel Test ${var} - Failed")
            set(v "")
        endif()

        set("${var}" "${v}" CACHE INTERNAL "Have include ${header}")
    endwhile()
endfunction()

function(parallel_check_cxx_symbol_exists)
    cmake_parse_arguments(ARG "" "" "CHECKS;HEADERS" ${ARGN})

    set(src_hdr)
    foreach(hdr IN LISTS ARG_HEADERS)
        string(APPEND header_include_str "#include <${hdr}>\n")
    endforeach()

    list(LENGTH ARG_CHECKS arg_checks_length)

    set(cpp_checks "")
    set(cpp_main_body "")
    set(list )

    set(i 0)
    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" symbol)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" first)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" count)
        math(EXPR i "${i} + 1")

        if(DEFINED CACHE{${var}})
            continue()
        endif()

        list(APPEND list "${var}" "${symbol}" "${first}" "${var}")

        message(STATUS "Performing Parallel Test ${var}")

        set(extra_args)
        set(a 1)
        while(a LESS ${count})
            string(APPEND extra_args ", 0")
            math(EXPR a "${a}+1")
        endwhile()

        string(APPEND cpp_checks "void ${symbol}() = delete;\ntemplate<typename T> concept Has_${symbol} = requires (T t) { ::${symbol}(t${extra_args}); };\nconstexpr const char *has_${symbol} = Has_${symbol}<${first}> ? \"INFO[${var}=1]\" : \"INFO[${var}=0]\";\n\n")
        string(APPEND cpp_main_body "  result += has_${symbol}[argc];\n")
    endwhile()

    list(LENGTH list length_list)
    if(length_list EQUAL 0)
        return()
    endif()
    string(MD5 md5_list "${list}")

    set(src "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks.cpp")
    set(bin "${CMAKE_CURRENT_BINARY_DIR}/${md5_list}_parallel_checks_bin")

    file(WRITE "${src}" "${header_include_str}\n${cpp_checks}int main(int argc, char *argv[]) {\n  int result = 0;  \n  (void)argv;\n${cpp_main_body}  return result;\n}\n")
    try_compile(COMPILED "${CMAKE_CURRENT_BINARY_DIR}/tt" SOURCES "${src}"
        COPY_FILE "${bin}"
        CXX_STANDARD 20
    )
    if(NOT COMPILED)
        message(FATAL_ERROR "FIXME: Failure to build -> fall back")
    endif()

    set(i 0)
    while(i LESS length_list)
        list(GET list "${i}" var)
        math(EXPR i "${i} + 1")
        list(GET list "${i}" symbol)
        math(EXPR i "${i} + 1")
        list(GET list "${i}" first)
        math(EXPR i "${i} + 1")
        list(GET list "${i}" count)
        math(EXPR i "${i} + 1")

        set(re "INFO\\[${var}=(1|0)\\]")
        file(STRINGS "${bin}" has_var REGEX "${re}")

#        message("re: ${has_var}")

        if(NOT has_var)
            continue()
        endif()

        string(REGEX MATCH "${re}" yes_no "${has_var}")
        if(CMAKE_MATCH_1)
            message(STATUS "Performing Parallel Test ${var} - Success")
            set(v "1")
        else()
            message(STATUS "Performing Parallel Test ${var} - Failed")
            set(v "")
        endif()

        set("${var}" "${v}" CACHE INTERNAL "Have include ${header}")
    endwhile()
endfunction()

include(CheckSymbolExists)
include(CheckCSourceCompiles)

function(serial_check_c_symbol_exists)
    cmake_parse_arguments(ARG "" "" "CHECKS;HEADERS" ${ARGN})
    set(i 0)

    set(src_hdr)
    foreach(hdr IN LISTS ARG_HEADERS)
        string(APPEND src_hdr "#include <${hdr}>\n")
    endforeach()

    list(LENGTH ARG_CHECKS arg_checks_length)

    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" symbol)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" first)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" count)
        math(EXPR i "${i} + 1")

        set(args "0")
        set(a 1)
        while(a LESS ${count})
            string(APPEND args ", 0")
            math(EXPR a "${a}+1")
        endwhile()


        set(src "${src_hdr}int main() {\n ${symbol}(${args});\n return 0;\n}\n")

        #check_symbol_exists("${symbol}" "${header_list}" "${var}_REFERENCE")
        check_c_source_compiles("${src}" "${var}_REFERENCE")

    endwhile()
endfunction()


function(compare_check_symbol_checks CHECKS)
    cmake_parse_arguments(ARG "" "" "CHECKS;HEADERS" ${ARGN})

    list(LENGTH ARG_CHECKS arg_checks_length)

    set(i 0)
    set(issues)
    while (i LESS arg_checks_length)
        list(GET ARG_CHECKS "${i}" var)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" symbol)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" first)
        math(EXPR i "${i} + 1")
        list(GET ARG_CHECKS "${i}" count)
        math(EXPR i "${i} + 1")

        set(ref "${${var}_REFERENCE}")
        set(got "${${var}}")

        if(NOT ref STREQUAL got)
            list(APPEND issues ${var})
        endif()

        message(STATUS "ref=${ref} got=${got}          ${var}")
    endwhile()
    if(issues)
        message(WARNING "These checks don't match: ${issues}")
    else()
        message(STATUS "All checks match!")
    endif()
endfunction()
