# WeberCedrus

This Julia package extends [Weber](https://github.com/haberdashPI/Weber.jl), to
enable the use of [Cedrus response-pad input](https://cedrus.com/rb_series/). It
adds a series of new keys, ranging from `key":cedrus0:"` to
`key":cedrus19:"`. You can see which key is which by pressing the buttons while
running the following code in julia.

```julia
using Weber
run_keycode_helper(extenstions=[@Cedrus()])
```

To make use of the response keys, just reference them as you would keyboard
keys. For instance, the following code will record cedrus buttons 1 and 2
as answers1 and answer2 to the experiment data file.

```julia
response(key":cedrus1:" => "answer1", key":cedrus2:" => "answer2")
```




