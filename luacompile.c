#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>

// Function to write bytecode to file
static int writer(lua_State *L, const void *p, size_t size, void *ud) {
  FILE *file = (FILE *)ud;
  fwrite(p, size, 1, file);
  return 0;
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <input.lua> <output.luac>\n", argv[0]);
    return 1;
  }

  const char *input_file = argv[1];
  const char *output_file = argv[2];

  lua_State *L = luaL_newstate();
  if (L == NULL) {
    fprintf(stderr, "Cannot create Lua state\n");
    return 1;
  }

  if (luaL_loadfile(L, input_file)) {
    fprintf(stderr, "Error loading file: %s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  FILE *file = fopen(output_file, "wb");
  if (file == NULL) {
    fprintf(stderr, "Cannot open output file: %s\n", output_file);
    lua_close(L);
    return 1;
  }

  if (lua_dump(L, writer, file) != 0) {
    fprintf(stderr, "Error dumping bytecode\n");
    fclose(file);
    lua_close(L);
    return 1;
  }

  fclose(file);
  lua_close(L);
  printf("Bytecode saved to %s\n", output_file);
  return 0;
}