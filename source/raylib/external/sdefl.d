// quick binding for sdefl. probably we can just implement the whole thing here
// pretty easily.
module raylib.external.sdefl;

extern(C) nothrow @nogc:

enum SDEFL_MAX_OFF = (1 << 15);
enum SDEFL_WIN_SIZ = SDEFL_MAX_OFF;
enum SDEFL_WIN_MSK = (SDEFL_WIN_SIZ-1);

enum SDEFL_HASH_BITS = 15;
enum SDEFL_HASH_SIZ = (1 << SDEFL_HASH_BITS);
enum SDEFL_HASH_MSK = (SDEFL_HASH_SIZ-1);

enum SDEFL_MIN_MATCH = 4;
enum SDEFL_BLK_MAX = (256*1024);
enum SDEFL_SEQ_SIZ = ((SDEFL_BLK_MAX + SDEFL_MIN_MATCH)/SDEFL_MIN_MATCH);

enum SDEFL_SYM_MAX = (288);
enum SDEFL_OFF_MAX = (32);
enum SDEFL_PRE_MAX = (19);

enum SDEFL_LVL_MIN = 0;
enum SDEFL_LVL_DEF = 5;
enum SDEFL_LVL_MAX = 8;

struct sdefl_freq {
  uint[SDEFL_SYM_MAX] lit;
  uint[SDEFL_OFF_MAX] off;
}
struct sdefl_code_words {
  uint[SDEFL_SYM_MAX] lit;
  uint[SDEFL_OFF_MAX] off;
}
struct sdefl_lens {
  ubyte[SDEFL_SYM_MAX] lit;
  ubyte[SDEFL_OFF_MAX] off;
}
struct sdefl_codes {
  sdefl_code_words word;
  sdefl_lens len;
}
struct sdefl_seqt {
  int off, len;
};
struct sdefl {
  int bits, bitcnt;
  int[SDEFL_HASH_SIZ] tbl;
  int[SDEFL_WIN_SIZ] prv;

  int seq_cnt;
  sdefl_seqt[SDEFL_SEQ_SIZ] seq;
  sdefl_freq freq;
  sdefl_codes cod;
};
int sdefl_bound(int in_len);
int sdeflate(sdefl *s, void *o, const void *i, int n, int lvl);
int zsdeflate(sdefl *s, void *o, const void *i, int n, int lvl);
