module raylib.external.sinfl;
@nogc nothrow extern(C):
package(raylib): // for internal use only

/*
# Small Deflate
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
If you do not define `SINFL_IMPLEMENTATION` before including this file, it
will operate in header only mode. In this mode it declares all used structs
and the API of the library without including the implementation of the library.

Implementation mode:
If you define `SINFL_IMPLEMENTATION` before including this file, it will
compile the implementation. Make sure that you only include
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

| File    |   Original | `sdefl 0`    | `sdefl 5`   | `sdefl 7` |
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
enum SINFL_PRE_TBL_SIZE = 128;
enum SINFL_LIT_TBL_SIZE = 1334;
enum SINFL_OFF_TBL_SIZE = 402;

struct sinfl {
  const(ubyte)* bitptr;
  ulong bitbuf;
  int bitcnt;

  uint[SINFL_LIT_TBL_SIZE] lits;
  uint[SINFL_OFF_TBL_SIZE] dsts;
};

import core.stdc.string; /* memcpy, memset */
import core.stdc.assert_; /* assert */

version(LDC)
{
    import ldc.intrinsics : llvm_expect;
    pragma(inline, true)
    bool sinfl_likely(bool x) { return llvm_expect(x, true); }
    pragma(inline, true)
    bool sinfl_unlikely(bool x) { return llvm_expect(x, false); }
} else {
    pragma(inline, true)
    bool sinfl_likely(bool x) { return x; }
    pragma(inline, true)
    bool sinfl_unlikely(bool x) { return x; }
}

import core.bitop : bsr;
private alias sinfl_bsr = bsr;

private ulong sinfl_read64(const(void)* p) {
  ulong n;
  memcpy(&n, p, 8);
  return n;
}

private ubyte* sinfl_write64(ubyte* dst, ulong w) {
  memcpy(dst, &w, 8);
  return dst + 8;
}
private void sinfl_copy64(ubyte** dst, ubyte** src) {
  ulong n;
  memcpy(&n, *src, 8);
  memcpy(*dst, &n, 8);
  *dst += 8, *src += 8;
}
private void sinfl_refill(sinfl* s) {
  s.bitbuf |= sinfl_read64(s.bitptr) << s.bitcnt;
  s.bitptr += (63 - s.bitcnt) >> 3;
  s.bitcnt |= 56; /* bitcount is in range [56,63] */
}
private int sinfl_peek(sinfl* s, int cnt) {
  assert(cnt >= 0 && cnt <= 56);
  assert(cnt <= s.bitcnt);
  // Is this cast right?
  return cast(int)(s.bitbuf & ((1UL << cnt) - 1));
}
private void sinfl_consume(sinfl* s, int cnt) {
  assert(cnt <= s.bitcnt);
  s.bitbuf >>= cnt;
  s.bitcnt -= cnt;
}
private int sinfl__get(sinfl* s, int cnt) {
  int res = sinfl_peek(s, cnt);
  sinfl_consume(s, cnt);
  return res;
}
private int sinfl_get(sinfl* s, int cnt) {
  sinfl_refill(s);
  return sinfl__get(s, cnt);
}
struct sinfl_gen {
  int len;
  int cnt;
  int word;
  short* sorted;
}
private int sinfl_build_tbl(sinfl_gen* gen, uint* tbl, int tbl_bits, const(int)* cnt) {
  int tbl_end = 0;
  while (!(() => gen.cnt = cnt[gen.len])()) {
    ++gen.len;
  }
  tbl_end = 1 << gen.len;
  while (gen.len <= tbl_bits) {
    do {uint bit = 0;
      tbl[gen.word] = (*gen.sorted++ << 16) | gen.len;
      if (gen.word == tbl_end - 1) {
        for (; gen.len < tbl_bits; gen.len++) {
          memcpy(&tbl[tbl_end], tbl, cast(size_t)tbl_end * typeof(tbl[0]).sizeof);
          tbl_end <<= 1;
        }
        return 1;
      }
      bit = 1 << sinfl_bsr(cast(uint)(gen.word ^ (tbl_end - 1)));
      gen.word &= bit - 1;
      gen.word |= bit;
    } while (--gen.cnt);
    do {
      if (++gen.len <= tbl_bits) {
        memcpy(&tbl[tbl_end], tbl, cast(size_t)tbl_end * typeof(tbl[0]).sizeof);
        tbl_end <<= 1;
      }
    } while (!(() => gen.cnt = cnt[gen.len])());
  }
  return 0;
}
private void sinfl_build_subtbl(sinfl_gen* gen, uint* tbl, int tbl_bits, const(int)* cnt) {
  int sub_bits = 0;
  int sub_start = 0;
  int sub_prefix = -1;
  int tbl_end = 1 << tbl_bits;
  while (1) {
    uint entry;
    int bit;int stride;int i;
    /* start new subtable */
    if ((gen.word & ((1 << tbl_bits)-1)) != sub_prefix) {
      int used = 0;
      sub_prefix = gen.word & ((1 << tbl_bits)-1);
      sub_start = tbl_end;
      sub_bits = gen.len - tbl_bits;
      used = gen.cnt;
      while (used < (1 << sub_bits)) {
        sub_bits++;
        used = (used << 1) + cnt[tbl_bits + sub_bits];
      }
      tbl_end = sub_start + (1 << sub_bits);
      tbl[sub_prefix] = (sub_start << 16) | 0x10 | (sub_bits & 0xf);
    }
    /* fill subtable */
    entry = (*gen.sorted << 16) | ((gen.len - tbl_bits) & 0xf);
    gen.sorted++;
    i = sub_start + (gen.word >> tbl_bits);
    stride = 1 << (gen.len - tbl_bits);
    do {
      tbl[i] = entry;
      i += stride;
    } while (i < tbl_end);
    if (gen.word == (1 << gen.len)-1) {
      return;
    }
    bit = 1 << sinfl_bsr(gen.word ^ ((1 << gen.len) - 1));
    gen.word &= bit - 1;
    gen.word |= bit;
    gen.cnt--;
    while (!gen.cnt) {
      gen.cnt = cnt[++gen.len];
    }
  }
}
private void sinfl_build(uint* tbl, ubyte* lens, int tbl_bits, int maxlen, int symcnt) {
  int i;int used = 0;
  short[288] sort;
  int[16] cnt = 0;int[16] off = 0;
  sinfl_gen gen; // = {0};
  gen.sorted = sort.ptr;
  gen.len = 1;

  for (i = 0; i < symcnt; ++i)
    cnt[lens[i]]++;
  off[1] = cnt[0];
  for (i = 1; i < maxlen; ++i) {
    off[i + 1] = off[i] + cnt[i];
    used = (used << 1) + cnt[i];
  }
  used = (used << 1) + cnt[i];
  for (i = 0; i < symcnt; ++i)
    gen.sorted[off[lens[i]]++] = cast(short)i;
  gen.sorted += off[0];

  if (used < (1 << maxlen)){
    for (i = 0; i < 1 << tbl_bits; ++i)
      tbl[i] = (0 << 16u) | 1;
    return;
  }
  if (!sinfl_build_tbl(&gen, tbl, tbl_bits, cnt.ptr)){
    sinfl_build_subtbl(&gen, tbl, tbl_bits, cnt.ptr);
  }
}
private int sinfl_decode(sinfl* s, const(uint)* tbl, int bit_len) {
  sinfl_refill(s);
  {int idx = sinfl_peek(s, bit_len);
  uint key = tbl[idx];
  if (key & 0x10) {
    /* sub-table lookup */
    int len = key & 0x0f;
    sinfl_consume(s, bit_len);
    idx = sinfl_peek(s, len);
    key = tbl[((key >> 16) & 0xffff) + cast(uint)idx];
  }
  sinfl_consume(s, key & 0x0f);
  return (key >> 16) & 0x0fff;}
}
private int sinfl_decompress(ubyte* out_, int cap, const(ubyte)* in_, int size) {
  static const(ubyte)* order = [16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15];
  static const(short)[30+2] dbase = [1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
      257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577];
  static const(ubyte)[30+2] dbits = [0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,
      10,10,11,11,12,12,13,13,0,0];
  static const(short)[29+2] lbase = [3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,
      43,51,59,67,83,99,115,131,163,195,227,258,0,0];
  static const(ubyte)[29+2] lbits = [0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,
      4,4,4,5,5,5,5,0,0,0];

  const(ubyte)* oe = out_ + cap;
  const(ubyte)* e = in_ + size;const(ubyte)* o = out_;
  enum sinfl_states {hdr,stored,fixed,dyn,blk}
  sinfl_states state = sinfl_states.hdr;
  sinfl s; // = {0};
  int last = 0;

  s.bitptr = in_;
  while (1) {
    with(sinfl_states) switch (state) {
    case hdr: {
      /* block header */
      int type = 0;
      sinfl_refill(&s);
      last = sinfl__get(&s,1);
      type = sinfl__get(&s,2);

      switch (type) {default: return cast(int)(out_-o);
      case 0x00: state = stored; break;
      case 0x01: state = fixed; break;
      case 0x02: state = dyn; break;}
    } break;
    case stored: {
      /* uncompressed block */
      int len;
      sinfl_refill(&s);
      sinfl__get(&s,s.bitcnt & 7);
      len = sinfl__get(&s,16);
      //int nlen = sinfl__get(&s,16);   // @raysan5: Unused variable?
      in_ -= 2; s.bitcnt = 0;

      if (len > (e-in_) || !len)
        return cast(int)(out_-o);
      memcpy(out_, in_, cast(size_t)len);
      in_ += len, out_ += len;
      state = hdr;
    } break;
    case fixed: {
      /* fixed huffman codes */
      int n; ubyte[288+32] lens;
      for (n = 0; n <= 143; n++) lens[n] = 8;
      for (n = 144; n <= 255; n++) lens[n] = 9;
      for (n = 256; n <= 279; n++) lens[n] = 7;
      for (n = 280; n <= 287; n++) lens[n] = 8;
      for (n = 0; n < 32; n++) lens[288+n] = 5;

      /* build lit/dist tables */
      sinfl_build(s.lits.ptr, lens.ptr, 10, 15, 288);
      sinfl_build(s.dsts.ptr, lens.ptr + 288, 8, 15, 32);
      state = blk;
    } break;
    case dyn: {
        /* dynamic huffman codes */
        int n;int i;
        uint[SINFL_PRE_TBL_SIZE] hlens;
        ubyte[19] nlens = 0;ubyte[288+32] lens;

        sinfl_refill(&s);
        {int nlit = 257 + sinfl__get(&s,5);
        int ndist = 1 + sinfl__get(&s,5);
        int nlen = 4 + sinfl__get(&s,4);
        for (n = 0; n < nlen; n++)
          nlens[order[n]] = cast(ubyte)sinfl_get(&s,3);
        sinfl_build(hlens.ptr, nlens.ptr, 7, 7, 19);

        /* decode code lengths */
        for (n = 0; n < nlit + ndist;) {
          int sym = sinfl_decode(&s, hlens.ptr, 7);
          switch (sym) {default: lens[n++] = cast(ubyte)sym; break;
          case 16: for (i=3+sinfl_get(&s,2);i;i--,n++) lens[n]=lens[n-1]; break;
          case 17: for (i=3+sinfl_get(&s,3);i;i--,n++) lens[n]=0; break;
          case 18: for (i=11+sinfl_get(&s,7);i;i--,n++) lens[n]=0; break;}
        }
        /* build lit/dist tables */
        sinfl_build(s.lits.ptr, lens.ptr, 10, 15, nlit);
        sinfl_build(s.dsts.ptr, lens.ptr + nlit, 8, 15, ndist);
        state = blk;}
    } break;
    case blk: {
      /* decompress block */
      int sym = sinfl_decode(&s, s.lits.ptr, 10);
      if (sym < 256) {
        /* literal */
        *out_++ = cast(ubyte)sym;
      } else if (sym > 256) {sym -= 257; /* match symbol */
        sinfl_refill(&s);
        {int len = sinfl__get(&s, lbits[sym]) + lbase[sym];
        int dsym = sinfl_decode(&s, s.dsts.ptr, 8);
        int offs = sinfl__get(&s, dbits[dsym]) + dbase[dsym];
        ubyte* dst = out_;ubyte* src = out_ - offs;
        if (sinfl_unlikely(offs > cast(int)(out_-o))) {
          return cast(int)(out_-o);
        }
        out_ = out_ + len;

        if (sinfl_likely(oe - out_ >= 3 * 8 - 3)) {
          if (offs >= 8) {
            /* copy match */
            sinfl_copy64(&dst, &src);
            sinfl_copy64(&dst, &src);
            do sinfl_copy64(&dst, &src);
            while (dst < out_);
          } else if (offs == 1) {
            /* rle match copying */
            uint c = src[0];
            uint hw = (c << 24u) | (c << 16u) | (c << 8u) | cast(uint)c;
            ulong w = cast(ulong)hw << 32UL | hw;
            dst = sinfl_write64(dst, w);
            dst = sinfl_write64(dst, w);
            do dst = sinfl_write64(dst, w);
            while (dst < out_);
          } else {
            *dst++ = *src++;
            *dst++ = *src++;
            do *dst++ = *src++;
            while (dst < out_);
          }
        }
        else {
          *dst++ = *src++;
          *dst++ = *src++;
          do *dst++ = *src++;
          while (dst < out_);}
        }
      } else {
        /* end of block */
        if (last) return cast(int)(out_-o);
        state = hdr;
        break;
      }
    } break;default: break;}
  }
  //return cast(int)(out_-o); // unreachable
}
extern int sinflate(void* out_, int cap, const(void)* in_, int size) {
  return sinfl_decompress(cast(ubyte*)out_, cap, cast(const(ubyte)*)in_, size);
}
private uint sinfl_adler32(uint adler32, const(ubyte)* in_, int in_len) {
  const(uint) ADLER_MOD = 65521;
  uint s1 = adler32 & 0xffff;
  uint s2 = adler32 >> 16;
  uint blk_len;uint i;

  blk_len = in_len % 5552;
  while (in_len) {
    for (i=0; i + 7 < blk_len; i += 8) {
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
    for (; i < blk_len; ++i)
      s1 += *in_++, s2 += s1;
    s1 %= ADLER_MOD; s2 %= ADLER_MOD;
    in_len -= blk_len;
    blk_len = 5552;
  } return cast(uint)(s2 << 16) + cast(uint)s1;
}
extern int zsinflate(void* out_, int cap, const(void)* mem, int size) {
  const(ubyte)* in_ = cast(const(ubyte)*)mem;
  if (size >= 6) {
    const(ubyte)* eob = in_ + size - 4;
    int n = sinfl_decompress(cast(ubyte*)out_, cap, in_ + 2u, size);
    uint a = sinfl_adler32(1u, cast(ubyte*)out_, n);
    uint h = eob[0] << 24 | eob[1] << 16 | eob[2] << 8 | eob[3] << 0;
    return a == h ? n : -1;
  } else {
    return -1;
  }
}
