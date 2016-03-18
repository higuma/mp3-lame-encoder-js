# Mp3LameEncoder.js

## What is it?

Mp3LameEncoder.js is a JavaScript library that encodes audio data to MP3 (MPEG-1 audio layer III) on web browsers.

[LAME](http://lame.sourceforge.net/) is used for encoding engine. [Emscripten](http://emscripten.org) is used to convert LAME C code into JavaScript.

### Acknowledgement

It was originally a fork of libmp3lame.js (<https://github.com/akrennmair/libmp3lame-js>). API has been totally re-designed and simplified. Now it has been a lower layer part of [WebAudioRecorder.js](https://github.com/higuma/web-audio-recorder-js).

## Demo

<https://boo-higuma.ssl-lolipop.jp/gh-pages/mp3-lame-encoder-js/>

## Library files

`lib/` contains library files.

* `Mp3LameEncoder.js`: JavaScript library (uncompressed)
* `Mp3LameEncoder.min.js`: JavaScript library (minified)
* `Mp3LameEncoder.min.js.mem`: memory initializer data for Mp3LameEncoder.min.js

### Using library

Uncompressesd library is a single file. You can use it from both HTML and Web Worker.

* from HTML: `<script src="javascripts/Mp3LameEncoder.js"></script>`
* from Worker: `importScripts("javascripts/Mp3LameEncoder.js");`

Using minified library is same way. But you must pay attention to memory initializer location.

* from HTML: default directory is same as HTML which loads Mp3LameEncoder.min.js
* from Worker: default directory is same as Mp3LameEncoder.min.js path

To change memory initializer path from HTML:

``` html
<script>
// default path is on the same directory as this HTML
Mp3LameEncoderConfig = {
  memoryInitializerPrefixURL: "javascripts/"   // must end with slash
  // => changed to javascripts/Mp3LameEncoder.min.js.mem
};
</script>
<script src="javascripts/Mp3LameEncoder.min.js"></script>
```

From Worker:

``` javascript
// default path is on the same directory as Mp3LameEncoder.min.js
self.Mp3LameEncoderConfig = {
  memoryInitializerPrefixURL: "javascripts/memory/"
  // => changed to javascripts/memory/Mp3LameEncoder.min.js.mem
};
importScripts("javascripts/Mp3LameEncoder.min.js");
```

## API

``` javascript
encoder = new Mp3LameEncoder(sampleRate, bitRate)
```

Create an encoder object.

* Parameters
    * `samleRate`: sampling rate [Hz]
    * `bitRate`: MP3 bit rate [kbps]
* Returns
    * encoder object

Actual bit rate is set as follows (at 44100Hz).

```
   .. 72 ->  64
 73.. 89 ->  80
 90..104 ->  96
105..120 -> 112
121..144 -> 128
145..176 -> 160
177..208 -> 192
209..240 -> 224
241..288 -> 256
289..    -> 320
```

> Current implementation supports LAME CBR encoding only.

``` javascript
encoder.encode(buffers)
```

Encode audio buffers.

* Parameters
    * `buffers`: array of sample buffers (`[Float32Array, Float32Array]`)
* Returns
    * (none)

`buffers` must be an array of two Float32Array audio data (separate strereo, range = [-1, 1]). It supports stream (incremental) processing. Sample buffers are processed to MP3 stream and appended to internal data.

``` javascript
blob = encoder.finish([mimeType])
```

Finish encoding and get MP3 as a Blob.

* Parameters
    * `mimeType`(optional): MIME type (default = `"audio/mpeg"`)
* Returns
    * Blob object

After calling `.finish()`, all internal data is cleared (to avoid resource leak). You must create a new encoder object to encode another audio data.

``` javascript
encoder.cancel()
```

Cancel encoding and clear all internal data.

* Parameters
    * (none)
* Returns
    * (none)

You should call `.cancel()` manually to avoid resource leak when recording is canceled (encoder's internal memory is not deallocated by unbinding an object variable).

## Build

Emscripten and ruby are required to build the library.

```
$ rake
```

Download and extract LAME, build library files (see [Rakefile](Rakefile) for more details).

## License

LAME is licensed under the LGPL. JavaScript-converted part of this library follows the same license as LAME (see below). 

<http://lame.sourceforge.net/about.php>

JavaScript wrapper API part of this library is released under MIT license (see [LICENSE.txt](LICENSE.txt)).
