class Drone {
  late int id;
  late int busy;
  Drone(this.id, this.busy);
}
class Data {
  late int um03, um05, um10, um25, um50, um100, task, id;
  Data(this.id, this.um03, this.um05, this.um10, this.um25, this.um50, this.um100, this.task);

  int getTsk() {
    return task;
  }

  List<int> getUM() {
    List<int> list = [um03, um05, um10, um25, um50, um100];
    return list;
  }
}

class Task {
  late double lat, lon;
  late int id, status=1;
  Task(this.id, this.lat, this.lon, this.status);

  List<double> ll() {
    List<double> list = [lat, lon];
    return list;
  }

  int getStatus() {
    return status;
  }
}