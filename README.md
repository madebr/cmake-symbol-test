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

Combine tests by using the linker.

| Compiler (Generator)              | Normal Checks | Parallel Checks | Speedup |
|-----------------------------------|---------------|-----------------|---------|
| gcc 15.2.0 (Unix Makefiles)       | 11s           | <1s             | ~10s    |
| gcc 15.2.1 (Ninja)                | 14s           | <1s             | ~13s    |
| LLVM 21 (Unix Makefiles)          | 19s           | <2s             | ~16s    |
| Apple-LLVM 21 (Unix Makefiles)    | 22s           | <1s             | ~21s    |
| MSVC 2022 (Visual Studio 17 2022) | 77s           | <1s             | ~76s    |
