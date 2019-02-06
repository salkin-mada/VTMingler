unstable!

## install
...

## server and possible preparations
execute `s.options.numBuffers`, this throws 1026 in the post window. if a higher buffer count is needed set this before booting the server

```
( s.options.numBuffers_(4000); s.boot; )
```
