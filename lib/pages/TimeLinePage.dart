import 'package:Askforum/pages/HomePage.dart';
import 'package:Askforum/widgets/HeaderWidget.dart';
import 'package:Askforum/widgets/PostWidget.dart';
import 'package:Askforum/widgets/ProgressWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Askforum/models/user.dart';



class TimeLinePage extends StatefulWidget {

  final User gCurrentUser;

  TimeLinePage({
    this.gCurrentUser,
});

  @override
  _TimeLinePageState createState() => _TimeLinePageState();
}

class _TimeLinePageState extends State<TimeLinePage> {

  List<Post> posts;
  List<String> followingsList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  retriveTimeLine()async{
    QuerySnapshot querySnapshot = await timelineReference.document(widget.gCurrentUser.id).collection("timelinePosts")
        .orderBy("timestamp",descending: true).getDocuments();

    List<Post> allPosts = querySnapshot.documents.map((document) => Post.fromDocument(document)).toList();

    setState(() {
      this.posts = allPosts;
    });
  }

  retriveFollowings() async{
    QuerySnapshot querySnapshot = await followingReference.document(currentUser.id)
        .collection("userFollowing").getDocuments();

    setState(() {
      followingsList = querySnapshot.documents.map((document) => document.documentID).toList();
    });
  }

  @override

  void initState(){
    super.initState();

    retriveTimeLine();
    retriveFollowings();
  }

  createUserTimeLine(){
    if(posts == null){
      return circularProgress();

    }
    else{
      return ListView(
        children: posts,
      );
    }
  }

  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, isAppTitle: true,),
      body: RefreshIndicator(
        child: createUserTimeLine(),
        onRefresh: () => retriveTimeLine(),
      ),
    );
  }
}
