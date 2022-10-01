// quick binding for sinfl. probably we can just implement the whole thing here
// pretty easily.
module raylib.external.sinfl;
import core.stdc.config;

extern(C) nothrow @nogc:

enum SINFL_PRE_TBL_SIZE = 128;
enum SINFL_LIT_TBL_SIZE = 1334;
enum SINFL_OFF_TBL_SIZE = 402;

struct sinfl {
  const ubyte *bitptr;
  __c_longlong bitbuf;
  int bitcnt;

  uint[SINFL_LIT_TBL_SIZE] lits;
  uint[SINFL_OFF_TBL_SIZE] dsts;
}

int sinflate(void *out_, int cap, const void *in_, int size);
int zsinflate(void *out_, int cap, const void *in_, int size);
