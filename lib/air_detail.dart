import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pm25/air_quality_page.dart';

class AQICardPage extends StatefulWidget {
  @override
  _AQICardPageState createState() => _AQICardPageState();
}

class _AQICardPageState extends State<AQICardPage> {
  Map<String, dynamic>? station;

  @override
  void initState() {
    super.initState();
    loadAQI();
  }

  Future<void> loadAQI() async {
    final url = Uri.parse("http://air4thai.pcd.go.th/services/getNewAQI_JSON.php");

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final stations = data["stations"] ?? [];

      // ใช้เฉพาะสถานี "ทุ่งสองห้อง" (ตามที่คุณใช้อยู่)
      final selected = stations.firstWhere(
        (e) => e["areaTH"].toString().contains("ทุ่งสองห้อง"),
        orElse: () => null,
      );

      setState(() => station = selected);
    }
  }

  // แปลง AQI เป็นสีและข้อความ
  Map<String, dynamic> getAQILevel(int aqi) {
    if (aqi <= 50) {
      return {"text": "Good", "color": Colors.green.shade300};
    } else if (aqi <= 100) {
      return {"text": "Moderate", "color": Colors.yellow.shade300};
    } else if (aqi <= 150) {
      return {"text": "Unhealthy", "color": Colors.orange.shade300};
    } else {
      return {"text": "Very Unhealthy", "color": Colors.red.shade300};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (station == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final aqi = int.tryParse(station?["AQILast"]?["AQI"]?["aqi"] ?? "0") ?? 0;
    final pm25 = double.tryParse(station?["AQILast"]?["PM25"]?["value"] ?? "0") ?? 0.0;
    final level = getAQILevel(aqi);

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, spreadRadius: 2)
              ],
            ),

            // ========================
            //      COLUMN UI หลัก
            // ========================
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Text(
                  "${station?["areaTH"]} Rtarf(AQI)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 5),
                Text(
                  "Last updated at ${station?["AQILast"]?["time"]}, ${station?["AQILast"]?["date"]}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),

                SizedBox(height: 16),

                // MAIN AQI BOX
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: level["color"],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.face, size: 50, color: Colors.black54),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$aqi",
                            style: TextStyle(
                                fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            level["text"],
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("PM2.5"),
                          Text(
                            "${pm25.toStringAsFixed(1)} µg/m³",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // // WEATHER-LIKE ROW (ใช้ N/A เพราะ API ไม่มี)
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                //     _info(Icons.cloud, "N/A"),
                //     _info(Icons.water_drop, "N/A"),
                //     _info(Icons.air, "N/A"),
                //   ],
                // ),

                // SizedBox(height: 22),

                // Divider(),

                // // FORECAST 3 วัน (Placeholder)
                // SizedBox(height: 16),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                //   children: [
                //     _forecast("Fri", 81),
                //     _forecast("Sat", 78),
                //     _forecast("Sun", 67),
                //   ],
                // ),

                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    backgroundColor: Colors.blueGrey,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AirQualityPage(),
                      ),
                    );
                  },
                  child: Text("เลือกสถานีอื่นๆ"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sub Widgets
  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _forecast(String day, int aqi) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.yellow.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text("$aqi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 6),
        Icon(Icons.cloud, size: 28),
      ],
    );
  }
}
