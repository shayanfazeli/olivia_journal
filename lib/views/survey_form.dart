import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:olivia_journal/auth.dart';
import 'package:olivia_journal/views/survey_selection.dart';


class SurveyForm extends StatefulWidget {
  final String surveyId;
  final String surveyTitle;

  const SurveyForm({Key key, this.surveyId, this.surveyTitle}) : super(key: key);

  @override
  _SurveyFormState createState() => _SurveyFormState(this.surveyId, this.surveyTitle);
}

class _SurveyFormState extends State<SurveyForm> {
  final String surveyId;
  final String surveyTitle;
  List<Widget> questionCard;

  List<String> questionTextList = null;
  List<String> questionTypeList = null;
  List<List<String>> questionChoicesList = null;
  List<List<String>> userAnswerList = null;
  bool surveyIsLoaded = null;

  int questionInSight = 0;
  List<String> userAnswerForQuestionInSight = null;
  String radioButtonGroupValue = null;

  FirebaseUser user;

  _SurveyFormState(this.surveyId, this.surveyTitle);


  Future<void> getSurveyQuestions() async{
    List<String> tmpQuestionTextList = new List<String>();
    List<String> tmpQuestionTypeList = new List<String>();
    List<List<String>> tmpQuestionChoicesList = new List<List<String>>();
    List<List<String>> tmpUserAnswerList = new List<List<String>>();
    int numberOfQuestions;
    List<String> tmpQuestionsData;


    await Firestore.instance.collection("olivia_journal").document("surveys").collection("items").document(surveyId).get().then(
        (DocumentSnapshot docRef){
          tmpQuestionsData = docRef.data['questions'].cast<String>();
          numberOfQuestions = tmpQuestionsData.length;
        }
    );

    user = await firebaseAuthAgent.currentUser();
    // here you write the codes to input the data into firestore

    for (int i = 0; i < numberOfQuestions; i = i + 1){
      String tmpQuestionData = tmpQuestionsData.elementAt(i);
      List<String> components = tmpQuestionData.split("|");
      tmpQuestionTextList.add(components[0]);
      tmpQuestionTypeList.add(components[1]);
      tmpUserAnswerList.add(null);
      tmpQuestionChoicesList.add(components[2].split(","));
      debugPrint("shayandebug " + components[2].split(",").toString());
    }

    setState(() {
      questionTextList = tmpQuestionTextList;
      questionTypeList = tmpQuestionTypeList;
      questionChoicesList = tmpQuestionChoicesList;
      userAnswerList = tmpUserAnswerList;
      surveyIsLoaded = true;
    });

  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    surveyIsLoaded = false;
    questionTextList = null;
    questionTypeList = null;
    questionChoicesList = null;
    getSurveyQuestions();
    questionInSight = 0;
    userAnswerForQuestionInSight = [];
  }

  Future<void> trySubmittingResponse(BuildContext context) async{
    try{
      await Firestore.instance.collection(
          "olivia_journal")
          .document("responses")
          .collection("items")
          .add(
          {
            "questionTextList": questionTextList.toString(),
            "questionTypeList": questionTypeList.toString(),
            "questionChoicesList": questionChoicesList.toString(),
            "userAnswerList": userAnswerList.toString(),
            "user_email": user.email.toString(),
            "user_id": user.uid.toString(),
          }
      );
      setState(() {
        Scaffold.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text("Your response is submitted.")));
      });

      Navigator.push(context, MaterialPageRoute(builder: (context) => SurveySelector()));
    }
    catch(e){
      setState(() {
        Scaffold.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Please check your network and try again.")));
      });
    }
  }

  List<Widget> getQuestionWidget(BuildContext context) {
    if (!surveyIsLoaded){
      return [CircularProgressIndicator()];
    }
    else{
      if (questionTypeList.elementAt(questionInSight) == "multiple_choice"){
        debugPrint("shayandebug " + questionChoicesList.elementAt(questionInSight).elementAt(0).toString());
        return [
          Center(child: Text(questionTextList.elementAt(questionInSight), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),)),
          Builder(
            builder: (BuildContext context) => Center(
              child: Container(
                height: MediaQuery.of(context).size.height/2.0,
                width: MediaQuery.of(context).size.width,
                child:  SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ListView.separated(
                    shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) => CheckboxListTile(
                        title: Text(questionChoicesList.elementAt(questionInSight).elementAt(index)),
                        value: userAnswerForQuestionInSight.contains(
                            questionChoicesList.elementAt(questionInSight).elementAt(index)
                        ),
                        onChanged: (bool value){
                          setState(() {
                            if (value)
                              userAnswerForQuestionInSight.add(questionChoicesList.elementAt(questionInSight).elementAt(index));
                            else{
                              if (userAnswerForQuestionInSight.contains(questionChoicesList.elementAt(questionInSight).elementAt(index)))
                                userAnswerForQuestionInSight.remove(questionChoicesList.elementAt(questionInSight).elementAt(index));
                            }
                          });
                        },
                      ),
                      separatorBuilder: (BuildContext context, int index) => const Divider(),
                      itemCount: questionChoicesList.elementAt(questionInSight).length),
                ),
              ),
            ),
          ),
          InkWell(
            child: Center(
              child: Container(
                height: 25,
                  width: MediaQuery.of(context).size.width / 1.5,
                  decoration: BoxDecoration(
                      color: Colors.greenAccent.shade700,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))
                  ),
                  child: Center(child: Text("OK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0),))
              ),
            ),
            onTap: (){
              // todo: write the code for submission
              userAnswerList[questionInSight] = userAnswerForQuestionInSight;
              if (questionInSight == questionTextList.length - 1){
                trySubmittingResponse(context);
              }
              else{
                setState(() {
                  questionInSight = questionInSight + 1;
                  userAnswerForQuestionInSight = [];
                });
              }
            },
          )
        ];
      }
      else if (questionTypeList.elementAt(questionInSight) == "single_choice"){
        return [
          Center(child: Text(questionTextList.elementAt(questionInSight), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),)),
          Builder(
            builder: (BuildContext context) => Container(
              height: MediaQuery.of(context).size.height/2.0,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ListView.separated(
                  shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) => RadioListTile<String>(
                      title: Text(questionChoicesList.elementAt(questionInSight).elementAt(index)),
                      value: questionChoicesList.elementAt(questionInSight).elementAt(index),
                      groupValue: radioButtonGroupValue,
                      onChanged: (String value){
                        setState(() {
                          radioButtonGroupValue = value;
                          userAnswerForQuestionInSight = [value];
                        });
                      },
                    ),
                    separatorBuilder: (BuildContext context, int index) => const Divider(),
                    itemCount: questionChoicesList.elementAt(questionInSight).length),
              ),
            ),
          ),
          InkWell(
            child: Center(
              child: Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width / 1.5,
                  decoration: BoxDecoration(
                      color: Colors.greenAccent.shade700,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))
                  ),
                  child: Center(child: Text("OK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0),))
              ),
            ),
            onTap: (){
              // todo: write the code for submission
              userAnswerList[questionInSight] = userAnswerForQuestionInSight;
              if (questionInSight == questionTextList.length - 1){
                trySubmittingResponse(context);
              }
              else{
                setState(() {
                  questionInSight = questionInSight + 1;
                  userAnswerForQuestionInSight = [];
                });
              }
            },
          )
        ];
      }
      else if (questionTypeList.elementAt(questionInSight) == "text"){
        TextEditingController controller = new TextEditingController();
        return [
          Center(child: Text(questionTextList.elementAt(questionInSight), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.0),)),
          Builder(
            builder: (BuildContext context) => Container(
              height: MediaQuery.of(context).size.height/2.0,
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: TextField(
                  controller: controller,

                )
              ),
            ),
          ),
          InkWell(
            child: Center(
              child: Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width / 1.5,
                  decoration: BoxDecoration(
                      color: Colors.greenAccent.shade700,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))
                  ),
                  child: Center(child: Text("OK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.0),))
              ),
            ),
            onTap: (){
              // todo: write the code for submission
              userAnswerList[questionInSight] = [controller.text];
              if (questionInSight == questionTextList.length - 1){
                trySubmittingResponse(context);
              }
              else{
                setState(() {
                  questionInSight = questionInSight + 1;
                  userAnswerForQuestionInSight = [];
                });
              }
            },
          )
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(surveyTitle),),
      body: Builder(
        builder: (BuildContext context) => Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(child: Text("Question " + (questionInSight + 1).toString() + "/" + questionTextList.length.toString())),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(height: 10, width: MediaQuery.of(context).size.width,),
                ),
                Container(
                  height: MediaQuery.of(context).size.height/1.5,
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    color: Colors.lightBlueAccent.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: getQuestionWidget(context),
                    ),
                  ),
                )
              ],
            ),
          )
        ),
      ),
    );
  }
}
