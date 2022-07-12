import 'package:asthmathon/Objects.dart';
import 'package:mysql1/mysql1.dart';

class DBHandler {
  static String host = "192.168.0.1";
  static int port = 3306;
  static String user = "pi2";
  static String password = "password";
  static String db = "drone";
  static var settings;
  DBHandler() {
    settings = ConnectionSettings(
        host: host,
        port: port,
        user: user,
        password: password,
        db: db
    );
  }
  Future<List<Drone>> getDrones() async {
    List<Drone> drones = [];
    var conn = await MySqlConnection.connect(settings);
    var results = await conn.query('select * from drones');
    for (var row in results) {
      drones.add(Drone(row[0], row[1]));
    }
    return drones;
  }
  Future<void> addTask(double lat, double lon, int drone) async {
    var conn = await MySqlConnection.connect(settings);
    String sql = "insert into task (lat, lon, status, drone) values ('" + lat.toString() + "','" + lon.toString() + "','1','" + drone.toString() + "')";
    await conn.query(sql);
  }
  Future<List<Data>> getData() async {
    List<Data> data = [];
    var conn = await MySqlConnection.connect(settings);
    var results = await conn.query('select * from data');
    for (var row in results) {
      data.add(Data(row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7]));
    }
    return data;
  }
  Future<List<Task>> getTasks() async {
    List<Task> tasks = [];
    var conn = await MySqlConnection.connect(settings);
    var results = await conn.query("SELECT * FROM task");
    print("Sunt aici");
    for (var row in results) {
      tasks.add(Task(row[0], row[1], row[2], row[3]));
    }
    return tasks;
  }
}