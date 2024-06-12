// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:aplikasi_absen/screen/attandance_recap_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aplikasi_absen/model/presensi.dart';
import 'package:aplikasi_absen/utils/mix.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String nik = "", token = "", name = "", dept = "", imgUrl = "";
  bool isMasuk = true;

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? nik = prefs.getString('nik') ?? "";
    String? token = prefs.getString('jwt') ?? "";
    String? name = prefs.getString('name') ?? "";
    String? dept = prefs.getString('dept') ?? "";
    String? imgUrl = prefs.getString('imgProfil') ?? "Not Found";

    setState(() {
      this.token = token;
      this.nik = nik;
      this.name = name;
      this.dept = dept;
      this.imgUrl = imgUrl;
    });
  }

  Future<Presensi> fetchPresensi(String nik, String tanggal) async {
    String url =
        'https://presensi.spilme.id/presence?nik=$nik&tanggal=$tanggal';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return Presensi.fromJson(jsonDecode(response.body));
    } else {
      //jika data tidak tersedia, buat data default
      return Presensi(
        id: 0,
        nik: this.nik,
        tanggal: getTodayDate(),
        jamMasuk: "--:--",
        jamKeluar: '--:--',
        lokasiMasuk: '-',
        lokasiKeluar: '-',
        status: '-',
      );
    }
  }

  // Metode untuk menyimpan status check-in/check-out
  Future<void> saveStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isMasuk', isMasuk);
  }

  // Metode untuk memuat status check-in/check-out
  Future<void> loadStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMasuk = prefs.getBool('isMasuk') ?? true;
    });
  }

  Future<void> recordAttendance() async {
    Navigator.pop(context);

    const String endpointMasuk = 'https://presensi.spilme.id/entry';
    const String endpointKeluar = 'https://presensi.spilme.id/exit';
    final endpoint = isMasuk ? endpointMasuk : endpointKeluar;
    final requestBody = isMasuk
        ? {
            'nik': nik,
            'tanggal': getTodayDate(),
            'jam_masuk': getTime(),
            'lokasi_masuk': 'polbeng',
          }
        : {
            'nik': nik,
            'tanggal': getTodayDate(),
            'jam_keluar': getTime(),
            'lokasi_keluar': 'polbeng',
          };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseBody['message'])),
      );
      setState(() {
        isMasuk = !isMasuk;
        saveStatusMasuk(); // simpan status absensi
      });
      //refresh informasi absensi
      fetchPresensi(nik, getTodayDate());
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record attendance')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    loadStatusMasuk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        imgUrl,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons
                              .error); // Display error icon if image fails to load
                        },
                      )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(dept, style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                  Icon(Icons.notifications_outlined, size: 40),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Kehadiran Hari Ini",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RiwayatAbsen()),
                        );
                      },
                      child: Text(
                        "Rekap Absen",
                        style: TextStyle(color: Colors.blue, fontSize: 15),
                      ))
                ],
              ),
              SizedBox(height: 15),
              FutureBuilder<Presensi>(
                  future: fetchPresensi(nik, getTodayDate()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final data = snapshot.data;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              width: 170,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    10), // Mengatur sudut bulat
                                border: Border.all(
                                    color: Colors.grey,
                                    width: 1), // Mengatur garis tepi
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(
                                        Icons.arrow_circle_right_outlined,
                                        size: 35),
                                    title: Text(
                                      'Masuk',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(width: 15),
                                      Text(data?.jamMasuk ?? '--:--',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(width: 15),
                                      Text(
                                        getPresenceEntryStatus(
                                            data?.jamMasuk ?? '-'),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              child: Container(
                            width: 170,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  10), // Mengatur sudut bulat
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 1), // Mengatur garis tepi
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(
                                      Icons.arrow_circle_right_outlined,
                                      size: 35),
                                  title: Text(
                                    'Keluar',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 15),
                                    Text(data?.jamKeluar ?? '--:--',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 15),
                                    Text(
                                      getPresenceExitStatus(
                                          data?.jamKeluar ?? '-'),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ))
                        ],
                      );
                    } else {
                      return const Center(child: Text("No Data Available"));
                    }
                  }),
              SizedBox(
                height: 15,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      width: 350,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: Size(350, 50),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.9,
                                child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      children: <Widget>[
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              'Presensi ${isMasuk ? 'Masuk' : 'Pulang'}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 25),
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.calendar_month_outlined,
                                              color: Colors.red,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    "Tanggal Masuk",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  Text(getTodayDate(),
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.schedule_outlined,
                                              color: Colors.red,
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    "Jam Masuk",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  Text(getTime(),
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 15,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text("Foto selfie di area kampus",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.grey))
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.5,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.48,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8), // Mengatur sudut bulat
                                                  border: Border.all(
                                                      color: Colors.grey,
                                                      width:
                                                          2), // Mengatur garis tepi
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.camera_alt,
                                                      size: 50,
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text("Ambil Gambar",
                                                        style: TextStyle(
                                                            fontSize: 18))
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  minimumSize: Size(350, 50),
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                                onPressed: () {},
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Text(
                                                      "Hadir",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    )),
                              );
                            },
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.circle_outlined,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Tekan untuk presensi ${isMasuk ? 'masuk' : 'pulang'}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: 170,
                      height: 190,
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10), // Mengatur sudut bulat
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black,
                              Colors.grey,
                              Colors.grey,
                              Colors.grey,
                              Colors.black,
                            ],
                          ) // Mengatur garis tepi
                          ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  "Izin Absen",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "Isi form untuk meminta izin absen",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 50,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 130,
                                  child: Column(
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {},
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              "Ajukan Izin",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      width: 170,
                      height: 190,
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10), // Mengatur sudut bulat
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple,
                              Colors.purpleAccent,
                              Colors.purpleAccent,
                              Colors.purpleAccent,
                              Colors.purple,
                            ],
                          ) // Mengatur garis tepi
                          ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  "Ajukan Cuti",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                )
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "Isi form untuk mengajukan cuti",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 50,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: 130,
                                  child: Column(
                                    children: <Widget>[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {},
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Text(
                                              "Ajukan Cuti",
                                              style: TextStyle(
                                                  color: Colors.purple,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
