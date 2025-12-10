cmake_minimum_required(VERSION 3.6...4.0)
project(cmake-symbol-test LANGUAGES C)

include(parse_linker_output.cmake)

include(all_in_one.cmake)

option(PARALLEL_HEADER_CHECKS "Do Parallel Header Checks" ON)
option(SERIAL_HEADER_CHECKS "Do Serial Header Checks" ON)
option(PARALLEL_LINKER_SYMBOL_CHECKS "Do linker Parallel Symbol Checks" ON)
option(SERIAL_SYMBOL_CHECKS "Do Serial Symbol Checks" ON)

set(HEADERS_TO_CHECK
    float.h         HAVE_FLOAT_H
    iconv.h         HAVE_ICONV_H
    inttypes.h      HAVE_INTTYPES_H
    limits.h        HAVE_LIMITS_H
    malloc.h        HAVE_MALLOC_H
    math.h          HAVE_MATH_H
    memory.h        HAVE_MEMORY_H
    signal.h        HAVE_SIGNAL_H
    stdarg.h        HAVE_STDARG_H
    stddef.h        HAVE_STDDEF_H
    stdint.h        HAVE_STDINT_H
    stdio.h         HAVE_STDIO_H
    stdlib.h        HAVE_STDLIB_H
    string.h        HAVE_STRING_H
    strings.h       HAVE_STRINGS_H
    sys/types.h     HAVE_SYS_TYPES_H
    time.h          HAVE_TIME_H
    wchar.h         HAVE_WCHAR_H
)

if(PARALLEL_HEADER_CHECKS)
    string(TIMESTAMP start "%s")
    parallel_check_include_file(CHECKS ${HEADERS_TO_CHECK})
    string(TIMESTAMP end "%s")
    math(EXPR dt_parhdr "${end}-${start}")
else()
    math(EXPR dt_parhdr "UNKNOWN")
endif()

if(SERIAL_HEADER_CHECKS)
    string(TIMESTAMP start "%s")
    serial_check_include_file(CHECKS ${HEADERS_TO_CHECK})
    string(TIMESTAMP end "%s")
    math(EXPR dt_serhdr "${end}-${start}")
else()
    math(EXPR dt_serhdr "UNKNOWN")
endif()

set(known_headers)
set(i 0)
list(LENGTH HEADERS_TO_CHECK len_headers)
while(i LESS len_headers)
    list(GET HEADERS_TO_CHECK "${i}" header)
    math(EXPR i "${i} + 1")
    list(GET HEADERS_TO_CHECK "${i}" var)
    math(EXPR i "${i} + 1")
    set(b ${${var}})
    if(b)
        list(APPEND known_headers "${header}")
    endif()
endwhile()

message(STATUS "known_headers: ${known_headers}")

set(SYMBOLS
    abs acos acosf asin asinf atan atan2 atan2f atanf atof atoi
    bcopy
    ceil ceilf copysign copysignf cos cosf
    _Exit exp expf
    fabs fabsf floor floorf fmod fmodf fopen64 fseeko fseeko64
    getenv
    _i64toa index itoa
    log log10 log10f logf lround lroundf _ltoa
    malloc memcmp memcpy memmove memset modf modff
    pow powf putenv
    rindex round roundf
    scalbn scalbnf setenv sin sinf sqr sqrt sqrtf sscanf strchr
    strcmp strlcat strlcpy strlen strncmp strnlen strpbrk
    strrchr strstr strnstr strtod strtok_r strtol strtoll strtoul strtoull
    tan tanf trunc truncf
    unsetenv
    vsnprintf vsscanf
    wcsnlen wcscmp wcsdup wcslcat wcslcpy wcslen wcsncmp wcsstr wcstol

    _copysign _fseeki64 _strrev _ui64toa _uitoa _ultoa _wcsdup
    strcasestr
)

if(PARALLEL_LINKER_SYMBOL_CHECKS)
    string(TIMESTAMP start "%s")
    check_symbols_in_parallel(
        VAR_PREFIX LIBC_HAS_
        VAR_SUFFIX _LINKER
        VAR_UPPER
        HEADERS ${known_headers}
        SYMBOLS ${SYMBOLS}
    )
    string(TIMESTAMP end "%s")
    math(EXPR dt_parldsym "${end}-${start}")
else()
    math(EXPR dt_parldsym "UNKNOWN")
endif()

if(SERIAL_SYMBOL_CHECKS)
    string(TIMESTAMP start "%s")
    if(CMAKE_C_COMPILER_ID MATCHES "(GNU|Clang|AppleClang)")
        list(APPEND CMAKE_REQUIRED_LIBRARIES "m")
    endif()
    serial_check_c_symbol_exists(HEADERS ${known_headers} SYMBOLS ${SYMBOLS} PREFIX "LIBC_HAS_" SUFFIX "_REFERENCE")
    string(TIMESTAMP end "%s")
    math(EXPR dt_sersym "${end}-${start}")
else()
    math(EXPR dt_sersym "UNKNOWN")
endif()

set(RESULT_HEADERS TRUE)
if(PARALLEL_HEADER_CHECKS AND SERIAL_HEADER_CHECKS)
    compare_check_include_file(RESULT_HEADERS ${HEADERS_TO_CHECK})
endif()

set(RESULT_SYMBOLS TRUE)
if(PARALLEL_LINKER_SYMBOL_CHECKS AND SERIAL_SYMBOL_CHECKS)
    compare_check_symbol_checks(RESULT_SYMBOLS
        VAR_PREFIX_REF LIBC_HAS_
        VAR_SUFFIX_REF _REFERENCE
        VAR_PREFIX LIBC_HAS_
        VAR_SUFFIX _LINKER
        SYMBOLS ${SYMBOLS}
    )
endif()

message(STATUS "parallel header:         ${dt_parhdr}s")
message(STATUS "serial header:           ${dt_serhdr}s")
message(STATUS "parallel C++ symbols:    ${dt_parsym}s")
message(STATUS "serial symbols:          ${dt_sersym}s")
message(STATUS "parallel linker symbols: ${dt_parsym}s")

if(NOT RESULT_HEADERS OR NOT RESULT_SYMBOLS)
    message(FATAL_ERROR "Something did not match :(")
endif()
