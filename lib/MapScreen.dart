import 'dart:collection';
import 'package:asthmathon/Objects.dart';
import 'package:asthmathon/dbhandler.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:prompt_dialog/prompt_dialog.dart';



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
    Navigator.pop(context);
    Navigator.pop(context);
  }

  //!
  //NEW MAP
  //!

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
                        title:Text(loc, style: const TextStyle(fontSize: 18),),
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
                    "Send Drone!",
                    style: TextStyle(fontSize: 25),
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
  void goToNewMap(int index, int busy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => NewMap(drone: index),
      ),
    );
  }

  void alert() {
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: const Text("Oops!"),
            content: const Text("Drone is currently in use!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  },
                child: const Text("Close"),
              )
            ],
          );
        }
    );
  }

  //!
  //LISTA DRONE
  //!
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
                    if (snapshot.data![index].busy == 0) {
                      return TextButton(
                        //style: ButtonStyle(
                        //foregroundColor: MaterialStateProperty.all<Color>(
                        //Colors.blue),
                        //),
                        style: TextButton.styleFrom(
                          primary: Colors.green[700],
                        ),
                        onPressed: () {
                          goToNewMap(snapshot.data![index].id,
                              snapshot.data![index].id);
                        },
                        child: Text(
                          "Drone ${snapshot.data![index].id}",
                          style: const TextStyle(fontSize: 25),
                        ),

                      );
                    }
                    else {
                      return TextButton(
                        //style: ButtonStyle(
                        //foregroundColor: MaterialStateProperty.all<Color>(
                        //Colors.blue),
                        style: TextButton.styleFrom(
                          primary: Colors.red[700],
                        ),
                        onPressed: () {
                          alert();
                        },
                        child: Text(
                          "Drone ${snapshot.data![index].id}",
                          style: const TextStyle(fontSize: 25),
                        ),
                      );
                    }
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

//!
//MAIN SCREEN
//!
class _MapScreenState extends State<MapScreen> {
  DBHandler db = DBHandler();
  GoogleMapController? _controller;
  CameraPosition? cameraPosition;
  Location currentLocation = Location();
  Set<Marker> _markers={};

  final Set<Circle> _circles = HashSet<Circle>();

  double radius=250.0;
  double radiusToLatLon = 0.0065/2;
  //radius 250 = latlong .0065

  List<bool> marked = [];
  List<double> ll = [];
  List<double> sums = [];
  List<int> nr = [];

  bool showed = false;

  int _circleIdCounter = 1;
  int _markerIdCounter = 1;
  double sum = 0;

  void goToDroneScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const SecondRoute(),
      ),
    );
  }

  void _setCircle(double lat, double long, Color clr) {
    final String circleIdVal = 'marker_id_$_circleIdCounter';
    _circleIdCounter++;
    LatLng point = LatLng(lat, long);
      print(
        'Circle | Latitude: ${point.latitude} Longitude: ${point.longitude} Radius: $radius');
      _circles.add(Circle(
        circleId: CircleId(circleIdVal),
        center:  point,
        radius: radius,
        fillColor: clr.withOpacity(0.25),
        strokeWidth: 2,
        strokeColor: clr
      ));
  }

  void cameraFix() async {
    var location = await currentLocation.getLocation();
    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    currentLocation.onLocationChanged.listen((LocationData loc){

      _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(loc.latitude ?? 0.0,loc.longitude?? 0.0),
        zoom: 15.0,
      )));
      setState(() {
        _markers.add(
          Marker(markerId: MarkerId(markerIdVal),
            position: LatLng(loc.latitude ?? 0.0,loc.longitude?? 0.0),
            ),
          );
      });
    });
  }

  void clearCircles() async{
    _circles.clear();
  }

  /*void clearMarkers() async{
    setState(() {
      _markers.clear();
    });
  }*/

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
    sums = List.filled(1000, 0.0);
    nr = List.filled(1000, 0);
    /*setState(() {
      getLocation();
    });*/
  }

  bool alreadyCircled(double lat, double lon) {
    for(Circle circle in _circles) {
        if(circle.center == LatLng(lat,lon)) {
          return false;
        }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    print(db.getData());
    return Scaffold(
      appBar: AppBar(
        title: Text("Allergy Map"),
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
            clearCircles();
          },
          onCameraMove: (CameraPosition cameraPositiona) {
            cameraPosition = cameraPositiona;
            //_markers.clear();
          },
          onCameraIdle: () async { //when map drag stops
            _setCircle(45.75372, 21.22571, Colors.orangeAccent);
            //_setCircle(45.75372, 21.23221, Colors.orangeAccent);
            print("AM INTRAT");
            List<Data> data = await db.getData();
            print(data.length);
            for (Data d in data) {
                  sums[d.task] += d.um25;
                  nr[d.task]++;
            }
            print("INAINTE");
            List<Task> tasks = await db.getTasks();
            for (Task task in tasks) {
                if (task.status == 3) {
                  double value = sums[task.id] / nr[task.id];
                  print(value);
                  print(sums[task.id]);
                  print(nr[task.id]);
                  print(task.id);
                  if (value <= 15.0 && !alreadyCircled(task.lat, task.lon)) {
                    setState(() {
                      //clearCircles();
                      _setCircle(task.lat, task.lon, Colors.greenAccent);
                    });
                  }
                  else if (value <= 50.0 && !alreadyCircled(task.lat, task.lon)) {
                    setState(() {
                      //clearCircles();
                      _setCircle(task.lat, task.lon, Colors.orangeAccent);
                    });
                  }
                  else if (!alreadyCircled(task.lat, task.lon)) {
                    setState(() {
                      //clearCircles();
                      _setCircle(task.lat, task.lon, Colors.redAccent);
                    });
                  }
                }
            }
            /*for(int i=0;i<rows.length;++i) {
              sums[rows[i].getTsk()]/=rows.length;
              if(sums[rows[i].getTsk()]<=25.0) {
                setState(() {
                  clearCircles();
                  _setCircle(ll[0], ll[1], Colors.greenAccent);
                });
              }
              else if(sums[rows[i].getTsk()]>25.0 && sum<=35.0) {
                setState(() {
                  clearCircles();
                  _setCircle(ll[0], ll[1], Colors.orangeAccent);
                });
              }
              else if(sums[rows[i].getTsk()]>35.0) {
                setState(() {
                  clearCircles();
                  _setCircle(ll[0], ll[1], Colors.redAccent);
                });
              }
            }*/
          },
          markers: _markers,
          circles: _circles,
          onTap: (LatLng latLng){
            var lat = latLng.latitude;
            var lon = latLng.longitude;
            for(Circle circle in _circles) {
              var center = circle.center;
              var circlelat = center.latitude;
              var circlelon = center.longitude;
              //radiusToLatLon = (radius * 2.6)/100000;
              if(lat >= circlelat - radiusToLatLon && lat <= circlelat + radiusToLatLon && lon >= circlelon - radiusToLatLon && lon <= circlelon + radiusToLatLon) {
                print("11111111111111111111111111111111111111111111111111");
              }
            }
          },
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
          /*Positioned(
            left: 30,
            top: 120,
            child: FloatingActionButton(
              heroTag: 'clear',
              onPressed: () {clearMarkers();},
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}