library sample;

import '../singleAudioContext.dart';
import 'package:angular/angular.dart';
import 'dart:html';
import 'dart:async';
import 'dart:web_audio';

@NgComponent(
    selector: 'sample',
    templateUrl: 'sample/sample.html',
    cssUrl: 'sample/sample.css',
    publishAs: 'cmp'
)
class SampleComponent {
  @NgAttr('id')
  String id;
  
  @NgAttr('name')
  String name;
  
  @NgAttr('href')
  String href;
  
  @NgCallback('onItemDragged')
  var onItemDragged;
  
  @NgCallback('onRightClick')
  var onRightClick;

  SingleAudioContext _audioContext;
  SampleComponent(){
    _audioContext = new SingleAudioContext();
  }
  
  void drag(MouseEvent e){
    e.dataTransfer.setData('id', (e.currentTarget as Element).id);
    e.dataTransfer.setData('SampleName', name);
    e.dataTransfer.setData('SampleHref', href);
  }
  
  void dragEnd(MouseEvent e){
    onItemDragged();
  }
  
  void onContextMenu (Event e){
    onRightClick();
    e.preventDefault();
  }
  
  void playSample(){ 
    new SingleAudioContext().stopAll();
    new Sample(href).play();
  }
  
  String getColors(){
    if (href.contains("beat"))
      return '#3F3EE5, #3E93E5';
    
    if (href.contains("key"))
      return '#97218D, #D86FCF';
    
    if (href.contains("guitar"))
      return '#E5983E, #DBAC75';
    
    if (href.contains("bass"))
      return '#2B4C20, #4F9C35';
    
    return '#CBA610, #D4BD5E';
  }
}

class Sample{
  
  SingleAudioContext _context = new SingleAudioContext();
  StreamController _loadedController = new StreamController.broadcast();

  String _fileName;
  
  AudioBuffer _buffer;
  bool get loaded => _buffer != null;

  static Map<String, Sample> _cache;

  factory Sample(String fileName) {

    if (_cache == null) 
      _cache = {};

    if (_cache.containsKey(fileName))
      return _cache[fileName];
    
    final sample = new Sample._internal(fileName);
    _cache[fileName] = sample;
    
    return sample;
  }

  Sample._internal(this._fileName){
    _load();
  }

  void _load(){  
    
    new HttpRequest()
      ..open('GET', _fileName, async: true)
      ..responseType = 'arraybuffer'
      ..onLoad.listen(_onLoadSuccess)
      ..onError.listen(_onLoadError)
      ..send();
  }

  void _onLoadSuccess (Event e){

    _context
      .decodeAudioData((e.target as HttpRequest).response)
      .then((AudioBuffer buffer){

        if (buffer == null) {
          print("Error decoding file data: $_fileName");
          return;
        }
        
        print(_fileName + " - " + buffer.duration.toString());  
        _buffer = buffer;
        
        _loadedController.add("loaded");
      })
      .catchError((error) => print("Error: $error"));
  }
  
  void _onLoadError (Event e)=> print("BufferLoader: XHR error");
  
  void play({num startTime: 0}){ 
       
    if (_buffer == null){
      _loadedController.stream.listen((_) {_play(startTime);});
    }
    else
      _play(startTime);
  }
  
  void _play(num startTime)=> _context.playFromBuffer(_buffer, startTime: startTime);
}
