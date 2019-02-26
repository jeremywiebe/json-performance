# json-performance

Comparing JSON encoding/decoding in Swift 5. The tests use the [Xi](https://github.com/xi-editor/xi-editor) message format for testing.

## Running

The project builds a command-line app that can be run to test performance. You can optionally pass in the number of iterations to test (there is definitely a "ramp up" time before both implementations hit their sweet spot).

## Results

On my laptop (MacBook Pro 2017 - 2.8 GHz Intel Core i7) I get these results.

# 1 iteration

```
Test: JSONSerialization..........

  == Serializing... ==============================================
  1.json (140 bytes)                             0.39 MB/s
  2.json (121 bytes)                             0.58 MB/s
  3.json (559 bytes)                             5.66 MB/s
  4.json (4195 bytes)                            9.54 MB/s
  5-paste-whole-file:send.json (15850 bytes)   199.65 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             0.27 MB/s
  2.json (121 bytes)                             1.37 MB/s
  3.json (559 bytes)                             1.96 MB/s
  4.json (4195 bytes)                            7.39 MB/s
  5-paste-whole-file:send.json (15850 bytes)   132.97 MB/s

Test: Codable..........

  == Serializing... ==============================================
  1.json (140 bytes)                             0.25 MB/s
  2.json (121 bytes)                             0.26 MB/s
  3.json (559 bytes)                             1.12 MB/s
  4.json (4195 bytes)                            3.54 MB/s
  5-paste-whole-file:send.json (15850 bytes)    72.46 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             0.12 MB/s
  2.json (121 bytes)                             0.16 MB/s
  3.json (559 bytes)                             0.77 MB/s
  4.json (4195 bytes)                            2.04 MB/s
  5-paste-whole-file:send.json (15850 bytes)    35.51 MB/s
```

# 100,000 iterations

```
Test: JSONSerialization..........

  == Serializing... ==============================================
  1.json (140 bytes)                             6.28 MB/s
  2.json (121 bytes)                             6.19 MB/s
  3.json (559 bytes)                            12.41 MB/s
  4.json (4195 bytes)                           13.30 MB/s
  5-paste-whole-file:send.json (15850 bytes)   254.90 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             9.59 MB/s
  2.json (121 bytes)                            10.18 MB/s
  3.json (559 bytes)                            13.06 MB/s
  4.json (4195 bytes)                           14.90 MB/s
  5-paste-whole-file:send.json (15850 bytes)   214.60 MB/s

Test: Codable..........

  == Serializing... ==============================================
  1.json (140 bytes)                             5.90 MB/s
  2.json (121 bytes)                             4.20 MB/s
  3.json (559 bytes)                             7.65 MB/s
  4.json (4195 bytes)                            8.67 MB/s
  5-paste-whole-file:send.json (15850 bytes)   191.77 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             2.94 MB/s
  2.json (121 bytes)                             2.56 MB/s
  3.json (559 bytes)                             2.81 MB/s
  4.json (4195 bytes)                            4.63 MB/s
  5-paste-whole-file:send.json (15850 bytes)   123.54 MB/s
```
