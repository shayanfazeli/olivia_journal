import 'package:flutter/material.dart';
import 'package:olivia_journal/views/survey_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ffi';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:olivia_journal/auth.dart';

class SurveySelector extends StatefulWidget {
  @override
  _SurveySelectorState createState() => _SurveySelectorState();
}

class _SurveySelectorState extends State<SurveySelector> {
  // todo: write the code for obtaining surveytitles and surveyids from
  // firestore database isnide a initState function

  //todo: the entire main should show a loading circle unless the records are fetched.
  List<String> surveyTitles = null;
  List<String> surveyIds = null;
  List<String> surveyImageNames = null;

  bool userIsAuthenticated = false;

  Future<void> getSurveyList() async {
    List<String> tmpSurveyTitles = <String>[];
    List<String> tmpSurveyIds = <String>[];
    List<String> tmpSurveyImageNames = <String>[];
    await Firestore.instance
        .collection("olivia_journal")
        .document("surveys")
        .collection("items")
        .getDocuments()
        .then((QuerySnapshot surveyDocuments) {
      int numberOfSurveys = surveyDocuments.documents.length;
      for (int i = 0; i < numberOfSurveys; i = i + 1) {
        tmpSurveyTitles
            .add(surveyDocuments.documents.elementAt(i).data['title']);
        tmpSurveyIds.add(surveyDocuments.documents.elementAt(i).documentID);
        tmpSurveyImageNames.add(
            surveyDocuments.documents.elementAt(i).data['imgname'].toString());
      }
    });

    setState(() {
      surveyIds = tmpSurveyIds;
      surveyTitles = tmpSurveyTitles;
      surveyImageNames = tmpSurveyImageNames;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    surveyTitles = null;
    surveyIds = null;
    surveyImageNames = null;
    getSurveyList();
  }

  Widget getMainBody(BuildContext context) {
    if (surveyIds == null) {
      return Center(child: Container(child: CircularProgressIndicator()));
    } else {
      debugPrint("newdebug: " + surveyImageNames.toString());
      return Center(
          child: Container(
            color: Colors.lightBlue,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    child: Card(
                      child: Container(
                          width: MediaQuery.of(context).size.width / 1.2,
                          height: MediaQuery.of(context).size.height / 1.5,
                          color: Colors.amber,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                          FutureBuilder(
                              future: _getThumbnailImageItem(
                                  context, surveyImageNames[index].toString()),
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (!snapshot.hasData)
                                  return CircularProgressIndicator();
                                else {
                                  return snapshot.data;
                                }
                              }),
                              Center(
                                  child: Text(surveyTitles.elementAt(index), style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w700),)),
                            ],
                          )),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SurveyForm(
                                    surveyId: surveyIds.elementAt(index),
                                    surveyTitle: surveyTitles.elementAt(index),
                                  )));
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
                itemCount: surveyTitles.length,
              ),
            ),
            InkWell(
              child: Container(
                height: 30,
                width: MediaQuery.of(context).size.width/1.1,
                color: Colors.grey,
                  child: Center(child: Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w500),))
              ),
              onTap: () {
                signOutGoogle();
                Navigator.pop(context);
              },
            )
          ],
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text("Select a Survey", style: TextStyle(fontSize: 15.0),),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: getMainBody(context),
    );
  }

  Future<Widget> _getThumbnailImageItem(
      BuildContext context, String imagename) async {
    try {
      Image thumbnail;
      await loadImage(context, imagename).then((value) {
        thumbnail = Image.network(value.toString(), fit: BoxFit.cover);
      });
      return thumbnail;
    } on Exception catch (e) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Colors.black,
        ),
      );
    }
  }

  static Future<dynamic> loadImage(
      BuildContext context, String filename) async {
    return await FirebaseStorage.instance
        .ref()
        .child("survey_thumbnails")
        .child(filename)
        .getDownloadURL();
  }
}
