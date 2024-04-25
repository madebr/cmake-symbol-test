# Run CMake compiler tests in parallel

This repo contains a proof of concept to combine multiple compiler tests in a single test.
The reduction of number of tests should result in faster CMake configuration.


## Combine header tests

Use `__has_include` of the preprocessor to conditionally include strings in binaries.
This is supported by gcc/clang/apple-clang/msvc.

| Compiler | Normal Checks | Parallel Checks | Speedup |
| - | - | - | - |
| gcc 13.2.1 (Ninja) | 1s | < 1s | ~1s |
| gcc 13.2.1 (Unix Makefiles) | 2s | < 1s | ~2s |
| MSVC 2019 (Ninja) | 7s | 1s | 6s |
| MSVC 2022 (Visual Studio 17 2022) | 13s | 8s | 5s |


example:
```c
#if __has_include(<float.h>)
#define M2 "1"
#else
#define M2 "0"
#endif
const char *V2 = "INFO[HAVE_FLOAT_H=" M2 "]";
#if __has_include(<iconv.h>)
#define M4 "1"
#else
#define M4 "0"
#endif
const char *V4 = "INFO[HAVE_ICONV_H=" M4 "]";
int main(int argc, char *argv[]) {
  int result = 0;  
  (void)argv;
  result += V2[argc];
  result += V4[argc];
  return result;
}
````

## Combine C symbol checks

Combine tests by using C++20's contracts.
This is supported by gcc>=12, and MSVC 2022+.

Some believe this approach relies on Ill-formed, no diagnostic required (IFNDR) behaviour.
This undefined behavior makes this approach a non-starter for broad usage.
We hope the speed-up encourages compiler developers to create a supported alternative. 

| Compiler | Normal Checks | Parallel Checks | Speedup |
| - | - | - | - |
| gcc 13.2.1 (Ninja) | 13s | <1s | ~13s |
| gcc 13.2.1 (Unix Makefiles) | 15s | <1s | ~15s |
| MSVC 2019 (Ninja) | 43s | 1s | 42s |
| MSVC 2022 (Visual Studio 17 2022) | 51s | 2s | 49s |

example:
```c++

void abs() = delete;
template<typename T> concept Has_abs = requires (T t) { ::abs(t); };
constexpr const char *has_abs = Has_abs<double> ? "INFO[LIBC_HAS_ABS=1]" : "INFO[LIBC_HAS_ABS=0]";

void acos() = delete;
template<typename T> concept Has_acos = requires (T t) { ::acos(t); };
constexpr const char *has_acos = Has_acos<double> ? "INFO[LIBC_HAS_ACOS=1]" : "INFO[LIBC_HAS_ACOS=0]";

int main(int argc, char *argv[]) {
  int result = 0;
  (void)argv;
  result += has_abs[argc];
  result += has_acos[argc];
  return result;
}
```
