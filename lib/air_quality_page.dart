import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AirQualityPage extends StatefulWidget {
  @override
  _AirQualityPageState createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {
  List stations = [];
  List filteredStations = [];
  String? selectedStation;
  String searchQuery = "";
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAQI();
  }

  Future<void> fetchAQI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final url = Uri.parse("http://air4thai.pcd.go.th/services/getNewAQI_JSON.php");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List stationsData = data["stations"] ?? [];

        final preselected =
            stationsData.isNotEmpty ? stationsData.first["areaTH"] : null;

        setState(() {
          stations = stationsData;
          selectedStation = preselected;
          searchQuery = "";
          filteredStations =
              _buildFilteredList(stationsData, selected: preselected);
          isLoading = false;
        });
      } else {
        throw Exception("API error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        errorMessage = "โหลดข้อมูลไม่สำเร็จ: $e";
        isLoading = false;
      });
    }
  }

  // ตรวจค่าฝุ่นเกินมาตรฐาน
  bool isPM25Over(double v) => v > 25; // มาตรฐานไทย
  bool isPM10Over(double v) => v > 50;

  List _buildFilteredList(List source, {String? selected, String query = ""}) {
    final trimmedQuery = query.trim().toLowerCase();

    return source.where((item) {
      final area = item["areaTH"]?.toString() ?? "";
      final areaLower = area.toLowerCase();
      final matchesSelected =
          selected == null || selected.isEmpty || area == selected;
      final matchesQuery =
          trimmedQuery.isEmpty || areaLower.contains(trimmedQuery);
      return matchesSelected && matchesQuery;
    }).toList();
  }

  List _dropdownSource() {
    final trimmed = searchQuery.trim().toLowerCase();
    if (trimmed.isEmpty) return stations;
    return stations.where((item) {
      final area = item["areaTH"]?.toString() ?? "";
      final areaLower = area.toLowerCase();
      if (selectedStation != null && area == selectedStation) return true;
      return areaLower.contains(trimmed);
    }).toList();
  }

  void updateFilters({String? newSelected, String? newQuery}) {
    setState(() {
      if (newSelected != null) selectedStation = newSelected;
      if (newQuery != null) searchQuery = newQuery;
      filteredStations = _buildFilteredList(
        stations,
        selected: selectedStation,
        query: searchQuery,
      );
    });
  }

  // สี Card ตามสถานะ PM2.5
  Color getCardColor(double pm25) {
    if (pm25 == -1) return Colors.grey.shade300;
    return isPM25Over(pm25) ? Colors.red.shade200 : Colors.green.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final dropdownWidth =
        math.min(MediaQuery.of(context).size.width * 0.9, 320.0);
    final dropdownItems = _dropdownSource();

    return Scaffold(
      appBar: AppBar(
        title: Text("Rtarf (AQI)"),
      ),
      
      body: Column(
        children: [
          // Dropdown เลือกพื้นที่
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dropdownWidth),
                child: DropdownButtonFormField<String>(
                  value: selectedStation,
                  decoration: InputDecoration(
                    labelText: "เลือกพื้นที่",
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: dropdownItems.map<DropdownMenuItem<String>>((item) {
                    return DropdownMenuItem<String>(
                      value: item["areaTH"],
                      child: Text(
                        item["areaTH"],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    updateFilters(newSelected: value);
                  },
                ),
              ),
            ),
          ),

          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dropdownWidth),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "ค้นหาพื้นที่",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) => updateFilters(newQuery: text),
                ),
              ),
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (errorMessage != null) {
                  return Center(child: Text(errorMessage!));
                }
                if (filteredStations.isEmpty) {
                  return Center(child: Text("ไม่พบข้อมูล"));
                }

                return ListView.builder(
                  itemCount: filteredStations.length,
                  itemBuilder: (context, index) {
                    final item = filteredStations[index];
                    final stationName = item["areaTH"]?.toString() ?? "-";

                    // ----- โครงสร้างตาม JSON จริง -----
                    final aqiAll = item["AQILast"]["AQI"]["aqi"]?.toString() ?? "-";

                    final pm25String = item["AQILast"]["PM25"]["value"] ?? "-1";
                    final pm25 = double.tryParse(pm25String) ?? -1;

                    final pm10String = item["AQILast"]["PM10"]["value"] ?? "-1";
                    final pm10 = double.tryParse(pm10String) ?? -1;

                    final pm25Status = pm25 == -1
                        ? "ไม่มีข้อมูล"
                        : (isPM25Over(pm25) ? "เกินมาตรฐาน" : "ปกติ");

                    final pm10Status = pm10 == -1
                        ? "ไม่มีข้อมูล"
                        : (isPM10Over(pm10) ? "เกินมาตรฐาน" : "ปกติ");

                    return Card(
                      color: getCardColor(pm25),
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          stationName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "AQI รวม: $aqiAll\n"
                          "PM2.5: $pm25 µg/m³ ($pm25Status)\n"
                          "PM10: $pm10 µg/m³ ($pm10Status)",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      
    );
  }
}
