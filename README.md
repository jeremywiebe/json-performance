# json-performance

Comparing JSON encoding/decoding in Swift 5. The tests use the [Xi](https://github.com/xi-editor/xi-editor) message format for testing. 

## Running 

The project builds a command-line app that can be run to test performance. You can optionally pass in the number of iterations to test (there is definitely a "ramp up" time before both implementations hit their sweet spot). 

