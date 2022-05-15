import 'dart:collection';

import 'package:asthmathon/Objects.dart';
import 'package:asthmathon/dbhandler.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class NewMap extends StatefulWidget {
  int drone;

  NewMap({Key? key, required this.drone}) : super(key: key);
  @override
  _NewMapState createState() => _NewMapState();

  /*static int getDrone() {
    return drone;
  }*/

}
class _NewMapState extends State<NewMap>{

  DBHandler db = DBHandler();
  GoogleMapController? _controller;
  Set<Marker> _markers={};
  CameraPosition? cameraPosition;
  String loc = "Location Name:";
  late LatLng point;

  void sendTask() {
    db.addTask(point.latitude, point.longitude, widget.drone);
    print(loc);
    Navigator.pop(context);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a location"),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
      ),
      body: Stack(
        children: [
          //height: MediaQuery.of(context).size.height,
          //width: MediaQuery.of(context).size.width,
          GoogleMap(
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            initialCameraPosition:const CameraPosition(
              target: LatLng(45.75372, 21.22571),
              zoom: 12.5,
           ),
            onMapCreated: (GoogleMapController controller){
              _controller = controller;
            },
            onCameraMove: (CameraPosition cameraPositiona) {
              cameraPosition = cameraPositiona; //when map is dragging
            },
            onCameraIdle: () async { //when map drag stops
              print(1);
              List<gc.Placemark> placemarks = await gc.placemarkFromCoordinates(
                  cameraPosition!.target.latitude,
                  cameraPosition!.target.longitude);
              setState(() {
                loc =
                "${placemarks.first.administrativeArea}, ${placemarks.first
                    .street}";
                point = LatLng(cameraPosition!.target.latitude, cameraPosition!.target.longitude);
              });
            },
            markers: _markers,
         ) ,
          Center( //picker image on google map
            child: Image.asset("assets/images/picker.png", width: 20,),
          ),
          Positioned(  //widget to display location name
              bottom:100,
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Card(
                  child: Container(
                      padding: EdgeInsets.all(0),
                      width: MediaQuery.of(context).size.width - 40,
                      child: ListTile(
                        leading: Image.asset("assets/images/picker.png", width: 20,),
                        title:Text(loc, style: TextStyle(fontSize: 18),),
                        dense: true,
                      )
                  ),
                ),
              )
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              child: FloatingActionButton(
                onPressed: () {
                    sendTask();
                },
                backgroundColor: Colors.blue[700],
                shape: const RoundedRectangleBorder(),
                child: const Text(
                    "Submit!"
                ),
              ),
            ),
          ),
          ],
        ),
    );
  }
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({Key? key}) : super(key: key);

  _SecondRouteState createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  void goToNewMap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => NewMap(drone: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DBHandler db = DBHandler();
    return FutureBuilder(
        future: db.getDrones(),
        builder: (BuildContext context, AsyncSnapshot<List<Drone>> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                title: Text("Drones"),
              ),
              body: ListView.builder(
                itemCount: snapshot.data?.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (BuildContext context, int index) {
                  // return Text((snapshot.data![index].id).toString());
                  return TextButton(
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(
                          Colors.blue),
                     // backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      goToNewMap(snapshot.data![index].id);
                    },
                    child: Text((snapshot.data![index].id).toString()),
                  );
                }
            ),
            );

          }
          else {
            return const Center(child: CircularProgressIndicator());
          }
        }
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  DBHandler db = DBHandler();
  GoogleMapController? _controller;
  Location currentLocation = Location();
  Set<Marker> _markers={};

  final Set<Circle> _circles = HashSet<Circle>();

  double radius=2250.0;

  int _circleIdCounter = 1;

  void goToDroneScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SecondRoute(),
      ),
    );
  }

  void _setCircle(double lat, double long) {
    final String circleIdVal = 'marker_id_$_circleIdCounter';
    _circleIdCounter++;
    LatLng point = LatLng(lat, long);
      print(
        'Circle | Latitude: ${point.latitude} Longitude: ${point.longitude} Radius: $radius');
      _circles.add(Circle(
        circleId: CircleId(circleIdVal),
        center:  point,
        radius: radius,
        fillColor: Colors.redAccent.withOpacity(0.25),
        strokeWidth: 1,
        strokeColor: Colors.redAccent
      ));
  }

  void cameraFix() async {
    var location = await currentLocation.getLocation();
    currentLocation.onLocationChanged.listen((LocationData loc){

      _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(loc.latitude ?? 0.0,loc.longitude?? 0.0),
        zoom: 15.0,
      )));
      });
  }

  void clearCircles() async{
    print(_circles);
    _circles.clear();
    print(db.getData());
  }

  void getLocation() async{
    var location = await currentLocation.getLocation();
    currentLocation.onLocationChanged.listen((LocationData loc){
      print(loc.latitude);
      print(loc.longitude);
      /*setState(() {
        _circles.clear();
        _setCircle(loc.latitude ?? 0.0, loc.longitude ?? 0.0);
      });*/
    });
  }
  @override
  void initState(){
    super.initState();
    /*setState(() {
      getLocation();
    });*/
  }

  @override
  Widget build(BuildContext context) {
    print(db.getData());
    return Scaffold(
      appBar: AppBar(
        title: Text("AsthMap"),
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
            zoom: 12.5,
          ),
          onMapCreated: (GoogleMapController controller){
            _controller = controller;
          },
          onCameraIdle: () async { //when map drag stops
            print(1);
            List rows = await db.getData();
            for(int i=0;i<rows.length;++i) {
              print(rows[i].getTsk());
                Task task= await db.getTask(rows[i].getTsk());
                print(task.getStatus());
                if(task.getStatus()==3) {
                  List ll = task.ll();
                  _setCircle(ll[0], ll[1]);
                }
            }
          },
          markers: _markers,
          circles: _circles,
        ) ,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            bottom: 20,
            right: 30,
            child: FloatingActionButton(
              heroTag: 'back',
              onPressed: () {
                cameraFix();
                //db.getDrones();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_searching,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: 20,
            child: FloatingActionButton(
              heroTag: 'next',
              onPressed: () {goToDroneScreen();},
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 120,
            child: FloatingActionButton(
              heroTag: 'clear',
              onPressed: () {clearCircles();},
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          // Add more floating buttons if you want
          // There is no limit
        ],
      ),
    );
  }
}