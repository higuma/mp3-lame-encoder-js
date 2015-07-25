(function() {
  var buffers, encoder;

  importScripts('Mp3LameEncoder.min.js');

  encoder = void 0;

  buffers = void 0;

  self.onmessage = function(event) {
    var data;
    data = event.data;
    switch (data.command) {
      case 'start':
        encoder = new Mp3LameEncoder(data.sampleRate, data.bitRate);
        buffers = data.process === 'separate' ? [] : void 0;
        break;
      case 'record':
        if (buffers != null) {
          buffers.push(data.buffers);
        } else {
          encoder.encode(data.buffers);
        }
        break;
      case 'finish':
        if (buffers != null) {
          while (buffers.length > 0) {
            encoder.encode(buffers.shift());
          }
        }
        self.postMessage({
          blob: encoder.finish()
        });
        encoder = void 0;
        break;
      case 'cancel':
        encoder.cancel();
        encoder = void 0;
    }
  };

}).call(this);
