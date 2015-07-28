// manually rewritten from CoffeeScript output
// (see dev-coffee branch for original source)
importScripts('Mp3LameEncoder.min.js');

var buffers = undefined,
    encoder = undefined;

self.onmessage = function(event) {
  var data = event.data;
  switch (data.command) {
    case 'start':
      encoder = new Mp3LameEncoder(data.sampleRate, data.bitRate);
      buffers = data.process === 'separate' ? [] : undefined;
      break;
    case 'record':
      if (buffers != null)
        buffers.push(data.buffers);
      else
        encoder.encode(data.buffers);
      break;
    case 'finish':
      if (buffers != null)
        while (buffers.length > 0)
          encoder.encode(buffers.shift());
      self.postMessage({ blob: encoder.finish() });
      encoder = undefined;
      break;
    case 'cancel':
      encoder.cancel();
      encoder = undefined;
  }
};
