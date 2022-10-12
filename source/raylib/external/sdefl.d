module raylib.external.sdefl;
@nogc nothrow extern(C):
package(raylib): // for internal use only

import core.stdc.config: c_long, c_ulong;
/*# Small Deflate
`sdefl` is a small bare bone lossless compression library in ANSI C (ISO C90)
which implements the Deflate (RFC 1951) compressed data format specification standard.
It is mainly tuned to get as much speed and compression ratio from as little code
as needed to keep the implementation as concise as possible.

## Features
- Portable single header and source file duo written in ANSI C (ISO C90)
- Dual license with either MIT or public domain
- Small implementation
    - Deflate: 525 LoC
    - Inflate: 320 LoC
- Webassembly:
    - Deflate ~3.7 KB (~2.2KB compressed)
    - Inflate ~3.6 KB (~2.2KB compressed)

## Usage:
This file behaves differently depending on what symbols you define
before including it.

Header-File mode:
If you do not define `SDEFL_IMPLEMENTATION` before including this file, it
will operate in header only mode. In this mode it declares all used structs
and the API of the library without including the implementation of the library.

Implementation mode:
If you define `SDEFL_IMPLEMENTATION` before including this file, it will
compile the implementation . Make sure that you only include
this file implementation in *one* C or C++ file to prevent collisions.

### Benchmark

| Compressor name         | Compression| Decompress.| Compr. size | Ratio |
| ------------------------| -----------| -----------| ----------- | ----- |
| miniz 1.0 -1            |   122 MB/s |   208 MB/s |    48510028 | 48.51 |
| miniz 1.0 -6            |    27 MB/s |   260 MB/s |    36513697 | 36.51 |
| miniz 1.0 -9            |    23 MB/s |   261 MB/s |    36460101 | 36.46 |
| zlib 1.2.11 -1          |    72 MB/s |   307 MB/s |    42298774 | 42.30 |
| zlib 1.2.11 -6          |    24 MB/s |   313 MB/s |    36548921 | 36.55 |
| zlib 1.2.11 -9          |    20 MB/s |   314 MB/s |    36475792 | 36.48 |
| sdefl 1.0 -0            |   127 MB/s |   371 MB/s |    40004116 | 39.88 |
| sdefl 1.0 -1            |   111 MB/s |   398 MB/s |    38940674 | 38.82 |
| sdefl 1.0 -5            |    45 MB/s |   420 MB/s |    36577183 | 36.46 |
| sdefl 1.0 -7            |    38 MB/s |   423 MB/s |    36523781 | 36.41 |
| libdeflate 1.3 -1       |   147 MB/s |   667 MB/s |    39597378 | 39.60 |
| libdeflate 1.3 -6       |    69 MB/s |   689 MB/s |    36648318 | 36.65 |
| libdeflate 1.3 -9       |    13 MB/s |   672 MB/s |    35197141 | 35.20 |
| libdeflate 1.3 -12      |  8.13 MB/s |   670 MB/s |    35100568 | 35.10 |

### Compression
Results on the [Silesia compression corpus](http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia):

| File    |   Original | `sdefl 0`  	| `sdefl 5` 	| `sdefl 7` |
| :------ | ---------: | -----------------: | ---------: | ----------: |
| dickens | 10.192.446 |  4,260,187|  3,845,261|   3,833,657 |
| mozilla | 51.220.480 | 20,774,706 | 19,607,009 |  19,565,867 |
| mr      |  9.970.564 | 3,860,531 |  3,673,460 |   3,665,627 |
| nci     | 33.553.445 | 4,030,283 |  3,094,526 |   3,006,075 |
| ooffice |  6.152.192 | 3,320,063 |  3,186,373 |   3,183,815 |
| osdb    | 10.085.684 | 3,919,646 |  3,649,510 |   3,649,477 |
| reymont |  6.627.202 | 2,263,378 |  1,857,588 |   1,827,237 |
| samba   | 21.606.400 | 6,121,797 |  5,462,670 |   5,450,762 |
| sao     |  7.251.944 | 5,612,421 |  5,485,380 |   5,481,765 |
| webster | 41.458.703 | 13,972,648 | 12,059,432 |  11,991,421 |
| xml     |  5.345.280 | 886,620|    674,009 |     662,141 |
| x-ray   |  8.474.240 | 6,304,655 |  6,244,779 |   6,244,779 |

## License
```
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2020 Micha Mettke
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
```
*/
 
enum SDEFL_MAX_OFF =   (1 << 15);
enum SDEFL_WIN_SIZ =   SDEFL_MAX_OFF;
enum SDEFL_WIN_MSK =   (SDEFL_WIN_SIZ-1);

enum SDEFL_HASH_BITS = 15;
enum SDEFL_HASH_SIZ =  (1 << SDEFL_HASH_BITS);
enum SDEFL_HASH_MSK =  (SDEFL_HASH_SIZ-1);

enum SDEFL_MIN_MATCH = 4;
enum SDEFL_BLK_MAX =   (256*1024);
enum SDEFL_SEQ_SIZ =   ((SDEFL_BLK_MAX + SDEFL_MIN_MATCH)/SDEFL_MIN_MATCH);

enum SDEFL_SYM_MAX =   (288);
enum SDEFL_OFF_MAX =   (32);
enum SDEFL_PRE_MAX =   (19);

enum SDEFL_LVL_MIN =   0;
enum SDEFL_LVL_DEF =   5;
enum SDEFL_LVL_MAX =   8;

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
  int off;int len;
}
struct sdefl {
  int bits;int bitcnt;
  int[SDEFL_HASH_SIZ] tbl;
  int[SDEFL_WIN_SIZ] prv;

  int seq_cnt;
  sdefl_seqt[SDEFL_SEQ_SIZ] seq;
  sdefl_freq freq;
  sdefl_codes cod;
}
 /* SDEFL_H_INCLUDED */


import core.stdc.assert_; /* assert */
import core.stdc.string; /* memcpy */
import core.stdc.limits; /* CHAR_BIT */

enum SDEFL_NIL =               (-1);
enum SDEFL_MAX_MATCH =         258;
enum SDEFL_MAX_CODE_LEN =      (15);
enum SDEFL_SYM_BITS =          (10u);
enum SDEFL_SYM_MSK =           ((1u << SDEFL_SYM_BITS)-1u);
enum SDEFL_LIT_LEN_CODES =     (14);
enum SDEFL_OFF_CODES =         (15);
enum SDEFL_PRE_CODES =         (7);
auto SDEFL_CNT_NUM(int n) { return ((((n)+3u/4u)+3u)&~3u); }
enum SDEFL_EOB =               (256);

auto sdefl_npow2(int n) { return  (1 << (sdefl_ilog2((n)-1) + 1)); }

private int sdefl_ilog2(int n) {
  import core.bitop : bsr;
  if (!n) return 0;
  return bsr(n);
  /+ This is the C implementation, but D has better options
version (_MSC_VER) {
  c_ulong msbp = 0;
  _BitScanReverse(&msbp, cast(c_ulong)n);
  return cast(int)msbp;
} else static if (HasVersion!"__GNUC__" || HasVersion!"__clang__") {
  return cast(int)(c_ulong).sizeof * CHAR_BIT - 1 - __builtin_clzl(cast(c_ulong)n);
} else {
  enum string lt(string n) = ` n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n`;
  static const(char)[256] tbl = [
    0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,lt(4), lt(5), lt(5), lt(6), lt(6), lt(6), lt(6),
    lt(7), lt(7), lt(7), lt(7), lt(7), lt(7), lt(7), lt(7)];
  int tt;int t;
  if ((tt = (n >> 16))) {
    return (t = (tt >> 8)) ? 24 + tbl[t] : 16 + tbl[tt];
  } else {
    return (t = (n >> 8)) ? 8 + tbl[t] : tbl[n];
  }
  }+/
}
private uint sdefl_uload32(const(void)* p) {
  /* hopefully will be optimized to an unaligned read */
  uint n = 0;
  memcpy(&n, p, n.sizeof);
  return n;
}
private uint sdefl_hash32(const(void)* p) {
  uint n = sdefl_uload32(p);
  return (n * 0x9E377989) >> (32 - SDEFL_HASH_BITS);
}
private void sdefl_put(ubyte** dst, sdefl* s, int code, int bitcnt) {
  s.bits |= (code << s.bitcnt);
  s.bitcnt += bitcnt;
  while (s.bitcnt >= 8) {
    ubyte* tar = *dst;
    *tar = cast(ubyte)(s.bits & 0xFF);
    s.bits >>= 8;
    s.bitcnt -= 8;
    *dst = *dst + 1;
  }
}
private void sdefl_heap_sub(uint* A, uint len, uint sub) {
  uint c;uint p = sub;
  uint v = A[sub];
  while ((c = p << 1) <= len) {
    if (c < len && A[c + 1] > A[c]) c++;
    if (v >= A[c]) break;
    A[p] = A[c], p = c;
  }
  A[p] = v;
}
private void sdefl_heap_array(uint* A, uint len) {
  uint sub;
  for (sub = len >> 1; sub >= 1; sub--)
    sdefl_heap_sub(A, len, sub);
}
private void sdefl_heap_sort(uint* A, uint n) {
  A--;
  sdefl_heap_array(A, n);
  while (n >= 2) {
    uint tmp = A[n];
    A[n--] = A[1];
    A[1] = tmp;
    sdefl_heap_sub(A, n, 1);
  }
}
private uint sdefl_sort_sym(uint sym_cnt, uint* freqs, ubyte* lens, uint* sym_out) {
  uint[SDEFL_CNT_NUM(SDEFL_SYM_MAX)] cnts = 0;
  uint cnt_num = SDEFL_CNT_NUM(sym_cnt);
  uint used_sym = 0;
  uint sym;uint i;
  for (sym = 0; sym < sym_cnt; sym++)
    cnts[freqs[sym] < cnt_num-1 ? freqs[sym]: cnt_num-1]++;
  for (i = 1; i < cnt_num; i++) {
    uint cnt = cnts[i];
    cnts[i] = used_sym;
    used_sym += cnt;
  }
  for (sym = 0; sym < sym_cnt; sym++) {
    uint freq = freqs[sym];
    if (freq) {
        uint idx = freq < cnt_num-1 ? freq : cnt_num-1;
        sym_out[cnts[idx]++] = sym | (freq << SDEFL_SYM_BITS);
    } else lens[sym] = 0;
  }
  sdefl_heap_sort(sym_out + cnts[cnt_num-2], cnts[cnt_num-1] - cnts[cnt_num-2]);
  return used_sym;
}
private void sdefl_build_tree(uint* A, uint sym_cnt) {
  uint i = 0;uint b = 0;uint e = 0;
  do {
    uint m;uint n;uint freq_shift;
    if (i != sym_cnt && (b == e || (A[i] >> SDEFL_SYM_BITS) <= (A[b] >> SDEFL_SYM_BITS)))
      m = i++;
    else m = b++;
    if (i != sym_cnt && (b == e || (A[i] >> SDEFL_SYM_BITS) <= (A[b] >> SDEFL_SYM_BITS)))
      n = i++;
    else n = b++;

    freq_shift = (A[m] & ~SDEFL_SYM_MSK) + (A[n] & ~SDEFL_SYM_MSK);
    A[m] = (A[m] & SDEFL_SYM_MSK) | (e << SDEFL_SYM_BITS);
    A[n] = (A[n] & SDEFL_SYM_MSK) | (e << SDEFL_SYM_BITS);
    A[e] = (A[e] & SDEFL_SYM_MSK) | freq_shift;
  } while (sym_cnt - ++e > 1);
}
private void sdefl_gen_len_cnt(uint* A, uint root, uint* len_cnt, uint max_code_len) {
  int n;
  uint i;
  for (i = 0; i <= max_code_len; i++)
    len_cnt[i] = 0;
  len_cnt[1] = 2;

  A[root] &= SDEFL_SYM_MSK;
  for (n = cast(int)root - 1; n >= 0; n--) {
    uint p = A[n] >> SDEFL_SYM_BITS;
    uint pdepth = A[p] >> SDEFL_SYM_BITS;
    uint depth = pdepth + 1;
    uint len = depth;

    A[n] = (A[n] & SDEFL_SYM_MSK) | (depth << SDEFL_SYM_BITS);
    if (len >= max_code_len) {
      len = max_code_len;
      do len--; while (!len_cnt[len]);
    }
    len_cnt[len]--;
    len_cnt[len+1] += 2;
  }
}
private void sdefl_gen_codes(uint* A, ubyte* lens, const(uint)* len_cnt, uint max_code_word_len, uint sym_cnt) {
  uint i;uint sym;uint len;uint[SDEFL_MAX_CODE_LEN + 1] nxt;
  for (i = 0, len = max_code_word_len; len >= 1; len--) {
    uint cnt = len_cnt[len];
    while (cnt--) lens[A[i++] & SDEFL_SYM_MSK] = cast(ubyte)len;
  }
  nxt[0] = nxt[1] = 0;
  for (len = 2; len <= max_code_word_len; len++)
    nxt[len] = (nxt[len-1] + len_cnt[len-1]) << 1;
  for (sym = 0; sym < sym_cnt; sym++)
    A[sym] = nxt[lens[sym]]++;
}
private uint sdefl_rev(uint c, ubyte n) {
  c = ((c & 0x5555) << 1) | ((c & 0xAAAA) >> 1);
  c = ((c & 0x3333) << 2) | ((c & 0xCCCC) >> 2);
  c = ((c & 0x0F0F) << 4) | ((c & 0xF0F0) >> 4);
  c = ((c & 0x00FF) << 8) | ((c & 0xFF00) >> 8);
  return c >> (16-n);
}
private void sdefl_huff(ubyte* lens, uint* codes, uint* freqs, uint num_syms, uint max_code_len) {
  uint c;uint* A = codes;
  uint[SDEFL_MAX_CODE_LEN + 1] len_cnt;
  uint used_syms = sdefl_sort_sym(num_syms, freqs, lens, A);
  if (!used_syms) return;
  if (used_syms == 1) {
    uint s = A[0] & SDEFL_SYM_MSK;
    uint i = s ? s : 1;
    codes[0] = 0, lens[0] = 1;
    codes[i] = 1, lens[i] = 1;
    return;
  }
  sdefl_build_tree(A, used_syms);
  sdefl_gen_len_cnt(A, used_syms-2, len_cnt.ptr, max_code_len);
  sdefl_gen_codes(A, lens, len_cnt.ptr, max_code_len, num_syms);
  for (c = 0; c < num_syms; c++) {
    codes[c] = sdefl_rev(codes[c], lens[c]);
  }
}
struct sdefl_symcnt {
  int items;
  int lit;
  int off;
}
private void sdefl_precode(sdefl_symcnt* cnt, uint* freqs, uint* items, const(ubyte)* litlen, const(ubyte)* offlen) {
  uint* at = items;
  uint run_start = 0;

  uint total = 0;
  ubyte[SDEFL_SYM_MAX + SDEFL_OFF_MAX] lens;
  for (cnt.lit = SDEFL_SYM_MAX; cnt.lit > 257; cnt.lit--)
    if (litlen[cnt.lit - 1]) break;
  for (cnt.off = SDEFL_OFF_MAX; cnt.off > 1; cnt.off--)
    if (offlen[cnt.off - 1]) break;

  total = cast(uint)(cnt.lit + cnt.off);
  memcpy(lens.ptr, litlen, ubyte.sizeof * cast(size_t)cnt.lit);
  memcpy(lens.ptr + cnt.lit, offlen, ubyte.sizeof * cast(size_t)cnt.off);
  do {
    uint len = lens[run_start];
    uint run_end = run_start;
    do run_end++; while (run_end != total && len == lens[run_end]);
    if (!len) {
      while ((run_end - run_start) >= 11) {
        uint n = (run_end - run_start) - 11;
        uint xbits = n < 0x7f ? n : 0x7f;
        freqs[18]++;
        *at++ = 18u | (xbits << 5u);
        run_start += 11 + xbits;
      }
      if ((run_end - run_start) >= 3) {
        uint n = (run_end - run_start) - 3;
        uint xbits = n < 0x7 ? n : 0x7;
        freqs[17]++;
        *at++ = 17u | (xbits << 5u);
        run_start += 3 + xbits;
      }
    } else if ((run_end - run_start) >= 4) {
      freqs[len]++;
      *at++ = len;
      run_start++;
      do {
        uint xbits = (run_end - run_start) - 3;
        xbits = xbits < 0x03 ? xbits : 0x03;
        *at++ = 16 | (xbits << 5);
        run_start += 3 + xbits;
        freqs[16]++;
      } while ((run_end - run_start) >= 3);
    }
    while (run_start != run_end) {
      freqs[len]++;
      *at++ = len;
      run_start++;
    }
  } while (run_start != total);
  cnt.items = cast(int)(at - items);
}
struct sdefl_match_codes_t {
  int ls;int lc;
  int dc;int dx;
}
private void sdefl_match_codes(sdefl_match_codes_t* cod, int dist, int len) {
  static const(short)* dxmax = [0,6,12,24,48,96,192,384,768,1536,3072,6144,12288,24576];
  static const(ubyte)[258+1] lslot = [
    0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12,
    12, 13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16,
    16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18,
    18, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 20, 20, 20, 20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
    22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27, 28
  ];
  cod.ls = lslot[len];
  cod.lc = 257 + cod.ls;
  cod.dx = sdefl_ilog2(sdefl_npow2(dist) >> 2);
  cod.dc = cod.dx ? ((cod.dx + 1) << 1) + (dist > dxmax[cod.dx]) : dist-1;
}
private void sdefl_match(ubyte** dst, sdefl* s, int dist, int len) {
  static const(char)* lxn = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0];
  static const(short)* lmin = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,
      51,59,67,83,99,115,131,163,195,227,258];
  static const(short)* dmin = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,
      385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577];

  sdefl_match_codes_t cod;
  sdefl_match_codes(&cod, dist, len);
  sdefl_put(dst, s, cast(int)s.cod.word.lit[cod.lc], s.cod.len.lit[cod.lc]);
  sdefl_put(dst, s, len - lmin[cod.ls], lxn[cod.ls]);
  sdefl_put(dst, s, cast(int)s.cod.word.off[cod.dc], s.cod.len.off[cod.dc]);
  sdefl_put(dst, s, dist - dmin[cod.dc], cod.dx);
}
private void sdefl_flush(ubyte** dst, sdefl* s, int is_last, const(ubyte)* in_) {
  int j;int i = 0;int item_cnt = 0;
  sdefl_symcnt symcnt; // = {0}
  uint[SDEFL_PRE_MAX] codes;
  ubyte[SDEFL_PRE_MAX] lens;
  uint[SDEFL_PRE_MAX] freqs = 0;
  uint[SDEFL_SYM_MAX + SDEFL_OFF_MAX] items;
  static const(ubyte)[SDEFL_PRE_MAX] perm = [16,17,18,0,8,7,9,6,10,5,11,
      4,12,3,13,2,14,1,15];

  /* huffman codes */
  s.freq.lit[SDEFL_EOB]++;
  sdefl_huff(s.cod.len.lit.ptr, s.cod.word.lit.ptr, s.freq.lit.ptr, SDEFL_SYM_MAX, SDEFL_LIT_LEN_CODES);
  sdefl_huff(s.cod.len.off.ptr, s.cod.word.off.ptr, s.freq.off.ptr, SDEFL_OFF_MAX, SDEFL_OFF_CODES);
  sdefl_precode(&symcnt, freqs.ptr, items.ptr, s.cod.len.lit.ptr, s.cod.len.off.ptr);
  sdefl_huff(lens.ptr, codes.ptr, freqs.ptr, SDEFL_PRE_MAX, SDEFL_PRE_CODES);
  for (item_cnt = SDEFL_PRE_MAX; item_cnt > 4; item_cnt--) {
    if (lens[perm[item_cnt - 1]]) break;
  }
  /* block header */
  sdefl_put(dst, s, is_last ? 0x01 : 0x00, 1); /* block */
  sdefl_put(dst, s, 0x02, 2); /* dynamic huffman */
  sdefl_put(dst, s, symcnt.lit - 257, 5);
  sdefl_put(dst, s, symcnt.off - 1, 5);
  sdefl_put(dst, s, item_cnt - 4, 4);
  for (i = 0; i < item_cnt; ++i)
    sdefl_put(dst, s, lens[perm[i]], 3);
  for (i = 0; i < symcnt.items; ++i) {
    uint sym = items[i] & 0x1F;
    sdefl_put(dst, s, cast(int)codes[sym], lens[sym]);
    if (sym < 16) continue;
    if (sym == 16) sdefl_put(dst, s, items[i] >> 5, 2);
    else if(sym == 17) sdefl_put(dst, s, items[i] >> 5, 3);
    else sdefl_put(dst, s, items[i] >> 5, 7);
  }
  /* block sequences */
  for (i = 0; i < s.seq_cnt; ++i) {
    if (s.seq[i].off >= 0)
      for (j = 0; j < s.seq[i].len; ++j) {
        int c = in_[s.seq[i].off + j];
        sdefl_put(dst, s, cast(int)s.cod.word.lit[c], s.cod.len.lit[c]);
      }
    else sdefl_match(dst, s, -s.seq[i].off, s.seq[i].len);
  }
  sdefl_put(dst, s, cast(int)(s).cod.word.lit[SDEFL_EOB], (s).cod.len.lit[SDEFL_EOB]);
  memset(&s.freq, 0, typeof(s.freq).sizeof);
  s.seq_cnt = 0;
}
private void sdefl_seq(sdefl* s, int off, int len) {
  assert(s.seq_cnt + 2 < SDEFL_SEQ_SIZ);
  s.seq[s.seq_cnt].off = off;
  s.seq[s.seq_cnt].len = len;
  s.seq_cnt++;
}
private void sdefl_reg_match(sdefl* s, int off, int len) {
  sdefl_match_codes_t cod;
  sdefl_match_codes(&cod, off, len);
  s.freq.lit[cod.lc]++;
  s.freq.off[cod.dc]++;
}
struct sdefl_match_t {
  int off;
  int len;
}
private void sdefl_fnd(sdefl_match_t* m, const(sdefl)* s, int chain_len, int max_match, const(ubyte)* in_, int p) {
  int i = s.tbl[sdefl_hash32(&in_[p])];
  int limit = ((p-SDEFL_WIN_SIZ)<SDEFL_NIL)?SDEFL_NIL:(p-SDEFL_WIN_SIZ);
  while (i > limit) {
    if (in_[i+m.len] == in_[p+m.len] &&
        (sdefl_uload32(&in_[i]) == sdefl_uload32(&in_[p]))){
      int n = SDEFL_MIN_MATCH;
      while (n < max_match && in_[i+n] == in_[p+n]) n++;
      if (n > m.len) {
        m.len = n, m.off = p - i;
        if (n == max_match) break;
      }
    }
    if (!(--chain_len)) break;
    i = s.prv[i&SDEFL_WIN_MSK];
  }
}
private int sdefl_compr(sdefl* s, ubyte* out_, const(ubyte)* in_, int in_len, int lvl) {
  ubyte* q = out_;
  static const(ubyte)* pref = [8,10,14,24,30,48,65,96,130];
  int max_chain = (lvl < 8) ? (1 << (lvl + 1)): (1 << 13);
  int n;int i = 0;int litlen = 0;
  for (n = 0; n < SDEFL_HASH_SIZ; ++n) {
    s.tbl[n] = SDEFL_NIL;
  }
  do {int blk_end = i + SDEFL_BLK_MAX < in_len ? i + SDEFL_BLK_MAX : in_len;
    while (i < blk_end) {
      sdefl_match_t m; // = {0}
      int max_match = ((in_len-i)>SDEFL_MAX_MATCH) ? SDEFL_MAX_MATCH:(in_len-i);
      int nice_match = pref[lvl] < max_match ? pref[lvl] : max_match;
      int run = 1;int inc = 1;int run_inc;
      if (max_match > SDEFL_MIN_MATCH) {
        sdefl_fnd(&m, s, max_chain, max_match, in_, i);
      }
      if (lvl >= 5 && m.len >= SDEFL_MIN_MATCH && m.len < nice_match){
        sdefl_match_t m2; // = {0}
        sdefl_fnd(&m2, s, max_chain, m.len+1, in_, i+1);
        m.len = (m2.len > m.len) ? 0 : m.len;
      }
      if (m.len >= SDEFL_MIN_MATCH) {
        if (litlen) {
          sdefl_seq(s, i - litlen, litlen);
          litlen = 0;
        }
        sdefl_seq(s, -m.off, m.len);
        sdefl_reg_match(s, m.off, m.len);
        if (lvl < 2 && m.len >= nice_match) {
          inc = m.len;
        } else {
          run = m.len;
        }
      } else {
        s.freq.lit[in_[i]]++;
        litlen++;
      }
      run_inc = run * inc;
      if (in_len - (i + run_inc) > SDEFL_MIN_MATCH) {
        while (run-- > 0) {
          uint h = sdefl_hash32(&in_[i]);
          s.prv[i&SDEFL_WIN_MSK] = s.tbl[h];
          s.tbl[h] = i, i += inc;
        }
      } else {
        i += run_inc;
      }
    }
    if (litlen) {
      sdefl_seq(s, i - litlen, litlen);
      litlen = 0;
    }
    sdefl_flush(&q, s, blk_end == in_len, in_);
  } while (i < in_len);

  if (s.bitcnt)
    sdefl_put(&q, s, 0x00, 8 - s.bitcnt);
  return cast(int)(q - out_);
}
extern int sdeflate(sdefl* s, void* out_, const(void)* in_, int n, int lvl) {
  s.bits = s.bitcnt = 0;
  return sdefl_compr(s, cast(ubyte*)out_, cast(const(ubyte)*)in_, n, lvl);
}
enum SDEFL_ADLER_INIT = (1);
private uint sdefl_adler32(uint adler32, const(ubyte)* in_, int in_len) {
  const(uint) ADLER_MOD = 65521;
  uint s1 = adler32 & 0xffff;
  uint s2 = adler32 >> 16;
  uint blk_len;uint i;

  blk_len = in_len % 5552;
  while (in_len) {
    for (i = 0; i + 7 < blk_len; i += 8) {
      s1 += in_[0]; s2 += s1;
      s1 += in_[1]; s2 += s1;
      s1 += in_[2]; s2 += s1;
      s1 += in_[3]; s2 += s1;
      s1 += in_[4]; s2 += s1;
      s1 += in_[5]; s2 += s1;
      s1 += in_[6]; s2 += s1;
      s1 += in_[7]; s2 += s1;
      in_ += 8;
    }
    for (; i < blk_len; ++i) {
      s1 += *in_++, s2 += s1;
    }
    s1 %= ADLER_MOD;
    s2 %= ADLER_MOD;
    in_len -= blk_len;
    blk_len = 5552;
  }
  return cast(uint)(s2 << 16) + cast(uint)s1;
}
extern int zsdeflate(sdefl* s, void* out_, const(void)* in_, int n, int lvl) {
  int p = 0;
  uint a = 0;
  ubyte* q = cast(ubyte*)out_;

  s.bits = s.bitcnt = 0;
  sdefl_put(&q, s, 0x78, 8); /* deflate, 32k window */
  sdefl_put(&q, s, 0x01, 8); /* fast compression */
  q += sdefl_compr(s, q, cast(const(ubyte)*)in_, n, lvl);

  /* append adler checksum */
  a = sdefl_adler32(SDEFL_ADLER_INIT, cast(const(ubyte)*)in_, n);
  for (p = 0; p < 4; ++p) {
    sdefl_put(&q, s, (a >> 24) & 0xFF, 8);
    a <<= 8;
  }
  return cast(int)(q - cast(ubyte*)out_);
}
extern int sdefl_bound(int len) {
  int a = 128 + (len * 110) / 100;
  int b = 128 + len + ((len / (31 * 1024)) + 1) * 5;
  return (a > b) ? a : b;
}
