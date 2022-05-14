import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Location currentLocation = Location();
  Set<Marker> _markers={};


  void getLocation() async{
    var location = await currentLocation.getLocation();
    currentLocation.onLocationChanged.listen((LocationData loc){

      _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(loc.latitude ?? 0.0,loc.longitude?? 0.0),
        zoom: 12.0,
      )));
      print(loc.latitude);
      print(loc.longitude);
      setState(() {
        _markers.add(Marker(markerId: const MarkerId('Home'),
            position: LatLng(loc.latitude ?? 0.0, loc.longitude ?? 0.0)
        ));
      });
    });
  }

  @override
  void initState(){
    super.initState();
    setState(() {
      getLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AsthmMap"),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child:GoogleMap(
          zoomControlsEnabled: false,
          initialCameraPosition:const CameraPosition(
            target: LatLng(45.75372, 21.22571),
            zoom: 9.0,
          ),
          onMapCreated: (GoogleMapController controller){
            _controller = controller;
          },
          markers: _markers,
        ) ,
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.location_searching,color: Colors.white,),
        onPressed: (){
          getLocation();
        },
      ),
    );
  }
}