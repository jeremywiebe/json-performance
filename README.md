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
  1.json (140 bytes)                             0.92 MB/s
  2.json (99 bytes)                              2.84 MB/s
  3.json (559 bytes)                            13.73 MB/s
  4.json (4195 bytes)                           21.73 MB/s
  5-paste-whole-file:send.json (15850 bytes)   210.81 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             0.66 MB/s
  2.json (99 bytes)                              3.48 MB/s
  3.json (559 bytes)                            10.46 MB/s
  4.json (4195 bytes)                           59.67 MB/s
  5-paste-whole-file:send.json (15850 bytes)   119.04 MB/s

Test: Codable..........

  == Serializing... ==============================================
  1.json (140 bytes)                             0.24 MB/s
  2.json (99 bytes)                              0.65 MB/s
  3.json (559 bytes)                             1.44 MB/s
  4.json (4195 bytes)                            3.73 MB/s
  5-paste-whole-file:send.json (15850 bytes)    85.11 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             0.11 MB/s
  2.json (99 bytes)                              0.44 MB/s
  3.json (559 bytes)                             0.67 MB/s
  4.json (4195 bytes)                            2.59 MB/s
  5-paste-whole-file:send.json (15850 bytes)    41.88 MB/s
```

# 100,000 iterations

```
Test: JSONSerialization..........

  == Serializing... ==============================================
  1.json (140 bytes)                            15.30 MB/s
  2.json (99 bytes)                             12.99 MB/s
  3.json (559 bytes)                            33.65 MB/s
  4.json (4195 bytes)                           50.65 MB/s
  5-paste-whole-file:send.json (15850 bytes)   307.41 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                            43.97 MB/s
  2.json (99 bytes)                             38.11 MB/s
  3.json (559 bytes)                            46.75 MB/s
  4.json (4195 bytes)                           82.86 MB/s
  5-paste-whole-file:send.json (15850 bytes)   249.23 MB/s

Test: Codable..........

  == Serializing... ==============================================
  1.json (140 bytes)                             5.55 MB/s
  2.json (99 bytes)                              4.52 MB/s
  3.json (559 bytes)                             6.82 MB/s
  4.json (4195 bytes)                            8.30 MB/s
  5-paste-whole-file:send.json (15850 bytes)   156.64 MB/s

  == Deserializing... ============================================
  1.json (140 bytes)                             2.82 MB/s
  2.json (99 bytes)                              2.48 MB/s
  3.json (559 bytes)                             2.56 MB/s
  4.json (4195 bytes)                            4.21 MB/s
  5-paste-whole-file:send.json (15850 bytes)   120.89 MB/s
```
