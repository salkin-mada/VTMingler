## install

## server and possible preparations

execute 's.options.numBuffers', this throws 1026 in the post window.
if a higher buffer count is needed set this before booting the server
´´´
(
    s.options.numBuffers_(4000);
    s.boot;
)
´´´

´´´
~tio = VTMBufferFolders(s, "C:/something/something/audiofiles");


(
Pbind(
	\instrument, \VTMingler,
	\bufnum, Pseq([~tio[\basepath].at(0).values.at(2)], inf),
	//\bufnum, Pxrand(~tio[\basepath].at(0).values, inf),
	\dur, Pseq([1],inf),
	\startPos, 0.0,
	\rate, 3.5,
).play(TempoClock(130.60/60*4));
)

´´´