# navigator.getUserMedia shim
navigator.getUserMedia =
  navigator.getUserMedia ||
  navigator.webkitGetUserMedia ||
  navigator.mozGetUserMedia ||
  navigator.msGetUserMedia

# URL shim
URL = window.URL || window.webkitURL

# audio context + .createScriptProcessor shim
audioContext = new AudioContext
unless audioContext.createScriptProcessor?
  audioContext.createScriptProcessor = audioContext.createJavaScriptNode

# elements (jQuery objects)
$testToneLevel = $ '#test-tone-level'
$microphone = $ '#microphone'
$microphoneLevel = $ '#microphone-level'
$encodingProcess = $ 'input[name="encoding-process"]'
$bufferSize = $ '#buffer-size'
$bitRate = $ '#bit-rate'
$recording = $ '#recording'
$timeDisplay = $ '#time-display'
$record = $ '#record'
$cancel = $ '#cancel'
$dateTime = $ '#date-time'
$recordingList = $ '#recording-list'

# initialize input element states (required for reloading page on Firefox)
$testToneLevel.attr 'disabled', false
$testToneLevel[0].valueAsNumber = 0
$microphone.attr 'disabled', false
$microphone[0].checked = false
$microphoneLevel.attr 'disabled', false
$microphoneLevel[0].valueAsNumber = 0
$encodingProcess.attr 'disabled', false
$encodingProcess[0].checked = true
$bufferSize.attr 'disabled', false
# ($bufferSize[0].valueAsNumber is initaialized later)
$bitRate.attr 'disabled', false
$bitRate[0].valueAsNumber = 5

# test tone (440Hz sine with 2Hz on/off beep)
testTone = do ->
  osc = audioContext.createOscillator()
  lfo = audioContext.createOscillator()
  lfo.type = 'square'
  lfo.frequency.value = 2
  oscMod = audioContext.createGain()
  osc.connect oscMod
  lfo.connect oscMod.gain
  output = audioContext.createGain()
  output.gain.value = 0.5
  oscMod.connect output
  osc.start()
  lfo.start()
  output

# source input mixer
testToneLevel = audioContext.createGain()
testToneLevel.gain.value = 0
testTone.connect testToneLevel
microphoneLevel = audioContext.createGain()
microphoneLevel.gain.value = 0
mixer = audioContext.createGain()
testToneLevel.connect mixer
microphone = undefined          # obtained by user click
microphoneLevel.connect mixer
mixer.connect audioContext.destination

# mixer level
$testToneLevel.on 'input', ->
  level = $testToneLevel[0].valueAsNumber / 100
  testToneLevel.gain.value = level * level
  return

$microphoneLevel.on 'input', ->
  level = $microphoneLevel[0].valueAsNumber / 100
  microphoneLevel.gain.value = level * level
  return

# obtaining microphone input
$microphone.click ->
  unless microphone?
    navigator.getUserMedia(
      { audio: true },
      (stream) ->
        microphone = audioContext.createMediaStreamSource stream
        microphone.connect microphoneLevel
        $microphone.attr 'disabled', true
        $microphoneLevel.removeClass 'hidden'
      (error) ->
        $microphone[0].checked = false
        window.alert "Could not get audio input."
    )
  return

# encoding process selector
encodingProcess = 'separate'    # separate | background | direct

$encodingProcess.click (event) ->
  encodingProcess = $(event.target).attr 'mode'
  return

# processor node
# (create here to detect browser-default bufferSize)
processor = audioContext.createScriptProcessor(null, 2, 2)
mixer.connect processor
processor.connect audioContext.destination

# processor buffer size
BUFFER_SIZE = [256, 512, 1024, 2048, 4096, 8192, 16384]

iDefBufSz = BUFFER_SIZE.indexOf processor.bufferSize
$bufferSize[0].valueAsNumber = iDefBufSz    # initialize with browser default

updateBufferSizeText = ->
  iBufSz = $bufferSize[0].valueAsNumber
  text = "#{BUFFER_SIZE[iBufSz]}"
  text += ' (browser default)' if iBufSz == iDefBufSz
  $('#buffer-size-text').html text
  return

updateBufferSizeText()  # initialize text

$bufferSize.on 'input', ->
  updateBufferSizeText()
  return

# MP3 bit rate
BIT_RATE = [64, 80, 96, 112, 128, 160, 192, 224, 256, 320]

$bitRate.on 'input', ->
  $('#bit-rate-text').html "#{BIT_RATE[$bitRate[0].valueAsNumber]}kbps"
  return

# save/delete recording
saveRecording = (blob) ->
  time = new Date()
  url = URL.createObjectURL blob
  html = "<p recording='#{url}'>" +
    "<audio controls src='#{url}'></audio> &nbsp; " +
    "#{time.toString()} &nbsp; " +
    "<a class='btn btn-default' href='#{url}' download='recording.mp3'>" +
    "Save..." +
    "</a> " +
    "<button class='btn btn-danger' recording='#{url}'>Delete</button>"
    "</p>"
  $recordingList.prepend $(html)
  return

$recordingList.on 'click', 'button', (event) ->
  url = $(event.target).attr 'recording'
  $("p[recording='#{url}']").remove()
  URL.revokeObjectURL url
  return

# recording process
worker = new Worker 'js/EncoderWorker.js'
worker.onmessage = (event) ->
  saveRecording event.data.blob
  return
encoder = undefined     # used on encodingProcess == direct

startRecordingProcess = ->
  bufSz = BUFFER_SIZE[$bufferSize[0].valueAsNumber]
  if bufSz != processor.bufferSize
    mixer.disconnect()
    mixer.connect audioContext.destination
    processor.disconnect()
    processor = audioContext.createScriptProcessor bufSz, 2, 2
    mixer.connect processor
    processor.connect audioContext.destination
  bitRate = BIT_RATE[$bitRate[0].valueAsNumber]
  if encodingProcess == 'direct'
    encoder = new Mp3LameEncoder audioContext.sampleRate, bitRate
    processor.onaudioprocess = (event) ->
      encoder.encode(event.inputBuffer.getChannelData ch for ch in [0...2])
      return
  else
    worker.postMessage
      command: 'start'
      process: encodingProcess
      sampleRate: audioContext.sampleRate
      bitRate: bitRate
    processor.onaudioprocess = (event) ->
      worker.postMessage
        command: 'record'
        buffers: event.inputBuffer.getChannelData ch for ch in [0...2]
      return
  return

stopRecordingProcess = (finish) ->
  processor.onaudioprocess = null
  if encodingProcess == 'direct'
    if finish
      saveRecording encoder.finish()
    else
      encoder.cancel()
  else
    worker.postMessage command: if finish then 'finish' else 'cancel'
  return

# recording buttons interface
startTime = null        # null indicates recording is stopped

minSecStr = (n) -> (if n < 10 then "0" else "") + n

updateDateTime = ->
  $dateTime.html((new Date).toString())
  if startTime?
    sec = Math.floor (Date.now() - startTime) / 1000
    $timeDisplay.html "#{minSecStr sec / 60 | 0}:#{minSecStr sec % 60}"
  return

window.setInterval updateDateTime, 200

# disable recording configs
disableControlsOnRecord = (disabled) ->
  unless microphone?
    $microphone.attr 'disabled', disabled
  $bufferSize.attr 'disabled', disabled
  $encodingProcess.attr 'disabled', disabled
  return

startRecording = ->
  startTime = Date.now()
  $recording.removeClass 'hidden'
  $record.html 'STOP'
  $cancel.removeClass 'hidden'
  disableControlsOnRecord true
  startRecordingProcess()
  return

stopRecording = (finish) ->
  startTime = null
  $timeDisplay.html '00:00'
  $recording.addClass 'hidden'
  $record.html 'RECORD'
  $cancel.addClass 'hidden'
  disableControlsOnRecord false
  stopRecordingProcess finish
  return

$record.click ->
  if startTime?
    stopRecording true
  else
    startRecording()
  return

$cancel.click ->
  stopRecording false
  return
